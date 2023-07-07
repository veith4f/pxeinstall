PXEinstall - boot
=======================
This is a build environment that outputs grub efi image, kernel, ramdisk and configuration files.


Dependencies
=======================
- docker-compose https://docs.docker.com/compose/install/
- internet connection


Configuration
=======================
Copy and edit templates in cfg dir according to your needs. 

'grub.cfg'
-----------------------
Definition of boot menu, kernel, ramdisk selection and cmdline with parameters.
- Parameter 'hostconf' indicates where accompanying web service is found. In most cases, will be same as tftp server given in template. 
- Parameter 'client' provides ramdisk's init script with mac adress of network adapter doing PXE. 
- Parameter 'debug' can be added to kernel cmdline, which will cause booting ramdisk to pause at set positions and allow dropping to shell or continue on keystrike which is useful for debugging purposes. 
- Parameter 'insecure' allows querying web service with insecure certificate, i.e. curl -k option.

'gpg.cfg'
-----------------------
Concerns parameters of an ephemeral gpg key that is used to sign kernel, ramdisk and grub.cfg. Specified name and email address will appear in signatures.


Secure Boot Keys
=======================
In order to create netboot.efi.signed, Secure Boot keys are required. Copy db.key and db.crt into sbkeys directory of this project.


Usage
=======================
```
docker-compose build
``` 
Creates build environment. Will take a while.
```
docker-compose up 
``` 
Creates custom signed ramdisk, kernel and grub image in output directory. Scripts in 'scripts' directory are run by docker-compose up. Changes to these only require re-running this command.

```
make
```
For convenience, there is also a GNU Makefile that executes both commands in sequence. Lengthy rebuild of build environment is only triggered if there are changes to buildenv/Docker, so this is usually just as fast as running docker-compose up.


Output
=======================
After successfully running docker-compose build and docker-compose up, output folder will contain following files, all of which have to be placed in server directory (usually /srv/tftp) of tftp server configured as next-server in dhcp.
- netboot.efi.signed: Grub efi boot image signed with supplied secure boot keys.
- vmlinuz: Debian 12 Linux kernel signed with gpg key, public side of which has been compiled into netboot.efi.signed. Private side already deleted.
- vmlinuz.sig: GPG signature file.
- initrd.img: Installer ramdisk signed with gpg key, public side of which has been compiled into netboot.efi.signed. The private side already deleted.
- intrd.img.sig: GPG signature file.
- grub.cfg: Grub cfg file containing boot entries as specified in conf directory.
- grub.cfg.sig: GPG signature file.

