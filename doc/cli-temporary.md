# CLI Setup: Temporary

Buildkit includes specific versions of some fairly popular tools (such as
`drush`, `phpunit`, and `wp-cli`), and it's possible that you have already
installed other versions of these tools.

By design, most of the buildkit tools can coexist with other versions, but
you must manually manage the `PATH`.  Whenever you wish to use buildkit, run
a command like, e.g.:

```bash
export PATH=/path/to/buildkit/bin:$PATH
```

To restore your normal `PATH`, simply close the terminal and open a new one.

Each time you open a new terminal while working on Civi development, you
would need to re-run the `export` command.
