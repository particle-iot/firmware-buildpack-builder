FROM particle/buildpack-hal

COPY . /

RUN /scripts/build-all-platforms.sh

WORKDIR /
