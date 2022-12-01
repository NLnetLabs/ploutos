# Ploutos: Cross-compiling

**Contents:**
- [Known issues](#known-issues)
- [Inputs](#inputs)
  - [Workflow inputs](#workflow-inputs)
- [Outputs](#outputs)
- [How it works](#how-it-works)
  - [Why is the cross tool used?](#why-is-the-cross-tool-used)

## Known issues

- [Cross-compilation is not customisable](https://github.com/NLnetLabs/.github/issues/42)

## Inputs

The set of targets to cross-compile for is automatically determined from the unique union of the `target` values supplied in the `docker_build_rules` and/or `package_build_rules` inputs.

### Workflow inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `cross_max_wait_mins` | string | No | The maximum number of minutes alowed for the `cross` job to complete the cross-compilation process and to upload the resulting binaries as workflow artifacts. After this permutations of the downstream `docker` and `pkg` workflow jobs will fail if the artifact has not yet become available to download. |

## Outputs

The result of cross-compilation is a temporary artifact uploaded to GitHub Actions that will be downloaded by later jobs in the Ploutos workflow. This is because, as the GitHub Actions ["Storing workflow data as artifacts" docs](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) say, _"Artifacts allow you to share data between jobs in a workflow_".

In the example above this would cause temporary artifacts with the following names to be uploaded:

- `tmp-cross-binaries-arm-unknown-linux-gnueabihf`
- `tmp-cross-binaries-arm-unknown-linux-musleabihf`

While these are referred to as "temporary" artifacts (because they are not needed after the later jobs consume them) they are actually not deleted by the Ploutos workflow in case they are useful for debugging issues with the packaging process. GitHub Actions will anyway [delete workflow artifacts after 90 days by default](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts#about-workflow-artifacts).

## How it works

The `cross` job runs in parallel to the `docker` and `pkg` jobs in the Ploutos workflow. Permutations of those jobs that need to use the cross-compiled binaries will wait `cross_max_wait_mins` minutes until the binary they need has been uploaded as a workflow artifact by the `cross` job.

Cross compilation takes place inside a Docker container running on an x86_64 GH runner host using an image from the Rust [`cross`](https://github.com/cross-rs/cross) project. These images contain the correct toolchain components needed to compile for one of the [supported targets](https://github.com/cross-rs/cross#supported-targets).

### Why is the cross tool used?

Alternatives were explored but found lacking.

`cargo-deb` supports cross-compilation [upto a point](https://github.com/kornelski/cargo-deb/issues/60#issuecomment-1333852148), `cargo-generate-rpm` does no compilation at all, so using `cargo-deb` cross support would be both incomplete and inconsistent with the approach required for RPMs.

Docker buildx QEmu based cross-compilation for example is far too slow ([due to the emulated execution](https://github.com/multiarch/qemu-user-static/issues/176#issuecomment-1191078533)) and doesn't parallelize across multiple GitHub hosted runners.

Native Rust Cargo support for cross-compilation requires you to know more about the required toolchain, to install the required tools yourself including the appropriate strip tool, set required environment variables, and to add a `.cargo/config.toml` file to your project with the paths to the tools to use (which may vary by build environment!).

As a Rust project, the fact that the `cross` tool was originally developed by the Rust Embedded Working Group Tools team makes it highly attractive for our use case.
