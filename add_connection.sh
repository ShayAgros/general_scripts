#!/usr/bin/env bash

function usage {
	echo "$1 [ssh connect command]"
	exit 1
}

login_file=~/saved_logins

#if [[ -f ${login_file} ]]; then
	## We update the login file first
	#~/update_saved_logins.sh
#fi


con_command=${@}


key=/home/shay/$(echo ${con_command} | sed -ne 's/.*-i \([a-zA-Z]\+\.pem\) .*$/\1/p')
server=$(echo ${con_command} | sed -ne 's/.*-i [a-zA-Z]\+\.pem \(.*\)$/\1/p')

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 2
fi

echo key="${key}"
echo server=${server}

touch ${login_file} # make sure the login file exists

# done add new entry if already exists
grep -q ${server} ${login_file} >/dev/null 2>&1 && exit 0

echo "${server} ${key}" >> ~/saved_logins
