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

<p>To login as a HR administrator:
<strong>Username:</strong> civihr_admin
<strong>Password:</strong> civihr_admin</p>

<p>To login as a staff member:
<strong>Username:</strong> civihr_staff
<strong>Password:</strong> civihr_staff</p>

<p>To login as a staff manager:
<strong>Username:</strong> civihr_manager
<strong>Password:</strong> civihr_manager</p>

<p><strong>Any data you enter on this demo site is "publicly available" due to the open login. Please do not enter real email addresses or other personal information.</strong> The demo database is reset periodically.</p>

<h3>New to CiviHR?</h3>
 CiviHR will be developed in multiple phases. So far it comprises of the following functionality:
<ul>
<li>Directory - a listing of the people who work for an organisation (paid and unpaid)
 <li>Staff Contact Details</li>
 <li>Identification</li>
 <li>Medical & Disability</li>
 <li>Visas & Work Permits</li>
 <li>Emergency Contacts</li>
 <li>Job Positions & Job Roles</li>
 <li>Skills & Qualifications</li>
 <li>Education & Employment History</li>
 <li>Simple Remuneration Recording</li>
 <li>Recording of Leave and Absences</li>
 <li>Workflows to manage Joining, Probation and Exiting</li>
 <li>Recruitment with an online job application process</li>
</ul>

For more information, please post your queries on the <strong><a href="http://forum.civicrm.org/index.php/board,87.0.html" target="_blank">CiviHR forum board</a></strong>. To stay updated about new developments in CiviHR, please subscribe to the <strong><a href="https://civicrm.org/civicrm-blog-categories/civihr" target="_blank" title="CiviHR Blog - opens in a new window">CiviHR blog</a></strong>.

Want to install your own copy of CiviHR? <a href="https://civicrm.org/extensions/civihr" target="_blank">Information about downloading and installation can be found here</a>.
';

// <h3>This is the development sandbox</h3>
// This sandbox represents the upcoming release - a work-in-progress. Unless you are interested in tracking development real-time, you might prefer to <a href="http://civihr.demo.civicrm.org/">explore CiviHR\'s current capabilities using the stable demo</a>.</p>

$node->body[$node->language][0]['summary'] = text_summary($node->body[$node->language][0]['value']);
$node->body[$node->language][0]['format']  = 'filtered_html';

$node->path = array('alias' => 'welcome');

node_save($node);
