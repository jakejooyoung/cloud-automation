#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
echo END

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/testing multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list

apt-get update

curl -sL https://deb.nodesource.com/setup_7.x | -E bash -
apt-get install -y nodejs
ln -s /usr/bin/nodejs /usr/bin/node

apt-get install -y npm


apt-get install -y mongodb-org
#MongoDB systemd service file [Ubuntu 16.04 only]
echo '[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target' >/lib/systemd/system/mongod.service 


apt-get install -y ruby-full
npm install -g bower
npm install -g grunt-cli
npm install -g --no-optional forever
 
reboot 0