#!/usr/bin/env python

import os
import sys
import awscli as aws
import boto3

amis_dict = { 'amazon2_x86': 'ami-0713f98de93617bb4' }

os.popen('/home/shay/scripts/create_ami_volume_mapping.py {}'.format(amis_dict['amazon2_x86']))


client = boto3.client

os.popen('''aws ec2 run-instances --image-id {} --count 2 \
            --instance-type c5.18xlarge --key-name dublin --security-group-ids sg-14057963 \
            --block-device-mappings file://mapping.json '''.format(amis_dict['amazon2_x86']))
