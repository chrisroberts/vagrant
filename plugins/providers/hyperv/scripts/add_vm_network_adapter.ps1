#Requires -Modules VagrantMessages

param(
    [parameter(Mandatory=$true)]
    [string] $VMID,
    [parameter(Mandatory=$true)]
    [string] $AdapterName,
    [parameter(Mandatory=$false)]
    [string] $NetworkID=$null
)

$ErrorActionPreference = "Stop"

try {
    $VM = Hyper-V\Get-VM -Id $VMID
    $AddArgs = @{
        "VM" = $VM;
        "Name" = "${AdapterName}";
    }
    if($NetworkID -and $NetworkID -ne "") {
        $network = Get-VagrantHNSNetwork -Id $NetworkID
        $switch = (Hyper-V\Get-VMSwitch | ? Name -eq $network.Name)
        $AddArgs += @{ "SwitchName" = "$($switch.Name)"; }
    }
    $Adapter = Hyper-V\Add-VMNetworkAdapter @AddArgs -PassThru
    Write-OutputMessage (ConvertTo-Json @{ Name = $AdapterName })
} catch {
    Write-ErrorMessage "Failed to add network adapter: ${PSItem}"
    exit 1
}
