We are going to need system level packages in our case for fedora42.

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

(oops, we first needed to set an environment as the build got sad without it)
```
export QA_RPATHS=$(( 0x0001|0x0010 ))
```

Then you can go on to build the rest - start with rpm_core as the others depend on it.
```
[root@hmxlabs-hpl flux-rpm]# rpm -i RPMS/x86_64/flux-security-0.14.0-1.fc42.x86_64.rpm 
[root@hmxlabs-hpl flux-rpm]# make rpm_core
rpmbuild  -bb SPECS/flux-core.spec \
--define "_topdir /root/flux/cuffbuild/flux-rpm" \
--define "_disable_source_fetch 0"
setting SOURCE_DATE_EPOCH=1754438400
etc...
```

Then install rpm_core and some more deps so you can build sched etc.
```
[root@hmxlabs-hpl flux-rpm]# rpm -i RPMS/x86_64/flux-core-0.77.0-1.fc42.x86_64.rpm 
[root@hmxlabs-hpl flux-rpm]# dnf install ninja-build libedit-devel yaml-cpp-devel python3-jsonschema
[root@hmxlabs-hpl flux-rpm]# make rpm_sched
[root@hmxlabs-hpl flux-rpm]# make rpm_pam
[root@hmxlabs-hpl flux-rpm]# make rpm_wrappers
```

Rejoice!
```
[root@hmxlabs-hpl flux-rpm]# ls -ltra RPMS/x86_64/flux-*
-rw-r--r-- 1 root root   98785 Aug  9 16:34 RPMS/x86_64/flux-security-0.14.0-1.fc42.x86_64.rpm
-rw-r--r-- 1 root root 3501847 Aug  9 17:00 RPMS/x86_64/flux-core-0.77.0-1.fc42.x86_64.rpm
-rw-r--r-- 1 root root  962055 Aug  9 17:06 RPMS/x86_64/flux-sched-0.46.0-1.fc42.x86_64.rpm
-rw-r--r-- 1 root root   15759 Aug  9 17:08 RPMS/x86_64/flux-pam-0.2.0-3.20241210gitb75b87d.fc42.x86_64.rpm
-rw-r--r-- 1 root root   23931 Aug  9 17:08 RPMS/x86_64/flux-wrappers-0.1-1.20250417git418d494.fc42.x86_64.rpm
```

we have not built accounting yet, it needs "imp" and we are now running a python that's too new in fedora42 (3.13.5)

> The error "ModuleNotFoundError: No module named 'imp'" indicates that the imp module cannot be found by your Python installation. This typically occurs in Python versions 3.12 and later because the imp module was deprecated in Python 3.4 and subsequently removed in Python 3.12.

we also need to add a flux user.

```
adduser flux
vipw (I changed uid to 500, not sure it matters)
```

DOh!  we are going to have to work out how to build flux with systemd.
```
Aug 09 17:28:29 hmxlabs-hpl systemd[1]: Starting flux.service - Flux message broker...
░░ Subject: A start job for unit flux.service has begun execution
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░ 
░░ A start job for unit flux.service has begun execution.
░░ 
░░ The job identifier is 12080.
Aug 09 17:28:29 hmxlabs-hpl flux[1302184]: broker: broker.sd_notify is set but Flux was not built with systemd support>
Aug 09 17:28:29 hmxlabs-hpl systemd[1]: flux.service: Main process exited, code=exited, status=1/FAILURE
```

ok this seems to be straightforward need a dep with systemd so the build picks it up.  let's build again after adding a dnf install systemd-devel...

yep that did it!

```
[root@hmxlabs-hpl flux-rpm]# systemctl start flux 
[root@hmxlabs-hpl flux-rpm]# journalctl -xeu flux.service
Aug 09 17:40:42 hmxlabs-hpl systemd[1]: Stopped flux.service - Flux message broker.
░░ Subject: A stop job for unit flux.service has finished
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░ 
░░ A stop job for unit flux.service has finished.
░░ 
░░ The job identifier is 15816 and the job result is done.
Aug 09 17:40:42 hmxlabs-hpl systemd[1]: flux.service: Consumed 1.024s CPU time, 21.6M memory peak.
░░ Subject: Resources consumed by unit runtime
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░ 
░░ The unit flux.service completed and consumed the indicated resources.
Aug 09 17:40:45 hmxlabs-hpl systemd[1]: Starting flux.service - Flux message broker...
░░ Subject: A start job for unit flux.service has begun execution
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░ 
░░ A start job for unit flux.service has begun execution.
░░ 
░░ The job identifier is 15817.
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: start: none->join 0.243368ms
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: parent-none: join->init 0.087679ms
Aug 09 17:40:46 hmxlabs-hpl systemd[1]: Started flux.service - Flux message broker.
░░ Subject: A start job for unit flux.service has finished successfully
░░ Defined-By: systemd
░░ Support: https://lists.freedesktop.org/mailman/listinfo/systemd-devel
░░ 
░░ A start job for unit flux.service has finished successfully.
░░ 
░░ The job identifier is 15817.
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: sdbus.info[0]: unix:path=/run/user/500/bus: connected
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: sdbus-sys.info[0]: sd_bus_open_system: connected
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: rc1.0: restoring content from /var/lib/flux/dump/20250809_174042.tgz
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: kvs.info[0]: restored KVS from checkpoint on 2025-08-09T17:40:42Z
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: cron.info[0]: synchronizing cron tasks to event heartbeat.pulse
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: job-manager.info[0]: restart: 0 jobs
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: job-manager.info[0]: restart: 0 running jobs
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: rc1.0: /etc/flux/rc1 Exited (rc=0) 0.4s
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: rc1-success: init->quorum 0.409916s
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: online: hmxlabs-hpl (ranks 0)
Aug 09 17:40:46 hmxlabs-hpl flux[1358309]: broker.info[0]: quorum-full: quorum->run 0.100978s
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
