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

# Main image combining base image, toolchain, and DeviceOS sources
# Some sensible default
FROM ${DOCKER_IMAGE_NAME}:${BASE_VERSION} as main
ENV FIRMWARE_REPO=not-used
WORKDIR /
COPY --from=deviceos / /firmware/

# This could be a separate step, but for now to simplify CI updates
# this is integrated into the main step
ENV PATH="/root/.particle/bin":$PATH
RUN \
  curl https://prtcl.s3.amazonaws.com/install-apt.sh | sh \
  && apt-get clean \
  && apt-get purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && cat /etc/*release \
  && prtcl toolchain:install source:/firmware \
  && prtcl toolchain:use source:/firmware \
  && echo ":::: Using $(which arm-none-eabi-gcc)" \
  && echo ":::: With directories and files" \
  && ls -la /root/.particle \
  && ls -la /root/.particle/toolchains \
  && ls -la /root/.particle/bin

# Platform image, prebuilding the modules required for building the application
FROM ${DOCKER_IMAGE_NAME}:${MAIN_VERSION} as platform
ARG PLATFORM
ARG PREBUILD
ENV FIRMWARE_REPO=not-used
# PLATFORM and PREBUILD are passed as environment variables to RUN commands
RUN /bin/prebuild-platform

# Test image adding on things required for running the unit tests
FROM ${DOCKER_IMAGE_NAME}:${MAIN_VERSION} as test
RUN apt-get update -q && apt-get install -qy gcc-4.9 g++-4.9 zlib1g-dev \
  && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 \
  && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 60 \
  && apt-get clean && apt-get purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
