Here we made some deb files for flux. debs directory here has the builds, [trixie_flux_buildhost.sh](https://github.com/DrCuff/hpc/blob/main/flux/Debian/trixie_flux_buildhost.sh) just raises a normal debian to be able to start and/or even build flux
_WARNING: we are still missing flux_pam_

### time to make some debs, and get the gits!

_first become a user - tests get all super weird if not, you know how to make a user right?  you just put your lips together and blow_

```sudo su - flux```

_set up some things:_
```
git config --global user.name 'James Cuff'
git config --global user.email james@witnix.com
```

_get cloning!_

```
git clone --branch v0.14.0 https://github.com/flux-framework/flux-security.git
git clone --branch v0.77.0 https://github.com/flux-framework/flux-core.git
git clone --branch v0.46.0 https://github.com/flux-framework/flux-sched.git
git clone --branch v0.2.0  https://github.com/flux-framework/flux-pam.git
git clone --branch v0.49.0 https://github.com/flux-framework/flux-accounting.git
```

### it buildy time!

_security first!_

```
cd flux-security
autogen.sh
./configure
make -j8 deb
```

### woot!
```-rw-r--r-- 1 flux flux  77408 Aug 12 02:18 debbuild/flux-security_0.14.0_amd64.deb```

_can install?  (we have to, so we install)_

```sudo dpkg -i ./debbuild/flux-security_0.14.0_amd64.deb```

_yep!  onwards!_

```
cd ../flux-core
autogen.sh
./configure
make -j8 deb
```

_awww yeah - install core!_

```
flux@hmx-flux-head:~/flux-core$ sudo dpkg -i debbuild/flux-core_0.77.0-15-g185be1209_amd64.deb .
```

_ok libpam is different...  can't make a deb file for this. will need to come back to this_

```
cd ../flux-pam
./autogen.sh 
./configure
make install
```

_setup sched.  test will fail if not._

```sudo mkdir /etc/flux/system/conf.d```


_do the etc toml thing._

```wget https://github.com/DrCuff/hpc/blob/main/flux/etc.toml.sh```


_sched... (cuff, you need more disk space and DRAM for this build, stop being cheap)_

```
cd ../flux-sched
./autogen.sh
./configure
make -j8 deb
```

_accounting._

```
cd ../flux-accounting
./autogen.sh
./configure
make -j8 deb
```

## woof! done!
```
flux@hmx-flux-head:~/flux-accounting$ ls -ltra ../debs/
total 5592
-rw-rw-r-- 1 flux flux  668251 Aug 12 02:41 flux-security-0.14.0.tar.gz
-rw-r--r-- 1 flux flux 4055060 Aug 12 02:50 flux-core_0.77.0-15-g185be1209_amd64.deb
drwx------ 8 flux flux    4096 Aug 12 03:21 ..
-rw-r--r-- 1 flux flux  819720 Aug 12 03:26 flux-sched_0.46.0_amd64.deb
-rw-r--r-- 1 flux flux  162400 Aug 12 03:30 flux-accounting_0.49.0_amd64.deb
