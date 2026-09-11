#!/usr/bin/env php
<?php
function createRandom($len, $alphabet) {
  $alphabetSize = strlen($alphabet);
  $result = '';
  for ($i = 0; $i < $len; $i++) {
    $result .= $alphabet[random_int(1, $alphabetSize) - 1];
  }
  return $result;
}

if (empty($argv[1])) {
  $len = 8;
} else {
  $len = $argv[1];
}
print createRandom($len, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
print "\n";
