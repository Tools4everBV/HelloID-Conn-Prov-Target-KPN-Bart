$config = ConvertFrom-Json $configuration
$dR = $dryRun | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json
$resultSamAccountName = ""

$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::New()

Import-Module $config.ModuleLocation -Force

try {
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
}

[string] $newpassword = "testww_$($p.DisplayName)"
$encryptedPassword = ConvertTo-SecureString $newpassword -Force -AsPlainText
$accountCreateuserModel = @{
    FirstName         = $p.Name.GivenName
    LastName          = $p.Name.FamilyName
    Initials          = $p.Name.Initials
    Password          = $encryptedPassword
    UserPrincipalName = "$($p.Name.FamilyName)$($p.Name.GivenName)@$($config.defaultADDomain)"
    DisplayName       = $p.DisplayName
    MiddleName        = $p.Name.FamilyNamePrefix
    SamAccountName    = $p.UserName
}
$accountUpdateAttributes = @{
    Info       = $p.Description
    EmployeeId = $p.ExternalId
}

$emailAliases = [System.Collections.Generic.List[string]]::New()
$emailAliases.Add($p.Contact.Business.Email)
$emailAliases.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test5.local")
$emailAliases.Add("$($p.Name.FamilyName)$($p.Name.GivenName)@test6.local")


$accountSpecialAttributes = @{
    Mail                                   = $p.Contact.Business.Email
    #UserType = "AD"
    #UserType = "User"S
    IsActive                               = $false
    ChangePasswordAtLogon                  = $true
    UpdateExistingPasswordFlag             = $true
    UpdateExchangeWhenSettingMailAttribute = $false
    EmailAliasesToAdd                      = $emailAliases
    ManagerUserPrincipalName               = $mRef.UserPrincipalName
    Persona                                = "AD User"
}
$Account = $accountCreateuserModel + $accountUpdateAttributes + $accountSpecialAttributes



$queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
$queryObjectIdentity.IdentityType = "UserPrincipalName"
$queryObjectIdentity.Value = $accountCreateUserModel.UserPrincipalName

$bulkObjectIdentity = [KPNBartConnectedServices.BulkCommandService.ObjectIdentity]::new()
$bulkObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$bulkObjectIdentity.Value = $queryObjectIdentity.value

$commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
$commandObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$commandObjectIdentity.Value = $queryObjectIdentity.Value


# check if account for person already exists in bart

try {

    [string[]] $ObjectAttributes = @("UserPrincipalName", "SamAccountName", "ObjectGUID")
    $existingUser = Get-KPNBartuser -Identity $queryObjectIdentity -Attributes $objectAttributes
    $resultObjectGUID = $existingUser.ObjectGUID
    $resultSamAccountName = $existingUser.SamAccountName
    $accountAlreadyExists = $true

} catch {
    $accountAlreadyExists = $false
}

#create bare user account in bart when it does not yet exist

$success = $true


if ($accountAlreadyExists -eq $false) {
    if (-not ($dR -eq $true)) {
        try {
            $CreateResult = New-KPNBartUser @accountCreateuserModel
            if ($CreateResult.Error -eq $true) {
                $auditMessage = "Kpn bart user create for person " + $p.DisplayName + " failed"
                $auditLogs.Add([PSCustomObject]@{
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $true
                    })
                throw($auditMessage)

            }
            [string[]] $ObjectAttributes = @("UserPrincipalName", "SamAccountName", "ObjectGUID")
            $createdUser = Get-KPNBartuser -Identity $queryObjectIdentity -Attributes $objectAttributes
            if (-not ($null -eq $createdUser)) {
                $resultObjectGUID = $createdUser.ObjectGUID
                $resultSamAccountName = $createdUser.SamAccountName
                $auditMessage = "Kpn bart user create for person " + $p.DisplayName + " succeeded"
                $auditLogs.Add([PSCustomObject]@{
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $false
                    })

            }

        } catch {
            throw("Could not create New-KPNBartUser, $($_.Exception.Message)")
        }
    }
}


$CommandList = [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]::New()
foreach ($keyValue in $accountUpdateAttributes.GetEnumerator()) {
    $modifyCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
    $modifyCommand.ObjectIdentity = $bulkObjectIdentity
    $modifyCommand.Attribute = $keyValue.Key
    $modifyCommand.Value = $keyValue.Value
    $CommandList.add($modifyCommand)
}

if (-not ($dR -eq $true)) {
    try {
        $UpdateResults = Set-KPNBartUserAttributeMultiple -CommandList $CommandList

        foreach ($Result in $UpdateResults) {
            if ( -not $Result.error -eq $false) {
                $success = $false
                $auditMessage = "user-create for person " + $p.DisplayName + ". Update after initial create failed with Error: " + $Result.Message
                $auditLogs.Add([PSCustomObject]@{
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $true
                    })
            }
        }
    }

    catch {
        throw("Could not set account attributes of new account. Set-KPNBartUserAttributeMultiple returned error $($_.Exception.Message)")
    }
}

# Convert user to the correct user type
if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.UserType)) {
    if (-not ($dR -eq $true)) {
        try {
            Set-KPNBartUserType  -Identity $commandObjectIdentity -userType $accountSpecialAttributes.UserType
        } catch {
            throw("Set-KPNBartUserType returned error $($_.Exception.Message)")
        }
    }
}

# disable the initial user
if ($accountSpecialAttributes.IsActive -eq $false) {
    if (-not ($dR -eq $true)) {
        try {
            Disable-KPNBartUser  -Identity $commandObjectIdentity
        } catch {
            throw("Disable-KPNBartUser returned error $($_.Exception.Message)")
        }
    }
}
# update the password
if ($accountAlreadyExists) {

    if (-not ($dR -eq $true)) {

        if ($updateExistingPasswordFlag -eq $true) {
            try {
                Set-KPNBartUserPassword -Identity $commandObjectIdentity  -Password $encryptedPassword
            } catch {
                throw("Set-KPNBartUserPassword returned error $($_.Exception.Message)")
            }
        }
    }
}

# Force user to change password at the next logon
if (-not ($dR -eq $true)) {

    if ($accountSpecialAttributes.ChangePasswordAtLogon -eq $true) {

        try {
            Set-KPNBartPasswordchangeAtNextLogon -Identity $commandObjectIdentity
        } catch {
            throw("Set-KPNBartPasswordchangeAtNextLogon returned error $($_.Exception.Message)")
        }
    }
}


# Set aliases before setting primary
if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true) {
    foreach ($emailAlias in $accountSpecialAttributes.EmailAliasesToAdd) {
        if (-not ($dR -eq $true)) {
            try {
                New-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $emailAlias
            } catch {
                throw("New-KPNBartEmailAlias returned error $($_.Exception.Message)")
            }
        }
    }
}

# Set mail
if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.Mail)) {
    if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true) {
        if (-not ($dR -eq $true)) {
            try {
                Set-KPNBartEmailPrimaryAddress -Identity $commandObjectIdentity -EmailAddress $accountSpecialAttributes.Mail
            } catch {
                throw("Set-KPNBartEmailPrimaryAddress returned error $($_.Exception.Message)")
            }
        }

    } else {
        if (-not ($dR -eq $true)) {
            try {
                Set-KPNBartEmailADAttribute -Identity $commandObjectIdentity -EmailAddress $accountSpecialAttributes.Mail
            } catch {
                throw("Set-KPNBartEmailPrimaryAddress returned error $($_.Exception.Message)")
            }
        }

    }
}
# Set Manager
if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.ManagerUserPrincipalName)) {
    $managerIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
    $managerIdentity.IdentityType = "UserPrincipalName"
    $managerIdentity.Value = $accountSpecialAttributes.ManagerUserPrincipalName

    if (-not ($dR -eq $true)) {
        try {
            Set-KPNBartUserManager -Identity $commandObjectIdentity -ManagerIdentity $managerIdentity
        } catch {
            throw("Set-KPNBartUserManager returned error $($_.Exception.Message)")
        }
    }
}

# Set persona

if (-not [string]::IsNullOrEmpty($accountSpecialAttributes.Persona)) {
    if (-not ($dR -eq $true)) {
        try {
            Set-KPNBartUserPersona -Identity $commandObjectIdentity -Persona $accountSpecialAttributes.Persona
        } catch {
            throw("Set-KPNBartUserPersona returned error $($_.Exception.Message)")
        }
    }
}


if ($success -eq $true) {
    $auditMessage = "create Account for person " + $p.DisplayName + " succeeded"
    $auditLogs.Add([PSCustomObject]@{
            action  = "CreateAccount"
            Message = $auditMessage
            IsError = $false
        })

}

$result = [PSCustomObject]@{
    Success          = $success
    AccountReference = @{ 
        UserPrincipalName   = $accountCreateUserModel.UserPrincipalName
        ObjectGuid          = $resultObjectGUID
        SamAccountName      = $resultSamAccountName
    }
    Auditlogs        = $auditLogs
    Account          = $account
}

#send result back
Write-Output $result | ConvertTo-Json -Depth 10
