# vm-vbox-script
Scripts for creating a Virtual Machine (VM) using Virtual Box. Including access to the ./post_install_scripts from within the VM after installation.

# Dependencies
* [VirtualBox](https://www.virtualbox.org/)
## Linux host
* Bash command line utilities: wget, jq, mkisofs. 

## Windows host
* PowerShell scripts depends on a 3rd party library to create an .iso file, [New-ISOFile](https://github.com/whitejamie/library/tree/master/3rdparty/PowerShell/New-ISOFile). This has been copied to the ```/library``` folder.

# Instructions
Both Linux and Windows scripts use a .json config file and some of these parameters can be set via the command line calls to create the VMs. See each script's documentation for details and default ```./config.json```.
## Linux host
1. Run ```./vm-create.sh```.
1. After automatic install of OS finishes run ```./vm-post-install.sh```. Follow the onscreen instructions to mount the .iso in the VM to run the scripts.
## Windows host
1. Run PowerShell as admin and then call ```Set-ExecutionPolicy RemoteSigned```.
1. Run  ```.\vm-create-win.ps1```.
1. After automatic install of OS finishes run ```.\vm-post-install-win.ps1```. Follow the onscreen instructions to mount the .iso in the VM to run the scripts.
# Additional information
* There's a bug in Virtual Box's VBoxManage unattended install. It looks in the wrong location for virtualbox/UnattendedTemplates. On Debian/RedHat host machines it is located here: /usr/lib/virtualbox/UnattendedTemplates/. See https://www.virtualbox.org/ticket/17335.
The Linux script works around this issue by testing the location of Virtual Box's ```/UnattendedTemplates``` directory.
* For vm_locale configuration see locale and country https://www.gnu.org/software/gettext/manual/html_node/Locale-Names.html
* CentOS-7-x86_64-Minimal-2003
  * .iso [checksum](https://wiki.centos.org/action/show/Manuals/ReleaseNotes/CentOS7.2003?action=show&redirect=Manuals%2FReleaseNotes%2FCentOS7) source.
  * Use ```./post_install_scripts/setup_ethernet.sh``` to enable network connection.
  * Upgrade: ```sudo yum upgrade -y```
  * Add user as sudoer: ```gpasswd -a vboxuser wheel```
  * Change default passwords: ```sudo passwd root``` and ```sudo passwd vboxuser```
  * Get SHA256 ECDSA key fingerprint for verification when creating a secure shell SSH: ```ssh-keygen -l -f /etc/ssh/ssh_host_ecdsa.pub```