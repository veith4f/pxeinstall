#!/bin/sh

cp /secureboot/OVMF_VARS_4M.sopra.fd /tmp/OVMF_VARS_4M.sopra.fd

rm -f /tmp/log.txt
qemu-system-x86_64 \
    -m 1024 \
    -bios /usr/share/ovmf/OVMF.fd \
    -netdev user,id=net0,net=192.168.178.78/24,tftp=/tftp,bootfile=/netboot.efi.signed \
    -device virtio-net-pci,netdev=net0,mac=ee:4a:6a:a1:04:47 \
    -machine q35,smm=on \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd,readonly=on \
    -drive if=pflash,format=raw,unit=1,file=/tmp/OVMF_VARS_4M.sopra.fd \
    -nographic \
    -boot n \
    $@ > /tmp/log.txt &

(tail -f /tmp/log.txt | grep -q "BOOT_IMAGE=" && kill $(pidof qemu-system-x86_64) && kill $(pidof tail) && \
    echo && \
    echo "##############################################################################" && \
    echo "Success: Signed kernel loaded" && \
    echo "##############################################################################" && \
    echo) &

(sleep 35 && kill $(pidof qemu-system-x86_64) && kill $(pidof tail) && \
    echo && \
    echo "##############################################################################" && \
    echo "Failure: Signed kernel not loaded" && \
    echo "##############################################################################" && \
    echo) &

tail -f /tmp/log.txt
