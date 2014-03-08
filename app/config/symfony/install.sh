#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup Drupal (config files, database tables)

drupal_install

###############################################################################
## Setup CiviCRM (config files, database tables)

CIVI_DOMAIN_NAME="Demonstrators Anonymous"
CIVI_DOMAIN_EMAIL="\"Demonstrators Anonymous\" <info@example.org>"
CIVI_CORE="${WEB_ROOT}/sites/all/modules/civicrm"
CIVI_SETTINGS="${WEB_ROOT}/sites/default/civicrm.settings.php"
CIVI_FILES="${WEB_ROOT}/sites/default/files/civicrm"
CIVI_TEMPLATEC="${CIVI_FILES}/templates_c"
CIVI_UF="Drupal"

civicrm_install

###############################################################################
## Extra configuration

drush -y updatedb
drush -y dis overlay shortcut color
drush -y en civicrm toolbar civicrmtheme
#drush -y vset theme_default seven
#drush -y vset civicrmtheme_theme_admin seven
#drush -y vset site_frontpage "civicrm/dashboard"

drush -y en civicrm_webtest
drush -y user-create --password="$DEMO_PASS" --mail="$DEMO_EMAIL" "$DEMO_USER"
drush -y user-add-role civicrm_webtest_user "$DEMO_USER"

###############################################################################
## Setup civicrm-symfony

cat > "${WEB_ROOT}/symfony/app/config/parameters.yml" <<EOF
parameters:
    database_driver:   pdo_mysql
    database_host:     ${CIVI_DB_HOST}
    database_port:     ${CIVI_DB_PORT}
    database_name:     ${CIVI_DB_NAME}
    database_user:     ${CIVI_DB_USER}
    database_password: ${CIVI_DB_PASS}

    mailer_transport:  smtp
    mailer_host:       localhost
    mailer_user:       ~
    mailer_password:   ~

    locale:            en
    secret:            $(cvutil_makepasswd 16)

    civicrm_settings_path: ${CIVI_SETTINGS}
EOF

pushd "$WEB_ROOT/symfony" >> /dev/null
  ## Need to trigger scripts now that we have parameters.yml
  composer install
popd >> /dev/null

echo "define('CIVICRM_SYMFONY_PATH', '${WEB_ROOT}/symfony');" >> "$CIVI_SETTINGS"
