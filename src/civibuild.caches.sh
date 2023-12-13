## Declare git repos that are commonly caches
##
## usage: git_cache_map CACHE_ID
## example: core_url=$( git_cache_map civicrm/civicrm-core )
function git_cache_map() {
  case "$1" in
    "backdrop/backdrop")                       echo "https://github.com/$1.git" ; ;;
    "civicrm/api4")                            echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-backdrop")                echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-core")                    echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-demo-wp")                 echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-drupal")                  echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-drupal-8")                echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-joomla")                  echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-packages")                echo "https://github.com/$1.git" ; ;;
    "civicrm/civicrm-wordpress")               echo "https://github.com/$1.git" ; ;;
    "civicrm/org.civicoop.civirules")          echo "https://lab.civicrm.org/extensions/civirules.git" ; ;;
    "civicrm/org.civicrm.civicase")            echo "https://github.com/$1.git" ; ;;
    "civicrm/org.civicrm.contactlayout")       echo "https://github.com/$1.git" ; ;;
    "civicrm/org.civicrm.module.cividiscount") echo "https://lab.civicrm.org/extensions/cividiscount.git" ; ;;
    "civicrm/org.civicrm.shoreditch")          echo "https://github.com/$1.git" ; ;;
    "civicrm/org.civicrm.styleguide")          echo "https://github.com/$1.git" ; ;;
    "TechToThePeople/civisualize")             echo "https://lab.civicrm.org/extensions/civisualize.git" ; ;;
    *)                                         cvutil_fatal "Unrecognized cache id: $1 (See also: civibuild.caches.sh)" ; ;;
  esac
}
