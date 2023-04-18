#!/bin/bash

###########################################################
## Bootstrap

set -e
BINDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BKNIXSRC=$(dirname "$BINDIR")
cd "$BKNIXSRC"
source "$BINDIR/../lib/common.sh"


###########################################################

if [ ! -e /home/dispatcher ]; then
  echo >&2 "Please install the runner configuration first (install-runner.sh)"
  exit 1
fi

if [ ! -e /etc/ufw ]; then
  echo >&2 "Only support on hosts with ufw"
  exit 1
fi

#enable_line /etc/ufw/sysctl.conf "net/ipv4/ip_forward=1"
install_bin "$BINDIR"/portfw /usr/local/sbin/portfw
/usr/local/sbin/portfw install

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 8001/tcp
ufw allow 8002/tcp
ufw allow 8003/tcp
ufw allow 8007/tcp
ufw default allow FORWARD
portfw set tcp 80 8003


## Add a line to a file (unless already present)
## usage: enable_line /etc/ufw/sysctl.conf
#function enable_line() {
#  local file="$1"
#  local line="$2"
#  if ! grep -qFx -- "$line" "$file"; then
#    echo "$line" >> "$file"
#  fi
#}
