function Set-KPNBartEmailAliasADAttribute {
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
        [String]
        $Identity,

        [String]
        $EmailAddress
    )

    try {
        $modifyADAttributeCommand = [KPNBartConnectedServices.CommandService.ModifyADAttributeCommand]::new()
        $modifyADAttributeCommand.Attribute = "mail"
        $modifyADAttributeCommand.ObjectIdentity = $Identity
        $modifyADAttributeCommand.EmailAddress = $EmailAddress
        $returnObject = $script:CommandService.Execute($modifyADAttributeCommand)

        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}