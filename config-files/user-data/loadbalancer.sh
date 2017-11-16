#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo BEGIN
"Setting up reverse proxy server"
date '+%Y-%m-%d %H:%M:%S'
echo END

# Install Deps

apt-get update
apt-get install -y python-pip python-dev build-essential 
pip install --upgrade pip 
pip install --upgrade virtualenv 
pip install awscli
apt-get install -y nginx

#############################################################################################################

# Configure basic load balancing NginX server to use for getting HTTPS Cert. 

# S3 Get: NginX Configuration ("loadbalancer")
(aws s3 cp s3://npgains.nginxconfig/loadbalancer -)\
	> /etc/nginx/sites-available/default

touch /etc/nginx/upstream.conf
# S3 Get: SSL-param Configuration	
(aws s3 cp s3://npgains.nginxconfig/loadbalancer-upstream -)\
	> /etc/nginx/upstream.conf

nginx -t && nginx -s reload

"Exiting..."
date '+%Y-%m-%d %H:%M:%S'
echo END

exit 0
 
" > /etc/rc.local
 
reboot 0
