#!/usr/bin/env python

import os
import sys
import json

ami_id=""
if len(sys.argv) < 2:
    ami_id = "ami-0947d2ba12ee1ff75"
else:
    ami_id = sys.argv[1]

print("Ami id={}".format(ami_id))

instance_desc=os.popen('aws ec2 --region us-east-1 describe-images --image-ids {}'.format(ami_id)).read()
# instance_desc=os.popen('echo {}'.format(ami_id))

json_output=json.loads(instance_desc)['Images'][0]['BlockDeviceMappings']

# modify storage
json_output[0]['Ebs']['VolumeSize'] = 100

print(json.dumps(json_output, indent=4))

with open('mapping.json', 'w') as outfile:
    json.dump(json_output, outfile, indent=4)
