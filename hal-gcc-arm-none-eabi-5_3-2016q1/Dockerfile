FROM particle/buildpack-hal:0.0.14-gcc-arm-none-eabi-5_3-2016q1

ARG FIRMWARE_PATH
WORKDIR /
COPY ${FIRMWARE_PATH} /firmware

# Must also tag as particle/buildpack-particle-firmware:dd9d5512a343d646176ebfb8c90fc6d672264583-photon-source
