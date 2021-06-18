function Set-KPNBartUserManager {
    <#
    .SYNOPSIS
    Set or update the manager for a KPN Bart user

    .DESCRIPTION
    Set or update the manager for a KPN Bart user

    .PARAMETER Identity
    The Identity of the user for whom you want to update the manager. This is the Identity in Active Directory

    .PARAMETER ManagerIdentity
    The Identity for the manager. This is the Identity in Active Directory

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $ManagerIdentity
    )

    process {
        if ($PSCmdlet.ShouldProcess("$Identity", "Setting manager with identity '$MangerIdentity'")) {
            try {
                $setManagerCommand = [KPNBartConnectedServices.CommandService.SetManagerCommand]::new()
                $setManagerCommand.UserIdentity = $Identity
                $setManagerCommand.ManagerIdentity = $ManagerIdentity

                $null = $Script:CommandService.Execute($setManagerCommand)
            } catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }
    }
}