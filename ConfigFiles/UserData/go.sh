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
apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install golang
cat > /etc/profile.d/debug<<EOL
	$HOME
EOL

# Prepare GOPATH and working directory 
export GOPATH=/home/ubuntu/work
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
cat > /etc/profile.d/setgoenv.sh <<EOL
	export GOPATH=/home/ubuntu/work
	export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOL
MYGO=$GOPATH/src/bitbucket.org/gainsresearch/go
mkdir -p $MYGO

# # Configure ssh identity
# cat > /home/ubuntu/.ssh/config <<EOL
# Host bitbucket.org
# IdentityFile /home/ubuntu/.ssh/repo_rsa
# EOL

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
cd $MYGO
git clone git@bitbucket.org:gainsresearch/go.git .
git co -b gostructure

chown -R ubuntu:staff $GOPATH
go get github.com/lib/pq

reboot 0
