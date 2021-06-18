function Get-KPNBartCompany {
    <#
    .SYNOPSIS
    Retrieves the KPN Bart company info

    .DESCRIPTION
    Retrieves the KPN Bart company info. This could be either the; locations, divisions or departments

    .PARAMETER Option
    This could be either the; locations, divisions or departments
    #>
    [CmdletBinding()]
    param (
        [ValidateSet('Locations','Divisions','Departments')]
        $Option
    )

    try {
        switch ($Option){
            'Locations'{
                $queryType = [KPNBartConnectedServices.CommandService.LocationQuery]::new()
            }
            'Divisions'{
                $queryType = [KPNBartConnectedServices.CommandService.DivisionQuery]::new()
            }
            'Departments'{
                $queryType = [KPNBartConnectedServices.CommandService.DepartmentQuery]::new()
            }
        }
        $returnObject = $script:QueryService.Execute($queryType)
        Write-Output $returnObject
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}