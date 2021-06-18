function Initialize-KPNBartBulkCommandServiceClient {
    <#
    .SYNOPSIS
    Initializes the KPN Bart BulkCommandService client

    .DESCRIPTION
    Initializes the KPN Bart BulkCommandService client and creates a namespace [BulkCommandService] so that the KPN Bart methods
    can be used througout this module

    .PARAMETER PSCredentials
    The credentials object containing the UserName and Password

    .PARAMETER Uri
    The Uri to your KPN Bart environment
    #>
    [OutputType([KPNBartConnectedServices.BulkCommandService.BulkCommandServiceClient])]
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
    $endpointAddress = [System.ServiceModel.EndpointAddress]::new("$uri/BulkCommandService.svc")
    $bartBulkCommandServiceClient = [KPNBartConnectedServices.BulkCommandService.BulkCommandServiceClient]::new($binding, $endpointAddress)
    $bartBulkCommandServiceClient.ClientCredentials.Windows.ClientCredential =  New-Object System.Management.Automation.PSCredential($PSCredentials)
    $bartBulkCommandServiceClient.ClientCredentials.Windows.AllowNtlm = $true

    Write-Output $bartBulkCommandServiceClient
}