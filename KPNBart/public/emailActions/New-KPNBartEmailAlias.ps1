function New-KPNBartEmailAlias {
    <#
    .SYNOPSIS
    Creates a new email address alias

    .DESCRIPTION
    Creates a new email address alias for a user in KPN Bart

    .PARAMETER Identity
    The Identity of the user. This is the Identity in Active Directory

    .PARAMETER EmailAddress
    The EmailAddress you want to add
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [String]
        $EmailAddress
    )

    try {
        $emailAliasCommand = [KPNBartConnectedServices.CommandService.AddEmailAliasCommand]::new()
        $emailAliasCommand.ObjectIdentity = $Identity
        $emailAliasCommand.EmailAddress = $EmailAddress
        $null = $script:CommandService.Execute($emailAliasCommand)
       
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}