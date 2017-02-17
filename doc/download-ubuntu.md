# Download: Full Stack on New Ubuntu Host

If you have a new installation of Ubuntu 12.04 or 14.04, then you can download
everything -- buildkit and the system requirements -- with one command. This
command will install buildkit to `~/buildkit`:

```bash
curl -Ls https://civicrm.org/get-buildkit.sh | bash -s -- --full --dir ~/buildkit
```

Note:
 * When executing the above command, you should *not* run as `root`. However, you *should*
have `sudo` permissions.
 * The `--full` option is *very opinionated*; it specifically installs `php`, `apache`, and `mysql` (rather than `hvm`, `nginx`, `lighttpd`, or `percona`). If you try to mix `--full` with alternative systems, then expect conflicts.
 * If you use the Ubuntu feature for "encrypted home directories", then don't put buildkit in `~/buildkit`. Consider `/opt/buildkit`, `/srv/buildkit`, or some other location that remains available during reboot.
