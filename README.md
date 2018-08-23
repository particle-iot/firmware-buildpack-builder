# Particle Firmware buildpack scripts

[![](https://imagelayers.io/badge/particle/buildpack-particle-firmware:latest.svg)](https://imagelayers.io/?images=particle/buildpack-particle-firmware:latest 'Get your own badge on imagelayers.io')

This repo is used by [`firmware` Travis CI build](https://travis-ci.org/spark/firmware) to build, test and push images to Docker Hub.

| |
|---|
|  **Particle firmware (you are here)**  |
| [HAL](https://github.com/particle-iot/buildpack-hal) / [Legacy](https://github.com/particle-iot/buildpack-0.3.x)   |
| [Base](https://github.com/particle-iot/buildpack-base) |

## Running scripts locally when developing a buildpack

First clone and set up this repo:
```
$ git clone git@github.com:particle-iot/firmware-buildpack-builder.git
$ cd firmware-buildpack-builder
$ export FIRMWARE_PATH=path/to/particle/firmware
$ export DOCKER_IMAGE_NAME=particle/your-firmware-name
```

### To build a firmware buildpack (containing just toolchain + firmware) run:
```
$ script/build-image
```
**Note:** the firmware buildpack inherits `BUILDPACK_VARIATION` image specified in `.buildpackrc` file in your firmware. If you need to use different toolchain it is recommended to create a different variation and specify it in the `.buildpackrc` file.

### To build a buildpack with precompiled intermediate files for a platform used by the cloud compiler (same as firmware buildpack + it runs `make` in all important dirs)

First empty the `RELEASE_PLATFORMS` array in `.buildpackrc` and then add your platform to `PRERELEASE_PLATFORMS`. Then run:

```
$ script/build-platform-images
```

Once the images are built you can test them with:

```
$ docker run --rm -it -v EXAMPLE_APP_DIRECTORY:/input -e PLATFORM_ID=EXAMPLE_PLATFORM_ID $DOCKER_IMAGE_NAME
```

## Flow inside Travis CI

When doing a Travis CI job following scripts should be executed in order:

1. `scripts/build-image` which will:
  1. Build `$DOCKER_IMAGE_NAME` image
  2. Build `$DOCKER_IMAGE_NAME-test` image which includes test tools
2. `scripts/run-tests-in-container` which will:
  1. Run [`/bin/run-tests`](bin/run-tests) inside of `$DOCKER_IMAGE_NAME-test` container

3. if previous script was a success then `scripts/push-image` which:
  1. if `TRAVIS_TAG` was set will:
    1. push `$DOCKER_IMAGE_NAME:$TRAVIS_TAG` to Docker Hub
    2. create prebuild images for each platform specified in [`.buildpackrc`](https://github.com/particle-iot/firmware/blob/develop/.buildpackrc) `RELEASE_PLATFORMS` and `PRERELEASE_PLATFORMS`
    3. push those images too

### Why is it building so many images?

Here's breakout of all images:

* `$DOCKER_IMAGE_NAME:$TRAVIS_TAG` is an image that contains the toolchain (usually from [`buildpack-hal`](https://github.com/particle-iot/buildpack-hal)) and a copy of firmware at specific version (one that the scripts were run against)
* `$DOCKER_IMAGE_NAME-test` contains the same things as `$DOCKER_IMAGE_NAME:$TRAVIS_TAG` but also bundles host `gcc` for running unit tests. This one is a throw away
* `$DOCKER_IMAGE_NAME:$TRAVIS_TAG-$PLATFORM` contains the same things as `$DOCKER_IMAGE_NAME:$TRAVIS_TAG` but also intermediate files for `$PLATFORM` making compilation for it faster

#### Example `.travis.yml` file

If you're forking our [firmware repository](https://github.com/particle-iot/firmware/) you can build your own images with firmware.
To do so, edit `.travis.yml` file to include:

```yaml
sudo: required  
services:  
  - docker
install:  
  - docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
  - wget https://github.com/particle-iot/firmware-buildpack-builder/archive/master.tar.gz -O - | tar -xz -C ../ --strip-components 1
  - ../scripts/build-image
script:  
  - ../scripts/run-tests-in-container
after_success: ../scripts/push-image
env:  
  - DOCKER_IMAGE_NAME=username/my-image
```

**Note:** remember to change `DOCKER_IMAGE_NAME` to your image name.

After this add `DOCKER_HUB_EMAIL`, `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD` environment variables to Travis CI setting.

Having done all this, Travis should build image every time a change is pushed. It will also tag Docker images when a git tag is set.
