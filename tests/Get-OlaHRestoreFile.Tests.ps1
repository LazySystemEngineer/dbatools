#Thank you Warren http://ramblingcookiemonster.github.io/Testing-DSC-with-Pester-and-AppVeyor/

if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}



$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
Import-Module $PSScriptRoot\..\internal\$sut -Force

Describe "Get-OlaHRestoreFile Unit Tests" -Tag 'Unittests'{
    #Mock Test-Path {$true}
    Context "Test Path handling" {
        It "Should throw on an invalid Path"{
            Mock Test-Path {$false}
            {Get-OlaHRestoreFile -Path c:\temp\} | Should Throw
        }
        Mock Test-Path {$true}
        It "Should throw if no FULL folder exists" {
            Mock Test-Path {$false} -ParameterFilter {$Path -and $Path -eq 'c:\temp\FULL'}
            {Get-OlaHRestoreFile -Path c:\temp} | Should Throw
        }
        It "Should call the Test-Path Full mock exactly once" {
            Assert-MockCalled Test-Path -ParameterFilter {$Path -and $Path -eq 'c:\temp\FULL'}  -Times 1
        }
    }
    Context "Test File returns" {
        New-item "TestDrive:\OlaH\" -ItemType directory
        New-item "TestDrive:\OlaH\Full\" -ItemType directory
        New-item "TestDrive:\OlaH\Full\full.bak" -ItemType File
        $results = Get-OlaHRestoreFile -Path TestDrive:\OlaH\
        It "Should return single object of System.IO.FileSystemInfo" {
            $results | Should BeOfType System.IO.FileSystemInfo
        }
        It "Should return 1 full backup - Just Fulll" {
            $results.count | Should be 1
        }
        It "Should return TestDrive:\OlaH\Full\full.bak"{
            $results.Fullname  | Should beLike '*\OlaH\Full\full.bak'
        }
    }
    Context "With Log Files" {  
        New-item "TestDrive:\OlaH\" -ItemType directory
        New-item "TestDrive:\OlaH\Full\" -ItemType directory
        New-item "TestDrive:\OlaH\Full\full.bak" -ItemType File
        New-item "TestDrive:\OlaH\Log\" -ItemType directory
        New-item "TestDrive:\OlaH\Log\log1.trn" -ItemType File
        New-item "TestDrive:\OlaH\Log\log2.trn" -ItemType File
        $results2 = Get-OlaHRestoreFile -Path TestDrive:\OlaH\
        It "Should an array of System.IO.FileSystemInfo" {
            $results2[1] | Should BeOfType System.IO.FileSystemInfo
        }
        It "Should return 3 files" {
            $results2.count | should be 3
        }
        It "Should contain 1 Full backup" {
            ($results2 | Where-Object {$_.Fullname -like '*\OlaH\Full\*.bak'}).count | Should be 1
        }    
        It "Shoud contain 2 log backups" {
            ($results2 | Where-Object {$_.Fullname -like '*\OlaH\Log\*.trn'}).count | Should be 2
        }   
    }
    Context "With Diff Files" {  
        New-item "TestDrive:\OlaH\" -ItemType directory
        New-item "TestDrive:\OlaH\Full\" -ItemType directory
        New-item "TestDrive:\OlaH\Full\full.bak" -ItemType File
        New-item "TestDrive:\OlaH\Log\" -ItemType directory
        New-item "TestDrive:\OlaH\Log\log1.trn" -ItemType File
        New-item "TestDrive:\OlaH\Log\log2.trn" -ItemType File
        New-item "TestDrive:\OlaH\Diff\" -ItemType directory
        New-item "TestDrive:\OlaH\Diff\Diff1.bak" -ItemType File
        New-item "TestDrive:\OlaH\Diff\Diff2.bak" -ItemType File
        $results3 = Get-OlaHRestoreFile -Path TestDrive:\OlaH\
        It "Should an array of System.IO.FileSystemInfo" {
            $results3[1] | Should BeOfType System.IO.FileSystemInfo
        }
        It "Should return 5 files" {
            $results3.count | should be 5
        }
        It "Should contain 1 Full backup" {
            ($results3 | Where-Object {$_.Fullname -like '*\OlaH\Full\*.bak'}).count | Should be 1
        }    
        It "Shoud contain 2 log backups" {
            ($results3 | Where-Object {$_.Fullname -like '*\OlaH\Log\Log*.trn'}).count | Should be 2
        }
        It "Shoud contain 2 Diff backups" {
            ($results3 | Where-Object {$_.Fullname -like '*\OlaH\Diff\Diff*.bak'}).count | Should be 2
        }   
    }
}