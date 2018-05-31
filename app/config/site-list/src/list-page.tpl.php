<?php
/**
 * @file
 *
 * Render a full listing page.
 *
 * @param array $config
 *   Site-list UI configuration.
 * @param array $sites
 *   List of site definitions (from the *.sh files)
 */ ?>
<html>

<head>
  <title><?php echo htmlentities($title); ?></title>
  <style type="text/css">
    <?php echo sitelist_render('style.css.php'); ?>
  </style>
</head>

<body>

<h1><?php echo htmlentities($title); ?></h1>

<?php if (empty($sites)): ?>
  <p>No sites found.</p>
<?php endif; ?>

<ul class="site-list">
  <?php foreach ($sites as $name => $site): ?>
    <li>
      <h2 class="site-list-title">
        <a href="<?php echo htmlentities($site['CMS_URL']); ?>">
          <?php echo htmlentities($name); ?>
        </a>
      </h2>
      <div class="site-list-details">
        <?php echo sitelist_render('site-details.tpl.php', [
          'config' => $config,
          'site' => $site
        ]); ?>
      </div>
    </li>
  <?php endforeach; ?>
</ul>
</body>
</html>
