$config = ConvertFrom-Json $configuration
$aRef = $AccountReference | ConvertFrom-Json
$pRef = $permissionReference | ConvertFrom-Json
$auditLogs = New-Object Collections.Generic.List[PSCustomObject]
$success = $false

Import-Module $config.ModuleLocation -Force
Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url

$userIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
if (![string]::IsNullOrEmpty($aRef.ObjectGuid)) {
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
        Set-KPNBartResourceAccess -ResourceAuthorization $ResourceAuthorization -Identity $userIdentity -Add $false -ResourceIdentity $resourceIdentity
        $auditLogs.Add([PSCustomObject]@{
                Action = "RevokeMembership"
                Message = "Permission $($pRef.Reference) removed from account $($aRef.UserPrincipalName)"
                IsError = $false
            }
        )
        $Success = $true
    } catch {
        $auditLogs.Add([PSCustomObject]@{
                Action = "RevokeMembership"
                Message = "Failed to remove permission $($pRef.Reference) from account $($aRef.UserPrincipalName)  Message: $($_.Exception.Message)"
                IsError = $true
            }
        )
    }
}

# Send results
$result = [PSCustomObject]@{
    Success   = $success
    AuditLogs = $auditLogs
    Account   = [PSCustomObject]@{ }
}

Write-Output $result | ConvertTo-Json -Depth 10






