<?php

namespace Civici\Util;

use Civici\Util\Process as ProcessUtil;

class TargetParserTest extends \Civici\CiviciTestCase {

  public static function getExamples(): array {
    $exs = [];
    $exs[] = ['stable:org.example.foo', ['key' => 'org.example.foo', 'feed' => 'STABLE']];
    $exs[] = ['dev:org.example.foo', ['key' => 'org.example.foo', 'feed' => 'DEV']];
    $exs[] = ['git:https://example/foobar.git', ['git-url' => 'https://example/foobar.git']];
    $exs[] = ['hub:owner/project', ['git-url' => 'hub:owner/project']];
    $exs[] = ['lab:owner/project', ['git-url' => 'lab:owner/project']];
    return $exs;
  }

  /**
   * @param string $input
   * @param array $expected
   * @return void
   * @dataProvider getExamples
   */
  public function testParse(string $input, array $expected): void {
    $actual = (new TargetParser())->parse($input);
    $this->assertEquals($expected, $actual);
  }

}
