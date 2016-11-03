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
# These should not be necessary...
# groupadd stapusr
# groupadd stapdev
usermod -a -G stapusr vagrant
usermod -a -G stapdev vagrant

# OpenAFS
if [ ! -d /lib/modules/`uname -r`/kernel/fs/openafs ]; then
  mkdir -p /lib/modules/`uname -r`/kernel/fs/openafs
fi

# TODO: Systemtap vim addons
# su -l -c 'vim-addons install systemtap' vagrant
# vim addons: http://vam.mawercer.de/

# remove blacklist in case user wants to install these manually
rm /etc/apt/preferences.d/01texlive-exclude

if [ ${EXIT_SUDO} == 1 ]; then
  exit
fi
