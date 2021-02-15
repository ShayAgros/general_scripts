#!/bin/bash

set -x

echo ${1} | sudo tee /proc/sys/net/core/busy_poll
echo ${1} | sudo tee /proc/sys/net/core/busy_read
