PXEinstall - hostconf
=======================
Web service that reads yaml file in order to provide parameters to hosts doing os install via PXE and custom ramdisk.


Dependencies
=======================
- docker-compose https://docs.docker.com/compose/install/
- internet connection


Certificates
=======================
Put any pre-existing key (key.pem) and certificate (cert.pem) into cert folder or generate with the following command. The generated certificate will have CN=hostconf.domain.tld and the IP address of first network device as subjectAltName.
```
make cert
```


Configuration
=======================
traefik.yml in conf folder. See https://doc.traefik.io/traefik/reference/dynamic-configuration/file/.


Data Source
=======================
hostconf.yaml in app directory. Copy and edit hostconf.yaml-template to get started.


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

