FROM particle/buildpack-hal:0.0.4

COPY . /

RUN apt-get -y install wget
RUN /scripts/build-all-platforms.sh

WORKDIR /
