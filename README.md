# vm-vbox-script
Scripts for automatically generating Virtual Machines using Virtual Box.

# Dependencies

## Linux host

## Windows host
PowerShell scripts depends on a 3rd party library to create an .iso file, [New-ISOFile](https://github.com/whitejamie/library/tree/master/3rdparty/PowerShell/New-ISOFile). This has been copied to the ```/library``` folder.

# Instructions
## Linux host
## Windows host

# TODO
* Move common parameters between Linux and Windows scripts into one file.


# Additional information
* There's a bug in Virtual Box's VBoxManage unattended install. It looks in the wrong location for virtualbox/UnattendedTemplates. On Debian/RedHat host machines it is located here: /usr/lib/virtualbox/UnattendedTemplates/. See https://www.virtualbox.org/ticket/17335.
The Linux script works around this issue by testing the location of Virtual Box's ```/UnattendedTemplates``` directory.