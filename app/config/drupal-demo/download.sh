#!/bin/bash

[ -z "$CMS_VERSION" ] && CMS_VERSION=7.x
MAKEFILE="${TMPDIR}/${SITE_TYPE}.make"
cat "$SITE_CONFIG_DIR/drush.make.tmpl" \
  | sed "s;%%CIVI_REPO_BASE%%;${CIVI_REPO_BASE};" \
  | sed "s;%%CIVI_VERSION%%;${CIVI_VERSION};" \
  | sed "s;%%CMS_VERSION%%;${CMS_VERSION};" \
  > "$MAKEFILE"

drush -y make --working-copy "$MAKEFILE" "$WEB_ROOT"
