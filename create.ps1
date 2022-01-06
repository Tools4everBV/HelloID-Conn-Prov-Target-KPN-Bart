$config = ConvertFrom-Json $configuration
$p = $person | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::New()
$success = $true

#samaccountname generation
# 1. <First Name (initial)><Last name prefix><Last Name>(e.g jwilliams)
# 2. <First Name>.<last name prefix><Last Name> (e.g john.williams2)
# 3. <First Name (initial)><Last name prefix><Last Name><iterator> (e.g jwilliams4)
function New-SamAccountName {
    [cmdletbinding()]
    Param (
        [object]$person,
        [int]$Iteration
    )
    Process {
        try {
            $suffix = "";
            if ([string]::IsNullOrEmpty($p.Name.Nickname)) { $tempFirstName = $p.Name.GivenName } else { $tempFirstName = $p.Name.Nickname }
            $tempFirstName = $tempFirstName -Replace ' ',''

            switch ($Iteration) {
                0 {
                    $tempFirstName = $tempFirstName.substring(0,1)
                    Break 
                }
                1 {
                    $tempFirstName = $tempFirstName
                    Break 
                }
                default {
                    $tempFirstName = $tempFirstName.substring(0,1)
                    $suffix = "$($Iteration+1)"
                }
            }

            if([string]::IsNullOrEmpty($p.Name.FamilyNamePrefix)) { $tempLastNamePrefix = "" } else { $tempLastNamePrefix = $p.Name.FamilyNamePrefix }
            $tempLastName = $person.Name.FamilyName
            $tempUsername = $tempFirstName + $tempLastNamePrefix + $tempLastName
            $tempUsername = $tempUsername.substring(0,[Math]::Min(20-$suffix.Length,$tempUsername.Length))  #max 18 chars for samaccountname
            $result = ("{0}{1}{2}" -f $tempUsername, $suffix, "_li")
            $result = $result.toLower()

            $result = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($result))
            $result = $result -replace '\s',''

            return $result
        } catch {
             throw("An error was found in the name convention algorithm: $($_.Exception.Message): $($_.ScriptStackTrace)")
        } 
    }
}

#Primary Email and UPN Generation
# 1. <First Name (initial)><Last name prefix><Last Name>@<Domain> (e.g jwilliams@yourdomain.com)
# 2. <First Name>.<last name prefix><Last Name>@<Domain> (e.g john.williams@yourdomain.com)
# 3. <First Name (initial)><Last name prefix><Last Name><iterator> @<Domain>(e.g jwilliams4@yourdomain.com)
function New-PrimaryEmail {
    [cmdletbinding()]
    Param (
        [object]$person,
        [string]$domain,
        [int]$Iteration
    )
    Process {
        try {
            $suffix = "";

            #Check Nickname
            if([string]::IsNullOrEmpty($p.Name.Nickname)) { $tempFirstName = $p.Name.GivenName } else { $tempFirstName = $p.Name.Nickname }
            $tempFirstName = $tempFirstName -Replace ' ',''

            switch ($Iteration) {
                0 {
                    $tempFirstName = $tempFirstName.substring(0,1)
                    Break 
                }
                1 {
                    $tempFirstName = $tempFirstName
                    Break 
                }
                default {
                    $tempFirstName = $tempFirstName.substring(0,1)
                    $suffix = "$($Iteration+1)"
                }
            }

            if([string]::IsNullOrEmpty($p.Name.FamilyNamePrefix)) { $tempLastNamePrefix = "" } else { $tempLastNamePrefix = $p.Name.FamilyNamePrefix }
            $tempLastName = $p.Name.FamilyName        
            $tempUsername = $tempFirstName + $tempLastNamePrefix + $tempLastName
            $tempUsername = $tempUsername.substring(0,[Math]::Min(64-$suffix.Length,$tempUsername.Length))  #max 64 chars for email address and upn
            $result = ("{0}{1}@{2}" -f $tempUsername, $suffix, $domain)
            $result = $result.toLower()
            $result = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($result))
            $result = $result -replace '\s',''
            return $result
        } catch {
             throw("An error was found in the name convention algorithm: $($_.Exception.Message): $($_.ScriptStackTrace)")
        } 
    }
}

function New-RandomPassword($PasswordLength) {
    if($PasswordLength -lt 8) { $PasswordLength = 8}

    # Used to store an array of characters that can be used for the password
    $CharPool = New-Object System.Collections.ArrayList

    # Add characters a-z to the arraylist
    for ($index = 97; $index -le 122; $index++) { [Void]$CharPool.Add([char]$index) }

    # Add characters A-Z to the arraylist
    for ($index = 65; $index -le 90; $index++) { [Void]$CharPool.Add([Char]$index) }

    # Add digits 0-9 to the arraylist
    $CharPool.AddRange(@("0","1","2","3","4","5","6","7","8","9"))

    # Add a range of special characters to the arraylist
    $CharPool.AddRange(@("!","""","#","$","%","&","'","(",")","*","+","-",".","/",":",";","<","=",">","?","@","[","\","]","^","_","{","|","}","~","!"))

    $password=""
    $rand = New-Object System.Random

    # Generate password by appending a random value from the array list until desired length of password is reached
    1..$PasswordLength | ForEach-Object { $password = $password + $CharPool[$rand.Next(0,$CharPool.Count)] }

    return $password
}

$clearTextPassword = New-RandomPassword($config.passwordLength)
$BartPassword = $clearTextPassword
$mail = New-PrimaryEmail -person $p -domain $config.emailAddressSuffix -Iteration 0
$userPrincipalName = $mail
$samAccountName = New-SamAccountName -person $p -Iteration 0

# unused attribues:
        #MiddleName                  = $p.Name.FamilyNamePrefix # Niet nodig
        #EmailAliasesToAdd           = @{}                      # Klant heeft geen aliassen
        #Info                       = ""                        # Niet gebruiken
        # location                                              # streetAddress..., hoeft niet.
        # division                  -                           # Niet nodig
        # startdate

$account = @{
        mail                        = $mail
        GivenName                   = $p.Name.NickName
        SN                          = $p.Custom.KpnBartLastName
        Initials                    = $p.Name.Initials
        Password                    = $clearTextPassword
        BartPassword                = $BartPassword
        UserPrincipalName           = $userPrincipalName
        DisplayName                 = $p.Custom.KpnBartDisplayName
        SamAccountName              = $samAccountName
        IsActive                    = $false
        ChangePasswordAtLogon       = $true
        UpdateExchangeWhenSettingMailAttribute = $false
        managerObjectGuid           = $mRef
        Persona                     = "Portal Werkplek + E1"
        EmployeeId                  = $p.ExternalId
        Department                  = $p.PrimaryContract.Department.DisplayName
        TelephoneNumber             = $p.contact.Business.phone.mobile
        OtherMobile                 = $p.contact.Personal.phone.mobile
        Title                       = $p.PrimaryContract.Title.Name
        ExtensionAttribute2         = $p.PrimaryContract.CostCenter.ExternalId 
}
#write-verbose -verbose ($account | ConvertTo-Json)

# Define attributes which should be updated on correlation
#$accountUpdateForAttributes = @("GivenName","SN","initials","DisplayName","managerObjectGuid","Department","OtherMobile","TelephoneNumber","ExtensionAttribute2","Title")
$accountUpdateForAttributes = @("Department","OtherMobile","TelephoneNumber","ExtensionAttribute2","Title")

# Connector specific settings (should only change when a new API call is required)
$accountCreateAttributes = @("GivenName","SN","Initials","Password","UserPrincipalName","DisplayName","MiddleName","SamAccountName")
$accountUpdateAttributes = @("EmployeeId","OtherMobile","TelephoneNumber","ExtensionAttribute2","Title","Department")

try {
    Import-Module $config.ModuleLocation -Force
    Initialize-KPNBartServiceClients -username $config.UserName -password $Config.password -BaseUrl $config.Url
} catch {
    #throw("Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)")
    $success = $false
    $auditMessage = "Initialize-KPNBartServiceClients failed with error: $($_.Exception.Message)"
    write-verbose -verbose -Message $auditMessage
    $auditLogs.Add([PSCustomObject]@{ 
            action  = "CreateAccount"
            Message = $auditMessage
            IsError = $true
        })
}

# Returns the objectguid of the user in case the user is known
function Get-CorrelationResult {
    [cmdletbinding()]
    Param (
        [string]$attribute,
        [string]$value
    )
    Process {
        try {
            [string[]] $ObjectAttributes = @("ObjectGUID", $attribute)
            #write-verbose -verbose ($objectAttributes | ConvertTo-Json)
            $userList = Get-KPNBartuser -Attributes $objectAttributes
            #write-verbose -verbose ($userList | ConvertTo-Json)
            $userFilter = $userList.Values.where({$_.Keys -eq $attribute -and $_.Values -eq $value})
            #write-verbose -verbose ($userFilter | ConvertTo-Json)
            return $userFilter.objectGuid
        } catch {
            throw("Get-KPNBartuser failed with error: $($_.Exception.Message)")
        }
    }
}

# Returns the objectguid of the user in case the user is known
function Get-UPN {
    [cmdletbinding()]
    Param (
        [string]$attribute,
        [string]$value
    )
    Process {
        try {
            [string[]] $ObjectAttributes = @("ObjectGUID", "userPrincipalName", $attribute)
            #write-verbose -verbose ($objectAttributes | ConvertTo-Json)
            $userList = Get-KPNBartuser -Attributes $objectAttributes
            #write-verbose -verbose ($userList | ConvertTo-Json)
            $userFilter = $userList.Values.where({$_.Keys -eq $attribute -and $_.Values -eq $value})
            #write-verbose -verbose ($userFilter | ConvertTo-Json)
            return $userFilter.userPrincipalName
        } catch {
            throw("Get-KPNBartuser failed with error: $($_.Exception.Message)")
        }
    }
}

function Get-Mail {
    [cmdletbinding()]
    Param (
        [string]$attribute,
        [string]$value
    )
    Process {
        try {
            [string[]] $ObjectAttributes = @("ObjectGUID", "mail", $attribute)
            #write-verbose -verbose ($objectAttributes | ConvertTo-Json)
            $userList = Get-KPNBartuser -Attributes $objectAttributes
            #write-verbose -verbose ($userList | ConvertTo-Json)
            $userFilter = $userList.Values.where({$_.Keys -eq $attribute -and $_.Values -eq $value})
            #write-verbose -verbose ($userFilter | ConvertTo-Json)
            return $userFilter.mail
        } catch {
            throw("Get-KPNBartuser failed with error: $($_.Exception.Message)")
        }
    }
}

# Only works for DistinguishedName, Guid, SamAccountName, Sid, UserPrincipalName, MailAddress
function Get-BartUserByIdentityType {
    [cmdletbinding()]
    Param (
        [string]$attribute,
        [string]$value
    )
    Process {
        $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
        $queryObjectIdentity.IdentityType = $attribute
        $queryObjectIdentity.Value = $value

        try {
            [string[]]$ObjectAttributes = @($attribute, "objectGuid")
            $return = Get-KPNBartuser -Identity $queryObjectIdentity -Attributes $objectAttributes
            Write-Verbose -Verbose "Checking for attribute '$attribute' with value '$value'. Exists: 'True'" 

            return $return
        } catch {
            $userNotFoundMessage = "Identity $value could not be found."            
            if ($_.Exception.Message.contains($userNotFoundMessage)) {
                Write-Verbose -Verbose "Checking for attribute '$attribute' with value '$value'. Exists: 'False'" 
                return $false
            } else {
                throw("Get-KPNBartuser failed with error: $($_.Exception.Message)")
            }
        }
    }
}

#Correlation
try {
    $correlationPersonField = ($config.correlationPersonField | Invoke-Expression)
    $correlationAccountField = $config.correlationAccountField

    #Check if account exists (based on externalId), else create
    $splat = @{
        attribute = $correlationAccountField
        value = $correlationPersonField
    }
    #write-verbose "1"
    $aRef = Get-CorrelationResult @splat
    #write-verbose "1"
    if (-not [string]::IsNullOrEmpty($aRef) -and $aRef.count -gt 1) {
        $message = "More than one account found. Please find the accounts in BART and remove the employeeID from the unmanaged account."
        Write-Verbose -Verbose $message
        throw ($message)
    }
} catch {
    #throw("Get-CorrelationResult failed with error: $($_.Exception.Message)")
	$success = $false
    $auditMessage = "Get-CorrelationResult failed with error: $($_.Exception.Message)"
    write-verbose -verbose $auditMessage
    $auditLogs.Add([PSCustomObject]@{ 
            action  = "CreateAccount"
            Message = $auditMessage
            IsError = $true
        }) 
}
if ($success -eq $true) {
    if (-not [string]::IsNullOrEmpty($aRef)) {

        # Correlate user
        Write-Verbose -Verbose -Message "Existing account found. Correlating person. (Using attribute '$correlationAccountField' and value '$correlationPersonField'. ObjectGuid: '$aRef')"

	# Get original values for account object -> To-Do: make this 1 call for complete 'original account' 
	# Generated UPN/Mail shouldn't be saved in account data, this can mess up external systems. Instead use original upn/mail.

        $account.userPrincipalName= Get-UPN @splat
        $account.mail = Get-Mail @splat

        # First Get-User, set to previousAccount
        $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
        $queryObjectIdentity.IdentityType = "Guid"
        $queryObjectIdentity.Value = $aRef

        $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
        $commandObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
        $commandObjectIdentity.Value = $queryObjectIdentity.Value
        $BartPassword = 'Geen nieuw wachtwoord gemaakt, account bestaat al'


        try {
            [string[]]$ObjectAttributes = @($accountUpdateForAttributes)
            $previousAccount = Get-KPNBartUser -Identity $queryObjectIdentity -Attributes $objectAttributes
        } catch {
            #throw("Get-KPNBartuser failed with error: $($_.Exception.Message)")
            $success = $false
            $auditMessage = "Get-KPNBartuser failed with error: $($_.Exception.Message)"
            write-verbose -verbose -Message $auditMessage
            $auditLogs.Add([PSCustomObject]@{ 
                    action  = "CreateAccount"
                    Message = $auditMessage
                    IsError = $true
                })
        }

        try {
        $previousAccountManager = Get-KPNBartUserManager -Identity $queryObjectIdentity
        } catch {
            #throw("Get-KPNBartUserManager failed with error: $($_.Exception.Message)")
            $success = $false
            $auditMessage = "Get-KPNBartUserManager failed with error: $($_.Exception.Message)"
            Write-Verbose -Verbose -Message $auditMessage
            $auditLogs.Add([PSCustomObject]@{ 
                    action  = "CreateAccount"
                    Message = $auditMessage
                    IsError = $true
                })
        }

        # Then define the accountUpdateAttributes array so it can be processed later on
        $accountUpdateAttributes = @()
        ForEach ($attribute in $account.GetEnumerator()) {
            if ($accountUpdateForAttributes.contains($attribute.key) -and ($attribute.value -ne $previousAccount.$($($attribute.Key)))) {
                Write-Verbose -Verbose -Message  "Update required for attribute '$($attribute.key)' (Current: '$($previousAccount.$($($attribute.Key)))', new: '$($attribute.value)')"

                # create new updateAttributes object
                $accountUpdateAttributes += $attribute.key
            }
        } 
    } else {
        write-information "Creating user"
        if ($config.blockAccountCreation -ne $true) {
            try {
                #Username, email Generation
                $maxUsernameIterations = 20

                $Iterator = 0
                do {
                    #SamAccountName check
                    $splat = @{
                        attribute = "SamAccountName"
                        value = $account.SamAccountName
                    }
                    $exists = Get-BartUserByIdentityType @splat

                    if ($exists -eq $false) {
                        # Mail check
                        $splat = @{
                            attribute = "MailAddress"
                            value = $account.mail
                        }
                        $exists = Get-BartUserByIdentityType @splat

                        if ($exists -eq $false) {
                            # UPN check
                            $splat = @{
                                attribute = "UserPrincipalName"
                                value = $account.UserPrincipalName
                            }
                            $exists = Get-BartUserByIdentityType @splat
                        }
                    }

                    if($exists -ne $false)
                    {
                        #Iterate
                        Write-Verbose -Verbose "SamAccountName, MailAddress or UPN already in use, iterating)"
                        $Iterator++
                        $account.samAccountName = New-SamAccountName -person $p -Iteration $Iterator
                        $account.mail = New-PrimaryEmail -person $p -domain $config.emailAddressSuffix -Iteration $Iterator
                        $account.UserPrincipalName = $account.mail
                        Write-verbose -Verbose "Iteration $($Iterator) - $($account.SamAccountName) - $($account.UserPrincipalName) - $($account.mail)"
                    }
                } while ($exists -ne $false -and $Iterator -lt $maxUsernameIterations)

                # Error handling in case the accounts run out
                if ($Iterator -eq $maxUsernameIterations) {
                    throw 'Iteration count exceeded. Increase $maxUsernameIterations or remove the (test)accounts'
                }

            } catch {
                #throw 'Iteration count exceeded. Increase $maxUsernameIterations or remove the (test)accounts'
                $success = $false
                $auditMessage = 'Iteration count exceeded. Increase $maxUsernameIterations or remove the (test)accounts'
                write-verbose -verbose $auditMessage
                $auditLogs.Add([PSCustomObject]@{ 
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $true
                    })
            }

            if (-not ($dryRun -eq $true)) {
                try {
                    $accountCreate = @{} 
                    $account.Password = ConvertTo-SecureString $account.Password -Force -AsPlainText
                    ForEach ($key in $account.Keys) {
                        if ($accountCreateAttributes.contains($key)) {
                            if ($key -eq "GivenName")   { $keyNew = "FirstName" }
                            elseif ($key -eq "SN")      { $keyNew = "LastName" }
                            else                        { $keyNew = $key }
                            $accountCreate.Add($keyNew,$account[$key])
                        }
                    }
                    Write-Verbose -Verbose -Message  "Creating account"
                    $createResult = New-KPNBartUser @accountCreate
                    #write-verbose -verbose ($createResult | ConvertTo-Json)
                    # Weet niet zeker of het onderstaande goed werkt - moet dit nog testen.
                    if ($createResult.Error -eq $true) {
                        $auditMessage = "KPN Bart user create for person " + $p.DisplayName + " failed"

                        $auditLogs.Add([PSCustomObject]@{
                                action  = "CreateAccount"
                                Message = $auditMessage
                                IsError = $true
                            })
                    }
                } catch {
                #throw("Could not run New-KPNBartUser, $($_.Exception.Message)")
                $success = $false
                $auditMessage = "Could not run New-KPNBartUser $($_.Exception.Message)"
                Write-Verbose -Verbose -Message  $auditMessage
                $auditLogs.Add([PSCustomObject]@{ 
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $true
                    }) 
                }

                try {
                    $splat = @{
                        attribute = "UserPrincipalName"
                        value = $account.UserPrincipalName
                    }
                    $createdUser = Get-BartUserByIdentityType @splat

                    if (-not ($null -eq $createdUser)) {
                        $aRef = $createdUser.objectGuid
                        $auditMessage = "Kpn Bart user create for person " + $p.DisplayName + " succeeded. (objectGuid: $aRef)"
                        $auditLogs.Add([PSCustomObject]@{
                                action  = "CreateAccount"
                                Message = $auditMessage
                                IsError = $false
                            })
                    }
                } catch {
                    $auditMessage = "KPN Bart user lookup (after create) for person " + $p.DisplayName + " failed"
                    $auditLogs.Add([PSCustomObject]@{
                                action  = "CreateAccount"
                                Message = $auditMessage
                                IsError = $true
                            })
                    #throw("Could not run Get-BartUserByIdentityType, $($_.Exception.Message)")
                }
            }

            $queryObjectIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
            $queryObjectIdentity.IdentityType = "Guid"
            $queryObjectIdentity.Value = $aRef

            $commandObjectIdentity = [KPNBartConnectedServices.CommandService.ObjectIdentity]::new()
            $commandObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
            $commandObjectIdentity.Value = $queryObjectIdentity.Value
            #write-verbose -verbose ($commandObjectIdentity | ConvertTo-Json)

            # disable the initial user (only on a create)
            if ($account.contains("isActive") -and $account.IsActive -eq $false ) {
                Write-Verbose -Verbose -Message  "User creation: Disabling user"
                if (-not ($dryRun -eq $true)) {
                    try {
                        Disable-KPNBartUser -Identity $commandObjectIdentity
                    } catch {
                        #throw("Disable-KPNBartUser returned error $($_.Exception.Message)")
                        $success = $false
                        $auditMessage = "Disable-KPNBartUser returned error $($_.Exception.Message)"
                        Write-Verbose -Verbose -Message  $auditMessage
                        $auditLogs.Add([PSCustomObject]@{ 
                                action  = "CreateAccount"
                                Message = $auditMessage
                                IsError = $true
                            }) 
                    }
                }
            }

            # Force user to change password at the next logon (only on a create)
            if ($account.contains("ChangePasswordAtLogon") -and $account.ChangePasswordAtLogon -eq $true) {
                Write-Verbose -Verbose "User creation: Setting password at next logon"
                if (-not ($dryRun -eq $true)) {
                    try {
                        Set-KPNBartPasswordchangeAtNextLogon -Identity $commandObjectIdentity
                    } catch {
                        #throw("Set-KPNBartPasswordchangeAtNextLogon returned error $($_.Exception.Message)")
                        $success = $false
                        $auditMessage = "Set-KPNBartPasswordchangeAtNextLogon returned error $($_.Exception.Message)"
                        write-verbose -verbose $auditMessage
                        $auditLogs.Add([PSCustomObject]@{ 
                                action  = "CreateAccount"
                                Message = $auditMessage
                                IsError = $true
                            }) 
                        }
                }
            }

            # Set mail (only on a create)
            if ( -not [string]::IsNullOrEmpty($account.Mail)) {
                if ($account.UpdateExchangeWhenSettingMailAttribute -eq $true) {
                    Write-Verbose -Verbose "User creation: Setting email addres and the Exchange property"
                    if (-not ($dryRun -eq $true)) {
                        try {
                            Set-KPNBartEmailPrimaryAddress -Identity $commandObjectIdentity -EmailAddress $account.Mail
                        } catch {
                            throw("Set-KPNBartEmailPrimaryAddress returned error $($_.Exception.Message)")
                        }
                    }
                } else {
                    Write-Verbose -Verbose "User creation: Setting email addres in the AD"
                    if (-not ($dryRun -eq $true)) {
                        try {
                            Set-KPNBartEmailADAttribute -Identity $commandObjectIdentity -EmailAddress $account.Mail
                        } catch {
                            throw("Set-KPNBartEmailPrimaryAddress returned error $($_.Exception.Message)")
                        }
                    }
                }
            }

            # Set persona
            if (-not [string]::IsNullOrEmpty($account.Persona)) {
                Write-Verbose "User creation: Setting persona"
                if (-not ($dryRun -eq $true)) {
                    try {
                        Set-KPNBartUserPersona -Identity $commandObjectIdentity -Persona $account.Persona
                    } catch {
                        throw("Set-KPNBartUserPersona returned error $($_.Exception.Message)")
                    }
                }
            }
        } else {
            # Check if samaccountname, mail, upn already exist  
            $auditMessage = "Kpn Bart user create for person " + $p.DisplayName + " blocked (See connector configuration). (objectGuid: $aRef)"
            $auditLogs.Add([PSCustomObject]@{
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $true
                    })
            Write-Verbose -Verbose -Message  "Creating users blocked!"
            $success = $false
            #throw("Not creating user for now (livegang stuff)")
        }
    }
} else {
    Write-Verbose -Verbose -Message "Not executing Create/Correlate block"
}
#Bulk update attributes 
$accountUpdate = @{}
ForEach ($key in $account.Keys) {
    if ($accountUpdateAttributes.contains($key)) {
        $accountUpdate.Add($key,$account[$key])
    }
}

$bulkObjectIdentity = [KPNBartConnectedServices.BulkCommandService.ObjectIdentity]::new()
$bulkObjectIdentity.IdentityType = $queryObjectIdentity.IdentityType
$bulkObjectIdentity.Value = $queryObjectIdentity.value

$CommandList = [System.Collections.Generic.List[KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]]::New()
foreach ($keyValue in $accountUpdate.GetEnumerator()) {
    $modifyCommand = [KPNBartConnectedServices.BulkCommandService.ModifyADAttributeCommand]::new()
    $modifyCommand.ObjectIdentity = $bulkObjectIdentity
    $modifyCommand.Attribute = $keyValue.Key
    $modifyCommand.Value = $keyValue.Value
    $CommandList.add($modifyCommand)
    Write-Verbose -Verbose -Message  "Update: setting attribute '$($keyValue.Key)' to value '$($keyValue.Value)'"
}

if (-not ($dryRun -eq $true) -and $success) {
    try {
        if ($CommandList.count -ne 0) {
            $UpdateResults = Set-KPNBartUserAttributeMultiple -CommandList $CommandList
            foreach ($Result in $UpdateResults) {
                if (-not $Result.error -eq $false) {
                    $success = $false
                    $auditMessage = "user-create for person " + $p.DisplayName + ".Failed to update attribute '$($Result.command.attribute)' to value '$($Result.command.value)'. Error: " + $Result.Message
                    Write-Verbose -Verbose -Message  $auditMessage
                    $auditLogs.Add([PSCustomObject]@{
                            action  = "CreateAccount"
                            Message = $auditMessage
                            IsError = $true
                        })
                }
            } 
        }
    } catch {
		#throw("Could not set account attributes of new account. Set-KPNBartUserAttributeMultiple returned error $($_.Exception.Message)")
        $success = $false
		$auditMessage = "Could not set account attributes of new account. Set-KPNBartUserAttributeMultiple returned error $($_.Exception.Message)"
		write-verbose -verbose $auditMessage
		$auditLogs.Add([PSCustomObject]@{ 
				action  = "CreateAccount"
				Message = $auditMessage
				IsError = $true
			}) 
    }
} else {
    Write-Verbose -Verbose -Message "Not executing multiple update block"
}

# Not required in my implementation (might need some work to get this working)
# # Convert user to the correct user type
# if ( -not [string]::IsNullOrEmpty($accountSpecialAttributes.UserType)) {
#     if (-not ($dryRun -eq $true)) {
#         try {
#             Set-KPNBartUserType  -Identity $commandObjectIdentity -userType $accountSpecialAttributes.UserType
#         } catch {
#             throw("Set-KPNBartUserType returned error $($_.Exception.Message)")
#         }
#     }
# }

## Aliasses are not used here
# Not required in my implementation (might need some work to get this working)
#$emailAliases = [System.Collections.Generic.List[string]]::New()
#$emailAliases.Add($p.Contact.Business.Email)
# Set aliases before setting primary
# if ($accountSpecialAttributes.UpdateExchangeWhenSettingMailAttribute -eq $true) {
#     foreach ($emailAlias in $accountSpecialAttributes.EmailAliasesToAdd) {
#         if (-not ($dryRun -eq $true)) {
#             try {
#                 New-KPNBartEmailAlias -Identity $commandObjectIdentity -EmailAddress $emailAlias
#             } catch {
#                 throw("New-KPNBartEmailAlias returned error $($_.Exception.Message)")
#             }
#         }
#     }
# }

# Set Manager
if ($success -eq $true) {
    if ( -not [string]::IsNullOrEmpty($mRef)) {
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
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $false
                    })
                } catch {
                    $success = $false
                    $auditMessage = "user-update for person " + $p.DisplayName + ". Update of manager failed with Error."
                    $auditLogs.Add([PSCustomObject]@{ 
                        action  = "CreateAccount"
                        Message = $auditMessage
                        IsError = $true
                    })
                    #throw("Set-KPNBartUserManager returned error $($_.Exception.Message)")
                }  
            } else {
                Write-Verbose -Verbose "dryRun: Setting manager"
            }
        } else {
            Write-Verbose -Verbose " Manager already configured correctly. Update not required."
        }
    } else {
        $success = $false
        $auditMessage = "user-update for person " + $p.DisplayName + ". Update of manager failed with Error: Manager is empty."    
        $auditLogs.Add([PSCustomObject]@{ 
            action  = "CreateAccount"
            Message = $auditMessage
            IsError = $true
        })
    }
} else {
    Write-Verbose -Verbose -Message "Not executing multiple update block"
}

if ($success -eq $true) {
    $auditMessage = "create Account for person " + $p.DisplayName + " succeeded"
    $auditLogs.Add([PSCustomObject]@{
            action  = "CreateAccount"
            Message = $auditMessage
            IsError = $false
        }
    )
}

$result = [PSCustomObject]@{
    Success          = $success
    AccountReference = $aRef
    Auditlogs        = $auditLogs
    Account          = $account
}

#send result to HelloID
Write-Output $result | ConvertTo-Json -Depth 10