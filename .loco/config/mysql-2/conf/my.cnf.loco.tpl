!include {{LOCO_CFG}}/mysql-common/my.cnf

[client]
user		= root
#password	= your_password
port		= {{MYSQL2_PORT}}
socket		= {{LOCO_SVC_VAR}}/run/mysql.sock

[mysqld]
server-id	= {{MYSQL2_PORT}}
bind-address	= {{LOCALHOST}}
# bind-address	= *
port		= {{MYSQL2_PORT}}
socket		= {{LOCO_SVC_VAR}}/run/mysql.sock
pid_file        = {{LOCO_SVC_VAR}}/run/mysql.pid
tmpdir          = {{LOCO_SVC_VAR}}/tmp
log-bin		= {{LOCO_SVC_VAR}}/log/mysql-bin

read_only       = 1

# Replication Slave (comment out master section to use this)
#
# To configure this host as a replication slave, you can choose between
# two methods :
#
# 1) Use the CHANGE MASTER TO command (fully described in our manual) -
#    the syntax is:
#
#    CHANGE MASTER TO MASTER_HOST=<host>, MASTER_PORT=<port>,
#    MASTER_USER=<user>, MASTER_PASSWORD=<password> ;
#
#    where you replace <host>, <user>, <password> by quoted strings and
#    <port> by the master's port number (3306 by default).
#
#    Example:
#
#    CHANGE MASTER TO MASTER_HOST='125.564.12.1', MASTER_PORT=3306,
#    MASTER_USER='joe', MASTER_PASSWORD='secret';
#
# OR
#
# 2) Set the variables below. However, in case you choose this method, then
#    start replication for the first time (even unsuccessfully, for example
#    if you mistyped the password in master-password and the slave fails to
#    connect), the slave will create a master.info file, and any later
#    change in this file to the variables' values below will be ignored and
#    overridden by the content of the master.info file, unless you shutdown
#    the slave server, delete master.info and restart the slaver server.
#    For that reason, you may want to leave the lines below untouched
#    (commented) and instead use CHANGE MASTER TO (see above)
#
# The replication master for this slave - required
#master-host     =   <hostname>
#master-user     =   <username>
#master-password =   <password>
#master-port     =  <port>

# Uncomment the following if you are using InnoDB tables
#innodb_data_home_dir = /var/lib/mysql
#innodb_data_file_path = ibdata1:10M:autoextend
#innodb_log_group_home_dir = /var/lib/mysql

