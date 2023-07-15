from fastapi import FastAPI, HTTPException, Request, Response
from fastapi import WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from jsonschema import validate
from jinja2 import Environment, PackageLoader, select_autoescape
from yaml import SafeLoader
from datetime import datetime
from urllib.parse import urlsplit
import json
import uuid
import os
import yaml
import asyncio


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
    for host in config.get('hosts'):
        for ifname, interface in host.get('interfaces').items():
            if interface.get('mac') == client:
                return host
    raise HTTPException(status_code=404, detail="Host not found: %s" % client)


##############################################################################
# Sanity checks and Initialization
##############################################################################


if not os.path.exists('hostconf.yml'):
    raise RuntimeError(
        "hostconf.yml not found. See README.md for instructions.")

config = None
with open('hostconf.yml', 'r') as f:
    config = yaml.load(f, Loader=SafeLoader)


schema = None
with open('hostconf.yml-schema', 'r') as f:
    schema = json.load(f)


validate(instance=config, schema=schema)


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
async def osconfig(client):
    template = env.get_template("osconfig.j2")
    host = get_host_config(client)

    return Response(content=template.render(get_host_config(client)),
                    media_type="text/string")


@app.get("/network-config/{client}")
async def network_config(client):
    template = env.get_template("network-config.j2")
    host = get_host_config(client)

    return Response(content=template.render(host),
                    media_type="text/yaml")


@app.get("/user-data/{client}")
async def user_data(client):
    template = env.get_template("user-data.j2")
    host = get_host_config(client)

    return Response(content=template.render(host),
                    media_type="text/yaml")


@app.get("/meta-data/{client}")
async def meta_data(client):
    template = env.get_template("meta-data.j2")

    return Response(content=template.render({
            'instance_id': uuid.uuid4
    }), media_type="text/yaml")


@app.put("/unattend/{client}")
async def unattend(client, request: Request):
    template_str = (await request.body()).decode('utf-8')
    template = env.from_string(template_str)
    host = get_host_config(client)

    return Response(content=template.render(host),
                    media_type="application/xml")


@app.get("/unattend/{client}")
async def unattend(client, request: Request):
    template = env.get_template("unattend.xml.j2")
    host = get_host_config(client)

    return Response(content=template.render(host),
                    media_type="application/xml")
