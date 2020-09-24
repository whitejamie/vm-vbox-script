# Script to automatically install a virtual machine and operating system based
# on the config.json.
#
# .\vm-create-win.ps1 [OPTIONS...]
#
#  OPTIONS
#      -config_json 
#          Path to .json configuration file.
#      -vm_name
#          Name given to virtual machine, used as argument to VBoxManage and is 
#          displayed in the VirtualBox Manager GUI.
#          Default name is in config.json.
#      -install_dir
#          Directory where to save the virtual machine and virtual disk.
#          Default is $pwd\vm.
#
################################################################################
param ($config_json = [IO.Path]::Combine($pwd, 'config.json'), 
       $vm_name,
       $install_dir)

$download_dir = [IO.Path]::Combine($pwd, 'downloads')
################################################################################
$ErrorActionPreference = "Stop"

################################################################################
echo "#########################################################################"
echo "#    Installation details - vm-create-win                               #"
echo "#########################################################################"

$config = Get-Content -Raw -Path $config_json | ConvertFrom-Json   

if ([string]::IsNullOrWhiteSpace($vm_name)){
    $vm_name = $config.vm_name
}
else{
    $config.vm_name = $vm_name
}

if ([string]::IsNullOrWhiteSpace($install_dir)){
    $install_dir = [IO.Path]::Combine($pwd, 'vm')
}
echo "config_json : $config_json"
echo "install_dir : $install_dir"
echo $config

################################################################################
$download_dir = [IO.Path]::Combine($pwd, 'downloads')
$iso_file = Split-Path -Path $config.iso_web -Leaf
$iso_download_file = [IO.Path]::Combine($download_dir, $iso_file)

################################################################################
echo "#########################################################################"
echo ""
Write-Warning "Continue with creating the VM?" -WarningAction Inquire

################################################################################
echo "Making directories..."
If(!(test-path $install_dir))
{
    New-Item -ItemType Directory -Force -Path $install_dir
}
If(!(test-path $download_dir))
{
    New-Item -ItemType Directory -Force -Path $download_dir
}

echo "Getting .iso..."
If(!(test-path $iso_download_file))
{
    wget $config.iso_web -OutFile $iso_download_file
}

echo ".iso checksum verification..."
$FileHash = Get-FileHash $iso_download_file -Algorithm SHA256
if($FileHash.Hash.ToString() -ne $config.iso_file_hash)
{
    write-host ".iso download checksum failed."
    exit 1
}

echo "Creating VM..."
$env:Path += ";C:\Program Files\Oracle\VirtualBox"

VBoxManage createvm --name $config.vm_name --ostype $config.ostype --register --basefolder $install_dir

# This LastExitCode check is not necessary since we've already set ErrorActionPreference
if($LastExitCode -ne 0)
{
    write-host "createvm failed."
    exit 1
}

echo "Set number of CPUs and memory..."
VBoxManage modifyvm $config.vm_name --cpus $config.vm_cpus
VBoxManage modifyvm $config.vm_name --ioapic on
VBoxManage modifyvm $config.vm_name --memory $config.vm_memory_mb --vram $config.vm_vram_mb 

echo "Set network..."
VBoxManage modifyvm $config.vm_name --nic1 nat

echo "Disable USB..."
VBoxManage modifyvm $config.vm_name --usb off
VBoxManage modifyvm $config.vm_name --usbehci off
VBoxManage modifyvm $config.vm_name --usbxhci off

echo "Disable audio..."
VBoxManage modifyvm $config.vm_name --audio none

echo "Create Disk and connect .iso..."
$vdi_file = [IO.Path]::Combine($install_dir, $($config.vm_name), "$($config.vm_name)_DISK.vdi")
VBoxManage createmedium disk --filename $vdi_file --size $config.vm_disk_size_mb --format VDI
VBoxManage storagectl $config.vm_name --name "SATA Controller" --add sata `
    --controller IntelAhci
VBoxManage storageattach $config.vm_name --storagectl "SATA Controller" --port 0 `
    --device 0 --type hdd --medium  $vdi_file
VBoxManage storagectl $config.vm_name --name "IDE Controller" --add ide `
    --controller PIIX4
VBoxManage storageattach $config.vm_name --storagectl "IDE Controller" --port 1 `
    --device 0 --type dvddrive --medium $iso_download_file
VBoxManage modifyvm $config.vm_name --boot1 dvd --boot2 disk --boot3 none --boot4 none

echo "Unattended install..."
VBoxManage unattended install $config.vm_name `
    --user=$($config.vm_user_name) `
    --password=$($config.vm_user_password) `
    --country=$($config.vm_country) `
    --locale=$($config.vm_locale) `
    --time-zone=$($config.vm_time_zone) `
    --hostname=$($config.vm_hostname) `
    --iso=$($iso_download_file) `
    --start-vm=gui

echo "After the automatic installation has finished run:"
echo ".\vm-post-install-win.ps1 $($config_json) $($config.vm_name)"

exit 0
################################################################################