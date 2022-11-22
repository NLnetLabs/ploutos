# Ploutos: Key concepts & general configuration

**Contents:**

- [Stability promise](#stability-promise)
- [Application versions](#application-versions)
- [Next dev version](#next-dev-version)
- [Matrix rules](#matrix-rules)
- [Caching and performance](#caching-and-performance)

## Stability promise

When you refer to the Ploutos workflow you are also indicating which version of the workflow that you want to use, e.g.:

```yaml
jobs:
  my_pkg_job:
    uses: NLnetLabs/ploutos/.github/workflows/pkg-rust.yml@v5
```

Here we see that the v3 version of the workflow will be used.

What may not be obvious is that this will work for v3.0.0, v3.0.1, v3.3.4 and so on. This is because Ploutos follows the principles of [Semantic Versioning](https://semver.org/).

The version number consists of MAJOR.MINOR.PATCH components. Any change in minor and patch versions should be backward compatible and thus safe to use automatically.

If a backward incompatible change is made however then the the major version number will be increased, e.g. from `v5` to `v6`. In that case you will not get the new version with the breaking changes unless you manually update the `uses` line in your workfow to refer to the new major version.

## Application versions

The Ploutos workflow differentiates between "release", "pre-release", "unstable" and "development" types of release/application version.

Ploutos uses your application version number, as defined in the `Cargo.toml` `version` field, and/or in the git ref (e.g. a branch name, or a release tag such as v1.2.3), to know which type of version is being packaged.

Ploutos also takes care of handling special cases that relate to these different types.

For example, an `XXX-rc1` (a "pre-release" or "release candidate") version defined in `Cargo.toml` requires special treatment for O/S packages as it should be considered older than `XXX` but won't be unless the dash `-` is replaced by a tilda `~`. Contrary to that, version `XXX-dev` (a "development" version) should be considered NEWER than `XXX` so SHOULD have a dash rather than a tilda. Also, `Cargo.toml` cannot contain tilda characters in the version number string so we have to handle this ourselves.

Also, when publishing to Docker Hub one wouldn't necessarily want the latest and greatest `main` branch code to be published as the Docker tag `latest` as users will automatically be upgraded to that if they don't provide a version number and do `docker run` (on a machine that has no version of the image yet locally) or do `docker pull` (to fetch the latest). There can still be value in letting users run the bleeding edge version for testing purposes and doing the Docker packaging for them, so we publish Docker images built from a `main` branch as tag `unstable`.

These are just a couple of examples of special behaviour relating to version numbers that Ploutos handles for you.

_**Known issue:** [Inconsistent determination version number determination](https://github.com/NLnetLabs/.github/issues/43)_

_**Known issue:** [Version number 'v' prefixed should not be required](https://github.com/NLnetLabs/.github/issues/44)_

## Next dev version

The Ploutos workflow accepts an input parameter called `next_ver_label`:

```yaml
next_ver_label:
  description: "A tag suffix that denotes an in-development rather than release version, e.g. `dev``."
  required: false
  type: string
  default: dev
```

As you can see it defaults to `dev`. This relates to the notion of a "development" version of your application referred to in the previous section.

When building packages or providing your source code to others to build, it is helpful to know e.g. when a bug report is submitted, which version of the application does the issue relate to? If you release version v1.2.3 of your application and then commit some more changes to version control, perhaps even build packaged versions of that "development" version, it shouldn't also report itself as v1.2.3 as that was the version that was "released" and may differ  in code and behaviour to the "development" version. But it also shouldn't report itself as v1.2.4 or v1.3.0, we don't know yet what the next version will be or what kinds of major, minor or patch differences it will contain as we haven't crafted a release yet. So instead, we update the version in `main` immediately after release to be `vX.Y.Z-dev` signifying that this is a new in-development version, not the last released version and not the next release version. And, as mentioned in the section above, this also has a necessary impact on the version inside the built DEB and RPM packages, notably the use of tilda instead of dash!

If `dev` isn't the suffix you use, you can change that with the `next_ver_label` input. We don't however support at this time other schemes for signifying a dev version via the version number, only suffixing. 

## Matrix rules

Several of the inputs to the Ploutus workflow are of "matrix" type. These matrices are used with [GitHub matrix strategies](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) to parallelize the packaging process.

GitHub will attempt to maximize the number of jobs running in parallel, and for each permutation of the matrix given to a particular job it will launch another parallel instance of the same workflow job to process that particular input permutation.

A matrix is an ordered sequence of `key: value` pairs. In the examples below there is a single key called `target` whose value is a list of strings.

An input of "matrix" type can be specified in one of two ways:

- As an inline YAML string matrix, e.g.: _(note the YAML | multi-line ["literal block style indicator"](https://yaml.org/spec/1.0/#id2490752) which is required to preserve the line breaks in the matrix definition)_

  ```yaml
  jobs:
    my_pkg_job:
      uses: NLnetLabs/ploutos/.github/workflows/pkg-rust.yml@v5
      with:
        cross_build_rules: |
          target:
            - arm-unknown-linux-musleabihf
            - arm-unknown-linux-gnueabihf
  ```

- As the relative path to a YAML file containing the string matrix, e.g.:

  ```yaml
  jobs:
    my_pkg_job:
      uses: NLnetLabs/ploutos/.github/workflows/pkg-rust.yml@v5
      with:
        cross_build_rules: pkg/rules/cross_build_rules.yml
  ```

  Where `pkg/rules/cross_build_rules.yml` looks like this:

  ```yaml
  target:
    - 'arm-unknown-linux-musleabihf'
    - 'arm-unknown-linux-gnueabihf'
  ```

## Caching and performance

For steps of the packaging process that take a long time (e.g Cargo install of supporting tools such as cargo-deb, cargo-generate-rpm, cross, etc.) we use the GitHub Actions caching support to store the resulting binaries.

After successful caching, subsequent invocations of the packaging workflow will proceed much faster through such steps. If the stored items expire from the cache they will of course need to be rebuilt causing the next run to be slower again.

While this doesn't help much for infrequent releases, it makes a big difference when iterating your packaging settings until the resulting packages match your expectations.

## Rust version

The Rust version used to compile your application is not expliclity controlled anywhere in the packaging process at present.

- For cross-compilation this is currently 1.64.0 from the [Ubuntu 20.04 GitHub hosted runner pre-installed software](https://github.com/actions/runner-images/blob/main/images/linux/Ubuntu2004-Readme.md).

- For O/S packaging it installs latest Rust via rustup.

- For Docker images it depends on how your `Dockerfile` performs the compilation.

_**Known issue:** [Inconsistent Rust compiler version](https://github.com/NLnetLabs/.github/issues/52)_

## Artifact prefixing

By default temporary and final produced artifacts are named under the assumption that no other workflow jobs exist that also upload artifacts and thus may cause artifact name conflicts.

If necessary the `artifact_prefix` worjflow string input can be used to specify a prefix that will be added to every GitHub actions artifact uploaded by Ploutos.

## Strict mode

Some actions performed by Ploutos can result in warnings or errors that are potentially spurious, that is to say that just because Lintian or rpmlint or some other tool reports a problem does not mean to say that we should consider it fatal. For such cases Ploutos by default includes the output of the tools in the log, and in some cases raises warnings in the workflow log, but won't fail the workflow run. If needed by setting the `strict_mode` workflow input to `true` you can force Ploutos to be stricter in some cases than it would normally be.