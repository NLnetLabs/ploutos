# Ploutos: Docker packaging

**Contents:**
- [Known issues](#known-issues)
- [Terminology](#terminology)
- [Inputs](#inputs)
  - [Workflow inputs](#workflow-inputs)
  - [Docker build rules](#docker-build-rules)
  - [Dockerfile build arguments](#dockerfile-build-arguments)
  - [Docker Hub secrets](#docker-hub-secrets)
- [Outputs](#outputs)
- [How it works](#how-it-works)
  - [Building](#building)
  - [Publication](#publication)
  - [Generated image names](#generated-image-names)

## Known issues

- [The Docker repository to publish to is not configurable](https://github.com/NLnetLabs/.github/issues/37)
- [Version number determination should be more robust](https://github.com/NLnetLabs/.github/issues/43)

## Terminology

Docker terminology regarding the location/identity of an image published to a registry (let's assume [Docker Hub](https://hub.docker.com/)) is a bit confusing. Dockers' own [official documentation](https://docs.docker.com/engine/reference/commandline/tag/) conflates the terms "image" and "tag". When configuring the Ploutos workflow we therefore use the following terminology:

```
# Using Docker Hub terminology, for a Docker image named nlnetlabs/krill:v0.1.2-arm64:
#   - The Organization would be 'nlnetlabs'.
#   - The Repository would be 'krill'.
#   - The Tag would be v0.1.2-arm64
# Collectively I refer to the combination of <org>/<repo>:<tag> as the 'image' name,
```

Source: https://github.com/NLnetLabs/.github/blob/main/.github/workflows/pkg-rust.yml

## Inputs

### Workflow inputs

**Note:** The `docker` workflow job will do a Git checkout of the repository that hosts the caller workflow.

| Input | Type | Required | Description |
|---|---|---|---|
| `docker_org` | string | Yes | E.g. `nlnetlabs`. |
| `docker_repo` | string | Yes | E.g. `krill`. |
| `docker_build_rules` | [matrix](./key_concepts_and_config.md#matrices) | Yes | See below.  |
| `docker_sanity_check_command` | string | No | A command to pass to `docker run`. If it returns a non-zero exit code it will cause the packaging workflow to fail. The command is intended to be a simple sanity check of the built image and should return quickly. It will only be run against images built for the x86_64 architecture as in order for `docker run` to work the image CPU architecture must match the host runner CPU architecture. As such when building images for non-x86_64 architectures it does **NOT** verify that ALL built images are sane. |
| `docker_file_path` | string | No | The path relative to the Git checkout to the `Dockerfile`. Defaults to `./Dockerfile.` |
| `docker_context_path` | string | No | The path relative to the Git checkout to use as the Docker context. Defaults to `.`. |

**Note:** There is no input for specifying the Docker tag because the tag is automatically determined based on the current Git branch/tag and architecture "shortname" (taken from the `docker_build_rules` matrix).

### Docker build rules

A rules [matrix](./key_concepts_and_config.md#matrices) with the following keys must be provided to guide the build process:

| Matrix Key | Required | Description |
|---|---|---|
| `platform` | Yes | Set the [target platform for the build](https://docs.docker.com/engine/reference/commandline/buildx_build/#platform), e.g. `linux/amd64`. See [^1], [^2] and [^3]. |
| `shortname` | Yes | Suffixes the tag of the architecture specific "manifest" image with this value, e.g. `amd64`. |
| `crosstarget` | No | Used to determine the correct cross-compiled binary GitHub Actions artifact to download. Only used when `mode` is `copy`. |
| `mode` | No | `copy` (for cross-compiled targets) or `build` (default). Passed through to the `Dockerfile` as build arg `MODE`. |
| `cargo_args` | No | Can be used when testing, e.g. set to `--no-default-features` to speed up the application build. Passed through to the Dockerfile as build arg `CARGO_ARGS`. |

[^1]: https://go.dev/doc/install/source#environment (from [^4])
[^2]: https://github.com/containerd/containerd/blob/v1.4.3/platforms/database.go#L83
[^3]: https://stackoverflow.com/a/70889505
[^4]: https://github.com/docker-library/official-images#architectures-other-than-amd64 (from [^5])
[^5]: https://docs.docker.com/desktop/multi-arch/

Example using an inline YAML string matrix definition:

```yaml
jobs:
  my_pkg_job:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v3
    with:
      docker_build_rules: |
        include:
          - platform: "linux/amd64"
            shortname: "amd64"
            mode: "build"

          - platform: "linux/arm/v6"
            shortname: "armv6"
            crosstarget: "arm-unknown-linux-musleabihf"
            mode: "copy"
```

### Dockerfile build arguments

The Ploutos workflow will invoke `docker buildx` passing [`--build-arg <varname>=<value>`](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) for the following custom build arguments.

The Docker context will be the root of a clone of the callers GitHub repository.

Your `Dockerfile` MUST define corresponding [`ARG <varname>[=<default value>]`](https://docs.docker.com/engine/reference/builder/#arg) instructions for these build arguments.

| Build Arg | Description |
|---|---|
| `MODE=build` | The `Dockerfile` should build the application from sources available in the Docker context. |
| `MODE=copy` | The pre-compiled binaries will be made available to the build process in subdirectory `dockerbin/$TARGETPLATFORM/*` of the Docker build context, where [`$TARGETPLATFORM`](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope) is a variable made available to the `Dockerfile` build process by Docker, e.g. `linux/amd64`. For an example see https://github.com/NLnetLabs/routinator/blob/v0.11.3/Dockerfile#L99. |
| `CARGO_ARGS=...` | Only relevant when `MODE` is `build`. Expected to be passed to the Cargo build process, e.g. `cargo build ... ${CARGO_ARGS}` or `cargo install ... ${CARGO_ARGS}`. For an example see https://github.com/NLnetLabs/routinator/blob/v0.11.3/Dockerfile#L92. |

## Docker Hub secrets

The Ploutos workflow supports two Docker specific secrets which can be passed to the workflow like so:

```yaml
jobs:
  full:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v3
    secrets:
      DOCKER_HUB_ID: ${{ secrets.YOUR_DOCKER_HUB_ID }}
      DOCKER_HUB_TOKEN: ${{ secrets.YOUR_DOCKER_HUB_TOKEN }}
```

Or, if you are willing to trust the packaging workflow with all of your secrets!!!

```yaml
jobs:
  full:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v3
    secrets: inherit
```

If either of the `DOCKER_HUB_ID` and/or `DOCKER_HUB_TOKEN` secrets are defined, the workflow `prepare` job will attempt to login to Docker Hub using these credentials and will fail the Ploutos workflow if it is unable to login.

Best practice is to use a separately created [Docker Hub access token](https://docs.docker.com/docker-hub/access-tokens/#create-an-access-token) for automation purposes that has minimal access rights. The Ploutos workflow needs write access but not delete access.

_**Note:** If neither of the `DOCKER_HUB_ID` and `DOCKER_HUB_TOKEN` secrets are defined then the Ploutos workflow will **NOT** atttempt to publish images to Docker Hub._

## Outputs

A [GitHub Actions artifact](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) will be attached to the workflow run with the name `tmp-docker-image-<shortname>`. The artifact will be a `zip` file, inside which will be a `tar` file called `docker-<shortname>-img.tar`. The `tar` file is the output of the [`docker save` command](https://docs.docker.com/engine/reference/commandline/save/) and can be loaded into a local Docker daemon using the [`docker load` command](https://docs.docker.com/engine/reference/commandline/load/).

If the required secrets are defined (see below), and the git ref is either the `main` branch or a `v*` tag, then the Docker image will be published to Docker Hub with the generated image name (see above).

## How it works

### Building

When using the [`cross` job](./cross_compiling.md) to cross-compile your application for different architectures you do not want to build the application again when building the Docker image from the `Dockerfile`.

You can direct the Ploutos workflow to use pre-cross-compiled binaries by setting the `mode` to `copy` instead of the default `build` in your `docker_build_rules(_path)` input matrix.

You must however make sure that your `Dockerfile` supports the build arguments that the Ploutos workflow will pass to it (see below).

### Publication

The Ploutos workflow is able to output built Docker images in three ways:

1. **Output Docker images as [GitHub Actions artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) attached to the workflow run** This can be useful for testing or manual distribution or if you don't (yet) have a Docker Hub login and/or access token.

2. **Publish Docker images to Docker Hub:** For the common single architecture case this is what you probably want.

3. **Publish [multi-arch Docker images](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/) AND a [Docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/) to Docker Hub:** This is useful when publishing the same image for multiple architectures to enable the end user to run the image without needing to specify the desired architecture.

### Generated image names

As stated above there is no way to manually control the tag given to the created Docker images. The images need to have distinct tags per architecture and per version/release type. For these reasons the workflow determines the tag itself. Possible tags that the workflow can generate are:

| Image Name | Archtecture Specific Tag | Multi-Arch Tag | Conditions |
|---|---|---|---|
| `<docker_org>/<docker_repo>` | `:vX.Y.Z-<shortname>` | `:vX.Y.Z` | No dash `-` in git ref |
| `<docker_org>/<docker_repo>` | `:unstable-<shortname>` | `:unstable` | Branch is `main` |
| `<docker_org>/<docker_repo>` | `:latest-<shortname>` | `:latest` | No dash `-` in git ref and not `main` |
| `<docker_org>/<docker_repo>` | `:test-<shortname>` | `:test` | Neither `main` nor `vX.Y.Z` tag |
