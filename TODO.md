# TODO

- [ ] No separation of trusted/untrusted builders
- [x] docker-worker/generic-worker specific scripts should not be run on all builders
- [x] No process to install docker-worker yet
- [ ] Version of docker et al are not specified
- [ ] Figure out where the line is between scripts that provision files and files that get untarred onto the file system
- [ ] Consolidate variables to a globals / variables file where it makes sense
- [ ] Template builders via jinja2 to support arbitrary combinations of scripts
