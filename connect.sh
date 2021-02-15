#!/usr/bin/env bash

instance=${1:-1}
INSTANCES_DIR=${HOME}/saved_instances
login_file=${INSTANCES_DIR}/saved_logins

server=""
key=""

# Search for saved logins first
if [[ ${instance} == "dev" ]]; then
	server="dev-desk-al-sw-1c-6ffd7520.eu-west-1.amazon.com"
	
	# transform server into ip address
	server=$(nslookup "${server}" | awk '/Name:/ {getline; print $2}')

elif [[ ${instance} == "esxi" ]]; then
	# the server on which esxi files exist
	server="centos@3.86.44.112"
else # Otherwise, search for saved logins entry
	if [[ ! -f ${login_file} ]]; then
		echo No login file ${login_file}
		exit 1
	fi
	if [[ $instance -gt $(cat ${login_file} | wc -l) ]]; then
		echo Invalid instance num
		exit 1
	fi

	server=$(sed -ne ${instance}p ${login_file} | cut -d' ' -f1)
	key=$(sed -ne ${instance}p ${login_file} | cut -d' ' -f2)

	if [[ -z ${server} ]]; then
		echo "Couldn't extract server from arguments"
		exit 3
	fi
fi

[[ -z ${server} ]] && { echo "Failed to find server name" ; exit 1 ; }

echo connecting to ${server}
if [[ ! -z ${key} ]]; then
	echo ssh -AX -i ${key} ${server}
	ssh -AX -i ${key} ${server}
else
	echo ssh -AY ${server}
	ssh -A ${server}
fi
