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
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

curl -sL https://deb.nodesource.com/setup_8.x | -E bash -

apt-get update
apt-get -y upgrade

#Install nodejs
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y nodejs
ln -s /usr/bin/nodejs /usr/bin/node;

#Install yarn
apt-get install yarn

export WORKSPACE=/home/ubuntu/work
mkdir -p $WORKSPACE

# Add github to known hosts
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

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
git clone git@github.com:jknpg/tweetfeed-api.git .
#git clone git@bitbucket.org:gainsresearch/cm-frontend-web-server.git .

#Install forever as global dependency
yarn global add forever

#start server
yarn install
# We need to first configure .env file before running yarn.
# yarn start

#node app.js

#Change ownership of $GOPATH to ubuntu in case we need to changes on go server
chown -R ubuntu /home/ubuntu/work

reboot 0
 