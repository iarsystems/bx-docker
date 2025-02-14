# 
# Copyright (c) 2020-2025 IAR Systems AB
#
# Dockerfile for the IAR Build Tools (BX)
#
# See LICENSE for detailed license information
#
#
# These arguments comes from the `build` utility
# Knowingly `safe defaults` are used if not specified otherwise
#
#  - 2022Q3+ IAR toolchains: Ubuntu Linux v20.04 (*default)
#  - earlier IAR toolchains: Ubuntu Linux v18.04
ARG BX_UBUNTU_VERSION=20.04
#
# Stage 1: The Ubuntu base image compatible required by BX
#
FROM ubuntu:${BX_UBUNTU_VERSION} AS base
#
# Copy the installer package from the context to `/tmp`
#
ARG BX_DEB_FILE=bx*-?.??.?.deb
ARG BX_DEV_DEB_FILE=bx*-cspy-device-support*.deb
COPY ${BX_DEB_FILE} ${BX_DEV_DEB_FILE} /tmp/
#
# Install the necessary packages and cleanup
#  sudo                      : required by earlier versions of bx*.deb
#  libsqlite3-0              : required by iarbuild
#  libxml2, tzdata           : required by C-STAT
#  udev, libusb-1.0-0        : required by C-SPY (in bxarm-9.50+)
#
RUN apt-get -qq update > /dev/null && \
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
libsqlite3-0 \
libxml2 tzdata \
udev libusb-1.0-0 usbutils \
> /dev/null
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq /tmp/*.deb

ARG BX_INCLUDE_CMAKE
ARG BX_INCLUDE_GIT
ARG BX_INCLUDE_SUDO
RUN test ${BX_INCLUDE_CMAKE} -eq 1 \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends cmake > /dev/null \
|| echo " **** BX_INCLUDE_CMAKE is [off]."
RUN test ${BX_INCLUDE_GIT} -eq 1 \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends git > /dev/null \
|| echo " **** BX_INCLUDE_GIT is [off]."
RUN test ${BX_INCLUDE_SUDO} -eq 1 \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends sudo > /dev/null \
|| echo " **** BX_INCLUDE_SUDO is [off]."
#
# Slimming image
#
ARG BX_PKG_ARCH=arm
ARG BX_EXCLUDE_CMSIS
ARG BX_EXCLUDE_DOCS
ARG BX_EXCLUDE_SRC
ARG BX_EXCLUDE_JPN_FILES
RUN test $BX_EXCLUDE_CMSIS -eq 1 \
&& find /opt/iar* -maxdepth 3 -type d -name CMSIS -exec rm -r {} + \
|| echo " **** BX_EXCLUDE_CMSIS is [off]."
RUN test $BX_EXCLUDE_DOCS -eq 1 \
&& find /opt/iar* -maxdepth 3 -type d -name doc -exec rm -r {} + \
|| echo " **** BX_EXCLUDE_DOCS is [off]."
RUN test $BX_EXCLUDE_SRC -eq 1 \
&& find /opt/iar* -maxdepth 3 -type d -name src -exec rm -r {} +; \
   find /opt/iar* -maxdepth 4 -type d -name template -exec rm -r {} + \
|| echo " **** BX_EXCLUDE_SRC is [off]."
RUN test $BX_EXCLUDE_JPN_FILES -eq 1 \
&& find /opt/iar* -regextype posix-extended -regex '.*\.(JPN|locale.ja_JP)$' -exec rm -r {} + \
|| echo " **** BX_EXCLUDE_JPN_FILES is [off]."
RUN rm -rf /var/lib/apt/lists/* /tmp/*.deb
#
# Patch file modes: post-mortem for earlier installers
#
RUN \
find /opt/iar* -type f -regextype posix-extended \
-iregex '.*(\.(a|bat|board|c|cmake|cpp|css|deb|dat|ew[pdtw]|featureinfo|flash|gif|gitignore|h|html|i|i79|icf|ini|ipp|js|json|ld|m[od]?|mar|menu|out|pdf|png|productinfo|py|rc|rpm|rtebuild|s|sct|scvd|so(\.?[0-9]?).*|src|suc|txt|uvoptx|uvprojx|xml|xsd|zip)|\/inc\/.*|\/src\/.*)$' \
-exec chmod 0644 {} +;
#
# Stage 2: Avoids the /tmp layer, reducing the final image size
#
FROM ubuntu:${BX_UBUNTU_VERSION} AS final
#
# Environment variables
# bx-docker - issue #22 - starting from bxarm-9.30.1, iarbuild tries to create $HOME/.iar.
#                         For the Ubuntu 20.04 container, $HOME must be manually set.
#
ARG BX_PKG_ARCH=arm
ARG BX_ASM_EXEC=iasm
ENV LC_ALL=C \
PATH=/opt/iarsystems/bx$BX_PKG_ARCH/$BX_PKG_ARCH/bin:/opt/iarsystems/bx$BX_PKG_ARCH/common/bin:$PATH \
CC=icc$BX_PKG_ARCH \
CXX=icc$BX_PKG_ARCH \
ASM=$BX_ASM_EXEC$BX_PKG_ARCH \
HOME=/workdir
#
# Copy root dir from `base` to the `final` image
#
COPY --from=base / /
#
# Set working directory in the `final` image
#
WORKDIR ${HOME}
#
# Entrypoint: command invoked when a container starts
#
ENTRYPOINT ["/bin/bash"]
