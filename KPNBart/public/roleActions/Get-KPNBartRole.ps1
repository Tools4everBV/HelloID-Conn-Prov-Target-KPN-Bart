function Get-KPNBartRole {
    <#
    .SYNOPSIS
    Retrieves all roles from KPN Bart

    .DESCRIPTION
    Retrieves all roles from KPN Bart
    #>
    [CmdletBinding()]
    param (
    )

    try {
        $roleQuery = [KPNBartConnectedServices.QueryService.BartRolesQuery]::new()

        $returnObject = $script:QueryService.Execute($roleQuery)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}