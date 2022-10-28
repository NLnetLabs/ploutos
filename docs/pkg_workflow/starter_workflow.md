# NLnet Labs Rust Cargo Packaging **starter** workflow

<img src="https://raw.githubusercontent.com/NLnetLabs/.github/main/docs/images/starter-workflow-screenshot.png" width="25%">

A GitHub [starter workflow](https://docs.github.com/en/actions/using-workflows/creating-starter-workflows-for-your-organization) is an easy way to get started with creating a new GitHub Actions workflow for your GitHub repository.

Starter workflows must be stored in the organization wide repository, i.e. this repository, in a folder called `workflow-templates`. This repository contains one such starter workflow which can be seen when creating a new workflow via the `New Workflow` button on the `Actions` tab of a GitHub repository. If the invoking repository contains a `Cargo.toml` file you should see the following starter workflow amongst the set to choose from:

Clicking `Configure` will drop you in to a web editor with a copy of the `workflow-templates/pkg-rust.yml` file from this repository which you can edit to get started with using the reusable Rust Cargo Packaging workflow. In this case the starter workflow is a minimal workflow showing how to invoke the reusable Rust Cargo Packaging workflow. Read on to learn more about it.
