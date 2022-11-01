# NLnet Labs Rust Cargo Packaging **reusable** workflow

## Docker packaging

**Contents:**
- [Known issues](#known-issues)
- [Outputs and publication](#outputs-and-publication)
- [Terminology](#terminology)
- [Docker stages, cross-compilation and build vs copy](#docker-stages-cross-compilation-and-build-vs-copy)
- [Docker related pkg workflow inputs](#docker-related-pkg-workflow-inputs)
- [Docker build rules matrix](#docker-build-rules-matrix)
- [Publication and Docker Hub secrets](#publication-and-docker-hub-secrets)
- [Dockerfile build arguments](#dockerfile-build-arguments)

### Known issues

- [The Docker repository to publish to is not configurable](https://github.com/NLnetLabs/.github/issues/37)
- [The Dockerfile to build is not configurable](https://github.com/NLnetLabs/.github/issues/36)

### Outputs and publication

The pkg workflow is able to output built Docker images in three ways:

1. **Output Docker images as [GitHub Actions artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) attached to the workflow run** This can be useful for testing or manual distribution or if you don't (yet) have a Docker Hub login and/or access token.

2. **Publish Docker images to Docker Hub:** For the common single architecture case this is what you probably want.

3. **Publish [multi-arch Docker images](https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/) AND a [Docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/) to Docker Hub:** This is useful when publishing the same image for multiple architectures to enable the end user to run the image without needing to specify the desired architecture.

### Terminology

Docker terminology regarding the location/identity of an image published to a registry (let's assume [Docker Hub](https://hub.docker.com/)) is a bit confusing. Dockers' own [official documentation](https://docs.docker.com/engine/reference/commandline/tag/) conflates the terms "image" and "tag". When configuring the pkg workflow we therefore use the following terminology:

```
# Using Docker Hub terminology, for a Docker image named nlnetlabs/krill:v0.1.2-arm64:
#   - The Organization would be 'nlnetlabs'.
#   - The Repository would be 'krill'.
#   - The Tag would be v0.1.2-arm64
# Collectively I refer to the combination of <org>/<repo>:<tag> as the 'image' name,
```

Source: https://github.com/NLnetLabs/.github/blob/main/.github/workflows/pkg-rust.yml

### Docker stages, cross-compilation and build vs copy

When using the [`cross` job](./cross_compiling.md) to cross-compile your application for different architectures you do not want to build the application again when building the Docker image from the `Dockerfile`.

You can direct the pkg workflow to use pre-cross-compiled binaries by setting the `mode` to `copy` instead of the default `build` in your `docker_build_rules(_path)` input matrix.

You must however make sure that your `Dockerfile` supports the build arguments that the pkg workflow will pass to it (see below).

### Docker related pkg workfow inputs

TODO

| Input | Type | Description |
|---|---|---|
| `docker_org` | string | E.g. `nlnetlabs`. |
| `docker_repo` | string | E.g. `krill`. |
| `docker_build_rules` | string | See below. |
| `docker_build_rules_path` | string | See below. |
| `docker_sanity_check_command` | string | A command to pass to `docker run`. If it returns a non-zero exit code it will cause the packaging workflow to fail. The command is intended to be a simple sanity check of the built image and should return quickly. It will only be run against images built for the x86_64 architecture as in order for `docker run` to work the image CPU architecture must match the host runner CPU architecture. As such when building images for non-x86_64 architectures it does **NOT** verify that ALL built images are sane. |

**Note:** There is no input for specifying the Docker tag because the tag is automatically determined based on the current Git branch/tag and architecture "shortname" (taken from the `docker_build_rules(_path)` matrix).

### Docker build rules matrix

A rules matrix must be provided to guide the build process. It can be provided in one of two forms:

- `docker_build_rules` - A **JSON** object in string form, _or_
- `docker_build_rules_path` - A path to a **YAML** file equivalent of the `cross_build_rules` JSON object.

The object is a [GitHub Actions build matrix](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) in which the following pkg workflow specific keys may be provided:

| Matrix Key | Description |
|---|---|
| `platform` | Set the [target platform for the build](https://docs.docker.com/engine/reference/commandline/buildx_build/#platform), e.g. `linux/amd64`. See [^1], [^2] and [^3]. |
| `shortname` | Suffixes the tag of the architecture specific "manifest" image with this value, e.g. `amd64`. |
| `crosstarget` | (optional) Used to download the correct cross-compiled binary GitHub Actions artifact. Only used when `mode` is `copy`. |
| `mode` | (optional) `copy` (for cross-compiled targets) or `build` (default). Passed through to the `Dockerfile` as build arg `MODE`. |
| `cargo_args` | (optional) Can be used when testing, e.g. set to `--no-default-features` to speed up the application build. Passed through to the Dockerfile as build arg `CARGO_ARGS`. |

[^1]: https://go.dev/doc/install/source#environment (from [^4])
[^2]: https://github.com/containerd/containerd/blob/v1.4.3/platforms/database.go#L83
[^3]: https://stackoverflow.com/a/70889505
[^4]: https://github.com/docker-library/official-images#architectures-other-than-amd64 (from [^5])
[^5]: https://docs.docker.com/desktop/multi-arch/

Example YAML file:

```yaml
include:
  - platform: "linux/amd64"
    shortname: "amd64"
    mode: "build"

  - platform: "linux/arm/v6"
    shortname: "armv6"
    crosstarget: "arm-unknown-linux-musleabihf"
    mode: "copy"

  - platform: "linux/arm/v7"
    shortname: "armv7"
    crosstarget: "armv7-unknown-linux-musleabihf"
    mode: "copy"

  - platform: "linux/arm64"
    shortname: "arm64"
    crosstarget: "aarch64-unknown-linux-musl"
    mode: "copy"
```


### Publication and Docker Hub secrets

The pkg workflow supports two Docker specific secrets which can be passed to the workflow like so:

```yaml
jobs:
  full:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v1
    secrets:
      DOCKER_HUB_ID: ${{ secrets.YOUR_DOCKER_HUB_ID }}
      DOCKER_HUB_TOKEN: ${{ secrets.YOUR_DOCKER_HUB_TOKEN }}
```

Or, if you are willing to trust the packaging workflow with all of your secrets!!!

```yaml
jobs:
  full:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v1
    secrets: inherit
```

If either of the `DOCKER_HUB_ID` and/or `DOCKER_HUB_TOKEN` secrets are defined, the workflow `prepare` job will attempt to login to Docker Hub using these credentials and will fail the pkg workflow if it is unable to login.

Best practice is to use a separately created [Docker Hub access token](https://docs.docker.com/docker-hub/access-tokens/#create-an-access-token) for automation purposes that has minimal access rights. The pkg workflow needs write access but not delete access.

_**Note:** If neither of the `DOCKER_HUB_ID` and `DOCKER_HUB_TOKEN` secrets are defined then the pkg workflow will **NOT** atttempt to publish images to Docker Hub._

### Dockerfile build arguments

The pkg workflow will invoke `docker buildx` passing [`--build-arg <varname>=<value>`](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) for the following custom build arguments.

The Docker context will be the root of a clone of the callers GitHub repository.

Your `Dockerfile` MUST define corresponding [`ARG <varname>[=<default value>]`](https://docs.docker.com/engine/reference/builder/#arg) instructions for these build arguments.

| Build Arg | Description |
|---|---|
| `MODE=build` | The `Dockerfile` should build the application from sources available in the Docker context. |
| `MODE=copy` | The pre-compiled binaries will be made available to the build process in subdirectory `dockerbin/$TARGETPLATFORM/*` of the Docker build context, where [`$TARGETPLATFORM`](https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope) is a variable made available to the `Dockerfile` build process by Docker, e.g. `linux/amd64`. For an example see https://github.com/NLnetLabs/routinator/blob/v0.11.3/Dockerfile#L99. |
| `CARGO_ARGS=...` | Only relevant when `MODE` is `build`. Expected to be passed to the Cargo build process, e.g. `cargo build ... ${CARGO_ARGS}` or `cargo install ... ${CARGO_ARGS}`. For an example see https://github.com/NLnetLabs/routinator/blob/v0.11.3/Dockerfile#L92. |