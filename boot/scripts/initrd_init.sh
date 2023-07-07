#!/bin/sh

# Default PATH differs between shells, and is not automatically exported
# by klibc dash.  Make it consistent.
export PATH=/sbin:/usr/sbin:/bin:/usr/bin

[ -d /dev ] || mkdir -m 0755 /dev
[ -d /root ] || mkdir -m 0700 /root
[ -d /sys ] || mkdir /sys
[ -d /proc ] || mkdir /proc
[ -d /tmp ] || mkdir /tmp
mkdir -p /var/lock
mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
mount -t proc -o nodev,noexec,nosuid proc /proc


# Note that this only becomes /dev on the real filesystem if udev's scripts
# are used; which they will be, but it's worth pointing out
mount -t devtmpfs -o nosuid,mode=0755 udev /dev

# Prepare the /dev directory
[ ! -h /dev/fd ] && ln -s /proc/self/fd /dev/fd
[ ! -h /dev/stdin ] && ln -s /proc/self/fd/0 /dev/stdin
[ ! -h /dev/stdout ] && ln -s /proc/self/fd/1 /dev/stdout
[ ! -h /dev/stderr ] && ln -s /proc/self/fd/2 /dev/stderr

mkdir /dev/pts
mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true

# Export the dpkg architecture
export DPKG_ARCH=
. /conf/arch.conf

# Set modprobe env
export MODPROBE_OPTIONS="-qb"

# Export relevant variables
export ROOT=
export ROOTDELAY=
export ROOTFLAGS=
export ROOTFSTYPE=
export IP=
export DEVICE=
export BOOT=
export BOOTIF=
export UBIMTD=
export break=
export init=/sbin/init
export readonly=y
export rootmnt=/root
export debug=
export panic=
export blacklist=
export resume=
export resume_offset=
export noresume=
export drop_caps=
export fastboot=n
export forcefsck=n
export fsckfix=
export quiet=
export client=
export hostconf=
export debug=


# Bring in the main config
. /conf/initramfs.conf
for conf in conf/conf.d/*; do
    [ -f "${conf}" ] && . "${conf}"
done
. /scripts/functions

mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run
mkdir -m 0700 /run/initramfs

if [ -n "$log_output" ]; then
    exec >$log_output 2>&1
    unset log_output
fi


##############################################################
## BEGIN FLASH CLOUD IMAGE ROUTINE
##

continue_or_shell()
{
    [ ! -z "$debug" ] \
      && read -p "Press enter to continue or sh to enter shell: " IN \
      && [ "sh" == "$IN" ] && sh
}

# Parse command line options
for x in $(cat /proc/cmdline); do
    case $x in
        hostconf=*)
            hostconf=${x#hostconf=}
            ;;
        client=*)
            client=${x#client=}
            ;;
        debug)
            debug="y"
            ;;
        esac
done

maybe_break top

# Don't do log messages here to avoid confusing graphical boots
run_scripts /scripts/init-top
. /scripts/local
. /scripts/nfs

maybe_break modules

log_begin_msg "Loading essential drivers"
[ -n "${netconsole}" ] && /sbin/modprobe netconsole netconsole="${netconsole}"
load_modules
modprobe af_packet
kos="fat vfat nls_cp437 nls_cp850 nls_ascii efivarfs"
for ko in $kos; do
    insmod $(find /usr/lib/modules -name $ko.ko)
done
log_end_msg

starttime="$(_uptime)"
starttime=$((starttime + 1)) # round up
export starttime

continue_or_shell

log_begin_msg "Configure networking"
configure_networking
log_end_msg

continue_or_shell

log_begin_msg "Query hostconf service for installation parameters"
osconfig=$(curl -k $hostconf/osconfig/$client)
install=$(echo "$osconfig" | sed '1q;d')
install_to=$(echo "$osconfig" | sed '2q;d')
config=$(echo "$osconfig" | sed '3q;d')
log_end_msg

continue_or_shell

log_begin_msg "Current layout of disk $install_to"
parted $install_to print
log_end_msg

continue_or_shell

log_begin_msg "Preparing local disk"
vgchange -an
dd if=/dev/zero of=$install_to bs=1M count=10
echo -e "yes\n" | parted $install_to mklabel gpt
log_end_msg

continue_or_shell

install_nfs=$(echo $install | sed 's|nfs://||g')
fields=$(echo $install_nfs | tr -dc "/"| wc -c)
mountpath=$(echo $install_nfs | cut -d/ -f1-$fields)
image=$(echo $install_nfs | cut -d/ -f$(($fields + 1)))
log_begin_msg "Mounting $mountpath to flash $image"
nfsmount $mountpath /mnt/nfs
log_end_msg

continue_or_shell

log_begin_msg "Flashing Cloud-Image to disk"
dd if=/mnt/nfs/$image of=$install_to
log_end_msg

continue_or_shell

log_begin_msg "Fix GPT header and probe for partitions"
sleep 1
echo -e "fix\n" | parted $install_to "print"
partprobe $install_to
vgchange -ay
VGNAME=$(vgs --no-headings | cut -d' ' -f 3)
log_end_msg

continue_or_shell

if [[ "$config" == "cloudinit" ]]; then
    # vfat file systems with disk label "CIDATA" serve as config drives.
    # https://cloudinit.readthedocs.io/en/22.2/topics/datasources/nocloud.html
    log_begin_msg "Cloud-Init configuration: Creating cidata and resizing root partition."
    if [ ! -z "$VGNAME" ]; then # handle image with lvm
        PVDEV=$(pvs | tail -n 1 | cut -d' ' -f 3 | cut -d/ -f 3)
        if [ ! -z "$PVDEV" ]; then
          growpart /dev/$(echo $PVDEV | rev | cut -c2- | rev) $(echo $PVDEV | rev | cut -c1)
        fi
        lvcreate -L 4M -n cidata $VGNAME
        yes | mkfs.vfat -n "CIDATA" /dev/$VGNAME/cidata
        mount -t vfat /dev/$VGNAME/cidata /mnt/config
    else # handle image without lvm
        echo -e "ignore\n" | parted $install_to -- mkpart CIDATA fat32 -4MB -0
        partprobe $install_to
        PARTNUM=$(cat /proc/partitions | tail -n 1 | tr -d '[:space:]' | tail -c 1)
        yes | mkfs.vfat -n "CIDATA" "${install_to}$PARTNUM"
        growpart $install_to $(expr $PARTNUM - 1)
        mount -t vfat "${install_to}$PARTNUM" /mnt/config
    fi
    log_end_msg

    continue_or_shell

    log_begin_msg "Downloading cloud-init configuration files to config-drive"
        curl -k $hostconf/meta-data/$client > /mnt/config/meta-data
        curl -k $hostconf/network-config/$client > /mnt/config/network-config
        curl -k $hostconf/user-data/$client > /mnt/config/user-data
        umount /mnt/config
    log_end_msg

elif [[ "$config" == "unattend" ]]; then
    log_begin_msg "Unattended installation: Writing unattend.xml to disk."
    mount "${install_to}4" /mnt/config
    curl -k $hostconf/unattend/$client > /mnt/config/unattend.xml
    umount /mnt/config
    log_end_msg
else
    echo "Configuration '$config' is not supported."
fi

continue_or_shell

log_begin_msg "Unmounting nfs"
umount /mnt/nfs
log_end_msg

continue_or_shell

log_begin_msg "Arrange EFI boot order to boot disk on next boot"
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
mount ${install_to}1 /mnt
if [[ "$config" == "cloudinit" ]]; then # linux case
    if [ -z "$(efibootmgr | grep Linux)" ]; then
        SHIM=$(find /mnt -name shimx64.efi | cut -d/ -f 3- | sed 's|/|\\|g')
        efibootmgr --create --disk=$install_to --part=1 --label=Linux --loader=$SHIM
    fi
    NEXT=$(efibootmgr | grep Linux | cut -d'*' -f1 | tr -d '[:space:]' | tail -c 4)
    efibootmgr --bootnext $NEXT
else # windows case
    echo "Windows case not handled yet"
fi
umount /mnt
umount /sys/firmware/efi/efivars
log_end_msg

continue_or_shell

reboot -f

##
## END FLASH CLOUD IMAGE ROUTINE
##############################################################
