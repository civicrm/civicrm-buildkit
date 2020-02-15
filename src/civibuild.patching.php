<?php

$composerContents = json_decode(file_get_contents('./composer.json'), TRUE);
if (array_key_exists('extra', $composerContents) !== FALSE) {
  $composerContents['extra']['enable-patching'] = 1;
}
else {
  $composerContents['extra'] = [];
  $composerContents['extra']['enable-patching'] = 1;
}
file_put_contents('./composer.json', json_encode($composerContents, JSON_FORCE_OBJECT | JSON_PRETTY_PRINT)); 
