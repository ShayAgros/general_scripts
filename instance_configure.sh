#!/usr/bin/env bash


function usage {
	echo "$1 [ssh connect command]"
	exit 1
}

export DEBUG=0

[[ -z $1 ]] && usage $0

# We update the login file first
# echo Updating login list
# ./update_saved_logins.sh

con_command=${@}

key=/home/shay/$(echo ${con_command} | sed -ne 's/.*-i \([a-zA-Z-]\+\.pem\) .*$/\1/p')
server=$(echo ${con_command} | sed -ne 's/.*-i [a-zA-Z-]\+\.pem \(.*\)$/\1/p')
user=$(echo ${server} | sed -ne 's/\(.*\)@.*/\1/p')

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 2
fi

echo key="${key}"
echo server=${server}
echo user=${user}

# Download a "fresh" version of ena-drivers
cd /tmp
rm -rf ena-drivers code.tar.bz2
if [[ ${DEBUG} -eq 1 ]]; then
	git clone --recurse-submodules https://gerrit.anpa.corp.amazon.com:9080/ena-drivers || exit 1
else
	git clone -q --recurse-submodules https://gerrit.anpa.corp.amazon.com:9080/ena-drivers || exit 1
fi
tar czf code.tar.bz2 ena-drivers
cd

echo Sending files to device
echo "yes" | scp -i ${key} ./setup_script.sh ${server}:/home/${user} >/dev/null
scp -i ${key} /tmp/code.tar.bz2 ${server}:/home/${user} >/dev/null
scp -i ${key} /home/shay/.gitconfig ${server}:/home/${user} >/dev/null

# Creating scripts dir and sending big scripts
ssh -i ${key} ${server} DEBUG=${DEBUG} mkdir /home/${user}/scripts
scp -i ${key} /home/shay/scripts/update_grub.sh ${server}:/home/${user}/scripts >/dev/null
scp -i ${key} /home/shay/scripts/change_drv_name.sh ${server}:/home/${user}/scripts >/dev/null


echo Setup instance
ssh -i ${key} ${server} DEBUG=${DEBUG} /home/${user}/setup_script.sh

# echo Adding instance to login list
# echo "${server} ${key}" >> ~/saved_logins
