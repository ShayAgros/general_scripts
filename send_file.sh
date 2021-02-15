#!/usr/bin/env bash

sent_history_file=~/workspace/last_sent_files

# TODO: make this script accept arguments
function usage() {
	echo "$1 <login num> [files to send] [alias for this file]"
	exit 1
}

function get_all_previous_records() {
	if [[ ! -f ${sent_history_file} ]]; then
		echo ""
		return
	fi

	cat ${sent_history_file} | sed '/^$/d'
}

# this function receives list of arguments and transforms
# into new-line separated list
function argument_to_list() {
	for arg in "${@}"; do
		echo "${arg}"
	done
}

function remove_non_existent() {
	files_to_send="$1"

	while read line ; do

		if [[ -z ${line} ]]; then
			echo ""
		elif [[ -f ${line} ]] || [[ -d ${line} ]]; then
			echo ${line}
		fi
	done <<< "${files_to_send}"
}

function add_entries_to_file() {
	files_to_send="$1"

	# make sure the file exists
	if [[ ! -f ${sent_history_file} ]]; then
		touch ${sent_history_file}
	fi

	# only store full path files in the file
	files_to_send=$(echo "${files_to_send}" | xargs -I {} readlink -f {})

	# remove all existing entries of these files
	while read line ; do
		sed -i "s?${line}??" ${sent_history_file}
	done <<< "${files_to_send}"

	previous_entries=$(cat ${sent_history_file})
	previous_entries=$(remove_non_existent "${previous_entries}")

	# uniq is to remove double new-lines
	echo -e "${files_to_send}\n\n${previous_entries}" | uniq > ${sent_history_file}
}

(( $# < 1 )) && usage $0
instance_num=$1


files_to_send="$(argument_to_list ${@:2})"
INSTANCES_DIR=${HOME}/saved_instances
login_file=${INSTANCES_DIR}/saved_logins


if [[ ! -f ${login_file} ]]; then
	echo No saved logins file
	exit 2
fi

if [[ ! ${instance_num} =~ ^[0-9]+$ ]]; then
	echo First argument is not a number. Choosing entry 1
	instance_num=1
	files_to_send="$(argument_to_list ${@:1})"
fi

if [[ ${instance_num} -gt $(cat ${login_file} | wc -l) ]]; then
	echo Instance num ${instance_num} doesn\'t exit
	exit 2
fi

server=$(sed -ne "${instance_num}p" ${login_file} | cut -d' ' -f1)
key=$(sed -ne "${instance_num}p" ${login_file} | cut -d' ' -f2)

if [[ -z ${key} ]] || [[ -z ${server} ]]; then
    echo "Couldn't extract server and key from arguments"
    exit 3
fi

# disable this part for now. this doesn't work
if [[ -z ${files_to_send} ]]; then
#if [[ -z ${files_to_send} ]]; then
	which rofi >/dev/null 2>&1 || { echo "Please install rofi to select from previously sent files" ; return ; }

	previous_records=$(get_all_previous_records)

	if [[ -z ${previous_records} ]]; then
		echo "No previous files recorded, please specify a file[s] to send"
		exit 3
	fi
	
	# output string would have the format -e 1p -e 4p -e 6p indicating the lines in previous_records
	# to print.
	files_entries_to_send=$(echo -e "${previous_records}" | xargs -I {} basename {} |\
							rofi -dmenu -multi-select -i -p "Choose files to send" -format 'd' | \
							xargs | sed -E 's/([0-9]+)/-e \1p /g')	

	if [[ -z ${files_entries_to_send} ]]; then
		echo "No files selected, exiting"
		exit 3
	fi

	# choose the entries chosen in previous part. Note the brace expansion
	files_to_send=$(echo -e "${previous_records}" | eval sed -n ${files_entries_to_send})
fi

files_to_send=$(remove_non_existent "${files_to_send}")
if [[ -z ${files_to_send} ]]; then
	echo "Non of the requested files exists anymore"
	exit 3
fi

echo files to send ${files_to_send}
echo "server=\"${server}\" key=\"${key}\" "

rsync --progress -azvhe "ssh -i ${key}" ${files_to_send} ${server}:~/

# add this entry to file
add_entries_to_file "${files_to_send}"

# create an alias for this file
#if [[ ! -z ${3} ]]; then
	#echo "creating alias for this file:"
	#ssh -i ${key} ${server} "echo alias ${3}=/home/ec2-user/$(basename ${files_to_send}) >> /home/ec2-user/.zshrc"
#fi
