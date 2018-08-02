# civici

## Usage

```
# Generate a test site for a given extension PR
civici extpr:create https://github.com/civicrm/org.civicrm.api4/pull/123 \
  --build=foobar \
  --build-root=/srv/buildkit/build

# As above, but enable extra output and minimize downloads
env DEBUG=1 OFFLINE=1 PATH=$PWD/bin:$PATH \
  civici extpr:create https://github.com/civicrm/org.civicrm.api4/pull/123 \
  --build=foobar \
  --build-root=/srv/buildkit/build

# Download dependencies for an extension
civici ext:dl-dep \
  --feed='https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single' \
  --info=/Users/totten/bknix/build/dmaster/sites/all/modules/civicrm/ext/api4/info.xml \
  --to=sites/all/modules/civicrm/ext

# Download dependencies for an extension
civici ext:dl-dep \
  --feed='https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single' \
  --key=org.civicrm.api4
  --to=sites/all/modules/civicrm/ext
```

## Requirements

* `cv`
* `civibuild`

## Development: Build (PHAR)

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
