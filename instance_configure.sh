#!/usr/bin/env bash


function usage {
	echo "$1 [ssh connect command]"
	exit 1
}

export DEBUG=0
SCRIPTS_DIR=${HOME}/workspace/scripts

[[ -z $1 ]] && usage $0

# We update the login file first
# echo Updating login list
# ./update_saved_logins.sh

con_command=${@}

key=${HOME}/keys/$(echo ${con_command} | sed -ne 's/.*-i \([a-zA-Z-]\+\.pem\) .*$/\1/p')
server=$(echo ${con_command} | sed -ne 's/.*-i [a-zA-Z-]\+\.pem \(.*\)$/\1/p')
remote_user=$(echo ${server} | cut -d@ -f1)

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 2
fi

echo key="${key}"
echo server=${server}
echo remote_user=${remote_user}

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
echo "yes" | scp -i ${key} ./setup_script.sh ${server}:/home/${remote_user} >/dev/null
scp -i ${key} /tmp/code.tar.bz2 ${server}:/home/${remote_user} >/dev/null
scp -i ${key} ${HOME}/.gitconfig ${server}:/home/${remote_user} >/dev/null

# Creating scripts dir and sending big scripts
ssh -i ${key} ${server} DEBUG=${DEBUG} mkdir /home/${remote_user}/scripts
scp -i ${key} ${SCRIPTS_DIR}/update_grub.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/change_drv_name.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/configure_xdp.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/install_xdp_deps.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/build_llvm.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/unbind_device.sh ${server}:/home/${remote_user}/scripts >/dev/null


echo Setup instance
ssh -i ${key} ${server} DEBUG=${DEBUG} /home/${remote_user}/setup_script.sh

# echo Adding instance to login list
# echo "${server} ${key}" >> ~/saved_logins
