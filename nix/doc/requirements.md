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

To install, run one of these commands as your regular (sudo-capable) user:

```
sh <(curl https://nixos.org/nix/install) --daemon

sh <(curl https://nixos.org/nix/install) --no-daemon

sh <(curl https://nixos.org/nix/install) --no-daemon --darwin-use-unencrypted-nix-store-volume
```

In choosing the install command, there are a few considerations:

* __Which operating system?__

    * In Linux platforms and older macOS platforms, the installer can simply create a `/nix` folder in the system root.
    * In newer macOS platforms (Catalina; v10.15+), [the `/nix` folder cannot be stored directly in the system root](https://github.com/NixOS/nix/issues/2925).
      As workaround, the option `--darwin-use-unencrypted-nix-store-volume` creates a separate partition (volume) for `/nix`.

* __How many workstation users?__

    * __Multi-user mode (`--daemon`)__: Multiple users will be allowed to work with `nix`.
      The `/nix` folder will be managed as a system service.
      It's (slightly) more robust and (slightly) more secure, but it has (slightly) higher system requirements.
      (Ex: *For Linux, the host OS must have `systemd`.*)
      The manual has more complete [install and uninstall instructions](https//nixos.org/nix/manual/#sect-multi-user-installation).

    * __Single-user mode (`--no-daemon`)__: Only one user will be allowed to work with `nix`.
      The `/nix` folder will be managed exclusively for your regular console user.
      It has (slightly) broader compatibility, and it's (slightly) easier to uninstall, but it's (slightly) less secure.
      The manual has more complete [install and uninstall instructions](https://nixos.org/nix/manual/#sect-single-user-installation).

    > NOTE: The "daemon" in "multi-user" mode is an internal service that facilitates download/installation (akin to
    > `dockerd`).  For our purposes, `nix` does not start, stop, or register any network services; it's main job is to
    > download binaries into `/nix`.

For a more complete discussion of installation options, see https://nixos.org/nix/manual/

## General knowledge requirements

Additionally, you should have some basic understanding of the tools/systems involved:

* Git
* PHP/JS development (e.g. `composer`, `npm`)
* Unix CLI (e.g. `bash`)
* Process management (e.g. `ps`, `kill`), esp for `httpd` and `mysqld`
* Filesystem management (e.g. "Disk Utility" on OSX; `umount` on Linux)
