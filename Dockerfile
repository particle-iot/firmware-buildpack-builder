FROM particle/buildpack-hal

COPY . /

RUN /scripts/build-all-platforms.sh
RUN source /firmware/ci/install_boost.sh
RUN /firmware/ci/build_boost.sh

WORKDIR /
