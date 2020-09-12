# Work with services and sites

Once you've downloaded the software packages, you can run the software and create new Civi sites.

## Quick Version

The highlights of this document can be summarized as a few steps:

```
## Step 1. Open a subshell
cd ~/bknix
nix-shell -A dfl
# ... or similarly: use-bknix dfl -s

## Step 2. (Optional) Configure the services
vi .loco/loco.yml

## Step 3. Run the services
loco run

## Step 4. Do developer-y stuff (New shell)
civibuild create dmaster
```

The rest of this document explains these steps in more depth. 

## Important Folders

* `~/bknix` - The location where you put the `bknix` repo.
* `~/bknix/build` - A workspace with various web-builds, git-repos, and such.
* `~/bknix/civicrm-buildkit` - A collection of PHP/JS/BASH tools like `civix`, `phpunit4`, `drush`, or `civibuild`
* `~/bknix/.loco/var` - Auto-generated configuration files (like `civibuild.conf`, `httpd.conf`, or `redis.conf`), PID files, log files, MySQL data, etc

## Step 1. Open a subshell

Before working with services and sites, you need to open a shell with a [profile](../README.md#profiles).
To open a shell with the `dfl` profile, you would typically run either:

* `nix-shell -A dfl`, or
* `use-bknix dfl -s`

The `nix-shell` command is appropriate if you followed the tutorial [Use a profile in a temporary subshell (`nix-shell`)](nix-shell.md).
Alternatively, the `use-bknix` command is appropriate if you followed the tutorial
[Install all profiles for use by a single developer (`install-developer.sh`)](install-developer.md).

## Step 2. (Optional) Configure the services

The file `.loco/loco.yml` contains some high-level configuration options. These are used
to generate some data-files and some configuration-files. You may wish to edit the file
before starting any services.

<!-- TODO:
* Setup default passwords for the admin and demo users.
    * Edit `civicrm-buildkit/app/civibuild.conf`
    * Set `ADMIN_PASS` and `DEMO_PASS`.
    * These will affect future builds.
* Setup wildcard DNS. (With wildcard DNS, your builds don't need to be registered in `/etc/hosts`, so this avoids `sudo` usage.)
    * Search Google for instructions for installing `dnsmasq` on your platform (e.g. `dnsmasq ubuntu` or `dnsmasq osx`).
    * Run `amp config:set --hosts_type=none`. (This tells `amp` that it doesn't need to do any special work setup DNS records.)
-->
<!-- * Set the PHP timezone in `config/php.ini`. -->
<!-- * Create `etc/bashrc.local` with some CLI customizations -->

(*Aside*: You can update these settings after initial setup, but some settings may require destroying/rebuilding.)

## Step 3. Run the services

The key command is `loco run`.  This will read `loco.yml`, auto-initialize data-files and configuration-files (if needed),
and start the corresponding services.

```
$ loco run
[VOLUME] Initialize folder: /Users/myuser/bknix/.loco/var
[[ Start ramdisk at "/Users/myuser/bknix/.loco/var" (600mb) ]]
> Create ramdevice (600mb)
> Format device (/dev/disk2)
Initialized /dev/rdisk2 as a 600 MB case-insensitive HFS Plus volume
> Mount (/Users/myuser/bknix/.loco/var)
[VOLUME] Service does not specify "run" option
[redis] Initialize folder: /Users/myuser/bknix/.loco/var/redis
[php-fpm] Initialize folder: /Users/myuser/bknix/.loco/var/php-fpm
[redis] Start service: redis-server --port "6380" --bind "127.0.0.1" --pidfile "/Users/myuser/bknix/.loco/var/redis/redis.pid" --dir "/Users/myuser/bknix/.loco/var/redis"

...

======================[ Startup Summary ]======================
[VOLUME] Loco data volume is a ram disk "/Users/myuser/bknix/.loco/var".
[redis] Redis is running on "127.0.0.1:6380".
[php-fpm] PHP-FPM is running on "127.0.0.1:9009"
[mailcatcher] Mailcatcher is running on "smtp://127.0.0.1:1025" and "http://127.0.0.1:1080"
[apache-vdr] Apache HTTPD is running at "http://127.0.0.1:8001" with content from "/Users/myuser/bknix/build".
[mysql] MySQL is running on "127.0.0.1:3307". The default credentials are user="root" and password="".
[buildkit] Buildkit (/Users/myuser/bknix/civicrm-buildkit) is configured to use these services. It produces builds in "/Users/myuser/bknix/build".

Services have been started. To shutdown, press Ctrl-C.
===============================================================
```

The services are running in the foreground -- additional errors and log messages will be displayed here. 

## Step 4. Do developer-y stuff

Once the services are running, you can open a new terminal with another subshell (`nix-shell...` or `use-bknix...`).
Now you have access to more interesting commands:

```
civibuild create -h
```

or

```
civibuild create dmaster
```

> TIP: If `civibuild` is missing, then the environment has probably not been setup correctly. Go back to the guidelines for
> [nix-shell](nix-shell.md), [install-developer.sh](install-developer.md), or [install-ci.sh](install-ci.md).

For more documentation on `civibuild`, see [Developer Guide: Tools: civibuild](https://docs.civicrm.org/dev/en/latest/tools/civibuild/).

## Cleanups, Shutdowns and Reboots

Eventually, you may need to shutdown or restart the services.  This works intuitively for most services; as mentioned
above, services will be stopped by simply pressing `Ctrl-C` in the console. You can restart the services by
calling `loco run` again.

The runtime data is stored in a ramdisk (`./.loco/var`). The data in this ramdisk can be destroyed either:

* _Explicitly_: Run `loco clean` to remove it and release memory promptly
* _Implicitly_: Whenever you shutdown or reboot the computer, the ramdisk is destroyed.

This begs a question: suppose that you're doing some work, that you reboot, and then you want to continue with work?

The first step should be intuitive: simply call `loco run` to start the services again.

But what about MySQL? The database content is not re-created. Fortunately, `civibuild` provides a few ways to get going again:

```
### (Option 1) Load a saved DB snapshot of dmaster.
civibuild restore dmaster

### (Option 2) Build a new DB and new settings files for dmaster.
civibuild reinstall dmaster
```
