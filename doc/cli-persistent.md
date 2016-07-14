# CLI Setup: Persistent

It is useful to register buildkit in the `PATH`. This enables you to run commands
by entering a name (e.g.  `civix`) rather than a full path (e.g.
`/path/to/buildkit/bin/civix`).

If you want to ensure that these CLI tools are always available, then:

 1. Determine the location of your shell configuration file. This is usually `~/.bashrc`, `~/.bash_profile`, or `~/.profile`.
 2. At the end of the file, add `export PATH="/path/to/buildkit/bin:$PATH"` (*with proper adjustments to match your local system*).
 3. Close and reopen the terminal.
 4. Enter the command `which civibuild`. This should display a full-path. If nothing appears, then retry the steps.
