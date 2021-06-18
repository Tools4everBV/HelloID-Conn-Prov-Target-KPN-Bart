function Get-KPNBartUserADAttribute {
    <#
    .SYNOPSIS
    Retrieves a specific attribute for a user

    .DESCRIPTION
    Retrieves a specific attribute for a user from Active Directory

    .PARAMETER Identity
    The Identity of the user for whom you want to retrieve the attributes. This is the Identity in Active Directory

    .PARAMETER Attribute
    The attribute you want to return
    #>
    [CmdletBinding()]
    param (
        [String]
        $Identity,

        [String]
        $Attribute
    )

    try {
    $adAtributeQuery = [KPNBartConnectedServices.QueryService.ADAttributeQuery]::new()
    $adAtributeQuery.ObjectIdentity = $Identity
    $adAtributeQuery.Attribute = $Attribute

    $returnObject = $script:QueryService.Execute($adAtributeQuery)
    Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}