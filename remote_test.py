#!/usr/bin/env python2
# -*- coding: utf-8 -*-

from UniformSructures import UniformList, UniformDict
from NewManager import InstancesManager, PairsManager
from RemoteAgent import fetchAgent
from json import dumps, JSONEncoder
from Logger import ContextLoggers
from inspect import getmembers


def main():

	agent = fetchAgent(
		hostname="34.245.194.191",
		username="ec2-user",
		RSAKeyFile="AgentRsaKey.pem",
		defaultRegion="eu-west-1",
		defaultSubnet="subnet-04c2a068a0722eb5d",
		defaultKey="ena_drivers",
		defaultIamProfile="AWS-Test-Instance",
		defaultS3Bucket="ena-driver",
		defaultS3Path="Temp/",
		defaultSecurityGroup="sg-095a24aee398f18f9"
	)

	manager = PairsManager(agent)

	manager.run(
        serverInstanceType="c5n.2xlarge",
        serverImageId="ami-0ce71448843cb18a1",
        serverTags={
            "Environment": "ENA-Linux-Driver CI",
            "Task": "Testing New Structs",
            "Role": "Server"
        },
        clientInstanceType="c5n.2xlarge",
        clientImageId="ami-0ce71448843cb18a1",
        clientTags={
            "Environment": "ENA-Linux-Driver CI",
            "Task": "Testing New Structs",
            "Role": "Client"
        }
    )
	manager.instances.waitReady()

	print manager.instances.runCommands(document = "AWS-RunShellScript", parameters = { "commands": [ "echo message > /dev/kmsg" ] }).outputs["0.aws:runShellScript"]


if __name__ == "__main__":
	main()
