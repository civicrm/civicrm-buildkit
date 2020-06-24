# Updating binary caches (cachix)

```
cd bknix
export CACHIX_SIGNING_KEY=...fixme...

## We need a list of items to publish. Not sure if one or all of these is best:
nix-build -E 'let p=import ./profiles; in builtins.attrValues p' | sort -u | cachix push bknix
nix-instantiate default.nix | sort -u | cachix push bknix
nix-store -r $( ( for PRF in old min dfl max edge; do nix-instantiate -A profiles.$PRF default.nix ; done ) | sort -u ) | cachix push bknix
```

# Updating binary caches (bknix.think.hm)

```
cd bknix/pkgs
nix-build
nix copy --to file://$HOME/nix-export -f default.nix
rsync -va --progress --ignore-existing $HOME/nix-export/./ myuser@myhost:/var/www/bknix/./
```
