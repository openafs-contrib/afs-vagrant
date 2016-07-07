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
echo "Don't forget to "
echo "${bold}cd $(PWD)${normal}"
echo "  since shells ${bold}do not${normal} readily inherent PWD from their children."
