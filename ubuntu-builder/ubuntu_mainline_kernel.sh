w# get the ubuntu kernel
# TODO: provision_script.sh CHECKSUMS parsing for these files automagically
wget --quiet  http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.1/linux-headers-4.10.1-041001_4.10.1-041001.201702260735_all.deb
wget --quiet  http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.1/linux-headers-4.10.1-041001-generic_4.10.1-041001.201702260735_amd64.deb
wget --quiet  http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.1/linux-image-4.10.1-041001-generic_4.10.1-041001.201702260735_amd64.deb

# install


# find or build debug symbols
# wget --quiet  http://ddebs.ubuntu.com/pool/main/l/linux/linux-image-4.10.0-9-generic-dbgsym_4.10.0-9.11_amd64.ddeb

cd $HOME
sudo apt-get install dpkg-dev debhelper gawk
mkdir tmp
cd tmp
sudo apt-get build-dep --no-install-recommends linux-image-$(uname -r)
apt-get source linux-image-$(uname -r)
cd linux-2.6.31 (this is currently the kernel version of 9.10)
fakeroot debian/rules clean
AUTOBUILD=1 fakeroot debian/rules binary-generic skipdbg=false
sudo dpkg -i ../linux-image-debug-2.6.31-19-generic_2.6.31-19.56_amd64.ddeb

# http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.1/
# v4.10.1 d23a9821d3972ae373357e933c8af8216d72e374
git clone git://git.launchpad.net/~ubuntu-kernel-test/ubuntu/+source/linux/+git/mainline-crack v4.10.1
cd v4.10.1
git apply

# 0001-base-packaging.patch
# 0002-UBUNTU-SAUCE-add-vmlinux.strip-to-BOOT_TARGETS1-on-p.patch
# 0003-UBUNTU-SAUCE-tools-hv-lsvmbus-add-manual-page.patch
# 0004-UBUNTU-SAUCE-no-up-disable-pie-when-gcc-has-it-enabl.patch
# 0005-debian-changelog.patch
# 0006-configs-based-on-Ubuntu-4.10.0-6.8.patch

for patch in 0001-base-packaging.patch \
0002-UBUNTU-SAUCE-add-vmlinux.strip-to-BOOT_TARGETS1-on-p.patch \
0003-UBUNTU-SAUCE-tools-hv-lsvmbus-add-manual-page.patch \
0004-UBUNTU-SAUCE-no-up-disable-pie-when-gcc-has-it-enabl.patch \
0005-debian-changelog.patch \
0006-configs-based-on-Ubuntu-4.10.0-6.8.patch; do
  echo "curl $patch | git apply --"
  curl http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.10.1/$patch | git apply --
done

fakeroot debian/rules clean
export CONCURRENCY_LEVEL=`nproc`

## TODO: try this
chmod a+x debian/rules
chmod a+x debian/scripts/*
chmod a+x debian/scripts/misc/*
fakeroot debian/rules clean
fakeroot debian/rules editconfigs # you need to go through each (Y, Exit, Y, Exit..) or get a complaint about config later
#AUTOBUILD=1 fakeroot debian/rules binary-generic skipdbg=false
# breaks.

cp /boot/config-4.10.1-041001-generic .config
make menuconfig
# build them all... why not.
AUTOBUILD=1 fakeroot make-kpkg --initrd --revision=1 kernel_image kernel_headers kernel_debug -j `nproc`


# alternatively
# git clone git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/yakkety


#
afs-robotest config set run exclude_tags todo
