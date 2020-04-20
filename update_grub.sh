#!/usr/bin/env bash

entries=()

function list_grub_entries() {

	count_arr=(0 0 0 0 0 0)
	last_item_ix=0
	while IFS= read -r line; do
		
		if [[ ${line} == *}* ]] && (( last_item_ix > 0 )); then
			let last_item_ix--
		fi

		if [[ ${line} == *menuentry\ * ]] || [[ ${line} == *submenu\ * ]]; then
			
			if [[ ${line} == *menuentry\ * ]]; then
				if (( last_item_ix > 0 )); then
					prev_index=${count_arr[$((last_item_ix-1))]}
					# we increased previous index by 1, but now we're in a
					# sub item if it
					index="$((prev_index-1))>${count_arr[${last_item_ix}]}"
				else
					index="${count_arr[${last_item_ix}]}"
				fi

				current_entry=$(printf "${line}" | sed "s/\(\s*\)[^']*'\([^']*\)'.*'.*/\2/")
				entries+=("${index}"  "${current_entry}")
			else
				index=""
			fi
			
			let count_arr[${last_item_ix}]++

			let last_item_ix++
			count_arr[$last_item_ix]=0
		fi

	done < /boot/grub2/grub.cfg

}

#set -x

if [[ ! $EUID -eq 0 ]]; then
	echo "Run script as root"
	exit 1
fi
	    
if ! grep -q 'GRUB_DEFAULT=saved' /etc/default/grub > /dev/null 2>&1; then

	sed -i '/GRUB_DEFAULT=/d' /etc/default/grub

	printf "\nGRUB_DEFAULT=saved" >> /etc/default/grub
fi

# update the grub config file with current kernels
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

list_grub_entries

if ! which whiptail >/dev/null 2>&1; then

	echo "Grub2 entries are:"
	i=0
	arr_length=${#entries[@]}
	while (( i < arr_length )); do
		printf "${entries[$i]}\t${entries[$(( i + 1 ))]}\n"
		i=$((i+2))
	done

	echo -e "\nYou can install 'whiptail' program to choose between them"
	exit 0
fi

MenuText="Menu No. --------------- Menu Name ---------------"

choice=$(whiptail --clear \
		--title "Use arrow, page, home & end keys. Tab toggle option" \
		--ok-button "Choose as default" \
		--default-item "0" \
		--cancel-button "Exit" \
		--menu "$MenuText" 24 80 16 \
		"${entries[@]}" \
		2>&1 >/dev/tty)

echo "You chose option ${choice}"
#echo "Choose the client you want to choose using grub2-make-dafault from following list"
sudo grub2-set-default "${choice}"
