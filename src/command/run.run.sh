if [ -z "$RUN_FILE" -a -z "$RUN_EVAL" ]; then
  echo "Missing option: '--eval CODE' or '--script FILENAME'"
  exit 89
elif [ -n "$RUN_EVAL" -a -n "$RUN_FILE" ]; then
  echo "Too many options. Use either '--eval CODE' or '--script FILENAME'"
  exit 89
elif [ -n "$RUN_EVAL" ]; then
  pushd "$WEB_ROOT/web" >> /dev/null
    eval "$RUN_EVAL"
  popd >> /dev/null
elif [ -n "$RUN_FILE" ]; then
  pushd "$WEB_ROOT/web" >> /dev/null
    source "$RUN_FILE"
  popd >> /dev/null
fi
