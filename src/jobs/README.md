# Jenkins Job Scripts

## Prerequisites

* Run one of the bknix installers, such as `install-developer.sh`, `install-ci.sh`, or `install-runner.sh`.

## Usage

All scripts in this folder are designed to be run _either_ locally or in Jenkins. They must be executed with the wrapper script `run-bknix-job`.

For example:

```bash
## (Jenkins) Run the hello-world job with CiviCRM `max` profile
run-bknix-job max Hello

## (Local) Run the hello-world job with CiviCRM `max` profile
run-bknix-job --mock max Hello
```

Many jobs require some extra variables. For example, `CiviCRM-Core-Matrix` requires the variables `CIVIVER` and `SUITES`. In Jenkins, these
are inherited from the job configuration. In local execution, you need to specify them.

```bash
## (Jenkins) Run the CiviCRM-Core-Matrix job. Inherit CIVIVER and SUITES.
run-bknix-job max CiviCRM-Core-Matrix

## (Local) Run the CiviCRM-Core-Matrix job. Set CIVIVER and SUITES.
env CIVIVER=5.57 SUITES=phpunit-e2e \
  run-bknix-job --mock min CiviCRM-Core-Matrix
```

For details about extra variables, see the start of the `*.job` file.

## Guidelines

* Jobs _should_ begin with assertions about any required variables.
    * For example:
        * `assert_common WORKSPACE EXECUTOR_NUMBER CIVIVER`
        * `assert_regex '^[0-9a-z\.-]\+$' "$CIVIVER"`
        * `assert_regex '^\(\|https://github.com/civicrm/civicrm-[a-z]*/pull/[0-9]\+/*\)$' "$PATCH"`
    * If you are going to run a job locally, then skim the top for a list of expected variables.
* Jobs _should_ put outputs in the following standardized folders:
    * `$WORKSPACE/build/junit/`: JUnit XML reports
    * `$WORKSPACE/build/checkstyle/`: Checkstyle XML reports
    * `$WORKSPACE/build/dist/`: Binaries for redistribution
    * `$WORKSPACE/build/html/`: HTML-formatted reports
    * `$WORKSPACE/build/log/`: Basic text logs from subprocesses
    * (*Other layouts can be valid. They just might require more boilerplate/configuration.*)
* Place helper functions in `common.sh`. This file is automatically included with any job.

## Technical Details

* Bash scripts have a quirk - if you upgrade a file while it's executing, the active process may start looking at the new file.
  This is unusual and (IMHO) counter-productive (*as it often produces errors because the new script does not align with the old*).
  The `run-bknix-job` script employs a counter-measure -- when you execute a job, it copies to a temp file and runs that.

## Migration

Suppose you have a job `CiviCRM-Foo-Bar` in Jenkins and want to migrate the script. Steps:

* From https://test.civicrm.org/job/CiviCRM-Foo-Bar/configure, copy the existing shell script
* Create a file `src/jobs/CiviCRM-Foo-Bar.job`. Paste the script.
* At the top, add docblocks and assertions for any special environment variables. Common ones might be `CIVIVER`, `ghprbTargetBranch`, or `ghprbPullId`.
* Decide where/how to start the bknix environment. Add one of these near the top:
    * `use_bknix` (*load requested bknix profile*)
    * `use_bknix_tmp` (*as above; additionally, if required, it will transactionally start services in the background*)
* (*Optional, if amenable*) Convert to "standard" workspace layout
    * Near the top, add `init_std_workspace`
    * Remove anything that initializes or deletes folders for "junit", "checkstyle", "civibuild html", "build", "dist", or similar.
    * Add a call to `clean_legacy_workspace` for the old paths
    * Find any steps which generate data for these folders. Update them to use these locations: `$WORKSPACE_BUILD` `$WORKSPACE_JUNIT` `$WORKSPACE_HTML` `$WORKSPACE_LOG` `$WORKSPACE_DIST` `$WORKSPACE_CHECKSTYLE`
* Run the job locally. Check `/tmp/mock-workspace-$USER` to ensure that artifacts are placed correctly.
* Commit, push, deploy
* In https://test.civicrm.org/job/CiviCRM-Foo-Bar/configure, switch to the new script
    * The bash script should look like this:
        ```
        #!/bin/bash
        ## See https://github.com/civicrm/civicrm-buildkit/tree/master/src/jobs
        set -e
        if [ -e $HOME/.profile ]; then . $HOME/.profile; fi
        run-bknix-job "$BKPROF"
        exit $?
        ```
    * If you converted to "standard" workspace layout, then update any "Post-build Actions" to read from the standard locations, e.g.
        * `build/junit/`
        * `build/checkstyle/`
        * `build/dist/`
        * `build/html/`
        * `build/log/`
* Run the job via Jenkins. Check the artifacts.
