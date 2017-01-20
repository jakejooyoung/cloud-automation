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

mkdir home/ubuntu/work
cat >/etc/profile.d/ <<EOL
export GOPATH=/home/ubuntu/work
export PATH=$PATH:/work/bin
export GOBIN=/work/bin
EOL
mkdir -p /home/ubuntu/work/src/gainsrg.com/coreengine/app

exit 0
 
" > /etc/rc.local
 
reboot 0
