## FIXME: Bluebird-CRM.git has outdated SQL templates. You can extract SQL
## template from staging/prod, but it's not clear if it's sufficiently
## anonymized, so I'm not committing it without discussion.
##
## To fix this:
## 1. Update the public "Bluebird-CRM.git" to have the current/reviewed templates.
## 2. Update "download.sh". Remove references to this hack. (See "FIXME"s)
## 3. Update "install.sh". Remove references to this hack. (See "FIXME"s)
## 4. Update "install.sh". Load the real SQL files. (See "FIXME"s)
## 5. Delete this file.

## For the moment, you have to download them manually before running civibuild.
## This file prints an error with instructions.

manual_sql_files=(senate_test_c_template.sql senate_test_d_template.sql senate_test_l_template.sql)
for SQL_FILE in "${manual_sql_files[@]}" ; do
  if [ ! -e "$SITE_CONFIG_DIR/sql/$SQL_FILE" ]; then
    echo >&2
    echo >&2 "FIXME: Bluebird-CRM.git does not have current SQL templates."
    echo >&2
    echo >&2 "Please manually create $SITE_CONFIG_DIR/sql/ with these files":
    for NEEDED in "${manual_sql_files[@]}" ; do
      echo >&2 " - $NEEDED"
    done
    echo >&2
    cvutil_fatal "FATAL: Bluebird requires manual override for SQL templates"
  fi
done
