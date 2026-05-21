$rows = @(
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Apex Class'
        ApiName = 'PSTA_AntiChurnDashboard_ctr'
        VisibleName = 'PSTA_AntiChurnDashboard_ctr'
        RequiredFor = 'Controller del dashboard'
        Notes = 'Calcula KPIs, alcance por usuario y resuelve reportes'
        LocalPath = 'force-app/main/default/classes/PSTA_AntiChurnDashboard_ctr.cls'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Apex Class'
        ApiName = 'PSTA_AntiChurnDashboard_ctr_tst'
        VisibleName = 'PSTA_AntiChurnDashboard_ctr_tst'
        RequiredFor = 'Prueba'
        Notes = 'Prueba del controller del dashboard'
        LocalPath = 'force-app/main/default/classes/PSTA_AntiChurnDashboard_ctr_tst.cls'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Lightning Component Bundle'
        ApiName = 'actAntiChurnDashboard'
        VisibleName = 'Dashboard Anti-Churn'
        RequiredFor = 'UI'
        Notes = 'LWC principal del dashboard'
        LocalPath = 'force-app/main/default/lwc/actAntiChurnDashboard'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'FlexiPage'
        ApiName = 'P_gina_de_inicio_predeterminada'
        VisibleName = 'Home de Bancas'
        RequiredFor = 'Ubicacion en Home'
        Notes = 'Agrega la pestana Dashboard Anti-Churn y referencia c:actAntiChurnDashboard'
        LocalPath = 'force-app/main/default/flexipages/P_gina_de_inicio_predeterminada.flexipage-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Custom Report Type'
        ApiName = 'ACT_AntiChurn_Account_Activity_User__c'
        VisibleName = 'Anti Churn - Accounts, Activities and Users'
        RequiredFor = 'Base de reportes'
        Notes = 'CRT de Activity con joins a Account y User'
        LocalPath = 'force-app/main/default/reportTypes/ACT_AntiChurn_Account_Activity_User.reportType-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Report Folder'
        ApiName = 'AntiChurn'
        VisibleName = 'Anti Churn'
        RequiredFor = 'Contenedor de reportes'
        Notes = 'Folder donde el Apex busca los reportes por FolderName = Anti Churn'
        LocalPath = 'force-app/main/default/reports/AntiChurn.reportFolder-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Report'
        ApiName = 'AntiChurn/Clientes_con_alto_riesgo_de_fuga_hh1'
        VisibleName = 'Clientes con alto riesgo de fuga'
        RequiredFor = 'Boton de reporte'
        Notes = 'Reporte de cuentas con riesgo alto; DeveloperName usado por Apex'
        LocalPath = 'force-app/main/default/reports/AntiChurn/Clientes_con_alto_riesgo_de_fuga_hh1.report-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Obligatorio'
        ComponentType = 'Report'
        ApiName = 'AntiChurn/Clientes_con_alto_riesgo_de_fuga_ANM'
        VisibleName = 'Actividades ANTI CHURN'
        RequiredFor = 'Boton de reporte'
        Notes = 'Reporte de actividades Anti Churn; DeveloperName usado por Apex'
        LocalPath = 'force-app/main/default/reports/AntiChurn/Clientes_con_alto_riesgo_de_fuga_ANM.report-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Permisos'
        ComponentType = 'Permission Set'
        ApiName = 'CHURN_Account'
        VisibleName = 'CHURN_Account'
        RequiredFor = 'Acceso'
        Notes = 'Da acceso a Apex, campos CHURN y RecordType Task.Anti_Churn'
        LocalPath = 'force-app/main/default/permissionsets/CHURN_Account.permissionset-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Dependencia'
        ComponentType = 'Record Type'
        ApiName = 'Task.Anti_Churn'
        VisibleName = 'Anti Churn'
        RequiredFor = 'Filtro de datos'
        Notes = 'El Apex busca DeveloperName = Anti_Churn en Task'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Task.Resultado_de_Gestion__c'
        VisibleName = 'Resultado de Gestion'
        RequiredFor = 'KPI'
        Notes = 'Actividades positivas, negativas, sin contacto y nulas'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Task.Motivo_de_fuga__c'
        VisibleName = 'Motivo de fuga'
        RequiredFor = 'Grafica'
        Notes = 'Motivo de fuga identificado'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Task.Tiempo_promedio_de_contacto_CHURN__c'
        VisibleName = 'Tiempo promedio de contacto CHURN'
        RequiredFor = 'KPI'
        Notes = 'Tiempo promedio de contacto'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Task.Fecha_de_contactacion__c'
        VisibleName = 'Fecha de contactacion'
        RequiredFor = 'KPI y reporte'
        Notes = 'Usado por reportes y por el modelo de datos del dashboard'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Account.Indicador_de_Riesgo_Churn__c'
        VisibleName = 'Indicador de Riesgo Churn'
        RequiredFor = 'KPI'
        Notes = 'Clientes en riesgo alto con actividad asignada'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Account.Semaforo_riesgo_fuga_churn__c'
        VisibleName = 'Semaforo riesgo fuga churn'
        RequiredFor = 'Reporte'
        Notes = 'Visible en reportes'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Account.Probabilidad_Abandono__c'
        VisibleName = 'Probabilidad Abandono'
        RequiredFor = 'Reporte'
        Notes = 'Visible en reportes y CRT'
        LocalPath = 'force-app/main/default/objects/Account/fields/Probabilidad_Abandono__c.field-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Account.BanqueroAsignado__c'
        VisibleName = 'Banquero Asignado'
        RequiredFor = 'Alcance'
        Notes = 'Filtro por sucursal via BranchUnitId del BBM'
        LocalPath = 'force-app/main/default/objects/Account/fields/BanqueroAsignado__c.field-meta.xml'
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'Account.ID_ASESOR__c'
        VisibleName = 'ID ASESOR'
        RequiredFor = 'Alcance'
        Notes = 'Filtro por asesor y equipo'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'User.ID_ASESOR__c'
        VisibleName = 'ID ASESOR'
        RequiredFor = 'Alcance'
        Notes = 'Define alcance por asesor y por arbol de rol'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'User.F3_Sucursal__c'
        VisibleName = 'Sucursal'
        RequiredFor = 'Fallback de alcance'
        Notes = 'Usado para resolver sucursal si no hay Banker directo'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'User.REQ36_Centro_Financiero__c'
        VisibleName = 'Centro Financiero'
        RequiredFor = 'Fallback de alcance'
        Notes = 'Usado para resolver BranchUnit por nombre'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Campo usado'
        ComponentType = 'Custom Field'
        ApiName = 'User.F3_Division__c'
        VisibleName = 'Division'
        RequiredFor = 'Reporte'
        Notes = 'Grouping del reporte por division del usuario propietario'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Dependencia'
        ComponentType = 'Standard/Custom Object'
        ApiName = 'Banker.CurrentBranchId'
        VisibleName = 'Current Branch'
        RequiredFor = 'Alcance'
        Notes = 'El Apex usa Banker para obtener la sucursal del usuario'
        LocalPath = ''
    }
    [pscustomobject]@{
        Category = 'Dependencia'
        ComponentType = 'Standard/Custom Object'
        ApiName = 'BranchUnit'
        VisibleName = 'BranchUnit'
        RequiredFor = 'Alcance'
        Notes = 'Resolve por Id, Name, BranchCode, ExternalId__c y ExternalIdBI__c'
        LocalPath = ''
    }
)

$outputDir = Join-Path $PSScriptRoot '..\output'
$resolvedOutputDir = [System.IO.Path]::GetFullPath($outputDir)
if (-not (Test-Path $resolvedOutputDir)) {
    New-Item -ItemType Directory -Path $resolvedOutputDir | Out-Null
}

$xlsxPath = Join-Path $resolvedOutputDir 'Dashboard_AntiChurn_Inventory.xlsx'
$xmlPath = Join-Path $resolvedOutputDir 'Dashboard_AntiChurn_Inventory.xml'

function Save-AsExcelXml {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Data,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $headers = @('Category', 'ComponentType', 'ApiName', 'VisibleName', 'RequiredFor', 'Notes', 'LocalPath')
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0"?>')
    [void]$sb.AppendLine('<?mso-application progid="Excel.Sheet"?>')
    [void]$sb.AppendLine('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
    [void]$sb.AppendLine('  <Worksheet ss:Name="AntiChurn Inventory">')
    [void]$sb.AppendLine('    <Table>')

    [void]$sb.AppendLine('      <Row>')
    foreach ($header in $headers) {
        $escapedHeader = [System.Security.SecurityElement]::Escape($header)
        [void]$sb.AppendLine("        <Cell><Data ss:Type=""String"">$escapedHeader</Data></Cell>")
    }
    [void]$sb.AppendLine('      </Row>')

    foreach ($row in $Data) {
        [void]$sb.AppendLine('      <Row>')
        foreach ($header in $headers) {
            $value = [string]$row.$header
            $escapedValue = [System.Security.SecurityElement]::Escape($value)
            [void]$sb.AppendLine("        <Cell><Data ss:Type=""String"">$escapedValue</Data></Cell>")
        }
        [void]$sb.AppendLine('      </Row>')
    }

    [void]$sb.AppendLine('    </Table>')
    [void]$sb.AppendLine('  </Worksheet>')
    [void]$sb.AppendLine('</Workbook>')

    [System.IO.File]::WriteAllText($Path, $sb.ToString(), [System.Text.Encoding]::UTF8)
}

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $workbook = $excel.Workbooks.Add()
    $worksheet = $workbook.Worksheets.Item(1)
    $worksheet.Name = 'AntiChurn Inventory'

    $headers = @('Category', 'ComponentType', 'ApiName', 'VisibleName', 'RequiredFor', 'Notes', 'LocalPath')
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $worksheet.Cells.Item(1, $i + 1) = $headers[$i]
    }

    $rowIndex = 2
    foreach ($row in $rows) {
        $worksheet.Cells.Item($rowIndex, 1) = $row.Category
        $worksheet.Cells.Item($rowIndex, 2) = $row.ComponentType
        $worksheet.Cells.Item($rowIndex, 3) = $row.ApiName
        $worksheet.Cells.Item($rowIndex, 4) = $row.VisibleName
        $worksheet.Cells.Item($rowIndex, 5) = $row.RequiredFor
        $worksheet.Cells.Item($rowIndex, 6) = $row.Notes
        $worksheet.Cells.Item($rowIndex, 7) = $row.LocalPath
        $rowIndex++
    }

    $headerRange = $worksheet.Range('A1', 'G1')
    $headerRange.Font.Bold = $true
    $headerRange.Interior.ColorIndex = 15
    $worksheet.Columns.AutoFit() | Out-Null

    $workbook.SaveAs($xlsxPath, 51)
    $workbook.Close($false)
    $excel.Quit()

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($headerRange) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($worksheet) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null

    Write-Output $xlsxPath
}
catch {
    if ($workbook) { $workbook.Close($false) }
    if ($excel) { $excel.Quit() }
    Save-AsExcelXml -Data $rows -Path $xmlPath
    Write-Output $xmlPath
}
