#Requires -Modules VagrantMessages, VagrantNet

param(
    [Guid] $NetworkId = [Guid]::Empty
)

$ErrorActionPreference = "Stop"

try {
    $Networks = @(Get-VagrantHNSNetwork -Id $NetworkId |`
      Select-Object CurrentEndpointCount,GatewayMacHash,ID,IsolateSwitch,MacPools,Name,Subnets,Type)
    Write-OutputMessage $(ConvertTo-JSON $Networks)
} catch {
    Write-ErrorMessage "Failed to get networks: ${PSItem}"
    exit 1
}
