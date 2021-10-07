# 
# Copyright (c) 2020-2021 IAR Systems AB
#
# Dockerfile for the IAR Build Tools (BX)
#   - Creates a bare minimal Docker image for the IAR Build Tools
#
# See LICENSE for detailed license information
#

FROM ubuntu:20.04

# User's UID, GID, package, architecture and version 
# These arguments are taken from scripts/build execution
ARG  USER_ID \
     GROUP_ID \
     PKG_FILE \
     PKG_NAME \
     BX_ARCH \
     BX_VERSION \
     IMG_TZ

# [Optional] Configure Ubuntu's timezone
ENV  TZ=${IMG_TZ}
RUN  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
     echo $TZ > /etc/timezone

# [Optional] Configure the Ubuntu's locale (useful for CMake users)
ENV  LC_ALL=C

# Update the Ubuntu packages catalog, install packages and cleanup
# Packages reasoning
#  sudo                      : convenience for interactive mode
#  libsqlite3-0              : used by iarbuild
#  libxml2, libicu66, tzdata : used by C-STAT
RUN  apt-get update && \
     DEBIAN_FRONTEND="noninteractive" apt-get install -y \
     sudo \
     libsqlite3-0 \
     libxml2 libicu66 tzdata && \
     apt-get clean autoclean && \
     apt-get autoremove -y && \
     rm -rf /var/lib/apt/lists/*
     
# The environment variables set with ENV will become available for when running the container
# The IAR Build Tools are going to be appended to the tip of the search $PATH
# When BX<package> is installed, a symbolic link named `bx<package>` is automatically created in $IAR_PATH
# The IAR_LMS_SETTINGS_DIR can be used to override the default license configuration path (default: /usr/local/etc/IARSystems)
ENV  IAR_PATH="/opt/iarsystems"
ENV  IAR_BX_PATH="${IAR_PATH}/${PKG_NAME}"
ENV  IAR_LMS_SETTINGS_DIR="/.lms"
ENV  IAR_BUILD_PATH="/build"
ENV  PATH="${IAR_BX_PATH}/${BX_ARCH}/bin:${IAR_BX_PATH}/common/bin:$PATH"

# Create the image with an user named `iaruser` using the same UID from the host's user
# For convenience, the user `iaruser` will be added to the "sudo" group 
RUN  groupadd -g ${GROUP_ID} docker && \
     useradd --no-log-init --create-home --uid ${USER_ID} --gid ${GROUP_ID} iaruser && \
     echo "iaruser:docker" | chpasswd && \
     adduser iaruser sudo 

# Copy the .deb package from the host to the image's /tmp directory
COPY ${PKG_FILE} /tmp

# Install the .deb package. Then remove the temporary package from the image
RUN  dpkg --install /tmp/${PKG_FILE} && \ 
     rm /tmp/${PKG_FILE}

# Setup the IAR_BUILD_PATH
RUN  mkdir ${IAR_BUILD_PATH} && \
     chmod ug+rwx -R ${IAR_BUILD_PATH} && \
     chown iaruser:docker ${IAR_BUILD_PATH}

# Setup the IAR_LMS_SETTINGS_DIR
RUN  mkdir -p ${IAR_LMS_SETTINGS_DIR} && \
     chmod ug+rwx -R ${IAR_LMS_SETTINGS_DIR} && \
     chown iaruser:docker ${IAR_LMS_SETTINGS_DIR}

# Set the user mask to allow group to write
RUN  echo "umask 002" >> /home/iaruser/.bashrc

# Allow the user to sudo without password
RUN  sed -i '$ a iaruser     ALL=(ALL) NOPASSWD:ALL' /etc/sudoers

# Setup the initial user and work directory for the image
USER iaruser 
WORKDIR ${IAR_BUILD_PATH}
