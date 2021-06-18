function Set-KPNBartResourceAccess {
    <#
    .SYNOPSIS
    Sets or updates access to a resource in KPN Bart

    .DESCRIPTION
    Sets or updates access to a resource in KPN Bart

    .PARAMETER ResourceAuthorization
    The type of the ResourceAuthorization that will be set

    Valid options are:
    Access
    ReadOnlyAccess
    ReadWriteAccess
    SendOnBehalf
    SendAs
    AutoMap

    .PARAMETER Identity
    The Identity of the user for whom you want to update the resource access. This is the Identity in Active Directory

    .PARAMETER ResourceIdentity
    The ResourceIdentity (AD Identity) of the resource

    .PARAMETER Add
    Determines if the ResourceAuthorization must be added
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [KPNBartConnectedServices.CommandService.ResourceAuthorizationEnum]
        $ResourceAuthorization,

        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $ResourceIdentity,

        [Boolean]
        $Add

    )

    process {
        if ($PSCmdlet.ShouldProcess("$ResourceIdentity", "Updating Resource")) {
            try {
                $resourceCommand = [KPNBartConnectedServices.CommandService.ResourceAuthorizationCommand]::new()
                $resourceCommand.UserIdentity = $Identity
                $resourceCommand.ResourceIdentity = $ResourceIdentity
                $resourceCommand.ResourceAuthorization = $ResourceAuthorization
                $resourceCommand.Set = $Add
                $null = $script:CommandService.Execute($resourceCommand)
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}