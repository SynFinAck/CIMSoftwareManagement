function Get-SoftwareItem {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [Alias('ComputerName')]
    [string[]]$CN = $ENV:COMPUTERNAME,

    [Parameter(
      Mandatory = $false,
      ParameterSetName = 'Filter'
    )]
    [uint]$OperationTimeoutSec,

    [Parameter(
      Mandatory = $false,
      ParameterSetName = 'Filter')]
    [Alias('Filter')]
    [scriptblock]$FilterScript
  )

  begin {
    function Get-RegistryValue {
      param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [RegistryKey]$InputObject,
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName
      )

      if ($InputObject -and $PropertyName) {
        try {
          $value = ([RegistryKey]$InputObject).GetValue($PropertyName)
          if ($null -ne $value) {
            return $value
          }
          else {
            return [string]::Empty
          }
        }
        catch {
          Write-Error -ErrorRecord $_
        }
      }
    }
  }
  process {
    $softwareItems = [List[SoftwareItem]]::new()
    foreach ($computer in $CN) {
      # Declare the registry hives and keys to search for installed software
      $uninstallRegKeys = [ordered]@{
        'x86' = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        'x64' = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
      }

      # Get the software items from each registry hive and key
      foreach ($key in $uninstallRegKeys.GetEnumerator()) {
        try {
          $registryKey = [RegistryKey]::OpenRemoteBaseKey(
            [RegistryHive]::LocalMachine,
            $computer
          ).OpenSubKey($key.Value)

          foreach ($subKeyName in $registryKey.GetSubKeyNames()) {
            $softwareItem = [SoftwareItem]::new()
            $softwareItem.ComputerName = $computer
            $softwareItem.Architecture = $key.Name

            foreach ($property in $registryKey.OpenSubKey($subKeyName).GetValueNames()) {
              if ($softwareItem.PSObject.Properties.Name -contains $property) {
                try {
                  switch ($property) {
                    'InstallDate' {
                      $installDate = $registryKey.OpenSubKey($subKeyName).GetValue($property)
                      try {
                        if (-NOT [string]::IsNullOrEmpty($installDate)) {
                          $softwareItem.$property = [datetime]::ParseExact($installDate, 'yyyyMMdd', $null)
                        }
                        else {
                          $softwareItem.$property = $installDate
                        }
                      }
                      catch {
                        $softwareItem.$property = $installDate
                      }
                    }
                    { $_ -in 'NoRemove', 'NoRepair' } {
                      $value = $registryKey.OpenSubKey($subKeyName).GetValue($property)
                      if (-NOT [string]::IsNullOrEmpty($value) -and $value -eq 1) {
                        $softwareItem.$property = [bool]$value
                      }
                      else {
                        $softwareItem.$property = $false
                      }
                    }
                    'EstimatedSize' {
                      $estimatedSize = $registryKey.OpenSubKey($subKeyName).GetValue($property)
                      if (-NOT [string]::IsNullOrEmpty($estimatedSize)) {
                        $softwareItem.EstimatedSizeBytes = $estimatedSize
                        $softwareItem.EstimatedSize = Format-Bytes -bytes $estimatedSize
                      }
                      else {
                        $softwareItem.EstimatedSizeBytes = 0
                        $softwareItem.EstimatedSize = $estimatedSize
                      }
                    }
                    default {
                      $softwareItem.$property = $registryKey.OpenSubKey($subKeyName).GetValue($property)
                    }
                  }
                }
                catch {
                  Write-Error -Message ('An error occurred: {0}' -f $_)
                }
              }
            }
            # Update the SoftwareItem object and add a custom display set
            $softwareItem = $softwareItem | Add-DefaultDisplaySet -TypeName 'CimInstance#SoftwareItem' -DefaultProperty (
              'ComputerName', 'DisplayName', 'DisplayVersion', 'Publisher', 'InstallDate', 'Architecture') -Force -PassThru
            $softwareItems.Add($softwareItem)
          } # End of foreach ($subKeyName in $registryKey.GetSubKeyNames())
        } # End of try block
        catch {
          Write-Error -Message ('An error occurred: {0}' -f $_)
        } # End of catch block
      } # End of foreach ($key in $uninstallRegKeys.GetEnumerator())
    } # End of foreach ($computer in $CN)
  } # End of process block
  end {
    # Apply the filter, if any
    if ($FilterScript) {
      $softwareItems = $softwareItems | Where-Object $FilterScript
    }
    return $softwareItems
  }
  <#
.SYNOPSIS
  Retrieves software items from a computer.

.DESCRIPTION
  The Get-SoftwareItem function retrieves software items from a computer. The function returns a list of SoftwareItem objects, each representing a software item installed on the computer.

.PARAMETER CN
  The name of the computer from which to retrieve software items. The default is the local computer.

.PARAMETER OperationTimeoutSec
  The maximum time, in seconds, that the function should wait for a response from the computer before timing out.

.PARAMETER FilterScript
  A script block that defines a filter to apply to the software items. Only software items that pass the filter are returned.

.EXAMPLE
  $computerName = $ENV:COMPUTERNAME
  Get-SoftwareItem -CN $computerName

  #This example retrieves all software items from the local computer.

  Output:
  DisplayName             DisplayVersion
  -----------             --------------
  Microsoft Office        16.0.4266.1001
  Adobe Reader            11.0.10

.EXAMPLE
  $computerName = 'localhost'
  $filterScript = { $_.DisplayName -like '*Microsoft*' }
  Get-SoftwareItem -CN $computerName -FilterScript $filterScript

  #This example retrieves all software items from the local computer that have 'Microsoft' in their display name.

  Output:
  DisplayName             DisplayVersion
  -----------             --------------
  Microsoft Office        16.0.4266.1001
  Microsoft Edge          89.0.774.63
#>
}  # End of Get-SoftwareItem function
