<?php
namespace Civici\Util;

class InfoXml {

  public $key, $type, $file, $label, $requires, $urls, $classloader;

  /**
   * Load extension info a string.
   *
   * @param string $string
   *   XML content.
   *
   * @throws Exception
   * @return InfoXml
   */
  public static function loadFromString($string) {
    list ($xml, $error) = \Civici\Util\Xml::parse($string);
    if ($xml === FALSE) {
      throw new Exception("Failed to parse info XML\n\n$string\n\n$error");
    }

    $instance = new InfoXml();
    $instance->parse($xml);
    return $instance;
  }

  public function parse($xml) {
    $this->key = (string) $xml->attributes()->key;
    $this->type = (string) $xml->attributes()->type;
    $this->file = (string) $xml->file;
    $this->label = (string) $xml->name;

    $this->urls = array();
    $this->classloader = array();
    $this->requires = array();

    // Convert first level variables to CRM_Core_Extension properties
    // and deeper into arrays. An exception for URLS section, since
    // we want them in special format.
    foreach ($xml as $attr => $val) {
      if (count($val->children()) == 0) {
        $this->$attr = (string) $val;
      }
      elseif ($attr === 'urls') {
        foreach ($val->url as $url) {
          $urlAttr = (string) $url->attributes()->desc;
          $this->urls[$urlAttr] = (string) $url;
        }
        ksort($this->urls);
      }
      elseif ($attr === 'classloader') {
        foreach ($val->psr4 as $psr4) {
          $this->classloader[] = array(
            'type' => 'psr4',
            'prefix' => (string) $psr4->attributes()->prefix,
            'path' => (string) $psr4->attributes()->path,
          );
        }
      }
      elseif ($attr === 'requires') {
        foreach ($val->ext as $ext) {
          $this->requires[] = (string) $ext;
        }
      }
      else {
        // Ignore.
      }
    }
  }

}
