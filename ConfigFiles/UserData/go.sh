#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive	

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
echo END

sudo apt-add-repository ppa:ubuntu-lxc/lxd-stable
apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install golang
cat > /etc/profile.d/two<<EOL
$HOME
tell me where is home 
EOL

export GOPATH=/home/ubuntu/work
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
cat > /etc/profile.d/setgoenv.sh <<EOL
export GOPATH=/home/ubuntu/work
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOL

MAINGO=$GOPATH/src/bitbucket.org/gainsresearch/goserver
mkdir -p $MAINGO/tmpl
cat > /home/ubuntu/work/src/bitbucket.org/gainsresearch/goserver/tmpl/edit.html <<EOL
<h1> EDIT NOW </h1>
EOL
cat > /home/ubuntu/work/src/bitbucket.org/gainsresearch/goserver/tmpl/view.html <<EOL
<h1> EDIT TOMORROW </h1>
EOL
chown -R ubuntu:staff $GOPATH
go get github.com/lib/pq
reboot 0