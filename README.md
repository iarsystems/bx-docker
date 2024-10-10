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
> In this guide, network node in which the Docker Engine was installed will be referred to as `DOCKER_HOST`.

### IAR License Server
The [__IAR License Server__](https://links.iar.com/lms2-server)
- ready to serve, up and running, with __activated__ license(s) for the network nodes with the __IAR Build Tools__ of your choice -and-
- reachable from the platform in which the `DOCKER_HOST` is running as described above.
> [!TIP]
> If you do not have the licenses you need, [__contact us__][url-iar-contact].


## Installing Docker
To install the Docker Engine on the `DOCKER_HOST`, follow the [official instructions][url-docker-docs-install].

Alternatively, launch a new bash shell and use the following procedure, known to work for most `DOCKER_HOST`s:
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
1. Set an environment variable with the download URL to the installer package you received from IAR Customer Support (set `BX_DOWNLOAD_URL` to the correct address).
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
iarsystems/bxarm                   9.40.1              93eb28dd4e65        9 days ago          3.17GB
iarsystems/bxarmfs                 9.20.3.59432        abc420034fcb        6 weeks ago         2.45GB
iarsystems/bxriscv                 3.20.1              89bd0878856f        8 weeks ago         1.46GB
```


## Setting up the license
The IAR Build Tools require an available network license to operate.

The [__`setup-license`__](setup-license) script prepares a named [Docker volume][url-docker-docs-volume] for storing persistent license configuration for any containers belonging to the same __DOCKER_HOST__. 

In the bash shell, perform the following steps (replace `iarsystems/<image>:<tag>` and `<iar-license-server-ip>` by the actual ones):
```console 
$ ~/bx-docker/setup-license iarsystems/<image>:<tag> <iar-license-server-ip>
setup-license: Creating a Docker volume for LMS2...
LMS2
9825affb94394ea88e10a49da75d2baf9bcc5516f03ab7bded66e9fc6397ecdb
bx-license-setup
setup-license: LMS2 license setup completed.
```

> [!TIP]
>  Setting up the license for a Docker image in such a way only needs to be performed once per __DOCKER_HOST__. The Docker Engine will never erase this (or any other) named volume, even after the containers which made use of it are stopped or removed. For manually removing a named volume, use `docker volume rm <volume-name>`.

## Running a container
In this section, you will use the image you created to run a container so that you can build a project later.

The [bx-docker][url-repo] repository comes with projects created in the [IAR Embedded Workbench IDE][url-iar-ew] for the supported target architectures. 

Access the [projects](projects) subdirectory:
| __Linux (Bash)__ | __Windows (PowerShell)__ |
| --------- | ----------- |
| `cd ~/bx-docker/projects` | `cd ./bx-docker/projects` |

The [__`run`__](run) script will use the [`docker run`][url-docker-docs-run] command with all the necessary parameters to run the container. Execute:
| __Linux (Bash)__ | __Windows (PowerShell)__ |
| --------- | ----------- |
| `~/bx-docker/run iarsystems/bx<package>:<version>`<br>Follow the instructions provided by the __`run`__ script output, to source the __`aliases-set`__ script. | `../run iarsystems/bx<package>:<version>`<br>The __`aliases-set`__ script is invoked automatically by the run command and applied to the current shell session. |

Containers spawned by the __`run`__ script will bind mount the current directory (`pwd`) to the Docker image's working directory (`/build`). This way, these containers cannot access any parent directories. Make sure to always run a container from the project's top directory, from which all the project's files are accessible.

> [!TIP]
> The `docker run --help` command provides more information.


## Executing the Build Tools
The [`docker exec`][url-docker-docs-exec] command can execute a command in a running container. Often, these command lines will get too long to type every single time.

When you spawned the container using the [__`run`__](scripts/run) script, you also got [bash aliases](https://en.wikipedia.org/wiki/Alias_%28command%29) set for all the IAR Build Tools from the image you selected to work with. These aliases encapsulated the required `docker exec` commands in such a way that the `DOCKER_HOST` can now execute all the IAR Build Tools seamlessly.

### Build the project with __iarbuild__
The IAR Command Line Build Utility (`iarbuild`) can build (or analyze) a `<project>.ewp` file.

The simplified `iarbuild` syntax is: `iarbuild relative/path/to/<project>.ewp [command] <build-cfg>`.

For example, use `iarbuild` with the `-build <build-cfg>` command to build the `hello-world.ewp` project using the build configuration for "Release": 
```
iarbuild <arch>/hello-world.ewp -build Release
```

> [!TIP]
> Invoke `iarbuild` with no parameters for a detailed description.


### Performing static code analysis
Static Code Analysis can be performed with [IAR C-STAT][url-iar-cstat].

C-STAT is an add-on to the IAR Build Tools that helps you ensure code quality in your applications.
If you have C-STAT, `iarbuild` can be used with the `-cstat_analyze <build-cfg>` command to analyze the project.

To perform an analysis using the "Release" configuration for the `hello-world.ewp` project, execute: 
```
iarbuild <arch>/hello-world.ewp -cstat_analyze Release
```

The analysis results are stored in an SQLite database named `cstat.db`. This database can be used for generating an analysis report with warnings about coding violations for the project's ruleset selection.

Use `icstat` to display the warnings on the terminal:
```
icstat load --db <arch>/Release/path/to/cstat.db
```

And then use `ireport` to generate an HTML report:
```
ireport --full --project hello-world --db <arch>/Release/path/to/cstat.db
```
> ```
> HTML report generated: hello-world.html
> ```

> [!TIP]
> On the Linux Bash shell, you can use `lynx hello-world.html` to visualize the text contents of the HTML report. This report contains graphical elements, so use a desktop web browser to visualize its full contents.
>
> Customized ruleset selections for a `<project>`__.ewp__ project are automatically stored in a corresponding `<project>`__.ewt__ file. If the project is under version control, you are advised to check in this file as well.


## Summary
This tutorial explains how to run the [IAR Build Tools][url-iar-bx] on Linux containers.
   
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
