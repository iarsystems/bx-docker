# 
# Copyright (c) 2020-2024 IAR Systems AB
#
# Dockerfile for the IAR Build Tools (BX)
#
# See LICENSE for detailed license information
#

#
# The base layer for the bx-docker image
#  - 2022Q3+ toolchain: Ubuntu 20.04 (*default)
#  - earlier toolchain: Ubuntu 18.04
#
FROM ubuntu:20.04

#
# Environment variables
# bx-docker - issue #22 - starting from bxarm-9.30.1, iarbuild tries to create $HOME/.iar.
#                         For the Ubuntu 20.04 container, $HOME must be manually set.
#
ENV  LC_ALL=C \
     DEBIAN_FRONTEND="noninteractive" \
     HOME=/build

#
# Allows specific image name to be copied from the Docker context
#
ARG BX_PACKAGE_DEB=bx*.deb

#
# Copy the installer package from the Docker context to /tmp
#
COPY ${BX_PACKAGE_DEB} /tmp

#
# Install the necessary packages and cleanup
#  sudo                      : required by earlier versions of bx*.deb
#  libsqlite3-0              : required by iarbuild
#  libxml2, tzdata           : required by C-STAT
#  git                       : added for convenience
#
RUN  apt-get update && \
     apt-get install -y sudo libsqlite3-0 libxml2 tzdata git && \
     apt-get install -y /tmp/bx*.deb && \
     apt-get clean autoclean autoremove && \
     rm -rf /var/lib/apt/lists/* /tmp/*.deb

#
# Set the default Working directory for the image
#
WORKDIR ${HOME}
