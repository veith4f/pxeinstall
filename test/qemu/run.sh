#!/bin/sh

[ ! -f /disk/sda.raw ] && qemu-img create /disk/sda.raw 512M

qemu-system-x86_64 \
    -m 1024 \
    -bios OVMF.fd \
    -netdev user,id=net0,net=192.168.178.78/24,tftp=/tftp,bootfile=/netboot.efi.signed \
    -device virtio-net-pci,netdev=net0,mac=ee:4a:6a:a1:04:47 \
    -hda /disk/sda.raw \
    -object rng-random,id=virtio-rng0,filename=/dev/urandom \
    -device virtio-rng-pci,rng=virtio-rng0,id=rng0,bus=pci.0,addr=0x9 \
    -nographic \
    -boot n \
    $@
