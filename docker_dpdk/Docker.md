## How to Build DPDK Docker

### Install Docker

```bash
# Ubuntu 22.04 LTS
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo service docker start
sudo docker run hello-world
```

### Project Directory

1. Create a new project directory on Host
2. Copy project content inside folder
    1. dpdk.sh
    2. dpdk-22.11.4.tar.xz
    3. dpdk-kmods.tar.xz
3. Create a new Dockerfile

### Dockerfile

Notes:

1. During development, create as many LAYERS as possible, since each layer is CACHED
2. Finally, create as minimum LAYERS as possible, so we get max performance while running

```bash
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
```

### Build Docker Container

```bash
sudo docker build -t dpdk .
sudo docker image ls
```

### Reserve HugePages on Host

```bash
mkdir /mnt/huge
sudo mount -t hugetlbfs pagesize=1GB /mnt/huge
sudo -s
echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
```

### Run DPDK Docker Container

```bash
sudo -s
# docker run dpdk
docker run -it --privileged --cap-add=ALL -v /mnt/huge:/mnt/huge -v /sys/bus/pci/devices:/sys/bus/pci/devices -v
/sys/devices/system/node:/sys/devices/system/node -v /lib/modules:/lib/modules -v /dev:/dev dpdk
```

### Check Docker Container Status

```bash
sudo docker ps
```

### Stop Docker Container

```bash
sudo docker ps
docker image stop 0a8e000e6ba0
```

### Delete Docker Container

```bash
sudo docker image ls
docker image rm 0a8e000e6ba0 -f
```

### Remove all Docker images

```bash
sudo -s
docker rmi $(docker images -q) -f
```
