# afs-vagrant
A collection of AFS development containers.
* debian-dev - for building the linux kernel and OpenAFS packages, 
 * Requires ~5 GB of disk space for the initial bootstrap, ~15 GB for a kernel build
 * 1/2 of host RAM, and all CPU cores are provided to the guest
* debian-server - for running the built packages on linux, e.g. with robotest
 * 1.4 GB of disk space, 768 MB RAM, 2 CPU cores

# Requirements
## Mac OS X
At least 4 GB RAM, 20 GB hard disk space remaining
### homebrew
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap caskroom/cask
```
### VirtualBox and Vagrant via homebrew
```
brew install Caskroom/cask/virtualbox Caskroom/cask/virtualbox-extension-pack Caskroom/cask/vagrant
# may need to enter password
```

# Usage
One liner to bring up the afs test box called debian-server:
```
curl -fsSL https://raw.githubusercontent.com/openafs-contrib/afs-vagrant/master/scripts/bootstrap.sh | bash -s -- debian-server
```
Note the addition of the directory as the first argument (debian-server) to the bootstrap.sh command.

Or if you want to do it manually:
```
git clone https://github.com/openafs-contrib/afs-vagrant.git
cd afs-vagrant/debian-server
vagrant up
```
Vagrant survival commands
```
vagrant help
vagrant halt   # shutdown
vagrant reload # halt, up
vagrant status
```
# Contributing
PRs welcome.

# Roadmap
This is intended to house the build and test environments for OpenAFS. I hope that
it might some day look similar to Chef's bento repo: https://github.com/chef/bento
though for all the kernels and OpenAFS versions we have and can mash together.
