#!/usr/bin/env bash
set -e

## When using nix-shell+loco, you are usually making a new/separate instance
## of MySQL. In this environment, we want to ignore ~/.my.cnf (because it
## is external to the environment). Instead, we'll change the precedence
## to respect $MYSQL_HOME.

SRC="$1"
DEST="$2"
BASH=`which bash`

function generate_with_cnf() {
  echo "#!""$BASH"
  printf "cmd=(%q)\n" "$1"
  echo
  echo '## Force usage of our my.cnf, unless our caller forces its own my.cnf.'
  echo 'if [[ $@ =~ "--defaults-file" ]]; then'
  echo '  true'
  echo 'elif [[ $@ =~ "--no-defaults" ]]; then'
  echo '  true'
  echo 'elif [ -n "$MYSQL_HOME" -a -e "$MYSQL_HOME/my.cnf" ]; then'
  echo '  cmd+=("--defaults-file=$MYSQL_HOME/my.cnf")'
  echo 'fi'
  echo
  echo 'cmd+=("$@")'
  echo
  # echo 'echo "RUN: ${cmd[@]}"'
  printf 'exec ${cmd[@]}'"\n"
  echo "#@ respect --defaults-file"
}

function generate_basic() {
  echo "#!""$BASH"
  printf "cmd=(%q)\n" "$1"
  echo 'cmd+=("$@")'
  # echo 'echo "RUN: ${cmd[@]}"'
  printf 'exec ${cmd[@]}'"\n"
}

if [ -z "$SRC" -o -z "$DEST" ]; then
  echo "usage: $0 <SRC_BIN_DIR> <DEST_BIN_DIR>"
  exit 1
fi

if [ ! -e "$DEST" ]; then
  mkdir -p "$DEST"
fi

find "$SRC" -type f -maxdepth 1 | while read SRC_FILE ; do
  NAME=$(basename "$SRC_FILE")
  DEST_FILE="$DEST/$NAME"

  # echo "Wrap ($SRC_FILE) => ($DEST_FILE)"
  case "$NAME" in
    mysql|mysqladmin|mysqldumpslow|mysqlshow)
      generate_with_cnf "$SRC_FILE" > "$DEST_FILE"
      ;;
    *)
      generate_basic "$SRC_FILE" > "$DEST_FILE"
      ;;
  esac
  chmod +x "$DEST_FILE"
done
