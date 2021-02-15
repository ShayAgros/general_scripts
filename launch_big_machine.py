#!/usr/bin/env python3

import os
import sys
#import awscli as aws
# import boto3

amis_dict = { 'amazon2_x86': 'ami-07d9160fa81ccffb5' }

os.popen('/home/ANT.AMAZON.COM/shayagr/workspace/scripts/create_ami_volume_mapping.py {}'.format(amis_dict['amazon2_x86']))


# client = boto3.client

os.popen('''aws ec2 run-instances --image-id {} --count 1 \
            --instance-type c5.18xlarge --key-name dublin --security-group-ids sg-14057963 \
            --block-device-mappings file://mapping.json '''.format(amis_dict['amazon2_x86']))
