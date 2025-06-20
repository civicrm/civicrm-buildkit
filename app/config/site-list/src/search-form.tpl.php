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

<form class="form-inline" method="get">
  <div class="form-group">
    <label class="sr-only" for="filter-inline">Filter</label>
    <input type="text" class="form-control" id="filter-inline" name="filter" value="<?php echo htmlentities($filter); ?>" placeholder="Filter">
  </div>
  <button type="submit" class="btn btn-default">Apply</button>
</form>
