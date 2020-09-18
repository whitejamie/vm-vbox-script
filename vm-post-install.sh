#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $dir/lib/get_config.sh

temp_dir=$dir/temp
iso_file=$temp_dir/scripts.iso

rm -fr $temp_dir
mkdir -p $temp_dir

mkisofs -iso-level 3 -o $iso_file $dir/post_install_scripts


VBoxManage storageattach $(get_config "vm_name") \
    --storagectl "IDE Controller" \
    --port 1 --device 0 --type dvddrive \
    --medium $iso_file

# Unattach...
# VBoxManage storageattach $(get_config "vm_name") --storagectl IDE --port 1 --device 0 --medium "none"



#VBoxManage storageattach $(get_config "vm_name") --storagectl "IDE Controller" --port 1 \
#    --device 0 --type dvddrive --medium $iso_file

echo "Now log into VM and mount the CDROM device to run the post installation scripts in the .iso..."
echo "mkdir -p /root/post_install_scripts"
echo "mount /dev/cdrom /root/post_install_scripts"