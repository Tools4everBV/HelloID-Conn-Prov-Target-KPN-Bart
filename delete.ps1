$config = ConvertFrom-Json $configuration
$p = $person | ConvertFrom-Json
write-verbose -verbose $person
$aRef = $AccountReference | ConvertFrom-Json
$success = $false
write-verbose -verbose 1
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()

$dryRun = $false
try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}
write-verbose -verbose 2
#specify the identity of the object that must be deleted
$commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
if ( -not [string]::IsNullOrEmpty($aRef)) {
    $commandObjectIdentity.IdentityType  = "Guid"
    $commandObjectIdentity.Value = $aRef
    #$commandObjectIdentity.Value -replace '[{}]',''
    write-verbose -verbose 3
    if (-not ($dryRun -eq $true)) {
        try {
            Remove-KPNBartUser  -Identity $commandObjectIdentity
            $auditMessage = "Kpn bart user delete for person " + $p.DisplayName + " succeeded";
            $auditLogs.Add([PSCustomObject]@{ 
                action  = "DeleteAccount"
                Message = $auditMessage
                IsError = $false
            }) 
            $success = $true

        } catch {
            throw("Remove-KPNBartUser returned error $($_.Exception.Message)")
        }
    } else {
        Write-Verbose -Verbose "Not processing delete as dryRun is True"
    }  
} else {
    $auditMessage = "aRef is empty, cannot delete account in KPN Bart, but removing the account from our database."
    $auditLogs.Add([PSCustomObject]@{ 
        action  = "DeleteAccount"
        Message = $auditMessage
        IsError = $false
    }) 
    $success = $true
}

$result = [PSCustomObject]@{ 
    Success             = $success
    Auditlogs           = $auditLogs
    AccountReference    = $aRef
}

Write-Output $result | ConvertTo-Json -Depth 10

