# Ubuntu for Pichi

Ubuntu 26.04 LTS base image for [Pichi](https://github.com/pichi-vm/pichi),
available for **x86-64 and ARM64**.

**For Pichi development and testing only. Do not use this image in production.**

## Get the image

With [Pichi installed](https://launchpad.net/~nmccallum/+archive/ubuntu/pichi):

```sh
pichi pull ghcr.io/pichi-vm/ubuntu:26.04
```

Use `ghcr.io/pichi-vm/ubuntu:26.04` as the base in your image recipe.
See [Pichi’s build guide](https://github.com/pichi-vm/pichi/blob/main/BUILD.md)
to create your own image.

The build uses conglobate’s default temporary `/run` and `/tmp` mounts.
It explicitly disables the default `/var` mount to preserve dpkg’s installed
package database, while APT caches and package lists remain temporary.

## Help

Report problems in [Issues](https://github.com/pichi-vm/ubuntu/issues).

## Ubuntu modifications

This repository contains Pichi-specific modifications to Ubuntu.
Canonical’s license requires permission to redistribute this modified image.
Canonical has granted us that permission.

## License

This repository uses [Apache-2.0](LICENSE). Ubuntu packages retain their own
licenses.
