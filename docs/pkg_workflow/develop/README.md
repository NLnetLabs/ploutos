# NLnet Labs Rust Cargo Packaging **reusable** workflow

## Developing the reusable workflow

This page is intended for people diagnosing, improving or fixing the reusable workflow itself. It is NOT intended for users of the workfow. Users should consult the [user guide](../README.md).

## Tips

1. The workflow Docker behaviour differs depending on whether the workflow is invoked for a Git release tag ("release" here meaning that the tag is of the form `v*` without a trailing `-*` suffix), a `main` branch or some other branch (e.g. a PR branch). To fully test it you should either run the workflow in each of these cases or modify the workflow behaviour temporarily to be triggered as necessary for testing.

2. When a calling GitHub workflow invokes a GitHub Action or reusable workflow it does so typically by major version number, e.g. <action or workflow>@v2. However, for reusable workflows this isn't actually done via GitHub selecting the nearest match according to semantic versioning rules, instead it is a trick achieved by the action and workflow publishers tagging their repository twice: once with the actual version, e.g. v2.1.3, and once with a major version only tag, e.g. v2, that **both point to the same Git ref**, i.e. the major version tag is deleted and re-created whenever a new minor or patch version tag is created.

3. When you push a change to the `pkg-rust.yml` workflow in this repository, downstream workflows that call `pkg-rust.yml` (e.g. from the https://github.com/NLnetLabs/.github-testing/ repository) will not see the changes unless you either update the `@<git ref>` to match the new commit, or if using `@<tag>` if the tag is moved to the new commit, or if using `@<branch>` you will need to trigger a new run of the action or do "Re-run all jobs" on the workflow run. Doing "Re-run failed jobs" is **NOT ENOUGH** as then GitHub Actions will use the workflow at the exact same commit as it used before, it won't pick up the new commit to the branch.

## Release process
  
To test and release changes to the workflow the recommended approach is as follows: _(an example of this release process in use can be seen [here](https://github.com/NLnetLabs/.github/pull/7#issuecomment-1246370906))_

Let's call this repository the RELEASE repo.
Let's call the https://github.com/NLnetLabs/.gihub-testing/ repostiory the TEST repo.

- [ ] 1. Create a branch in the RELEASE repo, let's call this the RELEASE branch.
- [ ] 2. Create a PR in the RELEASE repo for the RELEASE branch.
- [ ] 3. Create a matching branch in the TEST repo, let's call this the TEST branch.
- [ ] 4. Make the desired changes to the RELEASE branch.
- [ ] 5. In the TEST branch modify `.github/workflows/pkg.yml` so that instead of referring to `pkg-rust.yml@v1` it refers to `pkg-rust.yml@<Git ref of HEAD commit on the TEST branch>` or `pkg-rust.yml@<test branch name>`.
- [ ] 6. Create a PR in the `.gihub-testing` repository from the TEST branch to `main`, let's call this the TEST PR.
- [ ] 7. Repeat steps 4 and 5 until the the `Packaging` workflow run in the TEST PR passes and behaves as desired.
- [ ] 8. Merge the TEST PR to the `main` branch.
- [ ] 9. Verify that the automatically invoked run of the `Packaging` workflow in the TEST repo against the `main` branch passes and behaves as desired. If not, repeat steps 4-9 until the new TEST PR passes and behaves as desired.
- [ ] 10. Create a release tag in the TEST repo with the same release tag as will be used in the RELEASE repo, e.g. v1.2.3. _**Note:** Remember to respect semantic versioning, i.e. if the changes being made are not backward compatible you will need to bump the MAJOR version (in MAJOR.MINOR.PATCH) **and** any workflows that invoke the reusable workflow will need to be **manually edited** to refer to the new MAJOR version._
- [ ] 11. Verify that the automatically invoked run of the `Packaging` workflow in the TEST repo passes against the newly created release tag passes and behaves as desired. If not, delete the release tag **in the TEST repo** and repeat steps 4-11 until the new TEST PR passes and behaves as desired.
- [ ] 12. Merge the RELEASE PR to the `main` branch.
- [ ] 13. Create the new release vX.Y.Z tag in the RELEASE repo.
- [ ] 14. Update the v1 tag in the RELEASE repo to point to the new vX.Y.Z tag.
- [ ] 15. Edit `.github/workflows/pkg.yml` in the `main` branch of the TEST repo to refer again to `@v1`.
- [ ] 16. Verify that the `Packaging` action in the TEST repo against the `main` branch passes and works as desired.
- [ ] 17. (optional) If the MAJOR version was changed, update affected repositories that use the reusable workflow to use the new MAJOR version, including adjusting to any breaking changes introduced by the MAJOR version change.

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
