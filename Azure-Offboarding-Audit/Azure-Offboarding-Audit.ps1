#requires -Version 7.2
<#
.SYNOPSIS
Read-only offboarding audit for two Microsoft Entra user objects across Entra ID and Azure.

.DESCRIPTION
Scans ownership, memberships, app assignments/consents, Entra roles/PIM, Conditional Access,
entitlement management, audit/sign-in activity, Azure RBAC/PIM, Resource Graph references,
and (unless skipped) serialized ARM resource properties for references to the target users.

No changes are made.

Install PS 7.x
winget install --id Microsoft.PowerShell --source winget
Open Powershell -> pwsh -> $PSVersionTable.PSVersion

Install modules
Install-Module Microsoft.Graph.Authentication,Az.Accounts,Az.Resources,Az.ResourceGraph -Scope CurrentUser

Set User Infos in script: $Targets

Start Script Frist with fast parameter
.\Azure-Offboarding-Audit.ps1 -SkipDeepArmScan

And for deep scan without
.\Azure-Offboarding-Audit.ps1
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PWD ("Azure-Offboarding-Audit-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [ValidateRange(1,180)]
    [int]$LookbackDays = 90,
    [switch]$SkipSignIns,
    [switch]$SkipDirectoryAudits,
    [switch]$SkipDeepArmScan
)

$ErrorActionPreference = 'Stop'

# Example values - replace with actual user UPNs and Entra Object IDs.
$Targets = @(
    [pscustomobject]@{
        UPN      = 'max.mustermann@example.com'
        ObjectId = '11111111-1111-1111-1111-111111111111'
    },
    [pscustomobject]@{
        UPN      = 'john.doe@example.com'
        ObjectId = '22222222-2222-2222-2222-222222222222'
    }
)

$RequiredModules = @(
    'Microsoft.Graph.Authentication',
    'Az.Accounts',
    'Az.Resources',
    'Az.ResourceGraph'
)

$missing = $RequiredModules | Where-Object { -not (Get-Module -ListAvailable -Name $_) }
if ($missing) {
    throw "Missing PowerShell modules: $($missing -join ', '). Install them first, for example: Install-Module Microsoft.Graph.Authentication,Az.Accounts,Az.Resources,Az.ResourceGraph -Scope CurrentUser"
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

$Findings        = [System.Collections.Generic.List[object]]::new()
$DirectoryAudits = [System.Collections.Generic.List[object]]::new()
$SignIns         = [System.Collections.Generic.List[object]]::new()
$Errors          = [System.Collections.Generic.List[object]]::new()

function Add-ErrorRecord {
    param([string]$Area, [string]$Principal, [string]$Message)
    $Errors.Add([pscustomobject]@{
        Time      = (Get-Date).ToString('s')
        Area      = $Area
        Principal = $Principal
        Message   = $Message
    })
}

function Add-Finding {
    param(
        [string]$Principal,
        [string]$Area,
        [string]$Type,
        [string]$Name,
        [string]$ObjectId,
        [string]$Scope,
        [string]$SourcePrincipal,
        [string]$Risk,
        [string]$RecommendedAction,
        [string]$Details
    )
    $Findings.Add([pscustomobject]@{
        Principal         = $Principal
        Area              = $Area
        Type              = $Type
        Name              = $Name
        ObjectId          = $ObjectId
        Scope             = $Scope
        SourcePrincipal   = $SourcePrincipal
        Risk              = $Risk
        RecommendedAction = $RecommendedAction
        Details           = $Details
    })
}

function Invoke-GraphPaged {
    param([Parameter(Mandatory)][string]$Uri)
    $all = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject
        if ($null -ne $response.value) {
            foreach ($item in $response.value) { $all.Add($item) }
            $next = $response.'@odata.nextLink'
        }
        else {
            $all.Add($response)
            $next = $null
        }
    }
    return $all.ToArray()
}

function Test-ContainsAnyLiteral {
    param(
        [AllowNull()][string]$Text,
        [string[]]$Needles
    )
    if ([string]::IsNullOrEmpty($Text)) { return @() }
    $hits = foreach ($needle in $Needles) {
        if ($Text.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $needle }
    }
    return @($hits)
}

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
$GraphScopes = @(
    'Directory.Read.All',
    'Application.Read.All',
    'RoleManagement.Read.Directory',
    'Policy.Read.All',
    'EntitlementManagement.Read.All',
    'AuditLog.Read.All'
)
Connect-MgGraph -Scopes $GraphScopes -NoWelcome
$MgContext = Get-MgContext
if (-not $MgContext.TenantId) { throw 'Could not determine Microsoft Graph tenant ID.' }
$TenantId = $MgContext.TenantId

Write-Host "Connecting to Azure tenant $TenantId..." -ForegroundColor Cyan
Connect-AzAccount -Tenant $TenantId | Out-Null

# Validate both user objects.
foreach ($target in $Targets) {
    try {
        $u = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$($target.ObjectId)?`$select=id,displayName,userPrincipalName,accountEnabled,userType" -OutputType PSObject
        Add-Finding -Principal $target.UPN -Area 'Entra ID' -Type 'User object' -Name $u.displayName -ObjectId $u.id -Scope 'Tenant' -SourcePrincipal $u.userPrincipalName -Risk 'Info' -RecommendedAction 'Verify this is the intended account before remediation.' -Details "accountEnabled=$($u.accountEnabled); userType=$($u.userType); currentUPN=$($u.userPrincipalName)"
    }
    catch {
        Add-ErrorRecord -Area 'User validation' -Principal $target.UPN -Message $_.Exception.Message
    }
}

# Cache transitive groups for both users. Used later to identify group-derived roles/CA effects.
$GroupIdsByUser = @{}
$AllRelevantPrincipalIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($t in $Targets) { [void]$AllRelevantPrincipalIds.Add($t.ObjectId) }

foreach ($target in $Targets) {
    Write-Host "Scanning Entra relationships for $($target.UPN)..." -ForegroundColor Cyan

    try {
        $owned = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/users/$($target.ObjectId)/ownedObjects"
        foreach ($o in $owned) {
            $odataType = $o.'@odata.type'
            $action = 'Review and transfer ownership if the object is operationally required.'
            $risk = 'Medium'
            if ($odataType -eq '#microsoft.graph.application') {
                $action = 'Add at least one replacement owner before removing/disabling the user.'
                $risk = 'High'
            }
            elseif ($odataType -eq '#microsoft.graph.servicePrincipal') {
                $action = 'Add a replacement Enterprise App owner before removing/disabling the user.'
                $risk = 'High'
            }
            elseif ($odataType -eq '#microsoft.graph.group') {
                $action = 'Confirm another valid group owner exists; add one if needed, then remove this owner.'
                $risk = 'Medium'
            }
            Add-Finding -Principal $target.UPN -Area 'Entra ownership' -Type $odataType -Name $o.displayName -ObjectId $o.id -Scope 'Tenant' -SourcePrincipal $target.ObjectId -Risk $risk -RecommendedAction $action -Details "appId=$($o.appId); mail=$($o.mail)"
        }
    }
    catch { Add-ErrorRecord -Area 'Entra ownedObjects' -Principal $target.UPN -Message $_.Exception.Message }

    try {
        $memberships = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/users/$($target.ObjectId)/transitiveMemberOf"
        $groupIds = [System.Collections.Generic.List[string]]::new()
        foreach ($m in $memberships) {
            if ($m.'@odata.type' -eq '#microsoft.graph.group') {
                $groupIds.Add($m.id)
                [void]$AllRelevantPrincipalIds.Add($m.id)
                Add-Finding -Principal $target.UPN -Area 'Entra groups' -Type 'Transitive group membership' -Name $m.displayName -ObjectId $m.id -Scope 'Tenant' -SourcePrincipal $target.ObjectId -Risk 'Low' -RecommendedAction 'Normally remove through offboarding; review role-assignable/security groups separately.' -Details "mail=$($m.mail); securityEnabled=$($m.securityEnabled); isAssignableToRole=$($m.isAssignableToRole)"
            }
        }
        $GroupIdsByUser[$target.ObjectId] = $groupIds.ToArray()
    }
    catch {
        $GroupIdsByUser[$target.ObjectId] = @()
        Add-ErrorRecord -Area 'Entra transitiveMemberOf' -Principal $target.UPN -Message $_.Exception.Message
    }

    try {
        $appAssignments = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/users/$($target.ObjectId)/appRoleAssignments"
        foreach ($a in $appAssignments) {
            Add-Finding -Principal $target.UPN -Area 'Enterprise applications' -Type 'App role assignment' -Name $a.resourceDisplayName -ObjectId $a.id -Scope $a.resourceId -SourcePrincipal $a.principalId -Risk 'Low' -RecommendedAction 'Remove if no longer needed; verify whether access is direct or group-derived.' -Details "appRoleId=$($a.appRoleId); principalDisplayName=$($a.principalDisplayName); createdDateTime=$($a.createdDateTime)"
        }
    }
    catch { Add-ErrorRecord -Area 'App role assignments' -Principal $target.UPN -Message $_.Exception.Message }

    try {
        $filter = [uri]::EscapeDataString("principalId eq '$($target.ObjectId)'")
        $grants = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$filter=$filter"
        foreach ($g in $grants) {
            Add-Finding -Principal $target.UPN -Area 'Enterprise applications' -Type 'Delegated OAuth consent' -Name $g.scope -ObjectId $g.id -Scope "clientId=$($g.clientId); resourceId=$($g.resourceId)" -SourcePrincipal $g.principalId -Risk 'Medium' -RecommendedAction 'Review and revoke delegated consent if it should not survive offboarding.' -Details "consentType=$($g.consentType); scope=$($g.scope)"
        }
    }
    catch { Add-ErrorRecord -Area 'OAuth2 permission grants' -Principal $target.UPN -Message $_.Exception.Message }

    try {
        $devices = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/users/$($target.ObjectId)/registeredDevices"
        foreach ($d in $devices) {
            Add-Finding -Principal $target.UPN -Area 'Entra devices' -Type 'Registered device' -Name $d.displayName -ObjectId $d.id -Scope 'Tenant' -SourcePrincipal $target.ObjectId -Risk 'Low' -RecommendedAction 'Review device ownership/registration and retire or reassign where appropriate.' -Details "deviceId=$($d.deviceId); operatingSystem=$($d.operatingSystem)"
        }
    }
    catch { Add-ErrorRecord -Area 'Registered devices' -Principal $target.UPN -Message $_.Exception.Message }

    try {
        $filter = [uri]::EscapeDataString("target/objectId eq '$($target.ObjectId)'")
        $assignments = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignments?`$expand=target,accessPackage&`$filter=$filter"
        foreach ($a in $assignments) {
            Add-Finding -Principal $target.UPN -Area 'Identity Governance' -Type 'Access package assignment' -Name $a.accessPackage.displayName -ObjectId $a.id -Scope $a.accessPackage.id -SourcePrincipal $target.ObjectId -Risk 'Low' -RecommendedAction 'Remove/expire the access package assignment as part of offboarding.' -Details "state=$($a.state); assignmentPolicyId=$($a.assignmentPolicyId); expiredDateTime=$($a.expiredDateTime)"
        }
    }
    catch { Add-ErrorRecord -Area 'Access package assignments' -Principal $target.UPN -Message $_.Exception.Message }

    if (-not $SkipDirectoryAudits) {
        try {
            $since = (Get-Date).ToUniversalTime().AddDays(-$LookbackDays).ToString('yyyy-MM-ddTHH:mm:ssZ')
            $filterText = "initiatedBy/user/id eq '$($target.ObjectId)' and activityDateTime ge $since"
            $filter = [uri]::EscapeDataString($filterText)
            $audits = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits?`$filter=$filter&`$orderby=activityDateTime desc"
            foreach ($a in $audits) {
                $targetsText = ($a.targetResources | ForEach-Object { "[$($_.type)] $($_.displayName) ($($_.id))" }) -join ' | '
                $DirectoryAudits.Add([pscustomobject]@{
                    Principal          = $target.UPN
                    ActivityDateTime   = $a.activityDateTime
                    Category           = $a.category
                    OperationType      = $a.operationType
                    ActivityDisplayName= $a.activityDisplayName
                    Result             = $a.result
                    LoggedByService    = $a.loggedByService
                    Targets            = $targetsText
                    CorrelationId      = $a.correlationId
                })
            }
        }
        catch { Add-ErrorRecord -Area 'Directory audit logs' -Principal $target.UPN -Message $_.Exception.Message }
    }

    if (-not $SkipSignIns) {
        try {
            $since = (Get-Date).ToUniversalTime().AddDays(-$LookbackDays).ToString('yyyy-MM-ddTHH:mm:ssZ')
            $filterText = "userId eq '$($target.ObjectId)' and createdDateTime ge $since"
            $filter = [uri]::EscapeDataString($filterText)
            $logs = Invoke-GraphPaged "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=$filter&`$orderby=createdDateTime desc"
            foreach ($s in $logs) {
                $SignIns.Add([pscustomobject]@{
                    Principal               = $target.UPN
                    CreatedDateTime          = $s.createdDateTime
                    AppDisplayName           = $s.appDisplayName
                    AppId                    = $s.appId
                    ResourceDisplayName      = $s.resourceDisplayName
                    ResourceId               = $s.resourceId
                    ClientAppUsed            = $s.clientAppUsed
                    IPAddress                = $s.ipAddress
                    ConditionalAccessStatus  = $s.conditionalAccessStatus
                    ErrorCode                = $s.status.errorCode
                    FailureReason            = $s.status.failureReason
                })
            }
        }
        catch { Add-ErrorRecord -Area 'Sign-in logs' -Principal $target.UPN -Message $_.Exception.Message }
    }
}

# Entra active and eligible roles (including group-based role-assignable groups).
Write-Host 'Scanning Entra role assignments and PIM...' -ForegroundColor Cyan
foreach ($roleEndpoint in @(
    [pscustomobject]@{ Uri='https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances?$expand=roleDefinition'; Type='Active/Permanent Entra role'; Risk='Critical' },
    [pscustomobject]@{ Uri='https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilityScheduleInstances?$expand=roleDefinition'; Type='Eligible Entra PIM role'; Risk='High' }
)) {
    try {
        $rows = Invoke-GraphPaged $roleEndpoint.Uri
        foreach ($r in $rows) {
            if (-not $AllRelevantPrincipalIds.Contains([string]$r.principalId)) { continue }
            foreach ($target in $Targets) {
                $source = $null
                if ($r.principalId -eq $target.ObjectId) { $source = 'Direct user' }
                elseif ($GroupIdsByUser[$target.ObjectId] -contains $r.principalId) { $source = "Via group $($r.principalId)" }
                if ($source) {
                    Add-Finding -Principal $target.UPN -Area 'Entra roles / PIM' -Type $roleEndpoint.Type -Name $r.roleDefinition.displayName -ObjectId $r.id -Scope $r.directoryScopeId -SourcePrincipal $source -Risk $roleEndpoint.Risk -RecommendedAction 'Replace/remove before offboarding; validate break-glass and separation-of-duties coverage.' -Details "roleDefinitionId=$($r.roleDefinitionId); start=$($r.startDateTime); end=$($r.endDateTime); assignmentType=$($r.assignmentType); memberType=$($r.memberType)"
                }
            }
        }
    }
    catch { Add-ErrorRecord -Area $roleEndpoint.Type -Principal 'Both users' -Message $_.Exception.Message }
}

# Conditional Access direct references and references through the user's current group memberships.
Write-Host 'Scanning Conditional Access policies...' -ForegroundColor Cyan
try {
    $policies = Invoke-GraphPaged 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies'
    foreach ($p in $policies) {
        $incUsers  = @($p.conditions.users.includeUsers)
        $excUsers  = @($p.conditions.users.excludeUsers)
        $incGroups = @($p.conditions.users.includeGroups)
        $excGroups = @($p.conditions.users.excludeGroups)
        foreach ($target in $Targets) {
            $matches = [System.Collections.Generic.List[string]]::new()
            if ($incUsers -contains $target.ObjectId) { $matches.Add('includeUsers: direct') }
            if ($excUsers -contains $target.ObjectId) { $matches.Add('excludeUsers: direct') }
            foreach ($gid in @($GroupIdsByUser[$target.ObjectId])) {
                if ($incGroups -contains $gid) { $matches.Add("includeGroups: $gid") }
                if ($excGroups -contains $gid) { $matches.Add("excludeGroups: $gid") }
            }
            if ($matches.Count -gt 0) {
                Add-Finding -Principal $target.UPN -Area 'Conditional Access' -Type 'Policy targeting' -Name $p.displayName -ObjectId $p.id -Scope 'Tenant' -SourcePrincipal ($matches -join ', ') -Risk 'High' -RecommendedAction 'Review before removing group memberships/account; exclusions are especially security-sensitive.' -Details "state=$($p.state); matches=$($matches -join '; ')"
            }
        }
    }
}
catch { Add-ErrorRecord -Area 'Conditional Access' -Principal 'Both users' -Message $_.Exception.Message }

# Azure subscriptions and RBAC/PIM.
Write-Host 'Scanning Azure subscriptions, RBAC and PIM...' -ForegroundColor Cyan
$Subscriptions = @(Get-AzSubscription -TenantId $TenantId | Where-Object State -eq 'Enabled')
foreach ($sub in $Subscriptions) {
    Write-Host "  Subscription: $($sub.Name)" -ForegroundColor DarkCyan
    try { Set-AzContext -SubscriptionId $sub.Id -Tenant $TenantId | Out-Null }
    catch { Add-ErrorRecord -Area 'Azure context' -Principal $sub.Name -Message $_.Exception.Message; continue }

    foreach ($target in $Targets) {
        try {
            $rbac = @(Get-AzRoleAssignment -ObjectId $target.ObjectId -ExpandPrincipalGroups -IncludeClassicAdministrators -ErrorAction Stop)
            foreach ($r in $rbac) {
                Add-Finding -Principal $target.UPN -Area 'Azure RBAC' -Type 'Role assignment' -Name $r.RoleDefinitionName -ObjectId $r.RoleAssignmentId -Scope $r.Scope -SourcePrincipal "$($r.DisplayName) [$($r.ObjectType)] $($r.ObjectId)" -Risk 'High' -RecommendedAction 'Replace/remove direct assignments; for group-derived access, review the group rather than cloning the assignment.' -Details "subscription=$($sub.Name); canDelegate=$($r.CanDelegate); condition=$($r.Condition)"
            }
        }
        catch { Add-ErrorRecord -Area "Azure RBAC - $($sub.Name)" -Principal $target.UPN -Message $_.Exception.Message }
    }

    $scope = "/subscriptions/$($sub.Id)"
    foreach ($kind in @(
        [pscustomobject]@{ Type='Azure PIM eligible role'; Command='Eligibility'; Risk='High' },
        [pscustomobject]@{ Type='Azure PIM active/time-bound role'; Command='Assignment'; Risk='High' }
    )) {
        try {
            $rows = if ($kind.Command -eq 'Eligibility') {
                @(Get-AzRoleEligibilitySchedule -Scope $scope -ErrorAction Stop)
            } else {
                @(Get-AzRoleAssignmentSchedule -Scope $scope -ErrorAction Stop)
            }
            foreach ($r in $rows) {
                if (-not $AllRelevantPrincipalIds.Contains([string]$r.PrincipalId)) { continue }
                foreach ($target in $Targets) {
                    $source = $null
                    if ($r.PrincipalId -eq $target.ObjectId) { $source = 'Direct user' }
                    elseif ($GroupIdsByUser[$target.ObjectId] -contains $r.PrincipalId) { $source = "Via group $($r.PrincipalId)" }
                    if ($source) {
                        Add-Finding -Principal $target.UPN -Area 'Azure PIM' -Type $kind.Type -Name $r.RoleDefinitionDisplayName -ObjectId $r.Name -Scope $r.Scope -SourcePrincipal $source -Risk $kind.Risk -RecommendedAction 'Remove or reassign PIM eligibility/assignment before deprovisioning.' -Details "subscription=$($sub.Name); roleDefinitionId=$($r.RoleDefinitionId); start=$($r.StartDateTime); end=$($r.EndDateTime); memberType=$($r.MemberType)"
                    }
                }
            }
        }
        catch { Add-ErrorRecord -Area "$($kind.Type) - $($sub.Name)" -Principal 'Both users' -Message $_.Exception.Message }
    }
}

# Resource Graph broad references. Useful for policy/configuration references by object ID or UPN.
Write-Host 'Scanning Azure Resource Graph for references...' -ForegroundColor Cyan
$Needles = @($Targets.ObjectId) + @($Targets.UPN)
foreach ($target in $Targets) {
    $targetNeedles = @($target.ObjectId, $target.UPN)
    $argPredicate = ($targetNeedles | ForEach-Object {
        $escaped = $_.Replace("'", "''")
        "tostring(properties) contains '$escaped' or tostring(tags) contains '$escaped'"
    }) -join ' or '

    foreach ($table in @('Resources','PolicyResources','ResourceContainers')) {
        try {
            $q = "$table | where $argPredicate | project id, name, type, subscriptionId, resourceGroup, location"
            $rows = @(Search-AzGraph -Query $q -UseTenantScope -AllowPartialScope -First 1000 -ErrorAction Stop)
            foreach ($r in $rows) {
                Add-Finding -Principal $target.UPN -Area 'Azure Resource Graph reference' -Type $r.type -Name $r.name -ObjectId $r.id -Scope $r.resourceGroup -SourcePrincipal 'Object ID or UPN reference' -Risk 'Medium' -RecommendedAction 'Inspect the resource configuration and determine whether the user/account/email must be replaced.' -Details "table=$table; subscriptionId=$($r.subscriptionId); Resource Graph may scrub PII, so deep ARM scan is the stronger check."
            }
        }
        catch { Add-ErrorRecord -Area "Resource Graph $table" -Principal $target.UPN -Message $_.Exception.Message }
    }
}

# Management-group PIM, where accessible.
try {
    $mgQuery = "ResourceContainers | where type =~ 'microsoft.management/managementgroups' | project id, name"
    $mgs = @(Search-AzGraph -Query $mgQuery -UseTenantScope -AllowPartialScope -First 1000 -ErrorAction Stop)
    foreach ($mg in $mgs) {
        foreach ($kind in @(
            [pscustomobject]@{ Type='Azure MG PIM eligible role'; Command='Eligibility' },
            [pscustomobject]@{ Type='Azure MG PIM active/time-bound role'; Command='Assignment' }
        )) {
            try {
                $rows = if ($kind.Command -eq 'Eligibility') { @(Get-AzRoleEligibilitySchedule -Scope $mg.id -ErrorAction Stop) } else { @(Get-AzRoleAssignmentSchedule -Scope $mg.id -ErrorAction Stop) }
                foreach ($r in $rows) {
                    if (-not $AllRelevantPrincipalIds.Contains([string]$r.PrincipalId)) { continue }
                    foreach ($target in $Targets) {
                        $source = $null
                        if ($r.PrincipalId -eq $target.ObjectId) { $source = 'Direct user' }
                        elseif ($GroupIdsByUser[$target.ObjectId] -contains $r.PrincipalId) { $source = "Via group $($r.PrincipalId)" }
                        if ($source) {
                            Add-Finding -Principal $target.UPN -Area 'Azure Management Group PIM' -Type $kind.Type -Name $r.RoleDefinitionDisplayName -ObjectId $r.Name -Scope $r.Scope -SourcePrincipal $source -Risk 'High' -RecommendedAction 'Remove/reassign at management-group scope before deprovisioning.' -Details "roleDefinitionId=$($r.RoleDefinitionId); start=$($r.StartDateTime); end=$($r.EndDateTime)"
                        }
                    }
                }
            }
            catch { Add-ErrorRecord -Area "$($kind.Type) - $($mg.name)" -Principal 'Both users' -Message $_.Exception.Message }
        }
    }
}
catch { Add-ErrorRecord -Area 'Management group discovery' -Principal 'Both users' -Message $_.Exception.Message }

# Deep ARM scan: serialize readable ARM resource objects and search literal UPN/object IDs.
# This is slower but avoids Resource Graph's PII scrubbing for many resources.
if (-not $SkipDeepArmScan) {
    Write-Host 'Running deep ARM property scan. This can be slow in large tenants...' -ForegroundColor Cyan
    foreach ($sub in $Subscriptions) {
        try { Set-AzContext -SubscriptionId $sub.Id -Tenant $TenantId | Out-Null }
        catch { continue }
        try {
            $resources = @(Get-AzResource -ExpandProperties -ErrorAction Stop)
            foreach ($r in $resources) {
                $json = $r | ConvertTo-Json -Depth 40 -Compress
                $hits = Test-ContainsAnyLiteral -Text $json -Needles $Needles
                if ($hits.Count -eq 0) { continue }
                foreach ($target in $Targets) {
                    $targetHits = @($hits | Where-Object { $_ -ieq $target.ObjectId -or $_ -ieq $target.UPN })
                    if ($targetHits.Count -gt 0) {
                        Add-Finding -Principal $target.UPN -Area 'Deep ARM property reference' -Type $r.ResourceType -Name $r.Name -ObjectId $r.ResourceId -Scope $r.ResourceGroupName -SourcePrincipal ($targetHits -join ', ') -Risk 'High' -RecommendedAction 'Open the resource and replace/remove the embedded account reference. Verify child/data-plane configuration separately.' -Details "subscription=$($sub.Name); matched=$($targetHits -join '; ')"
                    }
                }
            }
        }
        catch { Add-ErrorRecord -Area "Deep ARM scan - $($sub.Name)" -Principal 'Both users' -Message $_.Exception.Message }
    }
}

# Deduplicate main findings.
$FindingsUnique = $Findings | Sort-Object Principal,Area,Type,ObjectId,Scope,SourcePrincipal -Unique

$FindingsUnique | Export-Csv -Path (Join-Path $OutputPath '01-Findings.csv') -NoTypeInformation -Delimiter ';' -Encoding utf8BOM
$DirectoryAudits | Export-Csv -Path (Join-Path $OutputPath '02-DirectoryAudits.csv') -NoTypeInformation -Delimiter ';' -Encoding utf8BOM
$SignIns | Export-Csv -Path (Join-Path $OutputPath '03-SignIns.csv') -NoTypeInformation -Delimiter ';' -Encoding utf8BOM
$Errors | Export-Csv -Path (Join-Path $OutputPath '99-Errors.csv') -NoTypeInformation -Delimiter ';' -Encoding utf8BOM

$summary = @"
Azure / Entra offboarding audit
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')
Tenant: $TenantId
Targets:
$($Targets | ForEach-Object { "- $($_.UPN) [$($_.ObjectId)]" } | Out-String)

Files:
- 01-Findings.csv: ownership, groups, roles, PIM, RBAC, CA, app assignments/consents, access packages, resource references
- 02-DirectoryAudits.csv: operations initiated by the users in the last $LookbackDays days (unless skipped)
- 03-SignIns.csv: recent app/resource sign-ins in the last $LookbackDays days (unless skipped)
- 99-Errors.csv: permission/API areas that could not be scanned

Important blind spots that require provider-specific checks:
- Azure DevOps PATs and other Azure DevOps ACL/service-connection ownership
- Credentials/secrets whose object does not persist a creator identity
- Key Vault secret/key/certificate data-plane history unless diagnostic/audit logs exist
- Previously issued SAS tokens or other bearer tokens that are not centrally enumerable
- SaaS applications outside Entra/Azure control plane
- Some child/data-plane settings not returned by generic ARM GETs

Do not delete/disable the accounts until High/Critical findings have replacement owners/identities and token dependencies have been rotated or revoked.
"@
$summary | Set-Content -Path (Join-Path $OutputPath 'README.txt') -Encoding utf8

Write-Host ''
Write-Host "Audit complete: $OutputPath" -ForegroundColor Green
Write-Host "Findings: $($FindingsUnique.Count) | Directory audits: $($DirectoryAudits.Count) | Sign-ins: $($SignIns.Count) | Errors: $($Errors.Count)"
Write-Host 'Start with 01-Findings.csv and filter Risk = Critical/High.' -ForegroundColor Yellow

