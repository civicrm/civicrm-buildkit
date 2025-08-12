#!/usr/bin/env bash

## Several build-types -- drupal-demo, wp-demo, etc -- are designed for use
## in different combinations.  It's useful to be able to create arbitrary
## combinations, but there are a few typical combinations which are
## frequently used.
##
## A build-type-alias provides a short-hand way to refer to a set of
## civibuild options.
##
## The *.demo.civicrm.org domains correspond directly to these aliases;
## e.g. "d45.demo.civicrm.org" is based on "d45" (i.e. type=drupal_demo,
## civi-ver=4.5, and title="CiviCRM 4.5 Demo on Drupal").
##
## In the future, it may be desirable to replace this with some kind
## of build-type-inheritance (e.g. the "d44" build-type inherits from
## the "drupal-demo" build-type).

## Load any default options which apply to a build-type-alias.
##
## usage: civibuild_alias_resolve <name>
## example: civibuild_alias_resolve d45
function civibuild_alias_resolve() {
  IS_ALIAS=1
  case "$1" in
    d7)          SITE_TYPE=drupal7-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 7"      ;;
    d8)          SITE_TYPE=drupal8-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 8"      ;;
    d9)          SITE_TYPE=drupal9-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 9"      ;;
    d10)         SITE_TYPE=drupal10-demo   ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 10"      ;;
    d11)         SITE_TYPE=drupal11-demo   ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 11"      ;;

    dmaster)     SITE_TYPE=drupal-demo     ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal"         ; VOL_VERSION=master       ; DISC_VERSION=master   ;;
    d7-master)   SITE_TYPE=drupal-clean    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 7"       ;;
    d8-master)   SITE_TYPE=drupal8-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 8"       ;;
    d9-master)   SITE_TYPE=drupal9-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 9"       ;;
    d10-master)  SITE_TYPE=drupal10-demo   ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 10"      ;;
    d11-master)  SITE_TYPE=drupal11-demo   ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 11"      ;;

    d7-rc)       SITE_TYPE=drupal7-demo    ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Sandbox on Drupal 7 (RC)"  ;;
    d8-rc)       SITE_TYPE=drupal8-demo    ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Sandbox on Drupal 8 (RC)"  ;;
    d9-rc)       SITE_TYPE=drupal9-demo    ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Sandbox on Drupal 9 (RC)"  ;;
    d10-rc)      SITE_TYPE=drupal10-demo   ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Sandbox on Drupal 10 (RC)" ;;
    d11-rc)      SITE_TYPE=drupal11-demo   ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Sandbox on Drupal 11 (RC)" ;;

    d7-stable)   SITE_TYPE=drupal7-demo    ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Sandbox on Drupal 7 (Stable)"  ;;
    d8-stable)   SITE_TYPE=drupal8-demo    ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Sandbox on Drupal 8 (Stable)"  ;;
    d9-stable)   SITE_TYPE=drupal9-demo    ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Sandbox on Drupal 9 (Stable)"  ;;
    d10-stable)  SITE_TYPE=drupal10-demo   ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Sandbox on Drupal 10 (Stable)" ;;
    d11-stable)  SITE_TYPE=drupal11-demo   ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Sandbox on Drupal 11 (Stable)" ;;

    d7-esr)      SITE_TYPE=drupal7-demo    ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Sandbox on Drupal 7 (ESR)"     ;;
    d8-esr)      SITE_TYPE=drupal8-demo    ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Sandbox on Drupal 8 (ESR)"     ;;
    d9-esr)      SITE_TYPE=drupal9-demo    ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Sandbox on Drupal 9 (ESR)"     ;;
    d10-esr)     SITE_TYPE=drupal10-demo   ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Sandbox on Drupal 10 (ESR)"     ;;
    d11-esr)     SITE_TYPE=drupal11-demo   ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Sandbox on Drupal 11 (ESR)"     ;;

    dcmaster)    SITE_TYPE=drupal-clean     ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Clean Sandbox on Drupal"   ;;
    dcase)       SITE_TYPE=drupal-case      ; CIVI_VERSION=master    ; CMS_TITLE="CiviCase Sandbox on Drupal"        ;;

    wpcase)      SITE_TYPE=wp-case          ; CIVI_VERSION=master    ; CMS_TITLE="CiviCase Sandbox on WordPress"     ;;
    wp)          SITE_TYPE=wp-demo          ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ; VOL_VERSION=master     ;;
    wpmaster)    SITE_TYPE=wp-demo          ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ; VOL_VERSION=master     ;;
    wp-master)   SITE_TYPE=wp-demo          ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ; VOL_VERSION=master     ;;
    wp-rc)       SITE_TYPE=wp-demo          ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ;;
    wp-stable)   SITE_TYPE=wp-demo          ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ;;
    wp-esr)      SITE_TYPE=wp-demo          ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ;;

    bcmaster)    SITE_TYPE=backdrop-clean   ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Clean Sandbox on Backdrop" ;;
    bmaster)     SITE_TYPE=backdrop-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Backdrop"       ;;
    b-master)    SITE_TYPE=backdrop-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Backdrop"       ;;

    smaster)     SITE_TYPE=standalone-demo  ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Standalone Sandbox"        ;;
    # sdmaster)    SITE_TYPE=standalone-dev ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Standalone Sandbox"      ;;
    scmaster)    SITE_TYPE=standalone-composer ; CIVI_VERSION=master ; CMS_TITLE="CiviCRM Standalone Sandbox (Composer)"        ;;
    master)      SITE_TYPE=standalone-demo  ; CIVI_VERSION=master   ; CMS_TITLE="CiviCRM Standalone Sandbox"        ;;

    stable)     SITE_TYPE=standalone-demo   ; CIVI_VERSION=stable    ; CMS_TITLE="CiviCRM Standalone Sandbox (Stable)" ;;
    rc)         SITE_TYPE=standalone-demo   ; CIVI_VERSION=rc        ; CMS_TITLE="CiviCRM Standalone Sandbox (RC)" ;;
    esr)        SITE_TYPE=standalone-demo   ; CIVI_VERSION=esr       ; CMS_TITLE="CiviCRM Standalone Sandbox (ESR)" ;;
    dev)        SITE_TYPE=standalone-demo   ; CIVI_VERSION=dev       ; CMS_TITLE="CiviCRM Standalone Sandbox (Dev)" ;;

    civihr)      SITE_TYPE=civihr           ; CIVI_VERSION=5.3.1     ; CMS_TITLE="CiviHR Sandbox"                    ; NO_SAMPLE_DATA=1       ;;

    bempty)      SITE_TYPE=backdrop-empty   ; CIVI_VERSION=none      ; CMS_TITLE="Backdrop Sandbox"                  ;;
    dempty)      SITE_TYPE=drupal-empty     ; CIVI_VERSION=none      ; CMS_TITLE="Drupal 7 Sandbox"                  ;;
    d7-empty)    SITE_TYPE=drupal-empty     ; CIVI_VERSION=none      ; CMS_TITLE="Drupal 7 Sandbox"                  ;;
    d8-empty)    SITE_TYPE=drupal8-empty    ; CIVI_VERSION=none      ; CMS_TITLE="Drupal 8 Sandbox"                  ;;
    jempty)      SITE_TYPE=joomla-empty     ; CIVI_VERSION=none      ; CMS_TITLE="Joomla Sandbox"                    ;;
    wpempty)     SITE_TYPE=wp-empty         ; CIVI_VERSION=none      ; CMS_TITLE="WordPress Sandbox"                 ;;
    wp-empty)    SITE_TYPE=wp-empty         ; CIVI_VERSION=none      ; CMS_TITLE="WordPress Sandbox"                 ;;

    ## For testing purposes
    testalias-anujrdw)  SITE_TYPE=empty         ; CIVI_VERION=4.6 ;;

    *) IS_ALIAS= ;;
  esac

#  if [ -n "$known" -a "%AUTO%" = "$URL_TEMPLATE" ]; then
#    URL_TEMPLATE='http://%SITE_NAME%.local.civi.bid'
#  fi
}
