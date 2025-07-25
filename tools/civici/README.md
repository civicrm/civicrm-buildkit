# civici

## Usage

```
# Generate a test site for a given extension SHA
civici ext:build --git-url=https://github.com/civicrm/org.civicrm.api4 \
  --rev=abcd1234 \
  --build=foobar \
  --build-root=/srv/buildkit/build

# Generate a test site for a given extension PR
civici ext:build --pr-url=https://github.com/civicrm/org.civicrm.api4/pull/123 \
  --build=foobar \
  --build-root=/srv/buildkit/build

# As above, but enable extra output and minimize downloads
env DEBUG=1 OFFLINE=1 PATH=$PWD/bin:$PATH \
  civici ext:build --pr-url=https://github.com/civicrm/org.civicrm.api4/pull/123 \
  --build=foobar \
  --build-root=/srv/buildkit/build

# Download dependencies for an extension (based on its current info.xml)
civici ext:dl-dep \
  --info=/srv/buildkit/build/dmaster/sites/all/modules/civicrm/ext/api4/info.xml \
  --feed='https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single' \
  --to=sites/all/modules/civicrm/ext

# Download dependencies for an extension (based on its name)
civici ext:dl-dep \
  --key=org.civicrm.api4
  --feed='https://civicrm.org/extdir/ver=5.3.0|cms=Drupal/single' \
  --to=sites/all/modules/civicrm/ext

# Run any tests in an extension
civici ext:test --info=/srv/buildkit/build/dmaster/sites/all/modules/civicrm/ext/api4/info.xml
```

## Requirements

* `cv`
* `civibuild`
