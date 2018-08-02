civici
============


Usage
=====

```
civici build-run https://github.com/civicrm/org.civicrm.api4
```

Development: Build (PHAR)
=========================

If you are developing new changes to `civici` and want to create a new
build of `civici.phar` from source, you must have
[`git`](https://git-scm.com), [`composer`](https://getcomposer.org/), and
[`box`](http://box-project.github.io/box2/) installed.  Then run commands
like:

```
$ git clone https://FIXME/civici
$ cd civici
$ composer install
$ which box
/usr/local/bin/box
$ php -dphar.readonly=0 /usr/local/bin/box build
```
