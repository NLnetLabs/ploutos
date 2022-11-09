# NLnet Labs reusable & starter workflows

This repository contains [GitHub reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) and associated [starter workflows](https://docs.github.com/en/actions/using-workflows/creating-starter-workflows-for-your-organization) used by many NLnet Labs GitHub Rust projects.

GitHub Actions workflows are so-called [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) if they contain a `workflow_call` trigger. This trigger enables the workflow to be called from another workflow, i.e. to be re-used.

Currently this repository contains a single reusable workflow called Ploutos, and associated content.

## Ploutos

Plutos is a GitHub reusable workflow used by NLnet Labs for packaging Rust Cargo projects as DEB & RPM packages and Docker images.

Further reading:

  - [User guide](./ploutos/README.md)
  - [Starter workflow](./ploutos/starter_workflow.md)
  - [Template repository](./ploutos/template_repository.md)
  - [Contributing](./ploutos/develop/README.md)

