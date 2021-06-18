function Enable-KPNBartUser {
    <#
    .SYNOPSIS
    Enables a KPN Bart user

    .DESCRIPTION
    Enables a KPN Bart user

    .PARAMETER Identity
    The Identity of the user you want to enable. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity
    )

    try {
        $enableUserCommand = [KPNBartConnectedServices.CommandService.ActivateUserCommand]::new()
        $enableUserCommand.UserIdentity = $Identity
        $null = $Script:CommandService.Execute($enableUserCommand)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}