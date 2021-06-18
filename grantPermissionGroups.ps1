$config = ConvertFrom-Json $configuration
$aRef = $AccountReference | ConvertFrom-Json
$pRef = $permissionReference | ConvertFrom-Json;
$auditLogs = New-Object Collections.Generic.List[PSCustomObject];
$success = $false

Import-Module $config.ModuleLocation -Force
Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url

$userIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
if (![string]::IsNullOrEmpty($aRef.objectGuid)) {
    $userIdentity.IdentityType = "guid"
    $userIdentity.Value = $aRef.ObjectGuid
} else {
    $userIdentity.IdentityType = "UserPrincipalName"
    $userIdentity.Value = $aRef.UserPrincipalName
}

$resourceIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
$resourceIdentity.IdentityType = "guid"
$resourceIdentity.Value = "$($pref.reference)"

$ResourceAuthorization = [KPNBartConnectedServices.CommandService.ResourceAuthorizationEnum]::Access

if (-Not($dryRun -eq $true)) {
    try {
        Set-KPNBartResourceAccess -ResourceAuthorization $ResourceAuthorization -Identity $userIdentity -Add $true -ResourceIdentity $resourceIdentity
        $auditLogs.Add([PSCustomObject]@{
                action  = "GrantMembership" 
                Message = "Permission $($pRef.Reference) added to account $($aRef.UserPrincipalName)";
                IsError = $false
            }
        );
        $Success = $true
    } catch {
        $auditLogs.Add([PSCustomObject]@{
                action  = "GrantMembership"  
                Message = "Failed to add permission $($pRef.Reference) to account $($aRef.UserPrincipalName) Message: $($_.Exception.Message))"
                IsError = $true
            }
        );
    }
}

# Send results
$result = [PSCustomObject]@{
    Success   = $success
    AuditLogs = $auditLogs
    Account   = [PSCustomObject]@{ }
};

Write-Output $result | ConvertTo-Json -Depth 10