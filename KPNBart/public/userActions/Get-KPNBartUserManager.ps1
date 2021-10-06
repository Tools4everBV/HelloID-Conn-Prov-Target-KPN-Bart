function Get-KPNBartUserManager {
    <#
    .SYNOPSIS
    Get the manager for a KPN Bart user

    .DESCRIPTION
    Get the manager for a KPN Bart user

    .PARAMETER Identity
    The Identity of the user for whom you want to get the manager. This is the Identity in Active Directory

    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $Identity
    )

    try {
    $adAtributeQuery = [KPNBartConnectedServices.QueryService.ADAttributeQuery]::new()
    $adAtributeQuery.ObjectIdentity = $Identity
    $adAtributeQuery.Attribute = 'manager'

    #$returnObject = $script:QueryService.Execute($adAtributeQuery)    
    $script:QueryService.Execute($adAtributeQuery)
        
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
