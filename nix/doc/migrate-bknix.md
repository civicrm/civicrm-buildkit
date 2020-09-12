# bknix migration (June 2020)

The `bknix.git` is being merged into `civicrm-buildkit.git`. If you installed a previous version 
of `bknix.git`, then you need to reconfigure the folder based on `civicrm-buildkit.git`.

You could destroy+recreate everything...  but if you have any existing
builds, it's preferrable to migrate.

__Before migration:__

```
~/bknix                    This is a copy of 'bknix.git'
~/bknix/civicrm-buildkit   This is a copy of `civicrm-buildkit.git'
~/bknix/build              This is a collection of local builds
~/bknix/.loco/var.keep     This has some metadata about the local buidls
```

__After migration:__

```
~/bknix.bak                This is an old copy of `bknix.git` which is no longer needed.
~/bknix                    This is a copy of `civicrm-buildkit.git'
~/bknix/build              This is a collection of local builds
~/bknix/.loco/var.keep     This has some metadata about the local buidls
```

## Step 1: Make sure any pending work is saved

As a precaution, make sure any pending work in the `build` folder is saved.
You might, eg, use `git scan` to find repos with uncommitted changes:

```
cd ~/bknix
git scan st
```

or to be more verbose:

```
git scan st --status=all
```


As needed, use 'git commit' and 'git push' for unsaved work.

## Step 2: Shutdown loco

If `loco run` is active, kill it (Ctrl-C).

Cleanup ramdisks/DBs/etc

```
loco clean -vv
```

## Step 3: Shutdown any other consumers

Close anything that might be using `~/bknix`, eg PHPStorm and bash
terminals.

Open a fresh terminal to continue working.

## Step 4: Make sure your bknix+buildkit repos are current

```
cd ~/bknix
git pull
cd civicrm-buildkit
git pull
```

## Step 5: Swap folders

Now, we want to promote `civicrm-buildkit` folder, replace the `bknix` folder, and retain the
data-folders (ie `~/bknix/build` and `~/bknix/.loco/var.keep`). The buildkit repo includes a
script do this (`swap-bknix-bkit.sh`).

On a local developer machine, run a command like:

```bash
cd ~
bash ~/bknix/civicrm-buildkit/nix/bin/swap-bknix-bkit.sh developer ~/bknix
```

> TIP: If the folder isn't literally `~/bknix`, then you'll need to update both arguments.

> TIP: For a pre-loco CI machine, change `developer` to `ci`.

The end result will be:

* `~/bknix` is working-copy of `civicrm-buildkit.git` (including nix files and everything else)
* `~/bknix/build` will retain its original data
* `~/bknix/.loco/var.keep` will retain its original data

## Step 6: Reinstall

If you have any profiles installed, update them.  On a dev workstation:

```bash
cd ~/bknix/nix
./bin/install-developer.sh
```