#!/usr/bin/env bash

echo >&2 "This is an example of an uninstall script. It is not maintained/tested."
echo >&2 "For proper instructions, see https://nix.dev/manual/nix/latest/installation/uninstall.html"
echo >&2 "Please review+edit before using."
exit 1

sudo systemctl stop nix-daemon.service
sudo systemctl disable nix-daemon.socket nix-daemon.service
sudo systemctl daemon-reload

sudo rm -rf /etc/nix /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf /nix ~root/.nix-channels ~root/.nix-defexpr ~root/.nix-profile ~root/.cache/nix
sudo rm -f /etc/*backup-before-nix
rm -rf ~/.nix-channels ~/.nix-defexpr ~/.nix-profile ~/.cache/nix ~/.config/nix

for i in $(seq 1 32); do
  sudo userdel nixbld$i
done
sudo groupdel nixbld

pushd /etc
  sudo editor bash.bashrc bashrc zshrc profile /home/*/.profile
popd