#!/bin/bash

if_pci="0000:00:06.0"
if=$1

# do we want to unbind specific interface?
if [[ ! -z ${if} ]]; then
	ifs_dir="/sys/class/net"
	if ! ls -1 ${ifs_dir} | grep -q ${if} >/dev/null 2>&1 ; then
		echo "interface ${if} doesn't exist"
		exit 1
	fi

	if_pci=$(readlink ${ifs_dir}/${if} | sed -ne "s@.*/\([0-9\.:a-z]\+\)/net/${if}@\1@p")

	echo "interface ${if} is in pci ${if_pci}"
fi

# find what driver bind the device
driver_name=$(lspci -ks ${if_pci} | awk '/Kernel driver in use:/ {print $NF}')

if [[ -z ${driver_name} ]]; then
	echo "interface ${if} is not bounded to a device"
	exit 2
fi

echo "driver in use: ${driver_name}"

echo "unbinding"
echo "${if_pci}" | sudo tee /sys/bus/pci/drivers/${driver_name}/unbind
