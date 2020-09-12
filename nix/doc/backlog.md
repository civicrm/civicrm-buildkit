# master-loco backlog (disorganized notes)

For using `master-loco` in the `c.o`'s CI, the biggest outstanding issue is
support for systemd and use-bknix.  I've struggled to find a simple way to
revise `bin/install-ci.sh` to support this and I'm starting to get resigned
to the idea that `bin/install-{ci,common}.sh` and `bin/use-bknix` should be
reworked somewhat aggressively.

## bridging loco/systemd 

Note: There are a couple options for bridging loco+systemd:

1. For each service in `loco.yml`, generate a separate systemd unit. Map metadata from `loco.yml` into
   systemd metadata - so that the service is actually monitored by systemd (without using loco at runtime).
   The experimental command `loco export` aims to do this. Pro: This probaby has the best process-mgmt and logging.
   Con: Deploying updates is more fiddly (more services to add/update/remove/shutdown/restart/start).
2. For each service in `loco.yml`, generate a separate systemd unit. It should not do anything except
   call `loco run --cwd=<loco-prj> <the-target-service>`. The service is effectively monitored by `loco`,  but you 
   can start/stop via systemd.
3. For a given `loco.yml`, generate one systemd unit which calls `loco run` (to run everything).  Pro: It keeps the
   total# services lower.  If you make a change to `loco.yml`, the update to systemd is pretty simple.  Con: This gives
   probably the weakest process-mgmt/logging (b/c systemd does it better than loco).

## First cogent notion

One concept that I think could work... this revolves around the idea that each installed "profile" is actually a pair
of two things:

* `/nix/var/nix/profiles/bknix-OWNER-PROFILE` (binaries)
* `/etc/bknix-ci/use-bknix/OWNER/PROFILE.sh` (shell environment/configuration)

(The concept can probably work with any loco/systemd bridge technique, but I'll assume 3 because it's simpler and it helps
to have something concrete.)

When you call `use-bknix`, it basically just adds `/nix/var/nix/profiles/bknix-OWNER-PROFILE/bin` to the PATH
and loads `/etc/bknix-ci/use-bknix/OWNER/PROFILE.sh` to the environment.

```
        OWNER=USER
        PROFILE=$1

        if exists
                source /etc/bknix-ci/use-bknix/OWNER/PROFILE.sh
        else
                loco env --export --cwd=$HOME/bknix
                PRFDIR=...

        PATH=/nix/var/nix/profiles/bknix-OWNER-PROFILE/bin:...
        PS1=...
        source bashrc.local
```


When systemd starts or stops it a service, it calls `use-bknix` (to setup environment) and then `loco run [<svc>]` (within that environment).

The install process for CI (eg `bin/install-ci.sh`) would involve:

* Creating files in `bknix.get/installs/{jenkins,publisher}-{dfl,min,max,old,edge}.sh` with distinct combinations of `MYSQLD_PORT`, `REDIS_PORT`, `BKIT`, `HTTPD_VDROOT`, etc
* Having a utility `install_profile <name>`  (e.g. `install_profile jenkins-min`)  which
    * Consumes definitions from
        * `installs/OWNER-PROFILE.sh`
        * `profiles/PROFILE/default.nix`
    * Creates resoures at
        * `/home/OWNER/bknix-PROFILE                       git clone of buildkit`
        * `/nix/var/nix/profiles/bknix-OWNER-PROFILE       set of binaries`
        * `/etc/bknix-ci/use-bknix/OWNER/PROFILE.sh        set of env-vars which describe this profile`
        * `/etc/systemd/system/OWNER-PROFILE-SVC.service   set of systemd services`
     * Using pseudocode:
        * `as_owner (source $INSTALL_SH && git clone BKIT or git update BKIT && civi-download-tools)`
        * `as_root (source $INSTALL_SH && [ -d "$PRFDIR" ] && nix-env -p "$PRFDIR" -e '.*')`
        * `as_root (source $INSTALL_SH && nix-env -i -p "$PRFDIR" -f . -E "f: f.profiles.$PROFILE")`
        * `as_owner (source $INSTALL_SH && loco env) | as_root (write /etc/bknix-ci/use-bknix/OWNER/PROFILE.sh)`
        * `as_root (source $INSTALL_SH && make /etc/systemd/system/OWNER-PROFILE.service)`
        * ~~`as_root (source $INSTALL_SH && foreach SVC (make /etc/systemd/system/OWNER-PROFILE-SVC.service))`~~
* The `install-ci.sh` use-case is basically just a loop to call `install_profile <name>` over desired profiles.

Note: In this model, the `installs/OWNER-PROFILE.sh` is combined with `loco env` to produce a final environment, and this
environment is written out to disk.

## Other notions

* Cleanup `civicrm-buildkit.git` so that it can be used as pure-binary project, built+installed via nix. `/home/OWNER/bknix-PROFILE` is a pure-data folder.
* Find a way to move the shell-list from a separate file `/etc/bknix-ci/use-bknix/OWNER/PROFILE.sh` and into `/nix/var/nix/profiles/bknix-OWNER-PROFILE`.
* Instead of creating `installs/OWNER-PROFILE.sh`, figure a way to use `installs/OWNER-PROFILE.nix` and a shell-hook. Main trick is getting `use-bknix`
  to play along.
* Thoughtlet: `eval $(nix-shell -A min --run env)` as a technique to have use-bknix run on top of nix-shell? If that works, then maybe CI servers
  don't even need `/nix/var/nix/profiles/FOO`? (The `env` command didn't properly escape some data in a quick test... but it can't be too hard to
  write a similar command that does escape properly.)
* `nix-shell` has special `#!` support. I tried using this in Jenkins originally and wound up with `eval $(use-bknix)`, but it is sufficiently appealing 
  to merit another look. (Maybe the problem was with Jenkins-SSH skipping `.bashrc` and lacking `nix-shell` at outset?)

## Second notion (not yet cogent)

Definitions are stored as:

* `civicrm-buildkit.git`
    * `default.nix` installs everything in `/nix/store`; takes `{ php, mysql }` (etc) as input vars
    * when using that, an env-var can redirect most of the `app/*` and `build/*` stuff.
* `bknix.git`
    * `installs/OWNER-PROFILE.nix` (set `REDIS_PORT` etc; also set env-var for buildkit's `app/*` and `build/*`)
    * `profiles/PROFILE.nix` (as today; also import `buildkit` and pass in our preferred php/mysql/etc)
    * `pkgs/...` (as today)
    * `pins/...` (as today)

`nix-shell -f installs/OWNER-PROFILE` loads a shell with `profiles/PROFILE` and plus env overrides (`REDIS_PORT`, etc) plus `loco env`

`eval $(nix-shell ... --run shell-invert)` exports env vars for use in current shell

`use-bknix PROFILE -e` is short-cut for `nix-shell -f installs/OWNER-PROFILE --run shell-invert`

`use-bknix PROFILE -s` is short-cut for `nix-shell -f installs/OWNER-PROFILE`

When installing `use-bknix`, substitute in absolute path to bknix.git (e.g. `/opt/bknix` or `/srv/bknix`)

`systemd` script is `eval $(use-bknix PROFILE) && loco run`
