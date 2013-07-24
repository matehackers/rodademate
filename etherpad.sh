#!/bin/bash

source utils.sh

INSTALL_PATH="/var"
LOG_PATH="/var/log/etherpad-lite"

echo "This script will attempt to install Etherpad Lite on '$INSTALL_PATH/etherpad-lite'"
echo "If that's not right cancel it now and edit the variable 'INSTALL_PATH' on the top of this script."
wait_msg "If you need more info see the article this is based on: \
 https://help.ubuntu.com/community/Etherpad-liteInstallation"

# Creating the etherpad user
sudo adduser --system --home=/opt/etherpad --group etherpad

# Dependencies
sudo apt-get install -y gzip git-core curl python libssl-dev build-essential abiword python-software-properties

cd $INSTALL_PATH
sudo git clone git://github.com/ether/etherpad-lite.git

# Log files
sudo mkdir $LOG_PATH

sudo chown etherpad $LOG_PATH
sudo chown -R etherpad $LOG_PATH

# Create file to use as a service
sudo echo "description \"etherpad-lite\"

start on started networking
stop on runlevel [!2345]

env EPHOME=$INSTALL_PATH
env EPLOGS=$LOG_PATH
env EPUSER=etherpad

pre-start script
    cd \$EPHOME
    mkdir \$EPLOGS                               	  ||true
    chown \$EPUSER:admin \$EPLOGS                	  ||true
    chmod 0755 \$EPLOGS                          	  ||true
    chown -R \$EPUSER:admin \$EPHOME/var         	  ||true
    \$EPHOME/bin/installDeps.sh >> \$EPLOGS/error.log || { stop; exit 1; }
end script

script
  cd \$EPHOME/
  exec su -s /bin/sh -c 'exec \"\$0\" \"\$@\"' \$EPUSER -- node node_modules/ep_etherpad-lite/node/server.js \
                        >> \$EPLOGS/access.log \
                        2>> \$EPLOGS/error.log
end script" > /etc/init/etherpad-lite.conf

sudo echo "$LOG_PATH/*.log
{
        rotate 4
        weekly
        missingok
        notifempty
        compress
        delaycompress
        sharedscripts
        postrotate
        	restart etherpad-lite >/dev/null 2>&1 || true
        endscript
}" > /etc/logrotate.d/etherpad-lite

echo "To install plugins see the file etherpad-plugins.sh"
wait_msg"The administrator should be configured in '$INSTALL_PATH/etherpad-lite/settings.json'"

echo "This ends the installation of Etherpad Lite."
wait_msg "I'll continue to install MySQL and configure it for usage with this server. Stop now if you're happy."

# Installing MySQL
sudo apt-get -y install mysql-server mysql-common mysql-client

# Create MySQL database
MYSQL_PASSWD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c 8)
Q1="CREATE DATABASE IF NOT EXISTS etherpad-lite;"
Q2="GRANT ALL PRIVILEGES ON etherpad-lite.* TO 'etherpad'@'localhost' IDENTIFIED BY '$MYSQL_PASSWD';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
print "Enter you MySQL "
mysql -uroot -p"" -e "$SQL" > /dev/null 2>&1

echo "Database: etherpad-lite"
echo "Database user: etherpad"
echo "Database host: localhost"
echo "Database user password: $MYSQL_PASSWD"

wait_msg "Don't forget to change the database in '$INSTALL_PATH/etherpad-lite/settings.json'"

echo "Initializing etherpad-lite ..."
sudo service etherpad-lite start