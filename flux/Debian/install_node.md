Work in progress!

```
lxc stop hmx-node-001
lxc delete hmx-node-001
lxc init images:debian/13 --vm hmx-node-001
lxc config set hmx-node-001 limits.cpu 8
lxc start hmx-node-001
```

(clean remote compute machine - cloud-init-testing)

testing need to ssh into it...

``` lxc exec hmx-node-001 bash ```

This needs to run...

```
useradd flux

sudo apt install -y wget libjansson4 libmunge2 libarchive13t64 libhwloc15 liblua5.1-0 libpython3.13 libzmq5 libboost-graph1.83.0 libyaml-cpp0.8 hwloc

wget https://github.com/DrCuff/hpc/raw/refs/heads/main/flux/Debian/debs/flux-security_0.14.0_amd64.deb
wget https://github.com/DrCuff/hpc/raw/refs/heads/main/flux/Debian/debs/flux-core_0.77.0-15-g185be1209_amd64.deb
wget https://github.com/DrCuff/hpc/raw/refs/heads/main/flux/Debian/debs/flux-sched_0.46.0_amd64.deb

dpkg -i ./flux-security_0.14.0_amd64.deb
dpkg -i ./flux-core_0.77.0-15-g185be1209_amd64.deb
dpkg -i ./flux-sched_0.46.0_amd64.deb

flux keygen /etc/flux/test.cert
chown flux:flux /etc/flux/test.cert
chmod 600 /etc/flux/test.cert

```

The toml etc. will move to cloud-init, for now:

```
mkdir /etc/flux/system/conf.d/
cat <<EOF > /etc/flux/system/conf.d/hosts.toml

[bootstrap]
curve_cert = "/etc/flux/test.cert"
default_port = 8060
default_bind = "tcp://enp5s0:%p"
default_connect = "tcp://%h:%p"

hosts = [
    # Management requires non-default config
    { host="hmx-flux-head" },
    # Other nodes use defaults
    { host = "hmx-node-00[1-10]" },
]
EOF

cat <<EOF > /etc/flux/system/conf.d/system.toml
# Enable the sdbus and sdexec broker modules
[systemd]
enable = true

# Flux needs to know the path to the IMP executable
[exec]
imp = "/usr/lib/x86_64-linux-gnu/flux/flux-imp"

# Run jobs in a systemd user instance
service = "sdexec"

# Limit jobs to a percentage of physical memory
[exec.sdexec-properties]
MemoryMax = "95%"

# Allow users other than the instance owner (guests) to connect to Flux
# Optionally, root may be given "owner privileges" for convenience
[access]
allow-guest-user = true
allow-root-owner = true

# Point to shared network certificate generated flux-keygen(1).
# Define the network endpoints for Flux's tree based overlay network
# and inform Flux of the hostnames that will start flux-broker(1).
# Speed up detection of crashed network peers (system default is around 20m)
[tbon]
tcp_user_timeout = "2m"

# Uncomment 'norestrict' if flux broker is constrained to system cores by
# systemd or other site policy.  This allows jobs to run on assigned cores.
# Uncomment 'exclude' to avoid scheduling jobs on certain nodes (e.g. login,
# management, or service nodes).
[resource]
#norestrict = true
#exclude = "test[1-2]"

[[resource.config]]
hosts = "hmx-node[001-010],hmx-flux-head"
cores = "0-7"
gpus = "0"


# Store the kvs root hash in sqlite periodically in case of broker crash.
# Recommend offline KVS garbage collection when commit threshold is reached.
[kvs]
checkpoint-period = "30m"
gc-threshold = 100000

# Immediately reject jobs with invalid jobspec or unsatisfiable resources
[ingest.validator]
plugins = [ "jobspec", "feasibility" ]

# Remove inactive jobs from the KVS after one week.
[job-manager]
inactive-age-limit = "7d"

# Jobs submitted without duration get a very short one
[policy.jobspec.defaults.system]
duration = "1m"

# Jobs that explicitly request more than the following limits are rejected
[policy.limits]
duration = "2h"
job-size.max.nnodes = 8
job-size.max.ncores = 32

# Configure the flux-sched (fluxion) scheduler policies
# The 'lonodex' match policy selects node-exclusive scheduling, and can be
# commented out if jobs may share nodes.
[sched-fluxion-qmanager]
queue-policy = "easy"
[sched-fluxion-resource]
match-policy = "lonodex"
match-format = "rv1_nosched"

EOF

# set up imp

mkdir -p /usr/local/etc/flux/imp/conf.d/

cat <<EOF > /usr/local/etc/flux/imp/conf.d/imp.toml

# Only allow access to the IMP exec method by the 'flux' user.
# Only allow the installed version of flux-shell(1) to be executed.
[exec]
allowed-users = [ "flux" ]
allowed-shells = [ "/usr/lib/x86_64-linux-gnu/flux/flux-shell" ]

# Enable the "flux" PAM stack (requires PAM configuration file)
pam-support = true

EOF

cat <<EOF > /etc/flux/security/conf.d/security.toml
# Job requests should be valid for 2 weeks
# Use munge as the job request signing mechanism
[sign]
max-ttl = 1209600  # 2 weeks
default-type = "munge"
allowed-types = [ "munge" ]

EOF
```
