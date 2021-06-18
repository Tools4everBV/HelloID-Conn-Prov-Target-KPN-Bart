function Set-KPNBartUserPassword {
    <#
    .SYNOPSIS
    Set or update the password

    .DESCRIPTION
    Set or update the password for the specified user in KPN Bart

    .PARAMETER Identity
    The Identity of the user for whom you want to update the password. This is the Identity in Active Directory

    .PARAMETER Password
    The new value of the password
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [Parameter(Mandatory)]
        [SecureString]
        $Password
    )

    try {
        $setPasswordCommand = [KPNBartConnectedServices.CommandService.SetPasswordCommand]::new()
        $setPasswordCommand.ObjectIdentity = $Identity
        $setPasswordCommand.Password = $Password

        $null = $Script:CommandService.Execute($setPasswordCommand)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}