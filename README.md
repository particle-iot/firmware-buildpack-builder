# Particle Firmware buildpack scripts

This repo is used by [`firmware` Travis CI build](https://travis-ci.org/spark/firmware) to build, test and push images to Docker Hub.

| |
|---|
|  **Particle firmware (you are here)**  |
| [HAL](https://github.com/spark/buildpack-hal) / [Legacy](https://github.com/spark/buildpack-0.3.x)   |
| [Wiring preprocessor](https://github.com/spark/buildpack-arduino-preprocessor) |
| [Base](https://github.com/spark/buildpack-base) |

## Flow

When doing a Travis CI job following scripts should be executed in order:

1. `bin/buid-image`
* `bin/run-tests`
* if previous script was a success then `bin/push-image`


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
  - ../bin/build-image
script:  
  - ../bin/run-tests
after_success: ../bin/push-image
env:  
  - DOCKER_IMAGE_NAME=username/my-image
```

**Note:** remember to change `DOCKER_IMAGE_NAME` to your image name.

After this add `DOCKER_HUB_EMAIL`, `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD` environment variables to Travis CI setting.

Having done all this, Travis should build image every time a change is pushed. It will also tag Docker images when a git tag is set.
