function Remove-KPNBartUser {
    <#
    .SYNOPSIS
    Removes a user from KPN Bart

    .DESCRIPTION
    Removes the specified user in KPN Bart

    .PARAMETER Identity
    The Identity of the user you want to remove. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity
    )

    try {
        $deleteEntityCommand = [KPNBartConnectedServices.CommandService.DeleteEntityCommand]::new()
        $deleteEntityCommand.EntityIdentity = $Identity

        $null = $script:CommandService.Execute($deleteEntityCommand)       
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}