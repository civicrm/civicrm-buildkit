#!/nix/store/gqxzpx1x6c7hhjcvk2w44d1dd40nlhwk-bash-interactive-5.2-p15/bin/bash

cmd=("/nix/store/mp7qg7lg63fs5wh8wkm16dx8zn2wfxbb-mysql-8.0.29/bin/mysql")

if [[ $@ =~ "--defaults-file" ]]; then
  true
elif [ -n "$MYSQL_HOME" -a -e "$MYSQL_HOME/my.cnf" ]; then
  cmd+=("--defaults-file=$MYSQL_HOME/my.cnf")
fi

cmd+=("$@")

echo exec ${cmd[@]}
