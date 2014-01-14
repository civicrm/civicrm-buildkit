<?php

/**
 * @file
 *
 * Register the "welcome" node (node/1)
 */

$node = node_load(1);
if ($node === FALSE) {
  $node = new stdClass();
  $node->type = 'page';
  node_object_prepare($node);
}

$node->title    = 'Welcome to ' . variable_get('site_name');
$node->language = LANGUAGE_NONE;
$node->body[$node->language][0]['value']   = '
<p>CiviHR is an integrated Human Resource Management application designed to meet the needs of non-profit and third sector organizations.</p>

<p>To login ...
<strong>Username:</strong> demo
<strong>Password:</strong> demo</p>

<p><strong>Any data you enter on this demo site is "publicly available" due to the open login. Please do not enter real email addresses or other personal information.</strong> The demo database is reset periodically.</p>

<h3>New to CiviHR?</h3>
 CiviHR will be developed in multiple phases. Phase 1 includes the following functionality:
<ul>
<li>People (Paid & Unpaid) - a directory listing of the people who work for an organisation - showing names and photographs
 <li>Personal Contact Details</li>
 <li>Work Contact Details</li>
 <li>Identification</li>
 <li>Medical & Disability</li>
 <li>Visas & Work Permits</li>
 <li>Emergency Contacts</li>
 <li>Job Positions & Job Roles</li>
 <li>Skills & Qualifications</li>
 <li>Education & Employment</li>
 <li>Simple Remuneration Recording</li>
</ul>

Some features to check out as you start exploring:
<ul>
<li>Click <strong>Directory</strong> in the top menu bar to view the searchable staff directory</li>
<li>Use <strong>Quick Search</strong> in the upper left corner to find a staff person and click their name or email to see how a staff person is displayed with their job information, career history, medical information and more.</li>
<li>Review HR Reports from the <strong>Contact Reports</strong> menu.</li>
</ul>

Learn more and stay up to date about CiviHR by <strong><a href="https://civicrm.org/civicrm-blog-categories/civihr" target="_blank" title="CiviHR Blog - opens in a new window">reading or subscribing to the CiviHR blog</a></strong>. You can use the <strong><a href="http://forum.civicrm.org/index.php/board,87.0.html">CiviHR forum board</a></strong> to discuss CiviHR with other folks in the community.

Want to install your own copy of CiviHR? <a href="https://civicrm.org/extensions/civihr" target="_blank">Information about downloading and installation can be found here</a>.
';

// <h3>This is the development sandbox</h3>
// This sandbox represents the upcoming release - a work-in-progress. Unless you are interested in tracking development real-time, you might prefer to <a href="http://civihr.demo.civicrm.org/">explore CiviHR\'s current capabilities using the stable demo</a>.</p>

$node->body[$node->language][0]['summary'] = text_summary($node->body[$node->language][0]['value']);
$node->body[$node->language][0]['format']  = 'filtered_html';

$node->path = array('alias' => 'welcome');

node_save($node);
