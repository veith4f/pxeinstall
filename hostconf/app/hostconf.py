from flask import Flask
from schema import Schema, SchemaError, Regex
import yaml
import os
import uuid
from yaml import SafeLoader
from jinja2 import Environment, PackageLoader, select_autoescape

if not os.path.exists('hostconf.yaml'):
    raise RuntimeError(
        "hostconf.yaml not found. See README.md for instructions.")

config_schema = Schema({
    "hosts": [
        Regex(r'^([a-z]+[0-9-_]\.?[a-z]+[0-9])+$'): {
            is_router: bool,
            run_cmds: list(str),
            install: str,
            install_to: str
            root_pw: str
        }
    ]
})

with open('hostconf.yaml', 'r') as f:
    config = yaml.load(f, Loader=SafeLoader)

    if not schema.is_valid(conf):
        raise RuntimeError("Invalid schema: hostconf.yaml")

    app = Flask(__name__)
    env = Environment(
        loader=PackageLoader(__name__),
        autoescape=select_autoescape()
    )

    def get_host_config(client):
        for hostname, host in config.get('hosts').items():
            for ifname, interface in host.get('interfaces').items():
                if interface.get('mac') == client:
                    return hostname, host
        return None, None

    def return_if_found(host, fn):
        if host is not None:
            return fn(host), 200
        else:
            return "Not found", 404

    @app.route("/osconfig/<client>")
    def install(client):
        hostname, host = get_host_config(client)
        template = env.get_template("osconfig.j2")
        return return_if_found(host,
                               lambda host: template.render({
                                   'install': host.get('install'),
                                   'install_to': host.get('install_to'),
                                   'config': host.get('config')
                               }))

    @app.route("/network-config/<client>")
    def network_config(client):
        hostname, host = get_host_config(client)
        template = env.get_template("network-config.j2")
        return return_if_found(host,
                               lambda host: template.render({
                                   'interfaces':  host.get('interfaces', [])
                               }))

    @app.route("/user-data/<client>")
    def user_data(client):
        hostname, host = get_host_config(client)
        template = env.get_template("user-data.j2")
        return return_if_found(host,
                               lambda host: template.render({
                                   'hostname': hostname,
                                   'users': host.get('users', []),
                                   'groups': host.get('groups', []),
                                   'root_pw': host.get('root_pw', None),
                                   'run_cmds': host.get('run_cmds', []),
                                   'is_router': host.get('is_router', False)
                               }))

    @app.route("/meta-data/<client>")
    def meta_data(client):
        hostname, host = get_host_config(client)
        template = env.get_template("meta-data.j2")
        return return_if_found(host,
                               lambda host: template.render({
                                   'instance_id': uuid.uuid4(),
                                   'hostname': hostname
                               }))

    @app.route("/unattend/<client>")
    def unattend(client):
        hostname, host = get_host_config(client)
        template = env.get_template("unattend.xml.j2")
        return return_if_found(host,
                               lambda host: template.render({
                                   'hostname': hostname,
                                   'users': host.get('users', []),
                                   'groups': host.get('groups', []),
                                   'root_pw': host.get('root_pw', None),
                                   'run_cmds': host.get('run_cmds', []),
                                   'is_router': host.get('is_router', False),
                                   'interfaces': host.get('interfaces', [])
                               }))
