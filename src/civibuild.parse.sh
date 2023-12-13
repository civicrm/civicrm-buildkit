#!/usr/bin/env bash

## Parse un-named params by position: <action> <sitename>[/<ms-id>]
function civibuild_parse_unnamed_params() {
  for OPTION in $@; do
    #skip named options
    [ "${OPTION::1}" == "-" ] && continue

    # if an option is "help" (not "--help") just show usage
    [ "$OPTION" == "help" ] && civibuild_app_usage

    # don't overwrite SITE_NAME if already set
    [ -n "$SITE_NAME" ] && continue

    if [ -z $ACTION ]; then
      cvutil_is_action $OPTION
      if [ $ACTION_VALIDATED -eq 1 ]; then
        ACTION=$OPTION
      fi
      continue
    fi

    if [ `echo "$ACTION" | egrep -c 'snapshots|restore-all|list|cache-warmup|env-info'` -eq 1 ]; then
      # dont parse site-name
      break
    fi

    civibuild_expand_site_name "$OPTION"
  done

  [ -z "$ACTION" ] && civibuild_app_usage

  if [ `echo "$ACTION" | egrep -c 'snapshots|restore-all|list|cache-warmup|env-info'` -eq 0 ]; then

    if [ -z "$SITE_NAME" ]; then
      civibuild_detect_site_name
      civibuild_expand_site_name "$SITE_NAME"
    fi

    [ -z "$SITE_NAME" ] && civibuild_app_usage
    [ -z "$SITE_ID" ] && civibuild_app_usage

    ## Load settings based in SITE_NAME / SITE_ID
    if [ -f "${BLDDIR}/${SITE_NAME}.sh" ]; then
      echo "[[Load saved options from ${BLDDIR}/${SITE_NAME}.sh]]"
      source "${BLDDIR}/${SITE_NAME}.sh"
      if [ "$SITE_ID" != "default" ]; then
        IS_INSTALLED=
      fi
    fi
    if [ -f "${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh" ]; then
      echo "[[Load saved options from ${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh]]"
      source "${BLDDIR}/${SITE_NAME}.${SITE_ID}.sh"
    fi
  fi
}

## If passed name is valid, assign to SITE_NAME
function civibuild_expand_site_name() {
  ## Convert "drupal-demo" or "drupal-demo/123" to vars SITE_NAME and optionally SITE_ID
  eval $(cvutil_parse_site_name_id "$1")

  if [ ! -z "$SITE_NAME" ]; then
    ## Convert certain aliases like "d45" into better defaults
    civibuild_alias_resolve "$SITE_NAME"
  fi
}

## Search build configs for CMS_ROOT and compare with pwd
function civibuild_detect_site_name() {
  local CWD=`pwd`

  ## Read all CMS_ROOT values
  if [ -z `compgen -G $BLDDIR/*.sh` ]; then
    return;
  fi
  local config_paths=`grep -H WEB_ROOT $BLDDIR/*.sh | sed s#WEB_ROOT=## | tr -d '"'`;

  local parents=()
  local children=()

  for site_path in ${config_paths[@]}; do
    local arr_site=(${site_path//:/ })

    local conf_file=${arr_site[0]}
    local cms_root=${arr_site[1]}

    if [[ "$cms_root" == $CWD* ]]; then
  #    echo "CWD is parent, in" $conf_file
      children=(${children[@]} $conf_file)
    fi

    if [[ "$CWD" == $cms_root* ]]; then
  #    echo "CWD is child, in " $conf_file
      parents=(${parents[@]} $conf_file)
    fi
  done

  local build_file=
  if [ "${#parents[@]}" -eq 1 ] && [ "${#children[@]}" -ne 1 ]; then
    build_file=$parents
  elif [ "${#children[@]}" -eq 1 ] && [ "${#parents[@]}" -ne 1 ]; then
    build_file=$children
  fi

  if [ -n "$build_file" ]; then
    SITE_NAME=`basename $build_file .sh`
    echo "[[Detected SITE_NAME: $SITE_NAME]]"
  fi
}

###############################################################################
## Parse options
declare -a ARGS=()
function civibuild_parse() {
  source "$PRJDIR/src/civibuild.defaults.sh"
  [ -f "$PRJDIR/app/civibuild.conf" ] && source "$PRJDIR/app/civibuild.conf"
  [ -f "/etc/civibuild.conf" ] && source "/etc/civibuild.conf"
  cvutil_mkdir "$TMPDIR" "$BLDDIR"
  [ -z "$CIVIBUILD_HOME" ] && cvutil_mkdir "$PRJDIR/app/private"

  civibuild_parse_unnamed_params $@

  while [ -n "$1" ] ; do
    OPTION="$1"
    shift

    case "$OPTION" in
      -h|--help|-\?)
        civibuild_app_usage
        ;;

      -v)
        VERBOSE=1
        ;;

      --admin-email)
        ADMIN_EMAIL="$1"
        shift
        ;;

      --admin-pass)
        ADMIN_PASS="$1"
        shift
        ;;

      --admin-user)
        ADMIN_USER="$1"
        shift
        ;;

      --civi-sql)
        CIVI_SQL="$1"
        shift
        ;;

      --civi-ver)
        CIVI_VERSION="$1"
        shift
        ;;

      --clone-id)
        CLONE_ID="$1"
        shift
        ;;

      --cms-sql)
        CMS_SQL="$1"
        shift
        ;;

      --cms-ver)
        CMS_VERSION="$1"
        shift
        ;;

      --demo-email)
        DEMO_EMAIL="$1"
        shift
        ;;

      --demo-pass)
        DEMO_PASS="$1"
        shift
        ;;

      --demo-user)
        DEMO_USER="$1"
        shift
        ;;

      --dl)
        EXTRA_DLS="$EXTRA_DLS|$1"
        shift
        ;;

      --ext)
        EXT_DLS="$EXT_DLS $1"
        shift
        ;;

      --force)
        FORCE_DOWNLOAD=1
        FORCE_INSTALL=1
        ;;

      --force-download)
        FORCE_DOWNLOAD=1
        ;;

      --force-install)
        FORCE_INSTALL=1
        ;;

      --full)
        SHOW_FULL_BUILD_CONF=1
        ;;

      --html)
        SHOW_HTML="$1"
        shift
        ;;

      --last-scan)
        SHOW_LAST_SCAN="$1"
        shift
        ;;

      --new-scan)
        SHOW_NEW_SCAN="$1"
        shift
        ;;

      --no-civi)
        CIVI_SQL_SKIP=1
        ;;

      --no-cms)
        CMS_SQL_SKIP=1
        ;;

      --no-test)
        TEST_SQL_SKIP=1
        ;;

      --patch)
        PATCHES="$PATCHES|$1"
        shift
        ;;

      --snapshot)
        SNAPSHOT_NAME="$1"
        shift
        ;;

      --title)
        CMS_TITLE="$1"
        shift
        ;;

      --type)
        SITE_TYPE="$1"
        shift
        ;;

      --test-ext)
        PHPUNIT_TGT_EXT="$1"
        ;;

      --url)
        CMS_URL="$1"
        shift
        ;;

      --url-template)
        URL_TEMPLATE="$1"
        shift
        ;;

      --web-root)
        WEB_ROOT="$1"
        shift
        ;;

      --no-sample-data)
        NO_SAMPLE_DATA="1"
        ;;

      --hr-ver)
        HR_VERSION="$1"
        shift
        ;;

      --eval)
        RUN_EVAL="$1"
        shift
        ;;

      --script)
        RUN_FILE="$1"
        shift
        ;;

      *)
        if [ "${OPTION::1}" == "-" ]; then
          echo "Unrecognized option: $OPTION"
          civibuild_app_usage
        else
          ARGS=("${ARGS[@]}" "$OPTION")
        fi
        ;;
    esac
  done

  source "$PRJDIR/src/civibuild.compute-defaults.sh"

  ## Note: Also declare new actions in src/civibuild.defaults.sh DECLARED_ACTIONS
  ## Translate action aliases
  case "$ACTION" in
    dl) ACTION=download ;;
    reinstall) ACTION=install ;;
    ut) ACTION=upgrade-test ;;
    *) ;;
  esac
}
