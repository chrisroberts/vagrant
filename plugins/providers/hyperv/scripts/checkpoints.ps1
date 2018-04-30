Param(
    [Parameter(Mandatory=$true)]
    [string]$VmId,
    [string]$Action
)

# Include the following modules
$Dir = Split-Path $script:MyInvocation.MyCommand.Path
. ([System.IO.Path]::Combine($Dir, "utils\write_messages.ps1"))

$VM = Hyper-V\Get-VM -Id $VmId -ErrorAction "Stop"

if((Get-Command Hyper-V\Set-VM).Parameters["AutomaticCheckpointsEnabled"]) {
    $chkpt = $false
    if("${Action}" -eq "enable") {
        $chkpt = $true
    }
    Hyper-V\Set-VM -VM $VM -AutomaticCheckpointsEnabled $chkpt
}
