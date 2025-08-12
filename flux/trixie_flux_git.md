### time to make some debs, and get the gits!


### first become a user - tests get all super weird if not:
```sudo su - flux```

```
git clone --branch v0.14.0 https://github.com/flux-framework/flux-security.git
git clone --branch v0.77.0 https://github.com/flux-framework/flux-core.git
git clone --branch v0.46.0 https://github.com/flux-framework/flux-sched.git
git clone --branch v0.2.0 https://github.com/flux-framework/flux-pam.git
git clone --branch v0.49.0 https://github.com/flux-framework/flux-accounting.git
```

### it's buildy time!

```apt install devscripts libpam-wrapper sqlite3```

### set some things:
```
git config --global user.name 'James Cuff'
git config --global user.email james@witnix.com
```

### build!
```
cd flux-security
autogen.sh
./configure
make -j8 deb
```

### woot!

```-rw-r--r-- 1 flux flux  77408 Aug 12 02:18 debbuild/flux-security_0.14.0_amd64.deb```

### can install?  (we have to)

```sudo dpkg -i ./debbuild/flux-security_0.14.0_amd64.deb```

### yep!  onwards!

```
cd ../flux-core
autogen.sh
./configure
make -j8 deb
```
### awww yeah!

```
flux@hmx-flux-head:~/flux-core$ sudo dpkg -i debbuild/flux-core_0.77.0-15-g185be1209_amd64.deb 
Selecting previously unselected package flux-core.
(Reading database ... 78433 files and directories currently installed.)
Preparing to unpack .../flux-core_0.77.0-15-g185be1209_amd64.deb ...
Unpacking flux-core (0.77.0-15-g185be1209) ...
Setting up flux-core (0.77.0-15-g185be1209) ...
Could not execute systemctl:  at /usr/bin/deb-systemd-invoke line 148.
Processing triggers for libc-bin (2.41-12) ...
Processing triggers for man-db (2.13.1-1) ...
```

### ok libpam is different...  can't make a deb file for this.
```
cd ../flux-pam
./autogen.sh 
./configure
make install
```
### setup sched.  test will fail if not.

sudo mkdir /etc/flux/system/conf.d


### do the etc toml thing.

https://github.com/DrCuff/hpc/blob/main/flux/etc.toml.sh


### sched... (cuff, you need more disk space and DRAM for this build, stop being cheap)
```
cd ../flux-sched
./autogen.sh
./configure
make -j8 deb
```

### accounting.
```
cd ../flux-accounting
./autogen.sh
./configure
make -j8 deb
```

## woof!
```
flux@hmx-flux-head:~/flux-accounting$ ls -ltra ../debs/
total 5592
-rw-rw-r-- 1 flux flux  668251 Aug 12 02:41 flux-security-0.14.0.tar.gz
-rw-r--r-- 1 flux flux 4055060 Aug 12 02:50 flux-core_0.77.0-15-g185be1209_amd64.deb
drwx------ 8 flux flux    4096 Aug 12 03:21 ..
-rw-r--r-- 1 flux flux  819720 Aug 12 03:26 flux-sched_0.46.0_amd64.deb
-rw-r--r-- 1 flux flux  162400 Aug 12 03:30 flux-accounting_0.49.0_amd64.deb
drwxrwxr-x 2 flux flux    4096 Aug 12 03:30 .
```
