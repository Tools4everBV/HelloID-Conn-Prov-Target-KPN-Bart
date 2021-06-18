function Initialize-KPNBartCommandServiceClient {
    <#
    .SYNOPSIS
    Initializes the KPN Bart CommandService client

    .DESCRIPTION
    Initializes the KPN Bart CommandService client and creates a namespace [CommandService] so that the KPN Bart methods
    can be used througout this module

    .PARAMETER PSCredentials
    The credentials object containing the UserName and Password

    .PARAMETER Uri
    The Uri to your KPN Bart environment
    #>
    [OutputType([KPNBartConnectedServices.CommandService.CommandServiceClient])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscredential]
        $PSCredentials,

        [Parameter(Mandatory)]
        [String]
        $Uri
    )

    $binding = New-WSHttpBinding
    $endpointAddress = [System.ServiceModel.EndpointAddress]::new("$uri/CommandService.svc")
    $bartCommandServiceClient = [KPNBartConnectedServices.CommandService.CommandServiceClient]::new($binding, $endpointAddress)
    $bartCommandServiceClient.ClientCredentials.Windows.ClientCredential =  New-Object System.Management.Automation.PSCredential($PSCredentials)
    $bartCommandServiceClient.ClientCredentials.Windows.AllowNtlm = $true

    Write-Output $bartCommandServiceClient
}