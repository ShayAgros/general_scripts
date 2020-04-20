#!/usr/bin/env bash

sed -i '/#define DRV_MODULE_NAME/s/ena/testing_ena/' ena_netdev.h
