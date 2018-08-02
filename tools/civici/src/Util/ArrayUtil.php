<?php
namespace Civici\Util;

class ArrayUtil {
  public static  function collect($array, $index) {
    $result = array();
    foreach ($array as $item) {
      if (isset($item[$index])) {
        $result[] = $item[$index];
      }
    }
    return $result;
  }

}
