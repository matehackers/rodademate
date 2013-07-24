#!/bin/bash

source utils.sh

# Path to your localhost
INSTALL_PATH="/var/www"
 
# Apache User
HTTP_USER="www-data"

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
echo "This script must be run as root" 1>&2
   exit 1
fi

echo "This script will attempt to install Owncloud on '$INSTALL_PATH/owncloud'"
echo "If that's not right cancel it now and edit the variable 'INSTALL_PATH' on the top of this script."
wait_msg "If you need more info see the article this is based on: \
 http://www.rosehosting.com/blog/script-install-owncloud-on-an-ubuntu-12-04-vps/"

# Server and DB dependencies
apt-get -y install apache2 libapache2-mod-php5 mysql-server mysql-common mysql-client php5-mysql

# Create MySQL database
MYSQL_OC_PASSWD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 8)
Q1="CREATE DATABASE IF NOT EXISTS owncloud;"
Q2="GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'localhost' IDENTIFIED BY '$MYSQL_OC_PASSWD';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
echo "Enter you MySQL "
mysql -uroot -p"" -e "$SQL" > /dev/null 2>&1
 
# Check if the database is created
if [ $? -ne 0 ]; then
    echo "Cannot connect to the MySQL database server"
    exit 1
fi

mkdir /etc/apache2/sites-available

# Create the file with VirtualHost configuration
echo "<VirtualHost *:80>
        DocumentRoot $INSTALL_PATH/owncloud
        ServerName localhost
        ServerAlias localhost
        <Directory $INSTALL_PATH/owncloud>
                Options Indexes FollowSymLinks MultiViews +Includes
                AllowOverride All
                Order allow,deny
                allow from all
        </Directory>
</VirtualHost>" > /etc/apache2/sites-available/owncloud
 
# Update System
apt-get -y update > /dev/null 2>&1
 
# Install PHP modules
apt-get -y install php5 php5-gd php5-json php-xml php-mbstring php5-zip php5-gd php5-sqlite php5-mysql curl libcurl3 libcurl3-dev php5-curl php-pdo
 
# Download and extract the latest version
wget -qO- -O tmp.tar.bz2 http://download.owncloud.org/community/owncloud-latest.tar.bz2 \
     && tar -C $INSTALL_PATH -xjf tmp.tar.bz2 && rm tmp.tar.bz2
 
# Set owner
chown $HTTP_USER: -R $INSTALL_PATH/owncloud
 
# Enable the site
a2ensite localhost
 
# Reload Apache2
/etc/init.d/apache2 restart
 
# Output
echo "Open your web browser and navigate to your ownCloud instance"
echo "Url: $1"
echo "Database: owncloud"
echo "Database user: owncloud"
echo "Database user password: $MYSQL_OC_PASSWD"

