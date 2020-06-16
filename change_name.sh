#!/usr/bin/env bash

new_name=$(echo ${1} | sed 's/\(.*shay-pc\),U=.*/\1/')

echo old name: ${1}
echo new name: ${new_name}

mv ${1} ${new_name}
