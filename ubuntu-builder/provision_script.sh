# vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"
# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi

export user=vagrant
export home=/home/$user

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

# Update sources and apt
sed -i -e 's/# deb-src/deb-src/' /etc/apt/sources.list
apt-get update

echo "apt-get install -y packages"
apt-get install -y git-core build-essential libncurses5-dev fakeroot python-pip kexec-tools \
    automake libtool libkrb5-dev libroken18-heimdal bison gawk flex \
    strace libelf-dev elfutils kernel-wedge cscope systemtap systemtap-doc systemtap-sdt-dev gdb \
    vim tmux vim-addon-manager nfs-kernel-server curl # Optional

apt-get install -y kernel-package --no-install-recommends
pip install --upgrade pip
pip install robotframework
pip install afsutil

# temporary libssl1.1 fix
wget --quiet http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4.1_amd64.deb
dpkg -i libssl1.1_1.1.0g-2ubuntu4.1_amd64.deb
# end libssl1.1

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
DEBIAN_INIT="/etc/init.d/afs_hostname_init"
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
cat <<"EOF" > $home/.inputrc
## arrow up
"\e[A":history-search-backward
## arrow down
"\e[B":history-search-forward
EOF
chown $user:$user $home/.inputrc

# Spruce up the bash homestead
# diff -u /etc/skel/.bashrc /home/vagrant/.bashrc
cd $home
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
cat <<"EOF" > $home/.vimrc
set nocompatible
syntax on
source $HOME/.vim/cscope_maps.vim
autocmd BufRead,BufNewFile *.strace set filetype=strace
EOF
chown $user:$user $home/.vimrc
cd $home
if [ ! -d $home/.vim ]; then
    echo No ~/.vim dir. Making it...
    su -l -c 'mkdir .vim' $user
fi
cd $home/.vim
wget --quiet http://cscope.sourceforge.net/cscope_maps.vim

cd $home
cat <<"EOF" > $home/.lessfilter
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
    *afsrobot)
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
chown $user:$user $home/.lessfilter
chmod a+x $home/.lessfilter

# Get our repos
# su -l -c 'cd ~/;git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' vagrant
su -l -c 'cd ~/;git clone https://gerrit.openafs.org/openafs' $user
su -l -c 'cd ~/;git clone https://github.com/openafs-contrib/openafs-robotest' $user
# su -l -c 'cd ~/openafs-robotest' $user
cd $home/openafs-robotest
#./install.sh
make install

cd $home
# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -s ". /home/vagrant/.bashrc" $home/.bash_profile || su -l -c 'echo ". /home/vagrant/.bashrc" >> ~/.bash_profile' $user
su -l -c 'cd /vagrant;ln -s ~/openafs;ln -s ~/openafs-robotest' $user
# su -l -c 'ln -s ~/linux; ln -s ~/linux /usr/src/linux;' vagrant
# su -l -c 'mkdir -p ~/.afsrobotestrc;cp /vagrant/afs-robotest.conf ~/.afsrobotestrc/afs-robotest.conf' vagrant
su -l -c 'afsrobot config init' $user
#su -l -c 'afsrobot config set host:$HOSTNAME installer transarc' $user
#su -l -c 'afsrobot config set host:$HOSTNAME dest $HOME/openafs/amd64_linux26/dest' $user
#su -l -c 'afsrobot config set variables afs_dist transarc' $user
su -l -c 'afsrobot config set paths.transarc aklog /usr/bin/aklog-1.6.18' $user
# su -l -c 'afsrobot config set options dafileserver "-d 1 -p 128 -b 2049 -l 600 -s 600 -vc 600 -cb 1024000"' vagrant
# disable fakestate to go faster
# su -l -c 'afsrobot config set options afsd '-dynroot -afsdb'
# To include more tests
su -l -c 'afsrobot config set run exclude_tags todo' $user

cd /vagrant
if [ ! -f aklog-1.6.18 ]; then
  wget --quiet http://download.sinenomine.net/user/jgorse/debian8x64/aklog-1.6.18
fi
if [ ! -f /usr/bin/aklog-1.6.18 ]; then
  cp aklog-1.6.18 /usr/bin/aklog-1.6.18
  chmod a+x /usr/bin/aklog-1.6.18
fi
chmod a+x /vagrant/*.sh


# Update kernel, clear testing flag if we do update it
cat <<"EOF" > $home/run_periodic-mainline.sh
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

echo "path $PATH"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "path $PATH"

cd ~/
LAST_TESTED="/home/vagrant/last_tested"
curl http://kernel.ubuntu.com/~kernel-ppa/mainline/daily/current/CHECKSUMS | grep -e "generic.*amd64.deb" -e "linux-headers.*all.deb" > CHECKSUMS
debs=$(cat CHECKSUMS | head -4 | awk '{ print $2}' | tr '\n' ' ')
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
EOF
chmod a+x $home/run_periodic-mainline.sh
chown $user:$user $home/run_periodic-mainline.sh
#su -l -c '(crontab -l 2>/dev/null; echo "0 23 * * *  ~/run_periodic-mainline.sh >> ~/run_periodic-mainline.log 2>&1") | crontab -' $user


cat <<"EOF" > $home/run_on_boot_script.sh
# vim: set ai ts=2 sts=2 sw=2 et :
export DEBIAN_FRONTEND=noninteractive
LAST_TESTED="~/last_tested"
MARKER_FILE="~/run_on_boot_script.marker"
# Only run tests once
if [ -f "${MARKER_FILE}" ]; then
  echo "`date` already ran $0. exiting."
  exit 0
fi

echo "`date` executing $0"

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "path $PATH"

. ~/.bashrc
cd ~/openafs
git pull
make distclean
git clean -fxd
./regen.sh
afsutil build # install kernel headers first, see below
afsrobot setup
afsrobot test
# afsrobot teardown

# TODO: Report back to mothership with 'run' output
# Set $LAST_TESTED for the kernel get script
echo `uname -v | perl -pe "s/#(.*?) .*/\1/"` > ${LAST_TESTED}

# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
EOF
chmod a+x $home/run_on_boot_script.sh
chown $user:$user $home/run_on_boot_script.sh
# This actually needs to run after network comes up. systemd horror show: http://unix.stackexchange.com/questions/188042/running-a-script-during-booting-startup-init-d-vs-cron-reboot?answertab=votes#tab-top
#su -l -c '(crontab -l 2>/dev/null; echo "@reboot sleep 30 && /home/vagrant/run_on_boot_script.sh >> ~/run_on_boot_script.log 2>&1") | crontab -' $user

#echo "Updating kernel. May reboot."
#su -l -c '~/run_periodic-mainline.sh' $user

echo "You are almost there! Do this next: "
echo "vagrant ssh"
echo "tmux -CC"
echo "NOTE: /vagrant on the guest vm is shared with your current directory. tmux is more fun in iTerm2. =)"

# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
