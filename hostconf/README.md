PXEinstall - hostconf
=======================
Web service that reads yaml file in order to provide parameters to hosts doing os install via PXE and custom ramdisk.


Dependencies
=======================
See requirements.txt. Install with pip or with your os's package manager.
```
pip3 install -r requirements.txt
```


Data Source
=======================
hostconf.yaml in base directory. Copy and edit hostconf.yaml-template to get started.


Usage
=======================
Run externally visible web application on port 5000.
```
gunicorn -w 2 -b 0.0.0.0:5000 'hostconf:app'
```
Run web application locally on port 5000. Choice option in reverse proxy setup.
```
gunicorn -w 2 -b localhost:5000 'hostconf:app'
```