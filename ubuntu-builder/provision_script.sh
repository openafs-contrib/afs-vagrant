# vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"
# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi

# Get rid of the /boot partition, we will need the space to grow.
if [ -d /boot ] && [ -d /boot-tmp ]; then
  rm -rf /boot-tmp
fi
cp -a /boot /boot-tmp
diff -ru /boot /boot-tmp
if [ $? -eq 0 ]; then
  echo "Merging /boot partition with /"
  chmod -R u+w /boot
  rm -rf /boot
  umount -f /boot
  rmdir /boot
  blkid
  mkfs.ext4 /dev/sda1
  mv /boot-tmp /boot
  if [ ! -f /etc/fstab.bkup ]; then
    cp /etc/fstab /etc/fstab.bkup
  fi
  rm /etc/fstab
  grep -v "/boot" /etc/fstab.bkup > /etc/fstab
  update-grub
  grub-install /dev/sda
else
  echo "/boot and /boot-tmp are different. Aborted the merge of /boot to /."
fi

# Install dependencies, Git, and stuff
# First, blacklist some of the heavy packages
cat <<"EOF" > /etc/apt/preferences.d/01texlive-exclude
Package: texlive*
Pin: release *
Pin-Priority: -1
EOF

# No and no to the kexec questions
cat <<"EOF" >> /var/cache/debconf/config.dat
Name: kexec-tools/load_kexec
Template: kexec-tools/load_kexec
Value: false
Owners: kexec-tools
Flags: seen

Name: kexec-tools/use_grub_config
Template: kexec-tools/use_grub_config
Value: false
Owners: kexec-tools
Flags: seen
EOF

# Live on the edge of the apt-get tree
#Probably not a good idea in ubuntu
# cat <<"EOF" > /etc/apt/sources.list
# ###### Debian Main Repos
# deb http://ftp.us.debian.org/debian/ sid main contrib non-free
# deb-src http://ftp.us.debian.org/debian/ sid main contrib non-free
#
# ###### Debian Update Repos
# deb http://security.debian.org/ sid/updates main contrib non-free
# deb http://ftp.us.debian.org/debian/ sid-proposed-updates main contrib non-free
# deb-src http://security.debian.org/ sid/updates main contrib non-free
# deb-src http://ftp.us.debian.org/debian/ sid-proposed-updates main contrib non-free
# EOF

# Update apt
apt-get update

# This seems like a good place to install the (optional) binary kernel install
# TODO: build_kernel.sh $version
# echo "Installing the specified kernel"
# ls -l /vagrant/
# echo "/home/vagrant/ before"
# ls -l /home/vagrant/
# # su -l -c 'ln -s /vagrant/*.deb /home/vagrant/' vagrant
# echo "/home/vagrant/ after"
# ls -l /home/vagrant/
# su -l -c 'bash /vagrant/build_kernel.sh' vagrant
# update-grub
# grub-install /dev/sda
# cat /boot/grub/grub.cfg | grep menuentry | grep -v recovery | tr \' '\n' | grep Debian.*[0-9]


# add for bootstrapping server, maybe: linux-headers-3.16.0-4-amd64 OR linux-headers-`uname -r`
# for package in git-core build-essential libncurses5-dev fakeroot python-pip \
#     automake libtool libkrb5-dev libroken18-heimdal bison gawk flex \
#     strace elfutils cscope systemtap systemtap-doc systemtap-sdt-dev \
#     vim tmux vim-addon-manager nfs-kernel-server; do   # Optional
#   echo "apt-get install -y $package"
#   apt-get install -y $package
# done
echo "apt-get install -y packages"
apt-get install -y git-core build-essential libncurses5-dev fakeroot python-pip kexec-tools \
    automake libtool libkrb5-dev libroken18-heimdal bison gawk flex \
    strace elfutils cscope systemtap systemtap-doc systemtap-sdt-dev gdb \
    vim tmux vim-addon-manager nfs-kernel-server curl # Optional

apt-get install -y kernel-package --no-install-recommends
pip install --upgrade pip
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
echo `hostname -I | awk '{ print $1 }'` `hostname`.local `hostname` | cat - tmp > /etc/hosts
rm tmp
EOF
chmod +x ${DEBIAN_INIT}
${DEBIAN_INIT}
fi

# Fix bash history search
cat <<"EOF" > /home/vagrant/.inputrc
## arrow up
"\e[A":history-search-backward
## arrow down
"\e[B":history-search-forward
EOF
chown vagrant:vagrant /home/vagrant/.inputrc

# Spruce up the bash homestead
# diff -u /etc/skel/.bashrc /home/vagrant/.bashrc
cd /home/vagrant
patch <<"EOF"
--- /etc/skel/.bashrc	2014-11-12 23:08:49.000000000 +0000
+++ /home/vagrant/.bashrc	2016-07-27 02:18:06.428000000 +0000
@@ -25,10 +25,14 @@

 # If set, the pattern "**" used in a pathname expansion context will
 # match all files and zero or more directories and subdirectories.
-#shopt -s globstar
+shopt -s globstar

 # make less more friendly for non-text input files, see lesspipe(1)
 #[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
+if [ -x /usr/bin/pygmentize ]; then
+  export LESSOPEN='|~/.lessfilter %s'
+  export LESS='-R'
+fi

 # set variable identifying the chroot you work in (used in the prompt below)
 if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
@@ -43,7 +47,7 @@
 # uncomment for a colored prompt, if the terminal has the capability; turned
 # off by default to not distract the user: the focus in a terminal window
 # should be on the output of commands, not on the prompt
-#force_color_prompt=yes
+force_color_prompt=yes

 if [ -n "$force_color_prompt" ]; then
     if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
@@ -76,21 +80,21 @@
 if [ -x /usr/bin/dircolors ]; then
     test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
     alias ls='ls --color=auto'
-    #alias dir='dir --color=auto'
-    #alias vdir='vdir --color=auto'
+    alias dir='dir --color=auto'
+    alias vdir='vdir --color=auto'

-    #alias grep='grep --color=auto'
-    #alias fgrep='fgrep --color=auto'
-    #alias egrep='egrep --color=auto'
+    alias grep='grep --color=auto'
+    alias fgrep='fgrep --color=auto'
+    alias egrep='egrep --color=auto'
 fi

 # colored GCC warnings and errors
-#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'
+export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

 # some more ls aliases
-#alias ll='ls -l'
-#alias la='ls -A'
-#alias l='ls -CF'
+alias ll='ls -l'
+alias la='ls -A'
+alias l='ls -CF'

 # Alias definitions.
 # You may want to put all your additions into a separate file like
EOF

# Vim setup
cat <<"EOF" > /home/vagrant/.vimrc
set nocompatible
syntax on
source /home/vagrant/.vim/cscope_maps.vim
autocmd BufRead,BufNewFile *.strace set filetype=strace
EOF
chown vagrant:vagrant /home/vagrant/.vimrc
if [ ! -d /home/vagrant/.vim ]; then
    echo No ~/vim dir. Making it...
    su -l -c 'mkdir /home/vagrant/.vim' vagrant
fi
cd /home/vagrant/.vim
wget --quiet http://cscope.sourceforge.net/cscope_maps.vim

cat <<"EOF" > /home/vagrant/.lessfilter
#!/usr/bin/env bash
# paraiso-dark native vim
pygmentize_opts="-f terminal256 -O style=native"
shopt -s extglob
lexers="+($(pygmentize -L lexers |
           perl -ne 'print join("|", split(/, /,$1)) . "|" if /\(filenames ([^\)]+)\)/' |
           sed 's/|$//'))"

case "$1" in
    $lexers)
        pygmentize -f 256 "$1";;
    *.stp)
        pygmentize -f 256 -l c "$1"
        ;;
    *.bash|*.*rc)
        pygmentize -f 256 -l sh "$1"
        ;;
    *afs-robotest)
        pygmentize -f 256 -l py "$1"
        ;;

    *)
        #pygmentize -f 256 -l sh "$1"
        grep "#\!/bin/bash" "$1" > /dev/null
        if [ "$?" -eq "0" ]; then
            pygmentize -f 256 -l sh "$1"
        fi
        head -n1 "$1" | grep "python" > /dev/null
        if [ "$?" -eq "0" ]; then
            pygmentize -f 256 -l py "$1"
        else
            exit 1
        fi
        ;;
esac
exit 0
EOF
chown vagrant:vagrant /home/vagrant/.lessfilter
chmod a+x /home/vagrant/.lessfilter

# Get our repos
# su -l -c 'cd ~/;git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' vagrant
su -l -c 'cd ~/;git clone https://gerrit.openafs.org/openafs' vagrant
su -l -c 'cd ~/;git clone https://github.com/openafs-contrib/openafs-robotest' vagrant
su -l -c 'cd ~/openafs-robotest;./install.sh' vagrant

# TODO: copy common files from shared host dir to guest's directory on host. do in bootstrap.sh

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -s "cd /vagrant" /home/vagrant/.bash_profile || su -l -c 'echo "cd /vagrant" >> /home/vagrant/.bash_profile' vagrant
grep -s ". /home/vagrant/.bashrc" /home/vagrant/.bash_profile || su -l -c 'echo ". /home/vagrant/.bashrc" >> /home/vagrant/.bash_profile' vagrant
su -l -c 'cd /vagrant;ln -s ~/openafs;ln -s ~/openafs-robotest' vagrant
# su -l -c 'ln -s ~/linux; ln -s ~/linux /usr/src/linux;' vagrant
su -l -c 'mkdir -p ~/.afsrobotestrc;ln -sf /vagrant/afs-robotest.conf ~/.afsrobotestrc/afs-robotest.conf' vagrant
# su -l -c 'cd ~/openafs;./regen.sh;./configure --with-krb5 --disable-strip-binaries --enable-debug --disable-optimize --enable-debug-kernel --disable-optimize-kernel --enable-debug-lwp --without-dot --enable-checking --enable-transarc-paths --with-linux-kernel-packaging' vagrant
#su -l -c 'cd ~/openafs;afsutil build --cf "--with-krb5 --disable-strip-binaries --enable-debug --disable-optimize --enable-debug-kernel --disable-optimize-kernel --enable-debug-lwp --without-dot --enable-checking --enable-transarc-paths"' vagrant
# TODO: build_openafs.sh $version...
cd /vagrant
if [ ! -f aklog-1.6.18 ]; then
  wget --quiet http://download.sinenomine.net/user/jgorse/debian8x64/aklog-1.6.18
fi
if [ ! -f /usr/bin/aklog-1.6.18 ]; then
  cp /vagrant/aklog-1.6.18 /usr/bin/aklog-1.6.18
  chmod a+x /usr/bin/aklog-1.6.18
fi
chmod a+x /vagrant/*.sh


# Update kernel, clear testing flag if we do update it
cat <<"EOF" > /home/vagrant/run_periodic-mainline.sh
# vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
echo "`date` executing $0"

## Kernel from ubuntu daily mainline

# linux-headers-4.7.0-999_4.7.0-999.201608012201_all.deb
# TODO: Turn this into a daily crontab script that
#   1) grabs latest CHECKSUMS file, if debs are newer than $LAST_TESTED, continue
#   2) installs latest debs
#   3) deletes runner lock file: MARKER_FILE="/home/vagrant/run_on_boot_script_marker"
#   4) kexec new kernel, rebooting into run_on_boot_script.sh for testing

cd ~/
LAST_TESTED="/home/vagrant/last_tested"
curl http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/CHECKSUMS | grep -e "generic.*amd64.deb" -e "linux-headers.*all.deb" > CHECKSUMS
debs=$(cat CHECKSUMS | head -3 | awk '{ print $2}' | tr '\n' ' ')
latest=$(head -1 CHECKSUMS | perl -pe "s/.*\.(.*)_all.deb/\1/")
# Only do this if we have not done it before
if [ -f "${LAST_TESTED}" ]; then
  echo "`date` checking ${LAST_TESTED}"
  if [[ $(cat ${LAST_TESTED}) == ${latest} ]]; then
    echo "Latest kernel debs match last tested. Exiting."
    # exit 0
  else
    echo "LAST_TESTED $(cat ${LAST_TESTED})=>${latest}"
  fi
fi

for package in $debs; do
  if [ ! -f $package ]; then
    wget --quiet http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/$package
  fi
done
#  check checksums
shasum -c CHECKSUMS
sudo dpkg -i $debs

sudo shutdown -r now

# get 4.7.0-999-generic from linux-image-4.7.0-999-generic_4.7.0-999.201608012201_amd64.deb

# new_uname=$(grep image CHECKSUMS | head -1 | awk '{print $2}' | perl -pe "s/linux-image-(.*?)_.*/\1/")
# kappend=\"$(perl -pe "s/=\/vmlinuz-.*?[[:space:]]/=\/boot\/vmlinuz-${new_uname} /" /proc/cmdline)\"
# echo "kexec -l /boot/vmlinuz-${new_uname} --append=${kappend} --initrd=/boot/initrd.img-${new_uname}"
# sudo kexec -l /boot/vmlinuz-${new_uname} --append=${kappend} --initrd=/boot/initrd.img-${new_uname}
#
# MARKER_FILE="/home/vagrant/run_on_boot_script_marker"
# if [ -f "${MARKER_FILE}" ]; then
#   echo "`date` removing ${MARKER_FILE} and rebooting"
#   rm ${MARKER_FILE}
# fi
# sudo kexec -e

# Goodbye world =)
EOF
chmod a+x /home/vagrant/run_periodic-mainline.sh
chown vagrant:vagrant /home/vagrant/run_periodic-mainline.sh
su -l -c '(crontab -l 2>/dev/null; echo "0 23 * * *  /home/vagrant/run_periodic-mainline.sh >> /home/vagrant/run_periodic-mainline.log 2>&1") | crontab -' vagrant


cat <<"EOF" > /home/vagrant/run_on_boot_script.sh
# vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
LAST_TESTED="/home/vagrant/last_tested"
MARKER_FILE="/home/vagrant/run_on_boot_script_marker"
# Only run tests once
if [ -f "${MARKER_FILE}" ]; then
  echo "`date` already ran $0. exiting."
  exit 0
fi

echo "`date` executing $0"

cd ~/openafs
git pull
afsutil build # install kernel headers first, see below
sudo afsutil install --force
afs-robotest setup
afs-robotest run
# afs-robotest teardown

# TODO: Report back to mothership with 'run' output
# Set $LAST_TESTED for the kernel get script
echo `uname -v | perl -pe "s/#(.*?) .*/\1/"` > ${LAST_TESTED}

# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
EOF
chmod a+x /home/vagrant/run_on_boot_script.sh
chown vagrant:vagrant /home/vagrant/run_on_boot_script.sh
# su -l -c 'cd /vagrant;ln -s ~/run_on_boot_script.sh' vagrant
su -l -c '(crontab -l 2>/dev/null; echo "@reboot /home/vagrant/run_on_boot_script.sh >> /home/vagrant/run_on_boot_script.log 2>&1") | crontab -' vagrant
# su -l -c 'touch /home/vagrant/run_on_boot_script.log; cd /vagrant;ln -s /home/vagrant/run_on_boot_script.log' vagrant

echo "Updating kernel. May reboot."
su -l -c '/home/vagrant/run_periodic-mainline.sh' vagrant

echo "You are almost there! Do this next: "
echo "vagrant ssh"
echo "tmux -CC"
echo "NOTE: /vagrant on the guest vm is shared with your current directory. tmux is more fun in iTerm2. =)"

#5.3 gb
# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
