#!/bin/bash
sudo apt-get update
sudo apt-get install -y python3 python3-pip git

# Clone the repository from Git
git clone https://github.com/FaresAT/SparkTradeServer.git /home/ubuntu/backend

cd /home/ubuntu/backend/api

sudo apt-get update
sudo apt-get update

sudo pip install -r requirements.txt

# Start the Flask application
nohup python3 login.py &
jus 