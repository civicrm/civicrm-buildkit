#!/usr/bin/env php
<?php
## Generate an HTML document which describes a particular build.
## This should be executed within the context of "civibuild"
## such that most civibuild environment variables are available.

/** Echo an environment variable */
function ev($var) {
  echo htmlspecialchars(getenv($var));
}

/** Build a list of changes in the git checkouts */
function git_scan_diff($from, $to) {
  exec("git scan diff --format=json " . escapeshellarg($from) . ' ' . escapeshellarg($to), $output);
  return json_decode(implode('', $output), TRUE);
}

$time = date('Y-m-d H:i:s T');
?>
<html>
  <head>
    <title>Build summary for <?php ev('SITE_NAME'); ?> (<?php echo $time ?>)</title>
    <style type="text/css">
      table {
        border-collapse: collapse;
      }
      table, tr, td, th {
        border: 1px solid black;
      }
      td, th {
        padding: 0.3em;
      }
      th {
        text-decoration: underline;
      }
      .git-new-scan {
        width: 90%;
      }
    </style>
  </head>
  <body>
    <h1>Build summary for <?php ev('SITE_NAME'); ?> (<?php echo $time ?>)</h1>

    <?php if (getenv('SHOW_NEW_SCAN')) { ?>
      <h2>Git Scan</h2>
      <small>(Compare <a href="git-scan.last.json">git-scan.last.json</a> [<a href="git-scan.last.txt">txt</a>] and <a href="git-scan.new.json">git-scan.new.json</a> [<a href="git-scan.new.txt">txt</a>])</small>
      <table class="git-changes">
        <thead>
          <tr>
            <th>Status</th>
            <th>Path</th>
            <th>From</th>
            <th>To</th>
            <th>Changes</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach(git_scan_diff(getenv('SHOW_LAST_SCAN'), getenv('SHOW_NEW_SCAN')) as $row) { ?>
            <tr>
              <td><?php echo htmlspecialchars($row['status']); ?></td>
              <td><code><?php echo htmlspecialchars($row['path']); ?></code></td>
              <td><code><?php echo htmlspecialchars($row['from']); ?></code></td>
              <td><code><?php echo htmlspecialchars($row['to']); ?></code></td>
              <td><?php echo htmlspecialchars($row['changes']); ?></td>
            </tr>
          <?php } /* end: foreach($row) */ ?>
        </tbody>
      </table>
    <?php } /* end: if (SHOW_NEW_SCAN) */ ?>

    <h2>Build Variables</h2>
    <table class="build-vars">
      <thead>
        <tr>
          <th>Variable</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach (array('SITE_NAME', 'SITE_TYPE', 'CMS_ROOT', 'CMS_URL', 'ADMIN_USER', 'ADMIN_PASS', 'DEMO_USER', 'DEMO_PASS', 'ghprbPullId', 'ghprbTargetBranch') as $var) { ?>
          <?php if (getenv($var)) { ?>
          <tr>
            <td><code><?php echo $var; ?></code></td>
            <td><code><?php ev($var); ?></code></td>
          </tr>
          <?php } ?>
        <?php } /* end: foreach($var) */ ?>
      </tbody>
    </table>

    <h2>Steps to Reproduce</h2>

    <pre>
civibuild download <?php ev('SITE_NAME'); ?> --type <?php ev('SITE_TYPE'); ?>

## FIXME: Load specific git commits
<?php /* #git scan import &lt;&lt; EOJSON
#<?php echo htmlspecialchars(file_get_contents(getenv('SHOW_NEW_SCAN'))) ?>
#EOJSON */ ?>
civibuild install <?php ev('SITE_NAME'); ?> \
  --url <?php ev('CMS_URL') ?> \
  --admin-user <?php ev('ADMIN_USER'); ?> --admin-pass <?php ev('ADMIN_PASS'); ?> \
  --demo-user <?php ev('DEMO_USER'); ?> --demo-pass <?php ev('DEMO_PASS'); ?>

</pre>

    <h2></h2>
  </body>
</html>
