param(
    [string]$OrgAlias = "actiprod",
    [string]$OutputDir = "outputs\postventa_advisors_prod_20260604"
)

$ErrorActionPreference = "Stop"
$env:SF_DISABLE_PROGRESS_BAR = "true"
$env:SFDX_DISABLE_PROGRESS_BAR = "true"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$advisorIds = @(
    '64635','63875','66','52275','63845','63658','63480','52841','90158','63967','5412','50409','65065','52230','62639','64537','5506','60349','64774','52377','6431','10016','52236','50166','65142','63703','63071','63712','60376','61477','60321','52335','64444','64441','63856','52471','50755','52406','63601','63498','60308','62185','52518','52331','61220','50385','62642','63167','295','64452','22','64153','51294','52458','61108','51288','64052','64767','66436','62134','66431','63646','60714','67313','64711','61230','64964','62009','60370','60834','66549','52334','51471','67387','63575','64772','60357','62852','64073','60248','62300','65334','66600','65215','65265','65214','65271','67386','65244','65172','67359','67358','65270','69181','65035','64600','66432','64618','68655','66805','63897','66531','50653','66529','66666','64692','67052','67609','66433','66400','66568','68267','68659','69679','67845','68741','65416','65281','66872','67588','69341','69722','67876','69358','67583','68664','67877','67943','68182','68071','69535','69266','69319','69132','68742','65052','67357','64891','62709','52294','52287','97823','60603','62952','50401','60420','60483','62674','64031','52652','97229','90034','97039','62806','50922','62181','52415','62302','98060','97344','60686','62708','62774','64461','64458','60668','97013','61373','64775','65111','65126','65259','67371','67844','67780','65342','66856','66500','66279','65403','66351','65304','65156','65141','65118','63901','67880','68170','67351','63174','67912','65260','62840','68081','68261','68652','69468','69656','69617','69738','69735','69733','69744','69796','80103','80335','80476','80603','80574','80338','80852','80928','69862','80667'
)

function Quote-InList([string[]]$values) {
    return "'" + (($values | ForEach-Object { $_.Replace("'", "\'") }) -join "','") + "'"
}

function Invoke-SfQuery([string]$name, [string]$query, [switch]$Optional) {
    $jsonPath = Join-Path $OutputDir "$name.json"
    $errPath = Join-Path $OutputDir "$name.err.txt"
    $compactQuery = ($query -replace "\s+", " ").Trim()
    try {
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
    } catch {
        if ($Optional) {
            "OPTIONAL QUERY FAILED: $name`r`n$($_.Exception.Message)`r`n$compactQuery" | Set-Content -Path $errPath -Encoding UTF8
            return @()
        }
        throw
    }
}

function Get-Field($obj, [string]$field) {
    if ($null -eq $obj) { return $null }
    $prop = $obj.PSObject.Properties[$field]
    if ($prop) { return $prop.Value }
    return $null
}

function Build-CountMap($records, [string]$keyField, [string]$countField) {
    $map = @{}
    foreach ($record in @($records)) {
        $key = [string](Get-Field $record $keyField)
        if ([string]::IsNullOrWhiteSpace($key)) { continue }
        $map[$key] = [int](Get-Field $record $countField)
    }
    return $map
}

$idIn = Quote-InList $advisorIds
$today = Get-Date -Format "yyyy-MM-dd"
$monthStart = (Get-Date -Day 1).ToString("yyyy-MM-dd")
$nextMonthStart = (Get-Date -Day 1).AddMonths(1).ToString("yyyy-MM-dd")

$users = Invoke-SfQuery "users" @"
SELECT Id, Name, IsActive, Username, Email, ID_ASESOR__c, EmployeeNumber, UserRole.Name, Profile.Name
FROM User
WHERE ID_ASESOR__c IN ($idIn) OR EmployeeNumber IN ($idIn)
ORDER BY Name
"@

$userIds = @($users | ForEach-Object { $_.Id } | Where-Object { $_ })
$userIdIn = if ($userIds.Count -gt 0) { Quote-InList $userIds } else { "''" }

$psa = Invoke-SfQuery "permission_set_assignments" @"
SELECT AssigneeId, PermissionSetId, PermissionSet.Name, PermissionSet.Label
FROM PermissionSetAssignment
WHERE AssigneeId IN ($userIdIn)
ORDER BY PermissionSet.Label
"@

$psl = Invoke-SfQuery "permission_set_license_assignments" @"
SELECT AssigneeId, PermissionSetLicense.DeveloperName, PermissionSetLicense.MasterLabel
FROM PermissionSetLicenseAssign
WHERE AssigneeId IN ($userIdIn)
ORDER BY PermissionSetLicense.MasterLabel
"@ -Optional

$groups = Invoke-SfQuery "public_group_memberships" @"
SELECT UserOrGroupId, Group.Name, Group.DeveloperName, Group.Type
FROM GroupMember
WHERE UserOrGroupId IN ($userIdIn)
ORDER BY Group.Name
"@ -Optional

$bankers = Invoke-SfQuery "bankers" @"
SELECT Id, Name, JobCode, ExternalId__c, Division__c, CurrentBranchId, CurrentBranch.Name, CurrentBranch.BranchCode, UserOrContactId
FROM Banker
WHERE ExternalId__c IN ($idIn) OR JobCode IN ($idIn)
ORDER BY Name
"@ -Optional

$bankerIds = @($bankers | ForEach-Object { $_.Id } | Where-Object { $_ })
$bankerIdIn = if ($bankerIds.Count -gt 0) { Quote-InList $bankerIds } else { "''" }

$branchMembers = Invoke-SfQuery "branch_unit_members" @"
SELECT Id, Name, BranchUnitId, BranchUnit.Name, BranchUnit.BranchCode, BusinessUnitMemberId
FROM BranchUnitBusinessMember
WHERE BusinessUnitMemberId IN ($bankerIdIn)
ORDER BY BranchUnit.Name
"@ -Optional

$contractConfig = Invoke-SfQuery "contract_config" @"
SELECT TipoContratos__c, EstatusContrato__c
FROM ConfiguracionActinver__c
WHERE RecordType.DeveloperName = 'PSTA_ConfiguracionContratosPostventa'
LIMIT 1
"@ -Optional

$dailyConfigs = Invoke-SfQuery "daily_goal_config" @"
SELECT Segmento__c, ClientesContactarPorDia__c
FROM ConfiguracionActinver__c
WHERE RecordType.DeveloperName = 'ContactoPostventa'
ORDER BY Segmento__c
"@ -Optional

$validContractTypes = @()
$validContractStatuses = @()
if (@($contractConfig).Count -gt 0) {
    $contractConfigRecord = @($contractConfig)[0]
    $validContractTypes = @(([string]$contractConfigRecord.TipoContratos__c).Split(';') | Where-Object { $_ })
    $validContractStatuses = @(([string]$contractConfigRecord.EstatusContrato__c).Split(';') | Where-Object { $_ })
}
$typeIn = if ($validContractTypes.Count -gt 0) { Quote-InList $validContractTypes } else { "''" }
$statusIn = if ($validContractStatuses.Count -gt 0) { Quote-InList $validContractStatuses } else { "''" }

$accountCounts = Invoke-SfQuery "account_counts" @"
SELECT ID_Asesor__c advisorId, COUNT(Id) total
FROM Account
WHERE ID_Asesor__c IN ($idIn)
GROUP BY ID_Asesor__c
"@

$eligiblePortfolio = Invoke-SfQuery "eligible_portfolio_counts" @"
SELECT Account.ID_Asesor__c advisorId, COUNT_DISTINCT(AccountId) total
FROM Contract
WHERE AccountId != null
AND Account.ID_Asesor__c IN ($idIn)
AND TypeOfContract__c IN ($typeIn)
AND Status__c IN ($statusIn)
GROUP BY Account.ID_Asesor__c
"@ -Optional

$monthlyPrioritized = Invoke-SfQuery "monthly_prioritized_counts" @"
SELECT ID_Asesor__c advisorId, COUNT(Id) total
FROM Account
WHERE ID_Asesor__c IN ($idIn)
AND ContactoPriorizadoEsteMes__c = true
GROUP BY ID_Asesor__c
"@

$toContactAccumulated = Invoke-SfQuery "to_contact_accumulated_counts" @"
SELECT ID_Asesor__c advisorId, COUNT(Id) total
FROM Account
WHERE ID_Asesor__c IN ($idIn)
AND FechaSiguienteContacto__c <= TODAY
AND EstatusContacto__c = 'Pendiente'
AND NoRequiereSerContactado__c = false
AND PriorizacionContacto__c = true
AND ContactoPriorizadoEsteMes__c = true
GROUP BY ID_Asesor__c
"@

$toContactTodayOnly = Invoke-SfQuery "to_contact_today_only_counts" @"
SELECT ID_Asesor__c advisorId, COUNT(Id) total
FROM Account
WHERE ID_Asesor__c IN ($idIn)
AND FechaSiguienteContacto__c = TODAY
AND EstatusContacto__c = 'Pendiente'
AND NoRequiereSerContactado__c = false
AND PriorizacionContacto__c = true
AND ContactoPriorizadoEsteMes__c = true
GROUP BY ID_Asesor__c
"@

$toContactPrevious = Invoke-SfQuery "to_contact_previous_accumulated_counts" @"
SELECT ID_Asesor__c advisorId, COUNT(Id) total
FROM Account
WHERE ID_Asesor__c IN ($idIn)
AND FechaSiguienteContacto__c < TODAY
AND EstatusContacto__c = 'Pendiente'
AND NoRequiereSerContactado__c = false
AND PriorizacionContacto__c = true
AND ContactoPriorizadoEsteMes__c = true
GROUP BY ID_Asesor__c
"@

$summaryToday = Invoke-SfQuery "summary_today" @"
SELECT Id, ExternalId_Nomina__c, Fecha__c, Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c, PorcentajeAvanceMensual__c, Owner.Name
FROM ResumenGlobalPostventa__c
WHERE ExternalId_Nomina__c IN ($idIn)
AND Fecha__c = $today
ORDER BY ExternalId_Nomina__c
"@ -Optional

$summaryMonth = Invoke-SfQuery "summary_month" @"
SELECT Id, ExternalId_Nomina__c, Fecha__c, Meta__c, MetaMensual__c, Contactados__c, ContactadosMensual__c, PorcentajeAvanceMensual__c, Owner.Name
FROM ResumenGlobalPostventa__c
WHERE ExternalId_Nomina__c IN ($idIn)
AND Fecha__c >= $monthStart
AND Fecha__c < $nextMonthStart
ORDER BY ExternalId_Nomina__c, Fecha__c DESC
"@ -Optional

$psaByUser = @{}
$targetPermissionSetId = "0PSWP0000004b0z4AA"
$targetPermissionSetByUser = @{}
foreach ($row in @($psa)) {
    $label = if ($row.PermissionSet -and $row.PermissionSet.Label) { $row.PermissionSet.Label } else { $row.PermissionSet.Name }
    if (!$psaByUser.ContainsKey($row.AssigneeId)) { $psaByUser[$row.AssigneeId] = @() }
    $psaByUser[$row.AssigneeId] += $label
    if ([string]$row.PermissionSetId -eq $targetPermissionSetId) {
        $targetPermissionSetByUser[$row.AssigneeId] = $true
    }
}
$pslByUser = @{}
foreach ($row in @($psl)) {
    $label = if ($row.PermissionSetLicense -and $row.PermissionSetLicense.MasterLabel) { $row.PermissionSetLicense.MasterLabel } else { $row.PermissionSetLicense.DeveloperName }
    if (!$pslByUser.ContainsKey($row.AssigneeId)) { $pslByUser[$row.AssigneeId] = @() }
    $pslByUser[$row.AssigneeId] += $label
}
$groupsByUser = @{}
foreach ($row in @($groups)) {
    $label = if ($row.Group) { "$($row.Group.Name) [$($row.Group.Type)]" } else { "" }
    if (!$groupsByUser.ContainsKey($row.UserOrGroupId)) { $groupsByUser[$row.UserOrGroupId] = @() }
    $groupsByUser[$row.UserOrGroupId] += $label
}
$bankersByUser = @{}
$bankersByAdvisor = @{}
$bankerListsByUser = @{}
$bankerListsByAdvisor = @{}
foreach ($banker in @($bankers)) {
    if ($banker.UserOrContactId) { $bankersByUser[$banker.UserOrContactId] = $banker }
    if ($banker.ExternalId__c) { $bankersByAdvisor[[string]$banker.ExternalId__c] = $banker }
    if ($banker.JobCode) { $bankersByAdvisor[[string]$banker.JobCode] = $banker }
    if ($banker.UserOrContactId) {
        if (!$bankerListsByUser.ContainsKey($banker.UserOrContactId)) { $bankerListsByUser[$banker.UserOrContactId] = @() }
        $bankerListsByUser[$banker.UserOrContactId] += $banker
    }
    foreach ($advisorKey in @($banker.ExternalId__c, $banker.JobCode) | Where-Object { $_ } | Select-Object -Unique) {
        $advisorKey = [string]$advisorKey
        if (!$bankerListsByAdvisor.ContainsKey($advisorKey)) { $bankerListsByAdvisor[$advisorKey] = @() }
        $bankerListsByAdvisor[$advisorKey] += $banker
    }
}
$branchByBanker = @{}
foreach ($member in @($branchMembers)) {
    if (!$branchByBanker.ContainsKey($member.BusinessUnitMemberId)) { $branchByBanker[$member.BusinessUnitMemberId] = @() }
    $branchLabel = if ($member.BranchUnit) { "$($member.BranchUnit.Name) ($($member.BranchUnit.BranchCode))" } else { $member.Name }
    $branchByBanker[$member.BusinessUnitMemberId] += $branchLabel
}
$dailyGoalBySegment = @{}
foreach ($config in @($dailyConfigs)) {
    if ($config.Segmento__c) { $dailyGoalBySegment[[string]$config.Segmento__c] = $config.ClientesContactarPorDia__c }
}

$accountMap = Build-CountMap $accountCounts "advisorId" "total"
$eligibleMap = Build-CountMap $eligiblePortfolio "advisorId" "total"
$monthlyMap = Build-CountMap $monthlyPrioritized "advisorId" "total"
$toContactMap = Build-CountMap $toContactAccumulated "advisorId" "total"
$todayOnlyMap = Build-CountMap $toContactTodayOnly "advisorId" "total"
$previousMap = Build-CountMap $toContactPrevious "advisorId" "total"

$summaryTodayByAdvisor = @{}
foreach ($s in @($summaryToday)) { $summaryTodayByAdvisor[[string]$s.ExternalId_Nomina__c] = $s }
$latestSummaryByAdvisor = @{}
foreach ($s in @($summaryMonth)) {
    $advisor = [string]$s.ExternalId_Nomina__c
    if (!$latestSummaryByAdvisor.ContainsKey($advisor)) { $latestSummaryByAdvisor[$advisor] = $s }
}

$usersByAdvisor = @{}
foreach ($u in @($users)) {
    $keys = @()
    if ($advisorIds -contains [string]$u.ID_ASESOR__c) { $keys += [string]$u.ID_ASESOR__c }
    if ($advisorIds -contains [string]$u.EmployeeNumber) { $keys += [string]$u.EmployeeNumber }
    foreach ($key in ($keys | Select-Object -Unique)) {
        if (!$usersByAdvisor.ContainsKey($key)) { $usersByAdvisor[$key] = @() }
        $usersByAdvisor[$key] += $u
    }
}

$userRows = foreach ($advisorId in $advisorIds) {
    $matchedUsers = if ($usersByAdvisor.ContainsKey($advisorId)) { @($usersByAdvisor[$advisorId]) } else { @() }
    if ($matchedUsers.Count -eq 0) {
        [pscustomobject]@{
            AdvisorIdBuscado = $advisorId
            UserId = ""
            NombreCompleto = "NO ENCONTRADO"
            ID_ASESOR__c = ""
            EmployeeNumber = ""
            Activo = ""
            Rol = ""
            Perfil = ""
            PermissionSetLicenses = ""
            PermissionSets = ""
            PublicGroupsDirectos = ""
            BankerId = ""
            BankerName = ""
            BankerDivision = ""
            BranchUnitMember = ""
        }
        continue
    }
    foreach ($u in $matchedUsers) {
        $matchedBankers = @()
        if ($bankerListsByUser.ContainsKey($u.Id)) { $matchedBankers += @($bankerListsByUser[$u.Id]) }
        if ($bankerListsByAdvisor.ContainsKey($advisorId)) { $matchedBankers += @($bankerListsByAdvisor[$advisorId]) }
        $matchedBankers = @($matchedBankers | Where-Object { $_ } | Sort-Object Id -Unique)
        $banker = if ($matchedBankers.Count -gt 0) { $matchedBankers[0] } elseif ($bankersByUser.ContainsKey($u.Id)) { $bankersByUser[$u.Id] } elseif ($bankersByAdvisor.ContainsKey($advisorId)) { $bankersByAdvisor[$advisorId] } else { $null }
        $branches = @()
        foreach ($matchedBanker in $matchedBankers) {
            if ($branchByBanker.ContainsKey($matchedBanker.Id)) {
                $branches += $branchByBanker[$matchedBanker.Id]
            }
        }
        if ($branches.Count -eq 0 -and $banker -and $branchByBanker.ContainsKey($banker.Id)) {
            $branches += $branchByBanker[$banker.Id]
        }
        $bankerLabels = @($matchedBankers | ForEach-Object { "$($_.Id) - $($_.Name) - Ext:$($_.ExternalId__c) - Job:$($_.JobCode) - Division:$($_.Division__c)" } | Sort-Object -Unique)
        [pscustomobject]@{
            AdvisorIdBuscado = $advisorId
            UserId = $u.Id
            NombreCompleto = $u.Name
            ID_ASESOR__c = $u.ID_ASESOR__c
            EmployeeNumber = $u.EmployeeNumber
            Activo = $u.IsActive
            Rol = if ($u.UserRole) { $u.UserRole.Name } else { "" }
            Perfil = if ($u.Profile) { $u.Profile.Name } else { "" }
            PermissionSetLicenses = if ($pslByUser.ContainsKey($u.Id)) { ($pslByUser[$u.Id] | Sort-Object -Unique) -join " | " } else { "" }
            PermissionSets = if ($psaByUser.ContainsKey($u.Id)) { ($psaByUser[$u.Id] | Sort-Object -Unique) -join " | " } else { "" }
            TienePermissionSet_0PSWP0000004b0z4AA = if ($targetPermissionSetByUser.ContainsKey($u.Id)) { "Si" } else { "No" }
            PublicGroupsDirectos = if ($groupsByUser.ContainsKey($u.Id)) { ($groupsByUser[$u.Id] | Sort-Object -Unique) -join " | " } else { "" }
            CantidadBankers = $matchedBankers.Count
            TieneMasDeUnBanker = if ($matchedBankers.Count -gt 1) { "Si" } else { "No" }
            BankersEncontrados = $bankerLabels -join " | "
            BankerId = if ($banker) { $banker.Id } else { "" }
            BankerName = if ($banker) { $banker.Name } else { "" }
            BankerDivision = if ($banker) { $banker.Division__c } else { "" }
            BranchUnitMember = ($branches | Sort-Object -Unique) -join " | "
        }
    }
}

$analysisRows = foreach ($advisorId in $advisorIds) {
    $summary = if ($summaryTodayByAdvisor.ContainsKey($advisorId)) { $summaryTodayByAdvisor[$advisorId] } elseif ($latestSummaryByAdvisor.ContainsKey($advisorId)) { $latestSummaryByAdvisor[$advisorId] } else { $null }
    $userNames = if ($usersByAdvisor.ContainsKey($advisorId)) { (@($usersByAdvisor[$advisorId]) | ForEach-Object { $_.Name } | Sort-Object -Unique) -join " | " } else { "" }
    $banker = if ($bankersByAdvisor.ContainsKey($advisorId)) { $bankersByAdvisor[$advisorId] } else { $null }
    $segment = if ($banker -and $banker.Division__c) { [string]$banker.Division__c } else { "" }
    [pscustomobject]@{
        AdvisorId = $advisorId
        NombreUsuario = $userNames
        BankerName = if ($banker) { $banker.Name } else { "" }
        DivisionBanker = $segment
        MetaDiariaConfiguracionSegmento = if (![string]::IsNullOrWhiteSpace($segment) -and $dailyGoalBySegment.ContainsKey($segment)) { $dailyGoalBySegment[$segment] } else { "" }
        CuentasAsignadas = if ($accountMap.ContainsKey($advisorId)) { $accountMap[$advisorId] } else { 0 }
        CarteraElegibleContratosConfig = if ($eligibleMap.ContainsKey($advisorId)) { $eligibleMap[$advisorId] } else { 0 }
        PriorizadosMesActual = if ($monthlyMap.ContainsKey($advisorId)) { $monthlyMap[$advisorId] } else { 0 }
        ListaContactarHoyAcumulada = if ($toContactMap.ContainsKey($advisorId)) { $toContactMap[$advisorId] } else { 0 }
        ListaContactarSoloHoy = if ($todayOnlyMap.ContainsKey($advisorId)) { $todayOnlyMap[$advisorId] } else { 0 }
        ListaContactarAcumuladoPrevio = if ($previousMap.ContainsKey($advisorId)) { $previousMap[$advisorId] } else { 0 }
        Cubre10ContactarHoy = if ($toContactMap.ContainsKey($advisorId) -and $toContactMap[$advisorId] -ge 10) { "Si" } else { "No" }
        ResumenFecha = if ($summary) { $summary.Fecha__c } else { "" }
        MetaDiariaResumen = if ($summary) { $summary.Meta__c } else { "" }
        MetaMensualResumen = if ($summary) { $summary.MetaMensual__c } else { "" }
        ContactadosDiaResumen = if ($summary) { $summary.Contactados__c } else { "" }
        ContactadosMensualResumen = if ($summary) { $summary.ContactadosMensual__c } else { "" }
        PorcentajeAvanceMensualResumen = if ($summary) { $summary.PorcentajeAvanceMensual__c } else { "" }
    }
}

$configRows = @()
$configRows += [pscustomobject]@{ Tipo = "Contratos validos"; Nombre = "TipoContratos__c"; Valor = ($validContractTypes -join ";") }
$configRows += [pscustomobject]@{ Tipo = "Contratos validos"; Nombre = "EstatusContrato__c"; Valor = ($validContractStatuses -join ";") }
foreach ($config in @($dailyConfigs)) {
    $configRows += [pscustomobject]@{ Tipo = "Meta diaria por segmento"; Nombre = $config.Segmento__c; Valor = $config.ClientesContactarPorDia__c }
}

$userRows | Export-Csv -Path (Join-Path $OutputDir "usuarios_accesos_branch_prod.csv") -NoTypeInformation -Encoding UTF8
$analysisRows | Export-Csv -Path (Join-Path $OutputDir "segmentacion_metas_prod.csv") -NoTypeInformation -Encoding UTF8
$configRows | Export-Csv -Path (Join-Path $OutputDir "configuracion_usada_prod.csv") -NoTypeInformation -Encoding UTF8

$summaryOutput = [pscustomobject]@{
    OrgAlias = $OrgAlias
    FechaEjecucionLocal = (Get-Date).ToString("s")
    AdvisorsSolicitados = $advisorIds.Count
    UsuariosEncontrados = @($users).Count
    AdvisorsConUsuario = $usersByAdvisor.Keys.Count
    AdvisorsSinUsuario = ($advisorIds.Count - $usersByAdvisor.Keys.Count)
    OutputDir = (Resolve-Path $OutputDir).Path
}
$summaryOutput | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $OutputDir "resumen.json") -Encoding UTF8
$summaryOutput | Format-List
