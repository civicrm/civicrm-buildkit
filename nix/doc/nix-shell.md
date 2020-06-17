# Use a profile in a temporary subshell (`nix-shell`)

(*This assumes that you have already [met the basic requirements](requirements.md).*)

In this tutorial, we'll start a new subshell with all of the packages for `dfl`.  The packages will only be visible within our
shell. This approaches has a few advantages/characteristics:

* It minimizes the impact on other parts of the workstation/server. You do not need to install any permanent system services.
* It is easier to juggle multiple profiles -- simply open different shells with different profiles.
* It uses an auto-download behavior: whenever you open a shell, it will re-read the configuration and automatically 
  download any missing or updated packages.

## Quick Version

This document can be summarized as a few small commands:

```
## Step 1. Download the configuration
me@localhost:~$ git clone https://github.com/totten/bknix

## Step 2. (Optional) Warmup with prebuilt binaries
me@localhost:~$ nix-env -iA cachix -f https://cachix.org/api/v1/install
me@localhost:~$ cachix use bknix

## Step 3. (Day-to-day) Open a subshell
me@localhost:~$ cd bknix
me@localhost:~/bknix$ nix-shell -A dfl
[nix-shell:~/bknix]$
```

The rest of this document explains these steps in more depth. If you already
understand them, then proceed to [bknix: General usage](usage-loco.md).

## Step 1. Download the configuration

The `bknix` repository stores some *metadata* -- basically, a list of required packages.  We download a copy via `git`:

```
git clone https://github.com/totten/bknix
```

This should be pretty quick.

## Step 2. (Optional) Warmup with prebuilt binaries

`nix` does the heavy lifting of downloading packages. It can download prebuilt binaries; and it can build new binaries
(from source); and all of this is automated and generally works without any special steps.

There's a small catch.  Installing prebuilt binaries is faster than building from source.  The official download server
(`cache.nixos.org`) only has binaries for official packages -- but not for our customized packages.  To get prebuilt
binaries for our customized packages, you can use the supplemental [cachix](https://cachix.org/) system.  This command downloads binaries
wherever they're available (official or supplemental servers).

```
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use bknix
```

## Step 3. (Day-to-day) Open a subshell

Whenever you want to work with `bknix`, navigate into its folder and run `nix-shell -A dfl`.

```
cd bknix
nix-shell -A dfl
```

Notice that the option `-A dfl` specifies the profile to use.

There's one other thing notice, but we'll need a more complete copy of the shell output to see it:

```
me@localhost:~$ cd bknix
me@localhost:~/bknix$ nix-shell -A dfl
[nix-shell:~/bknix]$
```

After running `nix-shell`, the command-prompt changes. This demonstrates that we're working in the new shell with a properly configured environment.

Once we know how to open a shell, we can proceed to [bknix: General usage](usage-loco.md).
