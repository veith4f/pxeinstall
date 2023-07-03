PXEinstall
=======================
Package consists of build environment in directory 'boot' that outputs EFI grub image, signed with Secure Boot keys, gpg-signed Debian kernel, ramdisk and grub.cfg as well as web application in directory 'hostconf'. Generated ramdisk will communicate with web application during boot in order to determine parameters for installation. With each request, hostconf receives mac address of requesting client and thereby outputs specific configuration parameters for given machine. Fully automated OS installation can be done for both Linux and Windows hosts. 

In a nutshell, the idea is the following:
1. PXE boot signed bootloader 'netboot.efi.signed' that chainloads into vmlinuz/initrd.img
2. Ramdisk initrd.img contacts configurable web service, providing mac address.
3. Web service informs ramdisk of NFS share where particular image can be found.
4. Ramdisk mounts NFS share and dumps image to disk using dd.
5. Ramdisk receives configuration files (Cloudinit for Linux, Unattend.xml for Windows) from hostconf and writes files to local storage such that further configuration can happen.
6. Ramdisk restarts computer and boots from disk.

See README.md in folders 'boot' and 'hostconf' for further instructions.
