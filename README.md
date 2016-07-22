# Particle Firmware buildpack scripts

[![](https://imagelayers.io/badge/particle/buildpack-particle-firmware:latest.svg)](https://imagelayers.io/?images=particle/buildpack-particle-firmware:latest 'Get your own badge on imagelayers.io')

This repo is used by [`firmware` Travis CI build](https://travis-ci.org/spark/firmware) to build, test and push images to Docker Hub.

| |
|---|
|  **Particle firmware (you are here)**  |
| [HAL](https://github.com/spark/buildpack-hal) / [Legacy](https://github.com/spark/buildpack-0.3.x)   |
| [Base](https://github.com/spark/buildpack-base) |

## Flow

When doing a Travis CI job following scripts should be executed in order:

1. `scripts/build-image` which will:
  1. Build `$DOCKER_IMAGE_NAME` image
  2. Build `$DOCKER_IMAGE_NAME-test` image which includes test tools
* `scripts/run-tests-in-container` which will:
  1. Run [`/bin/run-tests`](bin/run-tests) inside of `$DOCKER_IMAGE_NAME-test` container

* if previous script was a success then `scripts/push-image`

#### Example `.travis.yml` file

If you're forking our [firmware repository](https://github.com/spark/firmware/) you can build your own images with firmware.
To do so, edit `.travis.yml` file to include:

```yaml
sudo: required  
services:  
  - docker
install:  
  - docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
  - wget https://github.com/spark/firmware-buildpack-builder/archive/master.tar.gz -O - | tar -xz -C ../ --strip-components 1
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
