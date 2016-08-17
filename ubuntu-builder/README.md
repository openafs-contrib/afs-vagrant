# README

# Order of operations
1. Vagrantfile
2. provision_script.sh

# Theory of Operation
Build a new kernel every night and OpenAFS against that. Run it and smoke it.

1. Provision once via vagrant up => provision_script.sh
2. Run at least Daily
  1. /home/vagrant/run_periodic-mainline.sh
  1. Build or acquire kernel .deb packages and latest AFS master
  2. Install kernel .deb packages
  3. Cleanup
    1. Remove kernel .deb packages > 7 days old
    2. Kernel make clean
  4. kexec/reboot into new kernel
    1. /home/vagrant/run_on_boot_script.sh
  5. afsutil build
  6. afs-robotest {setup;run;teardown}
  7. Report status

When the smoke comes out. Patch it. (W)

# Notes

## Kernel from ubuntu daily mainline

```sh
# linux-headers-4.7.0-999_4.7.0-999.201608012201_all.deb
# TODO: Turn this into a daily crontab script that
#   1) grabs latest CHECKSUMS file, if debs are newer than $LAST_TESTED, continue
#   2) installs latest debs
#   3) deletes runner lock file: MARKER_FILE="/home/vagrant/run_on_boot_script_marker"
#   4) kexec new kernel, rebooting into run_on_boot_script.sh for testing

curl http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/CHECKSUMS | grep -e "generic.*amd64.deb" -e "linux-headers.*all.deb" > CHECKSUMS
debs=$(cat CHECKSUMS | head -3 | awk '{ print $2}' | tr '\n' ' ')
for package in $debs; do
  # echo "wget --quiet http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/$package"
  if [ ! -f $package ]; then
    wget --quiet http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/$package
  fi
done
#  check checksums
shasum -c CHECKSUMS
sudo dpkg -i $debs

# get 4.7.0-999-generic from linux-image-4.7.0-999-generic_4.7.0-999.201608012201_amd64.deb
new_uname=$(grep image CHECKSUMS | head -1 | awk '{print $2}' | perl -pe "s/linux-image-(.*?)_.*/\1/")
kappend=\"$(perl -p -e "s/=\/vmlinuz-.*?[[:space:]]/=\/boot\/vmlinuz-${new_uname} /" /proc/cmdline)\"
echo "kexec -l /boot/vmlinuz-${new_uname} --append=${kappend} --initrd=/boot/initrd.img-${new_uname}"
sudo kexec -l /boot/vmlinuz-${new_uname} --append=${kappend} --initrd=/boot/initrd.img-${new_uname}
sudo kexec -e

# At this point we reboot into the new kernel and lose our user-state.

(crontab -l 2>/dev/null; echo "@reboot /home/vagrant/run_on_boot_script.sh >> /home/vagrant/run_on_boot_script.out 2>&1") | crontab -
```
## Refs
(1) https://wiki.ubuntu.com/Kernel/BuildYourOwnKernel
(2) http://kernel.ubuntu.com/~kernel-ppa/mainline/

## Kernel from linux-next repo

```sh
# https://git.kernel.org/cgit/linux/kernel/git/next/linux-next.git/log/?ofs=100
```
## AFS

```sh
# cd /vagrant/openafs # NFS goes away after kexec
cd ~/openafs
afsutil build # install kernel headers first, see below
sudo afsutil install --force
afs-robotest setup
afs-robotest run
afs-robotest teardown
```
