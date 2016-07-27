#!/bin/bash
# it is hard for parents to inherent environment from children,
# so cd won't work otherwise. hint hint, shell devs
bold=$(tput bold)
normal=$(tput sgr0)

git clone https://github.com/openafs-contrib/afs-vagrant.git

if [ -d "afs-vagrant/$1" ]; then
  cd "afs-vagrant/$1"
else
  echo "${bold}Bad directory${normal}. Try again with "
  echo "${bold}./afs-vagrant/scripts/bootstrap.sh <box foldername>${normal}"
  echo "or "
  echo "${bold}curl -fsSL https://raw.githubusercontent.com/openafs-contrib/afs-vagrant/master/scripts/bootstrap.sh | bash -s -- debian-server${normal}"
  exit 1
fi

# vagrant up
vagrant up
echo "You are in a subshell for $1 via the bootstrap script."
echo "To keep things clean, ${bold}vagrant destroy${normal} when done and delete the directory."
echo "Or you may keep this vagrant box with ${bold}vagrant {halt|reload|up}${normal} and returning "
echo "to this directory as necessary."

# set up prompt to help us remember we're in a subshell, cd to
# the vagrant target dir and start $SHELL
shell=$SHELL
if test "x$SHELL" = "x/bin/bash"
then
  # debian/ubuntu resets our PS1.  bastards.
  shell="$SHELL --noprofile"
fi
PS1="[$1] $PS1" $shell
