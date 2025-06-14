<?php
namespace Civici\Util;

class InfoXml {

  /**
   * @var string|null
   */
  public $key = NULL;

  /**
   * @var string|null
   */
  public $type = NULL;

  /**
   * @var string|null
   */
  public $name = NULL;

  /**
   * @var string|null
   */
  public $label = NULL;

  /**
   * @var string|null
   */
  public $file = NULL;

  /**
   * @var array
   *   Each item is a specification like:
   *   array('type'=>'psr4', 'namespace'=>'Foo\Bar', 'path'=>'/foo/bar').
   */
  public $classloader = [];

  /**
   * @var array
   *   Each item is they key-name of an extension required by this extension.
   */
  public $requires = [];

  /**
   * @var array
   *   List of expected mixins.
   *   Ex: ['civix@2.0.0']
   */
  public $mixins = [];

  /**
   * @var array
   *   List of strings (tag-names).
   */
  public $tags = [];

  /**
   * @var array
   *   List of authors.
   *   Ex: [0 => ['name' => 'Alice', 'email' => 'a@b', 'homepage' => 'https://example.com', 'role' => 'Person']]
   */
  public $authors = [];

  /**
   * @var array|null
   *   The current maintainer at time of publication.
   *   This is deprecated in favor of $authors.
   * @deprecated
   */
  public $maintainer = NULL;

  /**
   * @var string|null
   *  The name of a class which handles the install/upgrade lifecycle.
   * @see \CRM_Extension_Upgrader_Interface
   */
  public $upgrader = NULL;

  /**
   * @var array|null
   */
  public $civix;

  /**
   * @var string|null
   */
  public $comments;

  /**
   * @var array
   *   Ex: ['ver' => '5.50']
   */
  public $compatibility;

  /**
   * @var array
   *   Ex: ['ver' => '8.4']
   */
  public $php_compatibility;

  /**
   * @var array
   *   Ex: ['ver' => '5']
   */
  public $smarty_compatibility;

  /**
   * @var string|null
   */
  public $description;

  /**
   * @var string|null
   *   Ex: 'stable', 'alpha', 'beta'
   */
  public $develStage;

  /**
   * @var string|null
   *   Ex: 'ready', 'not_ready'
   */
  public $ready;

  /**
   * @var int|null
   *   Ex: 1234
   */
  public $usage;

  /**
   * Full URL of the zipball for this extension/version.
   *
   * This property is (usually) only provided on the feed of new/available extensions.
   *
   * @var string|null
   */
  public $downloadUrl;

  /**
   * @var string|null
   *   Ex: 'GPL-3.0'
   */
  public $license;

  /**
   * @var string|null
   *   Ex: '2025-01-02'
   */
  public $releaseDate;

  /**
   * @var array|null
   *   Ex: ['Documentation' => 'https://example.org/my-extension/docs']
   */
  public $urls;

  /**
   * @var string|null
   *   Ex: '1.2.3'
   */
  public $version;

  /**
   * @var array
   */
  public $typeInfo;

  /**
   * @var string
   */
  public $url;

  /**
   * @var string
   */
  public $category;

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
      throw new \Exception("Failed to parse info XML\n\n$string\n\n$error");
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
