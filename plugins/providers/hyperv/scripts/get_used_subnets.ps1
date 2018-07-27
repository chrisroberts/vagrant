#Requires -Modules VagrantMessages

$ErrorActionPreference = "Stop"

try {
    $NetConfigs = Get-WmiObject Win32_NetworkAdapterConfiguration
    $Result = @()
    foreach($netconf in $NetConfigs) {
        $data = @{}
        foreach($addr in $netconf.IPAddress) {
            if($addr.Contains(".")) {
                $data += @{ Address = $addr; }
                break
            }
        }
        if(!$Address) {
            continue
        }
        foreach($mask in $netconf.IPSubnet) {
            if($mask.Contains(".")) {
                $data += @{ Netmask = $mask; }
                break
            }
        }
        foreach($gate in $netconf.DefaultIPGateway) {
            if($gate.Contains(".")) {
                $data += @{ Gateway = $gate; }
            }
        }
        $Result += $data
    }
    Write-OutputMessage (ConvertTo-Json $Result)
} catch {
    Write-ErrorMessage "Failed to generate host subnet list: ${PSItem}"
    exit 1
}
