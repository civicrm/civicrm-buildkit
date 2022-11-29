<?php

// This is supplemental/static list of repos.  These don't appear in the
// extension feeds (e.g.  because they aren't extensions; or they're not on
// lab.civicrm.org; or they haven't been submitted for in-app distribution).

return function() {
  $gitUrls = [
    // FORMAT: 'git-url[#branch]' => 'type-dir[/project-name]'

    // The "core" projects are incorporated into the main build release.
    'https://github.com/civicrm/civicrm-backdrop#1.x-master' => 'core/civicrm-backdrop-1.x',
    'https://github.com/civicrm/civicrm-core' => 'core',
    'https://github.com/civicrm/civicrm-drupal#6.x-master' => 'core/civicrm-drupal-6.x',
    'https://github.com/civicrm/civicrm-drupal#7.x-master' => 'core/civicrm-drupal-7.x',
    'https://github.com/civicrm/civicrm-drupal-8' => 'core/civicrm-drupal-8.x',
    'https://github.com/civicrm/civicrm-joomla' => 'core',
    'https://github.com/civicrm/civicrm-packages' => 'core',
    'https://github.com/civicrm/civicrm-upgrade-test' => 'core',
    'https://github.com/civicrm/civicrm-wordpress' => 'core',
    'https://github.com/civicrm/l10n' => 'core',

     // The "docs" projects are published as online guides.
    'https://github.com/civicrm/civicrm-infra' => 'docs',
    'https://github.com/civicrm/release-management' => 'docs',
    'https://lab.civicrm.org/documentation/docs-books' => 'docs',
    'https://lab.civicrm.org/documentation/docs/dev' => 'docs/civicrm-dev-docs', /* old project name */
    'https://lab.civicrm.org/documentation/docs/handbook' => 'docs',
    'https://lab.civicrm.org/documentation/docs/installation' => 'docs',
    'https://lab.civicrm.org/documentation/docs/sysadmin' => 'docs/civicrm-sysadmin-guide', /* old project name */
    'https://lab.civicrm.org/documentation/docs/training' => 'docs',
    'https://lab.civicrm.org/documentation/docs/user-de' => 'docs',
    'https://lab.civicrm.org/documentation/docs/user-en' => 'docs/civicrm-user-guide', /* old project name */
    'https://lab.civicrm.org/documentation/docs/user-es' => 'docs',
    'https://lab.civicrm.org/documentation/docs/user-fr' => 'docs',
    'https://lab.civicrm.org/documentation/test-book' => 'docs',

     // The "lib" projects are small/distinct libraries that have been extracted from core or forked from others.
    'https://github.com/civicrm/civicrm-cxn-rpc' => 'lib',
    'https://github.com/civicrm/civicrm-setup' => 'lib',
    'https://github.com/civicrm/composer-compile-lib' => 'lib',
    'https://github.com/civicrm/composer-compile-plugin' => 'lib',
    'https://github.com/civicrm/composer-downloads-plugin' => 'lib',
    'https://github.com/civicrm/jquery' => 'lib',
    'https://github.com/civicrm/jqueryui' => 'lib',
    'https://github.com/civicrm/mosaico' => 'lib',
    'https://github.com/civicrm/zetacomponents-mail' => 'lib',

    // The "misc" projects infrastructure that helps run c.o.
    'https://github.com/civicrm/civicon' => 'misc',
    'https://github.com/civicrm/civicrm-ac' => 'misc',
    'https://github.com/civicrm/civicrm-botdylan' => 'misc',
    'https://github.com/civicrm/civicrm-community-messages' => 'misc',
    'https://github.com/civicrm/civicrm-dist-manager' => 'misc',
    'https://github.com/civicrm/civicrm-docs' => 'misc',
    'https://github.com/civicrm/civicrm-extdir-example' => 'misc',
    'https://github.com/civicrm/civicrm-pingback' => 'misc',
    'https://github.com/civicrm/civicrm-statistics' => 'misc',
    'https://github.com/civicrm/cxnapp' => 'misc',
    'https://github.com/civicrm/pr-report' => 'misc',
    'https://github.com/civicrm/probot-civicrm' => 'misc',
    'https://lab.civicrm.org/documentation/docs-publisher' => 'misc',

     // The "tools" are small, distinct tools. They can run on their own, but they mostly exist to complement Civi's development+deployment.
    'https://github.com/civicrm/civicrm-buildkit' => 'tools',
    'https://github.com/civicrm/civistrings' => 'tools',
    'https://github.com/civicrm/coder' => 'tools',
    'https://github.com/civicrm/cv' => 'tools',
    'https://github.com/civicrm/cv-nodejs' => 'tools',
    'https://github.com/civicrm/phpunit-xml-cleanup' => 'tools',
    'https://github.com/systopia/CiviProxy' => 'tools',
    'https://github.com/totten/civix' => 'tools',
    'https://lab.civicrm.org/dev/coworker' => 'tools',
    'https://lab.civicrm.org/documentation/vale-standards' => 'tools',

    // Drupal Modules
    'https://git.drupalcode.org/project/civicrm_entity' => 'drupal-module',
    'https://github.com/civicrm/apachesolr_civiAttachments' => 'drupal-module',
    'https://github.com/colemanw/webform_civicrm' => 'drupal-module',

    // WordPress Plugins
    // NOTE: There's a separate section for svn-based plugins.
    'https://github.com/civicrm/civicrm-demo-wp' => 'wp-plugin',
    'https://github.com/ClickandPledge/wordpress-civicrm' => 'wp-plugin/click-and-pledge',
    'https://github.com/WPCV/cf-civicrm' => 'wp-plugin',
    'https://github.com/WPCV/wpcv-woo-civi-integration' => 'wp-plugin',

     // Some random exts that don't appear in the feeds.
    'https://github.com/3sd/civicrm-pinpoint' => 'ext',
    'https://github.com/3sd/civicrm-recalculate-recipients' => 'ext',
    'https://github.com/3sd/civicrm-recurring-mail' => 'ext',
    'https://github.com/MegaphoneJon/agbucontributiontab' => 'ext',
    'https://github.com/MegaphoneJon/com.megaphonetech.monitoring' => 'ext',
    'https://github.com/MegaphoneJon/com.megaphonetech.msumfields' => 'ext',
    'https://github.com/MegaphoneJon/coop.palantetech.module.hidepaypalexpresscheckout' => 'ext',
    'https://github.com/MegaphoneJon/core2581' => 'ext',
    'https://github.com/MegaphoneJon/fastactionpdf' => 'ext',
    'https://github.com/MegaphoneJon/fieldlookup' => 'ext',
    'https://github.com/MegaphoneJon/habitat' => 'ext',
    'https://github.com/MegaphoneJon/nosmsurltracking' => 'ext',
    'https://github.com/MegaphoneJon/org.ujc.requiredduration' => 'ext',
    'https://github.com/Project60/cbb-be-coda2' => 'ext',
    'https://github.com/Project60/org.project60.banking' => 'ext',
    'https://github.com/Project60/org.project60.bankingboilerplate' => 'ext',
    'https://github.com/Project60/org.project60.bic' => 'ext',
    'https://github.com/Project60/org.project60.coda' => 'ext',
    'https://github.com/Project60/org.project60.membership' => 'ext',
    'https://github.com/Project60/org.project60.sepa' => 'ext',
    'https://github.com/Project60/org.project60.sepapp' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.addcontributiontabs' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.citystatetoken' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.confirmbuttons' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.customcivistylesui' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.memberid' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.minimumpayment' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.nfbevents' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.otheramounts' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.remoteidsync' => 'ext',
    'https://github.com/aghstrategies/com.aghstrategies.usermover' => 'ext',
    'https://github.com/artfulrobot/grassrootspetition' => 'ext',
    'https://github.com/artfulrobot/inlaypetition' => 'ext',
    'https://github.com/artfulrobot/inlaysignup' => 'ext',
    'https://github.com/artfulrobot/uk.artfulrobot.civicrm.giftaid' => 'ext',
    'https://github.com/civicrm/civicrm-l10n-extensions' => 'ext',
    'https://github.com/civicrm/civihr#staging' => 'ext',
    'https://github.com/civicrm/org.civicrm.doctorwhen' => 'ext',
    'https://github.com/civicrm/org.civicrm.module.cividiscount' => 'ext',
    'https://github.com/civicrm/org.civicrm.shoreditch' => 'ext',
    'https://github.com/civicrm/org.civicrm.sms.twilio' => 'ext',
    'https://github.com/civicrm/org.civicrm.styleguide' => 'ext',
    'https://github.com/civicrm/org.civicrm.volunteer' => 'ext',
    'https://github.com/demeritcowboy/analyzecivicase' => 'ext',
    'https://github.com/demeritcowboy/com.chabadsuite.attachmentimport' => 'ext',
    'https://github.com/demeritcowboy/noprevnext' => 'ext',
    'https://github.com/eileenmcnaughton/nz.co.fuzion.cmcic' => 'ext',
    'https://github.com/eileenmcnaughton/nz.co.fuzion.entitymessages' => 'ext',
    'https://github.com/eileenmcnaughton/nz.co.fuzion.notificationlog' => 'ext',
    'https://github.com/eileenmcnaughton/org.wikimedia.forgetme' => 'ext',
    'https://github.com/eileenmcnaughton/org.wikimedia.omnimail' => 'ext',
    'https://github.com/eileenmcnaughton/testdata' => 'ext',
    'https://github.com/systopia/de.systopia.amazonbounceapi' => 'ext',
    'https://github.com/systopia/de.systopia.anonymiser' => 'ext',
    'https://github.com/systopia/de.systopia.civioffice' => 'ext',
    'https://github.com/systopia/de.systopia.committees' => 'ext',
    'https://github.com/systopia/de.systopia.contract' => 'ext',
    'https://github.com/systopia/de.systopia.dbmonitor' => 'ext',
    'https://github.com/systopia/de.systopia.donrec' => 'ext',
    'https://github.com/systopia/de.systopia.eck' => 'ext',
    'https://github.com/systopia/de.systopia.esr' => 'ext',
    'https://github.com/systopia/de.systopia.eventcheckin_de' => 'ext',
    'https://github.com/systopia/de.systopia.eventmessages' => 'ext',
    'https://github.com/systopia/de.systopia.gdprx' => 'ext',
    'https://github.com/systopia/de.systopia.identitytracker' => 'ext',
    'https://github.com/systopia/de.systopia.loggingtools' => 'ext',
    'https://github.com/systopia/de.systopia.mailattachment' => 'ext',
    'https://github.com/systopia/de.systopia.mailbatch_de' => 'ext',
    'https://github.com/systopia/de.systopia.mailingtools' => 'ext',
    'https://github.com/systopia/de.systopia.moregreetings' => 'ext',
    'https://github.com/systopia/de.systopia.newsletter' => 'ext',
    'https://github.com/systopia/de.systopia.promocodes' => 'ext',
    'https://github.com/systopia/de.systopia.remoteevent' => 'ext',
    'https://github.com/systopia/de.systopia.remotetools' => 'ext',
    'https://github.com/systopia/de.systopia.resource' => 'ext',
    'https://github.com/systopia/de.systopia.resourceactivity' => 'ext',
    'https://github.com/systopia/de.systopia.secretdata' => 'ext',
    'https://github.com/systopia/de.systopia.segmentation' => 'ext',
    'https://github.com/systopia/de.systopia.selfservice' => 'ext',
    'https://github.com/systopia/de.systopia.signatures' => 'ext',
    'https://github.com/systopia/de.systopia.stoken' => 'ext',
    'https://github.com/systopia/de.systopia.twingle' => 'ext',
    'https://github.com/systopia/de.systopia.xcm' => 'ext',
    'https://github.com/systopia/de.systopia.xportx' => 'ext',
    'https://github.com/totten/hurtlocker' => 'ext',
    'https://github.com/twomice/com.joineryhq.cpptmembership' => 'ext',
    'https://github.com/twomice/com.joineryhq.cpreports' => 'ext',
    'https://github.com/twomice/com.joineryhq.groupreg' => 'ext',
    'https://github.com/twomice/com.joineryhq.metrotweaks' => 'ext',
    'https://github.com/twomice/org.osltoday.osltweaks' => 'ext',
    'https://github.com/veda-consulting-company/ncn-civi-zoom' => 'ext',
    'https://github.com/veda-consulting-company/uk.co.vedaconsulting.module.wordmailmerge' => 'ext',
    'https://github.com/veda-consulting-company/uk.co.vedaconsulting.pcpteams' => 'ext',
    'https://github.com/webaccess/com.webaccessglobal.module.civimobile' => 'ext',
  ];
  foreach ($gitUrls as $gitUrlExpr => $type) {
    $gitUrlParts = explode('#', $gitUrlExpr);
    $gitUrl = $gitUrlParts[0];
    $typeParts = explode('/', $type);
    $key = $typeParts[1] ?? basename($gitUrl);

    $result[$key] = [
      'git_url' => $gitUrl,
      'type' => $typeParts[0],
    ];
    if (!empty($gitUrlParts[1])) {
      $result[$key]['git_branch'] = $gitUrlParts[1];
    }
  }

  // These repos all live on 'plugins.svn.wordpress.org'. They have simple naming+branching.
  $wporgPlugins = [
    'bp-groups-civicrm-sync',
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
