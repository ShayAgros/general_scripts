#!/bin/bash

function usage {
	echo "$0 <interface name>"
	exit 1
}

function find_first_bit {
	return $1
}

[[ -z $1 ]] && usage $0

if [[ $UID > 0 ]]; then
	echo "Must be run as root"
	exit 1
fi

interface=$1
num_queues=$(ethtool -l ${interface} | grep -A4 Current | sed -ne 's/RX:\s\+\([1-9]\+\)/\1/p')

# We might be using a newer driver version which uses 'combined' field
# in ethtool -l instead of specifying rx and tx seperately
if [[ -z ${num_queues} ]]; then
	num_queues=$(ethtool -l ${interface} | grep -A4 Current | sed -ne 's/Combined:\s\+\([1-9]\+\)/\1/p')

	[[ -z ${num_queues} ]] && { echo "didn't manage to get number of queues" ; exit 1 ; }
fi

numa_0_cpus=$(lscpu | sed -n '/NUMA node0/s/^.*:\s\+//p' | sed 's/,/ /')
final_range=""
for cpu_range in ${numa_0_cpus}; do
	if echo ${cpu_range} | grep -q '-' > /dev/null ; then
		range_start=$(echo $cpu_range | cut -f1 -d-)
		range_end=$(echo $cpu_range | cut -f2 -d-)
		final_range=${final_range}$(seq ${range_start} ${range_end})
	fi
	final_range=${final_range}" "
done
echo "There are $(echo ${final_range} | wc -w) CPUs in NUMA0"

for queue in `seq 0 $(( num_queues -1 ))`; do
	starting_cpu=9
	used_cpu=$(( starting_cpu + queue * 2 ))
	#used_cpu=$( echo ${final_range} | cut -d' ' -f$(( queue + 1 )) )
	bitmask=$(echo "obase=16; ibase=10; ${used_cpu}" | bc)

	hex_cpu_val=""
	iterations=0
	shifted_cpu=${used_cpu}
	while [[ ${shifted_cpu} -ge 4 ]]; do
		shifted_cpu=$(( shifted_cpu - 4 ))
		hex_cpu_val="0"${hex_cpu_val}
		iterations=$(( (iterations + 1) % 8 ))
		if [[ ${iterations} -eq 0 ]]; then
			hex_cpu_val=","${hex_cpu_val}
		fi
	done
	hex_cpu_val=$(( 1 << (shifted_cpu) ))${hex_cpu_val}

	interrupt_line=$(cat /proc/interrupts | grep "\<${interface}-Tx-Rx-${queue}\>" | cut -d: -f1 | xargs echo)

	echo "queue ${queue} (iline: ${interrupt_line}) -> ${used_cpu} (bitmask: ${hex_cpu_val})"
	echo ${hex_cpu_val} > /proc/irq/${interrupt_line}/smp_affinity
done
