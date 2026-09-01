# Azure / Entra Offboarding Audit

A read-only PowerShell audit script for identifying dependencies and access associated with Microsoft Entra ID users before offboarding or account deletion.

The script scans Microsoft Entra ID and Azure for ownership, memberships, role assignments, application access, Conditional Access references, PIM assignments, resource references, and recent activity related to the specified users.

> **Read-only:** The script does not modify, disable, or delete users, assignments, resources, or configuration.

## What It Checks

The audit covers:

- Microsoft Entra ID
  - User object validation
  - Owned objects
  - Transitive group memberships
  - Registered devices
  - Enterprise application role assignments
  - Delegated OAuth consent
  - Access package assignments
  - Entra role assignments
  - Entra PIM eligibility and assignments
  - Conditional Access policy references
  - Directory audit activity
  - Sign-in activity

- Microsoft Azure
  - Azure RBAC assignments
  - Azure PIM eligibility and assignments
  - Management Group PIM assignments
  - Azure Resource Graph references
  - Resource properties containing references to the user

The script checks both direct assignments and, where applicable, access inherited through group membership.

## Requirements

### PowerShell

PowerShell 7.2 or later is required.

Install the current PowerShell version on Windows:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Verify the installed version:

```powershell
pwsh
$PSVersionTable.PSVersion
```

### PowerShell Modules

Install the required modules:

```powershell
Install-Module Microsoft.Graph.Authentication,Az.Accounts,Az.Resources,Az.ResourceGraph -Scope CurrentUser
```

Required modules:

- `Microsoft.Graph.Authentication`
- `Az.Accounts`
- `Az.Resources`
- `Az.ResourceGraph`

## Configuration

Edit the `$Targets` section in `Azure-Offboarding-Audit.ps1` and replace the example values with the users that should be audited:

```powershell
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
```

Both the UPN and Microsoft Entra Object ID are used to locate references.

## Usage

### Fast Scan

Start with the faster scan, which skips serialization and inspection of all readable ARM resource properties:

```powershell
.\Azure-Offboarding-Audit.ps1 -SkipDeepArmScan
```

### Deep Scan

Run without `-SkipDeepArmScan` for the more comprehensive scan:

```powershell
.\Azure-Offboarding-Audit.ps1
```

The deep ARM scan can take considerably longer in tenants with many Azure resources.

## Parameters

| Parameter | Description |
|---|---|
| `-OutputPath` | Directory where the audit results are written. A timestamped directory is created by default. |
| `-LookbackDays` | Number of days included for audit and sign-in activity. Default: `90`. |
| `-SkipSignIns` | Skip Microsoft Entra sign-in log collection. |
| `-SkipDirectoryAudits` | Skip Microsoft Entra directory audit log collection. |
| `-SkipDeepArmScan` | Skip the slower scan of serialized Azure ARM resource properties. |

Example:

```powershell
.\Azure-Offboarding-Audit.ps1 -LookbackDays 30 -SkipDeepArmScan
```

## Authentication and Permissions

The script authenticates interactively against Microsoft Graph and Azure.

It requests the following Microsoft Graph delegated permissions:

- `Directory.Read.All`
- `Application.Read.All`
- `RoleManagement.Read.Directory`
- `Policy.Read.All`
- `EntitlementManagement.Read.All`
- `AuditLog.Read.All`

The authenticated account must also have sufficient Azure permissions to enumerate the subscriptions and resources that should be included in the audit.

Results depend on the permissions of the authenticated account. Areas that cannot be accessed are recorded in `99-Errors.csv`.

## Output

By default, the script creates a timestamped directory such as:

```text
Azure-Offboarding-Audit-20260901-153000/
```

The following files are generated:

| File | Content |
|---|---|
| `01-Findings.csv` | Ownership, groups, roles, PIM, RBAC, Conditional Access, application assignments, consent, access packages and resource references |
| `02-DirectoryAudits.csv` | Directory operations initiated by the target users during the configured lookback period |
| `03-SignIns.csv` | Recent application and resource sign-ins |
| `99-Errors.csv` | APIs, subscriptions or permission areas that could not be scanned |
| `README.txt` | Summary of the audit run and important limitations |

Start the review with `01-Findings.csv` and prioritize findings with a risk level of `Critical` or `High`.

## Important Limitations

This script is intended as an additional offboarding audit and cannot guarantee that every dependency associated with a user has been identified.

Some areas require separate or provider-specific checks, including:

- Azure DevOps PATs
- Azure DevOps ACLs and service connection ownership
- Credentials or secrets that do not retain creator information
- Key Vault secret, key, and certificate data-plane history unless appropriate audit logs exist
- Previously issued SAS tokens and other bearer tokens that cannot be centrally enumerated
- SaaS applications outside the Microsoft Entra/Azure control plane
- Child-resource and data-plane configuration not exposed through generic ARM resource queries

Azure Resource Graph may also omit or scrub personally identifiable information. The optional deep ARM scan therefore provides an additional search for user Object IDs and UPNs in readable resource properties, but it does not eliminate all possible blind spots.

## Security and Privacy

Audit results can contain sensitive information, including:

- User principal names
- Microsoft Entra Object IDs
- Group and role memberships
- Azure resource IDs and scopes
- Application information
- Sign-in IP addresses
- Directory audit activity
- Tenant information

**Do not commit generated audit results to a public repository.**

Consider excluding generated audit directories in `.gitignore`, for example:

```gitignore
Azure-Offboarding-Audit-*/
```

The UPNs and Object IDs included in this repository are example values only.

## Recommended Offboarding Workflow

1. Run the fast audit.
2. Review `Critical` and `High` findings.
3. Resolve ownership and privileged-access dependencies.
4. Run the deep ARM scan if appropriate.
5. Perform provider-specific checks for areas not covered by the script.
6. Rotate or revoke credentials and token dependencies where required.
7. Verify replacement owners and identities.
8. Only then proceed with account disablement or deletion.

## Disclaimer

This script is provided as an auditing aid. Its results depend on available APIs, permissions, logging retention, resource providers, and the configuration of the tenant.

Review the results and applicable Microsoft documentation before making changes to production environments.