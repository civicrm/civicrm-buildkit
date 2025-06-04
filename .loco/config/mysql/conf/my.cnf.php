<?php
function printenv($v, $suffix = '') {
  echo getenv($v) . $suffix;
}
$serviceDir = getenv('LOCO_SVC_VAR') . '/' . getenv('MYSQL_ID');
?>
!include <?php echo $serviceDir; ?>/conf/common-my.cnf

[client]
user		= root
#password	= your_password
port		= <?php printenv('MYSQLD_PORT', "\n"); ?>
socket		= <?php echo $serviceDir; ?>/run/mysql.sock

[mysqld]
server-id	= <?php printenv('MYSQLD_PORT', "\n"); ?>
bind-address	= <?php printenv('LOCALHOST', "\n"); ?>
# bind-address	= *
port		= <?php printenv('MYSQLD_PORT', "\n"); ?>
socket		= <?php echo $serviceDir; ?>/run/mysql.sock
pid_file        = <?php echo $serviceDir; ?>/run/mysql.pid
tmpdir          = <?php echo $serviceDir; ?>/tmp

# Uncomment the following if you are using InnoDB tables
#innodb_data_home_dir = /var/lib/mysql
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = /var/lib/mysql
