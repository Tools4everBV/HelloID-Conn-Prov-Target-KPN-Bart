function Initialize-KPNBartQueryServiceClient {
    <#
    .SYNOPSIS
    Initializes the KPN Bart QueryService client

    .DESCRIPTION
    Initializes the KPN Bart QueryService client and creates a namespace [QueryService] so that the KPN Bart methods
    can be used througout this module

    .PARAMETER PSCredentials
    The credentials object containing the UserName and Password

    .PARAMETER Uri
    The Uri to your KPN Bart environment
    #>
    [OutputType([KPNBartConnectedServices.QueryService.QueryServiceClient])]
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
    $binding.MaxReceivedMessageSize = [int]::MaxValue # Needed to retrieve the groups
    $endpointAddress = [System.ServiceModel.EndpointAddress]::new("$uri/QueryService.svc")
    $bartQueryServiceClient = [KPNBartConnectedServices.QueryService.QueryServiceClient]::new($binding, $endpointAddress)
    $bartQueryServiceClient.ClientCredentials.Windows.ClientCredential =  New-Object System.Management.Automation.PSCredential($PSCredentials)
    $bartQueryServiceClient.ClientCredentials.Windows.AllowNtlm = $true

    Write-Output $bartQueryServiceClient
}