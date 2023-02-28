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

* Jobs should begin with assertions about any special variables.
    * For example:
        * `assert_regex '^[0-9a-z\.-]\+$' "$CIVIVER"`
        * `assert_regex '^\(\|https://github.com/civicrm/civicrm-[a-z]*/pull/[0-9]\+/*\)$' "$PATCH"`
    * If you are going to run a job locally, then skim the top for a list of expected variables.
* Jobs should put outputs in the following folders:
    * `$WORKSPACE/junit/`: JUnit XML
    * `$WORKSPACE/html/`: HTML-formatted reports
    * `$WORKSPACE/dist/`: Binaries for redistribution
    * (*Todo: Extract helpers to handle cleanup/setup.*)
    * (*Todo: Change this to `build/junit`, `build/html`, `build/dist`*)
* Place helper functions in `common.sh`. This file is automatically included with any job.

## Technical Details

* Bash scripts have a quirk - if you upgrade a file while it's executing, the active process may start looking at the new file.
  This is unusual and (IMHO) counter-productive (*as it often produces errors because the new script does not align with the old*).
  The `run-bknix-job` script employs a counter-measure -- when you execute a job, it copies to a temp file and runs that.
