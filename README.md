# pichi-vm/ubuntu

Ubuntu 26.04 LTS base image for Pichi, built by [`pichi.yaml`](pichi.yaml).
It combines an ext4 carapace, an Arma-produced PMI with Corium as its
initramfs, and the requirements for booting Ubuntu with `pichi run`.

## Build

Use a native Linux/KVM host with the `pichi` package (which depends on
`dillo-vm`) from [the Ubuntu PPA](https://launchpad.net/~nmccallum/+archive/ubuntu/pichi),
and 4096 available 2 MiB hugepages for the 8 GiB build VM. Pichi finds Dillo
beside itself or on `PATH`; `PICHI_DILLO` overrides discovery.
With a published Ubuntu tool image available:

```sh
pichi pull ghcr.io/pichi-vm/ubuntu:26.04
pichi build . --ref HEAD --memory 8192 \
  --build-image ghcr.io/pichi-vm/conglobate@sha256:a6c123d3b63d02282b89cb8c233e3c816f3c7644695d84d8e614096721405c6f \
  -t ghcr.io/pichi-vm/ubuntu:26.04
```

The build uses the committed image recipe. It installs the root filesystem
from Ubuntu packages and assembles the boot payload with `arma` and `corium`
from the PPA. Only the firmware stage installs these tools; the final root
filesystem remains the Ubuntu base system. This repo contains no package
specs, source submodules, or source compilation steps.

Ubuntu 26.04 supplies the required Linux 7.0 kernel. The virtual-machine
kernel package avoids unnecessary hardware firmware. Arma selects the
required modules and constructs the initramfs, so no bootloader is needed.
For ARM64, the firmware stage uses `objcopy` to extract the kernel from
Ubuntu's unified EFI image before passing it to Arma.
The root includes `mmdebstrap` so it can build the next image. Temporary
mounts cover `/run`, `/tmp`, and APT caches, preserving the package database
in `/var/lib/dpkg`.

## Initial bootstrap

Only if the registry has no prior Ubuntu image, prepare a minimal tool image
locally on each target architecture. This requires Ubuntu's `mmdebstrap`,
`ubuntu-keyring`, `e2fsprogs`, and Pichi. The temporary root contains only
enough Ubuntu userspace to run mmdebstrap; it is not the production image
and is not published.

```sh
bootstrap_dir=$(mktemp -d)
case "$(dpkg --print-architecture)" in
  amd64) mirror=http://archive.ubuntu.com/ubuntu ;;
  arm64) mirror=http://ports.ubuntu.com/ubuntu-ports ;;
esac
sudo mmdebstrap --variant=minbase --components=main,universe \
  --include=mmdebstrap,ca-certificates resolute "$bootstrap_dir/root" "$mirror"
sudo mkfs.ext4 -F -d "$bootstrap_dir/root" "$bootstrap_dir/bootstrap.raw" 1G
pichi import raw "$bootstrap_dir/bootstrap.raw" -t ghcr.io/pichi-vm/ubuntu:26.04
```

Then run the same `pichi build` command from the Build section, using this
cached input instead of pulling it. Build once on each native architecture
and export each result with `pichi save ghcr.io/pichi-vm/ubuntu:26.04 -o oci-amd64`
or `-o oci-arm64`. Copy both layouts to the publishing host. With GHCR write
authentication configured:

```sh
pichi load oci-amd64 --tag ubuntu:26.04-amd64
pichi load oci-arm64 --tag ubuntu:26.04-arm64
pichi manifest create ubuntu:26.04 ubuntu:26.04-amd64 ubuntu:26.04-arm64
pichi manifest annotate ubuntu:26.04 ubuntu:26.04-amd64 --os pichi --arch amd64
pichi manifest annotate ubuntu:26.04 ubuntu:26.04-arm64 --os pichi --arch arm64
pichi manifest push ubuntu:26.04 ghcr.io/pichi-vm/ubuntu:26.04
```

## CI

CI checks Conventional Commit messages, installs Pichi from the PPA,
pulls the existing Ubuntu image, and builds the new image **once per
architecture**. It has no bootstrap fallback: if the registry has no prior
image, perform the local procedure above first. Both builds transfer their
images as workflow artifacts. Only main publishes the combined
multi-architecture index after commit checking and both builds succeed;
PRs build without publishing.

The recipe marks its tool input `!bootstrap`, so it needs no `pichi.lock`.
The output manifest has `dev.pichi.build.bootstrapped=true`, identifying the
unlocked input boundary. Pichi resolves the cached input before replacing its
tag, so the produced image can serve as the next build's tool image.

## License

Repository tooling: Apache-2.0 (see [LICENSE](LICENSE)). The image content is
composed of Ubuntu packages under their respective upstream licenses and is
not covered by this repository's license.
