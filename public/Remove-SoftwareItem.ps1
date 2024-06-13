function Remove-SoftwareItem {
  [CmdletBinding(
    DefaultParameterSetName = 'InputObject',
    SupportsShouldProcess = $true)]
  param (
    [Parameter(
      Mandatory = $false,
      ValueFromPipeline = $true,
      Position = 0,
      ParameterSetName = 'InputObject'
    )]
    [SoftwareItem[]]$InputObject,
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
    [scriptblock]$FilterScript,

    [switch]$Force,
    [switch]$Confirm
  )
  begin {
    function Invoke-UninstallCommand {
      param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,
        [Parameter(Mandatory = $true)]
        [string]$UninstallString,
        [switch]$Quiet,
        [switch]$NoRestart,
        [switch]$Force
      )

      $uninstallScript = "Start-Process -FilePath 'msiexec' `
                          -ArgumentList '/x', '$UninstallString', '/quiet', '/norestart' `
                          -Wait `
                          -NoNewWindow `
                          -ErrorAction Stop"
      Invoke-Command -ComputerName $ComputerName -ScriptBlock ([scriptblock]::Create($uninstallScript))
    }
  }
  process {
    if (-NOT $InputObject) {
      $CimSession = [CimSession]::Create($CN)
      $InputObject = Get-SoftwareItem -CimSession $CimSession
    }
    foreach ($item in $InputObject) {
      try {
        if (-NOT $item.NoRemove -or $Force.IsPresent) {
          if ($Confirm.IsPresent -and -NOT $Force.IsPresent) {
            $shouldProcess = $PSCmdlet.ShouldProcess($item.DisplayName, "Removing Software")
            if (-NOT $shouldProcess) {
              Write-Warning -Message ("Skipping removal of {0} as it was not confirmed for removal." -f $item.DisplayName)
              continue
            }
          }
          Invoke-UninstallCommand -ComputerName $CN -DisplayName $item.DisplayName -UninstallString $item.UninstallString -Force:$Force
        }
      }
      catch {
        Write-Error -Message ('Failed to remove {0}: {1}' -f $item.DisplayName, $_)
      }
    }
  }
}
