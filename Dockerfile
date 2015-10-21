FROM particle/buildpack-hal

COPY . /

RUN /bin/bash -c "source /firmware/ci/install_boost.sh"
RUN /firmware/ci/build_boost.sh
RUN /scripts/build-all-platforms.sh

WORKDIR /
