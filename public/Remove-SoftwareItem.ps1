using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace Microsoft.Win32
function Remove-SoftwareItem {
  [CmdletBinding(
    ConfirmImpact = 'High',
    SupportsShouldProcess = $true)]
  param (
    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $true,
      Position = 0,
      ParameterSetName = 'fromPipeline'
    )]
    [SoftwareItem[]]$InputObject,

    [Parameter(Mandatory = $false,
      ParameterSetName = 'NewSession')]
    [Alias('ComputerName')]
    [string[]]$CN = $ENV:COMPUTERNAME,
    [Parameter(Mandatory = $false,
      ParameterSetName = 'NewSession')]
    [CredentialAttribute()]
    [PSCredential]$Credential,
    [Parameter(Mandatory = $false,
      ParameterSetName = 'UseSession')]
    [cimsession[]]$CimSession,
    [uint]$OperationTimeoutSec = 60,

    [Parameter(
      Mandatory = $false,
      ParameterSetName = 'Filter'
    )]
    [Alias('Filter')]
    [scriptblock]$FilterScript,
    [switch]$NoRestart,
    [switch]$CloseSession,
    [switch]$Force
  )

  begin {
    function Invoke-UninstallCommand {
      [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
      param (
        [Parameter(
          Mandatory = $false,
          ParameterSetName = 'NewSession')]
        [string]$ComputerName,
        [Parameter(
          Mandatory = $false,
          ParameterSetName = 'NewSession')]
        [PSCredential]$Credential,
        [Parameter(
          Mandatory = $false,
          ParameterSetName = 'ByCimSession')]
        [CimSession[]]$CimSession,
        [Parameter(Mandatory = $false)]
        [string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [string]$UninstallString,
        [switch]$Quiet,
        [switch]$NoRestart,
        [switch]$Force
      )
      switch ( $PSCmdlet.ParameterSetName ) {
        'ByComputerName' {
          $CimSession = @(New-CimSession -ComputerName $ComputerName -Credential $Credential)
          $computerName = $CimSession.ComputerName
        }
        'ByCimSession' {
          foreach ($session in $CimSession) {
            $ComputerName = $session.ComputerName
            if ($PSCmdlet.ShouldProcess($ComputerName, ('Uninstall software item: {0}' -f $session.DisplayName))) {
              $scriptBlock = [ScriptBlock]::Create(([string]::format('Start-Process -FilePath "msiexec" -ArgumentList "/x", "{0}", $(if($Quiet){"/quiet"}), $(if($NoRestart){"/norestart"}), $(if($Force){"/forcerestart"}) -Wait', $session.UninstallString)))
              try {
                Invoke-Command -CimSession $session -ScriptBlock $scriptBlock
              }
              catch {
                Write-Error -Message ("Failed to invoke uninstall command for {0} on {1}: {2}" -f $session.DisplayName, $session.ComputerName, $_)
              }
            }
          }
        }
        default {
          throw 'Invalid parameter set name'
        }
      }
    }
  }
  process {
    switch ($PSCmdlet.ParameterSetName) {
      'fromPipeline' {
        foreach ($obj in $InputObject) {
          if (-NOT $Confirm -or $Force) {
            $message = if ($inputobject.count -eq 1) {
              'Uninstall ' + $obj.DisplayName
            }
            elseif ($InputObject.count -gt 3) {
              "{0} and {1} number more items" -f ($obj.Displayname, $InputObject.Count)
            }
            if ($PSCmdlet.ShouldProcess(
                $obj.ComputerName, $message)) {
              try {
                Invoke-UninstallCommand -UninstallString $obj.uninstallString -Quiet:$Quiet -NoRestart:$NoRestart -Force:$Force
              }
              catch {
                Write-Error -Message ("Failed to uninstall software item: {0}" -f $obj.DisplayName)
              }
            }
            else {
              Write-Warning -Message "{0} removal cancelled by the user." -f $obj.DisplayName
            }
          }
        }
      }
      'NewSession' {
        foreach ($computer in $CN) {
          $CimSession = New-CimSession -ComputerName $computer -Credential $Credential -OperationTimeoutSec $OperationTimeoutSec
          $softwareItems = Get-SoftwareItem -CimSession $CimSession
          foreach ($softwareItem in $softwareItems) {
            if ($softwareItem.DisplayName -eq $softwareDisplayName) {
              if ($PSCmdlet.ShouldProcess($computer, ('Uninstall software item: {0}' -f $softwareDisplayName))) {
                Invoke-UninstallCommand -ComputerName $computer -Credential $Credential -DisplayName $softwareDisplayName -UninstallString $softwareItem.UninstallString -NoRestart:$NoRestart -Force:$Force
              }
            }
          }
        }
      }
      'UseSession' {
        foreach ($session in $CimSession) {
          $softwareItems = Get-SoftwareItem -CimSession $session
          foreach ($softwareItem in $softwareItems) {
            if ($softwareItem.UninstallString -eq $softwareDisplayName) {
              if ($PSCmdlet.ShouldProcess($session.ComputerName, ('Uninstall software item: {0}' -f $softwareDisplayName))) {
                Invoke-UninstallCommand -CimSession $session -DisplayName $softwareDisplayName -UninstallString $softwareItem.UninstallString -NoRestart:$NoRestart -Force:$Force
              }
            }
          }
        }
      }
    }
  }
}
