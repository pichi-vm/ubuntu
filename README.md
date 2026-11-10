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

## Hostname configuration

For a derived image with read-only `/etc`, set the hostname under
`image.boot.extend`:

```yaml
kernel.systemd.hostname: worker-01
```

Every instance of that image receives this name. This sets the guest hostname;
it does not configure DNS.

## CI and bootstrap

[CI](.github/workflows/ci.yml) builds once on each native architecture. It pulls
the published Ubuntu image. If the pull fails, it imports a minimal Ubuntu root
with mmdebstrap into Pichi's local cache under the same name, then runs the
production recipe. The temporary tool image is never published.

The recipe's `!bootstrap` input needs no lock file; its output manifest records
`dev.pichi.build.bootstrapped=true`. Only successful main builds publish the
combined image; pull requests do not publish.

## Help

Report problems in [Issues](https://github.com/pichi-vm/ubuntu/issues).

## Ubuntu modifications

This repository contains Pichi-specific modifications to Ubuntu.
Canonical’s license requires permission to redistribute this modified image.
Canonical has granted us that permission.

## License

This repository uses [Apache-2.0](LICENSE). Ubuntu packages retain their own
licenses.
