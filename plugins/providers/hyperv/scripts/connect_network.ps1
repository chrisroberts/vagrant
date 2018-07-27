#Requires -Modules VagrantMessages, VagrantNet

param(
    [parameter(Mandatory=$true)]
    [string] $Name,
    [parameter(Mandatory=$true)]
    [string] $NetworkID,
    [parameter(Mandatory=$false)]
    [string] $IPAddress=$null,
    [parameter(Mandatory=$false)]
    [string] $Gateway=$null,
    [parameter(Mandatory=$false)]
    [string] $AdapterName=$null,
    [parameter(Mandatory=$false)]
    [string] $CompartmentID=$null
)

$ErrorActionPreference = "Stop"

try {
    $network = Get-VagrantHNSNetwork -Id $NetworkID
    $EndpointArgs = @{
        "Name" = "${Name}";
        "NetworkId" = $network.ID;
    }
    if($IPAddress -and $IPAddress -ne "") {
        $EndpointArgs += @{ "IPAddress" = $IPAddress; }
    }
    if($Gateway -and $Gateway -ne "") {
        $EndpointArgs += @{ "Gateway" = $Gateway; }
    }
    $Endpoint = New-VagrantHNSEndpoint @EndpointArgs
} catch {
    Write-ErrorMessage "Failed to create network endpoint: ${PSItem} - Args: ${EndpointArgs}"
    exit 1
}

try {
    $AttachArgs = @{
        "EndpointId" = $Endpoint.Id;
    }
    if($AdapterName -and $AdapterName -ne "") {
        $AttachArgs += @{
            "Type" = "VirtualMachine";
            "NetworkAdapterName" = "${AdapterName}";
        }
    }
    if($CompartmentID -and $CompartmentID -ne "") {
        $AttachArgs += @{
            "Type" = "Host";
            "CompartmentId" = $CompartmentID;
        }
    }
    Attach-VagrantHNSEndpoint @AttachArgs

    $result = ($Endpoint | Select-Object IPAddress,MacAddress,Name)
    Write-OutputMessage (ConvertTo-Json $result)
} catch {
    Write-ErrorMessage "Failed to attach network endpoint: ${PSItem}"
    exit 1
}
