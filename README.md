# vm-vbox-script
Scripts for automatically generating Virtual Machines using Virtual Box.

# Dependencies
* [VirtualBox](https://www.virtualbox.org/)
## Linux host
* Bash command line utilities: wget, jq, 

## Windows host
* PowerShell scripts depends on a 3rd party library to create an .iso file, [New-ISOFile](https://github.com/whitejamie/library/tree/master/3rdparty/PowerShell/New-ISOFile). This has been copied to the ```/library``` folder.

# Instructions
## Linux host
## Windows host

# TODO
* Move common parameters between Linux and Windows scripts into one file.
* Linux, .iso of post_install_scripts:
```
mkisofs -iso-level 3 -o ./scripts.iso ./post_install_scripts/
```
* Windows, .iso of post_install_scripts:
```
$source_dir = Join-Path -Path $pwd -ChildPath "scripts"
$target_iso = Join-Path -Path $pwd -ChildPath "scripts.iso"
$Get-ChildItem "$source_dir" | New-IsoFile -Path $target_iso
```

# Additional information
* There's a bug in Virtual Box's VBoxManage unattended install. It looks in the wrong location for virtualbox/UnattendedTemplates. On Debian/RedHat host machines it is located here: /usr/lib/virtualbox/UnattendedTemplates/. See https://www.virtualbox.org/ticket/17335.
The Linux script works around this issue by testing the location of Virtual Box's ```/UnattendedTemplates``` directory.
* For vm_locale configuration see locale and country https://www.gnu.org/software/gettext/manual/html_node/Locale-Names.html
* .iso checksums:
  * [CentOS-7-x86_64-Minimal-2003.iso](https://wiki.centos.org/action/show/Manuals/ReleaseNotes/CentOS7.2003?action=show&redirect=Manuals%2FReleaseNotes%2FCentOS7)