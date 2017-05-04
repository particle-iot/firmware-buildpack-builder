#!/bin/bash

set -xe

export DOCKER_IMAGE_NAME=particle/buildpack-particle-firmware
export TRAVIS_TAG=0.5.1-pi.13

rsync -a --exclude .git --exclude 'build/target' /home/monkbroc/Programming/firmware-rpi/* firmware/
cd firmware
make clean

../scripts/build-image
../scripts/push-image
