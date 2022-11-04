<?php

// Local desktop => Prefer to use Mailhog/Mailcatcher.
if (
  // No one else has configured outbound mail...
  empty($GLOBALS['civicrm_setting']['domain']['mailing_backend'])
  // This looks like local nix-based developer workstation...
  && !empty(getenv('MAIL_SMTP_PORT') && function_exists('posix_getlogin') && !in_array(posix_getlogin(), ['jenkins', 'publisher']))
  // This is a regular web/cli process -- not a phpunit process.
  && !class_exists('PHPUnit\Framework\TestCase', FALSE) && CIVICRM_UF !== 'UnitTests'
) {
  $GLOBALS['civicrm_setting']['domain']['mailing_backend'] = [
    'outBound_option' => 0,
    'smtpServer' => 'localhost',
    'smtpPort' => (int) getenv('MAIL_SMTP_PORT'),
    ## Tip: By default, PHP-FPM hides env-vars. This has to be exported via php-fpm.conf.
    'smtpAuth' => FALSE,
  ];
}

// Everyone else. (This continues the prior behavior.)
if (!defined('CIVICRM_MAIL_LOG') && empty($GLOBALS['civicrm_setting']['domain']['mailing_backend'])) {
  define('CIVICRM_MAIL_LOG', '/dev/null');
}
