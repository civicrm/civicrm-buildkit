#!/bin/bash
set -e

if [ -e $HOME/.profile ]; then . $HOME/.profile; fi
[ -z `which await-bknix` ] || await-bknix "$USER" "dfl"
eval $(use-bknix "dfl")
if [ -z "$BKITBLD" ]; then echo "Invalid BKPROF"; exit 1; fi

## Job Name: CiviCRM-Core-PR
## Job Description: Monitor civicrm-core.git for proposed changes
##    For any proposed changes, run a few "smoke tests"
## Job GitHub Project URL: https://github.com/civicrm/civicrm-core
## Job Source Code Management: None
## Job Triggers: GitHub pull-requests
## Job xUnit Files: WORKSPACE/output/*.xml
## Useful vars: $ghprbTargetBranch, $ghprbPullId, $sha1
## Pre-requisite: Install bknix (install-ci.sh)
## Pre-requisite: Configure DNS and Apache vhost to support wildcards (e.g. *.test-ubu1204-5.civicrm.org)

#################################################
## Pre-requisite: We only test PR's for main-line branches.
case "$ghprbTargetBranch" in
  4.6*|4.7*|5.*|master*) echo "PR test is supported for $ghprbTargetBranch" ;;
  *)                     echo "PR test not supported for $ghprbTargetBranch" ; exit 1 ;;
esac

#################################################
## Inputs; if called manually, use some defaults
EXECUTOR_NUMBER=${EXECUTOR_NUMBER:-9}
WORKSPACE=${WORKSPACE:-/var/lib/jenkins/workspace/Foo/Bar}
GUARD=

## Build definition
## Note: Suffixes are unique within a period of 180 days.
BLDTYPE="drupal-clean"
BLDNAME="core-$ghprbPullId-$(php -r 'echo base_convert(time()%(180*24*60*60), 10, 36);')"
BLDDIR="$BKITBLD/$BLDNAME"
EXITCODES=""

export TIME_FUNC="linear:500"

#################################################
## Cleanup left-overs from previous test-runs
[ -d "$BLDDIR" ] && $GUARD civibuild destroy "$BLDNAME"

#################################################
## Report details about the test environment
civibuild env-info

## Download dependencies, apply patches, and perform fresh DB installation
$GUARD civibuild download "$BLDNAME" --type "$BLDTYPE" --civi-ver "$ghprbTargetBranch" \
  --patch "https://github.com/civicrm/civicrm-core/pull/${ghprbPullId}"

## No obvious problems blocking a build...
$GUARD civibuild install "$BLDNAME"
