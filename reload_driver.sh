#!/usr/bin/env bash

module_params=${@}

if [[ ! -f `pwd`/ena_drv.ko ]]; then
	DRIVER_PATH=${HOME}/ena-drivers/linux
else
	DRIVER_PATH=`pwd`
fi

DRIVER=${DRIVER_PATH}/ena_drv.ko

if [[ ! -f ${DRIVER} ]]; then
	echo "Driver doesn't exist in ${DRIVER}" 
	exit 2
fi

echo reloading ${DRIVER}
[[ ! -z ${module_params} ]] && echo using following module params: ${module_params}

sudo rmmod ena_drv 2> /dev/null
sudo insmod ${DRIVER} ${module_params}
