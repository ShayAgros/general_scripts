#!/usr/bin/env bash

instance_num=${1:-1}
login_file=~/saved_logins

if [[ ! -f ${login_file} ]]; then
	echo No login file ${login_file}
	exit 1
fi
if [[ $instance_num -gt $(cat ${login_file} | wc -l) ]]; then
	echo Invalid instance num
	exit 1
fi

server=$(sed -ne ${instance_num}p ${login_file} | cut -d' ' -f1)
key=$(sed -ne ${instance_num}p ${login_file} | cut -d' ' -f2)

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 3
fi

echo connecting to ${server}
ssh -X -i ${key} ${server}
