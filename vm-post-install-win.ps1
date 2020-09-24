# Makes an .iso from the post_install_scripts directory and adds it to the VM
# drive so it's available to be mounted and its scripts executed.
#
# Calling options:
#    1. vm-post-install-win.ps1 [OPTIONS...]
#
#  OPTIONS
#      -config 
#          Path to .json configuration file.
#      -vm_name
#          Name given to virtual machine, used as argument to VBoxManage and is 
#          displayed in the VirtualBox Manager GUI.
#          Default name is in config.json.
#
################################################################################
param ($config_json = [IO.Path]::Combine($pwd, 'config.json'), 
       $vm_name)

################################################################################
$ErrorActionPreference = "Stop"

################################################################################
# Register required functions and tools
$create_iso_path = [IO.Path]::Combine($pwd, 'lib', '3rdparty', 'PowerShell', 'New-ISOFile', 'Create-ISO.ps1')
. $create_iso_path
$env:Path += ";C:\Program Files\Oracle\VirtualBox"

################################################################################
echo "#########################################################################"
echo "#    Installation details - vm-post-install-win                         #"
echo "#########################################################################"

$config = Get-Content -Raw -Path $config_json | ConvertFrom-Json   

if ([string]::IsNullOrWhiteSpace($vm_name)){
    $vm_name = $config.vm_name
}
else{
    $config.vm_name = $vm_name
}

echo "config_json : $config_json"
echo "vm_name     : $($config.vm_name)"

echo "#########################################################################"

echo "First unattach any existing storage"
VBoxManage storageattach $config.vm_name `
    --storagectl "IDE Controller" `
    --port 1 --device 0 --type dvddrive `
    --medium "emptydrive" `
    --forceunmount

$temp_dir = [IO.Path]::Combine($pwd, 'temp')
$iso_file = [IO.Path]::Combine($temp_dir, 'scripts.iso')

If((test-path $temp_dir))
{
    Remove-Item -LiteralPath $temp_dir -Force -Recurse
}
New-Item -ItemType Directory -Force -Path $temp_dir

$post_install_scripts_dir = [IO.Path]::Combine($pwd, 'post_install_scripts')
Get-ChildItem $post_install_scripts_dir | New-IsoFile -Path $iso_file

echo "Insert .iso into dvddrive"
VBoxManage storageattach $config.vm_name `
    --storagectl "IDE Controller" `
    --port 1 --device 0 --type dvddrive `
    --medium $iso_file

echo ""
echo "Now log into VM as root and mount the CDROM device to run the post installation scripts in the .iso..."
echo "mkdir -p /root/post_install_scripts"
echo "mount /dev/cdrom /root/post_install_scripts"
echo "sh /root/post_install_scripts/hello_world.sh"
echo "sh /root/post_install_scripts/setup_ethernet.sh"