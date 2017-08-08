<#
PowerNSX Publishing Script
Nick Bradford
nbradford@vmware.com
07/2017

Because of the variety of ways of distributing and supporting both Core and
Desktop PowerShell as well as supportong both script based and PowerShell
gallery based installation with the same module, we need to have flexibility
in the way the manifest is built for various platforms.  This is pretty much
to do just with properly expressing the PowerCLI dependancies that PowerNSX has.

On top of that, the process of publishing updates to PowerShell Gallery and
PowerNSX versioning is now handled by it.

The intent is to have this script called by CI/CD when updates are PRs are
merged to PowerNSX.

See PowerNSX.psd1.README.md for instructions on this process and the
requirements for maintaining manifests now.

Maintainers are the only ones that should edit this script.

Copyright © 2015 VMware, Inc. All Rights Reserved.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTIBILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License version 2 for more details.

You should have received a copy of the General Public License version 2 along with this program.
If not, see https://www.gnu.org/licenses/gpl-2.0.html.

Some files may be comprised of various open source software components, each of which
has its own license that is located in the source code of the respective component.
#>

# Requires -Version 3.0


param (
    [Parameter (Mandatory=$true)]
    #Required build number that is appended to the version (maj.min) string from include.ps1 to form the full version number.
    $BuildNumber,
    [Parameter (Mandatory=$true)]
    #Required API key to upload to PowershellGallery.
    $NugetAPIKey
)
##########################
##########################
# This script :
#   do sources include.ps1 and adds a build number to the version string from there.
#   Generates the platform specific manifests in the appropriate directories.
#   Copies the updated Manifests and module to the dist/ folder
#   Publishes the updated module to the PowerShell gallery
##########################

# Dot Source Include.ps1.  This file includes developer configurable variables
# such as FunctionsToExport and Version
. ./Include.ps1

#Append the build number on the version string
$ModuleVersion = $ModuleVersion + '.' + $BuildNumber

if ( -not ($ModuleVersion -as [version])) { throw "$ModuleVersion is not a valid version.  Check version and build number and try again."}

# The path the Installation script uses on Desktop
$DesktopPath = "./platform/desktop"
# The path the Installation script uses on Core
$CorePath = "./platform/core"
# The path this script uses for the Gallery distro upload
$GalleryPath = "./platform/gallery"

# Manifest Description
$Description = @"
PowerNSX is a PowerShell module that abstracts the VMware NSX API to a set of easily used PowerShell functions.
This module is not supported by VMware, and comes with no warranties express or implied. Please test and validate its functionality before using in a production environment.
It aims to focus on exposing New, Update, Remove and Get operations for all key NSX functions as well as adding additional functionality to extend the capabilities of NSX management beyond the native UI or API.
It is unlikely that it will ever expose 100% of the NSX API, but feature requests are welcomed if you find a particular function you require to be lacking.
PowerNSX is currently a work in progress and is not yet feature complete.
"@

# Required Modules for respective platforms.  These deps are defined in the resulting platform specific Manifest file.
$CoreRequiredModules = @("PowerCLI.Vds","PowerCLI.ViCore")
$DesktopRequiredModules = @("VMware.VimAutomation.Core","VMware.VimAutomation.Vds")
$GalleryRequiredModules = @("VMware.VimAutomation.Core","VMware.VimAutomation.Vds")

#Manifest settings that are common to all platforms.
$Common = @{
    RootModule = 'PowerNSX.psm1'
    GUID = 'ea3b0bdc-83a3-4cae-9920-7257beae8614'
    Author = 'Nick Bradford'
    CompanyName = 'VMware'
    Copyright = 'Copyright © 2015 VMware, Inc. All Rights Reserved.'
    Description = $Description
    PowerShellVersion = '3.0'
    DotNetFrameworkVersion = '4.0'
    FunctionsToExport = $FunctionsToExport
    ModuleVersion = $ModuleVersion
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    ProjectUri = 'https://powernsx.github.io/'

}

copy-item -Path "./PowerNSX.psm1" "$DesktopPath/PowerNSX/"
copy-item -Path "./PowerNSX.psm1" "$CorePath/PowerNSX/"
copy-item -Path "./PowerNSX.psm1" "$GalleryPath/PowerNSX/"

New-ModuleManifest -Path "$DesktopPath/PowerNSX/PowerNSX.psd1" -RequiredModules $DesktopRequiredModules @Common
New-ModuleManifest -Path "$CorePath/PowerNSX/PowerNSX.psd1" -RequiredModules $CoreRequiredModules @Common
New-ModuleManifest -Path "$GalleryPath/PowerNSX/PowerNSX.psd1" -RequiredModules $GalleryRequiredModules -CompatiblePSEditions Desktop @Common

# Publish-Module -NuGetApiKey $NugetAPIKey -Path "$GalleryPath/PowerNSX"

write-host -ForegroundColor Yellow "Version $ModuleVersion is now published to the Powershell Gallery.  You MUST now push these updates back to the git repository."