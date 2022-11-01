# NLnet Labs Rust Cargo Packaging **reusable** workflow

## Docker packaging

**Contents:**
- [Known issues](#known-issues)
- [Outputs and publication](#outputs-and-publication)
- [Terminology](#terminology)
- [Docker stages, cross-compilation and build vs copy](#docker-stages-cross-compilation-and-build-vs-copy)
- [Docker related pkg workfow inputs](#docker-related-pkg-workfow-inputs)

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

You must also however in this case make sure that your `Dockerfile` supports this.

### Docker related pkg workfow inputs

