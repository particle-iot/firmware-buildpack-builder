FROM particle/buildpack-hal

COPY . /

RUN apt-get -y install wget
RUN /scripts/build-all-platforms.sh

WORKDIR /
