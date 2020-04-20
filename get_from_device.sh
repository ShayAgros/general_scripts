#!/usr/bin/env bash

function usage {
	echo "$1 [login num] <path of file to get>"
	exit 1
}

[[ -z $1 ]] && usage $0

instance_num=$1
[[ -z $2 ]] && instance_num=1

file_to_get=${2:-$1}
# If no path provided, assume that file in $HOME
echo ${file_to_get} | grep '/' >/dev/null 2>&1 || file_to_get='~/'${file_to_get}

login_file=~/saved_logins

if [[ ! -f ${login_file} ]]; then
	echo No saved logins file
	exit 2
fi

server=$(sed -ne "${instance_num}p" ${login_file} | cut -d' ' -f1)
key=$(sed -ne "${instance_num}p" ${login_file} | cut -d' ' -f2)

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 3
fi

echo "server=\"${server}\" key=\"${key}\" "
echo "file=\"${file_to_get}\""

scp -i ${key} ${server}:${file_to_get} ./
