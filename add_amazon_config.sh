#!/usr/bin/env bash

if [[ ! -f .config ]]; then
	echo "No config file's found, copying one from boot"
	cp /boot/config-`uname -r` ./.config || exit 1
fi

./scripts/config -e CONFIG_NET_VENDOR_AMAZON
./scripts/config -m CONFIG_ENA_ETHERNET

make olddefconfig
