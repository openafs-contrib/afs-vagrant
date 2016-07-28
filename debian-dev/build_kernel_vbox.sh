#!/usr/bin/env bash  # vim: set ai ts=2 sts=2 sw=2 et :

## Rebuild guest VM kmod
### GUI Method
# Make sure CD is inserted: /Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso
# This is often optional...
# sudo mount /dev/cdrom /media/cdrom
# sudo sh /media/cdrom/VBoxLinuxAdditions.run

### OR
### CL GUEST Method

# VV=5.1.2
# V3=4.4.15
VV=$(curl http://download.virtualbox.org/virtualbox/LATEST.TXT)
if [ ! -f VBoxGuestAdditions_${VV}.iso ]; then
  wget http://download.virtualbox.org/virtualbox/${VV}/VBoxGuestAdditions_${VV}.iso
fi
# Pass these variables to sudo
sudo VV=${VV} V3=${V3} -s
mkdir /media/VBoxGuestAdditions
mount -o loop,ro VBoxGuestAdditions_${VV}.iso /media/VBoxGuestAdditions
export KERN_DIR=/usr/src/linux-headers-${V3}
sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
rm VBoxGuestAdditions_${VV}.iso
umount /media/VBoxGuestAdditions
rmdir /media/VBoxGuestAdditions
exit

### OR
# VV=$(http://download.virtualbox.org/virtualbox/LATEST.TXT)
# http://download.virtualbox.org/virtualbox/${VV}/
