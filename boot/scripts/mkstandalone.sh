#!/bin/bash

########################################################
# PHASE 0 - sanity checks and clean slate
########################################################

SECUREBOOT_DB_KEY="/root/sbkeys/db.key"
SECUREBOOT_DB_CRT="/root/sbkeys/db.crt"
CONF_GRUB_CFG="/root/conf/grub.cfg"
CONF_GPG_CFG="/root/conf/gpg.cfg"

if [ ! -f "$SECUREBOOT_DB_KEY" ]; then
  echo "Secure Boot db.key not existing in directory sbkeys. See README for details."
  exit 1
fi
if [ ! -f "$SECUREBOOT_DB_CRT" ]; then
  echo "Secure Boot db.crt not existing in directory sbkeys. See README for details."
  exit 1
fi
if [ ! -f "$CONF_GRUB_CFG" ]; then
  echo "grub.cfg not found in conf directory. See README for details."
  exit 1
fi
if [ ! -f "$CONF_GPG_CFG" ]; then
  echo "gpg.cfg not found in conf directory. See README for details."
  exit 1
fi

find /root/output -type f ! -name README.md -exec rm {} \;
rm -Rf /root/initrd

########################################################
# PHASE 1 - create kernel and custom ramdisk
########################################################

VMLINUZ="/root/output/vmlinuz"
INITRD="/root/output/initrd.img"
uname=$(find /boot -name vmlinuz-* | cut -d- -f2-)

cd /root
unmkinitramfs /boot/initrd.img-$uname /root/initrd
# copy init script to ramdisk folder
cp /root/scripts/initrd_init.sh initrd/init
# copy binaries
cp /usr/sbin/vgchange initrd/usr/sbin
cp /usr/sbin/lvs initrd/usr/sbin
cp /usr/sbin/pvs initrd/usr/sbin
cp /usr/sbin/vgs initrd/usr/sbin
cp /usr/sbin/lvcreate initrd/usr/sbin
cp /usr/sbin/sfdisk initrd/usr/sbin
cp /usr/sbin/mkfs.vfat initrd/usr/sbin
cp /usr/sbin/parted initrd/usr/bin
cp /usr/bin/growpart initrd/usr/bin
cp /usr/bin/flock initrd/usr/bin
cp /usr/bin/efibootmgr initrd/usr/bin
cp /usr/bin/uuidgen initrd/usr/bin
cp /usr/bin/curl initrd/usr/bin
# copy shared objects
cp /usr/lib/x86_64-linux-gnu/libfdisk.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libsmartcols.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libreadline.so.8 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libreadline.so.8.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libefivar.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libefiboot.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libparted.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libtinfo.so.6 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libdevmapper.so.1.02.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libblkid.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libselinux.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libudev.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libm.so.6 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libdl.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libuuid.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libcurl.so.4 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libz.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libnghttp2.so.14 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libidn2.so.0 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/librtmp.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libssh2.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libpsl.so.5 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libssl.so.3 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libldap-2.5.so.0 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/liblber-2.5.so.0 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libbrotlidec.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libunistring.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libgnutls.so.30 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libhogweed.so.6 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libnettle.so.8 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libgmp.so.10 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libkrb5.so.3 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libk5crypto.so.3 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libcom_err.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libsasl2.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libbrotlicommon.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libtasn1.so.6 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libkeyutils.so.1 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libresolv.so.2 initrd/usr/lib/x86_64-linux-gnu/
cp /usr/lib/x86_64-linux-gnu/libffi.so.8 initrd/usr/lib/x86_64-linux-gnu/
# copy needed fs modules
mkdir -p initrd/usr/lib/modules/$uname/kernel/fs/nls
cp -a /usr/lib/modules/$uname/kernel/fs/fat initrd/usr/lib/modules/$uname/kernel/fs
cp /usr/lib/modules/$uname/kernel/fs/nls/nls_cp437.ko initrd/usr/lib/modules/$uname/kernel/fs/nls
cp /usr/lib/modules/$uname/kernel/fs/nls/nls_cp850.ko initrd/usr/lib/modules/$uname/kernel/fs/nls
cp /usr/lib/modules/$uname/kernel/fs/nls/nls_ascii.ko initrd/usr/lib/modules/$uname/kernel/fs/nls
# copy efidisk module
mkdir -p initrd/usr/lib/modules/$uname/kernel/fs/efivarfs
cp /usr/lib/modules/$uname/kernel/fs/efivarfs/efivarfs.ko initrd/usr/lib/modules/$uname/kernel/fs/efivarfs
# copy hd drivers
cp -a /usr/lib/modules/$uname/kernel/drivers/ata initrd/usr/lib/modules/$uname/kernel/drivers
cp -a /usr/lib/modules/$uname/kernel/drivers/scsi initrd/usr/lib/modules/$uname/kernel/drivers
# copy ssl stuff
cp -a /etc/ssl initrd/
# fix log_begin_msg function
sed -i 's/"Begin: %s ... "/"Begin: %s ... \\\\n"/g' initrd/scripts/functions
# add new std log function log_msg
sed -i '10 i\\nfunction log_msg()\n{\n\t_log_msg "%s\\\\n" "$*"\n}' initrd/scripts/functions
# create mount dirs in ramdisk
mkdir -p initrd/mnt/nfs initrd/mnt/config
# create kernel and ramdisk in output dir
cd initrd
find . | cpio -o -H newc -R root:root | gzip -9 > $INITRD
cp /boot/vmlinuz-$uname $VMLINUZ
cd /root

########################################################
# PHASE 2 - create grub image
########################################################

TMP=$(mktemp -d)
TMP_GPG_KEY="$TMP/gpg.key"
TMP_GRUB_EFI="$TMP/tmp.efi"
TMP_GRUB_INITIAL="$TMP/grub-initial.cfg"
OUT_GRUB_CFG="/root/output/grub.cfg"
PASSPHRASE="--no-tty --pinentry-mode=loopback --passphrase irrelevant"

cat <<EOF > $TMP_GRUB_INITIAL
set default=0
set timeout=3

export default
export timeout

configfile "grub.cfg"

echo Could not find boot configuration.
echo Rebooting in 10 seconds.
sleep 10
reboot
EOF

gpg --batch $PASSPHRASE --gen-key $CONF_GPG_CFG 2>&1 > /dev/null
GPG_KEY=$(gpg --list-signatures | sed '4q;d' | tr -d '[:space:]')
gpg --export "$GPG_KEY" > "$TMP_GPG_KEY"

/usr/local/bin/grub-mkimage \
    --disable-shim-lock \
    --prefix "." \
    --directory="/usr/local/lib/grub/x86_64-efi" \
    --format="x86_64-efi" \
    --pubkey="$TMP_GPG_KEY" \
    --output="$TMP_GRUB_EFI" \
    --config="$TMP_GRUB_INITIAL" \
    configfile gcry_sha512 gcry_rsa echo normal linux \
    all_video reboot sleep efinet time tftp

########################################################
# PHASE 3 - sign everything
########################################################

GRUBIMAGE="/root/output/netboot.efi.signed"

cp $CONF_GRUB_CFG $OUT_GRUB_CFG
gpg $PASSPHRASE --default-key $GPG_KEY --detach-sign $OUT_GRUB_CFG
gpg $PASSPHRASE --default-key $GPG_KEY --detach-sign $VMLINUZ
gpg $PASSPHRASE --default-key $GPG_KEY --detach-sign $INITRD
# delete ephemeral gpg key - no longer needed
gpg --batch --yes --pinentry-mode=loopback --delete-secret-keys $GPG_KEY
gpg --batch --yes --pinentry-mode=loopback --delete-keys $GPG_KEY
# sign grub efi image with secure boot keys
sbsign --key "$SECUREBOOT_DB_KEY" --cert "$SECUREBOOT_DB_CRT" "$TMP_GRUB_EFI"
# copy grub efi image to output
cp "$TMP_GRUB_EFI.signed" "$GRUBIMAGE"

rm -Rf $TMP
