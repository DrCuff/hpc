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

### buildy time.

```apt install devscripts libpam-wrapper```

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

