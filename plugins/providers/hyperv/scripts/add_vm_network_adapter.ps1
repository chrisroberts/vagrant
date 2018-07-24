#Requires -Modules VagrantMessages, VagrantNet

param(
    [parameter(Mandatory=$true)]
    [string] $VMID,
    [parameter(Mandatory=$true)]
    [string] $AdapterName
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VmID
    $Adapter = Add-VMNetworkAdapter -VM $VM -Name "${AdapterName}" -PassThru
    Write-OutputMessage (ConvertTo-Json @{ name = $AdapterName })
} catch {
    Write-ErrorMessage "Failed to add network adapter: ${PSItem}"
    exit 1
}
