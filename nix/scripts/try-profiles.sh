#!/usr/bin/env ebash

#for PHP in php73 php84 ; do
#  for DB in m57 ; do
for PHP in php73 php74 php80 php81 php82 php83 php84 ; do
  for DB in m57 m84 m90 r106 ; do
    BKPROF="${PHP}${DB}"
    echo -n "$BKPROF: "
    nix-shell -A "$BKPROF" --run 'echo $( php --version | head -n1 ) $(mysql --version | head -n1)'
  done
done
