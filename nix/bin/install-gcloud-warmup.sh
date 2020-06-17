#!/bin/bash


###########################################################
## Install helpers

function template_render() {
  cat "$1" \
    | sed "s;%%RAMDISK%%;$RAMDISK;g" \
    | sed "s;%%RAMDISKSVC%%;$RAMDISKSVC;g" \
    | sed "s;%%RAMDISKSIZE%%;$RAMDISKSIZE;g" \
    | sed "s/%%OWNER%%/$OWNER/g" \
    | sed "s/%%PROFILE%%/$PROFILE/g"
}


## The warmup service updates the system everytime in boots.
function install_warmup_service() {
  OWNER=jenkins
  RAMDISK="/mnt/mysql/$OWNER"
  RAMDISKSVC=$(systemd-escape "mnt/mysql/$OWNER")
  SYSTEMSVC=bknix-warmup

  echo "Creating systemd service \"$SYSTEMSVC\""
  template_render examples/systemd-warmup.service > "/etc/systemd/system/${SYSTEMSVC}.service"

  echo "Activating systemd services \"$SYSTEMSVC\""
  systemctl daemon-reload
  # systemctl start "$SYSTEMSVC"
  systemctl enable "$SYSTEMSVC"
}

###########################################################
## Main

if [ -z `which nix` ]; then
  echo "Please install \"nix\" before running this. See: https://nixos.org/nix/manual/"
  exit 2
fi

install_warmup_service
