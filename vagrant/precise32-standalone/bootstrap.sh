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
  acl \
  colordiff \
  curl \
  git \
  git-man \
  joe \
  makepasswd \
  patch \
  rsync \
  subversion \
  unzip \
  wget \
  zip

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
apt-get install -y ruby1.8 rake

## civicrm-buildkit -- Re-install within VM
LPRJDIR=/home/vagrant/buildkit
RPRJDIR=/home/vagrant/buildkit.host
[ ! -d "$LPRJDIR" ]                   && sudo -u vagrant -H git clone "file://$RPRJDIR" "$LPRJDIR"
[ ! -d "$LPRJDIR/app/tmp" ]           && sudo -u vagrant -H mkdir -p "$LPRJDIR/app/tmp"
[ ! -d "$RPRJDIR/app/tmp" ]           && sudo -u vagrant -H mkdir -p "$RPRJDIR/app/tmp"
[ ! -e "$LPRJDIR/app/tmp/git-cache" ] && sudo -u vagrant -H ln -s "$RPRJDIR/app/tmp/git-cache" "$LPRJDIR/app/tmp/git-cache"
#[ ! -d "$LPRJDIR/vendor" ]            && sudo -u vagrant -H mkdir -p "$LPRJDIR/vendor"
#sudo -u vagrant -H rsync -a "$RPRJDIR/vendor/./" "$LPRJDIR/vendor/./"
sudo -u vagrant -H "$LPRJDIR/bin/civi-download-tools"
cat > /etc/profile.d/civicrm_project.sh << EOF
PATH="$LPRJDIR/bin:\$PATH"
export PATH
EOF

#[ ! -d "$LPRJDIR/app/tmp/apache.d" ] && mkdir -p "$LPRJDIR/app/tmp/apache.d"
echo "Include /home/vagrant/.amp/apache.d/*.conf" > /etc/apache2/conf.d/civicrm-buildkit

sudo -u vagrant -H $LPRJDIR/bin/amp config:set \
  --mysql_type="mycnf" \
  --httpd_type="apache" \
  --perm_type="linuxAcl" \
  --perm_user="www-data"
##  --mysql_type="dsn" \
##  --mysql_dsn="mysql://root:$MYSQLPASS@localhost:3306" \
##  --apache_dir="$LPRJDIR/app/tmp/apache.d" \
