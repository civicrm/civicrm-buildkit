<?php

define('SITE_CONFIG_DIR', getenv('SITE_CONFIG_DIR'));
if (! SITE_CONFIG_DIR) { throw new Exception("Failed to locate site config dir"); }

function _install_theme_applyColorScheme($theme, $scheme) {
  module_load_include('inc', 'system', 'system.admin');

  $fform = array();
  $fform_state = array();

  $fform_state['build_info']['args'][0] = $theme;
  $fform = system_theme_settings($fform, $fform_state, $theme);

  color_form_system_theme_settings_alter($fform, $fform_state);

  $fform_state['values']['theme'] = $theme;
  $fform_state['values']['info'] = color_get_info($theme);
  $fform_state['values']['palette'] = $fform_state['values']['info']['schemes'][$scheme]['colors'];
  $fform_state['values']['scheme'] = $scheme;

  color_scheme_form_submit($fform, $fform_state);
}

// Set Garland options
file_put_contents('public://logo.png', file_get_contents(SITE_CONFIG_DIR . '/civicrm-logo-fat.png'));
$settings_old = variable_get('theme_garland_settings', array());
$settings_new = array (
  'toggle_logo' => 1,
  'toggle_name' => 1,
  'toggle_slogan' => 1,
  'toggle_node_user_picture' => 1,
  'toggle_comment_user_picture' => 1,
  'toggle_comment_user_verification' => 1,
  'toggle_favicon' => 1,
  'toggle_main_menu' => 1,
  'toggle_secondary_menu' => 1,
  'default_logo' => 0,
  'logo_path' => 'public://logo.png',
  'default_favicon' => 1,
  'favicon_path' => '',
  'favicon_upload' => '',
  'garland_width' => 'fluid',
  'scheme' => 'ash',
  'theme' => 'garland',
);
variable_set('theme_garland_settings', array_merge($settings_old, $settings_new));
variable_set('theme_default', 'garland');

_install_theme_applyColorScheme('garland', 'ash');

// Enable blocks in Garland
db_query("update block set region='sidebar_first' where theme='garland' and module='user' and delta='login'");
db_query("update block set region='sidebar_first' where theme='garland' and module='system' and delta='navigation'");
