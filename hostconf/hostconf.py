from flask import Flask
from flask import request
import yaml
import os
import uuid
from yaml import SafeLoader
from jinja2 import Environment, PackageLoader, select_autoescape

if not os.path.exists('hostconf.yaml'):
    raise RuntimeError(
        "hostconf.yaml not found. See README.md for instructions.")

with open('hostconf.yaml', 'r') as f:
    app = Flask(__name__)
    LOG = app.logger
    env = Environment(
        loader=PackageLoader(__name__),
        autoescape=select_autoescape()
    )
    config = yaml.load(f, Loader=SafeLoader)

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
        template = env.get_template("osconfig")
        return return_if_found(host,
                               lambda host: template.render({
                                   'install': host.get('install'),
                                   'install_to': host.get('install_to'),
                                   'config': host.get('config')
                               }))

    @app.route("/network-config/<client>")
    def network_config(client):
        hostname, host = get_host_config(client)
        template = env.get_template("network-config")
        return return_if_found(host,
                               lambda host: template.render({
                                   'interfaces':  host.get('interfaces', default=[])
                               }))

    @app.route("/user-data/<client>")
    def user_data(client):
        hostname, host = get_host_config(client)
        template = env.get_template("user-data")
        return return_if_found(host,
                               lambda host: template.render({
                                   'hostname': hostname,
                                   'users': host.get('users', default=[]),
                                   'groups': host.get('groups', default=[]),
                                   'root_pw': host.get('root_pw', default=None),
                                   'run_cmds': host.get('run_cmds', default=[]),
                                   'is_router': host.get('is_router', default=False)
                               }))

    @app.route("/meta-data/<client>")
    def meta_data(client):
        hostname, host = get_host_config(client)
        template = env.get_template("meta-data")
        return return_if_found(host,
                               lambda host: template.render({
                                   'instance_id': uuid.uuid4(),
                                   'hostname': hostname
                               }))

    @app.route("/unattend/<client>")
    def unattend(client):
        hostname, host = get_host_config(client)
        template = env.get_template("Unattend.xml")
        return return_if_found(host,
                               lambda host: template.render({
                                   'hostname': hostname,
                                   'interfaces': host.get('interfaces', default=[])
                               }))
