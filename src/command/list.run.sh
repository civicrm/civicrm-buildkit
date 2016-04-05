cvutil_assertvars civibuild_app_list BLDDIR

for b in `find $BLDDIR -maxdepth 1 -type f`; do
  basename $b | sed 's/\.sh//'
done
