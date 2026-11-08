<?php

// Correct usage.
$x = ts('Invalid group %1 found and disabled', [1 => $groupID]);
$x = E::ts('%1 of %2', array(1 => $a, 2 => $b));
$x = ts('%count item', ['count' => $n, 'plural' => '%count items']);
$x = ts('One item', ['count' => $n, 'plural' => '%1 of %count items', 1 => $total]);
$x = ts('Print HTML (%1)', [1 => 'DOMPDF']);
$x = ts('Saved', ['domain' => 'org.example', 'escape' => 'js']);
$x = ts('Hello %name', ['name' => $name]);
$x = ts('Dynamic %1', $params);
$x = ts('Computed %1', [$key => $value]);
$x = ts('Spread %1', [...$params]);
$x = ts('%1 %2', [1 => foo($a, $b), 2 => [3, 4]]);
$x = ts('Keep %1', ['raw' => TRUE]);
$x = ts('Keep %1', ['skip' => TRUE]);
$x = ts('%10 percent', [1 => $a]);
$x = ts('One', ['plural' => $plural, 'count' => $n, 1 => $total]);
$x = ts('%16', [0x10 => $a]);
$x = ts('%name', ["\x6eame" => $a]);
$x = ts('No placeholder');
$x = ts('Use a literal 5% here');

// SearchKit task messages are filled in by JavaScript.
$task = ['confirmMsg' => E::ts('Are you sure you want to delete %1 %2?')];

// Replacements passed to the enclosing call.
CRM_Core_Session::setStatus(ts('Invalid group %1 found and disabled'), [1 => $groupID]);
throw new CRM_Core_Exception(ts('%1 is not enabled'), array(1 => 'CiviPledge'));

// Unused replacements.
$x = ts('Unlimited', [1 => $remaining]);
$x = ts('% record found', [1 => 'Participant']);
$x = ts('Hello', ['name' => $name, 'count' => $n]);

// Placeholders without replacement.
$x = ts('%1 of %2', [1 => $a]);
$x = ts('%1 of %2', [1 => $a, ],);
$x = ts('%1', ['01' => $a]);
$waitingMsg = ts('A group of %1 participants');
$x = [ts('%1'), [1 => 'x']];

// Replacement without key.
$x = ts('Hello %1', [$name]);
$x = ts('%1', ['oops', $key => 'y']);

// Healthy: substituted later in the same scope, URL encoding, digit-led string keys.
function quotedList(array $items) {
  $template = ts('"%1"');
  return array_map(fn($item) => str_replace('%1', $item, $template), $items);
}
$x = ts('Apply URL encoding (e.g. "%26" or "%23").');
$x = ts('%01', ['01' => $a]);
$x = ts('%1foo', ['1foo' => $a]);

// Not substituted: falsy raw/skip, trailing comma, array() is not a call.
$x = ts('%1', ['raw' => FALSE]);
$x = ts('%1', ['skip' => 0]);
$x = ts('%1',);
$x = array(ts('%1'), [1 => 'x']);
function notSubstituted() {
  $message = ts('Group of %1');
  return $message;
}

class Test {

  public static function ts($text, $params = []) {
    return $text;
  }

}

// Methods named ts() on unrelated objects and classes are not translations.
$x = $obj->ts('Hello', [1 => $a]);
$x = Other::ts('%1');
$x = self::ts('%1 of %2', [1 => $a]);
// The civix helpers are translations.
$x = E::ts('Hello', [1 => $a]);
$x = CRM_Foo_ExtensionUtil::ts('%1');

// PHP continues an array after the largest integer key.
$x = ts('%1 and %2', [1 => $a, $b]);
$x = ts('%1', [1 => $a, $b]);
$x = ts('%1', [$a, $b]);

// URL encoding is no placeholder, a gap in the numbering is a missing one.
$x = ts('Visit /search?q=a%20b: %1', [1 => $label]);
$x = ts('Apply "%26" and %1', [1 => $label]);
$x = ts('%1 and %3', [1 => $a]);

// Healthy: PHP numbers an element after a computed key or spread from a value only known at runtime.
$x = ts('Contact %0: %1', [$key => $contactId, $displayName]);
$x = ts('Hello %1', [...$params, 'oops']);
