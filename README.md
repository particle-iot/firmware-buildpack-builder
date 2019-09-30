# Particle Firmware buildpack scripts

[![](https://imagelayers.io/badge/particle/buildpack-particle-firmware:latest.svg)](https://imagelayers.io/?images=particle/buildpack-particle-firmware:latest 'Get your own badge on imagelayers.io')

This repo is used by [`DeviceOS` Travis CI build](https://travis-ci.org/spark/device-os) to build, test and push images to Docker Hub.

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
$ export TAG=a.b.c-rc.X
```

### To build a firmware buildpack (containing just toolchain + firmware) run:
```
$ scripts/build-image
```
**Note:** the firmware buildpack inherits `BUILDPACK_VARIATION` image specified in `.buildpackrc` file in your firmware. If you need to use different toolchain it is recommended to create a different variation and specify it in the `.buildpackrc` file.

### To build a buildpack with precompiled intermediate files for a platform used by the cloud compiler (same as firmware buildpack + it runs `make` in all important dirs)

Make sure the platform is in `RELEASE_PLATFORMS` array in `.buildpackrc`. Then run:

```
$ scripts/build-platform-images
```

Once the images are built you can test them with:

```
$ export PLATFORM=argon
$ docker run --rm -it -v EXAMPLE_APP_DIRECTORY:/input -e PLATFORM_ID=EXAMPLE_PLATFORM_ID $DOCKER_IMAGE_NAME:$TAG-$PLATFORM
```

## Flow inside Travis CI

When doing a Travis CI job following scripts should be executed in order:

1. `scripts/ci` which will:
  1. Build DeviceOS source image `particle/device-os:$TAG`, excluding anything unnecessary using the `.dockerignore` in DeviceOS sources
  2. Build base image `$DOCKER_IMAGE_NAME:$REF-$BUILDPACK_VERSION-$BUILDPACK_VARIATION` adding scripts from `bin` folder to the base buildpack containing the toolchain (usually [`buildpack-hal`](https://github.com/particle-iot/buildpack-hal))
  3. Build main image `$DOCKER_IMAGE_NAME:$TAG-$REF-$BUILDPACK_VERSION-$BUILDPACK_VARIATION` adding DeviceOS sources from `$FIRMWARE_PATH`
  4. Build test image `$DOCKER_IMAGE_NAME:$TAG-$REF-$BUILDPACK_VERSION-$BUILDPACK_VARIATION-test` for running unit tests, adding host gcc compiler and other necessary tools
  5. Run [`/bin/run-tests`](bin/run-tests) inside the container created from test image
2. (Optional, only if Travis is responsible for pushing prebuilt platform images to Docker Hub) `scripts/push-image`, which will:
  1. Push main image to Docker Hub
  2. Create prebuild platform images for each platform specified in [`.buildpackrc`](https://github.com/particle-iot/device-os/blob/develop/.buildpackrc) `RELEASE_PLATFORMS` and `PRERELEASE_PLATFORMS` (deprecated)
  3. Push platform images to Docker Hub

#### Example `.travis.yml` file

If you're forking our [DeviceOS repository](https://github.com/particle-iot/device-os/) you can build your own images with firmware.
To do so, edit `.travis.yml` file to include:

```yaml
sudo: required  
services:  
  - docker
install:  
  - echo "$DOCKER_HUB_PASSWORD" | docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password-stdin
  - wget https://github.com/particle-iot/firmware-buildpack-builder/archive/%VERSION%.tar.gz -O - | tar -xz -C ../ --strip-components 1
script:  
  - ../scripts/ci
after_success: ../scripts/push-image
env:  
  - DOCKER_IMAGE_NAME=username/my-image
```

**Note:** remember to change `DOCKER_IMAGE_NAME` to your image name.

After this add `DOCKER_HUB_EMAIL`, `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD` environment variables to Travis CI setting.

Having done all this, Travis should build image every time a change is pushed. It will also push the images to Docker Hub when a git tag is set if git origin is not `particle-iot/device-os`.
