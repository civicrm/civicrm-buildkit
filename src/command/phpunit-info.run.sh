cvutil_assertvars civibuild_app_phpunit_advisor BLDDIR

####################################################
## Display helpers

function echo_h1() {
  echo "[32m===== $@ =====[0m"
  echo
}
function echo_h2() {
  echo "[32m$@[0m"
}
function echo_li_1() {
  echo "* [33m$@[0m"
}
function echo_li_2() {
  echo "   * [33m$@[0m"
}
function echo_li_3() {
  echo "      * $@"
}
function echo_li_4() {
  echo "         * $@"
}
function echo_cmd() {
  echo "  [32m\$[0m [33m$@[0m"
}
function echo_warn() {
  echo "> [33mWARNING[0m $@"
}

####################################################
## Reporting functions

function find_phpunits() {
  for n in phpunit{4,5,6,7,8,9} ; do
    if [ -f "$PRJDIR/extern/$n/$n.phar" ]; then
      echo "$n"
    fi
  done
}

function phpunit_info_overview() {
  echo "(EXPERIMENTAL) This report is an informational aide to help developers run PHPUnit"
  echo "with CiviCRM."
  echo
  echo "Here are a few tips for interpreting the report."
  echo
  echo " - This report is broken into separate sections for CLI usage and PHPStorm usage."
  echo " - Run PHPUnit on the command-line before using an IDE. This will help you"
  echo "   understand the framework better and ensure that the fundamentals are in place."
  echo " - This report has no visibility into virtualization or containerization."
  echo "   If you are trying to run PHPStorm and PHPUnit on separate hosts, then"
  echo "   you will need to sort out other details."
  echo
}

function phpunit_info_cli_core() {
  echo "If you haven't already, ensure that buildkit is in the PATH."
  echo
  echo_cmd "export PATH=\"$BINDIR:\$PATH\""
  echo
  echo "Navigate to the folder with the test suite"
  echo
  echo_cmd "cd $CIVI_CORE"
  echo
  echo "Next, pick a version of PHPUnit (eg $(echo $PHPUNITS)), and then"
  echo "run an example test (eg CRM_Core_RegionTest):"
  echo
  echo_cmd "env CIVICRM_UF=UnitTests phpunit5 tests/phpunit/CRM/Core/RegionTest.php"
  echo
  echo "Most tests require specifying \"env CIVICRM_UF=UnitTests\". Some do not."
  echo "If you get this wrong, that's OK - there will be an error message describing"
  echo "whether to change CIVICRM_UF."
  echo
}

function phpunit_info_cli_ext() {
  echo "If you haven't already, ensure that buildkit is in the PATH."
  echo
  echo_cmd "export PATH=\"$BINDIR:\$PATH\""
  echo
  echo "Navigate to the folder with the test suite:"
  echo
  echo_cmd "cd $PHPUNIT_TGT_EXT_DIR"
  echo
  echo "If you haven't already, ensure that the extension is activated:"
  echo
  echo_cmd "cv en $PHPUNIT_TGT_EXT"
  echo
  echo "Finally, pick a version of PHPUnit (eg $(echo $PHPUNITS)) and"
  echo "an example test (eg CRM_Myext_FooTest). Run it:"
  echo
  echo_cmd "phpunit5 tests/phpunit/CRM/Myext/FooTest.php"
  echo
}

function phpunit_info_storm_intro() {
  echo "There will be two general parts of configuring PHPStorm. First, we need to"
  echo "setup the *project* to identify the PHP and PHPUnit binaries. Second, we need"
  echo "to configure the *test-runner* to use a specific test-suite."
  echo
  echo "In new versions of PHPStorm, some options may be moved or renamed, but"
  echo "the same options do exist in all versions that I've seen. To find them, you"
  echo "may need to search the configuration screens and read critically."
  echo
}

function phpunit_info_storm_project_cfg() {
  echo_li_1 "Project Preferences"
  echo_li_2 "PHP: Register the interpreter:"
  echo_li_3 "$PHP"
  echo_li_2 "PHP: Register one of these include paths:"
  for PHPUNIT in $PHPUNITS ; do
    echo_li_3 "$PRJDIR/extern/$PHPUNIT"
  done
  echo_li_2 "Test Frameworks/PHPUnit: Use PHAR and pick one these:"
  for PHPUNIT in $PHPUNITS ; do
    echo_li_3 "$PRJDIR/extern/$PHPUNIT/$PHPUNIT.phar"
  done
  echo
}

function phpunit_info_storm_run_core() {
  echo_li_1 "Run: Edit Configuration: Defaults/Templates: PHPUnit:"
  echo_li_2 "Alternative configuration file:"
  echo_li_3 "$CIVI_CORE/phpunit.xml.dist"
  echo_li_2 "Custom working directory:"
  echo_li_3 "$CIVI_CORE"
  echo_li_2 "Environment variables:"
  echo_li_3 "CIVICRM_UF=UnitTests"
  echo_li_3 "PATH=$PATH"
  echo
}

function phpunit_info_storm_run_ext() {
  echo_li_1 "Run: Edit Configuration: Defaults/Templates: PHPUnit:"
  echo_li_2 "Alternative configuration file:"
  echo_li_3 "$PHPUNIT_TGT_EXT_DIR/phpunit.xml.dist"
  echo_li_2 "Custom working directory:"
  echo_li_3 "$PHPUNIT_TGT_EXT_DIR"
  echo_li_2 "Environment variables:"
  echo_li_3 "(Do NOT set CIVICRM_UF)"
  echo_li_3 "PATH=$PATH"
  echo
}

####################################################
## Main: Variable resolution

PHP=$(which php)
PHPUNITS=$(find_phpunits)

[ -z "$PHPUNIT_TGT_EXT" ] && PHPUNIT_TGT_NAME="civicrm-core" || PHPUNIT_TGT_NAME="$PHPUNIT_TGT_EXT"
if [ -n "$PHPUNIT_TGT_EXT" ]; then
  pushd "$CIVI_CORE" >> /dev/null
    PHPUNIT_TGT_EXT_DIR=$(cv path -x $PHPUNIT_TGT_EXT)
  popd >> /dev/null

  if [ -z "$PHPUNIT_TGT_EXT_DIR" -o ! -d "$PHPUNIT_TGT_EXT_DIR" ]; then
    echo "Error: Failed to locate extension $PHPUNIT_TGT_EXT"
    return
  fi
fi

####################################################
## Main: Output
echo_h1 Overview
phpunit_info_overview

echo_h1 "$PHPUNIT_TGT_NAME: Command Line Interface (CLI)"
[ -z "$PHPUNIT_TGT_EXT" ] && phpunit_info_cli_core || phpunit_info_cli_ext "$PHPUNIT_TGT_EXT"

echo_h1 "$PHPUNIT_TGT_NAME: PHPStorm Configuration"
phpunit_info_storm_intro
phpunit_info_storm_project_cfg
[ -z "$PHPUNIT_TGT_EXT" ] && phpunit_info_storm_run_core || phpunit_info_storm_run_ext "$PHPUNIT_TGT_EXT"

if [ -z "$PHPUNIT_TGT_EXT" ]; then
  echo_h1 "Testing an extension?"
  echo "The above instructions are for testing civicrm-core."
  echo "For an extension, specify the name of the extension, e.g."
  echo
  echo_cmd "civibuild phpunit-info $SITE_NAME --test-ext api4"
  echo
fi
