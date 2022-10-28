# NLnet Labs Rust Cargo Packaging **reusable** workflow

GitHub Actions workflows are so-called [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) if they contain a `workflow_call` trigger. This trigger enables the workflow to be called from another workflow, i.e. to be re-used.

This repository contains a single reusable workflow in `.github/workflows/pkg-rust.yml` which is referred to by the starter workflow (see above) as the "Rust Cargo Packaging Workflow".

To learn how to use the workflow consult the following pages:

- [Workflow inputs](./inputs.md)

If you want to contribute to the worfklow itself please read out [developer documentation](./develop/README.md)
