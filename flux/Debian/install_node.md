Work in progress!

```
jcuff@amdmini:~$ lxc stop hmx-node-001
jcuff@amdmini:~$ lxc delete hmx-node-001
jcuff@amdmini:~$ lxc init images:debian/13 --vm hmx-node-001
Creating hmx-node-001
jcuff@amdmini:~$ lxc start hmx-node-001
```
(clean remote compute machine)

```
adduser flux

apt install -y wget libjansson4 libmunge2 libarchive13t64 libhwloc15 liblua5.1-0 libpython3.13 libzmq5 


wget https://github.com/DrCuff/hpc/raw/refs/heads/main/flux/Debian/debs/flux-security_0.14.0_amd64.deb
wget https://github.com/DrCuff/hpc/raw/refs/heads/main/flux/Debian/debs/flux-core_0.77.0-15-g185be1209_amd64.deb

dpkg -i ./flux-security_0.14.0_amd64.deb
dpkg -i ./flux-core_0.77.0-15-g185be1209_amd64.deb
```
