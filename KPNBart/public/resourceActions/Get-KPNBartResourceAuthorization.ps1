function Get-KPNBartResourceAuthorization {
    <#
    .SYNOPSIS
    Retrieves the users that are authorized for a resource in KPN Bart

    .PARAMETER ResourceIdentity
    The Identity of the resource (e.g. Group or FunctionGroup)

    .PARAMETER ResourceAuthorization
    The type of authorization to query. Defaults to Access
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $ResourceIdentity,

        [KPNBartConnectedServices.QueryService.ResourceAuthorizationEnum]
        $ResourceAuthorization = [KPNBartConnectedServices.QueryService.ResourceAuthorizationEnum]::Access
    )

    try {
        $resourceAuthorizationQuery = [KPNBartConnectedServices.QueryService.ResourceAuthorizationQuery]::new()
        $resourceAuthorizationQuery.ResourceIdentity = $ResourceIdentity
        $resourceAuthorizationQuery.ResourceAuthorization = $ResourceAuthorization

        $returnObject = $script:QueryService.Execute($resourceAuthorizationQuery)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
