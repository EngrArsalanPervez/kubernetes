#!/bin/sh
modprobe uio
insmod /home/dpdk-kmods/linux/igb_uio/igb_uio.ko
cd /home/dpdk-stable-22.11.4/
./usertools/dpdk-devbind.py --bind=igb_uio 0000:0b:00.0
./usertools/dpdk-devbind.py --bind=igb_uio 0000:0b:00.1
./usertools/dpdk-devbind.py --bind=igb_uio 0000:0b:00.2
./usertools/dpdk-devbind.py --bind=igb_uio 0000:0b:00.3
./usertools/dpdk-devbind.py --status
cd examples/multi_process/client_server_mp/mp_server
make
./build/mp_server -c f -n 4 -- -p 0xf -n 2