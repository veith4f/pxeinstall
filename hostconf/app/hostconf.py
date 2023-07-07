from flask import Flask
from schema import Schema, Optional, SchemaError, Regex, Use
import yaml
import os
import uuid
from yaml import SafeLoader
from jinja2 import Environment, PackageLoader, select_autoescape

if not os.path.exists('hostconf.yaml'):
    raise RuntimeError(
        "hostconf.yaml not found. See README.md for instructions.")

config_schema = Schema({
    "hosts": {
        str: {
            'install': str,
            'install_to': str,
            'config': str,
            'root_pw': str,
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
            Optional('run_cmds'): [str],
            Optional('groups'): [str],
        }
    }
}, ignore_extra_keys=True)

with open('hostconf.yaml', 'r') as f:
    config = yaml.load(f, Loader=SafeLoader)

    if not config_schema.is_valid(config):
        config_schema.validate(config)
        raise SchemaError("Invalid schema: hostconf.yaml")

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
                                   'interfaces': host.get('interfaces', [])
                               }))
