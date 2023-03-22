# worker-runnner-linux

This scripts directory installs worker-runner and a papertrail log destination on linux (assuming amd64)

## Inputs

* `WORKER_RUNNER_VERSION` - the version of worker-runner to install, defaulting to `$TASKCLUSTER_VERSION`
* `WORKER_RUNNER_RELEASE_FILE` - a filename on the image containing a worker-runner release to install; this overrides `WORKER_RUNNER_VERSION`.

### Secrets

* `/etc/taskcluster/secrets/worker_papertrail_dest` - the papertrail destination, of the form `logs17.papertrailapp.com:12345`

## Behaviors

* Download and install worker-runner at `/usr/local/bin/start-worker`
* Set up rsyslog to forward system logs to the papertrail destination configured in the secret described above

## Notes

### Installing a locally-built worker-runner

To install a version of worker-runner that you have built locally and has not been released:

* Put the `start-worker-linux-amd64` binary at `files/start-worker-linux-amd64`

* Set WORKER_RUNNER_RELEASE_FILE to `/start-worker-linux-amd64` in your builder (or in a copy of an existing builder)
  ```yaml
  builder_vars:
    env_vars:
      WORKER_RUNNER_RELEASE_FILE: /start-worker-linux-amd64
  ```

* Run the build as usual.
