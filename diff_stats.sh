#!/usr/bin/env bash

stats_command=""
interface=""
interval=1
program_name=$(basename ${0})

function usage() {

	echo Usage:
	echo -e "${program_name} [-i|--interval <interval>] <interface name>"
	echo -e "\t diff stats for given interface for command ethtool -S"
	echo
	echo -e "OR"
	echo
	echo -e "${program_name} [-i|--interval <interval>] -- <diff command>"
	echo -e "\t diff stats for a given command"
	echo
	echo
	echo -e "This tool prints the statistics every time interval (in seconds)."
	echo -e "Only the stats difference value from previous run is printed, and"
	echo -e "if there is no change the stat is not printed at all"
	echo
	echo -e "This tool also aggregates stats of the format"
	echo -e "          queue_<number>_<stat_name>         "
	echo -e "and for every such stats creates a"
	echo -e "          total_<stat_name>                 "
	echo -e "statistic (which is also printed only if it is different from previous"
	echo -e "output (for a given interval)"
}

function diff_stats() {
	previous_output=""
	echo evaluating command: ${stats_command}

	while true; do

		output="$(eval ${stats_command})" || { echo error executing stats command ; exit 2 ; }

		#echo output of the command it:
		#echo "${output}"
		time_now=$(date +%s.%N)

		if [[ ! -z ${previous_output} ]]; then

			time_diff=$(echo "${time_now} - ${time_prev}" | bc -l)

			# substract current stats run from previous run and sum totals
			var=`awk -v CONVFMT=%.4g -v tdiff=${time_diff} '

			function round(value) {
				floored=int(value)
				if (value - floored >= 0.5)
					return floored +1
				else
					return floored
			}

			function print_with_units(prefix, value) {
				if (value <= 0)
					return value

				if(value > 10^9)
					print prefix " " (value/(10^9))"G"
				else if(value > 10^6)
					print prefix " " (value/(10^6))"M"
				else if(value > 10^3)
					print prefix " " (value/(10^3))"K"
				else
					print prefix " " value
			}

			BEGIN { print "==============="
					print "time diff is " tdiff
					i=0
			}
			FNR==NR{a[$1]=$2;next}
			{
				difference=a[$1]-$2

				print_with_units($1 FS, round(difference/tdiff))

				if ( sub(/queue_[0-9]+_/, "", $1) > 0 ) {
					if ( length(totals[$1]) == 0 ) {
							order_array[i++] = $1
							totals[$1] = difference
					}
					else
						totals[$1] += difference
				}
			}
			END {
				for (j = 0; j < i ; j++) {
					print_with_units("total_"order_array[j] FS, round(totals[order_array[j]]/tdiff))
				}
			}
			' <(echo "${output}") <(echo "${previous_output}")`
			echo "${var}"

		fi

		previous_output="${output}"
		time_prev=${time_now}

		sleep ${interval}

		# clear previous stats
		tput clear

	done
}

while [[ $# -gt 0 ]]
	do
		key="$1"

		case $key in
			--help|-h)
				usage
				exit 1
			;;
			--interval|-i)
				shift
				interval=${1}
				shift
			;;
			--)
				shift
				stats_command="${@:1}"
				break
			;;
			*)
				if [[ -z ${interface} ]]; then
					# we allow the first unknown option to represnt an interface
					interface=${key}
					shift
				else
					# unknown option
					echo "error: invalid option ${key}"
					usage
					exit 1
				fi
			;;
		esac
done

if [[ -z ${stats_command} ]] && [[ -z ${interface} ]]; then
	echo error: neither stats command or interface were specified
	usage
	exit 1
fi

echo command: ${stats_command:-"default (ethtool -S <interface name>)"}
echo interface: ${interface:-"none"}
echo interval: ${interval}

[[ -z ${stats_command} ]] && stats_command="ethtool -S ${interface}"

echo
echo "Starting stats diff print:"
diff_stats
