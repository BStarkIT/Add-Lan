function Add-Lan {
    <#
.SYNOPSIS
A Script to create persistent network drives using credentials stored in an encrypted file.
.DESCRIPTION
This script retrieves credentials from an encrypted file and creates persistent network drives mapped to specific shared folders on
a network. It first removes any existing drives that are mapped to network locations, then creates new drives with specified names and paths.
It uses the PSCredential object to securely pass credentials for each drive mapping.
.PARAMETER Name
The name of the user for whom the network drives are to be created. Example: "User1"    
This script uses $name.txt and AES.key files located in the user's .ssh directory to retrieve encrypted credentials, & $name.csv for drive mappings.
.EXAMPLE
Run the script to create persistent network drives for the user "kosh" using credentials stored in an encrypted file.
.NOTES
Script written by: Brian Stark
Date: 28/06/2025
Modified by: Brian Stark
Date: 30/08/2025
Version: 1.0.1
.COMPONENT
PowerShell Version 5
encrypted credentials for network drives
.FUNCTIONALITY
This script is designed to manage network drives in a Windows environment, specifically for creating persistent drives with secure credentials.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $name
    )
    write-Host "Creating persistent network drives..."
    # Define the username and paths for the drives
    $PasswordFile = "$env:HOMEPATH\.ssh\$name.txt"
    $KeyFile = "$env:HOMEPATH\.ssh\AES.key"
    $key = Get-Content $KeyFile
    $encrypted = Get-Content $PasswordFile
    $secureStringDecrypt = ConvertTo-SecureString $encrypted -Key $key
    $Credential = New-Object System.Management.Automation.PSCredential($name, $secureStringDecrypt)
    $Drives = Import-Csv "$env:HOMEPATH\.ssh\$name.csv" | ForEach-Object {
        @{
            Name        = $_.mount
            Path        = $_.path
            Description = $_.name
        }
    }
    Write-Output "Using credentials for user: $Username"
    #Start adding drives
    if (-not(Test-Path -Path Z:)) {
        net use Z: https://live.sysinternals.com/tools
    } 
    Foreach ($Drive in $Drives) {
        if (-not(Test-Path -Path ($Drive.Name + ":\"))) {
            try {
                New-PSDrive -Name $Drive.Name -PSProvider FileSystem -Root $Drive.Path -Description $Drive.Description -Credential $Credential -Persist -Scope "Global"
                Write-Host "Drive $($Drive.Name): mapped to $($Drive.Path) successfully."
            }
            catch {
                Write-Host "Failed to map drive $($Drive.Name): to $($Drive.Path). Error: $_"
            }
        }
        else {
            Write-Host "Drive $($Drive.Name): already exists. Skipping..."
        }
        $keyname = $Drive.Path -replace '\\', '#'
        $keyValue = $Drive.Description
        $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\$keyname"
        Set-ItemProperty -Path $keyPath -Name '_LabelFromDesktopINI' -Value $keyValue
    }
    write-Host "Persistent network drives created successfully."
    # End of script
}
