function Set-KPNBartUserAttribute {
    <#
    .SYNOPSIS
    Update a KPN Bart user

    .DESCRIPTION
    Update a specific attribute of a user in Active Directory

    .PARAMETER Identity
    The Identity of the user for whom you want to update the attribute(s). This is the Identity in Active Directory

    .PARAMETER Attribute
    The name of the attribute that you want to update

    .PARAMETER Value
    The new value of the attribute that you want to update
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [KPNBartConnectedServices.BulkCommandService.ObjectIdentity]
        $Identity,

        [String]
        $Attribute,
        [String]
        $Value
    )
    try {
        $setUserCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
        $setUserCommand.ObjectIdentity = $Identity
        $setUserCommand.Attribute = $Attribute
        $setUserCommand.Value = $Value

        $returnObject = $Script:BulkCommandService.Execute($setUserCommand)
        Write-Output $returnObject       
    } 
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}