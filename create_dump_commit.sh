#!/usr/bin/env bash

script_name=$(basename $0)

function usage() {
	echo -e ""
	echo -e "${script_name} <net-next directory> <ena_linux_upstream_directory>"
}

if [[ $# -ne 2 ]]; then
	usage
	exit 1
fi

net_dir=$1
upstream_dir=$2

if [[ ! -d ${net_dir} ]]; then
	echo First argument is not a directory
	usage
	exit 2
fi

if [[ ! -d ${upstream_dir} ]]; then
	echo Second argument is not a directory
	usage
	exit 2
fi

code_path="drivers/net/ethernet/amazon"
documentation_path="Documentation/networking/device_drivers/ethernet/amazon"

mkdir -p ${upstream_dir}/${code_path}
mkdir -p ${upstream_dir}/${documentation_path}

cp -R ${net_dir}/${code_path}/* ${upstream_dir}/${code_path}/
cp ${net_dir}/${documentation_path}/* ${upstream_dir}/${documentation_path}/
