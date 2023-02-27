# Installation for Jenkins/CI Worker nodes (Transactional)

A Jenkins/CI worker node. All binaries/profiles are preinstalled. Services are stopped and started transactionally (*for specific tasks*).

* There is a configuration file, `.loco/worker-n.yml` which lists the services.
* The binaries are installed to `/nix/var/nix/profiles/bknix-PROFILE/bin`
* The data directory is `~/bknix`
* Services are started and stopped as-needed (using `loco start` or `loco run`).
* Each service has its own unique port.

| Service     | Worker 0     | Worker 1     | Worker 2     |
|-------------|--------------|--------------|--------------|
| Apache HTTP | 5000         | 5100         | 5200         |
| Memcached   | 5006         | 5106         | 5206         |
| MySQL       | 5001         | 5101         | 5201         |
| PHP FPM     | 5002         | 5102         | 5202         |
| PHP Xdebug  | 9003         | 9003         | 9003         |
| Redis       | 5005         | 5105         | 5205         |

## Initial installation

(*These steps were developed on Debian 9.*)

```bash
## Install multiuser nix pkg mgr, per https://nixos.org/nix/manual/#sect-multi-user-installation
sudo apt-get install rsync
sh <(curl https://nixos.org/nix/install) --daemon

## Get the config file
sudo -i bash
git clone https://github.com/civicrm/civicrm-buildkit /opt/buildkit
cd /opt/buildkit

## Initialize the min, max, and dfl profiles for the users "jenkins" and "publisher"
./nix/bin/install-runner.sh

## Do a trial run
su - jenkins
EXECUTOR_NUMBER=1 use-bknix dfl -s -N
which php
php --version
loco start
# ... and so on ...
loco stop
```

## Updates

There are two typical levels of updates:

1. (*Lighter*) Update all copies of `civicrm-buildkit.git` to revise the common CLI tools (`cv`, `drush`, etc).
2. (*More thorough*) Update all copies of `civicrm-buildkit.git` as well as all service binaries (`httpd`, `mysqld`, etc).

For the lighter update:

```bash
sudo -i bash
cd /opt/buildkit/
./nix/bin/update-ci-buildkit.sh
```

For a the thorough update:

```bash
sudo -i bash
cd /opt/buildkit/
./nix/bin/install-ci.sh
```

(TIP: If this complains about missing nix commands, then the call to su/sudo may not have properly managed
the environment. Try a different form of su/sudo.)
