# Run powershell as admin and then call Set-ExecutionPolicy RemoteSigned
$ErrorActionPreference = "Stop"

$vm_name = "auto_centos_vm_test1"
$vm_hostname = "vboxhost.localdomain"
$vm_user_name = "vboxuser"
$vm_user_password = "changeme"
# For locale and country codes see:
#  https://www.gnu.org/software/gettext/manual/html_node/Locale-Names.html
$vm_country = "ES"
$vm_locale = "en_GB"
$vm_time_zone = "CEST"



# Checksum for iso image from:
#     https://wiki.centos.org/action/show/Manuals/ReleaseNotes/CentOS7.2003?action=show&redirect=Manuals%2FReleaseNotes%2FCentOS7
$iso_web = "http://centos.uvigo.es/7.8.2003/isos/x86_64/CentOS-7-x86_64-Minimal-2003.iso"
$iso_file_hash = "659691c28a0e672558b003d223f83938f254b39875ee7559d1a4a14c79173193"
$ostype = "RedHat_64"

################################################################################

$install_dir = pwd
$download_dir = "$install_dir\downloads"
$vm_dir = "$install_dir\vm"
$iso_file = Split-Path -Path $iso_web -Leaf
$iso_download_file = "$download_dir\$iso_file"

echo "Downloading .iso..."
If(!(test-path $download_dir))
{
    New-Item -ItemType Directory -Force -Path $download_dir
}

If(!(test-path $iso_download_file))
{
    wget $iso_web -OutFile $iso_download_file
}

echo ".iso checksum verification..."
$FileHash = Get-FileHash $iso_download_file -Algorithm SHA256
if($FileHash.Hash.ToString() -ne $iso_file_hash)
{
    write-host ".iso download checksum failed."
    exit 1
}

echo "Creating VM..."
$env:Path += ";C:\Program Files\Oracle\VirtualBox"

VBoxManage createvm --name $vm_name --ostype $ostype --register `
    --basefolder $vm_dir

# This LastExitCode check is not necessary since we've already set ErrorActionPreference
if($LastExitCode -ne 0)
{
    write-host "createvm failed."
    exit 1
}

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
$vdi_file="$vm_dir\$vm_name\$vm_name_DISK.vdi"
VBoxManage createmedium disk --filename $vdi_file --size 20000 --format VDI
VBoxManage storagectl $vm_name --name "SATA Controller" --add sata `
    --controller IntelAhci
VBoxManage storageattach $vm_name --storagectl "SATA Controller" --port 0 `
    --device 0 --type hdd --medium  $vdi_file
VBoxManage storagectl $vm_name --name "IDE Controller" --add ide `
    --controller PIIX4
VBoxManage storageattach $vm_name --storagectl "IDE Controller" --port 1 `
    --device 0 --type dvddrive --medium $iso_download_file
VBoxManage modifyvm $vm_name --boot1 dvd --boot2 disk --boot3 none --boot4 none

echo "Unattended install..."
VBoxManage unattended install $vm_name --user=$vm_user_name `
    --password=$vm_user_password --country=$vm_country --locale=$vm_locale `
    --time-zone=$vm_time_zone --hostname=$vm_hostname --iso=$iso_download_file `
    --start-vm=gui

echo "Script finished. Virtual Box will continue to install the VM..."
exit 0