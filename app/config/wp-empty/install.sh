#!/bin/bash

## install.sh -- Create config files and databases; fill the databases

## Transition: Old builds don't have "web/" folder. New builds do.
## TODO: Simplify sometime after Dec 2019
[ -d "$WEB_ROOT/web" ] && CMS_ROOT="$WEB_ROOT/web"

###############################################################################
## Create virtual-host and databases

amp_install

###############################################################################
## Setup WordPress (config files, database tables)

wp_install

###############################################################################
## Extra configuration

pushd "$CMS_ROOT" >> /dev/null

## Clear out default content. Load real content.
TZ=$(php --info |grep 'Default timezone' |sed s/' => '/:/ |cut -d':' -f2)
wp option set timezone_string $TZ
wp post delete 1
wp post delete 2
wp rewrite structure '/%postname%/'
wp rewrite flush --hard
wp theme install twentythirteen --activate

wp user create "$DEMO_USER" "$DEMO_EMAIL" --user_pass="$DEMO_PASS"

wp plugin install gutenberg
wp plugin install classic-editor --activate

popd >> /dev/null
