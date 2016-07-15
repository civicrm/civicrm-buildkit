# PATH: Configure CLI support

Buildkit includes many CLI commands in the `bin/` folder.

You may execute the commands directly (e.g.  `./bin/civix` or `/path/to/buildkit/bin/civix`).  However, this would
become very cumbersome.  Instead, you should configure the shell's `PATH` to recognize these commands automatically.

> Tip: Throughout this document, we will provide examples which assume that buildkit was downloaded to
> `/path/to/buildkit`.  Be sure to adjust the examples to match your system.

## Persistently add buildkit to `PATH` (typical)

If you want to ensure that the buildkit CLI tools are always available, then:

 1. Determine the location of your shell configuration file. This is usually `~/.bashrc`, `~/.bash_profile`, or
`~/.profile`.
 2. At the end of the file, add `export PATH="/path/to/buildkit/bin:$PATH"`
 3. Close and reopen the terminal.
 4. Enter the command `which civibuild`. This should display a full-path. If nothing appears, then retry the steps.

## Temporarily switch shell configuration (advanced)

Buildkit includes specific versions of some fairly popular tools (such as `drush`, `phpunit`, and `wp-cli`), and it's
possible that you have already installed other versions of these tools.

By design, buildkit can coexist with other tools, but you must manually manage the `PATH`.
Whenever you wish to use buildkit, manually run a command like, e.g.:

```bash
export PATH=/path/to/buildkit/bin:$PATH
```

To restore your normal `PATH`, simply close the terminal and open a new one.

Each time you open a new terminal while working on Civi development, you would need to re-run the `export` command.
