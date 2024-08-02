# Requires -Version 5.1
# This module provides functions for managing software items on a local or remote using CIM computer.
# It uses the System.Management.Automation namespace for PowerShell integration,
# the Microsoft.Win32 namespace for registry access, and the System.Collections.Generic
# namespace for collection classes.
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace Microsoft.Win32

# The SoftwareItem class represents a software item installed on a computer.
# It has properties for the name, version, and install date of the software item.
# class SoftwareItem {
#   [string]$ComputerName
#   [string]$DisplayName
#   [string]$DisplayVersion
#   [string]$Publisher
#   [string]$InstallDate
#   [string]$InstallLocation
#   [string]$Architecture
#   [string]$UninstallString
#   [string]$QuietUninstallString
#   [string]$EstimatedSize
#   [int]$EstimatedSizeBytes
#   [bool]$NoRemove
#   [bool]$NoRepair
#   [bool]$NoModify
#   [string]$DisplayIcon
#   [string]$UrlInfoAbout
# }

# Load functions from other files
foreach ($file in (Get-ChildItem -Path $PSScriptRoot\public -Filter '*.ps1' -File -Exclude '*.Tests.ps1' -Recurse)) {
  Write-Verbose -Message ('Loading function from file: {0}' -f $file.FullName)
  . $file.FullName
}

# Export the functions
Export-ModuleMember -Function 'Get-SoftwareItem', 'Remove-SoftwareItem', 'Add-DefaultDisplaySet', 'Format-Bytes'
