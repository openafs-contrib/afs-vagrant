export DEBIAN_FRONTEND=noninteractive
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"
# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi
# Update apt
apt-get update

# Add the vagrant user to the RVM group
#usermod -a -G rvm vagrant

# Install dependencies, Git, and stuff
# First, blacklist some of the heavy packages
cat > /etc/apt/preferences.d/01texlive-exclude << EOF
Package: texlive*
Pin: release *
Pin-Priority: -1
EOF

# add for bootstrapping server, maybe: linux-headers-3.16.0-4-amd64 OR linux-headers-`uname -r`
for package in git-core build-essential libncurses5-dev fakeroot python-pip \
    automake libtool libkrb5-dev libroken18-heimdal bison gawk flex linux-headers-`uname -r` \   # AFS build deps
    strace elfutils \
    vim tmux vim-addon-manager nfs-kernel-server; do   # Optional
  echo "apt-get install -y $package"
  apt-get install -y $package
done
apt-get install -y kernel-package --no-install-recommends
# apt-get remove -y kernel-package fakeroot
# TODO: does not work yet, vim-addons
su -l -c 'vim-addons install systemtap' vagrant
yes | pip install robotframework

# interactive selection of kernel conf file and kernel-package prevents touch-free install
for package in linux-image-amd64 linux-image-amd64-dbg linux-headers-amd64; do
  echo "apt-get build-dep -y $package"
  apt-get build-dep -y $package
done

# remove blacklist in case user wants to install these manually
rm /etc/apt/preferences.d/01texlive-exclude

# Prepend hosts with our more outside ip address because
#  loopback does not work for robotest.
# Run this on boot hereon out.
# NOTE: Does not work for multiple IP interfaces
DEBIAN_INIT="/etc/init.d/vagrant_init"
if [ ! -f "${DEBIAN_INIT}" ]; then
cat <<EOF > ${DEBIAN_INIT}
#!/bin/bash
# ${DEBIAN_INIT}
cd /tmp
grep -v `hostname` /etc/hosts > tmp
rm /etc/hosts
echo `hostname -I` `hostname`.local `hostname` | cat - tmp > /etc/hosts
rm tmp
EOF
chmod +x ${DEBIAN_INIT}
${DEBIAN_INIT}
fi

# Get our repos
# su -l -c 'cd ~/;git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' vagrant
su -l -c 'cd ~/;git clone https://gerrit.openafs.org/openafs' vagrant
su -l -c 'cd ~/;git clone https://github.com/openafs-contrib/openafs-robotest' vagrant
su -l -c 'pip install robotframework;cd ~/openafs-robotest;./install.sh' vagrant

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -q "cd /vagrant" /home/vagrant/.bash_profile || su -l -c 'echo "cd /vagrant" >> /home/vagrant/.bash_profile' vagrant
su -l -c 'cd /vagrant;ln -s ~/openafs;ln -s ~/openafs-robotest' vagrant
# su -l -c 'ln -s ~/linux; ln -s ~/linux /usr/src/linux;' vagrant
su -l -c 'mkdir -p ~/.afsrobotestrc;ln -s /vagrant/afs-robotest.conf ~/.afsrobotestrc/afs-robotest.conf' vagrant
su -l -c 'cd ~/openafs;./regen.sh;./configure --with-krb5 --disable-strip-binaries --enable-debug --disable-optimize --enable-debug-kernel --disable-optimize-kernel --enable-debug-lwp --without-dot --enable-checking --enable-transarc-paths --with-linux-kernel-packaging' vagrant

echo "You are almost there. Do this next: "
echo "vagrant ssh"
echo "NOTE: /vagrant on the guest vm is shared with your current directory"

#5.3 gb
# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
