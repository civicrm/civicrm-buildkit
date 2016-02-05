#!/bin/bash

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
  local known=1
  case "$1" in
    d43)         SITE_TYPE=drupal-demo      ; CIVI_VERSION=4.3       ; CMS_TITLE="CiviCRM 4.3 Demo on Drupal"        ; DISC_VERSION=4.4	;;
    d44)         SITE_TYPE=drupal-demo      ; CIVI_VERSION=4.4       ; CMS_TITLE="CiviCRM 4.4 Demo on Drupal"        ; VOL_VERSION=4.4-1.x	; DISC_VERSION=4.4	;;
    d45)         SITE_TYPE=drupal-demo      ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviCRM 4.5 Demo on Drupal"        ; VOL_VERSION=v4.5-1.4.0	; DISC_VERSION=4.4	;;
    d46)         SITE_TYPE=drupal-demo      ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviCRM 4.6 Demo on Drupal"        ; VOL_VERSION=v4.5-1.4.0	; DISC_VERSION=master	; RULES_VERSION=master	;;
    d47)         SITE_TYPE=drupal-demo      ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Demo on Drupal"        ; VOL_VERSION=master	; DISC_VERSION=master	;;
    dmaster)     SITE_TYPE=drupal-demo      ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal"         ; VOL_VERSION=master	; DISC_VERSION=master	;;

    d7-43)       SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.3       ; CMS_TITLE="CiviCRM 4.3 Demo on Drupal 7"      ;;
    d7-44)       SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.4       ; CMS_TITLE="CiviCRM 4.4 Demo on Drupal 7"      ;;
    d7-45)       SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviCRM 4.5 Demo on Drupal 7"      ;;
    d7-46)       SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviCRM 4.6 Demo on Drupal 7"      ;;
    d7-47)       SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Demo on Drupal 7"      ;;
    d7-master)   SITE_TYPE=drupal-clean     ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 7"       ;;

#   d6-46)       SITE_TYPE=drupal6-demo     ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviCRM 4.6 Demo on Drupal 6"      ; VOL_VERSION=v4.5-1.4.0	; DISC_VERSION=master	; RULES_VERSION=master	;;
#   d6-47)       SITE_TYPE=drupal6-demo     ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Demo on Drupal 6"      ; VOL_VERSION=master	; DISC_VERSION=master	;;
#   d6-master)   SITE_TYPE=drupal6-demo     ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 6"       ; VOL_VERSION=master	; DISC_VERSION=master	;;
#   d8-47)       SITE_TYPE=drupal8-demo     ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Demo on Drupal 8"      ; VOL_VERSION=master	; DISC_VERSION=master	;;
    d8-master)   SITE_TYPE=drupal8-clean    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Drupal 8"       ;;

    dc43)        SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.3       ; CMS_TITLE="CiviCRM 4.3 Clean on Drupal"       ;;
    dc44)        SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.4       ; CMS_TITLE="CiviCRM 4.4 Clean on Drupal"       ;;
    dc45)        SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviCRM 4.5 Clean on Drupal"       ;;
    dc46)        SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviCRM 4.6 Clean on Drupal"       ;;
    dc47)        SITE_TYPE=drupal-clean     ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Clean on Drupal"       ;;
    dcmaster)    SITE_TYPE=drupal-clean     ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Clean Sandbox on Drupal"   ;;

    wp43)        SITE_TYPE=wp-demo          ; CIVI_VERSION=4.3       ; CMS_TITLE="CiviCRM 4.3 Demo on WordPress"     ;;
    wp44)        SITE_TYPE=wp-demo          ; CIVI_VERSION=4.4       ; CMS_TITLE="CiviCRM 4.4 Demo on WordPress"     ;;
    wp45)        SITE_TYPE=wp-demo          ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviCRM 4.5 Demo on WordPress"     ;;
    wp46)        SITE_TYPE=wp-demo          ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviCRM 4.6 Demo on WordPress"     ;;
    wp47)        SITE_TYPE=wp-demo          ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Demo on WordPress"     ;;
    wpmaster)    SITE_TYPE=wp-demo          ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ;;

    wp-43)       SITE_TYPE=wp-demo          ; CIVI_VERSION=4.3       ; CMS_TITLE="CiviCRM 4.3 Demo on WordPress"     ;;
    wp-44)       SITE_TYPE=wp-demo          ; CIVI_VERSION=4.4       ; CMS_TITLE="CiviCRM 4.4 Demo on WordPress"     ;;
    wp-45)       SITE_TYPE=wp-demo          ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviCRM 4.5 Demo on WordPress"     ;;
    wp-46)       SITE_TYPE=wp-demo          ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviCRM 4.6 Demo on WordPress"     ;;
    wp-47)       SITE_TYPE=wp-demo          ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Demo on WordPress"     ;;
    wp-master)   SITE_TYPE=wp-demo          ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on WordPress"      ;;

    bc47)        SITE_TYPE=backdrop-clean   ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 Clean on Backdrop"     ;;
    bcmaster)    SITE_TYPE=backdrop-clean   ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Clean Sandbox on Backdrop" ;;

    b47)         SITE_TYPE=backdrop-demo    ; CIVI_VERSION=4.7       ; CMS_TITLE="CiviCRM 4.7 on Backdrop"           ;;
    bmaster)     SITE_TYPE=backdrop-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Backdrop"       ;;
    b-master)    SITE_TYPE=backdrop-demo    ; CIVI_VERSION=master    ; CMS_TITLE="CiviCRM Sandbox on Backdrop"       ;;

    hr13)        SITE_TYPE=hrdemo           ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviHR 1.3 Demo"                   ; HR_VERSION=1.3        ;;
    hr14)        SITE_TYPE=hrdemo           ; CIVI_VERSION=4.5       ; CMS_TITLE="CiviHR 1.4 Demo"                   ; HR_VERSION=1.4        ;;
    hr15)        SITE_TYPE=hr15             ; CIVI_VERSION=4.6       ; CMS_TITLE="CiviHR 1.5 Demo"                   ; HR_VERSION=master     ;;
    hr16)	 SITE_TYPE=hr16		    ; CIVI_VERSION=4.7	     ; CMS_TITLE="CiviHR 1.6 Demo"		     ; HR_VERSION=PCHR-863-migrate-to-4.7     ;;
    hrmaster)    SITE_TYPE=hr15             ; CIVI_VERSION=master    ; CMS_TITLE="CiviHR Sandbox"                    ; HR_VERSION=master     ;;

    *) known=;;
  esac

  if [ -n "$known" ]; then
    CMS_URL="http://$1.dev"
  fi
}
