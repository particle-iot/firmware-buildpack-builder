FROM particle/buildpack-hal:0.0.3

COPY . /

RUN apt-get -y install wget
RUN /scripts/build-all-platforms.sh

WORKDIR /
