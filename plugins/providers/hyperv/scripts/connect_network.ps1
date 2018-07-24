#Requires -Modules VagrantMessages, VagrantNet

param(
    [parameter(Mandatory=$true)]
    [string] $NetworkID,
    [parameter(Mandatory=$true)]
    [string] $AdapterName
)

$ErrorActionPreference = "Stop"

try {
    $Endpoint = New-VagrantHNSEndpoint -Name "VagrantEndpoint" -NetworkId $NetworkID
    Attach-VagrantHNSEndpoint -EndpointId $Endpoint.Id -NetworkAdapterName $AdapterName
} catch {
    Write-ErrorMessage "Failed to attach the network adapter: ${PSItem}"
    exit 1
}
