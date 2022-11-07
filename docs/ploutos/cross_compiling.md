# Ploutos: Cross-compiling

**Contents:**
- [Known issues](#known-issues)
- [Inputs](#inputs)
  - [Workflow inputs](#workflow-inputs)
  - [Cross build rules](#docker-build-rules)
- [Outputs](#outputs)
- [How it works](#how-it-works)
  - [Why is the cross tool used?](#why-is-the-cross-tool-used)

## Known issues

- [Cross-compilation is not customisable](https://github.com/NLnetLabs/.github/issues/42)

## Inputs

### Workflow inputs

| Input | Type | Required | Description |
|---|---|---|---|
| `cross_build_rules` | [matrix](./key_concepts_and_config.md#matrix-rules) | Yes | See below.  |

### Cross build rules

A rules [matrix](./key_concepts_and_config.md#matrix-rules) with the following keys must be provided to guide the build process:

| Matrix Key | Required | Description |
|---|---|---|
| `target` | Yes | A list of [Rust target triples](https://doc.rust-lang.org/nightly/rustc/platform-support.html) to cross-compile your application for. |

Example using an inline YAML string matrix definition:

```yaml
jobs:
  my_pkg_job:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v3
    with:
      cross_build_rules: |
        target:
          - arm-unknown-linux-musleabihf
          - arm-unknown-linux-gnueabihf
```

## Outputs

The result of cross-compilation is a temporary artifact uploaded to GitHub Actions that will be downloaded by later jobs in the Ploutos workflow. This is because, as the GitHub Actions ["Storing workflow data as artifacts" docs](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) say, _"Artifacts allow you to share data between jobs in a workflow_".

In the example above this would cause temporary artifacts with the following names to be uploaded:

- `tmp-cross-binaries-arm-unknown-linux-gnueabihf`
- `tmp-cross-binaries-arm-unknown-linux-musleabihf`

While these are referred to as "temporary" artifacts (because they are not needed after the later jobs consume them) they are actually not deleted by the Ploutos workflow in case they are useful for debugging issues with the packaging process. GitHub Actions will anyway [delete workflow artifacts after 90 days by default](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts#about-workflow-artifacts).

## How it works

The `docker` workflow job will do a Git checkout of the repository that hosts the caller workflow.

The `cross` cross-compiling job runs before the other jobs in the Ploutos workflow.

Cross compilation takes place inside a Docker container running on an x86_64 GH runner host using an image from the Rust [`cross`](https://github.com/cross-rs/cross) project. These images contain the correct toolchain components needed to compile for one of the [supported targets](https://github.com/cross-rs/cross#supported-targets).

### Why is the cross tool used?

Alternatives were explored but found lacking.

Docker buildx QEmu based cross-compilation for example is far too slow ([due to the emulated execution](https://github.com/multiarch/qemu-user-static/issues/176#issuecomment-1191078533)) and doesn't parallelize across multiple GitHub hosted runners.

Native Rust Cargo support for cross-compilation requires you to know more about the required toolchain, to install the required tools yourself including the appropriate strip tool, to add a `.cargo/config.toml` file to your project with the paths to the tools to use (which may vary by build environment!).

As a Rust project, the fact that the `cross` tool was originally developed by the Rust Embedded Working Group Tools team makes it highly attractive for our use case.