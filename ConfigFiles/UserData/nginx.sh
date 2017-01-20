#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo BEGIN
"Setting up reverse proxy server"
date '+%Y-%m-%d %H:%M:%S'
echo END

apt-get update
apt-get install -y python-pip python-dev build-essential 
pip install --upgrade pip 
pip install --upgrade virtualenv 
pip install awscli
apt-get install -y nginx
apt-get install -y letsencrypt 

export DOMAIN="domain_placeholder"
export EMAIL="jakejooyoung@gmail.com"
export DOMAINS="$DOMAIN"', www.'"$DOMAIN"


mkdir -p /var/www/letsencrypt/.well-known/acme-challenge/
chgrp www-data /var/www/letsencrypt/
(aws s3 cp s3://npgains.nginxconfig/beforecert - | sed 's#$DOMAIN#'"$DOMAIN"'#') > /etc/nginx/sites-available/default
nginx -t && nginx -s reload
mkdir -p /etc/letsencrypt/
(aws s3 cp s3://npgains.letsencrypt.global.ini - | sed -e 's#$DOMAINS#'"$DOMAINS"'#' -e 's#$EMAIL#'"$EMAIL"'#')	> /etc/letsencrypt/cli.ini
letsencrypt certonly -c /etc/letsencrypt/cli.ini

echo "ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;\
\nssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"\
> /etc/nginx/snippets/ssl-$DOMAIN.conf
(aws s3 cp s3://npgains.nginxconfig/aftercert.ini - | sed -e 's#$DOMAIN#'"$DOMAIN"'#') > /etc/nginx/sites-available/default
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
nginx -t && nginx -s reload
"Exiting..."
date '+%Y-%m-%d %H:%M:%S'
echo END

exit 0
 
" > /etc/rc.local
 
reboot 0
