function Set-KPNBartUserAttributeMultiple {
    <#
    .SYNOPSIS
    Update a KPN Bart user

    .DESCRIPTION
    Update multiple attributes of users in Active Directory

    .PARAMETER CommandList
    The list of user-attribute combinations to update

    #>
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]
        $CommandList
    )
    
    try {
        $returnObject = $Script:BulkCommandService.Execute($Commandlist.ToArray())
        Write-Output $returnObject       
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}