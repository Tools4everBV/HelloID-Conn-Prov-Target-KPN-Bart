function Remove-KPNBartEmailAlias {
    <#
    .SYNOPSIS
    Removes an email address alias

    .DESCRIPTION
    Removes an email address alias for a user in KPN Bart

    .PARAMETER Identity
    The Identity of the user. This is the Identity in Active Directory

    .PARAMETER EmailAddress
    The EmailAddress you want to remove
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [String]
        $EmailAddress
    )

    try {
        $removeAliasCommand = [KPNBartConnectedServices.CommandService.RemoveEmailAliasCommand]::new()
        $removeAliasCommand.ObjectIdentity = $Identity
        $removeAliasCommand.EmailAddress = $EmailAddress
        $null = $script:CommandService.Execute($removeAliasCommand)
               
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}