# Ploutos: User guide

In this documentation we'll show you how to invoke the NLnet Labs Rust Cargo Packaging **reusable** workflow (hereafter the "Ploutos workflow") from your own repository and how to create the supporting files needed.

> _**WARNING:** Using Ploutos is free for public GitHub repositories, but is **NOT FREE** for **private GitHub repositories**. As Ploutos runs many jobs in parallel (if configured to build for multiple package types and/or targets) it can consume a LOT of GitHub Actions minutes. If you exceed the [free limits for GitHub private repositories](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions) it will cost money! For example a workflow that ran for ~11 minutes actually used ~141 minutes of GitHub Actions resources in total._

**Contents:**
- [See also](#see-also)
- [Getting started](#getting-started)
- [Examples](#examples)
- [Key concepts and general configuration](#key-concepts-and-general-configuration)
- [Creating specific package types](#creating-specific-package-types)

## See also

- **FAQ:** If your question isn't answered here, or you'd just like to know more, checkout the [FAQ](./FAQ.md).

- **Ploutos presentation:** Learn more about Ploutos and [see it in action](https://www.youtube.com/watch?v=ZZnLC0KmkHs) as presented at the November 30 2022 Rust Nederland meetup.

- **The starter workflow:** If you already know how to use this workflow but just want to quickly add it to a new project you might find the [starter workflow](../starter_workflow.md) helpful _(**only** visible to NLnet Labs GitHub organization members unfortunately)_.

- **The demo template:** This [template](template/README.md) can be used to create your own repository with sample input files and workflow invocation to get started with the Ploutos workflow.

- **Examples of the workflow in use:** This documentation contains some limited examples but if you're looking for real world examples of how to invoke and configure the Ploutos workflow take a look at the [projects that are already using the Ploutos workflow](https://github.com/NLnetLabs/ploutos/network/dependents).

- **The testing repository:** The https://github.com/NLnetLabs/ploutos-testing/ repository contains test data and workflow invocations for automated testing of as many features of Ploutos as possible.

## Getting started

1. Decide which package types you want to create.
2. Determine which [inputs](https://github.com/NLnetLabs/ploutos/blob/main/.github/workflows/pkg-rust.yml#L131) you need to provide to the Ploutos workflow.
3. Create the files in your repository that will be referenced by the inputs _(perhaps start from the [template](template/README.md))_.
4. Call the Ploutos workflow from your own workflow with the chosen inputs _(by hand or via the [starter workflow](/.starter_workflow.md))_.
5. Run your workflow _(e.g. triggered by a push, or use the GitHUb [`workflow_dispatch` manual trigger](https://docs.github.com/en/actions/managing-workflow-runs/manually-running-a-workflow))_.
6. Use the created packages:
   - DEB and RPM packages will be attached as artifacts to the workflow run that you can [download](https://docs.github.com/en/actions/managing-workflow-runs/downloading-workflow-artifacts).
   - Docker images will have been published to Docker Hub.
7. (optional) Publish your DEB and RPM packages to a repository somewhere.

## Examples

- [Simple Docker example](./minimal_docker_example.md)
- [Simple DEB example](./os_packaging.md#example)
- [Real use cases](https://github.com/NLnetLabs/ploutos/network/dependents?dependent_type=REPOSITORY)

## Key concepts and general configuration

Read [this page](./key_concepts_and_config.md) to learn more about key concepts and general configuration not specific to any single packaging type.

## Creating specific package types

To learn more about how to build a particular package type using the Ploutos workflow see:

- [Cross compiling](./cross_compiling.md)
- [Creating O/S packages](./os_packaging.md)
- [Publishing O/S packages](./os_publishing.md)
- [Creating & publishing Docker images](./docker_packaging.md)
