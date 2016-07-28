#!/usr/bin/env bash  # vim: set ai ts=2 sts=2 sw=2 et :

cd ~/openafs
wget http://download.sinenomine.net/user/jgorse/debian8x64/patch/diff.patch
patch -p1 < diff.patch
afsutil build --cf "--with-krb5 --disable-strip-binaries --enable-debug --disable-optimize --enable-debug-kernel --disable-optimize-kernel --enable-debug-lwp --without-dot --enable-checking --enable-transarc-paths"

# Publish it
BUILD_ID=`uname -r`-`date +%Y%m%d-%H%M%S`-`git log -n1 --format="%h"`
tar cfz amd64_linux26-${BUILD_ID}.tar.gz amd64_linux26
# TODO: Get a passwordless dropbox... or use AFS
# scp amd64_linux26-${BUILD_ID}.tar.gz \
#   jgorse@sftp.sinenomine.net:/afs/sinenomine.net/user/jgorse/public/debian8x64/`uname -r`
# TODO: ensure `uname -r` directory exists

if [ ! -d /lib/modules/`uname -r`/kernel/fs/openafs ]; then
  sudo mkdir -p /lib/modules/`uname -r`/kernel/fs/openafs
fi
  echo "Installing fresh built kernel module"
if [ -f src/libafs/MODLOAD-`uname -r`-MP/libafs.ko ]; then
  sudo cp src/libafs/MODLOAD-`uname -r`-MP/libafs.ko /lib/modules/`uname -r`/kernel/fs/openafs/libafs.ko
  sudo depmod -a
elif [ -f src/libafs/MODLOAD-`uname -r`-SP/openafs.ko ]; then
  sudo cp src/libafs/MODLOAD-`uname -r`-SP/openafs.ko /lib/modules/`uname -r`/kernel/fs/openafs/openafs.ko
  sudo depmod -a
else
  echo "ERROR No AFS kernel module found."
  echo " Skipping copy to /lib/modules/`uname -r`/kernel/fs/openafs and depmod -a."
fi

# TODO: the debian packages calls update-modules, instead of depmod directly
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

afs-robotest teardown
afs-robotest setup
time afs-robotest run
afs-robotest login
/usr/afs/bin/fs sq /afs/.robotest/test 0
