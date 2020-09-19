#!/bin/bash
# Makes an .iso from the post_install_scripts directory and adds it to the VM
# drive so it's available to be mounted and its scripts executed.

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $dir/lib/get_config.sh

temp_dir=$dir/temp
iso_file=$temp_dir/scripts.iso

rm -fr $temp_dir
mkdir -p $temp_dir

mkisofs -iso-level 3 -o $iso_file $dir/post_install_scripts


# First unattach any existing storage
VBoxManage storageattach $(get_config "vm_name") \
    --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive \
    --medium "emptydrive" \
    --forceunmount

VBoxManage storageattach $(get_config "vm_name") \
    --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive \
    --medium $iso_file


echo "Now log into VM and mount the CDROM device to run the post installation scripts in the .iso..."
echo "mkdir -p /root/post_install_scripts"
echo "mount /dev/cdrom /root/post_install_scripts"
echo "sh /root/post_install_scripts/hello_world.sh"