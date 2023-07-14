#!/bin/sh

##############################################################
## Boilerplate

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
export quiet=

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

# Don't do log messages here to avoid confusing graphical boots
run_scripts /scripts/init-top
. /scripts/local
. /scripts/nfs

starttime="$(_uptime)"
starttime=$((starttime + 1)) # round up
export starttime

##############################################################
## Parameters & Definitions

export client=""
export hostconf=""
export insecure=""
export debug=""

# Parse command line options
for x in $(cat /proc/cmdline); do
  case $x in
    hostconf=*)
      hostconf=${x#hostconf=}
      ;;
    client=*)
      client=${x#client=}
      ;;
    insecure)
      insecure="-k"
      ;;
    debug)
      debug="y"
      ;;
    esac
done

hostconf_get()
{
  while : ; do
    if curl "$insecure" $hostconf/$1/$client; then
      break
    fi
    if [ "$debug" == "y" ]; then
      read -p "Could not connect to hostconf. Press enter to try again or r to reboot: " IN
      [ "r" == "$IN" ] && reboot -f
    else
      log_msg "Could not connect to hostconf. Will reboot." && sleep 10 && reboot -f
    fi
  done
}

hostconf_put()
{
  while : ; do
    if curl "$insecure" -X PUT $hostconf/$1/$client -d "$2"; then
      break
    fi
    if [ "$debug" == "y" ]; then
      read -p "Could not connect to hostconf. Press enter to try again or r to reboot: " IN
      [ "r" == "$IN" ] && reboot -f
    else
      log_msg "Could not connect to hostconf. Will reboot." && sleep 10 && reboot -f
    fi
  done
}

begin()
{
  [ "$debug" == "y" ] && sleep 1
  log_msg ""
  log_begin_msg $1
  [ ! -z "$debug" ] \
    && read -p "Press enter to continue or sh to enter shell: " IN \
    && [ "sh" == "$IN" ] && sh
}

end()
{
  [ "$debug" == "y" ] && sleep 1
  log_end_msg
}

##############################################################
## Begin install routine

begin "Loading essential drivers"
[ -n "${netconsole}" ] && /sbin/modprobe netconsole netconsole="${netconsole}"
load_modules
modprobe af_packet
kos="fat vfat nls_cp437 nls_cp850 nls_ascii efivarfs"
for ko in $kos; do
  insmod $(find /usr/lib/modules -name $ko.ko)
done
end

begin "Configure networking"
configure_networking
end

begin "Query hostconf service for installation parameters"
osconfig=$(hostconf_get osconfig)
install=$(echo "$osconfig" | sed '1q;d')
install_to=$(echo "$osconfig" | sed '2q;d')
config=$(echo "$osconfig" | sed '3q;d')
install_nfs=$(echo $install | sed 's|nfs://||g')
fields=$(echo $install_nfs | tr -dc "/"| wc -c)
mountpath=$(echo $install_nfs | cut -d/ -f1-$fields)
image=$(echo $install_nfs | cut -d/ -f$(($fields + 1)))
log_msg "Image:       $image"
log_msg " - on NFS:   nfs://$mountpath"
log_msg "Local Disk:  $install_to"
log_msg "Config:      $config"
end

begin "Print layout of local disk $install_to"
echo -e "ignore\n" | parted $install_to print
end

begin "Preparing local disk"
vgchange -an
dd if=/dev/zero of=$install_to bs=1M count=10
echo -e "yes\n" | parted $install_to mklabel gpt
end

begin "Mounting $mountpath to flash $image"
nfsmount $mountpath /mnt/nfs
end

begin "Flashing Cloud-Image to disk"
dd if=/mnt/nfs/$image of=$install_to
end

begin "Fix GPT header and probe for partitions"
sleep 1
echo -e "fix\n" | parted $install_to "print"
sleep 1
partprobe $install_to
vgchange -ay
VGNAME=$(vgs --no-headings | cut -d' ' -f 3)
end

if [[ "$config" == "cloudinit" ]]; then
  # vfat file systems with disk label "CIDATA" serve as config drives.
  # https://cloudinit.readthedocs.io/en/22.2/topics/datasources/nocloud.html
  begin "Creating cidata drive and resizing root partition."
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
  end

  begin "Downloading Cloud-Init configuration files to cidata drive."
  hostconf_get meta-data > /mnt/config/meta-data
  hostconf_get network-config > /mnt/config/network-config
  hostconf_get user-data > /mnt/config/user-data
  umount /mnt/config
  end

elif [[ "$config" == "unattend" ]]; then
  begin "Unattended installation: Writing unattend.xml to disk."
  mount $(ls ${install_to}* | sed '5q;d') /mnt/config
  if [ -f /mnt/config/unattend.xml.j2 ]; then
      hostconf_put unattend "$(cat /mnt/config/unattend.xml.j2)" > /mnt/config/unattend.xml
  else
      hostconf_get unattend > /mnt/config/unattend.xml
  fi
  umount /mnt/config
  end

else
  log_msg "Configuration '$config' is not supported."

fi

begin "Unmounting nfs"
umount /mnt/nfs
end

begin "Arrange EFI boot order to boot disk on next boot"
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
NEXT=
if [ "$config" == "cloudinit" ]; then # linux case
  if [ -z "$(efibootmgr | grep Linux)" ]; then
    mount $(ls ${install_to}* | sed '2q;d') /mnt
    SHIM=$(find /mnt -name shimx64.efi | cut -d/ -f 3- | sed 's|/|\\|g' | head -n 1)
    if [ ! -z "$SHIM" ]; then
      efibootmgr --create --disk=$install_to --part=1 --label=Linux --loader=$SHIM
    fi
    umount /mnt
  fi
  NEXT=$(efibootmgr | grep Linux | cut -d'*' -f1 | tr -d '[:space:]' | tail -c 4 | head -n 1)

elif [ "$config" == "unattend" ]; then # windows case
  if [ -z "$(efibootmgr | grep WinInstall)" ]; then
    mount $(ls ${install_to}* | sed '5q;d') /mnt
    BMGR="/mnt/bootmgr.efi"
    if [ -f "$BMGR" ]; then
      efibootmgr --create --disk=$install_to --part=4 --label=WinInstall --loader=$BMGR
    fi
    umount /mnt
  fi
  NEXT=$(efibootmgr | grep WinInstall | cut -d'*' -f1 | tr -d '[:space:]' | tail -c 4 | head -n 1)

else
  log_msg "Setting boot order for config type '$config' is unsupported."

fi
if [ ! -z "$NEXT" ]; then
  efibootmgr --bootnext $NEXT
fi
umount /sys/firmware/efi/efivars
end

begin "Process completed. Will reboot."
reboot -f
end
