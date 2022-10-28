# NLnet Labs Rust Cargo Packaging **reusable** workflow

## Workflow inputs

Reusable workflows take a set of inputs which can be used to affect the behaviour of the workflow when run.

The most complex inputs take GitHub workflow matrices as input. Internally GitHub and the workflow work with these as [JSON](https://json.org/) objects and it is possible to construct and pass such JSON matrix objects to the workflow via its inputs (e.g. with the help of the GitHub [`fromJSON`](https://docs.github.com/en/actions/learn-github-actions/expressions#fromjson) and [`toJSON`](https://docs.github.com/en/actions/learn-github-actions/expressions#tojson) functions).

As a more readable and easier alternative the worfklow also supports loading matrices from [YAML](https://yaml.org/) files, i.e. you can express the matrix just as you would [natively in a workflow YAML file](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) - specifically the YAML content in the file will be used as the value of the `matrix` workflow key.

| Input | Notes | Docs |
| --- | --- | --- |
| `cross_build_rules` | A **JSON** array of [Rust target triples](https://doc.rust-lang.org/nightly/rustc/platform-support.html) to cross-compile your application for. Cross compilation takes place inside a Docker container running an image from the Rust [`cross`](https://github.com/cross-rs/cross) project. These images contain the correct toolchain components needed to compile for one of the [supported targets](https://github.com/cross-rs/cross#supported-targets). | [view](./cross_build_rules.md) |
| `cross_build_rules_path` | A relative path to a **YAML** file containing the `cross_build_rules` matrix. | [view](./cross_build_rules.md) |
| `package_build_rules` | A GitHub Actions **JSON** matrix definition that specifies which operating systems and versions packages should be created for. Currently only DEB and RPM packages can be created, using either x86_64 binaries compiled on-the-fly, or cross-compiled binaries compiled per the `cross_build_rules`. | |
| `package_build_rules_path` | A relative path to a **YAML** file containing the `package_build_rules` matrix. | |
| `package_test_rules` | A GitHub Actions **JSON** matrix definition that specifies which operating systems and versions provided test scripts should be run, and whether to run them post-install and/or post-upgrade. | |
| `package_test_rules_path` | A relative path to a **YAML** file containing the `package_test_rules` matrix. | |
| `docker_build_rules` | A GitHub Actions **JSON** matrix definition that specifies which platforms Docker images should be built for and whether to build the application image inside a Docker container or to copy in a cross-compiled binary that was compiled per the `cross_build_rules`. | |
| `docker_build_rules_path` | A relative path to a **YAML** file containing the `docker_build_rules` matrix. | |

For now the best way to understand these inputs is to look at the input descriptions in the workflow itself:

- https://github.com/NLnetLabs/.github/blob/main/.github/workflows/pkg-rust.yml#L131

And by looking at one of the places where the workflow is (or will soon be, used:

- https://github.com/NLnetLabs/.github-testing/blob/main/.github/workflows/pkg.yml
- https://github.com/NLnetLabs/routinator/blob/main/.github/workflows/pkg.yml
- https://github.com/NLnetLabs/rtrtr/blob/main/.github/workflows/pkg.yml
- https://github.com/NLnetLabs/krill/blob/main/.github/workflows/pkg.yml **COMING SOON**
- https://github.com/NLnetLabs/krill-sync/blob/main/.github/workflows/pkg.yml

To understand more about the history and design of the workflow read the comments at the top of the workflow itself:

- https://github.com/NLnetLabs/.github/blob/main/.github/workflows/pkg-rust.yml#L1
