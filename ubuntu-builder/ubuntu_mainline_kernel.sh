# vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
echo "`date` executing $0"
set -e # stop on errors

## Kernel from ubuntu daily mainline

# linux-headers-4.7.0-999_4.7.0-999.201608012201_all.deb
# TODO: Turn this into a daily crontab script that
#   1) grabs latest CHECKSUMS file, if debs are newer than $LAST_INSTALLED, continue
#   2) installs latest debs
#   3) deletes runner lock file: MARKER_FILE="/home/vagrant/run_on_boot_script_marker"
#   4) kexec new kernel, rebooting into run_on_boot_script.sh for testing

echo "path $PATH"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "path $PATH"

#url=http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/
url="http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.11-rc4/"

cd ~/
LAST_INSTALLED="/home/vagrant/last_tested"
curl ${url}/CHECKSUMS | grep -e "generic.*amd64.deb" -e "linux-headers.*all.deb" > CHECKSUMS
debs=$(cat CHECKSUMS | head -3 | awk '{ print $2}' | tr '\n' ' ')
latest=$(head -1 CHECKSUMS | perl -pe "s/.*\.(.*)_all.deb/\1/")
# Only do this if we have not done it before
if [ -f "${LAST_INSTALLED}" ]; then
  echo "`date` checking ${LAST_INSTALLED}"
  if [[ $(cat ${LAST_INSTALLED}) == ${latest} ]]; then
    echo "Latest kernel debs match last tested. Exiting."
    exit 0
  else
    echo "LAST_INSTALLED $(cat ${LAST_INSTALLED})=>${latest}"
  fi
else
  echo "No last installed (LAST_INSTALLED) file exists."
fi

for package in $debs; do
  if [ ! -f $package ]; then
    wget --quiet ${url}/$package
  fi
done
#  check checksums
shasum -c CHECKSUMS
sudo dpkg -i $debs

echo ${latest} > ${LAST_INSTALLED}
MARKER_FILE="/home/vagrant/run_on_boot_script.marker"
if [ -f "${MARKER_FILE}" ]; then
  echo "`date` removing ${MARKER_FILE} and rebooting"
  rm ${MARKER_FILE}
fi

sudo /sbin/shutdown -r now

# get 4.7.0-999-generic from linux-image-4.7.0-999-generic_4.7.0-999.201608012201_amd64.deb

# new_uname=$(grep image CHECKSUMS | head -1 | awk '{print $2}' | perl -pe "s/linux-image-(.*?)_.*/\1/")
# kappend=\"$(perl -pe "s/=\/vmlinuz-.*?[[:space:]]/=\/boot\/vmlinuz-${new_uname} /" /proc/cmdline)\"
# echo "kexec -l /boot/vmlinuz-${new_uname} --append=${kappend} --initrd=/boot/initrd.img-${new_uname}"
# sudo kexec -l /boot/vmlinuz-${new_uname} --append=${kappend} --initrd=/boot/initrd.img-${new_uname}
#

# Goodbye world =)
