## Introduction

Backend service for SparkTrade. Currently contains boilerplate for a login flow, and a terraform script to build it on EC2.

## Deployment

### Create Key Pair
The terraform script expects you to have this key pair already created, and is what will allow you to ssh into the EC2 instance.

1. You can do this by using this command:
`ssh-keygen -t rsa -b 2048 -f deployer-key`

2. Now, ensure that the keys have been appropriately created.
`ls | grep deployer-key`
This command should output two files, a private key and a public key.

3. Change the file permissions on your private key
`chmod 400 deployer-key`

### Modify the Terraform Script
1. Set the `public_key = file(/home/fares/deployer-key.pub)` to the path to your public key.
2. Set the `private_key = file(/home/fares/deployer-key)` to the path to your private key.