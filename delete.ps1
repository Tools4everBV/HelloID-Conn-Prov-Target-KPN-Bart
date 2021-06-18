$config = ConvertFrom-Json $configuration
$dR = $dryRun |  ConvertFrom-Json  
$p = $person | ConvertFrom-Json;
$aRef = $AccountReference | ConvertFrom-Json
$success = $true
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()

Import-Module $config.ModuleLocation -Force

try{
Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
}
catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

#specify the identity of the object that must be deleted

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

if (-not ($dR -eq $true)) {
    try {
        Remove-KPNBartUser  -Identity $commandObjectIdentity
    }
    catch {
        throw("Remove-KPNBartUser returned error $($_.Exception.Message)")     
    }
}

$auditMessage = "Kpn bart user delete for person " + $p.DisplayName + " succeeded";
$auditLogs.Add([PSCustomObject]@{ 
    action  = "DeleteAccount"
    Message = $auditMessage
    IsError = $false
}) 

$result = [PSCustomObject]@{ 
    Success       = $success;  
    Auditlogs     = $auditLogs ;
    AccountReference =$aRef
}

Write-Output $result | ConvertTo-Json -Depth 10

