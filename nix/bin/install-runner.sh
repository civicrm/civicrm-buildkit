#!/usr/bin/env bash

# `install-runner.sh` prepares a system to perform transactional test-runs for test.civicrm.org.
# The script may be used for new installs and post-boot self-updates.
#
# Pre-requisites:
#
#   - Install Debian or Ubuntu
#   - Install the "nix" package manager in multiuser mode
#   - Login as proper root (e.g. `sudo -i bash`)
#   - Checkout `civicrm-buildkit.git` as `/opt/buildkit`
#
# What this script does:
#
#   - Create user `dispatcher`. Authorize `test.civicrm.org` to login as `dispatcher`.
#   - Install "homerdo". Authorize `dispatcher` to run `homerdo`.
#   - Install a few other utilities/dependencies (`qemu-img`, `run-bknix-job`, `await-bknix`, `ssh-socket-forward`).
#   - Warm-up `/nix/store` with packages referenced by `/opt/buildkit/nix/profiles/*`
#
# After installation, the "dispatcher" can run commands like this:
#
#   $ homerdo -i example.img nix-shell -p php81
#
#   (Create a new home directory for `homer` stored in `example.img`, then
#   open a nix shell with PHP 8.1 CLI.)
#
# What it doesn't do:
#
#   - Register systemd services for php/mysql/etc. (These run transactionally.)
#   - Build specific homer images. (This are created as-needed by `run-bknix-job`.)
#
# Example: Install (or upgrade) all the profiles
#   ./bin/install-runner.sh
#
# Example: Install (or upgrade) all the profiles, overwriting any local config files
#   FORCE_INIT=-f ./bin/install-runner.sh


###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################
## Main

BKNIX_CI_TEMPLATE="runner"

assert_root_user
check_reqs
if [ -f "/var/local/bknix-ready" ]; then
  rm -f /var/local/bknix-ready
fi

install_cachix
init_folder "$BKNIXSRC/examples/$BKNIX_CI_TEMPLATE" /etc/bknix-ci
touch /etc/bknix-ci/is-runner
install_bin "$BKNIXSRC/../bin/homerdo"      /usr/local/bin/homerdo
install_bin "$BKNIXSRC/../bin/slotdo"       /usr/local/bin/slotdo
install_bin "$BKNIXSRC/../bin/ssh-socket-forward" /usr/local/bin/ssh-socket-forward
#install_bin "$BINDIR"/use-bknix             /usr/local/bin/use-bknix
install_bin "$BINDIR"/await-bknix.flag-file /usr/local/bin/await-bknix
install_bin "$BINDIR"/run-bknix-job         /usr/local/bin/run-bknix-job

# `util-linux` on Ubuntu Jammy and Debian Bullseye is v2.37. There was a regression in handling POSIX signals (introduced ~v2.36; fixed ~v2.38) which
# impacts children processes (incl homerdo). The regression interferes with using `kill`, `Ctrl-C`, `systemctl stop`, etc. To
# fix, we download a statically-linked copy of unshare v2.38.1.
case "$(lsb_release -cs)" in
  jammy|bullseye)
    install_bin_url https://storage.googleapis.com/civicrm/util-linux/unshare-2.38.1.bin /usr/local/lib/unshare-2.38.1.bin /usr/local/bin/unshare
    ;;
  *)
    if [ -L /usr/local/bin/unshare -a -f /usr/local/lib/unshare-2.38.1.bin ]; then
      rm /usr/local/bin/unshare
    fi
    ;;
esac

apt-get install -y qemu-utils acl psmisc && homerdo install
install_dispatcher
warmup_binaries
warmup_dispatcher_images

mkdir -p /var/local/runjob
chmod 1777 /var/local/runjob

touch /var/local/bknix-ready
