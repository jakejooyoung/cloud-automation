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
python -m pip uninstall pip && apt install python-pip --reinstall
pip install uwsgi
pip install --upgrade virtualenv 
pip install awscli
apt-get install -y nginx
apt-get install -y letsencrypt

export DOMAIN="domain_placeholder"
export EMAIL="jakejooyoung@gmail.com"
export DOMAINS="$DOMAIN"', www.'"$DOMAIN"

#############################################################################################################

# Configure basic NginX server to use for getting HTTPS Cert. 

# S3 Get: NginX Configuration ("beforecert")
(aws s3 cp s3://npgains.nginxconfig/beforecert - | sed 's#$DOMAIN#'"$DOMAIN"'#')\
	> /etc/nginx/sites-available/default

nginx -t && nginx -s reload

# Configure HTTPS

# S3 Get: Let's Encrypt Configuration
mkdir -p /etc/letsencrypt/
(aws s3 cp s3://npgains.letsencrypt/cli.ini - | sed -e 's#$DOMAINS#'"$DOMAINS"'#' -e 's#$EMAIL#'"$EMAIL"'#')\
	> /etc/letsencrypt/cli.ini

# Prepare NginX server directory for LE
mkdir -p /var/www/letsencrypt/.well-known/acme-challenge/
chgrp www-data /var/www/letsencrypt/

# Start Let's Encrypt
letsencrypt certonly -c /etc/letsencrypt/cli.ini

# Create file to manage cert paths
cat >/etc/nginx/snippets/ssl-$DOMAIN.conf <<EOL
	ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
EOL

# Configure nginx server block accordingly for SSL
export RANDFILE=~/.rnd
openssl dhparam -out /etc/nginx/dhparams.pem 2048

# S3 Get: NginX Configuration ("aftercert")
(aws s3 cp s3://npgains.nginxconfig/aftercert - | sed -e 's#$DOMAIN#'"$DOMAIN"'#')\
	> /etc/nginx/sites-available/default

# S3 Get: SSL-param Configuration	
(aws s3 cp s3://npgains.nginxconfig/sslparams - )\
	> /etc/nginx/snippets/ssl-params.conf

# S3 Get: Def. HTML file and place in index.html
(aws s3 cp s3://npgains.views/npg-def.html -)\
	> /usr/share/nginx/html/index.html

#Reload NginX
nginx -t && nginx -s reload

"Exiting..."
date '+%Y-%m-%d %H:%M:%S'
echo END

exit 0
 
" > /etc/rc.local
 
reboot 0
