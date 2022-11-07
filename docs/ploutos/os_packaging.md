# Ploutos

**Contents:**
- [Introduction](#introduction)
- [Inputs](#inputs)
  - [Cargo.toml](#cargotoml)
  - [Workflow inputs](#workflow-inputs)
  - [Package build rules](#package-build-rules)
  - [Package test rules](#package-test-rules)
- [Outputs](#outputs)
- [How it works](#how-it-works)
  - [Pre-installed package](#pre-installed-packages)
  - [Special cases](#special-cases)

## Introduction

The Ploutos workflow can package your Rust Cargo application as one or both of the following common Linux O/S package formats:

| Format | Installers | Example Operating Systems |
|---|---|---|
| [DEB](https://en.wikipedia.org/wiki/Deb_(file_format)) | `apt`, `apt-get` | Debian & derivatives (e.g. Ubuntu) |
| [RPM](https://en.wikipedia.org/wiki/Rpm_(file_format)) | `yum`, `dnf` | RedHat, Fedora, CentOS & derivatives (e.g. Stream, Rocky Linux, Alma Linux) |

The `pkg` and `pkg-test` jobs of the Ploutos workflow package your Rust Cargo application into one or more of these formats, run some sanity checks on them and verify that they can be installed, uninstalled, and (optionally) upgraded, plus (if configured) can also run tests specific to your application on the installed package.

Binaries to be included in the package are either pre-compiled by the [`cross` job](./cross_compiling.md) of the Ploutos workflow, or compiled during the `pkg` job.

Packaging and, if needed, compilation, take place inside a Docker container. DEB packaging is handled by the [`cargo-deb` tool](https://crates.io/crates/cargo-deb). RPM packaging is handled by the [`cargo-generate-rpm` tool](https://github.com/cat-in-136/cargo-generate-rpm).

Package testing takes place inside [LXD container instances](https://linuxcontainers.org/lxd/docs/master/explanation/instances/) because, unlike Docker containers, they support systemd and other multi-process scenarios that you may wish to test.

_**Note:** DEB and RPM packages support many different metadata fields and the native DEB and RPM tooling has many capabilities. We support only the limited subset of capabilities that we have thus far needed. If you need something that it is not yet supported please request it by creating an issue at https://github.com/NLnetLabs/.github/issues/, PRs are also welcome!_

## Inputs

### Cargo.toml

Many of the settings that affect DEB and RPM packaging are taken from your `Cargo.toml` file by the [`cargo-deb`](https://github.com/kornelski/cargo-deb) and [`cargo-generate-rpm`](https://github.com/cat-in-136/cargo-generate-rpm) tools respectively. For more information read their respective documentation.

### Workflow inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `package_build_rules` | [matrix](./key_concepts_and_config.md#matrices) | Yes | See below.  |
| `package_test_rules` | [matrix](./key_concepts_and_config.md#matrices) | No | See below.  |
| `package_test_scripts_path` | string | No | The path to find scripts for running tests. Invoked scripts take a single argument: post-install or post-upgrade. |
| `deb_extra_build_packages` | string | No | A space separated set of additional Debian packages to install when (not cross) compiling. |
| `deb_maintainer` | string | No | The name and email address of the Debian package maintainers, e.g. `The NLnet Labs RPKI Team <rpki@nlnetlabs.nl>`. |
| `rpm_extra_build_packages` | string | No | A space separated set of additional RPM packages to install when (not cross) compiling. |
| `rpm_scriptlets_path` | string | No | The path to a TOML file defining one or more of pre_install_script, post_install_script and/or post_uninstall_script. |

### Package build rules

A rules [matrix](./key_concepts_and_config.md#matrices) with the following keys must be provided to guide the build process:

| Matrix Key | Required | Description |
|---|---|---|
| `pkg` | Yes | Used in various places. See below. |
| `image` | Yes | Specifies the Docker image used by GitHub Actions to run the job in which your application will be built (when not cross-compiled) and packaged. Has the form `<os_name>:<os_rel>` (e.g. `ubuntu:jammy`, `debian:buster`, `centos:7`, etc). Also see `os` below. |
| `target` | Yes | Should be `x86_64` If `x86_64` the Rust application will be compiled using `cargo-deb` (for DEB) or `cargo build` (for RPM) and stripped. Otherwise it will be used to determine the correct cross-compiled binary GitHub Actions artifact to download. |
| `os` | No | Overrides the value of `image` when determining `os_name` and `os_rel`.
| `extra_build_args` | No | A space separated set of additional command line arguments to pass to `cargo-deb`/`cargo build`.
| `rpm_systemd_service_unit_file` | No | Relative path to the systemd file, or files (if it ends with `*`) to use. Only needed when there are more than one file to avoid having to specify multiple almost duplicate `cargo-generate-rpm` `asset` tables in `Cargo.toml` just to select a different (set of) systemd service files. A single file will be copied to `target/rpm/<pkg>.service`. Multiple files will be copied to `target/rpm/` with their names unchanged. The `cargo-generate-rpm` `assets` table in `Cargo.toml` should reference the correct `target/rpm/` path(s). Note that there is no DEB equivalent as `cargo-deb` handles systemd file selection automatically based on factors like the "variant" to use. |

### Package test rules

TO DO

## Outputs

A [GitHub Actions artifact](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) will be attached to the workflow run with the name `<pkg>_<os_name>_<os_rel>_<target>`. The artifact will be a `zip` file, inside which will either be `generate-rpm/*.rpm` or `debian/*.deb`.

## How it works

The `pkg` and `pkg-test` workflow jobs will do a Git checkout of the repository that hosts the caller workflow.

### Pre-installed packages

Some limited base development tools are installed prior to Rust compilation to support cases where a native library must be built for a dependency.

Add more packages using the `deb_extra_build_packages` and `rpm_extra_build_packages` workflow inputs.

| `os_name` | Packages installed |
|---|---|
| `debian` or `ubuntu` | `binutils`, `build-essential` and `pkg-config` |
| `centos` | `Development Tools` |

### Special cases

- **Centos 8 EOL:** Per https://www.centos.org/centos-linux-eol/ _"content will be removed from our mirrors, and moved to vault.centos.org"_, thus if `image` is `centos:8` the `yum` configuration is adjusted to use the vault so that `yum` commands continue to work.
