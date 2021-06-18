function Get-KPNBartUserIsActive {
    <#
    .SYNOPSIS
    Retrieves wether or not a user is activated

    .DESCRIPTION
    Retrieves wether or not a user is activated

    .PARAMETER Identity
    The Identity of the user for whom you want to retrieve de active status   
    #>
    [CmdletBinding()]
    param (
        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $Identity       
    )
    try {
        $userActiveQuery = [KPNBartConnectedServices.QueryService.IsUserActiveQuery]::new()
        $userActiveQuery.UserIdentity = $Identity    
        $returnObject = $script:QueryService.Execute($userActiveQuery)
        Write-Output $returnObject
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}