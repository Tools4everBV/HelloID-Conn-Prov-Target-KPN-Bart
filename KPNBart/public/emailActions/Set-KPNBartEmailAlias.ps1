function Set-KPNBartEmailAlias {
    <#
    .SYNOPSIS
    Set or updates an email address alias

    .DESCRIPTION
    Set or updates an email address alias for a user in KPN Bart

    .PARAMETER Identity
    The Identity of the user. This is the Identity in Active Directory

    .PARAMETER EmailAddress
    The EmailAddress you want to set or update
    #>
    [CmdletBinding()]
    param (
        [String]
        $Identity,

        [String]
        $EmailAddress
    )

    try {
        $removeAliasCommand = [KPNBartConnectedServices.CommandService.RemoveEmailAliasCommand]::new()
        $removeAliasCommand.ObjectIdentity = $Identity
        $removeAliasCommand.EmailAddress = $EmailAddress
        $returnObject = $script:CommandService.Execute($removeAliasCommand)

        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}