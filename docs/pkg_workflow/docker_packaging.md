# NLnet Labs Rust Cargo Packaging **reusable** workflow

## Docker packaging

The location of an image published to [Docker Hub](https://hub.docker.com/) is a bit confusing in Docker terminology as Dockers' own [official documentation](https://docs.docker.com/engine/reference/commandline/tag/) conflates the terms "image" and "tag". When configuring the pkg workflow we therefore use the following terminology:

```
# Using Docker Hub terminology, for a Docker image named nlnetlabs/krill:v0.1.2-arm64:
#   - The Organization would be 'nlnetlabs'.
#   - The Repository would be 'krill'.
#   - The Tag would be v0.1.2-arm64
# Collectively I refer to the combination of <org>/<repo>:<tag> as the 'image' name,
```

Source: https://github.com/NLnetLabs/.github/blob/main/.github/workflows/pkg-rust.yml

_**Known issue:** [ The Docker repository to publish to is not configurable](https://github.com/NLnetLabs/.github/issues/37)_
