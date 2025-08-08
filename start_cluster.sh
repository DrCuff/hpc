#!/bin/bash

# make a little 10 node test cluster using fluxrm/flux-sched:latest, patches it up with ssh and things

# stop cluster
# for i in {1..10}; do podman stop flux$i; done

# initial setup - replace all the things, blank slate, hostname needs to be done at start

for i in {1..10}; do podman run -dit --replace --hostname flux$i --network flux_net --name flux$i fluxrm/flux-sched:latest; done

# install some things

for i in {1..10}; do podman exec flux$i sudo apt-get update; done
for i in {1..10}; do podman exec flux$i sudo apt-get -y install ssh; done

# add the ssh key

for i in {1..10}; do podman exec flux$i sudo mkdir /root/.ssh; done
for i in {1..10}; do podman cp ~/.ssh/id_ed25519.pub flux$i:/root/.ssh/authorized_keys; done
for i in {1..10}; do podman exec flux$i sudo chmod 600 /root/.ssh/authorized_keys; done
for i in {1..10}; do podman exec flux$i sudo chown -R root /root/.ssh/; done
for i in {1..10}; do podman exec flux$i sudo /etc/init.d/ssh start; done

# make a hosts file:

rm flux.hosts
for i in {1..10}; do echo flux$i >> flux.hosts; done

# auto accept host keys.

for i in {1..10}; do ssh -oStrictHostKeyChecking=no flux$i uname -a; done

#use a pod to make a cert

ssh flux1 flux keygen /home/fluxuser/test.cert
podman cp flux1:/home/fluxuser/test.cert .
for i in {1..10}; do podman cp test.cert flux$i:/home/fluxuser/test.cert; done

# push the toml

for i in {1..10}; do podman cp test.toml flux$i:/home/fluxuser/test.toml; done

# check we have the right pdsh with ssh

sudo dnf install pdsh pdsh-rcmd-ssh

export PDSH_RCMD_TYPE=ssh

# finally the flux!

pdsh -N -w flux[1-10] flux start -o,--config-path=/home/fluxuser/test.toml flux resource list

#      STATE NNODES NCORES NGPUS NODELIST
#       free     10     80     0 flux[1-10]
#  allocated      0      0     0 
#       down      0      0     0 
