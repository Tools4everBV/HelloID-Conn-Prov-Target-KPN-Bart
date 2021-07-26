$aRef = $AccountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json
$config = ConvertFrom-Json $configuration
$p = $person | ConvertFrom-Json
$success = $true
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()
$aRef = '56feb63f-1935-4dd0-973b-164c18968dcd'
$dryRun = $false
try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

$account = @{
        GivenName                   = $p.Name.NickName
        SN                          = $p.Custom.KpnBartLastName
        Initials                    = $p.Name.Initials         
        DisplayName                 = $p.Custom.KpnBartDisplayName
        managerObjectGuid           = $mRef                
        Department                  = $p.PrimaryContract.Department.DisplayName
        TelephoneNumber             = $p.contact.Business.phone.mobile         
        OtherMobile                 = $p.contact.Personal.phone.mobile         
        Title                       = $p.PrimaryContract.Title.Name 
        ExtensionAttribute2         = $p.PrimaryContract.CostCenter.ExternalId
}

#specify the identity of the object that must be updated
$queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
$queryObjectIdentity.IdentityType  = "Guid"
$queryObjectIdentity.Value = $aRef

$bulkObjectIdentity = [KPNBartConnectedServices.BulkCommandService.ObjectIdentity]::new()
$bulkObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$bulkObjectIdentity.Value = $queryObjectIdentity.value

$commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
$commandObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$commandObjectIdentity.Value = $queryObjectIdentity.Value

# Set attributes to retrieve
$accountUpdateForAttributes = @()
ForEach ($key in $account.Keys) { $accountUpdateForAttributes += $key }

try {
    [string[]]$ObjectAttributes = @($accountUpdateForAttributes)
    $previousAccount = Get-KPNBartuser -Identity $queryObjectIdentity -Attributes $objectAttributes
    Write-Verbose -Verbose ($previousAccount | ConvertTo-Json)
} catch {
    throw("Get-KPNBartuser failed with error: $($_.Exception.Message)")
}

# Define the accountUpdateAttributes array so it can be processed later on
$accountUpdateAttributes = @()
ForEach ($attribute in $account.GetEnumerator()) {
    if ([string]$attribute.value -ne [string]$previousAccount.$($($attribute.Key))) {
        Write-Verbose -Verbose "Update required for attribute '$($attribute.key)' (Current: '$($previousAccount.$($($attribute.Key)))', new: '$($attribute.value)')"

        # create new updateAttributes object
        $accountUpdateAttributes += $attribute.key
    }
}

$CommandList = [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]::New()
foreach ($keyValue in $accountUpdateAttributes.GetEnumerator())
{
    $modifyCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
    $modifyCommand.ObjectIdentity = $bulkObjectIdentity
    $modifyCommand.Attribute = $keyValue.Key
    $modifyCommand.Value = $keyValue.Value
    $CommandList.add($modifyCommand)
    Write-Verbose -Verbose "Updating attribute '$($keyValue.Key)' to value '$($keyValue.Value)'"
}

if (-not ($dryRun -eq $true)) {
    try {
        Enable-KPNBartUser  -Identity $commandObjectIdentity
        
        $auditMessage = "Kpn bart user enable for person " + $p.DisplayName + " succeeded"
        $auditLogs.Add([PSCustomObject]@{ 
            action  = "EnableAccount"
            Message = $auditMessage
            IsError = $false
        })
        Write-Verbose -Verbose $auditMessage
    } catch {
        throw("Enable-KPNBartUser returned error $($_.Exception.Message)")     
    }
} else {
    Write-Verbose -Verbose "dryRun: Would enable user"
}

if ($accountUpdateAttributes.count -ne 0) {
    if (-not ($dryRun -eq $true)) {
        try {
            $UpdateResults = Set-KPNBartUserAttributeMultiple -CommandList $CommandList

            foreach ($Result in $UpdateResults){
                if(-not $Result.error -eq $false)  {
                    $success = $false   
                    $auditMessage = "user-update for person " + $p.DisplayName + ". Update of specific attribute failed with Error: " + $Result.Message     
                    Write-Verbose -Verbose $auditMessage
                    $auditLogs.Add([PSCustomObject]@{ 
                        action  = "UpdateAccount"
                        Message = $auditMessage
                        IsError = $true
                    })
                }
            }
        } catch {
            throw("Set-KPNBartUserAttributeMultiple returned error $($_.Exception.Message)")     
        } 
    } else {
            Write-Verbose -Verbose "dryRun: Would set attributes"
    }
} else {
    Write-Verbose -Verbose "No attributes to update"
}
# Set Manager 
# TODO: Make manager empty when manager cannot be found. Otherwise an old manager cannot be removed. 
# This only can be done after we went live.
if ( -not [string]::IsNullOrEmpty($mRef))
{
    $managerIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
    $managerIdentity.IdentityType = "Guid"
    $managerIdentity.Value = $mRef

    if (-not ($dryRun -eq $true)) {
        try {
            #Todo: Should add audit message here
            Set-KPNBartUserManager -Identity $commandObjectIdentity -ManagerIdentity $managerIdentity

        } catch {
            throw("Set-KPNBartUserManager returned error $($_.Exception.Message)")  
        }  
    } else {
        Write-Verbose -Verbose "dryRun: Setting manager"
    }
}


$result = [PSCustomObject]@{ 
    Success       = $success
    AuditLogs     = $auditLogs  
}

Write-Output $result | ConvertTo-Json -Depth 10