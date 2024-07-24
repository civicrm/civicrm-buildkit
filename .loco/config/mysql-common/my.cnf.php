<?php
function ver() {
  static $ver = NULL;
  if ($ver === NULL) {
    $ver = getenv('FORCE_MY_CNF_VERSION') ?: `mysqld --no-defaults --version`;
  }
  return $ver;
}
function matchVer($pat) {return (bool) preg_match($pat, ver());}
?>
[mysqld]
skip-external-locking
key_buffer_size = 256M
max_allowed_packet = 16M
table_open_cache = 256
sort_buffer_size = 1M
read_buffer_size = 1M
read_rnd_buffer_size = 4M
myisam_sort_buffer_size = 64M
thread_cache_size = 8
<?php if (!matchVer('/Ver 8.\d/')) { printf("query_cache_size= 16M\n"); } ?>
<?php if (matchVer('/Ver 8.\d/')) { printf("default_authentication_plugin = mysql_native_password\n"); } ?>
# Try number of CPU's*2 for thread_concurrency
#MariaDB?# thread_concurrency = 8

binlog_format	= row
sync_binlog	= 1
<?php if (matchVer('/Ver 8.\d/')) { printf("skip-log-bin\n"); } ?>

innodb_file_per_table = 1
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
#innodb_buffer_pool_size = 256M
# Set .._log_file_size to 25 % of buffer pool size
#innodb_log_file_size = 64M
#innodb_log_buffer_size = 8M
#innodb_flush_log_at_trx_commit = 1
#innodb_lock_wait_timeout = 50

<?php if (matchVer('/Ver 5.6/')) { printf("innodb_large_prefix = 1\n"); } ?>
<?php if (matchVer('/Ver 5.6/')) { printf("sql_mode=\"STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION\"\n"); } ?>
<?php if (!matchVer('/Ver 8.\d/')) { printf("innodb_file_format = Barracuda\n"); } ?>

<?php if (matchVer('/Ver 5.7/')) { ?>
# https://expressionengine.com/blog/mysql-5.7-server-os-x-has-gone-away
interactive_timeout = 1200
wait_timeout = 1200
<?php } ?>

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
#no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[myisamchk]
key_buffer_size = 128M
sort_buffer_size = 128M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
