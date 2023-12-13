## Declare git repos that are commonly caches
##
## usage: git_cache_map CACHE_ID
## example: core_url=$( git_cache_map civicrm/civicrm-core )
function git_cache_map() {
  case "$1" in
    "civicrm/civicrm-backdrop")                echo "https://github.com/civicrm/civicrm-backdrop.git" ; ;;
    "civicrm/civicrm-core")                    echo "https://github.com/civicrm/civicrm-core.git" ; ;;
    "civicrm/civicrm-drupal")                  echo "https://github.com/civicrm/civicrm-drupal.git" ; ;;
    "civicrm/civicrm-drupal-8")                echo "https://github.com/civicrm/civicrm-drupal-8.git" ; ;;
    "civicrm/civicrm-packages")                echo "https://github.com/civicrm/civicrm-packages.git" ; ;;
    "civicrm/civicrm-joomla")                  echo "https://github.com/civicrm/civicrm-joomla.git" ; ;;
    "civicrm/civicrm-wordpress")               echo "https://github.com/civicrm/civicrm-wordpress.git" ; ;;
    "civicrm/civicrm-demo-wp")                 echo "https://github.com/civicrm/civicrm-demo-wp.git" ; ;;
    "civicrm/api4")                            echo "https://github.com/civicrm/api4.git" ; ;;
    "civicrm/org.civicoop.civirules")          echo "https://lab.civicrm.org/extensions/civirules.git" ; ;;
    "TechToThePeople/civisualize")             echo "https://lab.civicrm.org/extensions/civisualize.git" ; ;;
    "civicrm/org.civicrm.module.cividiscount") echo "https://lab.civicrm.org/extensions/cividiscount.git" ; ;;
    "civicrm/org.civicrm.contactlayout")       echo "https://github.com/civicrm/org.civicrm.contactlayout.git" ; ;;
    "backdrop/backdrop")                       echo "https://github.com/backdrop/backdrop.git" ; ;;
    *)                                         cvutil_fatal "Unrecognized cache id: $1 (See also: civibuild.caches.sh)" ; ;;
  esac
}
