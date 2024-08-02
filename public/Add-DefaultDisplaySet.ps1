function Add-DefaultDisplaySet {
  [CmdletBinding()]
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [object]$InputObject,
    [ValidateNotNullOrEmpty()]
    [string]$TypeName,
    [Hashtable]$PropertyToAdd,
    [string[]]$DefaultProperty,
    [switch]$Force,
    [switch]$PassThru
  )
  if ($Input) {
    $InputObject = $Input
  }
  if ((-NOT $PSBoundParameters.ContainsKey('TypeName')) -and $InputObject.psobject.Typenames[0] -match 'Selected|PSCustomObject|PSObject') {
    Write-Error -Message 'Object must have a custom type name associated. Specify the type name using the ''TypeName'' argument' -ErrorAction Stop
  }
  else {
    foreach ($Object in $InputObject) {
      switch ($PSBoundParameters.Keys) {
        'PropertyToAdd' {
          foreach ($Key in $PropertyToAdd.Keys) {
            switch ($PropertyToAdd[$Key].GetType().Name) {
              'ScriptBlock' {
                #Set value to the value of the script block against the object
                $Object.PSObject.Properties.Add(([Management.Automation.PSScriptProperty]::new($Key, $PropertyToAdd[$Key])))
                break
              }
              default {
                $Object.PSObject.Properties.Add(([Management.Automation.PSNoteProperty]::new($Key, $PropertyToAdd[$Key])))
                break
              }
            }
          }
        }
        'TypeName' {
          $null = $Object.PSObject.TypeNames.Insert(0, $TypeName)
        }
        'DefaultProperty' {
          $DefaultDisplayPropertySet = New-Object -TypeName Management.Automation.PSPropertySet -ArgumentList ('DefaultDisplayPropertySet', [string[]]$DefaultProperty)
          $PSStandardMembers = [Management.Automation.PSMemberInfo[]]@($DefaultDisplayPropertySet)
          Add-Member -InputObject $Object -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers -Force:$Force
        }
      }
      if ($Passthru) {
        $Object
      }
    }
  }
  <#
.SYNOPSIS
  Adds a default display set to an object in PowerShell.

.DESCRIPTION
  The Add-DefaultDisplaySet function adds a default display set to a Psobject. The default display set includes properties that are displayed by default when the CIM instance is formatted as a table.

.PARAMETER InputObject
  The object to which the default display set will be added. This parameter accepts pipeline input.

.PARAMETER TypeName
  The custom type name associated the powershell or .Net object. If not specified, the object should bave a type or custom type name associated.

.PARAMETER PropertyToAdd
  A hashtable containing the properties to add to the object. The keys represent the property names, and the values represent the property values. The values can be either script blocks or regular values.

.PARAMETER DefaultProperty
  An array of property names that should be included in the default display set.

.PARAMETER Force
  If specified, forces the addition of the default display set even if the object already has a default display set.

.PARAMETER PassThru
  If specified, returns the modified object after adding the default display set.

.EXAMPLE
  $software | Add-DefaultDisplaySet -TypeName 'SoftwareItem' -PropertyToAdd @{
  'CustomProperty' = 'CustomValue'
  } -DefaultProperty 'DisplayName', 'DisplayVersion'

  This example adds a default display set to the $software object. The custom type name is set to 'SoftwareItem', and a custom property 'CustomProperty' with the value 'CustomValue' is added. The default display set includes the 'DisplayName' and 'DisplayVersion' properties.

.EXAMPLE
  $software | Add-DefaultDisplaySet -PropertyToAdd @{
  'CustomProperty' = { 'CustomValue' }
  } -DefaultProperty 'DisplayName', 'DisplayVersion' -PassThru

  This example adds a default display set to the $software object. A custom property 'CustomProperty' with a script block value is added. The default display set includes the 'DisplayName' and 'DisplayVersion' properties. The modified object is returned.
#>
}
