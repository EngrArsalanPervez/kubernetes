FROM ubuntu:20.04

LABEL maintainer="eup@gmail.com" \
    version="0.1" \
    description="Hello EUP"

ARG DEBIAN_FRONTEND=noninteractive

COPY dpdk-22.11.4.tar.xz dpdk-kmods.tar.xz dpdk.sh /home/

RUN apt update -y \
    && apt install -y linux-headers-$(uname -r) pciutils kmod build-essential wget git python3 python3-dev python3-pip python3-venv pkg-config meson ninja-build libnuma-dev libpcap-dev iproute2 \
    && pip3 install pyelftools \
    && rm -rf /var/lib/apt/lists/* \
    && apt clean \
    && cd /home/ \
    && tar xJf dpdk-22.11.4.tar.xz \
    && cd dpdk-stable-22.11.4 \
    && meson build \
    && cd build \
    && ninja \
    && ninja install \
    && ldconfig \
    && cd ../../ \
    && tar xJf dpdk-kmods.tar.xz  \
    && cd dpdk-kmods/linux/igb_uio/ \
    && make \
    && chmod +x /home/dpdk.sh

CMD ["/home/dpdk.sh"]