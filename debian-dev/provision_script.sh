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
# add for bootstrapping server, maybe: linux-headers-3.16.0-4-amd64 OR linux-headers-`uname -r`
for package in git-core build-essential libncurses5-dev fakeroot python-pip kernel-package; do
  apt-get install -y $package
done
# apt-get remove -y kernel-package fakeroot

# interactive selection of kernel conf file and kernel-package prevents touch-free install
for package in linux-image-amd64 linux-image-amd64-dbg linux-headers-amd64 openafs; do
  apt-get build-dep -y $package
done

# Get our repos
su -l -c 'cd ~/;git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' vagrant
su -l -c 'cd ~/;git clone https://gerrit.openafs.org/openafs' vagrant
su -l -c 'cd ~/;git clone https://github.com/openafs-contrib/openafs-robotest' vagrant
su -l -c 'pip install robotframework;cd ~/openafs-robotest;./install.sh' vagrant

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -q 'cd /vagrant' /home/vagrant/.bash_profile || echo 'cd /vagrant' >> /home/vagrant/.bash_profile
su -l -c 'cd /vagrant;ln -s ~/linux; ln -s ~/linux /usr/src/linux;ln -s ~/openafs;ln -s ~/openafs-robotest' vagrant

#5.3 gb
# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
