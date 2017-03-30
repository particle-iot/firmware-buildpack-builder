FROM particle/buildpack-raspberrypi:0.0.3

ARG FIRMWARE_PATH
WORKDIR /
COPY bin /bin
COPY ${FIRMWARE_PATH} /firmware
