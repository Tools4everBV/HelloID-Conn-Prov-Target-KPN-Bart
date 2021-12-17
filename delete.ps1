$config = ConvertFrom-Json $configuration
$p = $person | ConvertFrom-Json
$aRef = $AccountReference | ConvertFrom-Json
$success = $false
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()

try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

#specify the identity of the object that must be deleted
if ( -not [string]::IsNullOrEmpty($aRef)) {
    $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
    $queryObjectIdentity.IdentityType  = "Guid"
    $queryObjectIdentity.Value = $aRef

    
    # test with isactive
    try {
        [string[]]$ObjectAttributes = @("Guid","DistinguishedName")
        $previousAccount = Get-KPNBartUserIsActive -Identity $queryObjectIdentity
        $exists = $true
    } catch {
        if ($_.Exception.message -like ' does not exist') 
        { 
            # error message when user doesn't exist:
            # 2021-09-01 13:05:05,209 [85] [20640206-0968-4972-a3be-a90fd4023011] INFO  HelloID.Provisioning.Agent.PowershellSessionManagement.PowershellSession - [eed83db6-460b-4043-acd4-73f2fbd79cc0] Get-KPNBartUserIsActive failed with error: Exception calling "Execute" with "1" argument(s): "the specified searchRoot '<GUID=29000d0e-fb45-442a-a831-05c6afc1203c>' does not exist"
            $auditMessage = "Account doesn't exist anymore. Deleting account data from database"
            write-verbose -verbose $auditMessage
            $auditLogs.Add([PSCustomObject]@{ 
                    action  = "DeleteAccount"
                    Message = $auditMessage
                    IsError = $false
                }) 
            $exists = $false
            $success = $true
        } else {
            $auditMessage = "Get-KPNBartUserIsActive failed with error: $($_.Exception.Message)"
            write-verbose -verbose $auditMessage
            $auditLogs.Add([PSCustomObject]@{ 
                    action  = "DeleteAccount"
                    Message = $auditMessage
                    IsError = $true
                }) 
        }
    }

    if ($exists -eq $true) {
        if (-not ($dryRun -eq $true)) {
            try {
                $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
                $commandObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
                $commandObjectIdentity.Value = $queryObjectIdentity.Value
                Remove-KPNBartUser -Identity $commandObjectIdentity

                $auditMessage = "Kpn bart user delete for person " + $p.DisplayName + " succeeded"
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
        $auditMessage = "Account with reference '$aRef' cannot be found. Cannot delete account in KPN Bart, but removing the account from the HelloID database."
        $auditLogs.Add([PSCustomObject]@{ 
            action  = "DeleteAccount"
            Message = $auditMessage
            IsError = $false
        }) 
        $success = $true
    }
} else {
    $auditMessage = "aRef is empty, cannot delete account in KPN Bart, but removing the account from the HelloID database."
    Write-Verbose -Verbose $auditMessage
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
}

Write-Output $result | ConvertTo-Json -Depth 10
