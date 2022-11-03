# Ploutos: Key concepts & general configuration

**Contents:**

- [Stability promises and the Ploutos version](#stability-promises-and-the-ploutos-version)
- [Release types and your application version](#release-types-and-your-application-version)
- [Matrix rules](#matrix-rules)

## Stability promises and the Ploutos version

When you refer to the Ploutos workflow you are also indicating which version of the workflow that you want to use, e.g.:

```yaml
jobs:
  my_pkg_job:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v2
```

Here we see that the v2 version of the workflow will be used.

What may not be obvious is that this will work for v2.0.0, v2.0.1, v2.3.4 and so on. This is because Ploutos follows the principles of [Semantic Versioning](https://semver.org/).

The version number consists of MAJOR.MINOR.PATCH components. Any change in minor and patch versions should be backward compatible and thus safe to use automatically.

If a backward incompatible change is made however then the the major version number will be increased, e.g. from `v2` to `v3`. In that case you will not get the new version with the breaking changes unless you manually update the `uses` line in your workfow to refer to the new major version.

## Release types and your application version

The Ploutos workflow differentiates between "release", "pre-release", "unstable" and "development" types of release/application version.

Ploutos uses your application version number, as defined in the `Cargo.toml` `version` field, and/or in the git ref (e.g. a branch name, or a release tag such as v1.2.3), to know which type of version is being packaged.

Ploutos also takes care of handling special cases that relate to these different types.

For example, an `XXX-rc1` (a "pre-release" or "release candidate") version defined in `Cargo.toml` requires special treatment for O/S packages as it should be considered older than `XXX` but won't be unless the dash `-` is replaced by a tilda `~`. Contrary to that, version `XXX-dev` (a "development" version) should be considered NEWER than `XXX` so SHOULD have a dash rather than a tilda. Also, `Cargo.toml` cannot contain tilda characters in the version number string so we have to handle this ourselves.

Also, when publishing to Docker Hub one wouldn't necessarily want the latest and greatest `main` branch code to be published as the Docker tag `latest` as users will automatically be upgraded to that if they don't provide a version number and do `docker run` (on a machine that has no version of the image yet locally) or do `docker pull` (to fetch the latest). There can still be value in letting users run the bleeding edge version for testing purposes and doing the Docker packaging for them, so we publish Docker images built from a `main` branch as tag `unstable`.

These are just a couple of examples of special behaviour relating to version numbers that Ploutos handles for you.

_**Known issue:** [Inconsistent determination version number determination](https://github.com/NLnetLabs/.github/issues/43)_

_**Known issue:** [Version number 'v' prefixed should not be required](https://github.com/NLnetLabs/.github/issues/44)_

## Matrix rules

Several of the inputs to the Ploutus workflow are of "matrix" type. These matrices are used with [GitHub matrix strategies](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs) to parallelize the packaging process.

GitHub will attempt to maximize the number of jobs running in parallel, and for each permutation of the matrix given to a particular job it will launch another parallel instance of the same workflow job to process that particular input permutation.
