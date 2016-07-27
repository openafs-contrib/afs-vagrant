export DEBIAN_FRONTEND=noninteractive
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"
# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi
# Add the vagrant user to the RVM group
#usermod -a -G rvm vagrant

# Install dependencies, Git, and stuff
# First, blacklist some of the heavy packages
cat <<EOF > /etc/apt/preferences.d/01texlive-exclude
Package: texlive*
Pin: release *
Pin-Priority: -1
EOF

# Update apt
apt-get update

# add for bootstrapping server, maybe: linux-headers-3.16.0-4-amd64 OR linux-headers-`uname -r`
for package in git-core build-essential libncurses5-dev fakeroot python-pip \
    automake libtool libkrb5-dev libroken18-heimdal bison gawk flex linux-headers-`uname -r` \
    strace elfutils cscope \
    vim tmux vim-addon-manager nfs-kernel-server; do   # Optional
  echo "apt-get install -y $package"
  apt-get install -y $package
done
apt-get install -y kernel-package --no-install-recommends

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

# Fix bash history search
cat <<"EOF" > /home/vagrant/.inputrc
## arrow up
"\e[A":history-search-backward
## arrow down
"\e[B":history-search-forward
EOF
chown vagrant:vagrant /home/vagrant/.inputrc

# Spruce up the bash homestead
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
+  export LESSOPEN='|pygmentize %s'
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
cat <<EOF > /home/vagrant/.vimrc
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
wget http://cscope.sourceforge.net/cscope_maps.vim

# Get our repos
# su -l -c 'cd ~/;git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git' vagrant
su -l -c 'cd ~/;git clone https://gerrit.openafs.org/openafs' vagrant
su -l -c 'cd ~/;git clone https://github.com/openafs-contrib/openafs-robotest' vagrant
su -l -c 'pip install robotframework;cd ~/openafs-robotest;./install.sh' vagrant

# TODO: copy common files from shared host dir to guest's directory on host. do in bootstrap.sh

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -q "cd /vagrant" /home/vagrant/.bash_profile || su -l -c 'echo "cd /vagrant" >> /home/vagrant/.bash_profile' vagrant
grep -q ". /home/vagrant/.bashrc" /home/vagrant/.bash_profile || su -l -c 'echo ". /home/vagrant/.bashrc" >> /home/vagrant/.bash_profile' vagrant
su -l -c 'cd /vagrant;ln -s ~/openafs;ln -s ~/openafs-robotest' vagrant
# su -l -c 'ln -s ~/linux; ln -s ~/linux /usr/src/linux;' vagrant
su -l -c 'mkdir -p ~/.afsrobotestrc;ln -s /vagrant/afs-robotest.conf ~/.afsrobotestrc/afs-robotest.conf' vagrant
su -l -c 'cd ~/openafs;./regen.sh;./configure --with-krb5 --disable-strip-binaries --enable-debug --disable-optimize --enable-debug-kernel --disable-optimize-kernel --enable-debug-lwp --without-dot --enable-checking --enable-transarc-paths --with-linux-kernel-packaging' vagrant

echo "You are almost there! Do this next: "
echo "vagrant ssh"
echo "tmux -CC"
echo "NOTE: /vagrant on the guest vm is shared with your current directory. tmux is more fun in iTerm2. =)"

#5.3 gb
# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
