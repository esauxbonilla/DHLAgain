# ===========================================
# Monitor-Carpeta.ps1
# Monitoreo de recepción de archivos
# ===========================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$configFile = Join-Path $PSScriptRoot "config.json"
$LogFile = Join-Path $PSScriptRoot "Monitor.log"

$Password = ConvertTo-SecureString "lbic fblv gvvn ygkc" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential(
    "tsmxjitsuppliers@gmail.com", $Password
)

if (!(Test-Path $configFile)) {
    Write-Host "No se encontró config.json"
    exit
}

$config = Get-Content $configFile -Encoding UTF8 | ConvertFrom-Json

$carpeta = $config.MonitorFolder
$modoPrueba = $config.Test

Write-Host "Test = [$modoPrueba]"
Write-Host "Tipo = $($modoPrueba.GetType().Name)"

if ([string]::IsNullOrWhiteSpace($carpeta)) {
    Write-Host "MonitorFolder no está configurado en config.json"
    exit
}

if (!(Test-Path $carpeta)) {
    Write-Host "La carpeta configurada no existe: $carpeta"
    exit
}

$limite = (Get-Date).AddHours(-24)

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
    $Subject = "ALERTA DHL - Carpeta sin archivos"
    $Message = @"
No se encontraron archivos en la carpeta monitoreada.

Carpeta:
$carpeta

Fecha:
$(Get-Date)
"@

    Write-Host $Message

    if ($config.NtfyTopic) {
        Invoke-RestMethod `
            -Method Post `
            -Uri "https://ntfy.sh/$($config.NtfyTopic)" `
            -Headers @{
                Title = $Subject
                Priority = "urgent"
            } `
            -Body $Message
    }

    Add-Content -Path $LogFile -Value @"
$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Subject

$Message

--------------------------------------------------
"@
    exit
}

$ultimaRecepcion = $ultimoArchivo.LastWriteTime
$tiempoSinArchivos = New-TimeSpan -Start $ultimaRecepcion -End (Get-Date)
$horasSinArchivos = [int]$tiempoSinArchivos.TotalHours
$minutosSinArchivos = $tiempoSinArchivos.Minutes

if ($horasSinArchivos -ge $config.NoFilesThresholdHours) {
    $Subject = "ALERTA DHL - Sin archivos recibidos"
    $Message = @"
Han transcurrido $horasSinArchivos horas y $minutosSinArchivos minutos sin recibir archivos.

Último archivo:
$($ultimoArchivo.Name)

Fecha última recepción:
$($ultimoArchivo.LastWriteTime)
"@
}
else {
    $Subject = "Recepción de archivos"
    $Message = @"
Se recibieron $cantidad archivo(s) en las últimas 24 horas.

Archivos recibidos:

$listaArchivosTexto

Último archivo:
$($ultimoArchivo.Name)

Fecha última recepción:
$($ultimoArchivo.LastWriteTime)
"@
}

Write-Host $Message

if ($config.NtfyTopic) {
    Invoke-RestMethod `
        -Method Post `
        -Uri "https://ntfy.sh/$($config.NtfyTopic)" `
        -Headers @{
            Title = $Subject
            Priority = "urgent"
        } `
        -Body $Message
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

Carpeta:
$carpeta

Archivos últimas 24 horas:
$cantidad

Archivos detectados:

$listaArchivosTexto
"@
    }
}
elseif ($config.UseEmail -eq $true -and $config.From -and $config.To) {
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

Cantidad: $cantidad

Archivos:
$listaArchivosTexto

--------------------------------------------------
"@

Add-Content -Path $LogFile -Value $LogMessage