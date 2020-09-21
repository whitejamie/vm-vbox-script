#!/bin/bash
# Makes an .iso from the post_install_scripts directory and adds it to the VM
# drive so it's available to be mounted and its scripts executed.
#
# Calling options:
#    1. vm-post-install.sh CONFIG_JSON
#    2. vm-post-install.sh CONFIG_JSON VM_NAME
#
# CONFIG_JSON : Path to .json configuration file.
#
# VM_NAME     : Name given to virtual machine, used as argument to VBoxManage 
#               and is displayed in the VirtualBox Manager GUI.
#               Default is name in config.json. 

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $dir/lib/get-config.sh

echo "#########################################################################"
echo "#    Installation details - vm-post-install                             #"
echo "#########################################################################"
config_json=$1
echo {,:\ $}config_json

if [ ! -z "$2" ]; then
    vm_name=$2
else
    vm_name=$(get-config $config_json "vm_name")
fi
echo {,:\ $}vm_name

echo "#########################################################################"

echo "First unattach any existing storage"
VBoxManage storageattach $vm_name \
    --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive \
    --medium "emptydrive" \
    --forceunmount

temp_dir=$dir/temp
iso_file=$temp_dir/scripts.iso

rm -fr $temp_dir
mkdir -p $temp_dir

mkisofs -iso-level 3 -o $iso_file $dir/post_install_scripts

echo "Insert .iso into dvddrive"
VBoxManage storageattach $vm_name \
    --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive \
    --medium $iso_file

echo
echo "Now log into VM as root and mount the CDROM device to run the post installation scripts in the .iso..."
echo "mkdir -p /root/post_install_scripts"
echo "mount /dev/cdrom /root/post_install_scripts"
echo "sh /root/post_install_scripts/hello_world.sh"
echo "sh /root/post_install_scripts/setup_ethernet.sh"