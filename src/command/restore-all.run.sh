pushd "$BLDDIR" >> /dev/null
  find . -mindepth 1 -maxdepth 1 -type d | while read dir ; do
    SITE_NAME=$(basename $dir)
    civibuild restore "$SITE_NAME"
  done
popd >> /dev/null
