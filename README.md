# Raspberry Pi Rust Cross-Compilation Tools

## Background

A cross-compilation environment for Raspberry Pi (Arm v7) designed to work with
[rust-embedded/cross](https://github.com/rust-embedded/cross) as maintained by the
[Rust Embedded Devices WG](https://github.com/rust-embedded/wg).

This project specializes the official ARM v7 Docker image to add libraries that are
useful for developing software for the Raspberry Pi.

## DEPRECATION

The whole purpose of this project was to provide a custom Docker image that `cross`
could then invoke during the cross-compilation for Raspberry Pi targets. However,
from `cross` [V0.2.2](https://github.com/cross-rs/cross/blob/main/CHANGELOG.md#v022---2022-06-24),
it has natively supported the [`target.{{TARGET}}.image`](https://github.com/cross-rs/cross/blob/main/README.md#dockerfiles)
key that means the specification of the necessary tooling can live within the project
that needs the custom Docker image.

Since each project probably has unique requirements that seems a much better pattern to
follow, rather than having to keep two projects in sync.

To import the scripts from this project into a Rust project using `cross` for the
Raspberry Pi, copy the `docker` folder into your project and then add the following to
your project's `cross.toml`:

``` toml
[target.armv7-unknown-linux-gnueabihf]
dockerfile = "./docker/Dockerfile.armv7-unknown-linux-gnueabihf.rpi"
```

There are no further plans to update this project beyond the current version.

## Supported targets

* armv7-unknown-linux-gnueabihf

  ARM v7 - second generation Raspberry Pi and later.

Currently only generates a container for executables dynamically linked against
[GNU libc](https://www.gnu.org/software/libc/).  Further work would be necessary to
generate the libraries needed for executables statically linked against
[MUSL libc](https://musl.libc.org/about.html).

## Supported libraries

The image currently adds support to the base image for:

* [RTIMULib as distributed with Raspbian](https://github.com/RPi-Distro/RTIMULib)
  
  Required to support the [Sense HAT](https://www.raspberrypi.org/products/sense-hat/)
  using, for example, the [sensehat-rs](https://crates.io/crates/sensehat) crate.

* Python 3.x

  Required to support compiling code that will use [PyO3](https://pyo3.rs/).

## Build instructions

### Interactive debugging

Uses [floki](https://metaswitch.github.io/floki/) so just invoke `floki`, which will
build the currently defined Docker image and launch an interactive shell in the
resulting container:

```console
$ cd docker
$ floki
Building ... 
<...snip...>
Specialized Rust Cross Compiler for Raspberry Pi (ARM v7) targets
# 
```

### Manual

Use the build script, specifying the semver tag (e.g. "0.1.2"):

```console
$ cd docker
$ ./build-cross-container-no-upload.sh <SEMVER VERSION>
Create solimike/cross-amd64 build container
        version: <SEMVER VERSION>
   architecture: amd64
  PARALLEL_MAKE: -j4
[+] Building 0.2s (10/10) FINISHED           
$ 
```

And then once you're happy with the operation of the container, push to Docker Hub:

```console
$ ./push-docker-image.sh
Password: 
Login Succeeded
The push refers to repository [docker.io/solimike/raspberry_cross]
ae61c6a2b875: Preparing 
<...snip...>
armv7-unknown-linux-gnueabihf-0.0.1: digest: sha256:7897e808af24e1dfec697ac27fb0d8d584bf7a4aa9ec93c5c65ea99c4ade186c size: 4922
$
```

### CI

TODO
