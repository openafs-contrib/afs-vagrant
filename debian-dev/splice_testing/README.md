# see also https://github.com/jhgorse/openafs/wiki/Linux-Splice-and-ERESTARTSYS-in-AFS/_edit

stap -v -l 'module("libafs").function("afs_linux_storeproc")'

module("libafs").function("afs_linux_storeproc@/vagrant/openafs/src/libafs/MODLOAD-4.7.0-MP/osi_fetchstore.c:86")

# test
cd /vagrant/splice_testing
afs-robotest teardown
afs-robotest setup
afs-robotest login
/usr/afs/bin/fs sq /afs/.robotest/test/ 0
stap -v erestartsys.stp -d libafs -d /lib/x86_64-linux-gnu/libc-2.24.so -d /bin/cp -d kernel

# make it fail by interrupting with ctrl+c during the copy operation
cp bigfile.bin /afs/.robotest/test/

ctrl+c
cp bigfile.bin /afs/.robotest/test/
# OR
stap -v -g inject_fault.stp -d libafs -d /lib/x86_64-linux-gnu/libc-2.24.so -d /bin/cp -d kernel
> cp: cannot stat ‘/afs/.robotest/test/bigfile.bin’: Connection timed out

https://sourceware.org/systemtap/man/tapset::signal.3stap.html

signal.do_action
signal.send
filter only for a particular signal
  (if sig==2) or for a particular process (if pid_name==stap).

trace on signal ERESTARTSYS and -ERESTARTSYS

check do_action

kernel.function("splice_direct_to_actor@fs/splice.c:1170")
  $in:struct file*
  $sd:struct splice_desc*
  $actor:splice_direct_actor*

  study the error codes, translations, etc.

repeat the failures by injecting return codes in:
* splice_direct_to_actor


8 generic_file_write_iter          -> 131072
9 afs_linux_write_iter             -> 131072
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1
5 afs_linux_flush                  -> -110
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1


4 afs_linux_write_end              -> 4096
8 generic_file_write_iter          -> 4096
9 afs_linux_write_iter             -> 4096
00 afs_linux_storeproc    bytesXferred M(0xffff880216207a30) = 0
01 afs_linux_storeproc              -> -512
02 afs_linux_storeproc    bytesXferred M(0xffff880216207a30) = 0
1 afs_CacheStoreDCaches            -> -512
00 afs_linux_storeproc    bytesXferred M(0xffff880216207a30) = 0
01 afs_linux_storeproc              -> -512
02 afs_linux_storeproc    bytesXferred M(0xffff880216207a30) = 0
1 afs_CacheStoreDCaches            -> -512
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1
5 afs_linux_flush                  -> -110
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1


4 afs_linux_write_end              -> 4096
8 generic_file_write_iter          -> 131072
9 afs_linux_write_iter             -> 131072
4 afs_linux_write_end              -> -4
8 generic_file_write_iter          -> -4
9 afs_linux_write_iter             -> -4
00 afs_linux_storeproc    bytesXferred M(0xffff88021446fa30) = 0
01 afs_linux_storeproc              -> -512
02 afs_linux_storeproc    bytesXferred M(0xffff88021446fa30) = 0
1 afs_CacheStoreDCaches            -> -512
00 afs_linux_storeproc    bytesXferred M(0xffff88021446fa30) = 0
01 afs_linux_storeproc              -> -512
02 afs_linux_storeproc    bytesXferred M(0xffff88021446fa30) = 0
1 afs_CacheStoreDCaches            -> -512
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1
5 afs_linux_flush                  -> -110
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1


2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> 0
4 afs_linux_write_end              -> 4096
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> 0
4 afs_linux_write_end              -> 4096
8 generic_file_write_iter          -> 131072
9 afs_linux_write_iter             -> 131072
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1
5 afs_linux_flush                  -> -110
2 afs_CacheStoreVCache             -> -1
3 afs_StoreAllSegments             -> -1
