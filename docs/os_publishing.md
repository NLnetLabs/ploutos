**Contents:**

- [Introduction](#introduction)
- [Considerations](#considerations)
- [Doing it yourself](#doing-it-yourself)
- [Tools that can help](#tools-that-can-help)
- [3rd party services](#3rd-party-services)

# Introduction

Ploutos produces O/S packages such as DEB and RPM files (contained within ZIP archives attached to GitHub Actions workflow runs), but it doesn't "publish" them for you.

Publishing of O/S packages is the process of making them available on a web server (your "online repository") somewhere in the correct directory structure with the correct accompanying metadata files such that standard O/S packaging tools like `apt` and `yum` can find and install packages from your "online repository".

# Considerations

- **How much will it cost to host the packages?** This will be influenced by the service you use to host the web server, the number of historical versions that you wish to keep, the package types you want to offer (e.g. DEB and/or RPM), and the number of specific O/S versions you intend to package for separately (unless your packages are usable on many/all O/S versions and such can be offered as a single O/S version independent package).
- **How much will it cost to serve the packages?** This will be influenced by the service you use to host the web server, the size of your packages, the size of your expected audience, how often you expect to publish new versions, and whether you wish to pay extra to serve the packages closer to the end user by fronting your repository with something like a Content Distribution Network.
- **How many packages do you intend to publish?** If only one or a few you may need a simpler setup than if you intend to publish many different software packages.
- **What kind of availability guarantees do you want?** Does it matter if your repository is offline or slow or unreachable sometimes and/or to some clients?
- **How long do you expect to keep the repository?** This can influence how much room you need for growth, or if you want the repository to also support additional package types later.
- **How do you want to manage the metadata?** By invoking stock packaging tool commands manually, or by using some tooling to help you, or even by using a 3rd party service to do the work for you?
- **Who should have access to your package signing key?**

# Doing it yourself

There are many examples out there of how to do this yourself, e.g. to pick just a few:

- Official [Ubuntu](https://help.ubuntu.com/community/Repositories/Personal), [RedHat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/sec-yum_repository) and [Fedora](https://docs.fedoraproject.org/en-US/packaging-guidelines/) guides.
- Via Google:
  - [deb](https://earthly.dev/blog/creating-and-hosting-your-own-deb-packages-and-apt-repo/), [deb](https://medium.com/sqooba/create-your-own-custom-and-authenticated-apt-repository-1e4a4cf0b864), [deb](https://www.linuxbabe.com/linux-server/set-up-package-repository-debian-ubuntu-server)
  - [deb & rpm](https://www.percona.com/blog/how-to-create-your-own-repositories-for-packages/)
  - [rpm](http://nuxref.com/2016/10/06/hosting-rpm-repository/), [rpm](https://www.recitalsoftware.com/blogs/34-howto-create-your-own-yum-repository-on-redhat-and-fedora-linux), [rpm](https://bgstack15.wordpress.com/2019/08/02/how-i-use-the-copr-to-build-and-host-rpms-for-centos-and-fedora/)
- _(Coming soon) How we at NLnet Labs publish our O/S packages._

# Tools that can help

Just a few examples, there are likely many others out there:

- https://www.aptly.info/
- https://manpages.debian.org/testing/debarchiver/debarchiver.1.en.html
- https://wiki.debian.org/DakHowTo

# 3rd party services

**Disclaimer:** The services are listed in alphabetical order, there is no special meaning or priority to the order. We have NO relationship with these services nor experience with them and cannot recommend them, they were simply found via Google, use them at your own risk.

- https://copr.fedorainfracloud.org/
- https://packagecloud.io/
- https://rpmdeb.com/
- https://rpmfusion.org/Contributors
