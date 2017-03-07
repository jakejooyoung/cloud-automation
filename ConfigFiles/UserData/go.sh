#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive	

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
echo END

keyurl="PRESIGNED_URL"
curl -o /home/ubuntu/key $keyurl
cat /home/ubuntu/key

sudo apt-add-repository ppa:ubuntu-lxc/lxd-stable
apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install golang
cat > /etc/profile.d/debug<<EOL
$HOME
EOL

export GOPATH=/home/ubuntu/work
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
cat > /etc/profile.d/setgoenv.sh <<EOL
export GOPATH=/home/ubuntu/work
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOL

MYGO=$GOPATH/src/bitbucket.org/gainsresearch/goserver

cd $MYGO 
git clone git@bitbucket.org:gainsresearch/go.git .
git co -b gostructure

chown -R ubuntu:staff $GOPATH
go get github.com/lib/pq
reboot 0
