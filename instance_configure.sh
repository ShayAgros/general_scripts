#!/usr/bin/env bash


function usage {
	echo "$1 [ssh connect comand]"
	exit 1
}

SCRIPTS_DIR=${HOME}/workspace/scripts
INSTANCES_DIR=${HOME}/saved_instances
login_file=${INSTANCES_DIR}/saved_logins

[[ -z $1 ]] && usage $0

# We update the login file first
# echo Updating login list
# ./update_saved_logins.sh

# is it an ssh command
if [[ $1 == 'ssh'* ]]; then
	echo configuring ssh command
	con_command=${@}

	key=${HOME}/keys/$(echo ${con_command} | sed -ne 's/.*-i \([a-zA-Z-]\+\.pem\) .*$/\1/p')
	server=$(echo ${con_command} | sed -ne 's/.*-i [a-zA-Z-]\+\.pem \(.*\)$/\1/p')

	if [[ -z ${key} ]] || [[ -z ${server} ]]; then
		echo "Couldn't extract server and key from arguments"
		exit 2
	fi

elif [[ $1 =~ ^[0-9]+$ ]]; then

	echo configuring entry from saved logins

	instance=$1

	if [[ ! -f ${login_file} ]]; then
		echo No login file ${login_file}
		exit 1
	fi

	if [[ $instance -gt $(wc -l ${login_file} | awk '{print $1}') ]]; then
		echo Invalid instance num
		exit 1
	fi

	server=$(sed -ne ${instance}p ${login_file} | cut -d' ' -f1)
	key=$(sed -ne ${instance}p ${login_file} | cut -d' ' -f2)
else
	echo invalid input
	exit 1
fi

remote_user=$(echo ${server} | cut -d@ -f1)

# Create a directory for this server and make sure it's empty
instance_dir=${INSTANCES_DIR}/${server}
rm -rf ${instance_dir}
mkdir -p ${instance_dir}

echo
echo key="${key}"
echo server=${server}
echo remote_user=${remote_user}

# Download a "fresh" version of ena-drivers
if [[ ${DEBUG} -eq 1 ]]; then
	git clone --recurse-submodules https://gerrit.anpa.corp.amazon.com:9080/ena-drivers ${instance_dir}/ena-drivers || exit 1
else
	git clone -q --recurse-submodules https://gerrit.anpa.corp.amazon.com:9080/ena-drivers ${instance_dir}/ena-drivers|| exit 1
fi

tar czf ${instance_dir}/code.tar.bz2 -C ${instance_dir} ena-drivers

echo Sending files to device
echo "yes" | scp -i ${key} ${SCRIPTS_DIR}/setup_script.sh ${server}:/home/${remote_user} >/dev/null
scp -i ${key} ${instance_dir}/code.tar.bz2 ${server}:/home/${remote_user} >/dev/null
scp -i ${key} ${HOME}/.gitconfig ${server}:/home/${remote_user} >/dev/null

# Creating scripts dir and sending big scripts
ssh -i ${key} ${server} DEBUG=${DEBUG} mkdir /home/${remote_user}/scripts
scp -i ${key} ${SCRIPTS_DIR}/update_grub.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/change_drv_name.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/configure_xdp.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/install_xdp_deps.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/build_llvm.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/unbind_device.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/diff_stats.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/set_affinity.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/unbind_all_devices.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/reload_driver.sh ${server}:/home/${remote_user}/scripts >/dev/null
scp -i ${key} ${SCRIPTS_DIR}/add_amazon_config.sh ${server}:/home/${remote_user}/scripts >/dev/null

echo Setup instance
ssh -i ${key} ${server} DEBUG=${DEBUG} /home/${remote_user}/setup_script.sh

# 99% of the time I'd rather have dmesg empty (so that I could see loads of new
# driver)
ssh -i ${key} ${server} DEBUG=${DEBUG} sudo dmesg -C

# echo Adding instance to login list
# echo "${server} ${key}" >> ~/saved_logins
