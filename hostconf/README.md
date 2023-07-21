PXEinstall - hostconf
=======================
Web service that reads yml file in order to provide parameters to hosts doing os install via PXE and custom ramdisk.


Dependencies
=======================
- docker-compose https://docs.docker.com/compose/install/
- internet connection


Certificates
=======================
Put any pre-existing key (key.pem) and certificate (cert.pem) into cert folder. If no certificate files exist, hostconf will generate and use a self-signed certificate.


Configuration
=======================
- traefik.yml in conf folder. See https://doc.traefik.io/traefik/reference/dynamic-configuration/file/.
- logging.yml in conf folder. See https://docs.python.org/3/library/logging.config.html#logging-config-fileformat.


Data Source
=======================
hostconf.yml in app directory. Copy and edit hostconf.yml-template to get started.


Logs
=======================
Visit web endpoint /log for live logging or refer to configuration in logging.yml.


API
=======================
Application will listen on port 443 and expose following endpoints which are contacted by booting ramdisk. Refer to hostconf.yml in app folder for existing hosts and interfaces.

- GET /osconfig/{mac-address}
- GET /network-config/{mac-address}
- GET /user-data/{mac-address}
- GET /meta-data/{mac-address}
- GET /unattend/{mac-address}


Usage
=======================
```
make build
``` 
Build.
```
make
``` 
Run.

