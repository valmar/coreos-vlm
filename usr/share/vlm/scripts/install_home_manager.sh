#!/usr/bin/env bash

set -ueo pipefail

if [[ -f "${HOME}/.config/vlm/home_manager_installed" ]];
then
    echo ""
    echo ">>>>>>>> Home Manager already installed (File ~/.config/vlm/home_manager_installed exists)"
    echo ""
    exit 1
fi

if [[ ! -d "/nix" ]];
then
    echo ""
    echo ">>>>>>>> Home Manager requires Nix"
    echo ""
    exit 1
fi

echo ""
echo ">>>>>>>>  Installing Home Manager"
echo ""

source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run home-manager/master -- init --switch

mkdir -p ~/.config/vlm/
touch ${HOME}/.config/vlm/home_manager_installed

echo ""
echo ">>>>>>>> Finished installing Home Manager"
echo ""
