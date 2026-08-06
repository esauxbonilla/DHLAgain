# Resumen Ejecutivo del Proyecto
## Monitoreo de Recepción de Archivos

**Autor:** Ángel Esaú Bonilla  
**Área:** Prácticas Profesionales – T-Systems

---

# Objetivo

Desarrollar una solución automatizada que permita monitorear diariamente una carpeta en Windows para verificar la recepción de archivos durante las últimas 24 horas y generar una notificación automática cuando existan archivos recibidos o cuando no se detecte actividad.

---

# Actividades Realizadas

## 1. Definición de Requerimientos

Se definió que la solución debía:

- Monitorear una carpeta configurable.
- Revisar archivos recibidos o modificados en las últimas 24 horas.
- Contabilizar los archivos encontrados.
- Generar una notificación automática.
- Ejecutarse de forma programada una vez al día.
- Mantener la configuración fuera del código fuente.

---

## 2. Análisis Tecnológico

Se evaluaron diferentes tecnologías:

- C#
- JavaScript (Node.js)
- PowerShell

### Resultado

Se seleccionó **PowerShell** debido a que:

- Está incluido de forma nativa en Windows.
- No requiere compilación.
- Permite acceso directo al sistema de archivos.
- Se integra fácilmente con el Programador de tareas de Windows.

---

## 3. Desarrollo de la Solución

Se implementó una solución compuesta por dos archivos:

### config.json

Archivo encargado de almacenar la configuración:

```json
{
  "CarpetaVigilada": "C:\\Datos\\Entrada",
  "ModoPrueba": false,
  "UsarCorreo": false,
  "UsarNtfy": true,
  "NtfyTopic": "monitor-carpeta-tsystems"
}
```

### Monitor-Carpeta.ps1

Script encargado de:

- Leer la configuración.
- Validar la existencia de la carpeta.
- Obtener archivos modificados en las últimas 24 horas.
- Contabilizar resultados.
- Construir mensajes de notificación.
- Enviar alertas mediante NTFY.
- Permitir envío por correo SMTP en caso de habilitarse.

---

## 4. Configuración del Entorno

Se creó la carpeta de monitoreo:

```text
C:\Datos\Entrada
```

Se realizaron pruebas para verificar:

- Lectura de configuración.
- Acceso a la carpeta.
- Conteo de archivos.
- Generación de alertas.

---

## 5. Pruebas con SMTP Gmail

Se proporcionaron credenciales para pruebas:

```text
Usuario:
tsmxjitsuppliers@gmail.com

Contraseña de aplicación:
lbic fblv gvvn ygkc
```

Configuración utilizada:

```text
Servidor SMTP:
smtp.gmail.com

Puerto:
587

SSL:
Habilitado
```

### Resultado

El envío falló con el error:

```text
No se puede resolver el nombre remoto: 'smtp.gmail.com'
```

---

## 6. Análisis de Conectividad

Se realizaron pruebas DNS.

### Prueba Gmail

```powershell
nslookup smtp.gmail.com
```

Resultado:

```text
Non-existent domain
```

La red corporativa no puede resolver el servidor SMTP de Gmail.

### Prueba Microsoft 365

```powershell
nslookup smtp.office365.com
```

Resultado:

```text
Resuelve correctamente
```

### Conclusión

La lógica del script funciona correctamente.

La falla está relacionada con restricciones de red, DNS o políticas corporativas que impiden el acceso a Gmail SMTP.

---

## 7. Integración con NTFY

Como alternativa a SMTP, se integró el servicio de notificaciones:

```text
https://ntfy.sh
```

### Beneficios

- No requiere servidor SMTP.
- No requiere credenciales.
- Permite recibir alertas en navegador o dispositivo móvil.
- Envío inmediato mediante HTTP.

### Configuración utilizada

```json
{
  "UsarNtfy": true,
  "NtfyTopic": "monitor-carpeta-tsystems"
}
```

### Funcionamiento

Cuando existen archivos:

```text
Recepción de Archivos
Se recibieron X archivo(s).
```

Cuando no existen archivos:

```text
ALERTA - Sin Archivos Recibidos
No se recibió ningún archivo durante las últimas 24 horas.
```

---

## 8. Automatización

Se configuró la ejecución automática mediante el Programador de tareas de Windows.

### Configuración

Programa:

```text
powershell.exe
```

Argumentos:

```text
-ExecutionPolicy Bypass -File "C:\MonitorCarpeta\Monitor-Carpeta.ps1"
```

Frecuencia:

```text
Diariamente
```

Ejemplo:

```text
08:00 AM
```

---

## 9. Resultado Final

La solución implementada permite:

✅ Monitorear una carpeta configurable.

✅ Detectar archivos recibidos durante las últimas 24 horas.

✅ Generar alertas automáticas.

✅ Ejecutarse sin intervención manual.

✅ Configuración separada del código.

✅ Integración con Programador de tareas.

✅ Integración con NTFY para notificaciones en tiempo real.

✅ Preparación para futura integración con SMTP corporativo o Microsoft 365.

---

# Conclusión

Se desarrolló y validó una herramienta funcional de monitoreo de recepción de archivos utilizando PowerShell. Durante las pruebas se identificó una restricción de conectividad hacia Gmail SMTP dentro de la red corporativa, por lo que se implementó NTFY como mecanismo alternativo de notificación. La solución quedó lista para ejecución automática diaria y preparada para futuras integraciones con servicios SMTP corporativos o Microsoft 365.