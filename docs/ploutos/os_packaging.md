# Ploutos

**Contents:**
- [Introduction](#introduction)
- [Example](#example)
- [Inputs](#inputs)
  - [Cargo.toml](#cargotoml)
  - [Workflow inputs](#workflow-inputs)
  - [Package build rules](#package-build-rules)
    - [Permitted `<image>` values](#permitted-image-values)
  - [Package test rules](#package-test-rules)
- [Outputs](#outputs)
- [How it works](#how-it-works)
  - [Build host pre-installed packages](#build-host-pre-installed-packages)
  - [Special cases](#special-cases)
  - [Install-time package dependencies](#install-time-package-dependencies)
  - [Custom handling of `Cargo.toml`](#custom-handling-of-cargotoml)
  - [Systemd units](#systemd-units)
    - [Target dependent unit files](#target-dependent-unit-files)

## Introduction

The Ploutos workflow can package your Rust Cargo application as one or both of the following common Linux O/S package formats:

| Format | Installers | Example Operating Systems |
|---|---|---|
| [DEB](https://en.wikipedia.org/wiki/Deb_(file_format)) | `apt`, `apt-get` | Debian & derivatives (e.g. Ubuntu) |
| [RPM](https://en.wikipedia.org/wiki/Rpm_(file_format)) | `yum`, `dnf` | RedHat, Fedora, CentOS & derivatives (e.g. Stream, Rocky Linux, Alma Linux) |

The `pkg` and `pkg-test` jobs of the Ploutos workflow package your Rust Cargo application into one or more of these formats, run some sanity checks on them and verify that they can be installed, uninstalled, and (optionally) upgraded, plus (if configured) can also run tests specific to your application on the installed package.

The set of files to include in the package are defined in `Cargo.toml`. Binaries to be included in the package are either pre-compiled by the [`cross` job](./cross_compiling.md) of the Ploutos workflow, or compiled during the `pkg` job.

Packaging and, if needed, compilation, take place inside a Docker container. DEB packaging is handled by the [`cargo-deb` tool](https://crates.io/crates/cargo-deb). RPM packaging is handled by the [`cargo-generate-rpm` tool](https://github.com/cat-in-136/cargo-generate-rpm).

Package testing takes place inside [LXD container instances](https://linuxcontainers.org/lxd/docs/master/explanation/instances/) because, unlike Docker containers, they support systemd and other multi-process scenarios that you may wish to test.

_**Note:** DEB and RPM packages support many different metadata fields and the native DEB and RPM tooling has many capabilities. We support only the limited subset of capabilities that we have thus far needed. If you need something that it is not yet supported please request it by creating an issue at https://github.com/NLnetLabs/.github/issues/, PRs are also welcome!_

## Example

_**Note: This example assumes have a GitHub account, that you are running on Linux, and that Rust, Cargo and git installed.**_

For the packaging process to work we need simple Hello World Cargo project to package, and a bare minimum of package metadata, let's create that and verify that it compiles and runs:

```shell
$ cargo new my_pkg_test
$ cd my_pkg_test
$ cat <<EOF >Cargo.toml
[package]
name = "pkg_hw_test"
version = "0.1.0"
edition = "2021"
authors = ["Example Author"]
EOF
$ cargo run
...
Hello, world!
```

Now let's add a minimal packaging workflow that will package our simple Rust application into a DEB package (because Ubuntu is a DEB based O/S).

```shell
$ mkdir -p .github/workflows
$ cat <<EOF >.github/workflows/pkg.yml
on:
  push:
  
jobs:
  package:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v3
    with:
      package_build_rules: |
        pkg: ["mytest"]
        image: ["ubuntu:jammy"]
        target: ["x86_64"]
      deb_maintainer: 'Build Bot <build.bot@example.com>'
```

Assuming that you have just created an empty GitHub repository, let's setup Git to push to it, add & commit the files we have created and push them to GitHub:

```shell
$ git remote add origin git@github.com:<YOUR_GH_USER>/<YOUR_GH_REPO>.git
$ git branch -M main
$ git add .github src/ Cargo.toml Cargo.lock
$ git commit -m "Initial commit."
$ git push -u origin main
```

Now browse to https://github.com/<YOUR_GH_USER>/<YOUR_GH_REPO>/actions and you should see the packaging action running. It will take a few minutes the first time as it is needs to install supporting tooling and then add it to the GH cache for quicker re-use on subsequent invocations.

When finished and successful the Summary page for the completed GitHub Actions run should have an Artifacts section at the bottom listing a single artifact, e.g. something like this:

```
Artifacts
Produced during runtime

Name                              Size
mytest_ubuntu_jammy_x86_64        121 KB
```

The artifact is a zip file that you can download and unzip, and inside is the DEB artifact that you can install, e.g.:

```shell
$ unzip mytest_ubuntu_jammy_x86_64.zip 
Archive:  mytest_ubuntu_jammy_x86_64.zip
   creating: debian/
  inflating: debian/pkg_hw_test_0.1.0-1jammy_amd64.deb 

$ cd debian/

$ apt show ./pkg_hw_test_0.1.0-1jammy_amd64.deb 
Package: pkg_hw_test
Version: 0.1.0-1jammy
Priority: optional
Maintainer: Example Author
Installed-Size: 326 kB
Depends: libc6 (>= 2.34)
Download-Size: 124 kB
APT-Sources: /tmp/pkg_hw_test_0.1.0-1jammy_amd64.deb
Description: [generated from Rust crate pkg_hw_test]

$ sudo apt install ./pkg_hw_test_0.1.0-1jammy_amd64.deb 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
Note, selecting 'pkg_hw_test' instead of './pkg_hw_test_0.1.0-1jammy_amd64.deb'
The following NEW packages will be installed:
  pkg_hw_test
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 0 B/124 kB of archives.
After this operation, 326 kB of additional disk space will be used.
Get:1 /tmp/pkg_hw_test_0.1.0-1jammy_amd64.deb pkg_hw_test amd64 0.1.0-1jammy [124 kB]
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package pkg_hw_test.
(Reading database ... 4395 files and directories currently installed.)
Preparing to unpack .../pkg_hw_test_0.1.0-1jammy_amd64.deb ...
Unpacking pkg_hw_test (0.1.0-1jammy) ...
Setting up pkg_hw_test (0.1.0-1jammy) ...

$ pkg_hw_test 
Hello, world!
```

## Inputs

### Cargo.toml

Many of the settings that affect DEB and RPM packaging are taken from your `Cargo.toml` file by the [`cargo-deb`](https://github.com/kornelski/cargo-deb) and [`cargo-generate-rpm`](https://github.com/cat-in-136/cargo-generate-rpm) tools respectively. For more information read their respective documentation.

### Workflow inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `package_build_rules` | [matrix](./key_concepts_and_config.md#matrix-rules) | Yes | Defines packages to build and how to build them. See below. |
| `package_test_rules` | [matrix](./key_concepts_and_config.md#matrix-rules) | No | Defines the packages to test and how to test them. See below.  |
| `package_test_scripts_path` | string | No | The path to find scripts for running tests. Invoked scripts take a single argument: post-install or post-upgrade. |
| `deb_extra_build_packages` | string | No | A space separated set of additional Debian packages to install in the build host when (not cross) compiling. |
| `deb_maintainer` | string | No* | The name and email address of the Debian package maintainers, e.g. `The NLnet Labs RPKI Team <rpki@nlnetlabs.nl>`. Required when packaging for a DEB based O/S in order to generate the required [`changelog`](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#changelog) file. |
| `rpm_extra_build_packages` | string | No | A space separated set of additional RPM packages to install in the build host when (not cross) compiling. |
| `rpm_scriptlets_path` | string | No | The path to a TOML file defining one or more of `pre_install_script`, `post_install_script` and/or `post_uninstall_script`. |

### Package build rules

A rules [matrix](./key_concepts_and_config.md#matrix-rules) with the following keys must be provided to guide the build process:

| Matrix Key | Required | Description |
|---|---|---|
| `pkg` | Yes | The package to build. Used in various places. See below. |
| `image` | Yes | Specifies the Docker image used by GitHub Actions to run the job in which your application will be built (when not cross-compiled) and packaged. The package type to build is implied by `<os_name>`, e.g. DEBs for Ubuntu and Debian, RPMs for CentOS Has the form `<os_name>:<os_rel>` (e.g. `ubuntu:jammy`, `debian:buster`, `centos:7`, etc). Also see `os` below.  |
| `target` | Yes | Should be `x86_64` If `x86_64` the Rust application will be compiled using `cargo-deb` (for DEB) or `cargo build` (for RPM) and stripped. Otherwise it will be used to determine the correct cross-compiled binary GitHub Actions artifact to download. |
| `os` | No | Overrides the value of `image` when determining `os_name` and `os_rel`. |
| `extra_build_args` | No | A space separated set of additional command line arguments to pass to `cargo-deb`/`cargo build`. |
| `rpm_systemd_service_unit_file` | No | Relative path to the systemd file, or files (if it ends with `*`) to inclde in an RPM package. See below for more info. |

#### Permitted `<image>` values

The `<image>` **MUST** be one of the following:

- `centos:<os_rel>` where `<os_rel>` is one of: `7` or `8`
- `debian:<os_rel>` where `<os_rel>` is one of: `stretch`, `buster` or `bullseye`
- `ubuntu:<os_rel>` where `<os_rel>` is one of: `xenial`, `bionic`, `focal` or `jammy`

Note the absence of RedHat, Fedora, Rocky Linux, Alma Linux, etc. which are all RPM compatible, and similarly no mention of other Debian derivatives such as Kali Linux or Raspbian.

You can in principle build your package inside an alternate DEB or RPM compatible Docker image by setting `<image>` appropriately to a Docker image that is natively DEB or RPM compatible, e.g `redhat/ubi8`, `fedora:37`, `rockylinux:8` or `kalilinux/kali-rolling`, but then you **MUST** set `<os>` to one of the supported `<image>` values in order to guide the packaging process to produce a DEB or RPM and to take into account known issues with certain releases (especially older ones).

It may not matter which O/S release the RPM or DEB package is built inside, except for example if your build process requires a dependency package that is only available in the package repositories of a particular O/S release, or if one O/S is known to bundle much newer or older versions of a dependency and that could impact your application, or if there is some other variation which matters in your case.

### Package test rules

A rules [matrix](./key_concepts_and_config.md#matrix-rules) with the following keys must be provided to guide the testing process:

| Matrix Key | Required | Description |
|---|---|---|
| `pkg` | Yes | The package to test. Must match the value used with `package_build_rules`.|
| `image` | Yes | Specifies the LXC `images:<os_name>/<os_rel>/cloud` image used for installing and testing the built package. See: https://images.linuxcontainers.org/. |
| `target` | Yes | The target the package was built for. Must match the value used with `package_build_rules`. |
| `mode` | Yes | One of: `fresh-install` or `upgrade-from-published` _(assumes a previous version is available in the default package repositories)_. |

## Outputs

A [GitHub Actions artifact](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) will be attached to the workflow run with the name `<pkg>_<os_name>_<os_rel>_<target>`. The artifact will be a `zip` file, inside which will either be `generate-rpm/*.rpm` or `debian/*.deb`.

## How it works

The `pkg` and `pkg-test` workflow jobs will do a Git checkout of the repository that hosts the caller workflow.

The `cargo-deb` and/or `cargo-generate-rpm` tools will be invoked to package (and if not cross-compiled, will also compile) your Rust application.

Post package creation `Lintian` (for DEBs) and `rpmlint` for (RPMs) will be invoked to report on any issues with the created archives. (note: Ploutos may continue even if errors are reported as these tools can be extremely strict and you may not need or want to resolve all issues they report).

### Build host pre-installed packages

Rust is installed from [rustup](https://rustup.rs/) using the [minimal profile](https://rust-lang.github.io/rustup/concepts/profiles.html).

Some limited base development tools are installed prior to Rust compilation to support cases where a native library must be built for a dependency.

| `os_name` | Packages installed |
|---|---|
| `debian` or `ubuntu` | `binutils`, `build-essential` and `pkg-config` |
| `centos` | `Development Tools` |

If needed you can cause more packages to be installed in the build host using the `deb_extra_build_packages` and/or `rpm_extra_build_packages` workflow inputs.
### Special cases

Ploutos is aware of certain cases that must be handled specially, for example:

- **CentOS 8 EOL:** Per https://www.centos.org/centos-linux-eol/ _"content will be removed from our mirrors, and moved to vault.centos.org"_, thus if `image` is `centos:8` the `yum` configuration is adjusted to use the vault so that `yum` commands continue to work.

- **LZMA and older O/S releases:** DEB and RPM packages created for Ubuntu Xenial and CentOS 7 respectively must not be compressed with LZMA otherwise the packaging tools fail with errors such as  _"malformed-deb-archive newer compressed control.tar.xz"_ (on Ubuntu, see [cargo-deb issue #12](https://github.com/kornelski/cargo-deb/issues/12) and _"cpio: Bad magic"_ (on CentOS, see [cargo-generate-rpm issue #30](https://github.com/cat-in-136/cargo-generate-rpm/issues/30)).

- **`unattended-upgrade` compatible DEB archives**: Ploutos works around [cargo-deb issue #47](https://github.com/kornelski/cargo-deb/issues/47) by unpacking and repacking the created DEB archive to ensure that data paths are `./` prefixed.

- **DEB changelog:** Debian archives are required to have a [`changelog`](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#changelog) in a very specific format. We generate a minimal file on the fly of the form:

  ```
  ${MATRIX_PKG} (${PKG_APP_VER}) unstable; urgency=medium
    * See: https://github.com/${{ env.GITHUB_REPOSITORY }}/releases/tag/v${APP_NEW_VER}changelog
   -- maintainer ${MAINTAINER}  ${RFC5322_TS}
  ```

  Where:
  - `${APP_NEW_VER}` is the value of the `version` key in `Cargo.toml`.
  - `${MAINTAINER}` is the value of the `<deb_maintainer>` workflow input.
  - `${MATRIX_PKG}` is the value of the `<pkg>` matrix key for the current permutation of the package build rules matrix being built.
  - `${PKG_APP_VER}` is the version of the application being built based on `version` in `Cargo.toml` but post-processed to handle things like [pre-releases](#./key_concepts_and_config#application-versions) or [next development versions](#./key_concepts_and_config#next-dev-version).
  - `${RFC5322_TS}` is set to the time now while building.

- **Support for "old" O/S releases:** For some "old" O/S releases it is known that the version of systemd that they support understands far fewer systemd unit file keys than more modern versions. In such cases (Ubuntu Xenial & Bionic, and Debian Stretch) the `cargo-deb` "variant" to use will be set to `minimal` if there exists a `[package.metadata.deb.variants.minimal]` TOML table in `Cargo.toml`. When cross-compiling the `minimal-cross` variant is looked for instead.

### Install-time package dependencies

Both DEB and RPM packages support the concept of other packages that should be installed in order to use our package. Both `cargo-deb` (via `$auto`) and `cargo-generate-rpm` (via `auto-req`) are able to determine needed shared libraries and the package that provides them and automagically adds such dependendencies to the created package. For cross-compiled binaries and/or for additional tools known to be needed (either by your application and/or its pre/post install scripts) you must specify such dependencies manually in `Cargo.toml`.

### Custom handling of `Cargo.toml`

Ploutos has some special behaviours regarding selection of the right `Cargo.toml` TOML table settings to use with `cargo-deb` and `cargo-generate-rpm`.

While both `cargo-deb` and `cargo-generate-rpm` take their core configuration from a combination of `Cargo.toml` `[package.metadata.XXX]` settings and command line arguments, and both support the notion of "variants" as a way to override and/or extend the settings defined in the `[package.metadata.XXX]` TOML table, "variant" support in `cargo-generate-rpm` is relatively new and not yet fully adoptd by Ploutos and neither tool supports defining packaging settings for more than one application in a single `Cargo.toml` file.

For DEB packaging, Ploutos will look for and instruct `cargo-deb` to use a variant named `<os_name>-<os_rel>` (or `<os_name>-<os_rel>-<target>` when cross-compiling) if it exists, and assuming that the `minimal` or `minimal-cross` profiles don't also exist and have not been chosen (see 'Support for "old" O/S releases' above).

For both DEB and RPM packaging, Ploutos has some limited support for defining packaging settings for more than one package in a single `Cargo.toml` file. If a `[package.metadata.deb_alt_base_<pkg>]` (for DEBs), or `[package.metadata.generate-rpm-alt-base-<pkg>]` (for RPMs), TOML table exists in `Cargo.toml` Ploutos will replace the proper `[package.metadata.deb]` or `[package.metadata.generate-rpm]` TOML table with the "alternate" table that was found.

### Systemd units

#### Target dependent unit files

When you need the unit file to include to depend on the target being packaged for, you need a way to specify which file to use.

For DEB packaging `cargo-deb` handles this automatically via its "variant" capability.

For RPM packaging no such equivalent functionality exists so you have to specify multiple separate "asset" tables in `Cargo.toml`, each almost a complete copy of the others with only the unit file being different. To avoid this duplication Ploutos can copy a chosen unit file or files to a "well-known" location which you can then reference in a single copy of the "assets" table.

A single file will be copied to `target/rpm/<pkg>.service`. Multiple files will be copied to `target/rpm/` with their names unchanged. The `cargo-generate-rpm` `assets` table in `Cargo.toml` should reference the correct `target/rpm/` path(s). This process is guided by the value of the `rpm_systemd_service_unit_file` matrix key.

