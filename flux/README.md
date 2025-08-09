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
[root@hmxlabs-hpl cuffbuild]# pdsh -N -w flux[1-10],hmxlabs-hpl flux start -o,--config-path=/home/fluxuser/test.toml flux resource list
     STATE NNODES NCORES NGPUS NODELIST
      free     11     88     0 hmxlabs-hpl,flux[1-10]
 allocated      0      0     0 
      down      0      0     0 
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
