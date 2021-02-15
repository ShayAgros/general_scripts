#!/usr/bin/env bash

function usage() {
	echo -e "$0 <interface name>"
}

if [[ ! ${#} -eq 1 ]]; then
	usage
	return 1
fi

if_name=${1}

ip a s ${if_name} >/dev/null 2>&1 || { echo "${if_name} isn't an interface that is up" ; return 2 ; }

ip_addr=$(ip a s ${if_name} | awk '/inet / { sub("/[0-9]+", "", $2) ; print $2 }')
mac_addr=$(ip a s ${if_name} | awk '/ether/ {print $2}')

export ip_addr=${ip_addr}
export mac_addr=${mac_addr}

echo exported
echo ip address  = ${ip_addr}
echo mac address = ${mac_addr}
