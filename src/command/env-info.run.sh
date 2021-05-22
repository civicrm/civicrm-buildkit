## "civibuild env-info": Display a report about the general tools/paths of the civibuild environment.
## Note that this is different from "civibuild show <build-name>" which reports on the values for a specific build.

## usage: env_report_cmd <cmd-name> <cmd-version-info-options>
function env_report_cmd() {
  local cmd="$1"
  shift
  local fullpath="$(which "$cmd")"
  if [ -z "$fullpath" ]; then
    printf '[32mCOMMAND[0m: [33m%s[0m [31mMISSING[0m\n' "$cmd"
  else
    printf '[32mCOMMAND[0m: [33m%s[0m ([33m%s[0m)\n' "$cmd" "$fullpath"
    $cmd "$@" 2>&1 | while read LINE ; do echo "> $LINE" ; done
  fi
  echo
}

## usage: env_report_var <var-name> <var-value>
function env_report_var() {
  printf '[32mVARIABLE[0m: [33m%s[0m=[33m%s[0m\n' "$1" "$2"
}

## usage: env_report_special <pseudo-var-name> <bash-lookup-expr>
function env_report_special() {
  printf '[32mSPECIAL[0m: [33m%s[0m: [33m%s[0m\n' "$1" "$2"
  eval "$2" 2>&1 | while read LINE ; do echo "> $LINE" ; done
  echo
}

echo '[32m==========================================[0m'
echo '[32m==========[[33m civibuild env-info [32m]==========[0m'
echo '[32m==========================================[0m'

env_report_cmd amp --version
env_report_cmd apachectl -V
env_report_cmd bash --version
env_report_cmd civistrings --version
env_report_cmd civix --version
env_report_cmd composer --version
env_report_cmd cv --version
env_report_cmd drush --version
env_report_cmd git --version
env_report_cmd git-scan --version
env_report_cmd memcached --version
env_report_cmd redis-cli --version
env_report_cmd mysql --version
env_report_cmd mysqld --version
env_report_cmd mysqldump --version
env_report_cmd node --version
env_report_cmd php --version
env_report_cmd php-fpm --version
env_report_cmd phpunit5 --version
env_report_cmd phpunit6 --version
env_report_cmd phpunit7 --version
env_report_cmd phpunit8 --version
env_report_cmd phpunit9 --version
env_report_cmd pogo --version
env_report_cmd wp --version

env_report_special MYSQLD_VERSION "echo 'select version()' | amp sql -a | tail -n1"
env_report_special AMP_CONFIG "amp config:get | grep '\(httpd_type\|hosts_type\|db_type\|perm_type\|ram_disk_type\|httpd_restart_command\)'"

env_report_var BINDIR "$BINDIR"
env_report_var PRJDIR "$PRJDIR"
env_report_var TMPDIR "$TMPDIR"
env_report_var BLDDIR "$BLDDIR"
env_report_var CIVIBUILD_HOME "$CIVIBUILD_HOME"
env_report_var CIVIBUILD_PATH "$CIVIBUILD_PATH"
env_report_var AMPHOME "$AMPHOME"
