#!/usr/bin/env bash

if [[ ! -f `pwd`/ena_drv.ko ]]; then
	DRIVER_PATH='~/ena-drivers/linux'
else
	DRIVER_PATH=`pwd`
fi

sudo rmmod ena_drv 2> /dev/null
sudo insmod ${DRIVER_PATH}/ena_drv.ko
