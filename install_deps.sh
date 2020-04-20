#!/usr/bin/env bash

deps='iperf3'
deps+=' git'
deps+=' make'
deps+=' gcc'

echo ${deps}

if $(which yum >/dev/null 2>&1); then
	sudo yum install kernel-devel-`uname -r` ${deps} -y
elif $(which zypper >/dev/null 2>&1); then
	exit 0 # Currently we don't support SUSE
	# SUSE provides perf3 as perf
	deps=$(echo $deps | sed -e 's/iperf3/iperf/')

	sudo zypper --non-interactive --no-gpg-checks update
	sudo zypper --non-interactive install kernel-source=$(uname -r| sed -e 's/-default//')
	sudo zypper --non-interactive install ${deps}
elif $(which apt-get >/dev/null 2>&1); then
	sudo apt-get update
	sudo apt-get install linux-headers-`uname -r` ${deps} -y
fi
