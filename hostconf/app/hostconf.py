from fastapi import FastAPI, HTTPException, Response
from schema import Schema, Optional, SchemaError, Regex, Use
import yaml
import os
import uuid
from yaml import SafeLoader
from jinja2 import Environment, PackageLoader, select_autoescape

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
# Begin application
##############################################################################

def get_host_config(client):
    for hostname, host in config.get('hosts').items():
        for ifname, interface in host.get('interfaces').items():
            if interface.get('mac') == client:
                return hostname, host
    raise HTTPException(status_code=404, detail="Host not found: %s" % client)


app = FastAPI(title=__name__)
env = Environment(
    loader=PackageLoader(__name__),
    autoescape=select_autoescape()
)


@app.get("/osconfig/{client}")
async def osconfig(client):
    hostname, host = get_host_config(client)
    template = env.get_template("osconfig.j2")

    return Response(content=template.render({
        'install': host.get('install'),
        'install_to': host.get('install_to'),
        'config': host.get('config')
    }), media_type="text/string")


@app.get("/network-config/{client}")
async def network_config(client):
    hostname, host = get_host_config(client)
    template = env.get_template("network-config.j2")

    return Response(content=template.render({
        'interfaces':  host.get('interfaces', [])
    }), media_type="text/yaml")


@app.get("/user-data/{client}")
async def user_data(client):
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
async def meta_data(client):
    hostname, host = get_host_config(client)
    template = env.get_template("meta-data.j2")

    return Response(content=template.render({
        'instance_id': uuid.uuid4(),
        'hostname': hostname
    }), media_type="text/yaml")


@app.get("/unattend/{client}")
async def unattend(client):
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
