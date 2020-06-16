# docker-worker-linux

This scripts directory installs docker-worker

## Inputs

* `DOCKER_WORKER_VERSION` - the version of docker-worker to install, defaulting to `$TASKCLUSTER_VERSION`
* `DOCKER_WORKER_RELEASE_FILE` - a filename on the image containing a docker-worker release to install; this overrides `DOCKER_WORKER_VERSION`.
* `WORKER_RUNNER_PROVIDER` - the worker-runner provider implementation

## Behaviors

* Installs the latest docker from the `download.docker.com` Ubuntu repository and configures it to start on boot.
* Installs `docker-worker` and `worker-runner` along with a worker-runner config and a systemd unit to start them up.
* Sets up a script to run on boot that formats and initializes any instance-local storage (ephemeral disks).
  This script only works on AWS, and depends on finding `"tmpfsSize"` in the JSON blob in user data.

## Notes

### Installing a locally-built docker-worker

To install a version of docker-worker that you have built locally and has not been released:

* Put the docker-worker tarball at `files/docker-worker-x64.tgz`.

* Set DOCKER_WORKER_RELEASE_FILE to `/docker-worker-x64.tgz` in your builder (or in a copy of an existing builder)
  ```yaml
  builder_vars:
    env_vars:
      DOCKER_WORKER_RELEASE_FILE: /docker-worker-x64.tgz
  ```

* Run the build as usual.
