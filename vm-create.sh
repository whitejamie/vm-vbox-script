#!/bin/bash
################################################################################
# README
# TODO:
#    - Currently hard coded for a unattended install of RedHat based distro 
#      guest OS using Ubuntu host. This is to get around bug in VirtualBox...
#
#          There's a bug in Virtual Box's VBoxManage unattended install. It 
#          looks in the wrong location for virtualbox/UnattendedTemplates. On 
#          Debian/RedHat host machines it is located here: 
#          /usr/lib/virtualbox/UnattendedTemplates/.
#          See https://www.virtualbox.org/ticket/17335
#
#    - Post installation script for further modifications?
#    - Use input argument for vm_name
#    - SSH server setup, etc.

################################################################################
#vm_name=$1
vm_name="auto_centos_vm_test1"
vm_hostname="vboxhost.localdomain"
vm_user_name="vboxuser"
vm_user_password="changeme"
vm_country="ES"
vm_time_zone="CEST"

# Checksum for iso image from:
#     https://wiki.centos.org/action/show/Manuals/ReleaseNotes/CentOS7.2003?action=show&redirect=Manuals%2FReleaseNotes%2FCentOS7
iso_web="http://centos.uvigo.es/7.8.2003/isos/x86_64/CentOS-7-x86_64-Minimal-2003.iso"
iso_file_hash="659691c28a0e672558b003d223f83938f254b39875ee7559d1a4a14c79173193"
ostype="RedHat_64"

################################################################################

install_dir=`pwd`
download_dir=$install_dir"/downloads"
vm_dir=$install_dir"/vm"
iso_file=${iso_web##http*\/}
iso_download_file=$download_dir/$iso_file

err_report() {
    echo "Error on line $1"
    exit 1
}
trap 'err_report $LINENO' ERR

mkdir -p $download_dir

wget -nc -P $download_dir $iso_web

echo ".iso checksum verification..."
echo "$iso_file_hash $iso_download_file" | sha256sum --check --status
if [ $? != 0 ]; then
  echo '.iso download checksum failed.'
  exit 1
fi

echo "Creating VM..."
VBoxManage createvm --name $vm_name --ostype $ostype --register \
    --basefolder $vm_dir

echo "Set number of CPUs and memory..."
VBoxManage modifyvm $vm_name --cpus 1
VBoxManage modifyvm $vm_name --ioapic on
VBoxManage modifyvm $vm_name --memory 2048 --vram 16 

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
VBoxManage createmedium disk --filename $vdi_file --size 20000 --format VDI
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
VBoxManage unattended install $vm_name --user=$vm_user_name \
    --password=$vm_user_password --country=$vm_country \
    --time-zone=$vm_time_zone --hostname=$vm_hostname --iso=$iso_download_file \
    --script-template /usr/lib/virtualbox/UnattendedTemplates/redhat67_ks.cfg \
    --post-install-template /usr/lib/virtualbox/UnattendedTemplates/redhat_postinstall.sh \
    --start-vm=gui

echo "Finished script."
exit 0
################################################################################