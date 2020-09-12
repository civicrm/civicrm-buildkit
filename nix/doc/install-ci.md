# Installation for Jenkins/CI Worker nodes (*arrbuk*)

A Jenkins/CI worker node, we want all profiles to be used concurrently. For each profile:

* There is a configuration file, `.loco/USER-PROFILE.yaml` which lists the services.
* The binaries are installed to `/nix/var/nix/profiles/bknix-PROFILE/bin`
* The data directory is `~/bknix-PROFILE`
* Each service from the YAML file is installed in `systemd`
* Each service has its own unique port.

| Service     | dfl Port     | min Port     | max Port     |
|-------------|--------------|--------------|--------------|
| Apache HTTP | 8001         | 8002         | 8003         |
| Memcached   | 12221        | 12222        | 12223        |
| MySQL       | 3307         | 3308         | 3309         |
| PHP FPM     | 9009         | 9010         | 9011         |
| PHP Xdebug  | 9000         | 9000         | 9000         |
| Redis       | 6380         | 6381         | 6382         |

## Steps

(*These steps were developed on Debian 9.*)

```bash
## Install multiuser nix pkg mgr, per https://nixos.org/nix/manual/#sect-multi-user-installation
sudo apt-get install rsync
sh <(curl https://nixos.org/nix/install) --daemon

## Get the config file
sudo -i bash
git clone https://github.com/totten/bknix /root/bknix
cd /root/bknix

## Optional: If you want to change the ramdisk config, then create files like:
mkdir /etc/bknix-ci
echo RAMDISKSIZE=12G >> /etc/bknix-ci/install_all_jenkins.sh
echo RAMDISKSIZE=700M >> /etc/bknix-ci/install_all_publisher.sh

## Initialize the min, max, and dfl profiles for the test user "jenkins"
./bin/install-ci.sh

## Do a trial run
su - totten
eval $(use-bknix dfl)
which php
php --version
# (...and exit...)
```
