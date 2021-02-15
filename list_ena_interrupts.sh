#!/bin/bash

NR_CPUS=$(getconf _NPROCESSORS_ONLN)

while true; do
	# store interrupts into array
	interrupts=()
	nr_queues=0
	while read line; do
		interrupts[${nr_queues}]="${line}"
		nr_queues=$(( nr_queues + 1 ))
	done <<< "$(cat /proc/interrupts | grep eth0-Tx-Rx)"

	time_now=$(date +%s.%N)

	if [[ ! -z ${first_round_done} ]]; then
		for i in `seq 0 ${nr_queues}`; do
			previous_queue_interrupts=${previous_interrupts[$i]}
			current_queue_interrupts=${interrupts[$i]}

			output=""
			for cpu_nr in `seq 0 $(( NR_CPUS - 1 ))`; do
				# transform the string into array
				#previous_queue_interrupts=(${previous_queue_interrupts})
				#current_queue_interrupts=(${current_queue_interrupts})

				previous_int_nr=$(echo ${previous_queue_interrupts} | cut -d' ' -f $(( cpu_nr + 2 )) )
				current_int_nr=$(echo ${current_queue_interrupts} | cut -d' ' -f $(( cpu_nr + 2 )))

				diff=$(( current_int_nr - previous_int_nr ))
				if [[ ${diff} -gt 0 ]]; then
					output="${output} CPU[$cpu_nr]: ${diff} "
				fi
			done
			if [[ ! -z ${output} ]]; then
				echo "queue[${i}] = ${output}"
			fi
		done

	fi

	time_prev=${time_now}
	previous_interrupts=()
	for i in `seq 0 ${nr_queues}`; do
		previous_interrupts[${i}]=${interrupts[${i}]}
	done

	first_round_done="true"
	echo "======================"

	sleep 1
done
