# Pluotos cargo-hatch template

This repository is a cargo-hatch template for generating a demonstation Git repository intended to be pushed to GitHub where it will cause GitHub Actions to package a simple Hello World Rust application as DEB, RPM package(s) and/or Docker image(s) for x86_64 platforms and optionally also for other architectures.

[Ploutos](https://github.com/NLnetLabs/ploutos) is:

> _a GitHub reusable workflow for packaging Rust Cargo projects as DEB & RPM packages and Docker images._

[Cargo Hatch](https://crates.io/crates/cargo-hatch) is:

> _a cargo init/cargo new on steroids, allowing complex templates thanks to the Tera engine. Additional template values can be configured and requested from the user during execution._

## Usage

The following assumes that you have already created an empty GitHub project called `<org_or_user>/<proj_name>`.

**Tip:** Do you intend to say yes when Hatch asks `Publish Docker images(s) to Docker Hub`? Then:
1. Generate an access token at https://hub.docker.com/settings/security.
2. Store it in a `DOCKER_HUB_TOKEN` secret in your new GitHub project at https://github.com/YOUR_ORG/YOUR_REPO/settings/secrets/actions.

First install Cargo Hatch and invoke it using the template in this repository:

```shell
cargo install cargo-hatch
cargo hatch git https://github.com/NLnetLabs/ploutos-template <proj_name>
```

Now enter the project directory that was created, generate the `Cargo.lock` file and commit the files to Git:

```shell
cd <proj_name>
cargo generate-lockfile
git add .gitignore .github *
git commit -m "Initial version."
```

And then follow the standard GitHub instructions for pushing the local Git project to GitHub:

```shell
git remote add origin git@github.com:<org_or_user>/<proj_name>.git
git branch -M main
git push --set-upstream origin main
```

