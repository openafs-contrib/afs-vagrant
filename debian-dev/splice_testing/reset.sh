#! /usr/bin/env bash

afs-robotest teardown
afs-robotest setup
afs-robotest login
/usr/afs/bin/fs sq /afs/.robotest/test/ 0

