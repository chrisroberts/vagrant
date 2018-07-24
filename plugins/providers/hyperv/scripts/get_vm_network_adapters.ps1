#Requires -Modules VagrantVM, VagrantMessages

param(
    [parameter (Mandatory=$true)]
    [Guid] $VMID
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
    $Adapters = @(Hyper-V\Get-VMNetworkAdapter -VM $VM | `
      Select-Object Name,ID,SwitchName)
    Write-OutputMessage $(ConvertTo-JSON $Adapters)
} catch {
    Write-ErrorMessage "Failed to locate VM: ${PSItem}"
    exit 1
}
