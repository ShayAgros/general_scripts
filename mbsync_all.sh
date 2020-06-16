#!/usr/bin/env bash

# This would call mbsync for every channel

set -x

# make gpg-agent stash password
gpg2 -q --for-your-eyes-only --no-tty -d ~/.emacs.d/.mbsyncpass.gpg >/dev/null 2>&1

# sync Amazon (exchange) mail
mbsync amazon >/dev/null 2>&1 &
export amazon_pid=$!

# sync gmail mail
mbsync gmail >/dev/null 2>&1 &
export gmail_pid=$!

# wait for the gmail process to finish
wait ${gmail_pid}
gmail_exit_val=$?

wait ${amazon_pid} 
amazon_exit_val=$?

[[ $gmail_exit_val > 0 ]] && { echo "Error syncing gmail"; exit 1; }
[[ $amazon_exit_val > 0 ]] && { echo "Error syncing amazon"; exit 1; }

exit 0
