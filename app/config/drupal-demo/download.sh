#!/bin/bash

drush -y make --working-copy "$SITE_CONFIG_DIR/drush.make" "$WEB_ROOT"
