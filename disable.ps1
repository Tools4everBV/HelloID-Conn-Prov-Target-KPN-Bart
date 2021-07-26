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

#specify the identity of the object that must be disabled

$commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
if ( -not [string]::IsNullOrEmpty($aRef.ObjectGuid))
{
    $commandObjectIdentity.IdentityType  = "guid"
    $commandObjectIdentity.Value = $aRef
    $commandObjectIdentity.Value -replace '[{}]',''
}
else 
{
   # aRef not available....
}

if (-not ($dryRun -eq $true)) {
    try {
        Disable-KPNBartUser  -Identity $commandObjectIdentity
    }
    catch {
        throw("Disable-KPNBartUser returned error $($_.Exception.Message)")     
    }
}

$auditMessage = "Kpn bart user disable for person " + $p.DisplayName + " succeeded"
$auditLogs.Add([PSCustomObject]@{ 
    action  = "DisableAccount"
    Message = $auditMessage
    IsError = $false
})

$result = [PSCustomObject]@{ 
    Success       = $success
    Auditlogs     = $auditLogs
}
Write-Output $result | ConvertTo-Json -Depth 10


