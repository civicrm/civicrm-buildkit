<?php

// CiviCRM ts() and the civix E::ts() helper follow the same rules.
$x = ts("Saved $name");
$x = ts('Saved' . ' %1', [1 => $name]);
$x = CRM_Foo_ExtensionUtil::ts(' Saved');
$x = ts('Saved \'%1\'', [1 => $name]);
$x = ts('Saved %1', [1 => $name]);
$x = E::ts("Saved '%1'", [1 => $name]);
$x = E::ts('receipt') . '.pdf';

class CRM_Foo_ExtensionUtil {

  public static function ts($text, $params = []) {
    return ts($text, $params);
  }

  public function other() {
    return self::ts($this->label) . $this->ts($this->label);
  }

}

// ts() keeps typography inside the string.
$x = ts('Selected Option') . ': ' . $option;
$x = ts('Renew') . '...';
$x = ts('Contribution') . ' %%StatusMessage%%';
$x = ts('Invalid type') . ': "' . $type . '"';
// ts() embedded in markup, SQL, JavaScript or Smarty, or used as a file name, is fine.
$x = '<a title="' . ts('View Contact') . '" href="' . $url . '">';
$x = 'IF(is_hidden, "' . ts('Search Results') . '", title) AS value';
$x = 'IF(owner_id, "(' . E::ts('by relationship') . ')", owner_id)';
$x = "{if '[parent_id]'}" . ts('Subtype of %1', [1 => '[parent_id:label]']) . "{/if}";
$x = "<a href='#'>" . ts('flip') . "</a>&nbsp;|&nbsp;";
$x = ts('First sentence.') . '\n\n' . ts('Second sentence.');

// ts() strings stay on one line.
$x = ts('A long sentence
  continued on the next line.');
$x = ts("A long sentence\ncontinued.");

// ts() strings keep inline markup, block-level markup goes around them.
$x = ts('Use the <code>%1</code> setting.', [1 => $name]);
$x = ts('Number of<br />Participants');
$x = ts('Read the <a href="%1">documentation</a>.', [1 => $url]);
$x = ts('Use a name and address, such as "Client Services" <services@example.org>.');
$x = ts('This information is <strong>very important</strong>.');
$x = ts('<p>First paragraph.</p><p>Second paragraph.</p>');
$x = ts('Remove these groups: <ul><li>%1</li></ul>', [1 => $groups]);
$x = '<p>' . ts('First paragraph.') . '</p><p>' . ts('Second paragraph.') . '</p>';

// ts() strings contain words.
$x = ts('%1 %2 %3', [1 => $field, 2 => $op, 3 => $value]);
$x = ts('%1', [1 => $label]);
$x = ts('5');
$x = ts('%1: %2', [1 => $label, 2 => $value]);
$x = ts('"%1"', [1 => $label]);
$x = ts('Page %1 of %2', [1 => $page, 2 => $pages]);

// The Smarty {ts} block plugin passes its content through.
function smarty_block_ts($params, $text, &$smarty) {
  return ts($text, $params);
}

// Interpolated strings and variables never reach the translation template.
$x = ts("Shutdown Worker for {$queueName}");
$x = E::ts($label);

// An element named in a sentence is text, and an HTML comment around ts() is markup.
$x = ts('Displayed in <div> at top of the section.');
$x = '<div><!-- ' . ts('This content comes from a token') . '--></div>';
