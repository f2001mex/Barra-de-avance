param(
    [string]$TargetOrg = "https://actinvertrial--fullprodu.sandbox.my.salesforce.com/",
    [string]$CadenceId = "77CWP0000000hJV2AY",
    [string]$StaleStepTitle = "Perspectiva Actinver",
    [string]$OwnerId,
    [string]$ExcludeOwnerId,
    [int]$BatchSize = 100,
    [int]$ProbeCount = 1,
    [switch]$ExecuteAll
)

$ErrorActionPreference = "Stop"

function Get-OrgSession {
    $org = sf org display --target-org $TargetOrg --verbose --json | ConvertFrom-Json
    if (-not $org.result) {
        throw "No se pudo obtener la sesion del org."
    }

    return @{
        AccessToken = $org.result.accessToken
        InstanceUrl = $org.result.instanceUrl.TrimEnd('/')
    }
}

function Invoke-SalesforceAction {
    param(
        [hashtable]$Session,
        [string]$ActionName,
        [array]$Inputs
    )

    $uri = "$($Session.InstanceUrl)/services/data/v66.0/actions/standard/$ActionName"
    $headers = @{
        Authorization = "Bearer $($Session.AccessToken)"
        "Content-Type" = "application/json"
    }
    $body = @{ inputs = $Inputs } | ConvertTo-Json -Depth 6
    return Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
}

function Get-AffectedTrackers {
    $query = "SELECT Id, TargetId, OwnerId, CreatedDate " +
        "FROM ActionCadenceTracker " +
        "WHERE ActionCadenceId = '$CadenceId' " +
        "AND State = 'Running' " +
        "AND Id IN (SELECT ActionCadenceTrackerId FROM ActionCadenceStepTracker WHERE StepTitle = '$StaleStepTitle') "

    if ($OwnerId) {
        $query += "AND OwnerId = '$OwnerId' "
    }

    if ($ExcludeOwnerId) {
        $query += "AND OwnerId != '$ExcludeOwnerId' "
    }

    $query +=
        "ORDER BY CreatedDate DESC"

    $result = sf data query --target-org $TargetOrg --query $query --json | ConvertFrom-Json
    if (-not $result.result) {
        throw "No se pudieron obtener los trackers afectados."
    }

    return $result.result.records
}

function Get-LatestTrackerSnapshot {
    param(
        [string]$TargetId
    )

    $query = "SELECT Id, State, CreatedDate, " +
        "(SELECT Id, StepTitle, ActionCadenceName, State, CreatedDate FROM ActionCadenceStepTrackers ORDER BY CreatedDate DESC) " +
        "FROM ActionCadenceTracker " +
        "WHERE ActionCadenceId = '$CadenceId' " +
        "AND TargetId = '$TargetId' " +
        "ORDER BY CreatedDate DESC " +
        "LIMIT 1"

    $result = sf data query --target-org $TargetOrg --query $query --json | ConvertFrom-Json
    return $result.result.records
}

$affected = Get-AffectedTrackers
Write-Host ("Trackers activos afectados encontrados: {0}" -f $affected.Count)

if (-not $affected -or $affected.Count -eq 0) {
    return
}

$session = Get-OrgSession

if (-not $ExecuteAll) {
    $probe = @($affected | Select-Object -First $ProbeCount)
    Write-Host ("Ejecutando prueba real con {0} tracker(s)." -f $probe.Count)

    $removeInputs = @()
    foreach ($row in $probe) {
        $removeInputs += @{
            actionCadenceTrackerId = $row.Id
            completionReasonCode = "ManuallyRemoved"
            shouldApplyUserContext = $false
        }
    }

    $removeResponse = Invoke-SalesforceAction -Session $session -ActionName "removeTargetFromSalesCadence" -Inputs $removeInputs
    Write-Host "Respuesta removeTargetFromSalesCadence:"
    $removeResponse | ConvertTo-Json -Depth 8

    $assignInputs = @()
    foreach ($row in $probe) {
        $assignInputs += @{
            salesCadenceNameOrId = $CadenceId
            targetId = $row.TargetId
            userId = $row.OwnerId
        }
    }

    $assignResponse = Invoke-SalesforceAction -Session $session -ActionName "assignTargetToSalesCadence" -Inputs $assignInputs
    Write-Host "Respuesta assignTargetToSalesCadence:"
    $assignResponse | ConvertTo-Json -Depth 8

    foreach ($row in $probe) {
        Write-Host ("Snapshot mas reciente para target {0}:" -f $row.TargetId)
        Get-LatestTrackerSnapshot -TargetId $row.TargetId | ConvertTo-Json -Depth 8
    }
    return
}

$chunks = [System.Collections.Generic.List[object[]]]::new()
for ($i = 0; $i -lt $affected.Count; $i += $BatchSize) {
    $end = [Math]::Min($i + $BatchSize - 1, $affected.Count - 1)
    $chunks.Add($affected[$i..$end])
}

$failedReassignments = [System.Collections.Generic.List[object]]::new()
$failedRemovals = [System.Collections.Generic.List[object]]::new()
$batchNumber = 0
foreach ($chunk in $chunks) {
    $batchNumber++
    Write-Host ("Procesando lote {0}/{1} con {2} tracker(s)." -f $batchNumber, $chunks.Count, $chunk.Count)

    $removeInputs = @()
    foreach ($row in $chunk) {
        $removeInputs += @{
            actionCadenceTrackerId = $row.Id
            completionReasonCode = "ManuallyRemoved"
            shouldApplyUserContext = $false
        }
    }

    $removeResponse = Invoke-SalesforceAction -Session $session -ActionName "removeTargetFromSalesCadence" -Inputs $removeInputs
    $successfulRows = @()
    for ($i = 0; $i -lt $chunk.Count; $i++) {
        $result = @($removeResponse)[$i]
        if ($result.isSuccess) {
            $successfulRows += $chunk[$i]
            continue
        }

        $failedRemovals.Add([PSCustomObject]@{
                batchNumber = $batchNumber
                trackerId = $chunk[$i].Id
                targetId = $chunk[$i].TargetId
                ownerId = $chunk[$i].OwnerId
                error = (($result.errors | ForEach-Object { $_.message }) -join ' | ')
            })
    }

    $assignInputs = @()
    foreach ($row in $successfulRows) {
        $assignInputs += @{
            salesCadenceNameOrId = $CadenceId
            targetId = $row.TargetId
            userId = $row.OwnerId
        }
    }

    if ($assignInputs.Count -eq 0) {
        continue
    }

    $assignResponse = Invoke-SalesforceAction -Session $session -ActionName "assignTargetToSalesCadence" -Inputs $assignInputs
    for ($i = 0; $i -lt $successfulRows.Count; $i++) {
        $result = @($assignResponse)[$i]
        if ($result.isSuccess) {
            continue
        }

        $failedReassignments.Add([PSCustomObject]@{
                batchNumber = $batchNumber
                trackerId = $successfulRows[$i].Id
                targetId = $successfulRows[$i].TargetId
                ownerId = $successfulRows[$i].OwnerId
                error = (($result.errors | ForEach-Object { $_.message }) -join ' | ')
            })
        Write-Warning ("No se pudo reasignar TargetId {0} con OwnerId {1}: {2}" -f $successfulRows[$i].TargetId, $successfulRows[$i].OwnerId, (($result.errors | ForEach-Object { $_.message }) -join ' | '))
    }
}

Write-Host ("Correccion completada. Trackers reprocesados: {0}" -f $affected.Count)
if ($failedRemovals.Count -gt 0 -or $failedReassignments.Count -gt 0) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $failurePath = Join-Path $PSScriptRoot ("refresh_contacto_integral_failures_{0}.json" -f $timestamp)
    [PSCustomObject]@{
        failedRemovals = $failedRemovals
        failedReassignments = $failedReassignments
    } | ConvertTo-Json -Depth 8 | Set-Content -Path $failurePath
    Write-Warning ("Se registraron fallos en: {0}" -f $failurePath)
}
