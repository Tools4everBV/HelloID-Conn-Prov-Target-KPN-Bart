$config = ConvertFrom-Json $configuration

try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

try {
    $resultGroupList = Get-KPNBartResource -ResourceType Group
    $groups = $resultGroupList.ResourceModel
} catch {
    throw "Could not get KPN BArt Resource Group, :$($_.Exception.Message)"
}

$permissions = $groups | Select-Object   @{Name = 'DisplayName';    Expression = { "Group_$($_.DisplayName)" } } ,
                                         @{Name = 'Identification'; Expression = { @{ Reference = $_.ObjectGuid } } }

Write-Output  ($permissions | ConvertTo-Json -Depth 10 )
