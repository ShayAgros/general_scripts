#!/usr/bin/env bash

ena_pci_adderss=$(lspci | awk '/Elastic Network Adapter/ {print $1}')

# find the interface on which we're connected to ssh
connected_address=$(sudo netstat -np --protocol=inet | awk '/sshd/ {sub(":[0-9]+", "") ; print $4}' | head -n1)
connected_interface=$(ip -br a s | awk "/${connected_address}/ {print \$1}")

# unbind all interfaces except the one we're connected to ssh with
echo "${ena_pci_adderss}" | while read address; do
	ena_interface=$(ls -l /sys/class/net | grep ${address} | awk -F'/' '{print $NF}')

	# in case the interface is already unbinded, continue to the next one
	[[ -z ${ena_interface} ]] && continue

	if [[ ${ena_interface} != ${connected_interface} ]]; then
		~/scripts/unbind_device.sh ${ena_interface}
	fi
done
