#!/usr/bin/env bash

mkdir ~/Downloads/Combinatorics_234141 >/dev/null 2>&1
cd ~/Downloads/Combinatorics_234141

# webcourse is divided into <tbody> sections. Don't parse sections that don't
# have links in them
grep '<tbody>' ${@} | grep href | while read line; do
	i=0

	prev_entry=""

	# only parse panopto videos
	echo ${line} | grep -q panoptotech >/dev/null 2>&1 || continue

	echo ${line} | grep -Eo '(>[^<]+)|(https://[^"]+)' | while read entry; do

		entry=${entry/\>/}

		if [[ ${entry} == ${prev_entry} ]]; then
			continue
		fi

		# first entry in tbody is the section name
		if [[ ${i} -eq 0 ]]; then
			echo -e "${entry}\n\n"
			let i++
			mkdir "${entry}" 2>/dev/null
			pushd "${entry}"
			continue
		fi

		echo -n "${entry} "

		#eco ${entry} | grep panoptotech >/dev/null 2>&1 && wget --output-document=${prev_entry} 
		if echo ${entry} | grep -q panoptotech >/dev/null 2>&1 ; then
			id=$(echo ${entry} | sed 's/.*id=\(.\+\)$/\1/')
			file_name=$(echo $prev_entry | cut -d' ' -f1)
			#echo ""
			#echo Downloading file ${file_name} from https://panoptotech.cloud.panopto.eu/Panopto/Podcast/Syndication/${id}.mp4
			wget --output-document=${file_name}.mp4 https://panoptotech.cloud.panopto.eu/Panopto/Podcast/Syndication/${id}.mp4
		fi

		prev_entry=${entry}

		echo "${entry}" | grep -q https >/dev/null 2>&1 && echo "  ";
	done

	popd >/dev/null 2>&1
	echo "  "
	echo "  "

done
