#! @bash@/bin/sh -e

export PATH=@bash@/bin:@coreutils@/bin:@findutils@/bin:@utillinux@/bin:@utillinux@/sbin:@e2fsprogs@/sbin:@grub@/sbin:@sysvinitPath@/sbin

kernel=@kernel@

sysvinitPath=@sysvinitPath@
bootPath=@bootPath@
modutils=@modutils@
hotplug=@hotplug@

echo mounting special filesystems

mount -t proc proc /proc
mount -t sysfs sys /sys

# make a complete /dev filesystem
# ripped permissions and everything from anaconda (loader2/devices.h)

echo making device nodes

# consoles

#mknod -m 0600 /dev/console c 5 1
mknod -m 0600 /dev/ttyS0 c 4 64
mknod -m 0600 /dev/ttyS1 c 4 65
mknod -m 0600 /dev/ttyS2 c 4 66
mknod -m 0600 /dev/ttyS3 c 4 67

# base UNIX devices
mknod -m 0600 /dev/mem c 1 1
mknod -m 0666 /dev/null c 1 3
mknod -m 0666 /dev/zero c 1 5

# tty
mknod -m 0600 /dev/tty c 5 0
mknod -m 0600 /dev/tty0 c 4 0
mknod -m 0600 /dev/tty1 c 4 1
mknod -m 0600 /dev/tty2 c 4 2
mknod -m 0600 /dev/tty3 c 4 3
mknod -m 0600 /dev/tty4 c 4 4
mknod -m 0600 /dev/tty5 c 4 5
mknod -m 0600 /dev/tty6 c 4 6
mknod -m 0600 /dev/tty7 c 4 7
mknod -m 0600 /dev/tty8 c 4 8
mknod -m 0600 /dev/tty9 c 4 9

mkdir -m 0755 /dev/pts
mknod -m 0666 /dev/ptmx c 5 2

# random

mknod -m 0644 /dev/random c 1 8
mknod -m 0644 /dev/urandom c 1 9

mknod -m 0660 /dev/hda b 3 0
mknod -m 0660 /dev/hda1 b 3 1
mknod -m 0660 /dev/hda2 b 3 2
mknod -m 0660 /dev/hda3 b 3 3

mknod -m 0660 /dev/hdb b 3 64
mknod -m 0660 /dev/hdb1 b 3 65
mknod -m 0660 /dev/hdb2 b 3 66
mknod -m 0660 /dev/hdb3 b 3 67

mknod -m 0660 /dev/hdc b 22 0
mknod -m 0660 /dev/hdc1 b 22 1
mknod -m 0660 /dev/hdc2 b 22 2
mknod -m 0660 /dev/hdc3 b 22 3

mknod -m 0660 /dev/hdd b 22 64
mknod -m 0660 /dev/hdd1 b 22 65
mknod -m 0660 /dev/hdd2 b 22 66
mknod -m 0660 /dev/hdd3 b 22 67

#mknod -m 0660 /dev/sda b 8 0
#mknod -m 0660 /dev/sda1 b 8 1
#mknod -m 0660 /dev/sda2 b 8 2
#mknod -m 0660 /dev/sda3 b 8 3

mknod -m 0600 /dev/initctl p

targetdrive=/dev/hda
device=${targetdrive}1
mkfs.ext2 ${device}
mkswap ${targetdrive}2


#if ! test -n "$1"
#then
#    echo "need harddisk device for installing!"
#    exit
#else
#    device=$1
#fi


make_dir() {
    mode=$1
    name=$2
    echo creating $name...
    if ! test -d $root/$name; then mkdir $root/$name; fi
    chmod $mode $root/$name
}


touch_file() {
    name=$1
    echo touching $name...
    if ! test -d $root/$name; then touch $root/$name; fi
}
root=/tmp/mnt

mkdir -p $root

echo mounting the target drive

mount -t ext2 $device $root

##
## Create a directory tree on the installation disk.
##

echo creating file system hierarchy on target drive

make_dir 00755 /bin
make_dir 00755 /boot
make_dir 00755 /dev
make_dir 00755 /etc # global non-constant configuration
make_dir 00755 /etc-secret
make_dir 00755 /home
make_dir 00755 /home/root
make_dir 00755 /lib
make_dir 00755 /lib/modules
make_dir 00755 /mnt
make_dir 00755 /mnt/host
make_dir 00755 /nix
make_dir 00755 /nix/store
make_dir 00755 /nix/var
make_dir 00755 /nix/var/nix
make_dir 00755 /nix/var/nix/db
make_dir 00755 /nix/var/nix/manifests
make_dir 00755 /nix/var/log
make_dir 00755 /nix/var/log/nix
make_dir 00755 /nixpkgs
make_dir 00755 /nixpkgs/trunk
make_dir 00755 /proc
make_dir 00755 /sbin
make_dir 00755 /sys
make_dir 01777 /tmp
make_dir 00755 /usr
make_dir 00755 /var
make_dir 00755 /var/log
make_dir 00755 /var/run
make_dir 00755 /var/spool
make_dir 00755 /var/state
make_dir 00755 /var/state/dhcp
make_dir 00755 /var/tmp

##
## Add a few devices to /dev on the install disk. This is by far complete.
##

echo making device nodes on target drive

mknod $root/dev/null c 1 3
mknod -m 0600 $root/dev/console c 5 1
mknod -m 0600 $root/dev/tty c 5 0
mknod -m 0600 $root/dev/tty0 c 4 0
mknod -m 0600 $root/dev/tty1 c 4 1
mknod -m 0444 $root/dev/urandom c 1 9

#touch_file /etc/passwd
#touch_file /etc/shadow
#touch_file /etc/group

rm -f $root/etc/mtab
#ln -s /proc/mounts $root/etc/mtab

#cat /proc/mounts

## Probe for CD device which contains our CD here and mount /nix and
## /nixpkgs from it inside the ramdisk. Anaconda uses kudzu for this.
## Find out how Knoppix and SUSE do this...

#devices=$(grep -r cdrom hd* | cut -d '/' -f 1 | sort | uniq)
#echo devices ${devices}

DEVICES="/dev/hd?"

for i in ${DEVICES}
do
echo "Looking for CDROM in: $i"
if mount -t iso9660 $i /cdrom >/dev/null 2>&1
then
  echo "cdrom contents"
  ls /cdrom
  if test -f /cdrom/NIXOS
  then
    cddevice=$i
    echo "Accessing NixOS CDROM at $i"
  break
fi
#umount /cdrom
fi
done

echo switch to /nix and /nixpkgs from CD

ln -s /cdrom/nixpkgs /nixpkgs
mount --bind /cdrom/nix /nix


export NIX_DATA_DIR=$root/nix/share
export NIX_LOG_DIR=$root/nix/log/nix
export NIX_STATE_DIR=$root/nix/var/nix
export NIX_CONF_DIR=$root/nix/etc
NIX_CMD_PATH=@NIX_CMD_PATH@/bin

echo initialising Nix DB...
#/nix/bin/nix-store --init
$NIX_CMD_PATH/nix-store --init

echo verifying Nix DB...
$NIX_CMD_PATH/nix-store --verify

echo copying nixpkgs...
cp -fLa /cdrom/pkgs $root/nixpkgs/trunk

make_dir 0755 /tmp/scripts
cp -fa /cdrom/scripts $root/tmp

#echo adding manifest
#$NIX_CMD_PATH/nix-pull $manifest

echo adding packages

export NIX_ROOT=$root
unset NIX_DATA_DIR
unset NIX_LOG_DIR
unset NIX_STATE_DIR
unset NIX_CONF_DIR

#storeExpr=$(echo '(import /tmp/scripts/pkgs.nix).everything' | $NIX_CMD_PATH/nix-instantiate -v -v -)
#storeExpr=$(echo '(import ./pkgs.nix).everything' | $NIX_CMD_PATH/nix-instantiate -v -v -)
#$NIX_CMD_PATH/nix-store -r $storeExpr
#echo $storeExpr
#storeExpr2=$($NIX_CMD_PATH/nix-store -qR $($NIX_CMD_PATH/nix-store -r $storeExpr))
#echo storeExpr $storeExpr
#echo $($NIX_CMD_PATH/nix-store -qR --include-outputs $storeExpr)

echo copying store

#(while read storepaths; do
  #cp -fa $storepaths $root/nix/store
#done) < /cdrom/mystorepaths

cp -fa /nix/store/* $root/nix/store

#echo registering valid paths...
#(while read storepath; do
#    echo PATH $storepath
#    if ! $NIX_CMD_PATH/nix-store --isvalid $storepath 2> /dev/null; then
#        (unset NIX_ROOT; $NIX_CMD_PATH/nix-store --dump $storepath) | $NIX_CMD_PATH/nix-store --restore $storepath
#        $NIX_CMD_PATH/nix-store --validpath $storepath
#    fi
#done) < /tmp/mystorepaths

#echo registering successors...
#(while read line; do
#    echo SUCC $line
#    $NIX_CMD_PATH/nix-store --successor $line
#done) < /tmp/mysuccessors

echo setting init symlink...
rm -f $root/init
ln -s $sysvinitPath/sbin/init $root/init
ln -s @bash@/bin/sh $root/bin/sh
ln -s @bash@/bin/bash $root/bin/bash

echo setting up inittab...
rm -f $root/etc/inittab
echo "id:2:initdefault:" >> $root/etc/inittab
echo "si::bootwait:$bootPath/bin/boot.sh" >> $root/etc/inittab
echo "ht:06:wait:$bootPath/bin/halt.sh" >> $root/etc/inittab
echo "1:2345:respawn:$bootPath/bin/login.sh /dev/tty1" >> $root/etc/inittab
#echo "2:2345:respawn:$bootPath/bin/login.sh /dev/ttys/1" >> $root/etc/inittab

echo setting up networking information...
make_dir 00755 /etc/networking
echo 192.168.150.1 > $root/etc/networking/local-ip
echo 192.168.150.3 > $root/etc/networking/gateway-ip
#cp /etc/resolv.conf $root/etc
rm -f $root/etc/hosts
echo "127.0.0.1 localhost" >> $root/etc/hosts
echo "192.168.150.1 uml" >> $root/etc/hosts

echo setting up initial account information...

echo "root:x:0:root" > $root/etc/group
echo "root:x:0:0:root:/root:/bin/sh" > $root/etc/passwd
echo "root::12757:0:99999:7:::" > $root/etc/shadow

###
### Do kernel stuff here.
###
strippedName=$(basename @kernel@);
if echo "$strippedName" | grep -q '^[a-z0-9]\{32\}-'; then
        strippedName=$(echo "$strippedName" | cut -c34-)
fi

echo "stripped" $strippedName


###
### Do funky stuff with grub here.
###

ln -s @kernel@/vmlinuz $root/boot/vmlinuz
ln -s @sysvinitPath@/sbin/init $root/sbin/init
ln -s @hotplug@/sbin/hotplug $root/sbin/hotplug
ln -s @hotplug@/etc/hotplug $root/etc/hotplug
ln -s @hotplug@/etc/hotplug.d $root/etc/hotplug.d
ln -s $device $root/dev/root

echo installing bootloader

grub-install --root-directory=${root} --no-floppy ${targetdrive}

echo umounting filesystem

umount $root

echo install done
telinit 0
