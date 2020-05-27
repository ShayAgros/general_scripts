#!/usr/bin/env sh

# This line changes automatically when choosing default interface
dev=${1:-""}

max_mtu="3818"

function choose_default() {

	interfaces=$(ip -br a s | cut -d' ' -f1 | grep eth | grep -n '^')
	interfaces_nr=$(echo "${interfaces}" | wc -l)

	echo "Choose interface interface which would be used"
	echo "as the default interface in future invocations"

	while [[ -z ${dev} ]]; do
		echo ""
		echo -e "${interfaces}\n"
		read -p "Enter choice [ 1 - ${interfaces_nr} ]: " choice
		dev=$(echo "${interfaces}" | sed -n "${choice}s/[0-9]\+://p")
	done
}

if [[ -z ${dev} ]]; then
	echo -e "No interface was chosen. Configuring default\n"

	choose_default

	# changing the dafault
	sed -ine "4s/{1:-\"\"}/{1:-\"${dev}\"}/" $0
fi

echo "Making ${dev} XDP compatible"

num_channels=$(ethtool -l ${dev} | grep -A4 'maximums' |\
				sed -n 's/Combined:\s*\([0-9]\+\)/\1/p') 

echo "Setting number of channels to $((num_channels / 2))"

sudo ethtool -L ${dev} combined $((num_channels / 2)) >/dev/null 2>&1

echo "Setting MTU to ${max_mtu}"

sudo ip link set dev ${dev} mtu ${max_mtu} >/dev/null 2>&1
