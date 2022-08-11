<?php

// This is supplemental/static list of repos. These don't appear in the extension-feed.

return function() {
  $result = array(
    'civicrm-core' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-core',
      'type' => 'core',
    ),
    'civicrm-backdrop-1.x' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-backdrop',
      'git_branch' => '1.x-master',
      'type' => 'core',
    ),
    'civicrm-buildkit' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-buildkit',
      'type' => 'tools',
    ),
    'civicrm-drupal-6.x' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-drupal',
      'git_branch' => '6.x-master',
      'type' => 'core',
    ),
    'civicrm-drupal-7.x' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-drupal',
      'git_branch' => '7.x-master',
      'type' => 'core',
    ),
    'civicrm-drupal-8.x' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-drupal-8',
      'type' => 'core',
    ),
    'civicrm-joomla' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-joomla',
      'type' => 'core',
    ),
    'civicrm-packages' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-packages',
      'type' => 'core',
    ),
    'civicrm-setup' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-setup',
      'type' => 'lib',
    ),
    'civicrm-wordpress' => array(
      'git_url' => 'https://github.com/civicrm/civicrm-wordpress',
      'type' => 'core',
    ),
    'civihr' => array(
      'git_url' => 'https://github.com/civicrm/civihr',
      'git_branch' => 'staging',
      'type' => 'ext',
    ),
    'com.webaccessglobal.module.civimobile' => array(
      'git_url' => 'https://github.com/webaccess/com.webaccessglobal.module.civimobile',
      'type' => 'ext',
    ),
    'civix' => array(
      'git_url' => 'https://github.com/totten/civix',
      'type' => 'tools',
    ),
    'coworker' => array(
      'git_url' => 'https://lab.civicrm.org/dev/coworker',
      'type' => 'tools',
    ),
    'cf-civicrm' => array(
      'git_url' => 'https://github.com/mecachisenros/cf-civicrm',
      'type' => 'wp-plugin',
    ),
    'civicrm_entity' => array(
      'git_url' => 'https://git.drupalcode.org/project/civicrm_entity',
      'type' => 'drupal-module',
    ),
    'webform_civicrm' => array(
      'git_url' => 'https://github.com/colemanw/webform_civicrm',
      'type' => 'drupal-module',
    ),
    'click-and-pledge' => [
      'git_url' => 'https://github.com/ClickandPledge/wordpress-civicrm',
      'type' => 'wp-plugin',
    ],
  );

  // These repos all live in `github.com/civicrm', have basic names, and use default branches.
  $subRepos = array(
    'l10n' => 'core',
    'civicrm-upgrade-test' => 'core',

    'civicrm-dev-docs' => 'docs',
    'civicrm-infra' => 'docs',
    'civicrm-sysadmin-guide' => 'docs',
    'civicrm-user-guide' => 'docs',
    'release-management' => 'docs',

    'apachesolr_civiAttachments' => 'drupal-module',

    'civicrm-l10n-extensions' => 'ext',
    'org.civicrm.doctorwhen' => 'ext',
    'org.civicrm.module.cividiscount' => 'ext',
    'org.civicrm.shoreditch' => 'ext',
    'org.civicrm.sms.twilio' => 'ext',
    'org.civicrm.styleguide' => 'ext',
    'org.civicrm.volunteer ' => 'ext',

    'civicrm-cxn-rpc' => 'lib',
    'composer-compile-lib ' => 'lib',
    'composer-compile-plugin ' => 'lib',
    'composer-downloads-plugin ' => 'lib',
    'jquery' => 'lib',
    'jqueryui' => 'lib',
    'mosaico' => 'lib',
    'zetacomponents-mail' => 'lib',

    'civicon' => 'misc',
    'civicrm-ac' => 'misc',
    'civicrm-botdylan' => 'misc',
    'civicrm-community-messages' => 'misc',
    'civicrm-dist-manager' => 'misc',
    'civicrm-docs' => 'misc',
    'civicrm-extdir-example' => 'misc',
    'civicrm-org-platform' => 'misc',
    'civicrm-pingback' => 'misc',
    'civicrm-statistics' => 'misc',
    'cxnapp' => 'misc',
    'pr-report' => 'misc',
    'probot-civicrm' => 'misc',

    'civistrings' => 'tools',
    'coder' => 'tools',
    'cv' => 'tools',
    'cv-nodejs' => 'tools',
    'phpunit-xml-cleanup ' => 'tools',

    'civicrm-demo-wp' => 'wp-plugin',
  );
  foreach ($subRepos as $subRepo => $type) {
    $result[$subRepo] = array(
      'git_url' => 'https://github.com/civicrm/' . $subRepo,
      'type' => $type,
    );
  }

  $wporgPlugins = [
    'civicrm-admin-utilities',
    'civicrm-contribution-page-widget',
    'civicrm-wp-member-sync',
    'civicrm-wp-profile-sync',
    'civievent-widget',
  ];
  foreach ($wporgPlugins as $name) {
    $result[$name] = [
      'svn_url' => 'https://plugins.svn.wordpress.org/' . $name . '/trunk',
      'type' => 'wp-plugin',
    ];
  }

  return $result;
};
