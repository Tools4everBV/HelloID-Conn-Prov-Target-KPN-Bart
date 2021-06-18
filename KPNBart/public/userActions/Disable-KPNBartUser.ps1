function Disable-KPNBartUser {
    <#
    .SYNOPSIS
    Disables a KPN Bart user

    .DESCRIPTION
    Disables the specified user in KPN Bart user. This prevents the user from loggingOn

    .PARAMETER Identity
    The Identity of the user you want to disable. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity
    )
    try {
        $disableUserCommand = [KPNBartConnectedServices.CommandService.DeactivateUserCommand]::new()
        $disableUserCommand.UserIdentity = $Identity
        $null = $Script:CommandService.Execute($disableUserCommand)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}