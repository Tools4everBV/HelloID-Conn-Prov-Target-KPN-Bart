#################################################################
# HelloID-Conn-Prov-Target-KPN-BART-Permissions-Group-Import
# PowerShell V2
#################################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

$resourceType = 'Group'

#region functions
function Get-KPNBartResourceAuthorization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSModuleInfo]
        $Module,

        [Parameter(Mandatory)]
        [KPNBartConnectedServices.QueryService.ObjectIdentity]
        $ResourceIdentity
    )

    try {
        $resourceAuthorizationQuery = [KPNBartConnectedServices.QueryService.ResourceAuthorizationQuery]::new()
        $resourceAuthorizationQuery.ResourceIdentity = $ResourceIdentity
        $resourceAuthorizationQuery.ResourceAuthorization = [KPNBartConnectedServices.QueryService.ResourceAuthorizationEnum]::Access

        # QueryService is a script-scoped variable inside the KPNBart module
        Write-Output (& $Module { param($query) $script:QueryService.Execute($query) } $resourceAuthorizationQuery)
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion functions

try {
    $actionMessage = 'initializing KPN-Bart service clients'
    Write-Information "Import module $($actionContext.Configuration.ModuleLocation) and initialize KPN WSDL Services"
    $bartModule = Import-Module $actionContext.Configuration.ModuleLocation -Force -PassThru | Select-Object -First 1
    Initialize-KPNBartServiceClients -Username $actionContext.Configuration.UserName -Password $actionContext.Configuration.password -BaseUrl $actionContext.Configuration.BaseUrl

    $actionMessage = "querying resources of type [$resourceType]"
    $resources = @((Get-KPNBartResource -ResourceType $resourceType -ErrorAction Stop).ResourceModel | Where-Object { $null -ne $_ })
    Write-Information "Queried [$($resources.Count)] resources of type [$resourceType]"

    $permissionCount = 0
    foreach ($resource in $resources) {
        $actionMessage = "querying members of resource [$($resource.DisplayName)] [$($resource.ObjectGuid)]"

        $resourceIdentity = [KPNBartConnectedServices.QueryService.ObjectIdentity]::new()
        $resourceIdentity.IdentityType = 'Guid'
        $resourceIdentity.Value = "$($resource.ObjectGuid)"

        try {
            $members = @(Get-KPNBartResourceAuthorization -Module $bartModule -ResourceIdentity $resourceIdentity -ErrorAction Stop | Where-Object { $null -ne $_ })
        } catch {
            Write-Warning "Error $($actionMessage). Error: $($_.Exception.Message)"
            continue
        }

        $accountReferences = @(foreach ($member in $members) {
                $memberGuid = [guid]::Empty
                if ([guid]::TryParse([string]$member.ObjectGuid, [ref]$memberGuid) -and $memberGuid -ne [guid]::Empty) {
                    @{
                        Id             = $memberGuid.ToString()
                        AccountCreated = $false
                    }
                }
            })

        if ($accountReferences.Count -gt 0) {
            # Must match the DisplayName and Reference structure of permissions.ps1
            $displayName = "Group_$($resource.DisplayName)"
            $displayName = $displayName.Substring(0, [System.Math]::Min(100, $displayName.Length))

            $description = $null
            if (-not [string]::IsNullOrEmpty($resource.Description)) {
                $description = $resource.Description.Substring(0, [System.Math]::Min(100, $resource.Description.Length))
            }

            Write-Output @{
                AccountReferences   = $accountReferences
                PermissionReference = @{
                    Reference   = @{ Reference = $resource.ObjectGuid }
                    DisplayName = $displayName
                }
                Description         = $description
                DisplayName         = $displayName
            }
        }
        $permissionCount++
    }
    Write-Information "Successfully queried [$permissionCount] existing resources of type [$resourceType]"
} catch {
    $ex = $PSItem
    $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    if ($null -ne $ex.Exception.InnerException) {
        $warningMessage = "$warningMessage. Inner error: $($ex.Exception.InnerException.Message)"
    }
    Write-Warning $warningMessage
    Write-Error $auditMessage
}
