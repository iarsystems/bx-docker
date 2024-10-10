# Building embedded applications with<br/> the IAR Build Tools on Docker Containers

> __Disclaimer__
> The information in this repository is subject to change without notice and does not constitute a commitment by IAR. While it serves as a valuable reference for DevOps Engineers implementing Continuous Integration with IAR Tools, IAR assumes no responsibility for any errors, omissions, or specific implementations.

## Introduction
[Docker][url-docker-gs] is generally recognized as best practice for achieving automatically reproducible build environments. It provides the means for containerizing self-sufficient build environments that result from the requirements described in a Dockerfile.

This tutorial provides a [Dockerfile](Dockerfile) and helper scripts that provide the means for building embedded applications with the [IAR Build Tools][url-iar-bx] from a Linux [container][url-docker-container].

> [!TIP]
> We recommended that you initially perform this tutorial within a test environment.

## Pre-requisites

### Command line basics
To get the most of this tutorial, you will need a basic understanding on how to use command line tools.

### IAR Build Tools
A [__IAR Build Tools__][url-iar-bx] installer package of your choice for Ubuntu(/Debian) in the `.deb` format. IAR customers with a license can download directly from [IAR MyPages](https://iar.my.site.com/mypages). If you do not have a license yet, [contact IAR Sales][url-iar-contact].

The IAR Build Tools installer packages are delivered using the following name standard:
```
bx<arch>[fs]-<V.vv.patch[.build]>.deb
```
where `[fs]` and `[.build]` in the package names show up to distinguish tools that come pre-certified for [Functional Safety](https://iar.com/fusa).

### Docker Engine
A __x86_64/amd64__ platform supported by the Docker Engine ([supported platforms](https://docs.docker.com/engine/install/#supported-platforms)) capable of accessing the Internet for downloading the necessary packages.
> [!NOTE]
> In this guide, network node in which the Docker Engine was installed will be referred to as __DOCKER_HOST__.

### IAR License Server
The [__IAR License Server__](https://links.iar.com/lms2-server) ready to serve, up and running, with __activated__ license(s) for the network nodes with the __IAR Build Tools__ of your choice -and- reachable from the platform in which the __DOCKER_HOST__ is running as described above.
> [!TIP]
> If you do not have the licenses you need, [__contact us__][url-iar-contact].


## Installing Docker
To install the Docker Engine on the __DOCKER_HOST__, follow the [official instructions][url-docker-docs-install].

Alternatively, launch a new bash shell and use the following procedure, known to work for most cases:
```bash
sudo apt update
sudo apt install curl
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
sudo usermod -aG docker $USER
sudo - $USER
```

>[!TIP]
>If you want to use Docker Desktop on Windows, refer to the [wiki](https://github.com/iarsystems/bx-docker/wiki).


## Building a Docker image
Before you can run a Docker container, you need a Docker image that contains the required environment. A Dockerfile contains instructions that describe how to build an image .

This [__Dockerfile__](Dockerfile) was created as a universal template to build images with the IAR Build Tools.

The [__`build`__](build) script will use the [`docker build`][url-docker-docs-build] command with the Dockerfile, together with an installer package (__bx`<package>`-`<version>`.deb__), to create one image.

To build the image, you need to perform these three steps:
1. Set `BX_DOWNLOAD_URL` with the download link to the installer package you received from IAR Customer Support during your on-boarding process.
```bash
export BX_DOWNLOAD_URL=<fill-with-the-download-URL>
```
2. Clone the [bx-docker][url-repo] repository to the user's home directory.
```bash
sudo apt update
sudo apt install git
git clone https://github.com/iarsystems/bx-docker.git ~/bx-docker
```
3. Invoke the __`build`__ script pointing to the downloaded installer package:
```bash
cd ~/bx-docker
curl -fO $BX_DOWNLOAD_URL
./build ${BX_DOWNLOAD_URL##*/}
```

Depending on your system's properties, it might take a while to build the image. The build time ranges from seconds to a few minutes. In the end, the __`build`__ script will automatically tag the image as __iarsystems/bx`<package>`:`<version>`__.

> [!TIP]
> The Docker image only needs to be built once. If you use multiple packages for different targets/versions, repeat the process to build a dedicated docker image for each package.

Once you have created your images, execute the [`docker images iarsystems/*`][url-docker=docs-images] command to list all created images:
```console
$ docker images iarsystems/*
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
iarsystems/bxarm                   9.60.2              0f9ce7a7fde4        1 minute ago        4.18GB
iarsystems/bxarmfs                 9.50.3.71393        102c086a58df        5 minutes ago       3.75GB
iarsystems/bxarm                   9.40.1              93eb28dd4e65        9 days ago          3.17GB
iarsystems/bxarmfs                 9.20.3.59432        abc420034fcb        6 weeks ago         2.45GB
iarsystems/bxriscv                 3.20.1              89bd0878856f        8 weeks ago         1.46GB
```


## Setting up the license
The IAR Build Tools require an available network license to operate.

The [__`setup-license`__](setup-license) script prepares a named [Docker volume][url-docker-docs-volume] for storing persistent license configuration for any containers belonging to the same __DOCKER_HOST__. 

In the bash shell, perform the following step (replace `iarsystems/bx<image>:<tag>` and `<iar-license-server-ip>` by the actual ones):
```console 
$ ~/bx-docker/setup-license iarsystems/bx<image>:<tag> <iar-license-server-ip>
-- setup-license: Creating a Docker volume for storing persistent license information...
-- setup-license: Running a container for setting up the license...
-- setup-license: Setting up the license with IAR Light License Manager...
-- setup-license: Finished.
```

>[!TIP]
>Setting up the license for a Docker image in such a way only needs to be performed once per __DOCKER_HOST__. The Docker Engine will never erase this (or any other) named volume, even after the containers which made use of it are stopped or removed. For manually removing a named volume, remove all containers using it and then use `docker volume rm <volume-name>`.

## Running a container
In this section, you will run an interactive container locally, clone and build a project with the image you have created.

The following command line will bind the home directory (`$HOME`) to the "my-iar-bx-container" container's working directory (`/build`) for the `iarsystems/bx<image>:<tag>` image.

```bash
docker run \
  --restart=unless-stopped \
  --detach \
  --tty \
  --name my-iar-bx-container \
  --hostname `hostname` \
  --volume LMS2:/usr/local/etc/IARSystems \
  --volume $HOME:/build \
  iarsystems/bx<image>:<tag>
```
>[!TIP]
>The SHA256 hash number shown in the last line is dynamically attributed by Docker to any new container while uniquely identifying it.

You can check your containers with `docker container ls`:
```console
$ docker container ls
CONTAINER ID  IMAGE                    COMMAND      CREATED          STATUS          NAMES
dcc6c9f4e104  iarsystems/bxarm:9.60.2  "/bin/bash"  30 seconds ago   Up 29 seconds   my-iar-bx-container
```

Enter the container:
```console
$ docker exec -it my-iar-bx-container bash
root@<the-docker_host-hostname>:~# 
```

For this example we will clone a public repository with projects created in the [IAR Embedded Workbench IDE][url-iar-ew] for the supported target architectures:
```console
# git clone https://github.com/iarsystems/bx-workspaces-ci
Cloning into 'bx-workspaces-ci'...
remote: Enumerating objects: 345, done.
remote: Counting objects: 100% (99/99), done.
remote: Compressing objects: 100% (54/54), done.
remote: Total 345 (delta 44), reused 64 (delta 44), pack-reused 246 (from 1)
Receiving objects: 100% (345/345), 159.12 KiB | 631.00 KiB/s, done.
Resolving deltas: 100% (211/211), done.
```

## Building projects with the IAR Build Tools
Finally build the library project for the selected `<target>` (e.g. arm, avr, riscv, rl78, rx, rh850). In the following example, "arm" was selected and `iarbuild` was used to build the project:
```console
# /opt/iarsystems/bxarm/common/bin/iarbuild bx-workspaces-ci/targets/arm/library.ewp -build Release

     IAR Command Line Build Utility V9.3.5.863
     Copyright 2002-2024 IAR Systems AB.


library - Release
Reading project nodes...

Cleaning... 0 files.
crc16.c
crc32.c
library.a

Total number of errors: 0
Total number of warnings: 0
Build succeeded
```

Now build the application project that is linked against the library for the same selected target. In this example, `targets/arm` was selected for demonstration:
```console
# /opt/iarsystems/bxarm/common/bin/iarbuild bx-workspaces-ci/targets/arm/test-crc32.ewp -build Release

     IAR Command Line Build Utility V9.3.5.863
     Copyright 2002-2024 IAR Systems AB.


test-crc32 - Release
Reading project nodes...

Cleaning... 0 files.
test-crc32.c
test-crc32.out

Total number of errors: 0
Total number of warnings: 0
Build succeeded
```

> [!TIP]
> Invoke `/opt/iarsystems/bx<target>/common/bin/iarbuild` with no parameters for a detailed description of available options.


### Performing static code analysis
Additionally, [IAR C-STAT][url-iar-cstat] is an add-on to the IAR Build Tools that can perform static code analysis. It helps you ensure code quality in your applications. If you have C-STAT, `iarbuild` can drive the analysis with the `-cstat_analyze <build-cfg>` command to analyze the project.

Using the library project in `bx-workspaces-ci/targets/arm` as an example:
```console
# /opt/iarsystems/bxarm/common/bin/iarbuild bx-workspaces-ci/targets/arm/library.ewp -cstat_analyze Release

     IAR Command Line Build Utility V9.3.5.863
     Copyright 2002-2024 IAR Systems AB.


library - Release

Analysis completed. 8 message(s)
```

The analysis results are stored in an SQLite database named `cstat.db`. Use `icstat` to retrieve the warnings and display them on the terminal. For example:
```console
# /opt/iarsystems/bxarm/arm/bin/icstat load --db $(find bx-workspaces-ci -name "cstat.db")
"bx-workspaces-ci/library/source/crc32.c",29 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",30 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",31 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",32 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",33 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",34 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",35 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
"bx-workspaces-ci/library/source/crc32.c",36 Severity-Medium[ATH-shift-neg]:LHS argument of right shift operator may be negative. Its range is [-INF,INF].
```

The same database can be used for generating an analysis report with warnings about coding violations for the project's ruleset selection. Use `ireport` to generate an HTML report. In this example:
```console
# /opt/iarsystems/bxarm/arm/bin/ireport --full --project library --db $(find bx-workspaces-ci -name "cstat.db")
HTML report generated: library.html
```

Now exit the container:
```console
# exit
```

Thanks to running the container with the `--volume $HOME:/build` parameter, all existing files from the home directory and below are bound to the container's `/build` working directory. In this case, once you exit the container, any files within the `/build` directory will remain in their correspondent locations under the home directory.

You will find all your project files generated in this example under `~/bx-workspaces-ci`. However they belong to root as it was the default user for the container. In order to get ownership of all generated files, perform:
```console
$ sudo chown -Rv $USER:$USER bx-workspaces-ci/
changed ownership of 'bx-workspaces-ci/LICENSE' from root:root to <user>:<user>
changed ownership of 'bx-workspaces-ci/tests/test-crc32.c' from root:root to <user>:<user>
changed ownership of 'bx-workspaces-ci/tests/test-crc16.c' from root:root to <user>:<user>
...
```

>[!TIP]
>Since the container was run with the `--restart=unless-stopped` option, it will remain available for reattaching to it when desired, by using `docker exec -it my-iar-bx-container bash`, until it is manually stopped with `docker stop my-iar-bx-container`. The `docker run --help` command provides more information on different ways of running docker containers.



## Summary
This tutorial guided you through one way of running the [IAR Build Tools][url-iar-bx] on Linux containers.
   
Using the provided scripts, [Dockerfile](Dockerfile), and official [Docker Documentation][url-docker-docs], you can either use this setup as-is or customize it to ensure the containers operate according to your specific requirements. This setup can serve as a fundational element for your organization.

[__` Follow us `__](https://github.com/iarsystems) on GitHub to get updates about tutorials like this and more.


## Issues
For technical support contact [IAR Customer Support][url-iar-customer-support].

For questions or suggestions related to this tutorial: try the [wiki][url-repo-wiki] or check [earlier issues][url-repo-issue-old]. If those don't help, create a [new issue][url-repo-issue-new] with detailed information.


<!-- Links -->
[url-iar-customer-support]: https://iar.my.site.com/mypages/s/contactsupport

[url-iar-bx]:              https://iar.com/bx
[url-iar-contact]:         https://iar.com/about/contact
[url-iar-cstat]:           https://iar.com/cstat
[url-iar-ew]:              https://iar.com/products/overview
[url-iar-fs]:              https://iar.com/products/requirements/functional-safety
[url-iar-mp]:              https://iar.com/mypages
[url-iar-lms2]:            https://links.iar.com/lms2-server
   
[url-docker]:              https://docker.com
[url-docker-gs]:           https://docs.docker.com/get-started
[url-docker-container]:    https://docker.com/resources/what-container
[url-docker-docs]:         https://docs.docker.com
[url-docker-docs-install]: https://docs.docker.com/engine/install#server
[url-docker-docs-build]:   https://docs.docker.com/engine/reference/commandline/build/
[url-docker-docs-volume]:  https://docs.docker.com/storage/volumes/
[url-docker=docs-images]:  https://docs.docker.com/engine/reference/commandline/images/
[url-docker-docs-run]:     https://docs.docker.com/engine/reference/commandline/run/
[url-docker-docs-exec]:    https://docs.docker.com/engine/reference/commandline/exec/
   
[url-repo]:                https://github.com/iarsystems/bx-docker
[url-repo-wiki]:           https://github.com/iarsystems/bx-docker/wiki
[url-repo-issue-new]:      https://github.com/iarsystems/bx-docker/issues/new
[url-repo-issue-old]:      https://github.com/iarsystems/bx-docker/issues?q=is%3Aissue+is%3Aopen%7Cclosed
