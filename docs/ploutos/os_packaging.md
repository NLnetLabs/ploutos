# Ploutos

**Contents:**
- [O/S Packaging](#os-packaging)
- [Cargo.toml inputs](#cargotoml-inputs)
- [Workflow inputs](#workflow-inputs)

## O/S packaging

The Ploutos workflow can package your Rust Cargo application as one or both of the following common Linux O/S package formats:

| Format | Installers | Example Operating Systems |
|---|---|---|
| [DEB](https://en.wikipedia.org/wiki/Deb_(file_format)) | `apt`, `apt-get` | Debian & derivatives (e.g. Ubuntu) |
| [RPM](https://en.wikipedia.org/wiki/Rpm_(file_format)) | `yum`, `dnf` | RedHat, Fedora, CentOS & derivatives (e.g. Stream, Rocky Linux, Alma Linux) |

The `pkg` and `pkg-test` jobs of the Ploutos workflow package your Rust Cargo application into one or more of these formats, run some sanity checks on them and verify that they can be installed, uninstalled, and (optionally) upgraded, plus (if configured) can also run tests specific to your application on the installed package.

Binaries to be included in the package are either pre-compiled by the [`cross` job](./cross_compiling.md) of the Ploutos workflow, or compiled during the `pkg` job.

Packaging and, if needed, compilation, take place inside a Docker container. DEB packaging is handled by the [`cargo-deb` tool](https://crates.io/crates/cargo-deb). RPM packaging is handled by the [`cargo-generate-rpm` tool](https://github.com/cat-in-136/cargo-generate-rpm). Both tools take their configuration from your `Cargo.toml` file.

Package testing takes place inside [LXD container instances](https://linuxcontainers.org/lxd/docs/master/explanation/instances/) because, unlike Docker containers, they support systemd and other multi-process scenarios that you may wish to test.

_**Note:** DEB and RPM packages support many different metadata fields and the native DEB and RPM tooling has many capabilities. We support only the limited subset of capabilities that we have thus far needed. If you need something that it is not yet supported please request it by creating an issue at https://github.com/NLnetLabs/.github/issues/, PRs are also welcome!_

### Cargo.toml inputs

Many of the settings that affect DEB and RPM packaging are taken from your `Cargo.toml` file by the [`cargo-deb`](https://github.com/kornelski/cargo-deb) and [`cargo-generate-rpm`](https://github.com/cat-in-136/cargo-generate-rpm) tools respectively. For more information read their respective documentation.

### Workflow inputs

Note: The `pkg` and `pkg-test` workflow jobs will do a Git checkout of the repository that hosts the caller workflow.

| Input | Type | Package Type | Description |
|---|---|---|---|
| `package_build_rules` | string | All | See below. |
| `package_build_rules_path` | string | All | See below. |
| `package_test_rules` | string | All | See below. |
| `package_test_rules_path` | string | All | See below. |
| `package_test_scripts_path` | string | All | The path to find scripts for running tests. Invoked scripts take a single argument: post-install or post-upgrade. |
| `deb_extra_build_packages` | string | DEB | A space separated set of additional Debian packages to install when (not cross) compiling. |
| `deb_maintainer` | string | DEB | The name and email address of the Debian package maintainers, e.g. `The NLnet Labs RPKI Team <rpki@nlnetlabs.nl>`. |
| `rpm_extra_build_packages` | string | RPM | A space separated set of additional RPM packages to install when (not cross) compiling. |
| `rpm_scriptlets_path` | string | RPM | The path to a TOML file defining one or more of pre_install_script, post_install_script and/or post_uninstall_script. |

### Outputs

TODO
