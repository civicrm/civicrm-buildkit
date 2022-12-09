# buildkit: pogo scripts

### Example

Suppose we have a small script named `snafu`. This would have a few files:

* `bin/snafu` is the entry-point. It is a thin bash script.
* `src/pogo/snafu.php` is the main source-code.
* `extern/snafu-phpX.Y` is a collection of auto-downloaded PHP libraries.

### Details

* Each script (`src/pogo/*.php`) is a separate tool with some small/distinct purpose.
* Each script may include PHP libraries using [pogo](https://github.com/totten/pogo/)'s `#!require` notation.
* The `bin/*` scripts are created by `civi-download-tools`.
    * It loops through each script `src/pogo/*.php` and makes the `bin/*` stubs.)
    * Wrappers are derived from `src/pogo/wrapper.sh`.
    * If you modify `wrapper.sh`, then you should re-run `civi-download-tools` (to re-create the stubs). 

__TIP__: If you use an IDE (and if your system supports symlinks), then open
`extern/snafu-phpX.Y` as the IDE project.  This will provide access to the
script (*symlinked*) as well as all PHP libraries.
