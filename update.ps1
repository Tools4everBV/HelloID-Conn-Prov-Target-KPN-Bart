$aRef = $AccountReference | ConvertFrom-Json
$config = ConvertFrom-Json $configuration
$mRef = $managerAccountReference | ConvertFrom-Json 
$p = $person | ConvertFrom-Json

$success = $true
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()

Import-Module $config.ModuleLocation -Force

try{
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
    }
catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

#specify the identity of the object that must be updated

$queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
if ( -not [string]::IsNullOrEmpty($aRef.ObjectGuid))
{
    $queryObjectIdentity.IdentityType  = "guid"
    $queryObjectIdentity.Value = $aRef.ObjectGuid
    $queryObjectIdentity.Value -replace '[{}]',''
}
else 
{
    $queryObjectIdentity.IdentityType  = "UserPrincipalName"
    $queryObjectIdentity.Value =$aRef.UserPrincipalName
}

$bulkObjectIdentity = [KPNBartConnectedServices.BulkCommandService.ObjectIdentity]::new()
$bulkObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$bulkObjectIdentity.Value = $queryObjectIdentity.value

$commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
$commandObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$commandObjectIdentity.Value = $queryObjectIdentity.Value


[string] $newpassword = "testww_$($p.DisplayName)"
$encryptedPassword = ConvertTo-SecureString $newpassword -Force -AsPlainText

#specification of direct Ad attributes to update

$accountUpdateAttributes = @{ 
GivenName           = $p.Name.GivenName
SN                  = $p.Name.FamilyName   
Initials            = $p.Name.Initials
#UserPrincipalName  = "$($p.Name.FamilyName)$($p.Name.GivenName)@lievegoed.nl"
DisplayName         = $p.DisplayName   
MiddleName          = $p.Name.FamilyNamePrefix 
#SamAccountName     = "$($p.Name.FamilyName)$($p.Name.GivenName)"
Info                = $p.Description
}

#specification of attributes to update that require special actions

$emailAliases =[System.Collections.Generic.List[string]]::New()
$emailAliases.Add($p.Contact.Business.Email)
$emailAliases.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test7.local")
$emailAliases.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test8.local")

$emailAliasesToRemove = [System.Collections.Generic.List[string]]::New()
$emailAliasesToRemove.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test5.local")

$accountSpecialAttributes = @{
    Mail                                    = $p.Contact.Business.Email
    Password                                = $encryptedPassword  
    #UserType                               = "AD"       
    #UserType                               = "User"
    IsActive                                = $false 
    ChangePasswordAtLogon                   = $true
    UpdateExistingPasswordFlag              = $true
    UpdateExchangeWhenSettingMailAttribute  = $true
    EmailAliasesToAdd                       = $emailAliases
    EmailAliasesToRemove                    = $emailAliasesToRemove
    ManagerUserPrincipalName                = $mRef.UserPrincipalName
    Persona                                 = "AD User"
}
$Account = $accountUpdateAttributes + $accountSpecialAttributes

$CommandList = [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]::New()

foreach ($keyValue in $accountUpdateAttributes.GetEnumerator())
{
    $modifyCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
    $modifyCommand.ObjectIdentity = $bulkObjectIdentity
    $modifyCommand.Attribute = $keyValue.Key
    $modifyCommand.Value = $keyValue.Value
    $CommandList.add($modifyCommand)    
}
if (-not ($dryRun -eq $true)) 
{
    try {
        $UpdateResults = Set-KPNBartUserAttributeMultiple -CommandList $CommandList

        foreach ($Result in $UpdateResults){
            if(-not $Result.error -eq $false)  {
                $success = $false   
                $auditMessage = "user-update for person " + $p.DisplayName + ". Update of specific attribute failed with Error: " + $Result.Message     
                $auditLogs.Add([PSCustomObject]@{ 
                    action  = "UpdateAccount"
                    Message = $auditMessage
                    IsError = $true
                })            
            }
        }
    }
   catch {
    throw("Set-KPNBartUserAttributeMultiple returned error $($_.Exception.Message)")     
   } 
}

# update the password 
if (-not ($dryRun -eq $true)) {

    if ($accountSpecialAttributes.updateExistingPasswordFlag -eq $true){
        try{
            Set-KPNBartUserPassword -Identity $commandObjectIdentity  -Password $encryptedPassword
        }
        catch {
            throw("Set-KPNBartUserPassword returned error $($_.Exception.Message)")     
        }  
    }             
}

# Force user to change password at the next logon
if (-not ($dryRun -eq $true)) {

    if($accountSpecialAttributes.ChangePasswordAtLogon -eq $true) {

        try{
            Set-KPNBartPasswordchangeAtNextLogon -Identity $commandObjectIdentity              
        }
        catch {
            throw("Set-KPNBartPasswordchangeAtNextLogon returned error $($_.Exception.Message)")     
        }  
    }
}


# Set aliases before setting primary 
if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true)
{ 
    foreach ($emailAlias in $accountSpecialAttributes.EmailAliasesToAdd)
    {
        if (-not ($dryRun -eq $true)) {
            try{
                New-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $emailAlias              
            }
            catch {
                throw("New-KPNBartEmailAlias returned error $($_.Exception.Message)")    
            }  
        }
   }
}    

# Set mail
if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.Mail))
{
    if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true)
    {
        if (-not ($dryRun -eq $true)) {
            try{
                Set-KPNBartEmailPrimaryAddress -Identity $commandObjectIdentity -EmailAddress $accountSpecialAttributes.Mail            
            }
            catch {
                throw("Set-KPNBartEmailPrimaryAddress returned error $($_.Exception.Message)")    
            }  
        }

    }
    else
    {
        if (-not ($dryRun -eq $true)) {
            try{
                Set-KPNBartEmailADAttribute -Identity $commandObjectIdentity -EmailAddress $accountSpecialAttributes.Mail            
            }
            catch {
                throw("Set-KPNBartEmailADAttribute returned error $($_.Exception.Message)")   
            }  
        }        
    }
}

# remove aliases after setting primary 
if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true)
{ 
    foreach ($emailAlias in $accountSpecialAttributes.EmailAliasesToRemove)
    {
        if (-not ($dryRun -eq $true)) {
            try{
                Remove-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $emailAlias              
            }
            catch {
                throw("Remove-KPNBartEmailAlias returned error $($_.Exception.Message)")  
            }  
        }
   }
}  

# Set Manager
if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.ManagerUserPrincipalName))
{
    $managerIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
    $managerIdentity.IdentityType = "UserPrincipalName"
    $managerIdentity.Value = $accountSpecialAttributes.ManagerUserPrincipalName

    if (-not ($dryRun -eq $true)) {
        try{
            Set-KPNBartUserManager -Identity $commandObjectIdentity -ManagerIdentity $managerIdentity           
        }
        catch {
            throw("Set-KPNBartUserManager returned error $($_.Exception.Message)")  
        }  
    }
}

# Set persona

if (-not [string]::IsNullOrEmpty($accountSpecialAttributes.Persona))
{
    if (-not ($dryRun -eq $true)) {
        try{
            Set-KPNBartUserPersona -Identity $commandObjectIdentity -Persona $accountSpecialAttributes.Persona          
        }
        catch {
            throw("Set-KPNBartUserPersona returned error $($_.Exception.Message)")  
        }  
    }
}

if ($success -eq $true) {
    $auditMessage = "user-update for person " + $p.DisplayName + " succeeded"
    $auditLogs.Add([PSCustomObject]@{
            action  = "UpdateAccount"
            Message = $auditMessage
            IsError = $false
        })
    }


$result = [PSCustomObject]@{ 
    Success       = $success  
    AuditLogs     = $auditLogs
    Account       = $account 
}

#send result back
Write-Output $result | ConvertTo-Json -Depth 10
