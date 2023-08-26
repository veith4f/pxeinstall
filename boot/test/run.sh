#!/bin/sh

OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.secboot.fd"
OVMF_VARS_SRC="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
OVMF_VARS="/tmp/$(basename $OVMF_VARS_SRC)"

if [ ! -e "${OVMF_VARS}" ]; then
  cp "${OVMF_VARS_SRC}" "${OVMF_VARS}"
fi

[ ! -f /tmp/sda.raw ] && qemu-img create /tmp/sda.raw 8G

qemu-system-x86_64 \
    -m 1024 \
    -bios /usr/share/ovmf/OVMF.fd \
    -netdev user,id=net0,net=192.168.178.78/24,tftp=/tftp,bootfile=/netboot.efi.signed \
    -device virtio-net-pci,netdev=net0,mac=ee:4a:6a:a1:04:47 \
    -hda /tmp/sda.raw \
    -object rng-random,id=virtio-rng0,filename=/dev/urandom \
    -machine q35,smm=on \
    -global driver=cfi.pflash01,property=secure,value=on \
    -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on \
    -drive if=pflash,format=raw,unit=1,file="${OVMF_VARS}" \
    -nographic \
    -boot n \
    $@

#rm -f /tmp/sda.raw