function Set-KPNBartEmailADAttribute {
    <#
    .SYNOPSIS
    Set or updates an email address alias ADattribute

    .DESCRIPTION
    Set or updates an email address alias ADattribute for a user in Active Directory

    .PARAMETER Identity
    The Identity of the user. This is the Identity in Active Directory

    .PARAMETER EmailAddress
    The EmailAddress that will be added
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.CommandService.ObjectIdentity]
        $Identity,

        [String]
        $EmailAddress
    )

    try {
        $modifyADAttributeCommand = [KPNBartConnectedServices.CommandService.ModifyADAttributeCommand]::new()
        $modifyADAttributeCommand.Attribute = "mail"
        $modifyADAttributeCommand.ObjectIdentity = $Identity
        $modifyADAttributeCommand.Value = $EmailAddress
        $null = $script:CommandService.Execute($modifyADAttributeCommand)      
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}