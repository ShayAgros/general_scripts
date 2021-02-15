#!/usr/bin/env bash

interfaces=${@}

if [[ -z ${interfaces} ]]; then
	interfaces=$(ip -br a s | awk '/eth.*/ {print $1}' | xargs echo)
fi

for interface in ${interfaces}; do

	# check if exists
	if ! ip a s ${interface} >/dev/null 2>&1; then
		echo "interface ${interface} doesn't exist!"
		continue
	fi

	num_queues=`ethtool -l ${interface} | grep -A4 Current | \
				awk '
					BEGIN { num_queues = 0 }
					/RX|TX|Combined/ { if ( $2 > num_queues ) num_queues = $2 }
					END { print num_queues }'`

	echo --------------------------------------------------
	echo ${interface}, ${num_queues} queues:
	for queue in `seq 0 $(( num_queues - 1 ))`; do
		interrupt_line=$(cat /proc/interrupts | grep "\<${interface}-Tx-Rx-${queue}\>" | cut -d: -f1 | xargs echo)
		interrupt_affinity=$(cat /proc/irq/${interrupt_line}/smp_affinity | xargs echo)

		echo q${queue}: ${interrupt_line}: ${interrupt_affinity}
	done

done
