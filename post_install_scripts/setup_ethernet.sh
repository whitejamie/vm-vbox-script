#!/bin/bash
# Script to enable and connect the ethernet.

sudo ethernet_dev_name=$(nmcli -f TYPE,DEVICE device | grep ^ethernet | awk '{print $2}')
sudo nmcli con add type ethernet con-name my-network ifname $ethernet_device_name
sudo nmcli con up my-network
