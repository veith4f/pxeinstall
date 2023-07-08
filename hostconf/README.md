PXEinstall - hostconf
=======================
Web service that reads yaml file in order to provide parameters to hosts doing os install via PXE and custom ramdisk.


Dependencies
=======================
- docker-compose https://docs.docker.com/compose/install/
- internet connection


Certificates
=======================
Put any pre-existing key (key.pem) and certificate (cert.pem) into cert folder or generate with the following command. The generated certificate will have CN=hostconf.domain.tld.
```
make cert
```


Configuration
=======================
- traefik.yml in conf folder. See https://doc.traefik.io/traefik/reference/dynamic-configuration/file/.
- logging.yml in conf folder. See https://docs.python.org/3/library/logging.config.html#logging-config-fileformat.


Data Source
=======================
hostconf.yaml in app directory. Copy and edit hostconf.yaml-template to get started.


Logs
=======================
Visit web endpoint /log for live logging or refer to configuration in logging.yml.


API
=======================
Application will listen on port 443 and expose following endpoints which are contacted by booting ramdisk. Refer to hostconf.yaml in app folder for existing hosts and interfaces.

- GET /osconfig/{mac-address}
- GET /network-config/{mac-address}
- GET /user-data/{mac-address}
- GET /meta-data/{mac-address}
- GET /unattend/{mac-address}


Usage
=======================
```
docker-compose build
``` 
Build.
```
docker-compose up 
``` 
Run.
```
make
```
Build and Run in sequence. Rebuild only happens upon change to any of the files in docker directory so this is usually just as fast as Run.

