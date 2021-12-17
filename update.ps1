$p = $person | ConvertFrom-Json
$aRef = $AccountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json
$config = $configuration | ConvertFrom-Json
$success = $true
$auditLogs =[System.Collections.Generic.List[PSCustomObject]]::New()


try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}
Write-verbose -verbose -message 2
$account = @{
        #GivenName                   = $p.Name.NickName
        #SN                          = $p.Custom.KpnBartLastName
        #Initials                    = $p.Name.Initials
        #DisplayName                 = $p.Custom.KpnBartDisplayName
        managerObjectGuid           = $mRef
        Department                  = $p.PrimaryContract.Department.DisplayName
        TelephoneNumber             = $p.contact.Business.phone.mobile
        OtherMobile                 = $p.contact.Personal.phone.mobile
        Title                       = $p.PrimaryContract.Title.Name 
        ExtensionAttribute2         = $p.PrimaryContract.CostCenter.ExternalId
}
Write-verbose -verbose -message 3
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
    #Write-Verbose -Verbose ($previousAccount | ConvertTo-Json)
} catch {
    $auditMessage = "Get-KPNBartuser failed with error: $($_.Exception.Message)"
    Write-Verbose -Verbose -Message $auditMessage
    throw($auditMessage)
}

$accountUpdateAttributes = @()
ForEach ($attribute in $account.GetEnumerator()) {
    if ([string]$attribute.value -ne [string]$previousAccount.$($($attribute.Key)) -and $attribute.key -ne 'managerObjectGuid') {
        
        Write-Verbose -Verbose "Update required for attribute '$($attribute.key)' (Current: '$($previousAccount.$($($attribute.Key)))', new: '$($attribute.value)')"

        # create new updateAttributes object
        $accountUpdateAttributes += $attribute.key
    }
}
Write-verbose -verbose -message 4
try {
    $previousAccountManager = Get-KPNBartUserManager -Identity $queryObjectIdentity 
    #write-verbose -verbose ($previousAccountManager | ConvertTo-Json)
} catch {
    throw("Get-KPNBartUserManager failed with error: $($_.Exception.Message)")
}
Write-verbose -verbose -message 5
$accountUpdate = @{}    
ForEach ($key in $account.Keys) {
    if ($accountUpdateAttributes.contains($key)) {
        $accountUpdate.Add($key,$account[$key])
    }
}

$CommandList = [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]::New()
foreach ($keyValue in $accountUpdate.GetEnumerator())
{
    $modifyCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
    $modifyCommand.ObjectIdentity = $bulkObjectIdentity
    $modifyCommand.Attribute = $keyValue.Key
    $modifyCommand.Value = $keyValue.Value
    $CommandList.add($modifyCommand)
    Write-Verbose -Verbose "Updating attribute '$($keyValue.Key)' to value '$($keyValue.Value)'"
}

if (-not ($dryRun -eq $true)) 
{
    try {
		if ($CommandList.count -ne 0) {
			$UpdateResults = Set-KPNBartUserAttributeMultiple -CommandList $CommandList

			foreach ($Result in $UpdateResults){
				if(-not $Result.error -eq $false)  {
				    $success = $false   
                    $auditMessage = "user-create for person  $($p.DisplayName). Update of specific attribute failed with Error:  '$($Result.command.attribute)' to value '$($Result.command.value)'. Error: $($Result.Message)"
					Write-Verbose -Verbose $auditMessage										
					$auditLogs.Add([PSCustomObject]@{ 
						action  = "UpdateAccount"
						Message = $auditMessage
						IsError = $true
					})
				}
			}
		}
    } catch {
        $auditMessage = "Set-KPNBartUserAttributeMultiple returned error $($_.Exception.Message)"
        Write-Verbose -Verbose -Message $auditMessage
        throw($auditMessage)
   } 
}

# Not used in this implementation
# # Set aliases before setting primary 
# might add this part to the account attribute
# $emailAliases =[System.Collections.Generic.List[string]]::New()
# $emailAliases.Add($p.Contact.Business.Email)
# $emailAliases.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test7.local")
# $emailAliases.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test8.local")

# $emailAliasesToRemove = [System.Collections.Generic.List[string]]::New()
# $emailAliasesToRemove.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test5.local")

# if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true)
# { 
#     foreach ($emailAlias in $accountSpecialAttributes.EmailAliasesToAdd)
#     {
#         if (-not ($dryRun -eq $true)) {
#             try{
#                 New-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $emailAlias              
#             }
#             catch {
#                 throw("New-KPNBartEmailAlias returned error $($_.Exception.Message)")    
#             }  
#         }
#    }
# }    

# Not used in this implementation
# # Set mail
# if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.Mail))
# {
#     if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true)
#     {
#         if (-not ($dryRun -eq $true)) {
#             try{
#                 Set-KPNBartEmailPrimaryAddress -Identity $commandObjectIdentity -EmailAddress $accountSpecialAttributes.Mail            
#             }
#             catch {
#                 throw("Set-KPNBartEmailPrimaryAddress returned error $($_.Exception.Message)")    
#             }  
#         }

#     }
#     else
#     {
#         if (-not ($dryRun -eq $true)) {
#             try{
#                 Set-KPNBartEmailADAttribute -Identity $commandObjectIdentity -EmailAddress $accountSpecialAttributes.Mail            
#             }
#             catch {
#                 throw("Set-KPNBartEmailADAttribute returned error $($_.Exception.Message)")   
#             }  
#         }        
#     }
# }

# Not used in this implementation
# # remove aliases after setting primary 
# if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true)
# { 
#     foreach ($emailAlias in $accountSpecialAttributes.EmailAliasesToRemove)
#     {
#         if (-not ($dryRun -eq $true)) {
#             try{
#                 Remove-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $emailAlias              
#             }
#             catch {
#                 throw("Remove-KPNBartEmailAlias returned error $($_.Exception.Message)")  
#             }  
#         }
#    }
# }  
Write-verbose -verbose -message 7
# Set Manager
if ( -not [string]::IsNullOrEmpty($mRef)) {
    Write-verbose -verbose -message "8.1"
    write-verbose -verbose ($previousAccountManager| ConvertTo-Json)
    if ($previousAccountManager.ObjectGuid -ne $mRef) {
        $managerIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
        $managerIdentity.IdentityType = "Guid"
        $managerIdentity.Value = $mRef

        if (-not ($dryRun -eq $true)) {
            try {
                Set-KPNBartUserManager -Identity $commandObjectIdentity -ManagerIdentity $managerIdentity
                $auditMessage = "user-update for person " + $p.DisplayName + ". Manager update succesful."     
                Write-Verbose -Verbose $auditMessage
                $auditLogs.Add([PSCustomObject]@{ 
                    action  = "UpdateAccount"
                    Message = $auditMessage
                    IsError = $false
                })
            } catch {
                $success = $false
                $auditMessage = "user-create for person " + $p.DisplayName + ". Update of manager failed with Error: $($_.Exception.Message)".
                $auditLogs.Add([PSCustomObject]@{ 
                    action  = "UpdateAccount"
                    Message = $auditMessage
                    IsError = $true
                })
                $auditMessage = "Set-KPNBartUserManager returned error $($_.Exception.Message)"
                Write-Verbose -Verbose -Message $auditMessage
                throw($auditMessage)
            }
        } else {
            Write-Verbose -Verbose -Message "dryRun: Setting manager"
        }
    } else {
        Write-Verbose -Verbose -Message "Manager already configured correctly. Update not required."
    }
} else {
    #$success = $false
    $auditMessage = "user-update for person " + $p.DisplayName + ". Update of manager failed with Error: Manager is empty"
    Write-Verbose -Verbose -Message $auditMessage
    $auditLogs.Add([PSCustomObject]@{ 
        action  = "UpdateAccount"
        Message = $auditMessage
        IsError = $true
    })
}
#Not used in this implementation, persona is set once.
# # Set persona
# if (-not [string]::IsNullOrEmpty($accountSpecialAttributes.Persona))
# {
#     if (-not ($dryRun -eq $true)) {
#         try{
#             Set-KPNBartUserPersona -Identity $commandObjectIdentity -Persona $accountSpecialAttributes.Persona          
#         }
#         catch {
#             throw("Set-KPNBartUserPersona returned error $($_.Exception.Message)")  
#         }  
#     }
# }

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