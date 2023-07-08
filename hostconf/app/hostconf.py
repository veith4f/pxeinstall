from fastapi import FastAPI, HTTPException, Request, Response
from fastapi import WebSocket, WebSocketDisconnect
from schema import Schema, Optional, SchemaError, Regex
from jinja2 import Environment, PackageLoader, select_autoescape
from yaml import SafeLoader
from datetime import datetime
from urllib.parse import urlsplit
import uuid
import os
import yaml
import asyncio

##############################################################################
# Sanity checks
##############################################################################


config_schema = Schema({
    "hosts": {
        str: {
            'install': str,
            'install_to': str,
            'config': str,
            'nameserver': str,
            'users': {
                str: {
                    'primary_group': str,
                    Optional('groups'): [str],
                    Optional('gecos'): str,
                    Optional('ssh_keys'): [str],
                    Optional('sudo'): bool,
                    Optional('uid'): int,
                    Optional('shell'): str,
                    Optional('lock_passwd'): bool,
                }
            },
            'interfaces': {
                str: {
                    'mac': Regex(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'),
                    'addresses': [str],
                    'routes': [{
                        'to': str,
                        'via': str,
                        Optional('metric'): str
                    }]
                }
            },
            Optional('root_pw'): str,
            Optional('run_cmds'): [str],
            Optional('groups'): [str],
        }
    }
}, ignore_extra_keys=True)

if not os.path.exists('hostconf.yaml'):
    raise RuntimeError(
        "hostconf.yaml not found. See README.md for instructions.")

config = None
with open('hostconf.yaml', 'r') as f:
    config = yaml.load(f, Loader=SafeLoader)

if not config_schema.is_valid(config):
    config_schema.validate(config)
    raise SchemaError("Invalid schema: hostconf.yaml")


##############################################################################
# Helpers
##############################################################################


class WebSocketConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)


def get_host_config(client):
    for hostname, host in config.get('hosts').items():
        for ifname, interface in host.get('interfaces').items():
            if interface.get('mac') == client:
                return hostname, host
    raise HTTPException(status_code=404, detail="Host not found: %s" % client)


##############################################################################
# Begin application
##############################################################################


app = FastAPI(title=__name__)
wsman = WebSocketConnectionManager()
env = Environment(
    loader=PackageLoader(__name__),
    autoescape=select_autoescape()
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    response = await call_next(request)
    asyncio.create_task(wsman.broadcast(
        "%s - %s:%s %s %s %s %s" % (datetime.now(),
                                    request.client.host, request.client.port,
                                    request.method, request.url.path,
                                    "HTTP/1.1", response.status_code)
    ))
    return response


@app.websocket("/log")
async def websocket_endpoint(websocket: WebSocket):
    await wsman.connect(websocket)
    try:
        while True:
            msg = await websocket.receive_text()
    except WebSocketDisconnect:
        wsman.disconnect(websocket)


@app.get("/log")
async def log(request: Request):
    template = env.get_template("log.j2")
    return Response(content=template.render({
        'title': __name__,
        'host': urlsplit(request.url._url).hostname
    }), media_type="text/html")


@app.get("/osconfig/{client}")
async def osconfig(client, request: Request):
    hostname, host = get_host_config(client)
    template = env.get_template("osconfig.j2")

    return Response(content=template.render({
        'install': host.get('install'),
        'install_to': host.get('install_to'),
        'config': host.get('config')
    }), media_type="text/string")


@app.get("/network-config/{client}")
async def network_config(client, request: Request):
    hostname, host = get_host_config(client)
    template = env.get_template("network-config.j2")

    return Response(content=template.render({
        'interfaces':  host.get('interfaces', [])
    }), media_type="text/yaml")


@app.get("/user-data/{client}")
async def user_data(client, request: Request):
    hostname, host = get_host_config(client)
    template = env.get_template("user-data.j2")

    return Response(content=template.render({
        'hostname': hostname,
        'users': host.get('users', []),
        'groups': host.get('groups', []),
        'root_pw': host.get('root_pw', None),
        'run_cmds': host.get('run_cmds', []),
    }), media_type="text/yaml")


@app.get("/meta-data/{client}")
async def meta_data(client, request: Request):
    hostname, host = get_host_config(client)
    template = env.get_template("meta-data.j2")

    return Response(content=template.render({
        'instance_id': uuid.uuid4(),
        'hostname': hostname
    }), media_type="text/yaml")


@app.get("/unattend/{client}")
async def unattend(client, request: Request):
    hostname, host = get_host_config(client)
    template = env.get_template("unattend.xml.j2")

    return Response(content=template.render({
        'hostname': hostname,
        'users': host.get('users', []),
        'groups': host.get('groups', []),
        'root_pw': host.get('root_pw', None),
        'run_cmds': host.get('run_cmds', []),
        'interfaces': host.get('interfaces', [])
    }), media_type="application/xml")
