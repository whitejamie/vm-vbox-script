#!/bin/bash
# Script to automatically install a virtual machine and operating system based
# on the config.json.
#
# Optional arguments:
#    1. vm-create.sh INSTALL_DIR
#
# INSTALL_DIR: Directory where to save the virtual machine and virtual disk.
#              Default is <dir of this script>/vm.
#
source $dir/lib/get_config.sh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -z "$1" ] then
    install_dir=$1
    if [[ ! -d $install_dir ]]; then
        mkdir -p $install_dir 
    fi
else
    install_dir=$dir
fi

vm_name=$(get_config "vm_name")
iso_web=$(get_config "iso_web")

download_dir=$dir"/downloads"
vm_dir=$install_dir"/vm"
iso_file=${iso_web##http*\/}
iso_download_file=$download_dir/$iso_file

################################################################################

err_report() {
    echo "Error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

mkdir -p $download_dir

wget -nc -P $download_dir $iso_web

echo ".iso checksum verification..."
echo "$(get_config "iso_file_hash") $iso_download_file" | sha256sum --check --status
if [ $? != 0 ]; then
  echo '.iso download checksum failed.'
  exit 1
fi

echo "Creating VM..."
VBoxManage createvm --name $vm_name --ostype $(get_config "ostype") --register \
    --basefolder $vm_dir

echo "Set number of CPUs and memory..."
VBoxManage modifyvm $vm_name --cpus $(get_config "vm_cpus")
VBoxManage modifyvm $vm_name --ioapic on
VBoxManage modifyvm $vm_name --memory $(get_config "vm_memory_mb") --vram $(get_config "vm_vram_mb") 

echo "Set network..."
VBoxManage modifyvm $vm_name --nic1 nat

echo "Disable USB..."
VBoxManage modifyvm $vm_name --usb off
VBoxManage modifyvm $vm_name --usbehci off
VBoxManage modifyvm $vm_name --usbxhci off

echo "Disable audio..."
VBoxManage modifyvm $vm_name --audio none

echo "Create Disk and connect .iso..."
vdi_file=$vm_dir/$vm_name/$vm_name_DISK.vdi
VBoxManage createmedium disk --filename $vdi_file --size $(get_config "vm_disk_size_mb") --format VDI
VBoxManage storagectl $vm_name --name "SATA Controller" --add sata \
    --controller IntelAhci
VBoxManage storageattach $vm_name --storagectl "SATA Controller" --port 0 \
    --device 0 --type hdd --medium  $vdi_file
VBoxManage storagectl $vm_name --name "IDE Controller" --add ide \
    --controller PIIX4
VBoxManage storageattach $vm_name --storagectl "IDE Controller" --port 1 \
    --device 0 --type dvddrive --medium $iso_download_file
VBoxManage modifyvm $vm_name --boot1 dvd --boot2 disk --boot3 none --boot4 none

echo "Unattended install..."
alt_vbox_templates_dir="/usr/lib/virtualbox/UnattendedTemplates"
if [[ -d $alt_vbox_templates_dir ]]; then
templates_workaround_options="--script-template $alt_vbox_templates_dir/redhat67_ks.cfg \
--post-install-template $alt_vbox_templates_dir/redhat_postinstall.sh"
else
templates_workaround_options=""
fi

VBoxManage unattended install $vm_name \
    --user=$(get_config "vm_user_name") \
    --password=$(get_config "vm_user_password") \
    --country=$(get_config "vm_country") \
    --locale=$(get_config "vm_locale") \
    --time-zone=$(get_config "vm_time_zone") \
    --hostname=$(get_config "vm_hostname") \
    --iso=$iso_download_file \
    $templates_workaround_options \
    --start-vm=gui

echo "After the automatic installation has finished run ./vm-post-install.sh."
exit 0
################################################################################