function Get-KPNBartEmailAlias {
    <#
    .SYNOPSIS
    Retrieves the email address aliases

    .DESCRIPTION
    Retrieves a list of email address aliases for the specified user

    .PARAMETER Identity
    The Identity of the user. This is the Identity in Active Directory
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $Identity
    )

    try {
        $emailAliasQuery = [KPNBartConnectedServices.QueryService.EmailAliasQuery]::new()
        $emailAliasQuery.ObjectIdentity = $Identity
        $returnObject = $script:QueryService.Execute($emailAliasQuery)

        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}