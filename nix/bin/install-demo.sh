#!/bin/bash

## `install-demo.sh` prepares the system to host demo sites (where each demo may live
## for a couple days).
##
## Pre-requisites:
##
##  - Execute `install-runner.sh`
##
## What the script does:
##
##  - Add systemd unit for demo services (`demo.service` <=> `homerdo-demo.sh`). Internally, this will:
##     - Create a semi-isolated container (via homerdo) for running all demos.
##     - Warmup persistent caches
##     - Setup tmpfs/overlay
##     - Start Apache+PHP+MySQL for each profile (`use-bknix max -r loco start`, etc)
##     - Start an extra SSHD (for entering the container)
##  - Redirect HTTP (80/tcp) to the a demo service (eg 8003/tcp).
##  - Enable access to the demo TCP ports
##
## Key actions for managing the demos:
##
##  - Manage systemd unit
##      - `systemctl start demo`
##      - `systemctl stop demo`
##      - `journalctl -u demo`
##  - Login to the running environment:
##      - `sudo -iu dispatcher -- homerdo enter -i images/demo.img
##      - `ssh homer@localhost -p9022` (if authorized by /etc/bknix-ci/dispatcher-keys)
##  - Within the demo environment, access the min/dfl/max/edge profiles.
##      - `cd ~/bknix-min && use-bknix min`
##      - `cd ~/bknix-max && use-bknix max`
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
  echo >&2 "Only support on hosts with ufw"
  exit 1
fi

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 8001/tcp
ufw allow 8002/tcp
ufw allow 8003/tcp
ufw allow 8007/tcp
ufw allow 9022/tcp
ufw default allow FORWARD

#enable_line /etc/ufw/sysctl.conf "net/ipv4/ip_forward=1"
install_bin "$BINDIR"/portfw /usr/local/sbin/portfw
/usr/local/sbin/portfw install
portfw set tcp 80 8003

echo "Setup systemd (demo.service)"
cp "$BKNIXSRC/examples/systemd-demo.service" "/etc/systemd/system/demo.service"
systemctl daemon-reload
systemctl enable demo
systemctl start demo

## Add a line to a file (unless already present)
## usage: enable_line /etc/ufw/sysctl.conf
#function enable_line() {
#  local file="$1"
#  local line="$2"
#  if ! grep -qFx -- "$line" "$file"; then
#    echo "$line" >> "$file"
#  fi
#}
