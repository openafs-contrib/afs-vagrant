#!/usr/bin/env bash  # vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
EXIT_SUDO=0
if [ ! $UID == 0 ]; then
  sudo -s
  EXIT_SUDO=1
fi

# Install dependencies, Git, and stuff
# First, blacklist some of the heavy packages
cat <<EOF > /etc/apt/preferences.d/01texlive-exclude
Package: texlive*
Pin: release *
Pin-Priority: -1
EOF


# latex2html texlive-latex-base texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended xmlto
# Build dependencies
for package in debhelper dh-autoreconf gettext libelf-dev libdw-dev libsqlite3-dev libnss3-dev libnspr4-dev pkg-config libnss3-tools python-lxml  libavahi-client-dev; do   # Optional
  echo "apt-get install -y $package"
  apt-get install -y $package
done

cd /tmp
rm -rf systemtap-*
apt-get source systemtap
cd systemtap-*
# dpkg-buildpackage -us -uc -d # no docs, no dice here
./configure
make -j`nproc`
make install
groupadd stapusr
groupadd stapdev
usermod -a -G stapusr vagrant
usermod -a -G stapdev vagrant

# OpenAFS
if [ ! -d /lib/modules/`uname -r`/kernel/fs/openafs ]; then
  mkdir -p /lib/modules/`uname -r`/kernel/fs/openafs
fi
echo "Copying openafs.ko kernel module to /lib/modules/`uname -r`/kernel/fs/openafs/"
if [ -f /home/vagrant/openafs/src/libafs/MODLOAD-`uname -r`-SP/openafs.ko ]; then
  cp /home/vagrant/openafs/src/libafs/MODLOAD-`uname -r`-SP/openafs.ko /lib/modules/`uname -r`/kernel/fs/openafs/openafs.ko
  depmod -a
elif [ -f /vagrant/openafs/src/libafs/MODLOAD-`uname -r`-SP/openafs.ko ]; then
  cp /vagrant/openafs/src/libafs/MODLOAD-`uname -r`-SP/openafs.ko /lib/modules/`uname -r`/kernel/fs/openafs/openafs.ko
  depmod -a
else
  echo "ERROR No AFS kernel module found."
  echo " Skipping copy to /lib/modules/`uname -r`/kernel/fs/openafs and depmod -a."
fi

# TODO: the rhel rpm does this:
# [16:00:57]  <>	108 This package provides the ${kmod_name} kernel modules built for the Linux
# [16:00:57]  <>	109 kernel ${kname} for the %{_target_cpu} family of processors.
# [16:00:57]  <>	110 %post          -n kmod-${kmod_name}${dashvariant}
# [16:00:57]  <>	111 ${depmod} -aeF /boot/System.map-${kname} ${kname} > /dev/null || :
# [16:00:57]  <>	112 %postun        -n kmod-${kmod_name}${dashvariant}
# [16:00:57]  <>	113 ${depmod} -aF /boot/System.map-${kname} ${kname} &> /dev/null || :
# [16:00:57]  <>	114 %files         -n kmod-${kmod_name}${dashvariant}
# [16:00:57]  <>	115 %defattr(644,root,root,755)
# [16:00:57]  <>	116 /lib/modules/${kname}/extra/${kmod_name}/
# TODO: the rc script does:
# [16:02:00]  <>	RedHat/openafs-client.init:     modprobe openafs

# TODO: Patch afsutil for openafs.ko

# TODO: Systemtap vim addons
# su -l -c 'vim-addons install systemtap' vagrant
# vim addons: http://vam.mawercer.de/

# remove blacklist in case user wants to install these manually
rm /etc/apt/preferences.d/01texlive-exclude

if [ ${EXIT_SUDO} == 1 ]; then
  exit
fi
