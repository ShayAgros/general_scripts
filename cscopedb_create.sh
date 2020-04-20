#!/usr/bin/env bash

function usage {
	echo "usage: ${0} [base directory] {sub directories}"
	exit 1
}

[[ -z ${1} ]] && usage
base_dir=${1}

# Check dir validity
ls $base_dir >/dev/null 2>&1 || { echo "Directory is not valid" ; exit 2 ; }

which cscope >/dev/null 2>&1 || { echo "cscope is not installed" ; exit 3 ; }

rm -f /tmp/cscope.files

shift
# Check if more arguments are provided
echo "Finding files ..."
if [[ -z ${@} ]]; then
	find "${base_dir}" -name '*.[ch]' > "/tmp/cscope.files"
else
	for dir; do
		find "${base_dir}/${dir}" -name '*.[ch]' >> "/tmp/cscope.files"
	done
fi

cscope -b -f ${base_dir}/cscope.out -i /tmp/cscope.files
echo cscope data base created
