# NLnet Labs Rust Cargo Packaging reusable workflow

## Cross build rules

A **JSON** array of [Rust target triples](https://doc.rust-lang.org/nightly/rustc/platform-support.html) to cross-compile your application for. Cross compilation takes place inside a Docker container running an image from the Rust [`cross`](https://github.com/cross-rs/cross) project. These images contain the correct toolchain components needed to compile for one of the [supported targets](https://github.com/cross-rs/cross#supported-targets).

Can also be provided as the path to a **YAML** file containing the `cross_build_rules` matrix, e.g.:

```yaml
---
- 'arm-unknown-linux-musleabihf'    # for Docker
- 'arm-unknown-linux-gnueabihf'     # for DEB
```

### Known limitations

There is currently no way to customize the cross compilation process, e.g. to install libraries that should be linked against. The `cross` tool that we use supports such customization so it should be possible to expose such an ability in future if needed.
