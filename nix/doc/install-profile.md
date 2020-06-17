# nix-env: Install bknix to a profile folder

(*This document is WIP - needs to be re-tested and possibly to reflect some changes.
This is the most manual installer - it does not require any of the
install-scripts from `bknix.git`.*)

(*This assumes that you have already [met the basic requirements](requirements.md).*)

Let's use the `dfl` profile and install all its packages (PHP, MySQL, etc) to one folder (`/nix/var/nix/profiles/bknix-dfl`).

If you need to integrate with tools, workflows, or initialization systems that are not specifically aware of `nix` (such as a graphical IDE
or system-level process manager), this may be the most convenient arrangement. It feels a bit like installing an application suite under
`/opt/<foo>` except that the actual path is `/nix/var/nix/profiles/<foo>`.

## Quick Version

This document can be summarized as two steps (three commands):

```
## Step 1. Download the configuration
me@localhost:~$ git clone https://github.com/totten/bknix
me@localhost:~$ cd bknix

## Step 2. Download and install the binaries
me@localhost:~/bknix$ sudo -i
root@localhost:~$ nix-env -iA cachix -f https://cachix.org/api/v1/install
root@localhost:~$ cachix use bknix
root@localhost:~$ exit
me@localhost:~/bknix$ nix-env -i -f . -E 'f: f.profiles.dfl' -p /nix/var/nix/profiles/per-user/$USER/bknix-dfl

## Step 3. (Day-to-day) Open a subshell
me@localhost:~$ export PATH=/nix/var/nix/profiles/per-user/$USER/bknix-dfl/bin:$PATH; 
me@localhost:~$ eval $(bknix-profile env)
me@localhost:~$ eval $(loco env --cwd=$HOME/bknix)
```

The rest of this document explains these steps in more depth.  If you
already understand them, then proceed to [bknix: General usage](usage-loco.md).

## Step 1. Download the configuration

First, we need to get a copy of `bknix` repository. This provides configuration files which list
the various packages/programs, and it provides some helper scripts to make use of them.

```bash
git clone https://github.com/totten/bknix.git
```

## Step 2. Download and install the binaries

First, we enable a cache to improve installation time. (This step isn't strictly necessary,
but it will save a lot of time in compilation.)

```bash
sudo -i
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use bknix
```

The real work comes next - installing the binaries for the `dfl` profile:

```bash
nix-env -i \
  -f . -E 'f: f.profiles.dfl' \
  -p /nix/var/nix/profiles/per-user/$USER/bknix-dfl
```

Let's break down into a few parts:

* `nix-env -i` means *install packages to a live environment*
* `-f .` means *use the configuration files in the current folder* (`~/bknix`).
* `-E 'f: f.profiles.dfl'` means *evaluate the configuration file and return property `f.profiles.dfl` (the list of packages for `dfl`))*
* `-p /nix/var/nix/profiles/per-user/$USER/bknix-dfl` means *put the packages in a personalized profile folder, `bknix-dfl`*

The command may take some time when you first it -- it will need to download a combination of pre-compiled binaries and source-code. (It goes
faster when using pre-compiled binaries; if those aren't available, then it will download source-code and compile it.)

Once it's finished downloading, `nix-env` creates a `bin` folder with symlinks to all of the downloaded software.

```
$ ls /nix/var/nix/profiles/bknix-dfl/bin/
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

## Environment

After downloading, the programs are available in `/nix/var/nix/profiles/bknix-dfl` but their not ready to use on the command line.  You
need to setup the environment. First, we add binaries to our environment:

```bash
export PATH=/nix/var/nix/profiles/bknix-dfl/bin:$PATH
eval $(bknix-profile env)
```

This ensures that downloaded *commands* are available. Additionally, you need to set some environment
variables to ensure that each command *stores data in the appropriate folder*.

```bash
eval $(loco env --cwd=$HOME/bknix)
```

To ensure that the environment is configured in the future (when you open new shells or logout/login/reboot), add
both statements to your shell initialization script (`~/.profile` or `~/.bashrc`).

Once we know how to open a shell with a well-configured environment, we can proceed to [bknix: General usage](usage-loco.md).

## TIP: IDEs and Environments

If you use a graphical IDE, you should be able to view and edit code without any special work.  However, if you want to
use the Nice Stuff (such as debugging), then the IDE needs to have the same environment configuration.  The details
will depend a lot on your how the IDE and OS's graphical-shell work. Here are a few approaches to consider:

* In some platforms, the OS's graphical-shell might respect `~/.profile` -- which is great because everything else will pick up on this.
* In some platforms, the OS's graphical-shell might have a similar-but-different file (like `.xsession` or `.xinitrc`?).
* In some platforms, the OS's graphical-shell might let you use a custom launch command -- have it setup the environment and then run the IDE.
* In some platforms, the OS's graphical-shell might give explicit options for managing the environment of each program. Use this to add `PATH` (and all the other variables from `bknix env`).
* In some platforms, the IDE might have its own settings for manipulating the environment and registering tools and paths.
