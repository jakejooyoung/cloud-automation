#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
echo END

# Placeholder variable exchanged for presigned, time-limit enforced access to npgains.keys/ S3 bucket.
keyurl="PRESIGNED_URL"


sudo apt-add-repository ppa:ubuntu-lxc/lxd-stable
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt-get update
apt-get -y upgrade

#Install nodejs
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
sudo systemctl status docker

export WORKSPACE=/home/ubuntu/work
mkdir -p $WORKSPACE

# Would save bitbucket host fingerprint to ubuntu accessible location.
# ssh-keyscan -t rsa bitbucket.org >> /home/ubuntu/.ssh/known_hosts
# Instead we save bitbucket host fingerprint to root accessible location.
ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts
# Start the ssh-agent in the background.
eval `ssh-agent -s`

# Download Bitbucket Read-Only Access Key from presigned S3-url 
curl -o /home/ubuntu/.ssh/repo_rsa $keyurl
# Change permission of repo_key to restrict access
chmod 400 /home/ubuntu/.ssh/repo_rsa
# Load repo key to ssh-agent
ssh-add /home/ubuntu/.ssh/repo_rsa

# Set up project repo.
# Pull from git repository or docker image registry.
cd $WORKSPACE
git clone git@bitbucket.org:gainsresearch/cm-backend-api-server.git .

#start server
docker-compose up --build

reboot 0
 