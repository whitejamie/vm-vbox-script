#!/bin/bash
# Script to enable and connect the ethernet.

ethernet_dev_name=$(nmcli -f TYPE,DEVICE device | grep ^ethernet | awk '{print $2}')
nmcli con add type ethernet con-name my-network ifname $ethernet_device_name
nmcli con up my-network
