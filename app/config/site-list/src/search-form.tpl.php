<?php
/**
 * @file
 *
 * Render a search from.
 *
 * @param array $config
 *   Site-list UI configuration.
 * @param string $filter
 *   The current filter value.
 */ ?>

<form method="get">
  <label>Filter
    <input type="text" name="filter" value="<?php echo htmlentities($filter); ?>"/>
  </label>
  <input type="submit" value="Apply"/>
</form>
