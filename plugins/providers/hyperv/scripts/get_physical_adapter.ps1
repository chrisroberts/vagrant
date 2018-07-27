#Requires -Modules VagrantMessages

param(
    [string] $AdapterName = $null
)

$ErrorActionPreference = "Stop"

try {
    if($AdapterName -and $AdapterName -ne "") {
        $Adapter = Get-NetAdapter -Physical -Name "${AdapterName}"
    } else {
        $Adapter = $(Get-NetAdapter -Physical | ? Status -eq "Up")[0]
    }
    if(!$Adapter) {
        throw "No physical adapter detected!"
    }
    $Result = $($Adapter | Select-Object Name,Status,MacAddress,InterfaceName,InterfaceDescription)
    Write-OutputMessage $(ConvertTo-JSON $Result)
} catch {
    Write-ErrorMessage "Failed to find physical network adapter: ${PSItem}"
    exit 1
}
