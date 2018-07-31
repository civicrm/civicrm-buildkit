ext-test
============


Usage
=====

```
ext-test build-run https://github.com/civicrm/org.civicrm.api4
```

Development: Build (PHAR)
=========================

If you are developing new changes to `ext-test` and want to create a new
build of `ext-test.phar` from source, you must have
[`git`](https://git-scm.com), [`composer`](https://getcomposer.org/), and
[`box`](http://box-project.github.io/box2/) installed.  Then run commands
like:

```
$ git clone https://FIXME/ext-test
$ cd ext-test
$ composer install
$ which box
/usr/local/bin/box
$ php -dphar.readonly=0 /usr/local/bin/box build
```
