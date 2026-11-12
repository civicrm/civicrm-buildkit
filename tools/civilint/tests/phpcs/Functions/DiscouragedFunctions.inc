<?php

// A script boots CiviCRM through cv.
eval(`cv php:boot`);
eval(`cv php:boot --level=classloader`);
// Any other eval() stays discouraged.
eval($code);
eval(`cat boot.php`);
eval(`cv php:boot; cat boot.php`);
