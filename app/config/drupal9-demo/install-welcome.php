<?php

/**
 * @file
 *
 * Register the "welcome" node (node/1)
 */
$bodyValue = '<p><strong><a href="http://civicrm.org" target="_blank" title="Opens CiviCRM.org site in a new window.">CiviCRM</a> is a community-based open source project to build constituent relationship management functionality for the nonprofit, advocacy and nongovernmental sectors.
You can use this demo site to try out most of the features of CiviCRM including online donation processing, event management, memberships, case management, reporting and more ...</strong></p>

Just login with...
<strong>Username:</strong> demo<br />
<strong>Password:</strong> demo</p>
... and click the <a href="/civicrm"><strong>CiviCRM</strong></a> link (upper left-hand corner of your screen)

<p><strong>Any data you enter on this demo site is "publicly available" due to the open login. Please do not enter real email addresses or other personal information.</strong> The demo database is reset periodically.</p>

<h3>New to CiviCRM?</h3>
<ul>
<li>Learn about how you can use CiviCRM from our new <strong><a href="https://docs.civicrm.org/user/en/stable/" target="_blank" title="Opens Understanding CiviCRM book in a new window">online book</a></strong>.</li>
<li>Check out  <strong><a href="https://civicrm.org">CiviCRM.org</a></strong> for an overview of the project, blogs, professional services listings and other resources and links.</li>
<li>Join the <strong><a href="https://chat.civicrm.org">Mattermost</a></strong> chat to see what folks in the CiviCRM community are talking about.</li>
</ul>';
$config = \Drupal::configFactory()->getEditable('system.site');
$nodeEntity = \Drupal::entityTypeManager()->getStorage('node');
$node = $nodeEntity->load(1);
if ($node === NULL) {
  $node = $nodeEntity->create([
    'type' => 'page',
    'title' => 'Welcome to ' . $config->get('name'),
  ]);
  $node->body->value = $bodyValue;
  $node->body->summary = text_summary($node->body->value);
  $node->body->format  = 'restricted_html';
  $node->save();
}
else {
  $node->title = 'Welcome to ' . $config->get('name');
  $node->body->value = $bodyValue;
  $node->body->summary = text_summary($node->body->value);
  $node->body->format  = 'restricted_html';
  $node->save();
}
\Drupal::entityTypeManager()->getStorage('path_alias')->create(['path' => $node->toUrl()->toString(), 'alias' => '/welcome'])->save();
$config->set('page.front', $node->toUrl()->toString())->save();
