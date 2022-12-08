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
* If you would like to edit `src/pogo/snafu.php` and get IDE auto-completion, then point your IDE to `extern/snafu-phpX.Y`
