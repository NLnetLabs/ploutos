# NLnet Labs reusable & starter workflows

This repository contains [GitHub reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) and associated [starter workflows](https://docs.github.com/en/actions/using-workflows/creating-starter-workflows-for-your-organization) used by NLnet Labs GitHub repositories, but also usable by you.

GitHub Actions workflows are so-called [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) if they contain a `workflow_call` trigger. This trigger enables the workflow to be called from another workflow, i.e. to be re-used.

Currently this repository contains a single reusable workflow and associated content.

## Rust Cargo Packaging

The NLnet Labs Rust Cargo Packaging reusable workflow automates the packaging of a Rust Cargo application into various forms of "package", something that can be installed and run on another computer such that you don't need to install anything else manually to make it work, except perhaps to adjust configuration files to match your needs. In this case the kinds of package referred to are DEB, RPM and Docker at the time of writing.

  - [User guide](./pkg_workflow/README.md)
  - [Starter workflow](./pkg_workflow/starter_workflow.md)
  - [Template repository](./pkg_workflow/template_repository.md)
  - [Contributing](./develop/README.md)

