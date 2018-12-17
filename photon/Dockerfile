FROM particle/buildpack-particle-firmware:dd9d5512a343d646176ebfb8c90fc6d672264583-photon-source

COPY bin /bin
ARG PLATFORM
ARG MODULAR
RUN /bin/prebuild-platform ${PLATFORM}
