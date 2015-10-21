FROM particle/buildpack-hal

COPY ../firmware /firmware
COPY . /

RUN /scripts/build-all-platforms.sh

WORKDIR /
