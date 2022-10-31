# NLnet Labs Rust Cargo Packaging reusable workflow

## O/S packaging

The pkg workflow can package your Rust Cargo application as one or both of the following common Linux O/S package formats:

| Format | Installers | Example Operating Systems |
|---|---|---|
| [DEB](https://en.wikipedia.org/wiki/Deb_(file_format)) | `apt`, `apt-get` | Debian & derivatives (e.g. Ubuntu) |
| [RPM](https://en.wikipedia.org/wiki/Rpm_(file_format)) | `yum`, `dnf` | RedHat, CentOS & derivatives (e.g. Stream, Rocky Linux, Alma Linux) & Fedora |

The `pkg` and `pkg-test` jobs of the pkg workflow package your Rust Cargo application into one or more of these formats, run some sanity checks on them and verify that they can be installed, uninstalled, and (optionally) upgraded, plus (if configured) can also run tests specific to your application on the installed package.

Binaries to be included in the package are either pre-compiled by the [`cross` job](./cross_compiling.md) of the pkg workflow, or compiled during the `pkg` job.

Packaging and, if needed, compilation, take place inside a Docker container. DEB packaging is handled by the [`cargo-deb` tool](https://crates.io/crates/cargo-deb). RPM packaging is handled by the [`cargo-generate-rpm` tool](https://github.com/cat-in-136/cargo-generate-rpm). Both tools take their configuration from your `Cargo.toml` file.

Package testing takes place inside [LXD container instances](https://linuxcontainers.org/lxd/docs/master/explanation/instances/) because, unlike Docker containers, they support systemd and other multi-process scenarios that you may wish to test.

### Inputs

Inputs to the pkg workflow common to all package types are:

TODO

Inputs to the pkg workflow specific to DEB packaging are:

TODO

Inputs to the pkg workflow specific to RPM packaging are:

TODO

### Outputs

TODO