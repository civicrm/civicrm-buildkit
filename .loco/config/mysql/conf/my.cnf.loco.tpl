!include {{LOCO_SVC_VAR}}/conf/common-my.cnf

[client]
user		= root
#password	= your_password
port		= {{MYSQLD_PORT}}
socket		= {{LOCO_SVC_VAR}}/run/mysql.sock

[mysqld]
server-id	= {{MYSQLD_PORT}}
bind-address	= {{LOCALHOST}}
# bind-address	= *
port		= {{MYSQLD_PORT}}
socket		= {{LOCO_SVC_VAR}}/run/mysql.sock
pid_file        = {{LOCO_SVC_VAR}}/run/mysql.pid
tmpdir          = {{LOCO_SVC_VAR}}/tmp

# Uncomment the following if you are using InnoDB tables
#innodb_data_home_dir = /var/lib/mysql
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = /var/lib/mysql
