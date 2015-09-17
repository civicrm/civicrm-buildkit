#!/usr/bin/env bash
set -e
###############################################################
## This script is executed when launching a new virtual machine
###############################################################

## Update apt
sed -i 's/deb-src/#deb-src/' /etc/apt/sources.list
apt-get update

## Some basic helpers
apt-get install -y \
  colordiff \
  curl \
  git \
  git-man \
  joe \
  makepasswd \
  patch \
  subversion \
  unzip \
  wget \
  zip \
  nodejs-legacy

## MySQL
MYSQLPASS=$(makepasswd --chars=16)
echo "mysql-server-5.5 mysql-server/root_password password $MYSQLPASS" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQLPASS" | debconf-set-selections
apt-get install -y mysql-server-5.5 mysql-client-5.5
cat > /root/.my.cnf << EOF
[client]
user=root
password=$MYSQLPASS
EOF
chmod 600 /root/.my.cnf
cp /root/.my.cnf /home/vagrant/.my.cnf
chown vagrant.vagrant /home/vagrant/.my.cnf

## PHP
apt-get install -y php5-{cli,imap,ldap,curl,mysql,intl,gd} php-apc

## Apache
apt-get install -y apache2 libapache2-mod-php5

## Ruby (required for "hub")
apt-get install -y ruby rake

## civicrm-buildkit -- note: code is already shared (via Vagrantfile)
PRJDIR=/home/vagrant/civicrm-buildkit
sudo -u vagrant -H "$PRJDIR/bin/civi-download-tools"
cat > /etc/profile.d/civicrm_project.sh << EOF
PATH="$PRJDIR/bin:\$PATH"
export PATH
EOF

#[ ! -d "$PRJDIR/app/tmp/apache.d" ] && mkdir -p "$PRJDIR/app/tmp/apache.d"
echo "IncludeOptional /home/vagrant/.amp/apache.d/*.conf" > /etc/apache2/conf-available/civicrm-buildkit.conf
a2enconf civicrm-buildkit

sudo -u vagrant -H $PRJDIR/bin/amp config:set \
  --mysql_type="mycnf" \
  --httpd_type="apache" \
  --perm_type="worldWritable"
#  --mysql_type="dsn" \
#  --mysql_dsn="mysql://root:$MYSQLPASS@localhost:3306" \
#  --apache_dir="$PRJDIR/app/tmp/apache.d" \
