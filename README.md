# Tutorial<br/> Building embedded applications with<br/> the IAR Build Tools on Docker Containers

## Disclaimer 
The information provided in this repository is subject to change without notice and does not represent a commitment on any part of IAR. While the information contained herein is useful as reference for DevOps Engineers willing to implement Continuous Integration using IAR Tools, IAR assumes no responsibility for any errors, omissions or particular implementations.

## Introduction
[Docker][url-docker-gs] is generally recognized as best practice for achieving automatically reproducible build environments. It provides the means for containerizing self-sufficient build environments that result from the requirements described in a Dockerfile.

This tutorial provides a [Dockerfile](Dockerfile) and helper scripts that provide the means for building embedded applications with the [IAR Build Tools][url-iar-bx] from a Linux [container][url-docker-container].

>:warning: We recommended that you use this tutorial in a test environment.

## Pre-requisites
To complete this tutorial you need:
- An understanding of how to use command line tools
- An [__IAR Build Tools__][url-iar-bx] installer package in the `.deb` format
   - >:bulb: [__Contact us__][url-iar-contact] to get access to the installers.
- A recent __x86_64/amd64__ machine
   - with Ubuntu 18+ (or Debian 10+, or Fedora 35+, ...), or Windows 10 21H1+ (build 19043)
   - connected to the internet
   - >:bulb: In this tutorial, this machine will be referred to as `DOCKER_HOST`.
- An [__IAR LMS2 License Server__](https://links.iar.com/lms2-server)
   - with activated license(s) for the product in the `.deb` package
   - reachable from the `DOCKER_HOST`.


## Conventions
These naming conventions are used in the tutorial:
| __Placeholder__ | __Meaning__        | __Valid values__   |
| :-------------- | :----------------- | :----------------- |
| `<arch>`        | Architecture       | `arm`, `avr`, `rh850`, `riscv`, `rl78`, or `rx`                                                  |
| `<package>`     | Product package    | `arm`, `armfs`, `avr`, `rh850`, `rh850fs`, `riscv`, `riscvfs`, `rl78` or `rx` |
| `<version>`     | Package version    | `major`.`minor`.`patch` `[.build]`                                                       |

Some examples:
| __Installer package__              | __Meaning__                                   | __Placeholders to be replaced__ |
| :-----------------------------     | :-------------------------------------------- | :------------------------------ |
| bx**arm**-**9.40.1**.deb           | IAR Build Tools for Arm<br/>version 9.40.1    | `<arch>`=`arm`<br/>`<package>`=`arm`<br/>`<version>`=`9.40.1` |
| bx**armfs**-**9.20.3.59432**.deb  | IAR Build Tools for Arm<br/>[Functional Safety Edition][url-iar-fs]<br/>version 9.20.3.59432 | `<arch>`=`arm`<br/>`<package>`=`armfs`<br/>`<version>`=`9.20.3.59432` |
| bx**riscv**-**3.20.1**.deb         | IAR Build Tools for RISC-V<br/>version 3.20.1 | `<arch>`=`riscv`<br/>`<package>`=`riscv`<br/>`<version>`=`3.20.1` |


## Installing Docker
To install the Docker Engine on the `DOCKER_HOST`, follow the [official instructions][url-docker-docs-install].

Alternatively, use this procedure that should work for most `DOCKER_HOST`s:
| __Linux (Bash)__ | __Windows__ |
| --------- | ----------- |
| `curl -fsSL https://get.docker.com -o get-docker.sh`<br>`sh ./get-docker.sh` | Install [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/) |

>:bulb: On Windows hosts, make sure that Docker Desktop is set up to run Linux Containers (default).

To execute Docker commands, the current user (`$USER`) must be in the `docker` group. Execute:
| __Linux (Bash)__ | __Windows__ |
| --------- | :-----------: |
| `sudo usermod -aG docker $USER`<br>Then log out and log in again for the changes to take effect. | N/A |


## Building a Docker image
Before you can run a Docker container, you need a Docker image that contains the required environment. A Dockerfile contains instructions that describe how to build an image .

This [__Dockerfile__](Dockerfile) was created as a universal template to build images with the IAR Build Tools.

The [__`build`__](build) script will use the [`docker build`][url-docker-docs-build] command with the Dockerfile, together with an installer package (__bx`<package>`-`<version>`.deb__), to create one image.

To build the image, clone the [bx-docker][url-repo] repository to the user's home directory:
| __Linux (Bash)__ | __Windows (PowerShell)__ |
| --------- | ----------- |
| `git clone https://github.com/iarsystems/bx-docker.git ~/bx-docker` | `git clone https://github.com/iarsystems/bx-docker.git $home/bx-docker` |

Then, invoke the __`build`__ script that points to the installer package:
| __Linux (Bash)__ | __Windows (PowerShell)__ |
| --------- | ----------- |
| `~/bx-docker/build /path/to/bx<package>-<version>.deb` | `./bx-docker/build /path/to/bx<package>-<version>.deb` |

Depending on your system's properties, it might take a while to build the image. The build time ranges from seconds to a few minutes. In the end, the __`build`__ script will automatically tag the image as __iarsystems/bx`<package>`:`<version>`__.

>:bulb: Invoke the __`build`__ script once for each installer package you have, to get one dedicated image for each package.

Once you have created the image, execute the [`docker images`][url-docker=docs-images] command to list all created images:
```
docker images iarsystems/*
```
The output will be similar to this, depending on which images you have created:
>```
>REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
>iarsystems/bxarm                   9.40.1              93eb28dd4e65        2 minutes ago       3.17GB
>iarsystems/bxarmfs                 9.20.3.59432        abc420034fcb        8 minutes ago       2.45GB
>iarsystems/bxriscv                 3.20.1              89bd0878856f        About an hour ago   1.46GB
>```


## Setting up the license
The IAR Build Tools require an available network license to operate.

To set up the license for all the containers in the `DOCKER_HOST`, execute the [__`setup-license`__](setup-license) script, pointing to the image's `<tagname:version>` followed by the IAR LMS2 License Server's IP address:
| __Linux (Bash)__ | __Windows (PowerShell)__ |
| ---------------- | ------------------------ |
| `~/bx-docker/setup-license iarsystems/bx<package>:<version> <lms2-server-ip>` | `./bx-docker/setup-license iarsystems/bx<package>:<version> <lms2-server-ip>` |

The __`setup-license`__ script will prepare a [Docker volume][url-docker-docs-volume] to be shared by all containers that run on the `DOCKER_HOST`, for persistent storage of the license configuration.

>:bulb: This step can only be performed once. The Docker Engine will never erase this (or any other) named volume, even after the containers which made use of it are stopped or removed.

>:bulb: If your network has multiple build nodes (`DOCKER_HOST`s), __`setup-license`__ must be run __individually__ on all of them.


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

>:bulb: The `docker run --help` command provides more information.


## Executing the Build Tools
The [`docker exec`][url-docker-docs-exec] command can execute a command in a running container. Often, these command lines will get too long to type every single time.

When you spawned the container using the [__`run`__](scripts/run) script, you also got [bash aliases](https://en.wikipedia.org/wiki/Alias_%28command%29) set for all the IAR Build Tools from the image you selected to work with. These aliases encapsulated the required `docker exec` commands in such a way that the `DOCKER_HOST` can now execute all the IAR Build Tools seamlessly.

>:bulb: The `docker run --help` command provides more information.

### Build the project with __iarbuild__
The IAR Command Line Build Utility (`iarbuild`) can build (or analyze) a `<project>.ewp` file.

The simplified `iarbuild` syntax is: `iarbuild relative/path/to/<project>.ewp [command] <build-cfg>`.

For example, use `iarbuild` with the `-build <build-cfg>` command to build the `hello-world.ewp` project using the build configuration for "Release": 
```
iarbuild <arch>/hello-world.ewp -build Release
```

>:bulb:  Invoke `iarbuild` with no parameters for a detailed description.


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

>:bulb: On the Linux Bash shell, you can use `lynx hello-world.html` to visualize the text contents of the HTML report. This report contains graphical elements, so use a desktop web browser to visualize its full contents.

>:bulb: Customized ruleset selections for a `<project>`__.ewp__ project are automatically stored in a corresponding `<project>`__.ewt__ file. If the project is under version control, you are advised to check in this file as well.

   
## Issues
Did you find an issue or do you have a suggestion related to the [__bx-docker__][url-repo] tutorial? Please use the public issue tracker.
- Do not forget to take a look at [earlier issues][url-repo-issue-old].
- If you are reporting a [new][url-repo-issue-new] issue, please describe it in detail.


## Summary
This tutorial decribes how the [IAR Build Tools][url-iar-bx] can run on Linux containers.
   
From the scripts, the [Dockerfile](Dockerfile), and the official [Docker Documentation][url-docker-docs] &mdash;which can form a cornerstone for your organization&mdash; you can learn how to use this setup as it is or to customize it so that the containers run in the way you need them to.

<!-- [Here][url-iar-bx] you can find additional resources such as on-demand webinars about the IAR Build Tools within automated workflows scenarios. -->

   
<!-- Links -->
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
