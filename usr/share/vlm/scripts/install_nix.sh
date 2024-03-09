#!/usr/bin/env bash

set -ueo pipefail

if [[ -f "/etc/vlm/nix_installed" ]];
then
    sudo echo ""
    sudo echo ">>>>>>>> Nix already installed (File /etc/vlm/nix_installed exists)"
    sudo echo ""
    exit 1
fi

sudo echo ""
sudo echo ">>>>>>>> Installing Nix"
sudo echo ""
    
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sudo bash -s -- install --no-confirm
sudo rm -f /etc/systemd/system/nix-daemon.service
sudo rm -f /etc/systemd/system/nix-daemon.socket
sudo cp /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.service /etc/systemd/system/nix-daemon.service
systemctl enable --now nix-daemon

sudo echo ""
sudo echo ">>>>>>>> Adding Nix bin path to sudoers configuration"
sudo echo ""

sudo rm -f /etc/sudoers.d/nix-sudo-env
SUDOPATHVARIABLE5=$(sudo printenv PATH)
sudo tee /etc/sudoers.d/nix-sudo-env <<EOF
Defaults  secure_path = /nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:$SUDOPATHVARIABLE5
EOF

sudo mkdir -p /etc/vlm/
sudo touch /etc/vlm/nix_installed

sudo echo ""
sudo echo ">>>>>>>> Finished installing Nix"
sudo echo ""
