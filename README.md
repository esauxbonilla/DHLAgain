# DHL Folder Monitor

Monitor liviano en PowerShell para supervisar la recepción de archivos en una carpeta de DHL, detectar ausencia de archivos y enviar notificaciones automáticas por `ntfy` y opcionalmente por correo.

## Objetivo

Automatizar el monitoreo operativo de carpetas para:

- detectar archivos recibidos,
- detectar ausencia de archivos,
- generar heartbeat,
- registrar evidencias en log,
- ejecutarse sin intervención manual.

## Estructura del proyecto

- `MonitoreoFolder.ps1`: script principal de monitoreo.
- `config.json`: configuración del monitoreo.
- `Monitor.log`: bitácora de ejecuciones.
- `.gitignore`: exclusiones para Git.

## Requisitos

- Windows
- PowerShell
- acceso a internet para `ntfy`
- permisos de lectura sobre la carpeta monitoreada

## Configuración

Ejemplo de `config.json`:

```json
{
  "MonitorFolder": "C:\\DHL\\Encolados",
  "SMTP_Server": "smtp.gmail.com",
  "Port": 587,
  "From": "",
  "To": "",
  "SmtpUser": "",
  "SmtpPassword": "",
  "UseEmail": false,
  "Test": true,
  "NtfyTopic": "monitor-carpeta-dhl",
  "NoFilesThresholdHours": 1
}
```

### Campos principales

- `MonitorFolder`: carpeta a monitorear.
- `NtfyTopic`: tópico de notificación en `https://ntfy.sh`.
- `NoFilesThresholdHours`: horas máximas sin recibir archivos antes de alertar.
- `Test`: si está en `true`, envía heartbeat y muestra salida de prueba.
- `UseEmail`: habilita envío por correo.
- `From`, `To`, `SmtpUser`, `SmtpPassword`: datos SMTP si se usa correo.

## Ejecución manual

Desde la carpeta del proyecto:

```powershell
.\MonitoreoFolder.ps1
```

Si PowerShell bloquea scripts por política de ejecución, puedes usar una sesión temporal adecuada según tu entorno.

## Comportamiento actual

El script:

1. lee `config.json`,
2. valida la carpeta configurada,
3. busca archivos de las últimas 24 horas,
4. identifica el último archivo recibido,
5. calcula el tiempo transcurrido desde la última recepción,
6. envía una alerta por `ntfy` si no han llegado archivos dentro del umbral,
7. envía heartbeat en modo prueba,
8. registra el resultado en `Monitor.log`.

## Notificaciones

### Alerta por ausencia de archivos

Título:

- `ALERTA DHL - Sin archivos recibidos`

### Notificación de recepción

Título:

- `Recepción de archivos`

### Heartbeat

Título:

- `Heartbeat DHL`

## Logs

Cada ejecución agrega una entrada en `Monitor.log` con:

- fecha y hora,
- tipo de evento,
- cantidad de archivos,
- lista de archivos detectados.

## Seguridad

No subas credenciales reales al repositorio.

Recomendaciones:

- mantener `UseEmail` en `false` si no se usa,
- completar `SmtpPassword` solo en entornos controlados,
- rotar cualquier secreto que haya sido subido previamente al repositorio.

## Próximos pasos sugeridos

- soporte para múltiples carpetas,
- catálogo de archivos esperados,
- detección de archivos encolados,
- límite configurable de archivos mostrados,
- dashboard o resumen ejecutivo.
