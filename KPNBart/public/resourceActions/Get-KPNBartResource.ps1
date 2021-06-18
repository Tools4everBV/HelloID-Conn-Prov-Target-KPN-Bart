function Get-KPNBartResource {
    <#
    .SYNOPSIS
    Retrieves all resources from KPN Bart

    .DESCRIPTION
    Retrieves all resources from KPN Bart

    .PARAMETER ResourceType
    The type of the resources that will be retrieved

    Valid options are:
    DesktopApplication
    PortalApplication
    MobileApplication
    FunctionGroup
    Share
    Group
    ConferenceRoom
    DistributionList
    SharedMailbox
    PhysicalWorkspaceApplication
    SyncFile
    CloudSharedMailbox
    Server

    .PARAMETER Identity
    The Identity of the user for whom you want to retrieve the resources. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.QueryService.ResourceTypeEnum]
        $ResourceType,

        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $Identity
    )

    try {
        if ($Identity) {
            $resourceQuery = [KPNBartConnectedServices.QueryService.UserAuthorizationQuery]::new()
            $resourceQuery.ResourceType = $ResourceType
            $resourceQuery.UserIdentity = $Identity
        } else {
            $resourceQuery = [KPNBartConnectedServices.QueryService.ResourceQuery]::new()
            $resourceQuery.ResourceType = $ResourceType
        }
        $returnObject = $script:QueryService.Execute($resourceQuery)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}