#Requires -Modules VagrantMessages, VagrantNet

param(
    [parameter(Mandatory=$true)]
    [string] $Name,
    [parameter(Mandatory=$true)]
    [string] $Type,
    [string] $AddressPrefix,
    [string] $Gateway,
    [string] $AdapterName
)

$ErrorActionPreference = "Stop"

try {
    $NewNet = New-VagrantHNSNetwork -Type $Type -Name "${Name}" -AddressPrefix $AddressPrefix `
      -Gateway $Gateway -AdapterName "${AdapterName}"
    $Result = ($NewNet | Select-Object Name,ID,State,Subnets,Type)
    Write-OutputMessage (ConvertTo-Json $Result)
} catch {
    Write-ErrorMessage "Failed to create network: ${PSItem}"
    exit 1
}
