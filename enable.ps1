$aRef = $AccountReference | ConvertFrom-Json
$config = ConvertFrom-Json $configuration
$p = $person | ConvertFrom-Json
$success = $true
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()

try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

#specify the identity of the object that must be updated

$commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
if ( -not [string]::IsNullOrEmpty($aRef.ObjectGuid))
{
    $commandObjectIdentity.IdentityType  = "guid"
    $commandObjectIdentity.Value = $aRef.ObjectGuid
    $commandObjectIdentity.Value -replace '[{}]',''
}
else 
{
    $commandObjectIdentity.IdentityType  = "UserPrincipalName"
    $commandObjectIdentity.Value =$aRef.UserPrincipalName
}

if (-not ($dryRun -eq $true)) {
    try {
        Enable-KPNBartUser  -Identity $commandObjectIdentity
    }
    catch {
        throw("Enable-KPNBartUser returned error $($_.Exception.Message)")     
    }
}

$auditMessage = "Kpn bart user enable for person " + $p.DisplayName + " succeeded"
$auditLogs.Add([PSCustomObject]@{ 
    action  = "EnableAccount"
    Message = $auditMessage
    IsError = $false
}) 

$result = [PSCustomObject]@{ 
    Success       = $success  
    AuditLogs     = $auditLogs   
}

Write-Output $result | ConvertTo-Json -Depth 10

