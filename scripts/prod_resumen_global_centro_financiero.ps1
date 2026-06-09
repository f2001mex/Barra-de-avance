param(
    [string]$OrgAlias = "actiprod",
    [string]$CentroFinancieroLike = "%MONTES%URALES%",
    [string]$OutputDir = "outputs\resumen_global_montes_urales_prod_20260608"
)

$ErrorActionPreference = "Stop"
$env:SF_DISABLE_PROGRESS_BAR = "true"
$env:SFDX_DISABLE_PROGRESS_BAR = "true"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Invoke-SfQuery([string]$name, [string]$query) {
    $jsonPath = Join-Path $OutputDir "$name.json"
    $errPath = Join-Path $OutputDir "$name.err.txt"
    $compactQuery = ($query -replace "\s+", " ").Trim()
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $raw = & sf data query -o $OrgAlias -q $compactQuery --json 2>$errPath
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $raw | Set-Content -Path $jsonPath -Encoding UTF8
    if ($exitCode -ne 0) {
        throw "sf data query failed with exit code $exitCode. $((Get-Content -Path $errPath -ErrorAction SilentlyContinue) -join ' ')"
    }
    $parsed = $raw | ConvertFrom-Json
    if ($parsed.status -ne 0) {
        throw ($parsed.message | Out-String)
    }
    return @($parsed.result.records)
}

$today = Get-Date
$monthStart = (Get-Date -Day 1).ToString("yyyy-MM-dd")
$nextMonthStart = (Get-Date -Day 1).AddMonths(1).ToString("yyyy-MM-dd")

$summaries = Invoke-SfQuery "resumen_global_montes_urales" @"
SELECT Id, Name, Fecha__c, ExternalId_Nomina__c, CentroFinanciero__c, OwnerId, Owner.Name,
       Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c, PorcentajeAvanceMensual__c
FROM ResumenGlobalPostventa__c
WHERE Fecha__c >= $monthStart
AND Fecha__c < $nextMonthStart
AND CentroFinanciero__c LIKE '$CentroFinancieroLike'
ORDER BY ExternalId_Nomina__c, Fecha__c DESC
"@

$advisorIds = @($summaries | ForEach-Object { $_.ExternalId_Nomina__c } | Where-Object { $_ } | Sort-Object -Unique)
$ownerIds = @($summaries | ForEach-Object { $_.OwnerId } | Where-Object { $_ } | Sort-Object -Unique)

function Quote-InList([string[]]$values) {
    if (!$values -or $values.Count -eq 0) { return "''" }
    return "'" + (($values | ForEach-Object { $_.Replace("'", "\'") }) -join "','") + "'"
}

$advisorIn = Quote-InList $advisorIds
$ownerIn = Quote-InList $ownerIds

$users = Invoke-SfQuery "users_roles" @"
SELECT Id, Name, IsActive, Username, Email, ID_ASESOR__c, EmployeeNumber,
       Profile.Name, UserRoleId, UserRole.Name, UserRole.DeveloperName, UserRole.ParentRoleId
FROM User
WHERE Id IN ($ownerIn) OR ID_ASESOR__c IN ($advisorIn) OR EmployeeNumber IN ($advisorIn)
ORDER BY Name
"@

$roleIds = @()
$roleIds += @($users | ForEach-Object { $_.UserRoleId } | Where-Object { $_ })
$roleIds += @($users | ForEach-Object { if ($_.UserRole) { $_.UserRole.ParentRoleId } } | Where-Object { $_ })
$roleIds = @($roleIds | Sort-Object -Unique)
$roleIn = Quote-InList $roleIds

$roles = Invoke-SfQuery "roles" @"
SELECT Id, Name, DeveloperName, ParentRoleId
FROM UserRole
WHERE Id IN ($roleIn)
ORDER BY Name
"@

$roleById = @{}
foreach ($role in $roles) {
    $roleById[$role.Id] = $role
}

$usersById = @{}
$usersByAdvisor = @{}
foreach ($user in $users) {
    $usersById[$user.Id] = $user
    foreach ($key in @($user.ID_ASESOR__c, $user.EmployeeNumber) | Where-Object { $_ } | Select-Object -Unique) {
        $key = [string]$key
        if (!$usersByAdvisor.ContainsKey($key)) { $usersByAdvisor[$key] = @() }
        $usersByAdvisor[$key] += $user
    }
}

$latestSummaryByAdvisor = @{}
foreach ($summary in $summaries) {
    $advisorId = [string]$summary.ExternalId_Nomina__c
    if (!$latestSummaryByAdvisor.ContainsKey($advisorId)) {
        $latestSummaryByAdvisor[$advisorId] = $summary
    }
}

$rows = foreach ($advisorId in ($latestSummaryByAdvisor.Keys | Sort-Object)) {
    $summary = $latestSummaryByAdvisor[$advisorId]
    $matchedUsers = @()
    if ($summary.OwnerId -and $usersById.ContainsKey($summary.OwnerId)) {
        $matchedUsers += $usersById[$summary.OwnerId]
    }
    if ($usersByAdvisor.ContainsKey($advisorId)) {
        $matchedUsers += @($usersByAdvisor[$advisorId])
    }
    $matchedUsers = @($matchedUsers | Where-Object { $_ } | Sort-Object Id -Unique)
    foreach ($user in $matchedUsers) {
        $role = if ($user.UserRoleId -and $roleById.ContainsKey($user.UserRoleId)) { $roleById[$user.UserRoleId] } else { $null }
        $parentRole = if ($role -and $role.ParentRoleId -and $roleById.ContainsKey($role.ParentRoleId)) { $roleById[$role.ParentRoleId] } else { $null }
        [pscustomobject]@{
            CentroFinanciero = $summary.CentroFinanciero__c
            FechaResumen = $summary.Fecha__c
            ExternalId_Nomina = $summary.ExternalId_Nomina__c
            UserId = $user.Id
            NombreUsuario = $user.Name
            Activo = $user.IsActive
            ID_ASESOR__c = $user.ID_ASESOR__c
            EmployeeNumber = $user.EmployeeNumber
            Perfil = if ($user.Profile) { $user.Profile.Name } else { "" }
            Rol = if ($role) { $role.Name } else { "" }
            RolDeveloperName = if ($role) { $role.DeveloperName } else { "" }
            ReportaARol = if ($parentRole) { $parentRole.Name } else { "" }
            ReportaARolDeveloperName = if ($parentRole) { $parentRole.DeveloperName } else { "" }
            MetaDiaria = $summary.Meta__c
            MetaMensual = $summary.MetaMensual__c
            ContactadosDia = $summary.Contactados__c
            ContactadosMensual = $summary.ContactadosMensual__c
            PorcentajeAvanceMensual = $summary.PorcentajeAvanceMensual__c
            Username = $user.Username
            Email = $user.Email
        }
    }
}

$rows | Export-Csv -Path (Join-Path $OutputDir "usuarios_resumen_global_montes_urales_prod.csv") -NoTypeInformation -Encoding UTF8
$summaries | Export-Csv -Path (Join-Path $OutputDir "resumen_global_montes_urales_raw_prod.csv") -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
    OrgAlias = $OrgAlias
    FechaEjecucionLocal = (Get-Date).ToString("s")
    CentroFinancieroLike = $CentroFinancieroLike
    RegistrosResumenMes = $summaries.Count
    UsuariosUnicos = @($rows | Select-Object UserId -Unique).Count
    OutputDir = (Resolve-Path $OutputDir).Path
} | Format-List
