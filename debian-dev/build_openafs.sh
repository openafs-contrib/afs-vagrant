

cd ~/openafs
afsutil build
tar cvfz amd64_linux26-`date +%Y%m%d-%H%M%S`-`git log -n1 --format="%h"`.tar.gz amd64_linux26
