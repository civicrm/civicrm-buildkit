# drupal10-dod ("drupal.org developer" style)

* __Why__: So that you can write/test patches for `drupal.git` and `civicrm-core.git` in the same environment.
* __How__: Install the canonical `drupal.git`. Do **not** use the ordinary-but-derivative `drupal/recommended-project`.
  Then, add Civi stuff on top.
* __Note__: This will make changes to the top-level `composer.json` which you probably shouldn't commit or share.
