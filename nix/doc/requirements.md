# Requirements

## General system requirements

The system should meet two basic requirement:

* Run Linux or OS X on the local workstation
* Install the [nix package manager](https://nixos.org/nix/)
* Install `git`

## TIP: Installing the nix package manager

The `nix` package manager is used for downloading binaries.  It stores the
binaries in the folder `/nix`.  This design provides isolation/independence
from your host operating system (Ubuntu, RedHat, OSX, etc).

The conventional install process is to construct a command like ONE of these:

```
sh <(curl -L https://nixos.org/nix/install) --daemon

sh <(curl -L https://nixos.org/nix/install) --no-daemon

sh <(curl -L https://nixos.org/nix/install) --no-daemon --darwin-use-unencrypted-nix-store-volume
```

The exact command depends on the operating system and use-case.  For a more
complete discussion of installation options, see https://nixos.org/nix/manual/

Alternatively, you may use the script `bin/install-nix.sh` to start the
installer.  It will present a few introductory questions to address common
options and suggestions:

```
git clone https://github.com/civicrm/civicrm-buildkit ~/bknix
cd ~/bknix
./nix/bin/install-nix.sh
```

After running the script, you will need to re-initialize bash (i.e.  close
the shell and open a new one).

## General knowledge requirements

Additionally, you should have some basic understanding of the tools/systems involved:

* Git
* PHP/JS development (e.g. `composer`, `npm`)
* Unix CLI (e.g. `bash`)
* Process management (e.g. `ps`, `kill`), esp for `httpd` and `mysqld`
* Filesystem management (e.g. "Disk Utility" on OSX; `umount` on Linux)
