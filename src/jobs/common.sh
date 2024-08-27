#!/usr/bin/env bash
{ ## start common.sh

## Common utilities to include in jobs...

## usage: fatal <error-message>
function fatal() {
  echo "$@" 1>&2
  exit 2
}

## usage: assert_regex <grep-style-regex> <value> [<error-message>]
function assert_regex() {
  local regex="$1"
  local value="$2"
  local error="$3"
  if ! echo "$value" | grep -q "$regex" > /dev/null ; then
    if [ -z "$error" ]; then
      fatal "Error: Value ($value) does not match regex ($regex)"
    else
      fatal "$error"
    fi
  fi
}

## usage: assert_hublab_url <value> [<error-message>]
function assert_hublab_url() {
  assert_regex '^https://\(github.com\|lab.civicrm.org\)/[a-zA-Z0-9/+?%\._-]\+$' "$@"
}

## Assert that a list of common variables are well defined.
##
## usage: assert_common <var1 var2 var3...>
## example: assert_common CIVIVER BLDTYPE
function assert_common() {
  for VAR in "$@" ; do
    case "$VAR" in
      ghprbPullId)
        assert_regex '^[0-9]\+$' "$ghprbPullId" "ghprbPullId must be a number."
        ;;
      ghprbTargetBranch)
        assert_regex '^[0-9a-z][0-9a-z\.-]*$' "$ghprbTargetBranch" "ghprbTargetBranch should be a branch name."
        ;;
      CIVI_REPO)
        assert_regex '^civicrm-\(backdrop\|core\|drupal\|drupal-8\|packages\|wordpress\)$' "$CIVI_REPO"
        ;;
      BKITBLD)
        if [ -z "$BKITBLD" ]; then
          fatal "Failed to find BKITBLD for $BKPROF"
        fi
        ;;
      BKPROF)
        if [[ "$BKPROF" =~ ^php[0-9]{2}([mr][0-9]+)?$ ]]; then
          true
        else
          case "$BKPROF" in
            old|min|dfl|max|alt|edge) true ; ;;
            *) fatal "Missing or invalid BKPROF" ; ;;
          esac
        fi
        ;;
      BUILD_NUMBER)
        assert_regex '^[0-9]\+$' "$BUILD_NUMBER" "Missing or invalid BUILD_NUMBER"
        ;;
      BLDTYPE)
        assert_regex '^[0-9a-z][0-9a-z\.-]*$' "$BLDTYPE" "Missing or invalid BLDTYPE"
        ;;
      BLDNAME)
        assert_regex '^[0-9a-z][0-9a-z\.-]*$' "$BLDTYPE" "Missing or invalid BLDTYPE"
        ;;
      BKIT)
        if [ ! -e "$BKIT/bin/civi-download-tools" ]; then
          echo "BKIT must be a valid buildkit folder. (Missing flag-file bin/civi-download-tools.)"
        fi
        ;;
      CIVIVER)
        assert_regex '^[0-9a-z][0-9a-z\.-]*$' "$CIVIVER" "Missing or invalid CIVIVER"
        ;;
      EXECUTOR_NUMBER)
        assert_regex '^[0-9]\+$' "$EXECUTOR_NUMBER" "EXECUTOR_NUMBER must be a number. (If you are running manually, consider using --mock.)"
        ;;
      JOB_NAME)
        if [ -z "$JOB_NAME" ]; then fatal "Missing JOB_NAME" ; fi
        ;;
      LOCO_PRJ)
        if [ ! -e "$LOCO_PRJ/.loco" ]; then
          fatal "LOCO_PRJ must be a valid project"
        fi
        ;;
      PATCH)
        assert_regex '^https://github.com/civicrm/civicrm-[a-z0-9-]*/pull/[0-9]\+/*' "$PATCH" "Invalid or missing PATCH"
        ;;
      PHPUNIT)
        assert_regex '^phpunit[0-9]*$' "$PHPUNIT" "PHPUNIT ($PHPUNIT) should identify a general version (such as phpunit8 or phpunit9)"
        ;;
      SUITE)
        assert_regex '^[a-zA-Z][0-9a-zA-Z-]*\( [a-zA-Z][0-9a-zA-Z-]*\)*$' "$SUITE" "Missing or invalid SUITE"
        ;;
      SUITES)
        assert_regex '^[a-zA-Z][0-9a-zA-Z-]*\( [a-zA-Z][0-9a-zA-Z-]*\)*$' "$SUITES" "Missing or invalid SUITES"
        ;;
      TIME_FUNC)
        assert_regex '^[ 0-9a-z:\.-]\+$' "$TIME_FUNC" "Missing or invalid TIME_FUNC"
        ;;
      WORKSPACE)
        if [ -z "$WORKSPACE" -o ! -d "$WORKSPACE" ]; then
          fatal "WORKSPACE must be a valid path. (If you are running manually, consider using --mock.)"
        fi
        ;;
      WORKSPACE_HTML)
        if [ -z "$WORKSPACE_HTML" -o ! -d "$WORKSPACE_HTML" ]; then
          fatal "WORKSPACE_HTML must be a valid path. (If you are running manually, consider using --mock.)"
        fi
        ;;
      WORKSPACE_CHECKSTYLE)
        if [ -z "$WORKSPACE_CHECKSTYLE" -o ! -d "$WORKSPACE_CHECKSTYLE" ]; then
          fatal "WORKSPACE_CHECKSTYLE must be a valid path. (If you are running manually, consider using --mock.)"
        fi
        ;;
      *)
        fatal "Cannot validate unrecognized variable $VAR"
        ;;
    esac
  done
}

## Determine which version of Smarty to test.
## If SMARTY3_ENABLE is already set, use it. Otherwise, choose a value of SMARTY3_ENABLE.
function assign_smarty() {
  if [[ "x$SMARTY3_ENABLE" = "x" && "$CIVIVER" = "master" ]]; then
    SMARTY3_ENABLE=true
  fi
  export SMARTY3_ENABLE
}

function assert_bknix_durable() {
  case "$USER" in
    homer|runner-*)
      echo >&2 "WARNING: This job is expected to run in a persistent environment. The user is \"$USER\" which suggests it is temporary."
      ;;
  esac

}

function assert_bknix_temporary() {
  case "$USER" in
    homer|runner-*)
      true
      ;;
    *)
      echo >&2 "WARNING: This job is expected to run in a temporary environment. The user is \"$USER\" which suggests it is persistent."
      ;;
  esac
}

## Setup a mock Jenkins environment
function init_jenkins_mock() {
  echo "Using mock Jenkins environment"
  export EXECUTOR_NUMBER=0
  export BUILD_NUMBER=123
  export WORKSPACE="$HOME/tmp/mock-workspace"
  if [ ! -d "$WORKSPACE" ]; then
    mkdir -p "$WORKSPACE"
  fi
  cd "$WORKSPACE"
}

## Setup the standard build folders within the workspace.
## Output variables: WORKSPACE_BUILD WORKSPACE_HTML WORKSPACE_JUNIT WORKSPACE_LOG WORKSPACE_DIST
function init_std_workspace() {
  WORKSPACE_BUILD="$WORKSPACE/build"
  WORKSPACE_HTML="$WORKSPACE_BUILD/html"
  WORKSPACE_JUNIT="$WORKSPACE_BUILD/junit"
  WORKSPACE_LOG="$WORKSPACE_BUILD/log"
  WORKSPACE_DIST="$WORKSPACE_BUILD/dist"
  WORKSPACE_CHECKSTYLE="$WORKSPACE_BUILD/checkstyle"

  ## WORKSPACE and all the other Jenkins vars are exported. We might as well export these...
  export WORKSPACE_BUILD WORKSPACE_HTML WORKSPACE_JUNIT WORKSPACE_LOG WORKSPACE_DIST WORKSPACE_CHECKSTYLE

  if [ ! -d "$WORKSPACE_BUILD" ]; then
    mkdir "$WORKSPACE_BUILD"
  fi

  for dir in "$WORKSPACE_JUNIT" "$WORKSPACE_HTML" "$WORKSPACE_LOG" "$WORKSPACE_DIST" "$WORKSPACE_CHECKSTYLE" ; do
    ## This is probably a nullop now that `run-bknix-job` has a generic/pre-flight cleanup for $WORKSPACE/build.
    if [ -d "$dir" ]; then
      rm -rf "$dir"
    fi
    mkdir "$dir"
  done
}

## Remove old files
## This basically just 'rm -rf', but (semantically) it indicates an entry from the workspace that should no longer be in use.
function clean_legacy_workspace() {
  for FILE in "$@" ; do
    if [ -e "$FILE" ]; then
      rm -rf "$FILE"
    fi
  done
}

## Thin wrapper for calling PHPUnit. Makes it easier to swap between versions. Adaptations:
##
## - Determine preferred version from env var $PHPUNIT.
## - If "--tap" is used on newer versions, then swap for a similar --printer.
function xphpunit() {
  assert_common PHPUNIT
  local args=()

  ## Scan "$@" for non-portable options. Translate them.
  while [ $# -gt 0 ]; do
    arg="$1"
    shift
    case "$arg" in
     --tap)
       case "$PHPUNIT" in
         phpunit7|phpunit8) args+=("--printer=Civi\Test\TAP") ; ;;
         phpunit9) args+=("--debug") ; ;; ## FIXME Real TAP is better
         *) args+=("$arg") ; ;;
       esac
       ;;

     *)
       args+=("$arg")
       ;;
    esac
  done

  $PHPUNIT "${args[@]}"
}

## Thin wrapper for calling civilint.
## usage: xcivilint BASE_BRANCH DESCRPTION
## example: xcivilint "origin/$ghprbTargetBranch" "PR ${ghprbPullId}"
function xcivilint() {
  local baseBranch="$1"
  local description="$2"
  assert_common WORKSPACE_HTML WORKSPACE_CHECKSTYLE

  ## Create text+html renderings
  echo "---- Full Report ----"
  set +e
    git diff --name-only "$baseBranch.." | civilint - | tee "$WORKSPACE_HTML/civilint.txt"
  set -e
  (
    echo "<html>"
    echo "<h1>civilint: ${description}</h1>"
    php -r 'echo "<p>Executed circa " . htmlentities(date("Y-m-d H:i P")) . "</p>\n";'
    echo "<pre>"
    php -r 'echo htmlentities(file_get_contents($argv[1]));' "$WORKSPACE_HTML/civilint.txt"
    echo "</pre></html>"
  ) > "$WORKSPACE_HTML/civilint.html"

  ## Create CheckStyle XML rendering
  if git diff --name-only "$baseBranch.." | civilint --checkstyle "$WORKSPACE_CHECKSTYLE" - ; then
    echo "Style passed"
  else
    echo "Style error"
    exit 1
  fi
}

## Given that we are testing a specific repo+branch, figure out the CIVIVER.
##
## usage: detect_civiver REPO BASE_BRANCH
## example: detect_civiver civicrm-backrop 1.x-5.0
function detect_civiver() {
  local repo="$1"
  local baseBranch="$2"
  local prefix=

  case "$repo" in
    civicrm-backdrop) prefix=1.x- ; ;;
    civicrm-drupal) prefix=7.x- ; ;;
    civicrm-core|civicrm-drupal-8|civicrm-joomla|civicrm-packages|civicrm-wordpress) prefix= ; ;;
    *)
      echo >&2 "Unrecognized repo name: $repo"
      exit 1 ## Structural error in scripts
      ;;
  esac

  if [ -z "$prefix" ]; then
    CIVIVER="$baseBranch"
  else
    case "$baseBranch" in
      ${prefix}4.6*|${prefix}4.7*|${prefix}5*|${prefix}master*)
        CIVIVER=$(echo "$baseBranch" | sed 's;^'"$prefix"';;')
        ;;
      *)
        ## This actually true for many branches, so we exit softly...
        echo >&2 "PR test not allowed for $baseBranch"
        exit 0 ## Misguided request by PR-author
        ;;
    esac
  fi
}

## usage: assert_testable_version CIVIVER
## example: assert_testable_version master
## example: assert_testable_version 4.6
function assert_testable_version() {
  local version="$1"

  if [ -z "$1" ]; then
    fatal "assert_testable_version: The version number is blank!"
  fi

  case "$version" in
    5.*|master*)           echo "PR test is supported for $version" ;;
    *)                     fatal "PR test not supported for $version" ;;
  esac

}

## Print all environment variables - with shell escaping.
function escape_variables() {
  while IFS= read -r -d $'\0' line; do
    var="${line%%=*}"
    val="${line#*=}"
    printf "export $var=%q\n" "$val"
  done < <(printenv -0)
}

## usage: myfile=$(new_tmp_file)
function new_tmp_file() {
  local tmpdir=${TMPDIR:-/tmp}
  local tmpfile="$tmpdir/runjob-tmp-$RANDOM$RANDOM"
  touch "$tmpfile"
  chmod 600 "$tmpfile"
  echo "$tmpfile"
}

## Generate bash script to run a command with current environment.
## example: create_job_script ls -l / > file_list_script.sh
function create_job_script() {
  echo "#!/usr/bin/env bash"
  echo "{"
  escape_variables
  echo
  for part in "$@" ; do printf " %q" "$part" ; done
  echo
  echo 'exit $?'
  echo "}"
}

} ## end common.sh
