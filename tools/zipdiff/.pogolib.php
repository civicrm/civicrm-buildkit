<?php





function pogo_script() {
return pogo_clean_script(file_get_contents(getenv('POGO_SCRIPT')));
}





function pogo_script_dir() {
return dirname(getenv('POGO_SCRIPT'));
}







function pogo_clean_script($c) {
$lines = explode("\n", $c, 3);
$hasShebang = substr($lines[0], 0, 3) === '#!/';
if (!$hasShebang) {

return $c;
}

$tail = count($lines) === 3 ? $lines[2] : '';
if (preg_match(';^<' . '\?;', $lines[1])) {




return $lines[1] . "\n\n" . $tail;
}
else {


return $lines[1] . "\n" . $tail;
}
}







function pogo_stdin() {

return getenv('POGO_STDIN') ? getenv('POGO_STDIN') : 'php://stdin';
}
