#!/bin/bash
set -x
export DEBIAN_FRONTEND=noninteractive
export DBNAME="nopaindb"
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN
date '+%Y-%m-%d %H:%M:%S'
echo END

sudo apt-get update
echo "Installing Dependencies"
sudo apt-get install -y postgresql postgresql-client postgresql-contrib

echo "Configuring PostgreSQL"
sudo usermod -a -G sudo postgres 
new_pass="newpass"
sudo su postgres -c psql "ALTER USER postgres WITH PASSWORD $new_pass;"
sudo -i -u postgres
createdb $DBNAME
vi /etc/postgresql/8.2/main/pg_hba.conf # Append -> host all all 10.10.29.0/24 trust
vi /etc/postgresql/8.2/main/postgresql.conf # Specify port or listen all (*)
/etc/init.d/postgresql restart 

##
#Test from client system. username
#requires -> sudo apt-get install postgresql-client 
#psql -h 10.10.29.50 -U username -d dbname
exit 0
 
" > /etc/rc.local
reboot 0