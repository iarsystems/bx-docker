# 
# Copyright (c) 2020-2022 IAR Systems AB
#
# Dockerfile for the IAR Build Tools (BX)
#
# See LICENSE for detailed license information
#

#
# Base image layer 
#   The IAR Build Tools typically supports Ubuntu 18.04 or Ubuntu 20.04
#
FROM ubuntu:18.04

#
# Environment variables
#
ENV  LC_ALL=C \
     DEBIAN_FRONTEND="noninteractive"

#
# Copy from the Docker context to /tmp
#
COPY bx*.deb /tmp

#
# Install the necessary packages and cleanup
#  sudo                      : required by bx*.deb
#  libsqlite3-0              : required by iarbuild
#  libxml2, tzdata           : required by C-STAT
#
RUN  apt-get update && \
     apt-get install -y sudo libsqlite3-0 libxml2 tzdata /tmp/bx*.deb && \
     apt-get clean autoclean autoremove && \
     rm -rf /var/lib/apt/lists/* /tmp/*.deb

#
# Set the default Working directory for the image
#
WORKDIR /build

