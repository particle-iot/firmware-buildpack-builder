ARG BUILDPACK_BASE
ARG BUILDPACK_BASE_VERSION
ARG DEVICEOS_BASE_IMAGE
ARG DEVICEOS_VERSION
ARG DOCKER_IMAGE_NAME
ARG BASE_VERSION
ARG MAIN_VERSION

# Base image, based on a buildpack with binaries from this repo
FROM ${BUILDPACK_BASE}:${BUILDPACK_BASE_VERSION} as base
COPY bin /usr/bin

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
  printf 'Acquire::http::Timeout "30";\nAcquire::ftp::Timeout "30";\nAcquire::Retries "5";\n' | sudo tee /etc/apt/apt.conf.d/99timeout > /dev/null \
  && curl https://prtcl.s3.amazonaws.com/install-apt.sh | sh \
  && apt-get clean \
  && apt-get purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && cat /etc/*release \
  && prtcl toolchain:install source:/firmware --quiet \
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
RUN apt-get update -qy \
  && apt-get install -qy software-properties-common \
  && add-apt-repository ppa:ubuntu-toolchain-r/test -y \
  && apt-get update -qy \
  && apt-get install gcc g++ gcc-11 g++-11 -qy \
  && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 1100 \
                         --slave /usr/bin/g++ g++ /usr/bin/g++-11 \
                         --slave /usr/bin/gcov gcov /usr/bin/gcov-11 \
                         --slave /usr/bin/gcc-ar gcc-ar /usr/bin/gcc-ar-11 \
                         --slave /usr/bin/gcc-ranlib gcc-ranlib /usr/bin/gcc-ranlib-11 \
  && update-alternatives --install /usr/bin/cpp cpp /usr/bin/cpp-11 1100 \
  && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 1100 \
  && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 1100 \
  && update-alternatives --set cc /usr/bin/gcc \
  && update-alternatives --set c++ /usr/bin/g++ \
  && add-apt-repository --remove ppa:ubuntu-toolchain-r/test -y \
  && apt-get clean && apt-get purge \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && gcc --version \
  && g++ --version

SHELL ["/bin/bash", "--login", "-i", "-c"]
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=12
RUN mkdir -p $NVM_DIR \
  && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash \
  && source /root/.bashrc \
  && nvm install $NODE_VERSION \
  && nvm alias default $NODE_VERSION \
  && nvm use default
SHELL ["/bin/bash", "--login", "-c"]

