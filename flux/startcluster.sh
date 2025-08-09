podman network create flux_net

for i in {1..10}; do podman run -dit --replace --hostname flux$i --network flux_net --name flux$i cuff_flux; done

# fix up ssh keys
for i in {1..10}; do ssh -oStrictHostKeyChecking=no flux$i uname -a; done

