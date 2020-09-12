# Install all profiles for use by a single developer (<code>install-developer.sh</code>)</a>

(*This assumes that you have already [met the basic requirements](requirements.md).*)

The `install-developer.sh` script is optimized for a personal developer workstation (e.g.  macOS or Ubuntu).
It's tuned for the following assumptions:

* You are likely to need *periodic access* to different permutations of PHP, MySQL, etc. This allows one to investigate
  bug-reports that are version-specific.
* You don't need to *concurrently* use all services (php70+php71+php72+mysql54+mysql57+mysql80 ad nauseum).
  Supporting this would add complexity (more port-numbers, host-names, config-files, etc) and increase 
  resource-utilization.
* You need to integrate *third-party tooling* - such as an IDE - with the chosen environment. This requires
  having a stable set of file locations.


## Quick Version

This document can be summarized as a few steps:

```
## Step 1. Download the configuration
me@localhost:~$ git clone https://github.com/totten/bknix

## Step 2. Download and install the binaries
me@localhost:~$ cd ~/bknix
me@localhost:~/bknix$ ./bin/install-developer.sh

## Step 3. (Day-to-day) Open a subshell
me@localhost:~$ use-bknix dfl -s
```

The rest of this document explains the steps in more depth.  If you
already understand them, then proceed to [Work with services and sites](usage-loco.md).

## Step 1. Download the configuration

First, we need to get a copy of `bknix` repository. This provides configuration files which list
the various packages/programs, and it provides some helper scripts to make use of them.

```bash
git clone https://github.com/totten/bknix.git
```

## Step 2. Download and install the binaries

Second, we download and install the actual binaries.

```
cd bknix
./bin/install-developer.sh
```

The `install-developer.sh` script will:

1. Enable [cachix](https://cachix.org/) to speed-up downloads/install process.
2. Install the binaries in a distinct folder. This is conceptually similar to creating a folder `/opt/<foo>/bin`,
   but `nix` specifies a longer path (`/nix/var/nix/profiles/per-user/$USER/bknix-$PROFILE/bin`).
3. Install a global helper command, `use-bknix`, under `/usr/local/bin`. This command is similar to `nix-shell` or `docker exec`;
   it opens a subshell and registers `/nix/var/nix/profiles/per-user/$USER/bknix-$PROFILE` in the `PATH`.

> __TIP__: By default, `install-developer.sh` will install 3 profiles: `min max dfl`.
> Optionally, you may give a list of different profiles using the `PROFILES` variable, e.g.
>
> ```
> env PROFILES="max edge" ./bin/install-developer.sh
> ```

Once it's finished, you can inspect the list of binaries that were installed.  The `bin` folder contains symlinks for
all of the downloaded software.

```
$ ls /nix/var/nix/profiles/per-user/$USER/bknix-dfl/bin/
ab@            bzmore@                      git-receive-pack@    memcached@                   mysql_plugin@               mysqlimport@         redis-check-aof@     zip@
apachectl@     checkgid@                    git-shell@           my_print_defaults@           mysql_secure_installation@  mysqlpump@           redis-check-rdb@     zipcloak@
bknix@         curl@                        git-upload-archive@  myisam_ftdump@               mysql_ssl_rsa_setup@        mysqlshow@           redis-cli@           zipgrep@
bunzip2@       dbmmanage@                   git-upload-pack@     myisamchk@                   mysql_tzinfo_to_sql@        mysqlslap@           redis-sentinel@      zipinfo@
bzcat@         envvars@                     htcacheclean@        myisamlog@                   mysql_upgrade@              mysqltest@           redis-server@        zipnote@
bzcmp@         envvars-std@                 htdbm@               myisampack@                  mysqladmin@                 mysqltest_embedded@  replace@             zipsplit@
bzdiff@        fcgistarter@                 htdigest@            mysql@                       mysqlbinlog@                mysqlxtest@          resolve_stack_dump@  zlib_decompress@
bzegrep@       funzip@                      htpasswd@            mysql_client_test@           mysqlcheck@                 node@                resolveip@
bzfgrep@       git@                         httpd@               mysql_client_test_embedded@  mysqld@                     npm@                 rotatelogs@
bzgrep@        git-credential-netrc@        httxt2dbm@           mysql_config@                mysqld_multi@               perror@              rsync@
bzip2@         git-credential-osxkeychain@  innochecksum@        mysql_config_editor@         mysqld_safe@                php@                 tar@
bzip2recover@  git-cvsserver@               logresolve@          mysql_embedded@              mysqldump@                  php-fpm@             unzip@
bzless@        git-http-backend@            lz4_decompress@      mysql_install_db@            mysqldumpslow@              redis-benchmark@     unzipsfx@
```

## Step 3. (Day-to-day) Open a subshell

After downloading, the programs are available in `/nix/var/nix/profiles/per-user/$USER/bknix-dfl`, but they're not ready to use on the command line.

You need to setup the environment. The helper script `use-bknix` will open a subshell with a proper environment.

```
use-bknix dfl -s
```

In the example below, observe how we get access to a new version of `php`:

```
me@localhost:~/bknix$ which php
/usr/bin/php
me@localhost:~/bknix$ use-bknix dfl -s
[bknix-dfl:~/bknix] which php
/nix/var/nix/profiles/bknix-dfl/bin/php
```

Once we know how to open a shell with a well-configured environment, we can proceed to [Work with services and sites](usage-loco.md).

## TIP: IDEs and Environments

If you use a graphical IDE, you should be able to view and edit code without any special work.  However, if you want to
use the Nice Stuff (such as debugging), then the IDE needs to have the same environment configuration.  The details
will depend a lot on your how the IDE and OS's graphical-shell work. Here are a few approaches to consider:

* The primary job of `use-bknix` is to set environment variables. You can use it in a couple ways:
    * `use-bknix <PROFILE> -s`: This starts a new sub-shell and sets up the environment. If you type `exit`, it will go back to your original shell.
    * `eval $( use-bknix <PROFILE> )`: This keeps your existing shell and updates all the required environment variables.
* In some platforms, the OS's graphical-shell might respect `~/.profile`. If you want to always `bknix` available, you could edit the profile script and add `eval $( use-bknix <PROFILE> )`
* In some platforms, the OS's graphical-shell might have a similar-but-different file (like `.xsession` or `.xinitrc`?).
* In some platforms, the OS's graphical-shell might let you use a custom launch command -- have it setup the environment and then run the IDE.
* In some platforms, the OS's graphical-shell might give explicit options for managing the environment of each program. Use this to add `PATH` (and all the other variables from `bknix env`).
* In some platforms, the IDE might have its own settings for manipulating the environment and registering tools and paths.
