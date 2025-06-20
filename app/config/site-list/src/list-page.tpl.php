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
 * @param string $filter
 *   The current filter value.
 */

$columns = sitelist_columns();
?>
<html>

<head>
  <title><?php echo htmlentities($config['title']); ?></title>
  <?php sitelist_print_style('lib/bootstrap/dist/css/bootstrap.min.css'); ?>
  <?php sitelist_print_script('lib/jquery.min.js'); ?>
  <?php sitelist_print_script('lib/bootstrap/dist/js/bootstrap.min.js'); ?>
  <style type="text/css">
    <?php echo sitelist_render('style.css.php'); ?>
  </style>
</head>

<body>

<nav class="navbar navbar-default" role="navigation">
  <div class="container-fluid">
    <div class="navbar-header">
      <a class="navbar-brand" href="#">
        <?php echo htmlentities($config['title']); ?>
      </a>
    </div>

    <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
      <?php if (!empty($config['about'])): ?>
        <p class="navbar-text">
          <?php echo $config['about'];?>
        </p>
      <?php endif; ?>
    </div>
  </div>
</nav>

<?php echo sitelist_render('search-form.tpl.php', [
  'config' => $config,
  'filter' => $filter,
]); ?>

<table class="table table-striped table-bordered site-list">
  <thead>
  <tr>
    <?php
    foreach ($config['display'] as $displayOption) {
      if (isset($columns[$displayOption])) {
        $cb = $columns[$displayOption]['render'];
        printf('<th>%s</th>', $columns[$displayOption]['title']);
      }
    }
    ?>
  </tr>
  </thead>
  <tbody>
  <?php
  foreach ($sites as $name => $site) {
    echo '<tr>';
    foreach ($config['display'] as $displayOption) {
      if (isset($columns[$displayOption])) {
        $cb = $columns[$displayOption]['render'];
        echo '<td>';
        $cb($site, $config);
        echo '</td>';
      }
    }
    echo '</tr>';
  };
  ?>
  </tbody>
</table>
</body>
</html>
