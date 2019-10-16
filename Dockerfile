ARG BUILDPACK_BASE
ARG BUILDPACK_BASE_VERSION
ARG DEVICEOS_BASE_IMAGE
ARG DEVICEOS_VERSION
ARG DOCKER_IMAGE_NAME
ARG BASE_VERSION
ARG MAIN_VERSION

# Base image, based on a buildpack with binaries from this repo
FROM ${BUILDPACK_BASE}:${BUILDPACK_BASE_VERSION} as base
COPY bin /bin

# DeviceOS image, containing just the DeviceOS sources
FROM ${DEVICEOS_BASE_IMAGE}:${DEVICEOS_VERSION} as deviceos
WORKDIR /

# Main image combining base image and DeviceOS sources
# Some sensible default
FROM ${DOCKER_IMAGE_NAME}:${BASE_VERSION} as main
ENV FIRMWARE_REPO=not-used
WORKDIR /
COPY --from=deviceos / /firmware/

# Platform image, prebuilding the modules required for building the application
FROM ${DOCKER_IMAGE_NAME}:${MAIN_VERSION} as platform
ARG PLATFORM
ARG PREBUILD
ENV FIRMWARE_REPO=not-used
# PLATFORM and PREBUILD are passed as environment variables to RUN commands
RUN /bin/prebuild-platform

# Test image adding on things required for running the unit tests
FROM ${DOCKER_IMAGE_NAME}:${MAIN_VERSION} as test
ARG CMAKE_INSTALL_SCRIPT_URL
RUN sed -i -e 's/http:\/\/archive/mirror:\/\/mirrors/' -e 's/\/ubuntu\//\/mirrors.txt/' /etc/apt/sources.list \
  && apt-get update -q && apt-get install -qy wget gcc-4.9 g++-4.9 parallel \
  && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 \
  && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 60 \
  && curl -o /tmp/cmake_install.sh -sSL ${CMAKE_INSTALL_SCRIPT_URL} \
  && chmod +x /tmp/cmake_install.sh \
  && /tmp/cmake_install.sh --skip-license --prefix=/usr/local \
  && apt-get clean && apt-get purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
