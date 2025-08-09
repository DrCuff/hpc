Quick and dirty way to get ten nodes stood up with flux installed inside them.  Some unnatural acts of computing here to make it so that you can use podman and fedora 42 to connect the initial host and the ten pods together in a "flux".

# fetch the latest code
```
./get_latest.sh
```

# build
```
podman build -t cuff_flux .
```

# run
```
./start_cluster.sh
```
# copy the toml
```
[root@hmxlabs-hpl cuffbuild]# for i in {1..10}; do podman cp remote.toml flux$i:/home/fluxuser/test.toml; done
```

# results
```
[root@hmxlabs-hpl cuffbuild]# podman ps
CONTAINER ID  IMAGE                       COMMAND     CREATED        STATUS        PORTS       NAMES
d05db7eea892  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux1
296e23faafd8  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux2
20a31e86025c  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux3
ca4d2b8560de  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux4
0a012f98356c  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux5
42148e1566b7  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux6
58cd1d964631  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux7
445758141fe1  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux8
cc7625c02ac1  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux9
b18191cc024d  localhost/cuff_flux:latest              8 minutes ago  Up 8 minutes              flux10

[root@hmxlabs-hpl cuffbuild]# pdsh -N -w flux[1-10],hmxlabs-hpl flux start -o,--config-path=/home/fluxuser/test.toml flux resource list
     STATE NNODES NCORES NGPUS NODELIST
      free     11     88     0 hmxlabs-hpl,flux[1-10]
 allocated      0      0     0 
      down      0      0     0 

```

# getting munge up on fedora host image and check it works:
```
[root@hmxlabs-hpl ~]# sudo dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key ; chmod 600 /etc/munge/munge.key ; chown munge:munge /etc/munge/munge.key
1024+0 records in
1024+0 records out
1024 bytes (1.0 kB, 1.0 KiB) copied, 0.00917941 s, 112 kB/s

[root@hmxlabs-hpl ~]# systemctl enable munge
Created symlink '/etc/systemd/system/multi-user.target.wants/munge.service' → '/usr/lib/systemd/system/munge.service'.

[root@hmxlabs-hpl ~]# systemctl start munge

[root@hmxlabs-hpl ~]# echo xyz | ssh localhost munge | ssh localhost unmunge
STATUS:          Success (0)
ENCODE_HOST:     hmxlabs-hpl (10.89.1.1)
ENCODE_TIME:     2025-08-09 15:11:27 +0000 (1754752287)
DECODE_TIME:     2025-08-09 15:11:27 +0000 (1754752287)
TTL:             300
CIPHER:          aes128 (4)
MAC:             sha256 (5)
ZIP:             none (0)
UID:             root (0)
GID:             root (0)
LENGTH:          4

xyz
```

Now copy it to the remotes and start the services:
```
[root@hmxlabs-hpl ~]# pdsh -w flux[1-10] dnf install -y pdsh pdsh-rcmd-ssh  # initial image didn't have this in the Dockerfile, does now
[root@hmxlabs-hpl ~]# pdcp -w flux[1-10] /etc/munge/munge.key /etc/munge/

[root@hmxlabs-hpl ~]# pdsh -w flux[1-10] "chmod 600 /etc/munge/munge.key ; chown munge:munge /etc/munge/munge.key; systemctl enable munge"
```

then boot munge and check it:

```
[root@hmxlabs-hpl ~]# pdsh -w flux[1-10] systemctl start munge

[root@hmxlabs-hpl ~]# pdsh -w flux[1-10] systemctl is-active munge | dshbak -c
----------------
flux[1-10]
----------------
active

[root@hmxlabs-hpl ~]# echo xyz | ssh flux1 munge | ssh flux2 unmunge
STATUS:          Success (0)
ENCODE_HOST:     flux1 (10.89.1.78)
ENCODE_TIME:     2025-08-09 15:18:18 +0000 (1754752698)
DECODE_TIME:     2025-08-09 15:18:18 +0000 (1754752698)
TTL:             300
CIPHER:          aes128 (4)
MAC:             sha256 (5)
ZIP:             none (0)
UID:             root (0)
GID:             root (0)
LENGTH:          4

xyz

```

