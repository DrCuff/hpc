We are going to need systemd packages in our case for fedora.

Enterprising folks have setup an RPM package [here](https://gitlab.jsc.fz-juelich.de/maloney2/flux-rpm)

So far we have needed:
```
  634  git clone https://gitlab.jsc.fz-juelich.de/maloney2/flux-rpm.git
  635  cd flux-rpm/
  636  ls
  637  make
  638  dnf install rpmbuild pam-devel
  643  ./install-deps.sh 
  644  make
  645  dnf install munge-devel
```

Then you can do make, this builds security RPM which you install to them make the rest of it:
```
[root@hmxlabs-hpl flux-rpm]# rpm -i RPMS/x86_64/flux-security-0.14.0-1.fc42.x86_64.rpm 
[root@hmxlabs-hpl flux-rpm]# make rpm_core
rpmbuild  -bb SPECS/flux-core.spec \
--define "_topdir /root/flux/cuffbuild/flux-rpm" \
--define "_disable_source_fetch 0"
setting SOURCE_DATE_EPOCH=1754438400
etc...
```

# background

Packages

RPM packages for TOSS 4 (RHEL 8 based) are produced by the TOSS build system and 
can be made available externally on request. When requested, these are manually 
added to the release assets on github.

deb packages for Debian or Ubuntu can be built from a release tarball with make deb, 
producing debs in the debbuild sub-directory. This target is used by some Flux team 
members to build packages for test clusters running the Raspberry Pi OS (Debian/GNU 11).

Flux core can be made with spack of course.
```
git clone --depth=100 https://github.com/spack/spack.git

cd spack
. share/spack/setup-env.sh

spack install flux-core@0.54.0 %gcc@11.4.0

spack find flux-core
-- linux-ubuntu22.04-zen2 / gcc@11.4.0 --------------------------
flux-core@0.54.0
==> 1 installed package

spack load flux-core
```
