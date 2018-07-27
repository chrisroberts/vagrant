#Requires -Modules VagrantMessages

param(
    [string] $AdapterName=$null
)

$ErrorActionPreference = "Stop"

try {
    if($AdapterName) {
        $Adapter = Get-NetAdapter -Name "${AdapterName}"
    } else {
        $Adapter = Get-NetAdapter -Physical | ? Name -Like "Ethernet*"
        if(!$Adapter) {
            throw "Failed to locate valid network adapter"
        }
    }
    $NetConf = (Get-WmiObject Win32_NetworkAdapterConfiguration | ? InterfaceIndex -eq $Adapter.ifIndex)
    foreach($addr in $NetConf.IPAddress) {
        if($addr.Contains(".")) {
            $Address = $addr
            break
        }
    }
    foreach($mask in $NetConf.IPSubnet) {
        if($mask.Contains(".")) {
            $Netmask = $mask
            break
        }
    }
    foreach($gate in $NetConf.DefaultIPGateway) {
        if($gate.Contains(".")) {
            $Gateway = $gate
        }
    }

    $Result = @{
        Address = $Address;
        Netmask = $Netmask;
        Gateway = $Gateway;
    }

    Write-OutputMessage (ConvertTo-Json $Result)
} catch {
    Write-ErrorMessage "Failed to detect host subnet: ${PSItem}"
    exit 1
}
