# keys
flux keygen /etc/flux/test.cert
chown flux:flux /etc/flux/test.cert
chmod 600 /etc/flux/test.cert

# make an initial toml
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
    { host = "flux[1-10]" },
]
EOF

cat <<EOF > /etc/flux/system/conf.d/system.toml
# Enable the sdbus and sdexec broker modules
[systemd]
enable = true

# Flux needs to know the path to the IMP executable
[exec]
imp = "/libexec/flux/flux-imp"

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

mkdir -p /etc/flux/imp/conf.d/

cat <<EOF > /etc/flux/imp/conf.d/imp.toml

# Only allow access to the IMP exec method by the 'flux' user.
# Only allow the installed version of flux-shell(1) to be executed.
[exec]
allowed-users = [ "flux" ]
allowed-shells = [ "/usr/local/libexec/flux/flux-shell" ]

# Enable the "flux" PAM stack (requires PAM configuration file)
pam-support = true

EOF

