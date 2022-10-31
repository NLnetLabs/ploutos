# NLnet Labs Rust Cargo Packaging reusable workflow

## Cross-compiling

The `cross` cross-compiling job runs before the other jobs in the pkg workflow.

Cross compilation takes place inside a Docker container running an image from the Rust [`cross`](https://github.com/cross-rs/cross) project. These images contain the correct toolchain components needed to compile for one of the [supported targets](https://github.com/cross-rs/cross#supported-targets).

_**Known issue:** [Cross-compilation is not customisable](https://github.com/NLnetLabs/.github/issues/42)_

### Inputs

The `cross` job uses a single pkg workflow input, _either_:

- `cross_build_rules` - A **JSON** array of [Rust target triples](https://doc.rust-lang.org/nightly/rustc/platform-support.html) to cross-compile your application for, _or_
- `cross_build_rules_path` - A path to a **YAML** file equivalent of the `cross_build_rules` array.

YAML file example:

`pkg/rules/cross_build_rules.yml`:
```yaml
- 'arm-unknown-linux-musleabihf'
- 'arm-unknown-linux-gnueabihf'
```

### Outputs

The result of cross-compilation is a temporary artifact uploaded to GitHub Actions that will be downloaded by later jobs in the pkg workflow. This is because, as the GitHub Actions ["Storing workflow data as artifacts" docs](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) say, _"Artifacts allow you to share data between jobs in a workflow_".

In the example above this would cause temporary artifacts with the following names to be uploaded:

- `tmp-cross-binaries-arm-unknown-linux-gnueabihf`
- `tmp-cross-binaries-arm-unknown-linux-musleabihf`

While these are referred to as "temporary" artifacts (because they are not needed after the later jobs consume them) they are actually not deleted by the pkg workflow in case they are useful for debugging issues with the packaging process. GitHub Actions will anyway [delete workflow artifacts after 90 days by default](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts#about-workflow-artifacts).