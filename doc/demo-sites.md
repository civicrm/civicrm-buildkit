## Experimental: Multiple demo/training sites

When creating a batch of identical sites for training or demonstrations,
one may want to create a single source-code-build with several
databases/websites running on top (using "Drupal multi-site"). To install
extra sites,  use the notation "civibuild create buildname/site-id" as in:

```bash
## Create the original build
civibuild create training --type drupal-demo --civi-ver 4.5 --url http://demo00.example.org --admin-pass s3cr3t

## Create additional sites (01 - 03)
civibuild create training/01 --url http://demo01.example.org --admin-pass s3cr3t
civibuild create training/02 --url http://demo02.example.org --admin-pass s3cr3t
civibuild create training/03 --url http://demo03.example.org --admin-pass s3cr3t

## Alternatively, create additional sites (01 - 20)
for num in $(seq -w 1 20) ; do
  civibuild create training/${num} --url http://demo${num}.example.org --admin-pass s3cr3t
done
```
