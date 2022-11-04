# Tutorial<br/> Building embedded applications with<br/> the IAR Build Tools on Docker Containers

[Docker][url-docker-gs] is generally recognized as best practice to achieve automatically reproducible build environments. It provides means for containerizing self-sufficient build environments resulting from the requirements described in a Dockerfile.

This tutorial provides a [Dockerfile](Dockerfile) and helper scripts that provide means for building embedded applications with the [IAR Build Tools][url-iar-bx] from a [container][url-docker-container].

>:warning: It is recommended to follow this tutorial on a test environment.


## Disclaimer
The information in this repository is subject to change without notice and does not represent a commitment on any part of IAR Systems. While the information contained 
herein is assumed to be accurate, IAR Systems assumes no responsibility for any errors or omissions.


## Pre-requisites
For completing this tutorial you are going to need:
- Understanding on how to use command-line tools. 
- An [__IAR Build Tools__][url-iar-bx] installer package
   - in the __.deb__ format.
   - >:bulb: Feel free to [__contact us__][url-iar-contact] if you would like to learn how to get access to the installers.
- A recent __x86_64/amd64__ machine
   - with Ubuntu 18+ (or Debian 10+, or Fedora 35+, ...), or Windows 10 21H1+ (build 19043), and
   - connected to the Internet.
   - >:bulb: in this tutorial, this machine will be referred as `DOCKER_HOST`.
- An [__IAR LMS2 License Server__](https://links.iar.com/lms2-server)
   - with activated license(s) for the product in the __.deb__ package,
   - reachable from the Linux machine.


## Conventions
The following conventions are going to be used during this tutorial:
| __Placeholder__ | __Meaning__        | __Valid values__   |
| :-------------- | :----------------- | :----------------- |
| `<arch>`        | Architecture       | `arm`, `riscv`, `rh850`, `rl78` or `rx`                                                  |
| `<package>`     | Product package    | `arm`, `armfs`, `riscv`, `riscvfs`, `rh850`, `rh850fs`, `rl78`, `rl78fs`, `rx` or `rxfs` |
| `<version>`     | Package version    | `major`.`minor`.`patch` `[.build]`                                                       |

Consider the following examples:
| __Installer package__              | __Meaning__                                   | __Placeholders to be replaced__ |
| :-----------------------------     | :-------------------------------------------- | :------------------------------ |
| bx**arm**-**9.20.4**.deb           | IAR Build Tools for Arm<br/>version 9.20.4    | `<arch>`=`arm`<br/>`<package>`=`arm`<br/>`<version>`=`9.20.4` |
| bx**armfs**-**8.50.10.35167**.deb  | IAR Build Tools for Arm<br/>[Functional Safety Edition][url-iar-fs]<br/>version 8.50.10.35167 | `<arch>`=`arm`<br/>`<package>`=`armfs`<br/>`<version>`=`8.50.10.35167` |
| bx**riscv**-**3.10.1**.deb         | IAR Build Tools for RISC-V<br/>version 3.10.1 | `<arch>`=`riscv`<br/>`<package>`=`riscv`<br/>`<version>`=`3.10.1` |


## Installing Docker
For installing the Docker Engine on the `DOCKER_HOST`, follow the [official instructions][url-docker-docs-install].

Alternatively, the procedure below should work for most `DOCKER_HOST`s:
| __Linux (Bash)__ | __Windows__ |
| --------- | ----------- |
| <pre>curl -fsSL https://get.docker.com -o get-docker.sh<br>sh ./get-docker.sh</pre> | Install [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/) |

In order to execute Docker commands, the current user (`$USER`) must be in the `docker` group. Execute:
| __Linux (Bash)__ | __Windows__ |
| --------- | :-----------: |
| <pre>sudo usermod -aG docker $USER</pre><br>Then logout and login again for the changes to take effect. | -NA- |


## Building a Docker image
Before being able to run a Docker container, we need to have a Docker image containing its required environment. A Dockerfile contains instructions that describe how an image should be built.

This [__Dockerfile__](Dockerfile) was created as an universal template to build images with the IAR Build Tools.

The [__`build`__](build) script will use [`docker build ...`][url-docker-docs-build] with the Dockerfile, alongside an installer package (__bx`<package>`-`<version>`.deb__) to create one image.

In order to build the image, clone the [bx-docker][url-repo] repository to the user's home directory:
| __Linux (Bash)__ | __Windows (Powershell)__ |
| --------- | ----------- |
| <pre>git clone https://github.com/iarsystems/bx-docker.git ~/bx-docker</pre> | <pre>git clone https://github.com/iarsystems/bx-docker.git $home/bx-docker</pre> |

Then, invoke the __`build`__ script pointing to the installer package:
| __Linux (Bash)__ | __Windows (Powershell)__ |
| --------- | ----------- |
| <pre>~/bx-docker/build /path/to/bx<package>-<version>.deb</pre> | <pre>$home/bx-docker/build /path/to/bx<package>-<version>.deb</pre> |

Depending on your system's characteristics, it might take a while to build the image. This process usually might range from seconds to a few minutes. In the end, the __`build`__ script will automatically tag the image as __iarsystems/bx`<package>`:`<version>`__.

>:bulb: Invoke the __`build`__ script once for each installer package you have so you will get one dedicated image for each of them.

Once you're done with image creation, execute [`docker images ...`][url-docker=docs-images] to list all the created images:
```
docker images iarsystems/*
```
And you will get an output similar to this, depending on the images you've created:
>```
>REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
>iarsystems/bxarm                   9.20.4              cef45bb09322        5 minutes ago       2.42GB
>iarsystems/bxarmfs                 9.20.3.45167        527420cb4fcf        8 minutes ago       2.37GB
>iarsystems/bxriscv                 3.30.1              89bd0878856f        About an hour ago   2.25GB
>```


## Setting up the license
The IAR Build Tools require an available network license to operate.

In order to set up the license for all the containers in the Linux machine, execute the [__`setup-license`__](setup-license) script pointing to the image's \<tagname:version\> followed by the IAR LMS2 License Server's IP:
| __Linux (Bash)__ | __Windows (Powershell)__ |
| --------- | ----------- |
| <pre>~/bx-docker/setup-license iarsystems/bx\<package\>:\<version\> \<lms2-server-ip\></pre> | <pre>$home/bx-docker/setup-license iarsystems/bx\<package\>:\<version\> \<lms2-server-ip\></pre> |

The __`setup-license`__ script will prepare a [Docker volume][url-docker-docs-volume] which can be shared among all the containers running on the Linux machine for persistent storage of the license configuration.

>:bulb: This step must be performed only once. The Docker Engine will never erase this (or any other) named volume, even after the containers which made use of it are stopped or removed.

>:bulb: If your network has multiple build nodes (Linux machines), __`setup-license`__ must be performed __individually__ on all of them.


## Running a container
In this section, we will use the image we created to run a container so that later we can build a project.

The [bx-docker][url-repo] repository comes with projects created in the [IAR Embedded Workbench][url-iar-ew] for the supported target architectures. 

Access the [projects](projects) sub-directory:
| __Linux (Bash)__ | __Windows (Powershell)__ |
| --------- | ----------- |
| <pre>cd ~/bx-docker/projects</pre> | <pre>cd $home/bx-docker/projects</pre> |

The [__`run`__](run) script will use the [`docker run ...`][url-docker-docs-run] command with all the necessary parameters to run the container. 

Execute:
| __Linux (Bash)__ | __Windows (Powershell)__ |
| --------- | ----------- |
| <pre>~/bx-docker/run iarsystems/bx\<package\>:\<version\></pre>Follow the instructions provided by the __`run`__ script output for sourcing the __`aliases-set`__ script. | <pre>$home/bx-docker/run iarsystems/bx\<package\>:\<version\></pre>The __`aliases-set`__ script is invoked automatically by run and applied to the current shell session. |

Containers spawned by the __`run`__ script will bind mount the current directory (`pwd`) to the Docker image's working directory (`pwd`). That way, these containers cannot access any parent directories. Make sure to always run a container from the project's top-directory from which all the project's files are accessible.

>:bulb: Use `docker run --help` for more information.


## Executing the Build Tools
The [`docker exec ...`][url-docker-docs-exec] command can execute a command in a running container. Oftentimes, these command lines might become too long for typing every single time.

When you spawned the container using the [__`run`__](scripts/run) script, you also got [bash aliases](https://en.wikipedia.org/wiki/Alias_%28command%29) set for all the IAR Build Tools from the image you have selected to work with. These aliases encapsulated the required `docker exec ...` commands in such a way that the Linux machine can now execute all the IAR Build Tools seamlessly.

>:bulb: Use `docker exec --help` for more information.

### Build the project with __iarbuild__
The IAR Command Line Build Utility (`iarbuild`) can build (or analyze) a __`<project>`.ewp__.

The simplified `iarbuild` syntax is:
```
iarbuild relative/path/to/<project>.ewp [command] <build-cfg>
```

For example, use `iarbuild` with the __`-build <build-cfg>`__ command to build the __hello-world.ewp__ project using the build configuration for "Release": 
```
iarbuild <arch>/hello-world.ewp -build Release
```

>:bulb:  Invoke `iarbuild` with no parameters for detailed description.


### Performing static code analysis
Static Code Analysis can be performed with [IAR C-STAT][url-iar-cstat].

C-STAT is an add-on to the IAR Build Tools that help you to ensure code quality in your applications.
If you have C-STAT, `iarbuild` can be used with the __`-cstat_analyze <build-cfg>`__ command to analyze the project.

For performing an analysis using the "Release" configuration for the __hello-world.ewp__ project, execute: 
```
iarbuild <arch>/hello-world.ewp -cstat_analyze Release
```

The analysis results are stored in an SQLite database named __cstat.db__. This database can be used for generating an analysis report containing warnings about coding violations for the project's ruleset selection.

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

>:bulb: On terminal, you can use `lynx hello-world.html` to visualize the text content of the HTML report. This report contains graphical elements, so use a Desktop Web Browser to visualize its full contents.

>:bulb: Customized ruleset selections for a __`<project>`.ewp__ are automatically stored in a corresponding __`<project>`.ewt__. If the project is under version control, it is advised to check-in this file as well.

   
## Issues
Found an issue or have a suggestion related to the [__bx-docker__][url-repo] tutorial? Feel free to use the public issue tracker.
- Do not forget to take a look at [earlier issues][url-repo-issue-old].
- If creating a [new][url-repo-issue-new] issue, please describe it in detail.


## Summary
And that is how the [IAR Build Tools][url-iar-bx] can run in containers.
   
Now you can learn from the scripts, from the [Dockerfile](Dockerfile) and from the official [Docker Documentation][url-docker-docs] which together sum up as a cornerstone for your organization to use as it is or to customize them so that the containers run in suitable ways for particular needs.

[Here][url-iar-bx] you can find additional resources such as on-demand webinars about the IAR Build Tools within automated workflows scenarios.

   
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
