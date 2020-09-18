# New-ISOFile
## Source
Copy of https://github.com/whitejamie/library/tree/master/3rdparty/PowerShell/New-ISOFile.

## New-ISOFile
Powershell script to create an .iso file of a directory. From Microsoft TechNet Gallery by Chris Wu, https://gallery.technet.microsoft.com/scriptcenter/New-ISOFile-function-a8deeffd#content

Message on website 2020-09-17 "We are retiring the TechNet Gallery. Make sure to back up your code.". 

## Description from original source
2016-03-25 "This PowerShell function uses IMAPI COM objects to create .iso files.
Without using any external utilities/files, this function can wrap files and folders into an .iso file. Bootable images can also be created with the support of etfsboot.com, which can be commonly found in Windows AIK. The function can add multiple files/folders into the .iso image in a single session, and can accept pipeline input.
Some of the source code referenced http://tools.start-automating.com/Install-ExportISOCommand/, but the functionality is wrapped in such a way that it supports better pipeline processing."

## Example use:
1. Register this function, run:
```
. .\Create-ISO.ps1
```
1. Create an ISO of scripts directory under current directory, run:
```
$source_dir = Join-Path -Path $pwd -ChildPath "scripts"
$target_iso = Join-Path -Path $pwd -ChildPath "scripts.iso"
$Get-ChildItem "$source_dir" | New-IsoFile -Path $target_iso
```