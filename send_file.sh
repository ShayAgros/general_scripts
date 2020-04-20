#!/usr/bin/env bash

function usage {
	echo "$1 [login num] <file to send> [alias for this file]"
	exit 1
}

[[ -z $1 ]] && usage $0
instance_num=$1

[[ -z $2 ]] && instance_num=1

file_to_send=${2:-$1}
login_file=~/saved_logins

if [[ ! -f ${login_file} ]]; then
	echo No saved logins file
	exit 2
fi

if [[ ${instance_num} -gt $(cat ${login_file} | wc -l) ]]; then
	echo Instance num ${instance_num} doesn\'t exit
	exit 2
fi

if [[ ! -f "${file_to_send}" ]]; then
	echo file doesn\'t exist
	exit 2
fi

server=$(sed -ne "${instance_num}p" ${login_file} | cut -d' ' -f1)
key=$(sed -ne "${instance_num}p" ${login_file} | cut -d' ' -f2)

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 3
fi

echo "server=\"${server}\" key=\"${key}\" "
#echo scp command: \' scp -i ${key} ${1} ${server}:~/ \'

scp -i ${key} ${file_to_send} ${server}:~/

# create an alias for this file
if [[ ! -z ${3} ]]; then
	echo "creating alias for this file:"
	ssh -i ${key} ${server} "echo alias ${3}=/home/ec2-user/$(basename ${file_to_send}) >> /home/ec2-user/.zshrc"
fi
