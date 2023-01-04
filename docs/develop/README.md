# Ploutos: Contributor guide

This page is intended for people diagnosing, improving or fixing the reusable workflow itself. It is NOT intended for users of the workfow. Users should consult the [user guide](../README.md).

## Tips

1. The workflow Docker behaviour differs depending on whether the workflow is invoked for a Git release tag ("release" here meaning that the tag is of the form `v*` without a trailing `-*` suffix), a `main` branch or some other branch (e.g. a PR branch). To fully test it you should either run the workflow in each of these cases or modify the workflow behaviour temporarily to be triggered as necessary for testing.

2. When a calling GitHub workflow invokes a GitHub Action or reusable workflow it does so typically by major version number, e.g. <action or workflow>@v2. However, for reusable workflows this isn't actually done via GitHub selecting the nearest match according to semantic versioning rules, instead it is a trick achieved by the action and workflow publishers tagging their repository twice: once with the actual version, e.g. v2.1.3, and once with a major version only tag, e.g. v2, that **both point to the same Git ref**, i.e. the major version tag is deleted and re-created whenever a new minor or patch version tag is created.

3. When you push a change to the `pkg-rust.yml` workflow in this repository, downstream workflows that call `pkg-rust.yml` (e.g. from the https://github.com/NLnetLabs/ploutos-testing/ repository) will not see the changes unless you either update the `@<git ref>` to match the new commit, or if using `@<tag>` if the tag is moved to the new commit, or if using `@<branch>` you will need to trigger a new run of the action or do "Re-run all jobs" on the workflow run. Doing "Re-run failed jobs" is **NOT ENOUGH** as then GitHub Actions will use the workflow at the exact same commit as it used before, it won't pick up the new commit to the branch.

## Automated testing

The https://github.com/NLnetLabs/ploutos-testing/ repository contains workflows that can be used to test Ploutos. The `ploutos-testing` repository is referred to below as the `TEST repo`.

## Release process
  
To test and release changes to the workflow the recommended approach is to create a PR _(an example of this release process in use can be seen [here](https://github.com/NLnetLabs/ploutos/pull/42))_ and follow the release steps shown in the [default PR template](https://github.com/NLnetLabs/ploutos/.github/pull_request_template.md).

**How to update the vN tag:**

At the time of writing the GitHub web interface does not offer a way to delete tags or update tags, only to delete the extra "release" details which can be associated with a tag. To update a tag one must do it locally and remotely from the command line.

Assuming that you want to update the v1 tag to point not at the old v1.0.2 tag but at the new v1.0.3 tag, this is one way to do it:
```shell
$ NEW_REF=$(git rev-list -n 1 v1.0.3)
$ git rev-list -n 1 v1
$ git tag --force v1 ${NEW_REF}
$ git rev-list -n 1 v1 # should point to ${NEW_REF} now
$ git push --force --tags
```
