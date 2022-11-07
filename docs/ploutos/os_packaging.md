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
  - [Build host pre-installed packages](#build-host-pre-installed-packages)
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
| `package_build_rules` | [matrix](./key_concepts_and_config.md#matrix-rules) | Yes | See below.  |
| `package_test_rules` | [matrix](./key_concepts_and_config.md#matrix-rules) | No | See below.  |
| `package_test_scripts_path` | string | No | The path to find scripts for running tests. Invoked scripts take a single argument: post-install or post-upgrade. |
| `deb_extra_build_packages` | string | No | A space separated set of additional Debian packages to install in the build host when (not cross) compiling. |
| `deb_maintainer` | string | No | The name and email address of the Debian package maintainers, e.g. `The NLnet Labs RPKI Team <rpki@nlnetlabs.nl>`. Used when generating the required [`changelog`](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#changelog) file. |
| `rpm_extra_build_packages` | string | No | A space separated set of additional RPM packages to install in the build host when (not cross) compiling. |
| `rpm_scriptlets_path` | string | No | The path to a TOML file defining one or more of `pre_install_script`, `post_install_script` and/or `post_uninstall_script`. |

### Package build rules

A rules [matrix](./key_concepts_and_config.md#matrix-rules) with the following keys must be provided to guide the build process:

| Matrix Key | Required | Description |
|---|---|---|
| `pkg` | Yes | Used in various places. See below. |
| `image` | Yes | Specifies the Docker image used by GitHub Actions to run the job in which your application will be built (when not cross-compiled) and packaged. Has the form `<os_name>:<os_rel>` (e.g. `ubuntu:jammy`, `debian:buster`, `centos:7`, etc). Also see `os` below. |
| `target` | Yes | Should be `x86_64` If `x86_64` the Rust application will be compiled using `cargo-deb` (for DEB) or `cargo build` (for RPM) and stripped. Otherwise it will be used to determine the correct cross-compiled binary GitHub Actions artifact to download. |
| `os` | No | Overrides the value of `image` when determining `os_name` and `os_rel`.
| `extra_build_args` | No | A space separated set of additional command line arguments to pass to `cargo-deb`/`cargo build`.
| `rpm_systemd_service_unit_file` | No | Relative path to the systemd file, or files (if it ends with `*`) to inclde in an RPM package. See below for more info. |

### Package test rules

TO DO

## Outputs

A [GitHub Actions artifact](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) will be attached to the workflow run with the name `<pkg>_<os_name>_<os_rel>_<target>`. The artifact will be a `zip` file, inside which will either be `generate-rpm/*.rpm` or `debian/*.deb`.

## How it works

The `pkg` and `pkg-test` workflow jobs will do a Git checkout of the repository that hosts the caller workflow.

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

- **Centos 8 EOL:** Per https://www.centos.org/centos-linux-eol/ _"content will be removed from our mirrors, and moved to vault.centos.org"_, thus if `image` is `centos:8` the `yum` configuration is adjusted to use the vault so that `yum` commands continue to work.

- **DEB changelog:** Debian archives are required to have a [`changelog`](https://www.debian.org/doc/manuals/maint-guide/dreq.en.html#changelog) in a very specific format. We generate a minimal file on the fly of the form:

  ```
  ${MATRIX_PKG} (${PKG_APP_VER}) unstable; urgency=medium
    * See: https://github.com/${{ env.GITHUB_REPOSITORY }}/releases/tag/v${APP_NEW_VER}changelog
   -- maintainer ${MAINTAINER}  ${RFC5322_TS}
  ```

  Where:
  - `${MATRIX_PKG}` is the value of the `pkg` matrix key for the current permutation of the package build rules matrix being built.
  - `${PKG_APP_VER}` is the version of the application being built based on `version` in `Cargo.toml` but post-processed to handle things like [pre-releases](#./key_concepts_and_config#application-versions) or [next development versions](#./key_concepts_and_config#next-dev-version).
  - `${APP_NEW_VER}` is the literal value of the `version` field from `Cargo.toml`.
  - `${RFC5322_TS}` is set to the time now while building, 

- **Cargo.toml advanced re-use:** Via "variants" `cargo-deb` supports a single base set of properties in `Cargo.toml` which can be overriden by properties defined for a specified "variant". However, `cargo-deb` does not support multiple alternate base property sets. If we find that there exists a TOML table called `[package.metadata.deb_alt_base_${MATRIX_PKG}]` in `Cargo.toml` we replace the default `cargo-deb` property table `[package.metedata.deb]` TOML table with the alternate one we found.

- **Support for "old" systemd targets:** For some "old" O/S releases it is known that the version of systemd that they support understands far fewer systemd unit file keys than more modern versions. In such cases (Ubuntu Xenial & Bionic, and Debian Stretch) if there exists a `[package.metadata.deb.variants.minimal]` TOML table in `Cargo.toml` the `cargo-deb` "variant" to use will be set to `minimal`.

### Systemd units

#### Target dependent unit files

When you need the unit file to include to depend on the target being packaged for, you need a way to specify which file to use.

For DEB packaging `cargo-deb` handles this automatically via its "variant" capability.

For RPM packaging no such equivalent functionality exists so you have to specify multiple separate "asset" tables in `Cargo.toml`, each almost a complete copy of the others with only the unit file being different. To avoid this duplication Ploutos can copy a chosen unit file or files to a "well-known" location which you can then reference in a single copy of the "assets" table.

A single file will be copied to `target/rpm/<pkg>.service`. Multiple files will be copied to `target/rpm/` with their names unchanged. The `cargo-generate-rpm` `assets` table in `Cargo.toml` should reference the correct `target/rpm/` path(s). This process is guided by the value of the `rpm_systemd_service_unit_file` matrix key.

