# ===========================================
# Monitor-Carpeta.ps1
# Monitoreo de recepción de archivos
# ===========================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$configFile = Join-Path $PSScriptRoot "config.json"
$LogFile = Join-Path $PSScriptRoot "Monitor.log"
$ReportFile = Join-Path $PSScriptRoot "salida.txt"

$Credential = $null

if (!(Test-Path $configFile)) {
    Write-Host "No se encontró config.json"
    exit
}

$config = Get-Content $configFile -Encoding UTF8 | ConvertFrom-Json

if ($config.UseEmail -eq $true) {
    if ([string]::IsNullOrWhiteSpace($config.From) -or
        [string]::IsNullOrWhiteSpace($config.To) -or
        [string]::IsNullOrWhiteSpace($config.SMTP_Server) -or
        [string]::IsNullOrWhiteSpace($config.SmtpUser) -or
        [string]::IsNullOrWhiteSpace($config.SmtpPassword)) {
        Write-Host "Falta configuración SMTP. Revisa From, To, SMTP_Server, SmtpUser y SmtpPassword."
        exit
    }

    $Password = ConvertTo-SecureString $config.SmtpPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential(
        $config.SmtpUser,
        $Password
    )
}

$carpetas = @()
if ($config.Folders) {
    $carpetas = @($config.Folders)
}
elseif ($config.MonitorFolder) {
    $carpetas = @($config.MonitorFolder)
}

$modoPrueba = $config.Test

Write-Host "Test = [$modoPrueba]"
Write-Host "Tipo = $($modoPrueba.GetType().Name)"

if (-not $carpetas -or $carpetas.Count -eq 0) {
    Write-Host "No hay carpetas configuradas en config.json"
    exit
}

$limite = (Get-Date).AddHours(-24)
$resumenes = @()
$resumenesCortos = @()
$hayAlertas = $false
$hayCarpetasValidas = $false

foreach ($carpeta in $carpetas) {
    if ([string]::IsNullOrWhiteSpace($carpeta)) {
        continue
    }

    if (!(Test-Path $carpeta)) {
        $resumenes += @"
Carpeta: $carpeta
Estado: ERROR
Detalle: La carpeta configurada no existe.
"@
        $resumenesCortos += "ERROR | $(Split-Path $carpeta -Leaf): carpeta no existe"
        $hayAlertas = $true
        continue
    }

    $hayCarpetasValidas = $true
    $archivos = Get-ChildItem -Path $carpeta -File -ErrorAction SilentlyContinue | Where-Object {
        $_.LastWriteTime -ge $limite
    }

    $cantidad = @($archivos).Count
    $listaArchivos = $archivos |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 50 |
        ForEach-Object {
            "$($_.Name) - $($_.LastWriteTime)"
        }
    $listaArchivosTexto = $listaArchivos -join "`r`n"

    $ultimoArchivo = Get-ChildItem `
        -Path $carpeta `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $ultimoArchivo) {
        $resumenes += @"
Carpeta: $carpeta
Estado: ALERTA
Detalle: No se encontraron archivos en la carpeta monitoreada.
Fecha: $(Get-Date)
"@
        $resumenesCortos += "ALERTA | $(Split-Path $carpeta -Leaf): sin archivos"
        $hayAlertas = $true
        continue
    }

    $ultimaRecepcion = $ultimoArchivo.LastWriteTime
    $tiempoSinArchivos = New-TimeSpan -Start $ultimaRecepcion -End (Get-Date)
    $horasSinArchivos = [int]$tiempoSinArchivos.TotalHours
    $minutosSinArchivos = $tiempoSinArchivos.Minutes

    if ($horasSinArchivos -ge $config.NoFilesThresholdHours) {
        $estado = "ALERTA"
        $detalle = "Han transcurrido $horasSinArchivos horas y $minutosSinArchivos minutos sin recibir archivos."
        $resumenesCortos += "ALERTA | $(Split-Path $carpeta -Leaf): $horasSinArchivos h $minutosSinArchivos min sin recibir"
        $hayAlertas = $true
    }
    else {
        $estado = "OK"
        $detalle = "Se recibieron $cantidad archivo(s) en las últimas 24 horas."
        $resumenesCortos += "OK | $(Split-Path $carpeta -Leaf): $cantidad archivo(s), último $($ultimoArchivo.Name)"
    }

    $resumenes += @"
Carpeta: $carpeta
Estado: $estado
Detalle: $detalle
Último archivo: $($ultimoArchivo.Name)
Fecha última recepción: $($ultimoArchivo.LastWriteTime)
Archivos detectados:
$listaArchivosTexto
"@
}

if (-not $hayCarpetasValidas -and $resumenes.Count -eq 0) {
    Write-Host "No hay carpetas válidas para monitorear."
    exit
}

if ($hayAlertas) {
    $Subject = "ALERTA DHL - Revisión de carpetas"
}
else {
    $Subject = "Recepción de archivos - Resumen DHL"
}

$Message = ($resumenes -join "`r`n------------------------------`r`n")
$ShortMessage = ($resumenesCortos | Select-Object -First 6) -join "`r`n"

if ([string]::IsNullOrWhiteSpace($ShortMessage)) {
    $ShortMessage = "Monitoreo ejecutado. Revisar log local para más detalle."
}

$DetailedReport = @"
Reporte de monitoreo DHL
Fecha: $(Get-Date)
Asunto: $Subject

$Message
"@

Set-Content -Path $ReportFile -Value $DetailedReport -Encoding UTF8

Write-Host $Message

if ($config.NtfyTopic) {
    Invoke-RestMethod `
        -Method Post `
        -Uri "https://ntfy.sh/$($config.NtfyTopic)" `
        -Headers @{
            Title = $Subject
            Priority = "urgent"
        } `
        -Body $ShortMessage

    Invoke-RestMethod `
        -Method Put `
        -Uri "https://ntfy.sh/$($config.NtfyTopic)" `
        -Headers @{
            Title = "$Subject - Detalle"
            Filename = "salida.txt"
        } `
        -InFile $ReportFile
}

if ($modoPrueba -eq $true) {
    Write-Host ""
    Write-Host "===== MODO PRUEBA ====="
    Write-Host "Asunto: $Subject"
    Write-Host "Mensaje: $Message"
    Write-Host "======================="

    if ($config.NtfyTopic) {
        Invoke-RestMethod `
            -Method Post `
            -Uri "https://ntfy.sh/$($config.NtfyTopic)" `
            -Headers @{
                Title = "Heartbeat DHL"
            } `
            -Body @"
Monitor activo

Fecha:
$(Get-Date)

Resumen corto:
$ShortMessage

Reporte detallado:
$ReportFile

Detalle completo en log local:
$LogFile
"@
    }
}
elseif ($config.UseEmail -eq $true -and $config.From -and $config.To -and $Credential) {
    Send-MailMessage `
        -From $config.From `
        -To $config.To `
        -Subject $Subject `
        -Body $Message `
        -SmtpServer $config.SMTP_Server `
        -Port $config.Port `
        -Credential $Credential `
        -UseSsl
}

$LogMessage = @"
$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Subject

Resumen:
$Message

--------------------------------------------------
"@

Add-Content -Path $LogFile -Value $LogMessage