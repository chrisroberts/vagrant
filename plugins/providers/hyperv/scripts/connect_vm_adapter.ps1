#Requires -Modules VagrantMessages

param(
    [parameter(Mandatory=$true)]
    [string] $AdapterID,
    [parameter(Mandatory=$true)]
    [string] $NetworkID=$null
)

$ErrorActionPreference = "Stop"

try {
    $Adapter = (Hyper-V\Get-VMNetworkAdapter | ? ID -eq "${AdapterID}")
    $network = Get-VagrantHNSNetwork -Id $NetworkID
    $switch = (Hyper-V\Get-VMSwitch | ? ID -eq $network.ID)
    Hyper-V\Connect-VMNetworkAdapter -VMNetworkAdapter $Adapter -VMSwitch $switch
} catch {
    Write-ErrorMessage "Failed to connect network adapter: ${PSItem}"
    exit 1
}
