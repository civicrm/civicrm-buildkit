<?php
/**
 * @file
 *
 * Render the chosen list of fields (for a given site).
 *
 * @param array $config
 *   Site-list UI configuration.
 * @param array $site
 *   Site definition (from the *.sh file)
 */ ?>

<?php foreach ($config['display'] as $displayOption): ?>

  <?php if ($displayOption === 'ALL'): ?>
    <div class="site-list-detail">
      <strong>All site metadata</strong>:
      <pre>
          <?php var_export($site); ?>
        </pre>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'ADMIN_USER'): ?>
    <div class="site-list-detail">
      <strong>Admin User</strong>:
      <code><?php echo htmlentities($site['ADMIN_USER']); ?></code>
      /
      <code><?php echo htmlentities($site['ADMIN_PASS']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'DEMO_USER'): ?>
    <div class="site-list-detail">
      <strong>Demo User</strong>:
      <code><?php echo htmlentities($site['DEMO_USER']); ?></code>
      /
      <code><?php echo htmlentities($site['DEMO_USER']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'CMS_DB'): ?>
    <div class="site-list-detail">
      <strong>CMS DB</strong>:
      <code><?php echo htmlentities($site['CMS_DB_DSN']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'CIVI_DB'): ?>
    <div class="site-list-detail">
      <strong>Civi DB</strong>:
      <code><?php echo htmlentities($site['CIVI_DB_DSN']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'TEST_DB'): ?>
    <div class="site-list-detail">
      <strong>Test DB</strong>:
      <code><?php echo htmlentities($site['TEST_DB_DSN']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'SITE_TYPE'): ?>
    <div class="site-list-detail">
      <strong>Site Build Type</strong>:
      <code><?php echo htmlentities($site['SITE_TYPE']); ?></code>
    </div>
  <?php endif; ?>


  <?php if ($displayOption === 'WEB_ROOT'): ?>
    <div class="site-list-detail">
      <strong>Web Root Path</strong>:
      <code><?php echo htmlentities($site['WEB_ROOT']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'CIVI_CORE'): ?>
    <div class="site-list-detail">
      <strong>Civi Core Path</strong>:
      <code><?php echo htmlentities($site['CIVI_CORE']); ?></code>
    </div>
  <?php endif; ?>

  <?php if ($displayOption === 'BUILD_TIME'): ?>
    <div class="site-list-detail">
      <strong>Build Time</strong>:
      <?php echo date('Y-m-d H:i T', $site['BUILD_TIME']); ?>
    </div>
  <?php endif; ?>

<?php endforeach; ?>
