#!/usr/bin/env bash

function usage {
	echo "$1 [ssh connect command]"
	exit 1
}

INSTANCES_DIR=${HOME}/saved_instances
login_file=${INSTANCES_DIR}/saved_logins

con_command=${@}


key=$(echo ${con_command} | egrep -o -- '-i [^ ]+' | awk -F' ' '{print $2}')
# append full key path if key exists
[[ -z $key ]] || key=${HOME}/keys/${key}
server=$(echo ${con_command} | egrep -o '[^ ]+@[^ ]+($|\s)')
port=$(echo ${con_command} | egrep -o -- '-p [0-9]+' | awk -F' ' '{print $2}')

if [[ -z ${server} ]]; then
    echo "Couldn't extract server"
    exit 2
fi

[[ ! -z ${port} ]] && server="-p ${port} ${server}"

echo key= "${key:-"no key provided"}"
echo server= ${server}

mkdir -p ${INSTANCES_DIR} >/dev/null 2>&1
touch ${login_file} # make sure the login file exists

# don't add entry if it already exists
grep -q ${server} ${login_file} >/dev/null 2>&1 && exit 0

echo "${server} ${key}" >> ${login_file}
