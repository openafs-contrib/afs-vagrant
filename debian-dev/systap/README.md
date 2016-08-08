# Test procedure with systemtap
## Two systemtap windows:
#### positive indicator (should not show)
* `stap -v osi_dentry_trace.stp`

#### negative indicator (should show)
* `stap -v osi_TryEvictVCache_trace.stp`

## Two AFS windows:
#### the do-er
```
afs-robotest teardown
afs-robotest setup
afs-robotest login
cd /afs/.robotest/test
/usr/afs/bin/fs sq . 0

mkdir g; cd g;

# start test
date; git clone git://gerrit.openafs.org/openafs.git;date;echo 1 $?;sleep 90;echo 2 $?;git log;echo -ne '\007'

# reset
cd /afs/.robotest/test
rm -rf g
```
#### the observer
```
cd /afs/.robotest/test/g
# the canary (before, during, and after test)
git log
# should see "not a git repo" instead of "could not getcwd"
```

# Notes
- probe overhead exceeded threshold: -g --suppress-time-limits

stap -v trace-close.stp stap -d /lib/x86_64-linux-gnu/libc-2.23.so stap -d /lib/x86_64-linux-gnu/libpthread-2.23.so stap -d /lib/systemd/systemd-udevd stap -d /usr/bin/git stap -d /bin/bash stap -d /lib/x86_64-linux-gnu/ld-2.23.so stap -d /usr/bin/wc kernel


stap -v -l 'probe module("*afs*").function("*")' -d /vagrant/openafs/src/libafs/MODLOAD-4.4.15-MP/libafs.ko | grep -v kafs

stap -v -l 'module("*").function("d_entry")' | head
stap -v -l 'module("*").function("d_unhashed")' | head

stap -v -l 'module("/vagrant/openafs/src/libafs/MODLOAD-4.4.15-MP/libafs.ko").function("*")' | head

  module("/vagrant/openafs/src/libafs/MODLOAD-4.4.15-MP/libafs.ko").function("osi_TryEvictVCache@/vagrant/openafs/src/libafs/MODLOAD-4.4.15-MP/osi_vcache.c:19")


stap -L 'kernel.function("vfs_*")'
stap -L 'kernel.function("*dentry*")'
  kernel.function("dentry_unhash@fs/namei.c:3650") $dentry:struct dentry*


# Not seeing resolved backtraces for libafs.ko, e.g.
kbt:
 0xffffffff811d5f60 : dput+0x0/0x1f0 [kernel]
 0xffffffffa060015d [libafs]
 0xffffffff810545f5 : kretprobe_trampoline+0x0/0x4b [kernel] (inexact)
 0xffffffffa059bed8 [libafs] (inexact)
 0xffffffffa0608b90 [libafs] (inexact)
 0xffffffffa0608e39 [libafs] (inexact)
 0xffffffffa0608b90 [libafs] (inexact)

readelf --sections /vagrant/openafs/src/libafs/MODLOAD-4.4.15-MP/libafs.ko | grep debug
.debug .debug_frame

http://lxr.free-electrons.com/source/include/linux/dcache.h#L108
  108 struct dentry {
  109         /* RCU lookup touched fields */
  110         unsigned int d_flags;           /* protected by d_lock */
  111         seqcount_t d_seq;               /* per dentry seqlock */
  112         struct hlist_bl_node d_hash;    /* lookup hash list */
  113         struct dentry *d_parent;        /* parent directory */
  114         struct qstr d_name;
  115         struct inode *d_inode;          /* Where the name belongs to - NULL is
  116                                          * negative */
  117         unsigned char d_iname[DNAME_INLINE_LEN];        /* small names */
  118
  119         /* Ref lookup also touches following */
  120         struct lockref d_lockref;       /* per-dentry lock and refcount */
  121         const struct dentry_operations *d_op;
  122         struct super_block *d_sb;       /* The root of the dentry tree */
  123         unsigned long d_time;           /* used by d_revalidate */
  124         void *d_fsdata;                 /* fs-specific data */
  125
  126         struct list_head d_lru;         /* LRU list */
  127         struct list_head d_child;       /* child of parent list */
  128         struct list_head d_subdirs;     /* our children */
  129         /*
  130          * d_alias and d_rcu can share memory
  131          */
  132         union {
  133                 struct hlist_node d_alias;      /* inode alias list */
  134                 struct rcu_head d_rcu;
  135         } d_u;
  136 };
