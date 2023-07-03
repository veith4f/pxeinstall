from flask import Flask
from flask import request
import yaml
import os
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
                    return host
        return None

    def return_if_found(host, fn):
        if host is not None:
            return fn(host), 200
        else:
            return "Not found", 404

    @app.route("/install/<client>")
    def install(client):
        host = get_host_config(client)
        return return_if_found(host,
                               lambda host: host.get('install'))

    @app.route("/install_to/<client>")
    def install_to(client):
        host = get_host_config(client)
        return return_if_found(host,
                               lambda host: host.get('install_to'))

    @app.route("/config/<client>")
    def type(client):
        host = get_host_config(client)        
        return return_if_found(host,
                               lambda host: host.get('config'))

    @app.route("/network-config/<client>")
    def network_config(client):
        host = get_host_config(client)
        template = env.get_template("network-config")
        return return_if_found(host,
                               lambda host: template.render({
                                   'interfaces': host.get('interfaces')
                               }))

    @app.route("/user-data/<client>")
    def user_data(client):
        host = get_host_config(client)
        template = env.get_template("user-data")
        return return_if_found(host,
                               lambda host: template.render({
                                   'users': host.get('users'),
                                   'groups': host.get('groups'),
                                   'root_pw': host.get('root_pw'),
                                   'run_cmds': host.get('run_cmds'),
                                   'is_router': host.get('is_router')
                               }))

    @app.route("/unattend/<client>")
    def unattend(client):
        host = get_host_config(client)
        template = env.get_template("Unattend.xml")
        return return_if_found(host,
                               lambda host: template.render({
                               }))
