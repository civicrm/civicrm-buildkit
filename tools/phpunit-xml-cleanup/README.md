# phpunit-xml-cleanup

The name "JUnit XML" or "xUnit XML" sounds like a well-defined file format. How handy that so many testing tools use the same format!

They don't.

This repository contains quick-and-dirty hacks to ensure that the various XML outputs from Civi's test suite (eg `phpunit` and `karma`)
can be loaded consistently into Jenkins reports.

## Usage

```
git clone https://github.com/civicrm/phpunit-xml-cleanup/
cd phpunit-xml-cleanup/bin
./phpunit-xml-cleanup /tmp/xunit/*.xml
```

## Development

* Add new example input files to `examples/input`
* Add new example output files to `examples/expected`
* To see if the current code produces the expected output, run:
    ```
    ./scripts/run-tests.sh
    ```

## See also

* https://github.com/jenkinsci/xunit-plugin/tree/master/src/main/resources/org/jenkinsci/plugins/xunit/types
