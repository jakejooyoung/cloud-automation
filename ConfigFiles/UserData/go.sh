#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
echo END

add-apt-repository ppa:ubuntu-lxc/lxd-stable
apt-get update
apt-get install -y golang
mkdir $HOME/work
export GOPATH=$HOME/work
export PATH=$PATH:$GOPATH/bin
export GOBIN=$GOPATH/bin
mkdir -p $GOPATH/src/gainsrg.com/coreengine/app

exit 0
 
" > /etc/rc.local
 
reboot 0
