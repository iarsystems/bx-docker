# Tutorial<br/>Building Docker images<br/>for IAR Build Tools on Linux

This tutorial provides guidance on how to build [Docker images](https://docs.docker.com/get-started/) containing one of the [IAR Build Tools][iar-bx-url] packages using Ubuntu Linux as host OS. From these images, the tools run inside [Docker containers][docker-container-url]. This repository is a revamped version of the earlier [bxarm-docker](https://github.com/iarsystems/bxarm-docker) tutorial.
 
Each of the __IAR Build Tools__ packages requires its specific license. Please feel free to [__contact us__](https://www.iar.com/about-us/contact) if you would like to learn how to get access to them.

If you have a question specifically related to this tutorial, you might be interested in verifying if it was already answered from [earlier questions][repo-old-issue-url]. Or, [ask a new question][repo-new-issue-url] if you could not find any answer for your question. 

If you want to be notifed in your GitHub inbox about significant updates to this tutorial, you can start __watching__ this repository. You can customize which types of notification you want to get. Read more about [notifications](https://docs.github.com/en/github/managing-subscriptions-and-notifications-on-github/setting-up-notifications/about-notifications) and how to [customize](https://docs.github.com/en/github/managing-subscriptions-and-notifications-on-github/setting-up-notifications/about-notifications#customizing-notifications-and-subscriptions) them.

>:warning: Before you start the walkthrough, make sure you have a non-root super user account - *a user with __sudo__ privileges* - if you need to install the _Docker Engine_ on the _Ubuntu host_. If you already have the _Docker Engine_ in place, the standard user account has to belong to the __docker__ group. 

>:warning: _IAR Systems only provides what is considered to be the bare essential information for the completion of this tutorial when it comes to Ubuntu, Linux, Docker, Bash and Git in general. That way, it becomes straightforward for any user willing to follow the steps until the end. Beyond this point, as in production, a proper level of familiarity with these platforms becomes a self-evident pre-requisite._

## Conventions
As we are going to be dealing with different packages, for different architectures and their respective versions, it unfolds many different possibilites for this tutorial. Establishing some useful conventions becomes convenient.

The following conventions are going to be used:
| __Placeholder__ | __Meaning__                                                                                |
| :-------------- | :----------------------------------------------------------------------------------------- |
| `<arch>`        | __Architecture__<br/>Valid: `arm`, `riscv`, `rh850`, `rl78`, `rx`                          |
| `<package>`     | __Product package__<br/>Valid: `arm`, `armfs`, `riscv`, `rh850`, `rh850fs`, `rl78`, `rx`   |
| `<version>`     | __Package version__<br/>Valid: `major`.`minor`.`patch` `[.build]`                          |

Examples:
| __Package/Version__       | __Meaning__                                                                                                                                    |
| :------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| BXARM 9.10.1              | IAR Build Tools for Arm version 9.10.1<br/>`<arch>`=`arm`<br/>`<package>`=`arm`<br/>`<version>`=`9.10.1`                                       |
| BXARMFS 8.50.10.35167     | IAR Build Tools for Arm, [Functional Safety Edition](https://www.iar.com/products/requirements/functional-safety/), version 8.50.10<br/>`<arch>`=`arm`<br/>`<package>`=`armfs`<br/>`<version>`=`8.50.10.35167` |
| BXRISCV 1.40.1            | IAR Build Tools for RISC-V version 1.40.1<br/>`<arch>`=`riscv`<br/>`<package>`=`riscv`<br/>`<version>`=`1.40.1`                                |


## Installing Docker

The following steps are the typical ones needed to make Docker ready to be used on the Ubuntu host which will hold the Docker images and run the containers. These installation instructions are based on the official ones available in the [_Docker Documentation_][docker-docs-url].

### Setup the Official Docker Repository
__Update__ the apt package database cache and __install packages__ that allow apt to use a repository over HTTPS:
```
sudo apt update && sudo apt install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg-agent \
     software-properties-common
```
>:warning: You can use GitHub's __Copy to clipboard__ feature. A button with a clipboard icon appears on the right side of the command whenever you hover the mouse pointer over the command.

Add __Docker's official repository GPG key__ to the package management keyring.
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -   
```

Use the following command to set up the __stable__ repository.
```
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

### Install the Docker Engine
__Update__ the `apt` package index, and install the _latest_ version of Docker Engine and containerd.
```
sudo apt update && sudo apt -y install docker-ce docker-ce-cli containerd.io
```

In order to use Docker as a non-root user, add the user (referred by the `$USER` environment variable) to the __"docker" group__.
```
sudo usermod -aG docker $USER
```
Now __log out and log back in__ so thay your group membership is re-evaluated.

As in many Linux distributions using `systemd` to manage which services to start when the system boots, the Docker service can be configured with `systemctl` to start on boot. To automatically start Docker with the system, __enable the service__.
```
sudo systemctl enable docker && sudo systemctl start docker
```

Now it is possible to verify if the `$USER` is able to use the `docker` commands without the `sudo` privileges:
```
docker run hello-world
```
The previous command automatically pulls a lightweight `hello-world` image, runs the image in a container from where it prints informational messages and then exits when the execution is finished.

## Build a Docker image with the IAR Build Tools
The commands in this section are for building a Docker image containing one IAR Build Tools package. It uses an universal [__Dockerfile__](images/Dockerfile) template to cover different packages, architectures and versions.

In order to simplify the process of building these Docker images, a [__build__](scripts/build) script is offered. The script will create one Docker image per `<package>`-`<version>`.

An IAR Build Tools installer package is required for the `build` script to operate over the Dockerfile. The IAR Build Tools installer packages are prefixed with __bx__ and packaged in the __.deb__ format. 

The general package naming will follow this format: __bx`<package>`-`<version>`.deb__. 

The table below lists the IAR Build Tools installer packages that have been successfully used for building Docker images with this current solution. 

| __bx`<package>`-`<version>`.deb__                                  | __`<package>`__ | __`<version>`__               | __`<arch>`__ |
| :---------------------------------------------------------------   | :----------     | :---------------------------  | :----------- |
| `bxarm-9.10.1.deb`<br/>`bxarm-8.50.9.deb`<br/>`bxarm-8.50.6.deb`   | `arm`           | 9.10.1</br>8.50.9<br/>8.50.6  | `arm`        |
| `bxarmfs-8.50.10.35167.deb`                                        | `armfs`         | 8.50.10.35167                 | `arm`        |
| `bxriscv-1.40.1.deb`                                               | `riscv`         | 1.40.1                        | `riscv`      |
| `bxrh850-2.21.1.deb`                                               | `rh850`         | 2.21.1                        | `rh850`      |
| `bxrh850fs-2.21.2.1803.deb`                                        | `rh850fs`       | 2.21.2.1803                   | `rh850`      |
| `bxrl78-4.21.1.deb`                                                | `rl78`          | 4.21.1                        | `rl78`       |
| `bxrx-4.20.1.deb`                                                  | `rx`            | 4.20.1                        | `rx`         |

Launch a bash shell and __clone__ the `bx-docker` repository to the user's home directory (`~`).
```
git clone https://github.com/iarsystems/bx-docker.git ~/bx-docker
```

__Build__ the Docker image for the desired bx`<package>`-`<version>`.deb using the following command.
```
~/bx-docker/scripts/build <path-to>/bx<package>-<version>.deb [image-user:[image-group]]
```
>:warning: The `image-user` and `image-group` parameters are optional. The build script will default to $USER:docker.

The [__build__](scripts/build) script will automatically tag the Docker image to be built as `iarsystems/bx<package>:<version>`.

Multiple images for different packages and their versions can be built in seconds by invoking the `build` script sucessive times with a corresponding installer package. It is possible to invoke `docker images iarsystems/*` to list any Docker images which were already built. For example:
```
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
iarsystems/bxrl78                  4.21.1              7a045de937c8        58 seconds ago      2.09GB
iarsystems/bxarm                   9.10.1              cef45bb09322        5 minutes ago       2.08GB
iarsystems/bxarmfs                 8.50.10.35167       527420cb4fcf        8 minutes ago       1.96GB
iarsystems/bxriscv                 1.40.1              89bd0878856f        About an hour ago   2.05GB
iarsystems/bxarm                   8.50.9              ffcfa26ef829        About an hour ago   2GB
iarsystems/bxrx                    4.20.1              ab1b39f07955        About an hour ago   1.4GB
iarsystems/bxrh850fs               2.21.2.1803         735d80b00832        About an hour ago   2.33GB
iarsystems/bxrh850                 2.21.1              d19afbb0a274        About an hour ago   2.32GB
iarsystems/bxarm                   8.50.6              ad9209426630        About an hour ago   2GB
```


## Setup Host environment
In this section, we will take advantage of __bash aliases__ so we can simplify how we run the containerized IAR Build Tools that were installed within the Docker image. 

The general syntax for declaring an alias in bash is:
>```
>alias <alias-name>='<command-to-run>'
>```
 
The [aliases-set](scripts/aliases-set) script is a general solution to make the usage of the IAR Build Tools seamless. These aliases bind the host's current directory (`$PWD`) to the container's `/build` directory. When relying on these aliases, it is recommended to invoke the tools from the project's __top__ directory (or any level above). That way, the Docker container will have full visibility over all the project's files.
 
### Setting aliases
The aliases for the IAR Build Tools from existing Docker images are set with the [__aliases-set__](scripts/aliases-set) script, using the following syntax:
```
source ~/bx-docker/scripts/aliases-set <package> <version>
```
> ```
> -- Aliases for IAR Build Tools were set.
>    .. Using Docker image: iarsystems/bx<package>:<version>.
> ```

From this point onwards, when any of the IAR Build Tools is invoked, the aliases will take place. The corresponding Docker container for the `iarsystems/bx<package>:<version>` image will be spawned, running the selected tool. When the tool operation is completed, the container is destroyed.
    
It is possible to __list__ all the IAR Build Tools aliases currently set with the following command:
```
alias | grep iarsystems 
```

>:warning: The __aliases-set__ script will only set the aliases for the IAR Build Tools if the corresponding Docker image can be found in the host.

### Sticking with the aliases
Aliases only last for the current bash shell session's lifetime. It is possible to make aliases settings __persistent__.

One way of achieving that is to source the [aliases-set](scripts/aliases-set) script whenever a new bash shell is launched. 

The files that the bash shell reads when a session launches are, in general, `~/.bashrc` and `~/.bash_profile`. With that in mind, the __aliases-set__ script can be sourced while pointing to the desired `iarsystems/bx<package>:<version>` image. 
 
It is possible to perform this change directy from the shell. For example:
```
echo "source ~/bx-docker/scripts/aliases-set <package> <version>" >> ~/.bashrc
```

Now, the aliases for running the IAR Build Tools from the `iarsystems/bx<package>:<version>` Docker image will be available for new shell sessions, __unless__:
* The corresponding `iarsystems/bx<package>:<version>` Docker image becomes inaccessible.
* The bash configuration file that sources the __alias-set__ script was modified and the command has been removed. 
 
>:warning: Ultimately, these aliases are __optional__. An user can take the [aliases-set](scripts/aliases-set) script as initial reference for any suitable customizations.

### Unsetting aliases
 In order to unset all the aliases which were set with the [aliases-set](scripts/aliases-set) use:
```
source ~/bx-docker/scripts/aliases-unset
```
 
>:warning: It is considered to be a good practice to always unset previous aliases for the tools before setting aliases for another Docker image. 
 

## Host license configuration
This section shows how to configure the __license__ on the Host for when using the IAR Build Tools from a Docker container.

The Host license configuration requires an [__IAR License Server__][lms2-url] already __up__, loaded with __activated__ licenses and __reachable__ from the Host.

Executing the build tools __prior properly setting up the license__ will result in a fatal error message: _"No license found."_. For example:
```
icc<arch> --version
```
> ```
>    IAR ANSI C/C++ Compiler V<version>/LNX for <arch>
>    Copyright 1999-2021 IAR Systems AB.
> Fatal error[LMS001]: License check failed. Use the IAR License Manager to
>           resolve the problem.
> No license found. [LicenseCheck:2.17.3.J190,
>           RMS:9.4.0.0023, Feature:<ARCH>BX.EW.COMPILER, Version:1.18]
> Fatal error detected, aborting.
> ```

Override the Host's default license settings to place the license settings into the user's home directory and make it __persistent__.
```
echo "export IAR_LMS_SETTINGS_DIR=$HOME/.lms" >> ~/.bashrc && source ~/.bashrc
```

__Make__ the directory for the license settings.
```
mkdir $IAR_LMS_SETTINGS_DIR
```

__Setup the Host license__ to point to the IAR License Server (LMS2) using `lightlicensemanager` with the following syntax. Replace `<lms2-server-ip>` with the __IAR License Server__ public IP:
```
lightlicensemanager setup -s <lms2-server-ip>
```

Once the license is properly setup, it should be __possible to run__ all the IAR Build Tools for the selected `<arch>` without licensing errors:
```
icc<arch> --version
```
> ```
> IAR ANSI C/C++ Compiler V<version>/LNX for <arch>
> ```

The IAR Build Tools are now __ready to use__.

>:warning: It is possible to customize the `IAR_LMS_SETTINGS_DIR` environment variable to point a different location. The location does not necessarily need to belong to the _build tools user_, but requires read/write/execute (`rwx`) access permissions. If the chosen location is volatile, such as `/tmp/.lms`, the Host license setup will need to be run every time after the Host reboots.
 
>:warning: There are cases where a Firewall could be preventing the Host from reaching the IAR License Server. IAR Systems provides a [__Tech Note__][lms-port-url] covering such cases.
 
>:warning: Access the [__Installation and Licensing User Guide for Linux__][ug-lms2-lx-1-url] for more information.

[ug-lms2-lx-1-url]: https://netstorage.iar.com/SuppDB/Public/UPDINFO/014853/common/doc/lightlicensemanager/UserGuide_LMS2_LX.ENU.pdf


## Using the IAR Build Tools from a Docker container
In this section, we are going to explore some of the IAR Build Tools capabilities using any of the example [projects](projects) for all the supported `<arch>`. Each of them was created with its respective [__IAR Embedded Workbench__](https://www.iar.com/products/overview) and you have them available since the point where you cloned this repository.

### Building a project
With the IAR command line build utility, namely [`iarbuild`](https://www.iar.com/knowledge/support/technical-notes/general/build-from-the-command-line), it is straightforward to build a project that was previously created with the __IAR Embedded Workbench__ for `<arch>`. It enables us to quickly build projects using the same `<build-configuration>` from the `.ewp` project file.

Simplified syntax:
```
iarbuild <relative-path-to>/<project>.ewp [command] <build-configuration> [-parallel <cpu-cores>] [other-options]
```
 
The __`[command]`__ parameter is __optional__. If ommited, it will default to `-make`. Other commands commonly used when build projects are `-build` or `-clean`.

The __`<build-configuration>`__ parameter is __mandatory__. Typically it will be `Debug` or `Release`. This parameter accepts multiple comma-separated _build configurations_ such as `Debug,Release[,MyAnotherCustomBuildConfiguration,...]`. Ultimately this parameter accepts the __` * `__ as wildcard. The wildcard will address all the _build configurations_ in the `<project>`.

The __`-parallel <cpu-cores>`__ parameter is __optional__. It can significantly reduce the required time for building when the host PC has 2 or more CPU cores.

For example, to __build__ using the _"Debug" build configuration_ from the `c-stat.ewp` project, paste the corresponding command from the table below for the `<arch>` in use.
| `<arch>`  | __Command__ |
| :-------- | :--------------------------------------------------------- |
| `arm`     | `iarbuild bx-docker/projects/arm/c-stat.ewp "Debug"`       |
| `riscv`   | `iarbuild bx-docker/projects/riscv/c-stat.ewp "Debug"`     |
| `rh850`   | `iarbuild bx-docker/projects/rh850/c-stat.ewp "Debug"`     |
| `rl78`    | `iarbuild bx-docker/projects/rl78/c-stat.ewp "Debug"`      |
| `rx`      | `iarbuild bx-docker/projects/rx/c-stat.ewp "Debug"`        |

>:warning: Invoke `iarbuild` with no parameters for a more extensive description on its parameter options.

### Static Code Analysis 
With `iarbuild`, it is also possible to perform static code analysis with [C-STAT](https://www.iar.com/cstat) on any existing `<build-configuration>` in an `.ewp` file.

Simplified syntax:
```
iarbuild <relpath-to>/<project>.ewp -cstat_analyze <build-configuration> [-parallel <cpu-cores>]
```
For example, __static code analysis__ with C-STAT using the _"Release" build configuration_ from the `c-stat.ewp` project can be performed by simply pasting the command from the table below which should point to the project created for the `<arch>` in use.
| `<arch>`  | __Command__                                                                                    |
| :-------- | :--------------------------------------------------------------------------------------------- |
| `arm`     | `iarbuild bx-docker/projects/arm/c-stat.ewp -cstat_analyze "Release" -parallel $(nproc)`       |
| `riscv`   | `iarbuild bx-docker/projects/riscv/c-stat.ewp -cstat_analyze "Release" -parallel $(nproc)`     |
| `rh850`   | `iarbuild bx-docker/projects/rh850/c-stat.ewp -cstat_analyze "Release" -parallel $(nproc)`     |
| `rl78`    | `iarbuild bx-docker/projects/rl78/c-stat.ewp -cstat_analyze "Release" -parallel $(nproc)`      |
| `rx`      | `iarbuild bx-docker/projects/rx/c-stat.ewp -cstat_analyze "Release" -parallel $(nproc)`        |

By default, the [C-STAT](https://www.iar.com/cstat) static analysis outputs a SQLite database named `cstat.db`. Then, use `ireport` to process the database and generate an automatic _full HTML report_ containing all the warnings about coding violations for the `<project>`'s selected checks:

Simplified syntax:
```
ireport [--full] --db <relpath-to>/cstat.db --project <relpath-to>/<project>.ewp
```

For example, to generate a __full HTML report__ from the previous project analysis, we can use the `ireport` tool pointing to the project for the corresponding `<arch>` from the table below.
| `<arch>`  | __Command__                                                                                                       |
| :-------- | :---------------------------------------------------------------------------------------------------------------- |
| `arm`     | `ireport --full --db bx-docker/projects/arm/Release/Obj/cstat.db --project bx-docker/projects/arm/c-stat.ewp`     |
| `riscv`   | `ireport --full --db bx-docker/projects/riscv/Release/Obj/cstat.db --project bx-docker/projects/riscv/c-stat.ewp` |
| `rh850`   | `ireport --full --db bx-docker/projects/rh850/Release/Obj/cstat.db --project bx-docker/projects/rh850/c-stat.ewp` |
| `rl78`    | `ireport --full --db bx-docker/projects/rl78/Release/Obj/cstat.db --project bx-docker/projects/rl78/c-stat.ewp`   |
| `rx`      | `ireport --full --db bx-docker/projects/rx/Release/Obj/cstat.db --project bx-docker/projects/rx/c-stat.ewp`       |

The output will be similar to:
> ```
> HTML report generated: bx-docker/projects/<arch>/c-stat.ewp.html
> ```
 
>:warning: When used in conjunction with `iarbuild`, [C-STAT](https://www.iar.com/cstat) will look for a file named `<project>.ewt` in the `<project>`'s folder. This file is automatically generated by the __IAR Embedded Workbench IDE__ when rulesets other than its _Standard Checks_ were selected a `<build-configuration>`. 

### Running interactive containers
The [__aliases-set__](scripts/aliases-set) script brings the `bx<package>-docker-interactive` alias to spawn a container in _interactive mode_:
```
bx<package>-docker-interactive
```
> ```
> To run a command as administrator (user "root"), use "sudo <command>".
> See "man sudo_root" for details.
> ```

For example:
```
iaruser@96a4986f8535:/build$ iarbuild bx-docker/projects/<arch>/c-stat.ewp -build "*" -parallel $(nproc)
```
> ```
> ...
> ...
> Total number of errors: 0
> Total number of warnings: 0
> ```

Type `exit` to exit from the interactive container:
```
iaruser@96a4986f8535:/build$ exit
```

## Additional Resources
If you are new to CI/CD, Docker, Jenkins and Self-Hosted Runners or just want to learn more and see the IAR tools in action, you can find an useful selection of recorded webinars about automated building and testing in Linux-based environments [here!][iar-bx-url]


## Summary
And that is how Docker images containing the [`IAR Build Tools`][iar-bx-url] can be made. The ambition is to provide a quick start towards Docker scenarios.  It is definitely not the only method, neither a replacement for the extensive [_Docker Documentation_][docker-docs-url]. 

The tutorial's sections alongisde the [__scripts__](scripts) and the universal [__Dockerfile__](images/Dockerfile) sum up as a cornerstone for many existing build server topologies. Ultimately, any user can take them as reference for customizing their code to meet particular DevOps requirements.

[iar-bx-url]: https://www.iar.com/bx
[iar-myp-url]: https://iar.com/mypages
[docker-url]: https://www.docker.com
[docker-docs-url]: https://docs.docker.com
[docker-container-url]: https://www.docker.com/resources/what-container
[docker-docs-ubuntu-url]: https://docs.docker.com/engine/install/ubuntu
[lms-port-url]: https://www.iar.com/support/tech-notes/licensing/iar-license-server-how-to-open-udp-5093
[lms2-url]: https://www.iar.com/support/tech-notes/licensing/iar-license-server-tools-lms2
[repo-wiki-url]: https://github.com/IARSystems/bx-docker/wiki
[repo-new-issue-url]: https://github.com/iarsystems/bx-docker/issues/new
[repo-old-issue-url]: https://github.com/iarsystems/bx-docker/issues?q=is%3Aissue+is%3Aopen%7Cclosed
