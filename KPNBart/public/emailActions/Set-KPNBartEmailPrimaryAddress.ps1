function Set-KPNBartEmailPrimaryAddress {
    <#
    .SYNOPSIS
    Sets an email adddress to primary

    .DESCRIPTION
    Set an email address to the primary address for a user in KPN Bart

    .PARAMETER Identity
    The Identity of the user. This is the Identity in Active Directory

    .PARAMETER EmailAddress
    The EmailAddress you want to make the primary address
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [String]
        $EmailAddress
    )

    try {
        $primaryEmailCommand = [KPNBartConnectedServices.CommandService.PrimaryEmailCommand]::new()
        $primaryEmailCommand.ObjectIdentity = $Identity
        $primaryEmailCommand.EmailAddress = $EmailAddress
        $null = $script:CommandService.Execute($primaryEmailCommand)
                
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}