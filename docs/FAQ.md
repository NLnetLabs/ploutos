# FAQ

- [What is Ploutos?](#what-is-plotos)
- [Why use Ploutos?](#why-use-ploutos)
- [Known issues](#known-issues)
- [Can I just run the Ploutos workflow?](#can-i-just-run-the-ploutos-workflow)
- [What packages can the Ploutos workflow produce?](#what-packages-can-the-ploutos-workflow-produce)
- [How can I run the created packages?](#how-can-i-run-the-created-packages)
- [How does it work?](#how-does-it-work)

## What is Ploutos?

Ploutos is a GitHub Actions reusable workflow that provides a thin, easy to use, wrapper around parallel invocation of tools such as cross, cargo-deb and cargo-generare-rpm to package and test your Rust application for your chosen combination of package formats, target cpu architectures and operating system flavours.

## Why use Ploutos?

Ploutos simplifies the creation of Debian, RPM and Docker packages for your Rust projects. You can call it in your project's workflow, by using [Github's reusable workflow feature](https://docs.github.com/en/actions/using-workflows/reusing-workflows). By reusing Ploutus, you can focus on the packaging specifics that matter for your project, instead of duplicating the foundation in every project.

## Known issues

The Ploutos workflow was originally written for use only by NLnet Labs. As such not all behaviours are yet (fully) configurable. With time, sufficient interest and resource permitting these limitations can in principle be removed. For a list of open issues and ideas for improvement and to submit your own see https://github.com/NLnetLabs/ploutos/issues/.

## Can I just run the Ploutos workflow?

No, it is not intended to be used standalone. To use it you must call it from your own GitHub Workflow. See the [official GitHub Actions documentation](https://docs.github.com/en/actions/using-workflows/reusing-workflows#calling-a-reusable-workflow) on calling reusable workflows for more information.

## What packages can the Ploutos workflow produce?

The Ploutos workflow is capable of producing Linux (DEB & RPM) packages and Docker images.

Produced DEB and RPM packages will be attached as artifacts to the caller workflow run. **Only GitHub users with `actions:read` permission** will be able to download the artifacts.

> The Ploutos workflow does **NOT** publish DEB and/or RPM packages anywhere. If you want your users to be able to download the produced DEB and/or RPM either directly or from a package repository using a tool like `apt` (for DEB) or `yum` (for RPM) you will need to upload the packages to the appropriate location yourself.

Produced Docker images can optionally be published to [Docker Hub](https://hub.docker.com/). In order for this to work you must configure the destination Docker Hub organisation, repository, username and password/access token and ensure that the used credentials provide write access to the relevant Docker Hub repository.

At NLnet Labs we publish produced DEB and RPM packages at https://packages.nlnetlabs.nl/ via an internal process that downloads the workflow run artifacts and signs & uploads them to the correct location, and Docker images are published by the Ploutos workflow to the appropriate repository under the https://hub.docker.com/r/nlnetlabs/ Docker organisation.

## How can I run the created packages?

Linux packages should be installed using the appropriate package manager (e.g. `apt` for DEB packages and `yum` for RPM packages).

Docker images can be run using the [`docker run`](https://docs.docker.com/engine/reference/commandline/run/) command.

## How does it work?

The Ploutos workflow is a GitHub Actions "reusable workflow" because it [defines](https://github.com/NLnetLabs/ploutos/blob/main/.github/workflows/pkg-rust.yml#L130) the `workflow_call` trigger and the set of inputs that must be provided in order to call the workflow. For an explanation of GitHub reusable workflows see the [official GitHub Actions documentation](https://docs.github.com/en/actions/using-workflows/reusing-workflows) on reusable workflows.

Once called the workflow runs one or more jobs like so:

```mermaid
flowchart LR
  prepare --> cross
  cross --> pkg --> pkg-test
  cross --> docker --> docker-manifest
  click cross href "https://github.com/NLnetLabs/ploutos/blob/main/docs/cross_compiling.md" "Cross-compilation"
  click pkg href "https://github.com/NLnetLabs/ploutos/blob/main/docs/os_packaging.md" "O/S Packaging"
  click pkg-test href "https://github.com/NLnetLabs/ploutos/blob/main/docs/os_package_testing.md" "O/S Package Testing"
  click docker href "https://github.com/NLnetLabs/ploutos/blob/main/docs/docker_packaging.md" "Docker Packaging"
  click docker-manifest href "https://github.com/NLnetLabs/ploutos/blob/main/docs/docker_multi_arch.md" "Docker Multi-Arch Packaging"
```

All of the jobs except `prepare` are matrix jobs, i.e. N instances of the job run in parallel where N is the number of relevant input matrix permutations.

Note that Git checkout is **NOT** done by the caller. Instead Ploutos checks out the source code at multiple different points in the workflow:

- In `prepare` to be able to load rule files from the checked out files.
- In `cross` to have the application files to build available on the GH runner.
- In `pkg` to have the application files to build available in the container.
- In `pkg-test` to have the test script to run available for copying into the LXC container.
- In `docker` to have the `Dockerfile` and Docker context files available for building.

Only the packaging types that you request (via the workflow call parameters) will actually be run, i.e. you can build only DEB packages, or only RPM and Docker, and cross-compile or not as needed.

- `prepare` - checks if the given inputs look roughly okay.
- [`cross`](./cross_compiling.md) - cross-compiles the Rust Cargo application if needed.
- [`pkg`](./os_packaging.md) - compiles (if not already cross-compiled) and packages the Rust Cargo application as a DEB or RPM package.
- [`pkg-test`](./os_packaging.md) - tests the produced DEB/RPM packages, both with some standard checks and optionally with application-specific checks provided by you.
- [`docker`](./docker_packaging.md) - builds and publishes one or more Docker images.
- [`docker-manifest`](./docker_packaging.md) - publishes a combined Docker Manifest that groups architecture specific variants of the same image under a single Docker tag.

The core parts of the workflow are not specific to GitHub but instead just invoke Rust ecosystem tools like [`cargo`](https://doc.rust-lang.org/cargo/), [`cross`](https://github.com/cross-rs/cross), [`cargo-deb`](https://github.com/kornelski/cargo-deb#readme) and [`cargo-generate-rpm`](https://github.com/cat-in-136/cargo-generate-rpm), and setup the correct conditions for invoking those tools, and the testing part invokes tools such as [`lxd` & `lxc`](https://linuxcontainers.org/), `apt` and `yum` which are also not GitHub specific. And of course there are the parts that invoke the `docker` command. The GitHub specific part is the pipeline that ties all these steps together and runs pieces in parallel and passes inputs in and outputs out.
