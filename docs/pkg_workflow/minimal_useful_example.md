# NLnet Labs Rust Cargo Packaging **reusable** workflow

## Minimal useful example

This page shows a minimal example of using the pkg workflow to package a very simple Docker image. In fact it doesn't even package a Rust application!

**Contents:**
- [Your repository layout](#your-repository-layout)
  - [`.github/workflows/my_pkg_workflow.yml`](#github-workflows-my-pkg-workflow-yml)
  - [`docker-build-rules.yml`](#docker-build-rules-yml)
  - [`Dockerfile`](#dockerfile)
- [Workflow summary](#workflow-summary)
- [Workflow outputs](#workflow-outputs)

### Workflow summary

The workflow we define below will configure the pkg workflow to:

- Build a Linux x86 64 architecture image from the `Dockerfile` located in the root of the callers repository.
- Tag the created Docker image as `my_org/my_image_name:test-amd64`.
- Attach the created Docker image as a GitHUb Actions artifact to the caller workflow run _(as a zip file containing a tar file produced by the [`docker save`](https://docs.docker.com/engine/reference/commandline/save/) command)_.

### Your repository layout

For this example we will need to create 3 files in the callers GitHub repository with the following directory layout:

```
<your repo>/
    .github/
        workflows/
            my_pkg_workflow.yml          <-- your workflow
    pkg/
        rules/
            docker-build-rules.yml       <-- rules for building the Docker image
    Dockerfile                           <-- the Dockerfile to build an image from
```

Now let's look at the content of these files.

_**Tip:** Read [Docker packaging with the pkg workflow](./docker_packaging.md) for a deeper dive into the meaning of the Docker specific terms, inputs & values used in the examples below._

#### `.github/workflows/my_pkg_workflow.yml`

In this example the file contents below define a workflow that GitHub Actions will run whenever a Git `push` to your repository occurs or when the workflow is invoked by you manually via the GitHub web UI (so-called `workflow_dispatch`).

This example only has a single job that has no steps of its own but instead invokes the NLnet Labs Rust Cargo Packaging reusable workflow.

```yaml
name: Packaging

on:
  push:
  workflow_dispatch:

jobs:
  my_pkg_job:
    uses: NLnetLabs/.github/.github/workflows/pkg-rust.yml@v1
    with:
      docker_org: my_org
      docker_repo: my_image_name
      docker_build_rules_path: pkg/rules/docker-build-rules.yml
```

There are a few things to note here:

1. You can give this file any name you wish but it must be located in the `.github/workflows/` subdirectory of your repository. See the [official GitHub Actions documentation](https://docs.github.com/en/actions/using-workflows/about-workflows#create-an-example-workflow) for more information.

2. With the ["uses"](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_iduses) key we tell GitHub Actions to invoke the NLnet Labs Rust Cargo Packaging reusable workflow located at the given URL.

3. We also specify @vN denoting the version number of the pkg workflow to invoke. This corresponds to a tag in the [NLnetLabs/.github](https://github.com/NLnetLabs/.github/tags/) repository For more information about the version number see [version numbers and upgrades](./README.md#pkg-workflow-version-numbers-and-upgrades).

4. We provide three ["inputs"](https://docs.github.com/en/actions/using-workflows/reusing-workflows#using-inputs-and-secrets-in-a-reusable-workflow) to the workflow as child key value pairs of the "with" key:
   - `docker_org`
   - `docker_repo`
   - `docker_build_rules_path`

   **Tip:** The full set of available inputs that the pkg workflow accepts is defined in the pkg workflow itself [here](https://github.com/NLnetLabs/.github/blob/main/.github/workflows/pkg-rust.yml#L131).

#### `docker-build-rules.yml`

In this example the contents of the file below configurs the pkg workflow to build a Docker image for the Linux x86 64 aka `linux/amd64` target architecture. There are more options that can be used here and you can target other architectures too but we won't cover that in this simple example.

```yaml
platform: ["linux/amd64"]
shortname: ["amd64"]
```

#### `Dockerfile`

Finally, a simple Docker [`Dockerfile`](https://docs.docker.com/engine/reference/builder/) which tells Docker what the content of the built image should be. In this case it's just a simple image which prints "Hello World!" to the terminal when the built image is run.

```Dockerfile
FROM alpine
CMD ["echo", "Hello World!"]
```

### Workflow outputs

When run and successful the workflow will have a [GitHub Actions artifact](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) attached to the workflow run.

The artifact will be named `tmp-docker-image-amd64` and can be downloaded either via the UI or using the [GitHub CLI](https://docs.github.com/en/github-cli/github-cli/about-github-cli). Note that only logged-in users with the GitHub `actions:read` permission will be able to see and download the artifact.

The artifact contains the built Docker image. We can test it like so using the GitHub CLI:

_**Tip:** The `gh run download` command unzips the downloaded artifact file for us automatically! Also note that the term "run" in this context refers to an existing workflow "run" and is not used here as the verb "to run"._

```
$ cd path/to/your/repo/clone
$ gh run download <workflow_run_id> --name tmp-docker-image-amd64
$ docker load -i docker-amd64-img.tar
Loaded image: my_org/my_image_name:test-amd64
$ docker run --rm my_org/my_image_name:test-amd64
Hello World!
```