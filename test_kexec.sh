#!/usr/bin/env bash


#set -x
for i in `seq 1 10`; do
	
	echo "iteration number ${i}"
	echo waiting for the connection to be stalbe
	bootloader=$(while ! ssh -i ${HOME}/keys/dublin.pem ubuntu@ec2-34-255-209-62.eu-west-1.compute.amazonaws.com -o ConnectTimeout=3000 "cat /proc/sys/kernel/bootloader_type" 2>/dev/null; do
		sleep 0.1
	done)
	echo "bootloader is: ${bootloader}. Retriggering"

	#while ! ssh -i ${HOME}/keys/dublin.pem admin@ec2-34-247-253-131.eu-west-1.compute.amazonaws.com -o ConnectTimeout=3000 "/home/admin/test_exec.sh" >/dev/null 2>&1; do
		#sleep 0.1
	#done
	ssh -i ${HOME}/keys/dublin.pem ubuntu@ec2-34-255-209-62.eu-west-1.compute.amazonaws.com -o ConnectTimeout=3000 "/home/admin/test_exec.sh" >/dev/null 2>&1
done
