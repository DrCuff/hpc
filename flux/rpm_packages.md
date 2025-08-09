We are going to need systemd packages in our case for fedora.

Enterprising folks have setup an RPM package [here](https://gitlab.jsc.fz-juelich.de/maloney2/flux-rpm)


Packages

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
