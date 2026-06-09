param(
    [string]$OrgAlias = "actiprod",
    [string]$OutputDir = "outputs\role_hierarchy_directors_prod_20260608"
)

$ErrorActionPreference = "Stop"
$env:SF_DISABLE_PROGRESS_BAR = "true"
$env:SFDX_DISABLE_PROGRESS_BAR = "true"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$advisorIds = @(
    '64635','63875','66','52275','63845','63658','63480','52841','90158','63967','5412','50409','65065','52230','62639','64537','5506','60349','64774','52377','6431','10016','52236','50166','65142','63703','63071','63712','60376','61477','60321','52335','64444','64441','63856','52471','50755','52406','63601','63498','60308','62185','52518','52331','61220','50385','62642','63167','295','64452','22','64153','51294','52458','61108','51288','64052','64767','66436','62134','66431','63646','60714','67313','64711','61230','64964','62009','60370','60834','66549','52334','51471','67387','63575','64772','60357','62852','64073','60248','62300','65334','66600','65215','65265','65214','65271','67386','65244','65172','67359','67358','65270','69181','65035','64600','66432','64618','68655','66805','63897','66531','50653','66529','66666','64692','67052','67609','66433','66400','66568','68267','68659','69679','67845','68741','65416','65281','66872','67588','69341','69722','67876','69358','67583','68664','67877','67943','68182','68071','69535','69266','69319','69132','68742','65052','67357','64891','62709','52294','52287','97823','60603','62952','50401','60420','60483','62674','64031','52652','97229','90034','97039','62806','50922','62181','52415','62302','98060','97344','60686','62708','62774','64461','64458','60668','97013','61373','64775','65111','65126','65259','67371','67844','67780','65342','66856','66500','66279','65403','66351','65304','65156','65141','65118','63901','67880','68170','67351','63174','67912','65260','62840','68081','68261','68652','69468','69656','69617','69738','69735','69733','69744','69796','80103','80335','80476','80603','80574','80338','80852','80928','69862','80667'
)

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

function Escape-Like([string]$value) {
    return $value.Replace("'", "\'")
}

$directorCandidates = Invoke-SfQuery "director_candidates" @"
SELECT Id, Name, IsActive, Username, Email, ID_ASESOR__c, EmployeeNumber, UserRoleId, UserRole.Name, Profile.Name
FROM User
WHERE Name LIKE '%Viesca%' OR Name LIKE '%Pellico%'
ORDER BY Name
"@

$directors = @()
$directors += @($directorCandidates | Where-Object { $_.Name -like '*Rodrigo*Viesca*' } | Select-Object -First 1)
$directors += @($directorCandidates | Where-Object { $_.Name -like '*Jose*Antonio*Pellico*' -or $_.Name -like '*José*Antonio*Pellico*' } | Select-Object -First 1)
$directors = @($directors | Where-Object { $_ })

$roles = Invoke-SfQuery "user_roles" @"
SELECT Id, Name, DeveloperName, ParentRoleId
FROM UserRole
ORDER BY Name
"@

$users = Invoke-SfQuery "users_with_roles" @"
SELECT Id, Name, IsActive, Username, Email, ID_ASESOR__c, EmployeeNumber, UserRoleId, UserRole.Name, Profile.Name
FROM User
WHERE UserRoleId != null
ORDER BY UserRole.Name, Name
"@

$roleById = @{}
$childrenByParent = @{}
foreach ($role in $roles) {
    $roleById[$role.Id] = $role
    $parentId = if ($role.ParentRoleId) { [string]$role.ParentRoleId } else { "" }
    if (!$childrenByParent.ContainsKey($parentId)) { $childrenByParent[$parentId] = @() }
    $childrenByParent[$parentId] += $role
}

$usersByRole = @{}
foreach ($user in $users) {
    if (!$usersByRole.ContainsKey($user.UserRoleId)) { $usersByRole[$user.UserRoleId] = @() }
    $usersByRole[$user.UserRoleId] += $user
}

$advisorSet = @{}
foreach ($advisorId in $advisorIds) { $advisorSet[$advisorId] = $true }

function Get-DescendantRoles([string]$rootRoleId) {
    $result = @()
    $queue = New-Object System.Collections.Queue
    if ($childrenByParent.ContainsKey($rootRoleId)) {
        foreach ($child in $childrenByParent[$rootRoleId]) {
            $queue.Enqueue([pscustomobject]@{ Role = $child; Level = 1 })
        }
    }
    while ($queue.Count -gt 0) {
        $item = $queue.Dequeue()
        $result += $item
        if ($childrenByParent.ContainsKey($item.Role.Id)) {
            foreach ($child in $childrenByParent[$item.Role.Id]) {
                $queue.Enqueue([pscustomobject]@{ Role = $child; Level = ($item.Level + 1) })
            }
        }
    }
    return $result
}

$roleRows = @()
$userRows = @()

foreach ($director in $directors) {
    $rootRole = if ($director.UserRoleId -and $roleById.ContainsKey($director.UserRoleId)) { $roleById[$director.UserRoleId] } else { $null }
    $descendantRoles = if ($rootRole) { @(Get-DescendantRoles $rootRole.Id) } else { @() }
    foreach ($item in $descendantRoles) {
        $role = $item.Role
        $roleUsers = if ($usersByRole.ContainsKey($role.Id)) { @($usersByRole[$role.Id]) } else { @() }
        $roleRows += [pscustomobject]@{
            DirectorSucursal = $director.Name
            DirectorUserId = $director.Id
            DirectorRole = if ($rootRole) { $rootRole.Name } else { "" }
            NivelDebajoDirector = $item.Level
            RoleId = $role.Id
            RoleName = $role.Name
            RoleDeveloperName = $role.DeveloperName
            ParentRoleId = $role.ParentRoleId
            UsuariosEnRol = $roleUsers.Count
            UsuariosActivosEnRol = @($roleUsers | Where-Object { $_.IsActive -eq $true }).Count
        }
        foreach ($user in $roleUsers) {
            $matchedAdvisorId = ""
            $inAdvisorList = "No"
            foreach ($candidate in @($user.ID_ASESOR__c, $user.EmployeeNumber) | Where-Object { $_ }) {
                if ($advisorSet.ContainsKey([string]$candidate)) {
                    $matchedAdvisorId = [string]$candidate
                    $inAdvisorList = "Si"
                    break
                }
            }
            $userRows += [pscustomobject]@{
                DirectorSucursal = $director.Name
                DirectorRole = if ($rootRole) { $rootRole.Name } else { "" }
                NivelDebajoDirector = $item.Level
                RoleName = $role.Name
                RoleDeveloperName = $role.DeveloperName
                UserId = $user.Id
                NombreUsuario = $user.Name
                Activo = $user.IsActive
                Perfil = if ($user.Profile) { $user.Profile.Name } else { "" }
                ID_ASESOR__c = $user.ID_ASESOR__c
                EmployeeNumber = $user.EmployeeNumber
                EstaEnListaIDAsesor = $inAdvisorList
                IDAsesorCoincidente = $matchedAdvisorId
                Username = $user.Username
                Email = $user.Email
            }
        }
    }
}

$summaryRows = foreach ($director in $directors) {
    $directorUserRows = @($userRows | Where-Object { $_.DirectorSucursal -eq $director.Name })
    [pscustomobject]@{
        DirectorSucursal = $director.Name
        DirectorUserId = $director.Id
        DirectorActivo = $director.IsActive
        DirectorRole = if ($director.UserRole) { $director.UserRole.Name } else { "" }
        RolesDebajo = @($roleRows | Where-Object { $_.DirectorSucursal -eq $director.Name }).Count
        UsuariosDebajo = $directorUserRows.Count
        UsuariosActivosDebajo = @($directorUserRows | Where-Object { $_.Activo -eq "True" -or $_.Activo -eq $true }).Count
        UsuariosEnListaIDAsesor = @($directorUserRows | Where-Object { $_.EstaEnListaIDAsesor -eq "Si" }).Count
        UsuariosNoEnListaIDAsesor = @($directorUserRows | Where-Object { $_.EstaEnListaIDAsesor -eq "No" }).Count
    }
}

$directorCandidates | Export-Csv -Path (Join-Path $OutputDir "candidatos_directores_prod.csv") -NoTypeInformation -Encoding UTF8
$summaryRows | Export-Csv -Path (Join-Path $OutputDir "resumen_directores_roles_prod.csv") -NoTypeInformation -Encoding UTF8
$roleRows | Export-Csv -Path (Join-Path $OutputDir "roles_debajo_directores_prod.csv") -NoTypeInformation -Encoding UTF8
$userRows | Export-Csv -Path (Join-Path $OutputDir "usuarios_roles_debajo_directores_prod.csv") -NoTypeInformation -Encoding UTF8

[pscustomobject]@{
    OrgAlias = $OrgAlias
    FechaEjecucionLocal = (Get-Date).ToString("s")
    DirectoresEncontrados = $directors.Count
    UsuariosEnRolesDebajo = $userRows.Count
    OutputDir = (Resolve-Path $OutputDir).Path
} | Format-List
