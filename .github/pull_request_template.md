This release contains the following changes:

- TODO

Successful test runs can be seen here:

- dev branch: TODO
- main branch: TODO
- release tag: TODO

Release checklist:

- [ ] 1. Create a branch in the RELEASE repo, let's call this the RELEASE branch.
- [ ] 2. Change RPM_MACROS_URL in the workflow to point to the new RELEASE branch.
- [ ] 3. Create a PR in the RELEASE repo for the RELEASE branch.
- [ ] 4. Create a matching branch in the TEST repo, let's call this the TEST branch.
- [ ] 5. Make the desired changes to the RELEASE branch.
- [ ] 6. In the TEST branch modify `.github/workflows/pkg.yml` so that instead of referring to `pkg-rust.yml@vX` it refers to `pkg-rust.yml@<Git ref of HEAD commit on the TEST branch>` or `pkg-rust.yml@<test branch name>`.
- [ ] 7. Create a PR in the `ploutos-testing` repository from the TEST branch to `main`, let's call this the TEST PR.
- [ ] 8. Repeat step 5 until the the `Packaging` workflow run in the TEST PR passes and behaves as desired.
- [ ] 9. Merge the TEST PR to the `main` branch.
- [ ] 10. Verify that the automatically invoked run of the `Packaging` workflow in the TEST repo against the `main` branch passes and behaves as desired. If not, repeat steps 4-9 until the new TEST PR passes and behaves as desired.
- [ ] 11. Create a release tag in the TEST repo with the same release tag as will be used in the RELEASE repo, e.g. v1.2.3. _**Note:** Remember to respect semantic versioning, i.e. if the changes being made are not backward compatible you will need to bump the MAJOR version (in MAJOR.MINOR.PATCH) **and** any workflows that invoke the reusable workflow will need to be **manually edited** to refer to the new MAJOR version._
- [ ] 12. Verify that the automatically invoked run of the `Packaging` workflow in the TEST repo passes against the newly created release tag passes and behaves as desired. If not, delete the release tag **in the TEST repo** and repeat steps 4-11 until the new TEST PR passes and behaves as desired.
- [ ] 13. Merge the RELEASE PR to the `main` branch.
- [ ] 14. Change RPM_MACROS_URL in the workflow to point to vX.Y.Z tag (if your release branch has a different name).
- [ ] 15. Create the new release vX.Y.Z tag in the RELEASE repo.
- [ ] 16. Update the vX tag in the RELEASE repo to point to the new vX.Y.Z tag ([howto](https://github.com/NLnetLabs/ploutos/blob/main/docs/develop/README.md#release-process)).
- [ ] 17. Edit `.github/workflows/pkg.yml` in the `main` branch of the TEST repo to refer again to `@vX`.
- [ ] 18. Verify that the `Packaging` action in the TEST repo against the `main` branch passes and works as desired.
- [ ] 19. (optional) If the MAJOR version was changed, update affected repositories that use the reusable workflow to use the new MAJOR version, including adjusting to any breaking changes introduced by the MAJOR version change.
