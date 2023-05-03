#!/bin/bash

## `install-demo.sh` prepares the system to host demo sites (where each demo may live
## for a couple days).
##
## Pre-requisites:
##
##  - Execute `install-runner.sh`
##
## What this script does:
##
##  - Add systemd unit for demo services (`demo.service` <=> `src/jobs/homerdo-demo.sh`). Internally, this will:
##     - Create a semi-isolated container (via homerdo) for running all demos.
##     - Warmup persistent caches
##     - Setup tmpfs/overlay
##     - Start Apache+PHP+MySQL for each profile (`use-bknix max -cr loco start`, etc)
##     - Start an extra SSHD (for entering the container)
##  - Redirect HTTP (80/tcp) to the a demo service (eg 8003/tcp).
##  - Add rules for ufw/iptables
##
## Key actions for managing the demos:
##
##  - Manage `demo.service` unit
##      - `systemctl start demo`
##      - `systemctl stop demo`
##      - `journalctl -u demo`
##  - Log into `demo` using `homerdo` or `ssh`
##      - `sudo -iu dispatcher -- homerdo enter -i images/demo.img`
##      - `ssh homer@hostname -p9022` (if authorized by /etc/bknix-ci/dispatcher-keys)
##  - Within the demo environment, access one of the profiles (min/dfl/max/edge)
##      - `use-bknix min -cs`
##      - `use-bknix max -cs`
##  - Manage services within min/max/etc
##      - `loco status`
##      - `loco info`
##      - `loco stop`
##      - `loco start`
##      - `loco clean`

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"

###########################################################

assert_root_user

if [ ! -e /home/dispatcher ]; then
  echo >&2 "Please install the runner configuration first (install-runner.sh)"
  exit 1
fi

if [ ! -e /etc/ufw ]; then
  echo >&2 "Only supported on hosts with ufw"
  exit 1
fi

echo "Configure firewall and port-forwards"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 8888/tcp
ufw allow 9022/tcp
ufw default allow FORWARD

install_bin "$BINDIR"/portfw /usr/local/sbin/portfw
/usr/local/sbin/portfw install
portfw set tcp 80 8888

if [[ ! -f /etc/site-list.settings.d/post.d/demo.php ]] ; then
  mkdir -p /etc/site-list.settings.d/post.d
  cp "$BKNIXSRC/examples/demo-site-list.php.ex" /etc/site-list.settings.d/post.d/demo.php
fi

echo "Setup systemd (demo.service)"
cp "$BKNIXSRC/examples/systemd-demo.service" "/etc/systemd/system/demo.service"
systemctl daemon-reload
systemctl enable demo

echo
echo "TIP: For new or migrated installations, you may wish to tune the names and credentials in these files:"
echo "- /etc/bknix-ci/loco-overrides.yaml"
echo "- /etc/site-list.settings.d/post.d/demo.php"
echo "- /etc/bknix-ci/dispatcher-keys"
echo
echo "TIP: To start the demo services, run:"
echo "$ systemctl start demo"
echo
