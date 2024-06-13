# Import the module
Import-Module -Name "$PSScriptRoot\CIMSoftwareManagement.psd1" -Force -Verbose

Describe "Get-SoftwareItem Tests" {
  BeforeAll {
    # Mock the Format-Bytes function to return a predictable result
    Mock Format-Bytes { return "100 MB" }
  }

  It "Should return software items with correct properties" {
    # Arrange
    $expectedComputerName = $ENV:COMPUTERNAME

    # Act
    $results = Get-SoftwareItem -CN $expectedComputerName

    # Assert
    $results | ForEach-Object {
      $_.ComputerName | Should -Be $expectedComputerName
      $_.Architecture | Should -Be ('x86' -or 'x64' -or $null)
      $_.EstimatedSize | Should -Match "\s(B|KB|MB|GB|TB)|$"
    }
  }
}

Describe "Remove-SoftwareItem Tests" {
  BeforeAll {
    # Mock the Remove-CimInstance function to prevent actual deletion
    Mock Remove-CimInstance { return $null } -ParameterFilter { $_ -is [System.Management.Automation.PSCustomObject] }
  }

  It "Should call Remove-CimInstance with correct parameters" {
    # Arrange
    $expectedComputerName = $ENV:COMPUTERNAME
    $expectedSoftwareName = 'TestSoftware'

    # Act
    Remove-SoftwareItem -CN $expectedComputerName -Filter { $_.Name -eq $expectedSoftwareName } -Force

    # Assert
    Assert-MockCalled Remove-CimInstance -ParameterFilter {


    }
  }
  It "Should throw an error for non-existent computer" {
    # Arrange
    $nonExistentComputerName = "NonExistentComputer"
    $softwareName = 'TestSoftware'

    # Act and Assert
    { Remove-SoftwareItem -CN $nonExistentComputerName } | Should -Throw
  }
}
