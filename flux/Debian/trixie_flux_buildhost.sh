# bring up a trixie debian 13 and bootstrap flux into it

#!/bin/bash

export FLUX_CORE_VERS=0.77.0
export FLUX_SECURITY_VERS=0.14.0
export FLUX_PAM_VERS=0.2.0
export FLUX_SCHED_VERS=0.46.0

apt update
apt upgrade

apt install -y \
  autoconf \
  automake \
  libtool \
  make \
  pkg-config \
  libc6-dev \
  libzmq3-dev \
  uuid-dev \
  libjansson-dev \
  liblz4-dev \
  libarchive-dev \
  libhwloc-dev \
  libsqlite3-dev \
  lua5.1 \
  liblua5.1-dev \
  lua-posix \
  python3-dev \
  python3-cffi \
  python3-ply \
  python3-setuptools \
  python3-yaml \
  python3-sphinx \
  aspell \
  aspell-en \
  time \
  valgrind \
  libmpich-dev \
  jq \
  systemd-dev \
  libsystemd-dev \
  libsodium-dev \
  libjansson-dev \
  uuid-dev \
  libmunge-dev \
  libpam0g-dev \
  munge \
  git \
  cmake \
  libhwloc-dev \
  libboost-dev \
  libboost-graph-dev \
  libedit-dev \
  libyaml-cpp-dev \
  python3-yaml \
  python3-jsonschema \
  devscripts \
  libpam-wrapper \
  wget


# flux security
wget https://github.com/flux-framework/flux-security/releases/download/v$FLUX_SECURITY_VERS/flux-security-$FLUX_SECURITY_VERS.tar.gz
tar zxf flux-security-$FLUX_SECURITY_VERS.tar.gz 
cd flux-security-$FLUX_SECURITY_VERS
./configure
make -j8 install

cd ..

# flux core
wget https://github.com/flux-framework/flux-core/releases/download/v$FLUX_CORE_VERS/flux-core-$FLUX_CORE_VERS.tar.gz
tar zxf flux-core-$FLUX_CORE_VERS.tar.gz 
cd flux-core-$FLUX_CORE_VERS
./configure --with-flux-security --with-systemdsystemunitdir=/etc/systemd/system/ 
make -j8 install

cd ..

# flux pam
wget https://github.com/flux-framework/flux-pam/releases/download/v$FLUX_PAM_VERS/flux-pam-$FLUX_PAM_VERS.tar.gz
tar zxf flux-pam-$FLUX_PAM_VERS.tar.gz 
cd flux-pam-$FLUX_PAM_VERS
./configure
make install

cd ..

ldconfig
useradd flux

# keys
flux keygen /usr/local/etc/flux/test.cert
chown flux:flux /usr/local/etc/flux/test.cert
chmod 600 /usr/local/etc/flux/test.cert

# make an initial toml
mkdir /usr/local/etc/flux/system/conf.d/
cat <<EOF > /usr/local/etc/flux/system/conf.d/hosts.toml

[bootstrap]
curve_cert = "/usr/local/etc/flux/test.cert"
default_port = 8060
default_bind = "tcp://enp5s0:%p"
default_connect = "tcp://%h:%p"

hosts = [
    # Management requires non-default config
    { host="hmx-flux-head" },
    # Other nodes use defaults
    { host = "flux[1-10]" },
]
EOF

cat <<EOF > /usr/local/etc/flux/system/conf.d/system.toml
# Enable the sdbus and sdexec broker modules
[systemd]
enable = true

# Flux needs to know the path to the IMP executable
[exec]
imp = "/usr/local/libexec/flux/flux-imp"

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
hosts = "flux[1-10],hmx-flux-head"
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
allowed-shells = [ "/usr/local/libexec/flux/flux-shell" ]

# Enable the "flux" PAM stack (requires PAM configuration file)
pam-support = true

EOF

# munge on debian makes it's own key it generates on install
systemctl enable munge
systemctl start munge

# install schedule on head node

# flux sched (4GB isn't enough memory it OOMs with -j16)
wget https://github.com/flux-framework/flux-sched/releases/download/v$FLUX_SCHED_VERS/flux-sched-$FLUX_SCHED_VERS.tar.gz
tar zxf flux-sched-$FLUX_SCHED_VERS.tar.gz 
cd flux-sched-$FLUX_SCHED_VERS
./configure
make -j8 install

cd ..


systemctl enable flux
systemctl start flux

flux resource list
flux module list
