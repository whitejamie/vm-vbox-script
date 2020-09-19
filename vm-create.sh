#!/bin/bash
# Script to automatically install a virtual machine and operating system based
# on the config.json.
#
# Calling options:
#    1. vm-create.sh CONFIG_JSON
#    2. vm-create.sh CONFIG_JSON VM_NAME
#    3. vm-create.sh CONFIG_JSON VM_NAME INSTALL_DIR
#
# CONFIG_JSON : Path to .json configuration file.
#
# VM_NAME     : Name given to virtual machine, used as argument to VBoxManage 
#               and is displayed in the VirtualBox Manager GUI.
#               Default is name in config.json. 
#
# INSTALL_DIR : Directory where to save the virtual machine and virtual disk.
#               Default is <dir of this script>/vm.
#
################################################################################
err_report() {
    echo "Error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

################################################################################

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source $dir/lib/get_config.sh

echo "#########################################################################"
echo "#    Installation details - vm-create                                   #"
echo "#########################################################################"
config_json=$1
echo {,:\ $}config_json

if [ ! -z "$2" ]; then
    vm_name=$2
else
    vm_name=$(get_config $config_json "vm_name")
fi
echo {,:\ $}vm_name

if [[ ! -z "$3" ]]; then
    install_dir=$3
else
    install_dir=$dir"/vm"
fi
echo {,:\ $}install_dir

vm_cpus=$(get_config $config_json "vm_cpus" -v)
vm_memory_mb=$(get_config $config_json "vm_memory_mb" -v)
vm_vram_mb=$(get_config $config_json "vm_vram_mb" -v)
vm_disk_size_mb=$(get_config $config_json "vm_disk_size_mb" -v)
vm_user_name=$(get_config $config_json "vm_user_name" -v)
vm_user_password=$(get_config $config_json "vm_user_password" -v)
vm_country=$(get_config $config_json "vm_country" -v)
vm_locale=$(get_config $config_json "vm_locale" -v)
vm_time_zone=$(get_config $config_json "vm_time_zone" -v)
vm_hostname=$(get_config $config_json "vm_hostname" -v)
iso_web=$(get_config $config_json "iso_web" -v)
iso_file_hash=$(get_config $config_json "iso_file_hash" -v)
ostype=$(get_config $config_json "ostype" -v)

################################################################################

download_dir=$dir"/downloads"
iso_file=${iso_web##http*\/}
iso_download_file=$download_dir/$iso_file

################################################################################
echo "#########################################################################"
echo
read -e -p "Type 'c' to continue with creating the VM: " choice
if [[ ! "$choice" == [Cc]* ]]; then
    echo "Stopping script."
    exit 1
fi

################################################################################

echo "Making directories..."
mkdir -p $install_dir 
mkdir -p $download_dir

echo "Getting .iso..."
wget -nc -P $download_dir $iso_web

echo ".iso checksum verification..."
echo "$iso_file_hash $iso_download_file" | sha256sum --check --status
if [ $? != 0 ]; then
  echo '.iso download checksum failed.'
  exit 2
fi

echo "Creating VM..."
VBoxManage createvm --name $vm_name --ostype $ostype --register \
    --basefolder $install_dir

echo "Set number of CPUs and memory..."
VBoxManage modifyvm $vm_name --cpus $vm_cpus
VBoxManage modifyvm $vm_name --ioapic on
VBoxManage modifyvm $vm_name --memory $vm_memory_mb --vram $vm_vram_mb 

echo "Set network..."
VBoxManage modifyvm $vm_name --nic1 nat

echo "Disable USB..."
VBoxManage modifyvm $vm_name --usb off
VBoxManage modifyvm $vm_name --usbehci off
VBoxManage modifyvm $vm_name --usbxhci off

echo "Disable audio..."
VBoxManage modifyvm $vm_name --audio none

echo "Create Disk and connect .iso..."
vdi_file=$install_dir/$vm_name/$vm_name_DISK.vdi
VBoxManage createmedium disk --filename $vdi_file --size $vm_disk_size_mb --format VDI
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
    --user=$vm_user_name \
    --password=$vm_user_password \
    --country=$vm_country \
    --locale=$vm_locale \
    --time-zone=$vm_time_zone \
    --hostname=$vm_hostname \
    --iso=$iso_download_file \
    $templates_workaround_options \
    --start-vm=gui

echo "After the automatic installation has finished run:"
echo "./vm-post-install.sh $config_json $vm_name"

exit 0
################################################################################