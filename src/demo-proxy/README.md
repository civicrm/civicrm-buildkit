# demo-proxy

### About

This is an HTTP reverse-proxy service for use in the demo environment (which has
multiple buildkits).

Example: Suppose the demo-proxy receives request for `http://FOOBAR.example.com`. Now...

* If `~/bknix/build/FOOBAR`      exists, then forward to `http://localhost:8001`.
* If `~/bknix-dfl/build/FOOBAR`  exists, then forward to `http://localhost:8001`.
* If `~/bknix-min/build/FOOBAR`  exists, then forward to `http://localhost:8002`.
* If `~/bknix-max/build/FOOBAR`  exists, then forward to `http://localhost:8003`.
* If `~/bknix-edge/build/FOOBAR` exists, then forward to `http://localhost:8007`.

### Usage

```
cd src/demo-proxy
nix-shell --run 'loco run'
```
