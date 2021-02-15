#!/usr/bin/env bash

INSTANCES_DIR=${HOME}/saved_instances
login_file=${INSTANCES_DIR}/saved_logins

if [[ ! -f ${login_file} ]]; then
	echo No saved logins file
	exit 2
fi

final_server_list=""
while read line; do
	server=$(echo $line | cut -d' ' -f1 | sed 's/[-a-zA-Z0-9]*@//')

	if ping -c 1 -W 1 ${server} >/dev/null 2>&1; then
		#echo "Server ${server} is responsive"
		final_server_list=${final_server_list}"\n"${line}
	fi
done < ${login_file}

echo -e "${final_server_list}" | sed -s '/^$/d' > ${login_file}
