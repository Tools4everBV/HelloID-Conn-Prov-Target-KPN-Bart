function Set-KPNBartUserRole {
    <#
    .SYNOPSIS
    Sets a KPN Bart role

    .DESCRIPTION
    Sets a KPN Bart role for a particulair user

    .PARAMETER RoleName
    The RoleName of the role you want to set

    .PARAMETER Identity
    The Identity for the user you want to update. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [String]
        $RoleName,

        [String]
        $Identity
    )

    try {
        $setRoleCommand = [KPNBartConnectedServices.CommandService.BartRoleCommand]::new()
        $setRoleCommand.BartRole = $RoleName
        $setRoleCommand.userIdentity = $Identity
        $null = $script:CommandService.Execute($setRoleCommand)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}