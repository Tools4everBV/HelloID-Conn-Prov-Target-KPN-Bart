#################################################
# HelloID-Conn-Prov-Target-KPN-Bart-UniquenessCheck
# PowerShell V2
#################################################

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

function ConvertTo-BartUniquenessData {
    param ($Account)

    $fields = @{}
    if ($Account -is [System.Collections.IDictionary]) {
        foreach ($field in $Account.Keys) {
            if ($field -isnot [string] -or [string]::IsNullOrWhiteSpace($field) -or $fields.ContainsKey($field)) {
                throw 'BART returned invalid or ambiguous attribute names.'
            }
            $fields[$field] = $Account[$field]
        }
    } elseif ($Account -is [pscustomobject]) {
        foreach ($property in $Account.PSObject.Properties) {
            $fields[$property.Name] = $property.Value
        }
    } else {
        throw 'BART returned an unsupported account record.'
    }
    return $fields
}

try {
    $outputContext.Success = $false
    $actionMessage = 'validating uniqueness input'
    if ($null -eq $actionContext.Data) {
        throw 'The mapped account data could not be found.'
    }
    $mappedData = ConvertTo-BartUniquenessData -Account $actionContext.Data
    $mailFieldName = 'Mail'
    $mailValue = $mappedData['Mail']
    if ($null -ne $mappedData['ExtensionData']) {
        $extensionData = ConvertTo-BartUniquenessData -Account $mappedData['ExtensionData']
        if ($extensionData.ContainsKey('Mail')) {
            $mailFieldName = 'ExtensionData.Mail'
            $mailValue = $extensionData['Mail']
        }
    }
    $fieldsToCheck = @(
        [pscustomobject]@{ Name = 'SamAccountName'; Attribute = 'sAMAccountName'; Value = $mappedData['SamAccountName']; CrossCheckOn = @() }
        [pscustomobject]@{ Name = 'UserPrincipalName'; Attribute = 'userPrincipalName'; Value = $mappedData['UserPrincipalName']; CrossCheckOn = @('mail') }
        [pscustomobject]@{ Name = 'CommonName'; Attribute = 'cn'; Value = $mappedData['CommonName']; CrossCheckOn = @() }
        [pscustomobject]@{ Name = $mailFieldName; Attribute = 'mail'; Value = $mailValue; CrossCheckOn = @('userPrincipalName') }
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Value) }

    $ownAccountGuid = [guid]::Empty
    if ([string]::IsNullOrWhiteSpace([string]$actionContext.Operation)) {
        throw 'The uniqueness operation could not be found.'
    }
    if ($actionContext.Operation -ne 'create') {
        if (-not [guid]::TryParse([string]$actionContext.References.Account.Id, [ref]$ownAccountGuid) -or $ownAccountGuid -eq [guid]::Empty) {
            throw 'The account reference must contain a valid ObjectGUID in Account.Id.'
        }
    }

    $nonUniqueFields = [System.Collections.Generic.List[string]]::new()
    foreach ($fieldName in @($outputContext.NonUniqueFields)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$fieldName)) {
            $nonUniqueFields.Add([string]$fieldName)
        }
    }

    if (@($fieldsToCheck).Count -gt 0) {
        $actionMessage = 'initializing KPN-Bart service clients'
        Import-Module $actionContext.Configuration.ModuleLocation -Force
        Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

        $attributes = [string[]]@('ObjectGUID') + @($fieldsToCheck | ForEach-Object { $_.Attribute; $_.CrossCheckOn })
        $attributes = [string[]]@($attributes | Select-Object -Unique)
        $actionMessage = 'querying KPN-Bart accounts for uniqueness'
        $userList = Get-KPNBartUser -Attributes $attributes -ErrorAction Stop
        if ($null -eq $userList) {
            throw 'BART returned no uniqueness query response. Uniqueness could not be verified.'
        }
        if ($userList -is [System.Collections.IDictionary]) {
            $accounts = @($userList.Values)
        } elseif ($userList -is [array]) {
            $accounts = @($userList)
        } else {
            throw 'BART returned an unsupported uniqueness query response.'
        }

        foreach ($rawAccount in $accounts) {
            $account = ConvertTo-BartUniquenessData -Account $rawAccount
            $accountGuid = [guid]::Empty
            if (-not [guid]::TryParse([string]$account['ObjectGUID'], [ref]$accountGuid) -or $accountGuid -eq [guid]::Empty) {
                throw 'BART returned an account without a valid ObjectGUID.'
            }
            if ($accountGuid -eq $ownAccountGuid) {
                continue
            }
            foreach ($attribute in $attributes) {
                if (-not $account.ContainsKey($attribute)) {
                    throw "BART did not return requested attribute [$attribute]. Uniqueness could not be verified."
                }
            }

            foreach ($field in $fieldsToCheck) {
                $actionMessage = "checking uniqueness of [$($field.Name)]"
                $matchedAttribute = $null
                foreach ($attribute in @($field.Attribute) + @($field.CrossCheckOn)) {
                    $matches = [string]::Equals([string]$account[$attribute], [string]$field.Value, [System.StringComparison]::OrdinalIgnoreCase)
                    if ($matches) {
                        $matchedAttribute = $attribute
                        break
                    }
                }
                if ($null -ne $matchedAttribute) {
                    $nonUniqueFields.Add($field.Name)
                    Write-Warning "Property [$($field.Name)] is not unique; another BART account uses this value in [$matchedAttribute]."
                }
            }
        }
        Write-Information "KPN-BART uniqueness check completed. Accounts checked: [$($accounts.Count)]."
    }

    $outputContext.NonUniqueFields = @($nonUniqueFields | Sort-Object -Unique)
    $outputContext.Success = $true
} catch {
    $outputContext.Success = $false
    Write-Warning "KPN-BART uniqueness check failed while $actionMessage at line [$($_.InvocationInfo.ScriptLineNumber)]."
    Write-Error "Could not verify KPN-Bart uniqueness. Error: $($_.Exception.Message)"
}