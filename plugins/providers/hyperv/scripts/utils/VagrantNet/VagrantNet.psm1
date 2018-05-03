# Make HNS available
function Get-VagrantVMComputeMethods {
    $vmcompute = @'
[DllImport("vmcompute.dll")]
public static extern void HNSCall(
    [MarshalAs(UnmanagedType.LPWStr)] string method,
    [MarshalAs(UnmanagedType.LPWStr)] string path,
    [MarshalAs(UnmanagedType.LPWStr)] string request,
    [MarshalAs(UnmanagedType.LPWStr)] out string response
);
'@
    Add-Type -MemberDefinition $vmcompute -Namespace VmCompute.PrivatePInvoke -Name NativeMethods -PassThru
}

# Interface into HNS
function Invoke-VagrantHNS {
    param (
        [ValidateSet('DELETE', 'GET', 'POST')]
        [parameter(Mandatory=$true)]
        [string] $Method,
        [ValidateSet('activities', 'endpoints', 'endpointstats', 'networks', 'policylists', 'plugins')]
        [parameter(Mandatory=$true)]
        [string] $Type,
        [parameter(Mandatory=$false)]
        [string] $Action = $null,
        [parameter(Mandatory=$false)]
        [string] $Request = "",
        [parameter(Mandatory=$false)]
        [Guid] $Id = [Guid]::Empty
    )
    $path = "/${Type}"
    if($Id -ne [Guid]::Empty){ $path += "/${Id}" }
    if($Action){ $path += "/${Action}" }
    $api = Get-VMComputeMethods
    $output = ""
    $result = ""
    $api::HNSCall($Method, $path, "${request}", [ref] $result)
    if($result) {
        try { $output = ($result | ConvertFrom-Json) }
        catch {
            Write-Error $_.Exception.Message
            return ""
        }
        if($output.Error){ Write-Error $output }
        $output = $output.Output
    }
    return $output
}

### HNSNetwork Functions

function Get-VagrantHNSNetwork {
    param (
        [parameter(Mandatory=$false)]
        [Guid] $Id = [Guid]::Empty
    )
    return Invoke-VagrantHNS -Type networks -Method GET -Id $Id
}

function Remove-VagrantHNSNetwork {
    param (
        [parameter(Mandatory=$true)]
        [Guid] $Id
    )
    return Invoke-VagrantHNS -Type networks -Method DELETE -Id $Id
}

function New-VagrantHNSNetwork {
    param (
        [ValidateSet('ICS', 'Internal', 'L2Bridge', 'L2Tunnel', 'Layered', 'NAT', 'Overlay', 'Private', 'Transparent')]
        [parameter(Mandatory=$true)]
        [string] $Type,
        [parameter(Mandatory=$false)]
        [string] $Name = $null,
        [parameter(Mandatory=$false)]
        [string] $AddressPrefix = $null,
        [parameter(Mandatory=$false)]
        [string] $Gateway = $null,
        [parameter(Mandatory=$false)]
        [string] $DNSServer = $null,
        [parameter(Mandatory=$false)]
        [string] $AdapterName = $null
    )

    $req = @{
        Type = $Type
    }
    if($Name){ $req += @{ Name = $Name; } }
    if($DNSServer){ $req += @{ DNSServerList = $DNSServer; } }
    if($AdapterName){ $req += @{ NetworkAdapterName = $AdapterName; } }
    if($AddressPrefix -and $Gateway){
        $req += @{
            Subnets = @(
                @{
                    AddressPrefix = $AddressPrefix;
                    GatewayAddress = $Gateway;
                }
            )
        }
    }
    return Invoke-VagrantHNS -Type networks -Method POST -Request (ConvertTo-Json $req -Depth 5)
}

### HNSEndpoint Functions

function Get-VagrantHNSEndpoint {
    param (
        [parameter(Mandatory=$false)]
        [Guid] $Id = [Guid]::Empty
    )
    return Invoke-VagrantHNS -type endpoints -Method Get -Id $Id
}

function Remove-VagrantHNSEndpoint {
    param (
        [parameter(Mandatory=$true)]
        [Guid] $Id
    )
    return Invoke-VagrantHNS -type endpoints -Method DELETE -Id $Id
}

function New-VagrantHNSEndpoint {
    param (
        [parameter(Mandatory=$true)]
        [string] $Name,
        [parameter(Mandatory=$false)]
        [Guid] $NetworkId,
        [parameter(Mandatory=$false)]
        [string] $IPAddress = $null,
        [parameter(Mandatory=$false)]
        [string] $Gateway = $null,
        [parameter(Mandatory=$false)]
        [string] $MACAddress = $null
    )

    $req = @{
        Name = $Name,
        VirtualNetwork = $NetworkId;
        Policies = @()
    }
    if($IPAddress){ $req += @{ IPAddress = $IPAddress } }
    if($Gateway){ $req += @{ GatewayAddress = $Gateway } }
    if($MACAddress){ $req += @{ MacAddress = $MACAddress } }
    return Invoke-VagrantHNS -Type endpoints -Method POST -Request (ConvertTo-Json $req -Depth 5)
}

function Attach-VagrantHNSEndpoint {
    param (
        [parameter(Mandatory=$true)]
        [Guid] $EndpointId,
        [parameter(Mandatory=$true)]
        [string] $NetworkAdapterName
    )
    $req = {
        SystemType = "VirtualMachine";
        VirtualNicName = $NetworkAdapterName
    }
    return Invoke-VagrantHNS -Type endpoints -Method POST -Id $EndpointId -Action "attach" -Request (ConvertTo-Json $req -Depth 5)
}

function Detach-VagrantHNSEndpoint {
    param (
        [parameter(Mandatory=$true)]
        [Guid] $EndpointId
    )
    $req = { SystemType = "VirtualMachine" }
    return Invoke-VagrantHNS -Type endpoints -Method POST -Id $EndpointId -Action "detach" -Request (ConvertTo-Json $req -Depth 5)
}

### HNSPolicy Functions

function New-VagrantHNSRoutePolicy {
    param (
        [parameter(Mandatory=$true)]
        [Guid] $EndpointId
        [parameter(Mandatory=$true)]
        [string] $DestinationPrefix
        [parameter(Mandatory=$true)]
        [bool] $Encapsulate
    )
    $req = @{
        References = @(
            "/endpoints/${EndpointId}"
        );
        Policies = @(
            @{
                Type = "ROUTE";
                DestinationPrefix = $DestinationPrefix;
                NeedEncap = $Encapsulate;
            }
        );
    }
    return Invoke-VagrantHNS -Type policylists -Method POST -Request (ConvertTo-Json $req -Depth 10)
}

function Remove-VagrantHNSRoutePolicy {
    param (
        [parameter(Mandatory=$true)]
        [Guid] $EndpointId
    )
    $req = @{
        References = @(
            "/endpoints/${EndpointId}"
        );
    }
    return Invoke-VagrantHNS -type policylists -Method Get -Request (ConvertTo-Json $req -Depth 5)
}

Export-ModuleMember -Function Invoke-VagrantHNS
Export-ModuleMember -Function Get-VagrantHNSNetwork
Export-ModuleMember -Function New-VagrantHNSNetwork
Export-ModuleMember -Function Remove-VagrantVHNSNetwork
Export-ModuleMember -Function Get-VagrantHNSEndpoint
Export-ModuleMember -Function New-VagrantHNSEndpoint
Export-ModuleMember -Function Remove-VagrantVHNSEndpoint
Export-ModuleMember -Function Attach-VagrantHNSEndpoint
Export-ModuleMember -Function Detach-VagrantVHNSEndpoint
Export-ModuleMember -Function New-VagrantHNSRoutePolicy
Export-ModuleMember -Function Remove-VagrantHNSRoutePolicy
