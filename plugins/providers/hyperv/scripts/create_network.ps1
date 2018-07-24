#Requires -Modules VagrantMessages, VagrantNet

param(
    [parameter(Mandatory=$true)]
    [string] $Name,
    [parameter(Mandatory=$true)]
    [string] $Type,
    [string] $AddressPrefix,
    [string] $Gateway
)

$ErrorActionPreference = "Stop"

try {
    New-VagrantHNSNetwork -Type $Type -Name "${Name}" -AddressPrefix $AddressPrefix `
      -Gateway $Gateway
} catch {
    Write-ErrorMessage "Failed to create network: ${PSItem}"
    exit 1
}
