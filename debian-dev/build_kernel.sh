#!/usr/bin/env bash  # vim: set ai ts=2 sts=2 sw=2 et :
#
# Two pathways: 1) an official release OR 2) a linux git repo with branch/tag

set -x

cd ~/

# Path 1, official tarball
export V=4.4.15    # release version
export V3=${V}     # release version, triplet

## Before building, can we cheat? Has this been done before...
deb_packages="linux-headers-${V3}_1_amd64.deb linux-image-${V3}_1_amd64.deb \
linux-image-${V3}-dbg_1_amd64.deb"

for deb in ${deb_packages}; do
  if [ ! -f ${deb} ] && [ -f /vagrant/${deb} ]; then
    ln -s /vagrant/${deb} `pwd`/${deb}
  fi
done
# Counter variable for found deb packages
i=0
for deb in ${deb_packages}; do
  if [ ! -f ${deb} ]; then
    wget --quiet http://download.sinenomine.net/user/jgorse/debian8x64/${V3}/${deb}
    if [ $? -ne 0 ]; then
      echo "No archived kernel, time to build."
      break
    else
      (( i++ ))
    fi
  else
    (( i++ ))
    echo "Found local package ${i} ${deb}"
  fi
done
echo "Got ${i} prebuilt packages."
if [ $i == 3 ]; then
  # We were able to download the debian packages. Now install them and quit.
  echo "Runing the following command to complete install:"
  echo "  sudo dpkg -i ${deb_packages}"
  echo "  Consider running post install: dkms --kernelsourcedir /usr/src/linux-headers-$V3"
  # dkms --kernelsourcedir /usr/src/linux-headers-$V3
  sudo dpkg -i ${deb_packages}
  echo "All done with kernel $V3! NOTE: Check your guest kernel module."
  exit 0
fi

echo "Start the build."

## Get the source
if [ ! -f linux-${V}.tar.xz ] && [ ! -f linux-${V}.tar ]; then
  wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${V}.tar.xz
fi
if [ ! -f linux-${V}.tar.sign ]; then
  wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${V}.tar.sign
fi
unxz linux-${V}.tar.xz
gpg --keyserver-options auto-key-retrieve --verify linux-${V}.tar.sign linux-${V}.tar
if [ $? -ne 0 ]; then
  echo "The tarball's authenticity is suspect."
  exit 1
fi
tar xf linux-${V}.tar
cd linux-${V}

## Build it
cp /boot/config-`uname -r` .config
# interactively set options...
#  make menuconfig
#  make config
# get options
#  make help

### Build .deb packages
# TODO: Consider removing fakeroot
sudo fakeroot make-kpkg clean
export CONCURRENCY_LEVEL=`nproc`
sudo fakeroot make-kpkg --initrd --revision=1 kernel_image kernel_headers kernel_debug -j`nproc`
#sudo chown -R vagrant:vagrant ../
V3=`make kernelversion`
sudo cp vmlinux /boot/vmlinux-${V3}

### Install .deb packages
sudo V3=${V3} dpkg -i ../linux-headers-${V3}_1_amd64.deb \
  ../linux-image-${V3}_1_amd64.deb \
  ../linux-image-${V3}-dbg_1_amd64.deb

sudo chmod a+r /boot/System.map-${V3}
# update-grub

### Push .deb packages
scp ../linux-headers-${V3}_1_amd64.deb \
  ../linux-image-${V3}_1_amd64.deb \
  ../linux-image-${V3}-dbg_1_amd64.deb \
  /boot/vmlinux-${V3} \
  jgorse@sftp.sinenomine.net:/afs/sinenomine.net/user/jgorse/public/debian8x64/${V3}/

# We now have the following packages in the directory above:
#   linux-headers-`make kernelversion`_1_amd64.deb
#   linux-image-`make kernelversion`_1_amd64.deb
#   linux-image-`make kernelversion`-dbg_1_amd64.deb
# NOTE: for V=4.7, the version was expanded to 4.7.0. `make kernelrelease`

### Build systemtap pieces
# make -j`nproc` all
# sudo make modules_install
# sudo make install


# wasn't needed
#sudo cp vmlinux /boot/vmlinux-`make kernelversion`

echo "Kernel script finished"

# Path 2, linux kernel via git
