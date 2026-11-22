# Actualización 20/11/2026: flujo de respaldo autorizado

El usuario autorizó cambiar el flujo: la EC2 de AWS exporta a S3, descarga desde S3 y envía a Blob por HTTPS con SAS de creación/escritura. La cuenta Storage tiene acceso público activado exclusivamente con firewall por las dos IP del NAT regional de AWS: 35.172.14.7 y 100.48.128.175; acción predeterminada Deny. El Private Endpoint continúa operativo para la VM Azure. Una copia iniciada por el script AWS llegó a Blob y fue verificada mediante SHA-256 desde Azure. Se verificó el cron anterior de seis horas. Tras autorización del usuario se configuró un cron de tres horas en ambas EC2; ambas copias manuales se verificaron en Azure. El disparo periódico de las 21:15 UTC se observó en ambas instancias y Azure verificó ambas copias con SHA-256. Una restauración anterior con un usuario sintético coincidió en tres tablas y huella.

La SAS vence el 20/12/2026 00:00 UTC (19/12 19:00 en Lima). Renovar antes con Terraform de Azure y reaplicar Terraform de AWS para actualizar SSM; proteger ambos estados. Si las IP del NAT cambian, actualizar la lista del firewall y volver a probar. La sesión AWS fue revocada durante el despliegue y se renovó después; se recuperaron las instancias y las respuestas HTTP. Verificar el entorno antes de sustentar.

# Registro histórico: inicio de reconstrucción del 20/11/2026

Por solicitud del usuario se inició la reconstrucción con Terraform en Azure for Students. Los recursos de red, Storage privado, endpoint privado, VM de integración ARM64 Standard_B2pts_v2, identidad administrada y monitoreo se volvieron a crear. El tamaño original B1s y las alternativas B1ms/B2s no tuvieron capacidad disponible en South Central US. El contenedor se accedió desde la VM con identidad administrada y el DNS resolvió al endpoint privado 10.20.3.4. Al momento de este registro inicial aún faltaba probar transferencia y restauración; ambas fueron verificadas posteriormente, como describe la actualización superior. El nombre de Storage y demás identificadores pueden consultarse con `terraform output`.

La sección del 12/11 es histórica y no describe el estado actual. El estado de Terraform y sus copias son sensibles. Esta infraestructura activa genera costos; el presupuesto es una alerta, no un límite de gasto. La eliminación solicitada para el futuro se realiza mediante Terraform después de verificar y preservar los datos que se necesiten.

# Estado actualizado: recursos eliminados (12/11/2026)

Por solicitud del usuario se eliminaron con Terraform el grupo `rg-wimiline-multicloud`, VM, disco, NAT, IP, Private Endpoint, Storage y contenedor, red, monitoreo y presupuesto. El contenedor `respaldos` estaba vacío antes de borrar. Se eliminó también el Network Watcher creado automáticamente para esa región. Azure no mostró recursos en el inventario de la suscripción después; el grupo vacío `NetworkWatcherRG` puede permanecer y no es un recurso en funcionamiento. El estado Terraform quedó sin recursos registrados. La suscripción sigue activa. Cargos de uso anterior pueden aparecer con retraso.

Los archivos `.tf`, scripts, estado y clave SSH siguen en el equipo. No publicar archivos de estado ni claves: pueden contener datos sensibles. Al reconstruir, ejecutar `terraform init`, establecer `TF_VAR_subscription_id`, revisar `terraform plan` y solo entonces aplicar. Se crearán recursos nuevos que podrían tener nombres, IDs e IP distintos; la VM tendrá que configurarse nuevamente. El presupuesto y sus alertas solo existirán otra vez si se aplica la configuración. El plazo y alertas del presupuesto deben revisarse antes de aplicar. AWS no fue modificado.

La sección siguiente es el historial de lo creado y las tareas que quedaban pendientes ANTES de la eliminación. No describe recursos activos actualmente. La integración S3 → Blob y la restauración nunca se probaron.

# Azure V3: operación y pendientes

Arquitectura de referencia: `Arquitectura V3 Oficial/Wimiline_Arquitectura_V3.html` y `Wimiline_Arquitectura_Completa.svg`.

## Recursos configurados mediante Terraform

Grupo `rg-wimiline-multicloud`; Storage `wimilinebackupd6e16cfb`, contenedor privado `respaldos`. Red `vnet-wimiline-integracion` 10.20.0.0/16, subred de integración 10.20.2.0/24, subred de Private Endpoint 10.20.3.0/24 y NSG de entrada. Azure NAT Gateway, IP pública de salida, NIC privada, Private Endpoint de Blob y zona DNS privada vinculada. VM `vm-wimiline-integracion` (Ubuntu, Standard_B1s, sin IP pública), identidad administrada con rol Storage Blob Data Contributor limitado al contenedor.

Monitoreo: workspace Log Analytics, DCR para syslog facility user, grupo de acciones al correo operativo y alerta de CPU habilitada. La extensión AzureMonitorLinuxAgent quedó en Creating; su instalación y la recepción real de logs no están verificadas. Terraform la importó a su estado después de interrumpir el apply. La alerta de fallos de transferencia y la prueba de recepción no se han completado. La instalación de AWS CLI y AzCopy en la VM se interrumpió y debe comprobarse al reiniciarla.

Terraform: `main.tf`, `integracion.tf`, `monitoreo.tf`, `variables.tf`, `versions.tf`, `outputs.tf`. El archivo de estado contiene información sensible; no publicarlo ni enviarlo. La clave SSH privada está en el perfil del usuario, en `.ssh/wimiline_azure_integracion`; no compartirla.

## Comprobaciones realizadas

Desde la VM, el nombre de Blob resolvió al endpoint privado 10.20.3.4. La solicitud HTTPS al endpoint regional de S3 recibió respuesta HTTP 307: demuestra salida HTTPS, no autoriza ni prueba acceso a un bucket concreto. No se ha probado transferencia de respaldo ni restauración.

## Pendientes históricos al recuperar AWS (no describen el estado actual)

1. Obtener inventario y confirmar el estado real de RDS y del grupo de aplicación. Definir la forma de generar `pg_dump -Fc` sin interrumpir la aplicación, frecuencia, retención y manifiesto SHA-256.
2. Crear o seleccionar el bucket/prefijo de respaldo y una identidad AWS de lectura con permisos mínimos, sin guardar secretos en Terraform ni en el repositorio. La identidad administrada de Azure NO concede acceso a S3.
3. Configurar la VM con una identidad AWS autorizada y las variables `WIMILINE_S3_OBJECT`, `WIMILINE_S3_MANIFEST`, `WIMILINE_AZURE_CONTAINER`, `WIMILINE_BACKUP_ID`. El script `scripts/copiar-respaldo.sh` es una base local, no se considera ejecutada ni probada. Su manifiesto debe referirse a `respaldo.dump`. El ID debe ser único por respaldo y estable para reintentos.
4. Instalar y comprobar el script en la VM, validar los permisos de Blob mediante identidad administrada, ejecutar copia de prueba, comparar integridad del objeto de destino y verificar reintentos seguros. No habilitar programación hasta terminar la validación.
5. Implementar alerta sobre errores y ausencia de copias, probar entrega de avisos y documentar la frecuencia. El grupo de acciones y alerta de CPU no demuestran que se supervise el proceso de copia.
6. Restaurar una copia de Azure en PostgreSQL aislado, comparar datos y comprobar la aplicación; definir y medir RTO/RPO de extremo a extremo. No afirmar que el respaldo intercloud ya funciona antes de la prueba.
7. Revisar el acceso público de red de Storage después de validar Private Endpoint y la forma de administración y estado de Terraform. El contenedor privado exige autorización pero no significa que el endpoint público esté bloqueado.
8. Probar las alertas del presupuesto y revisar el gasto real en ambas nubes. CloudTrail, reglas de AWS y recursos existentes no fueron modificados.
9. Confirmar con docente si Azure reemplaza OCI para la rúbrica.

## Costos y suspensión

La VM debe quedar `VM deallocated` para detener el cargo de cómputo. Discos administrados, NAT Gateway, IP pública estándar, Private Endpoint, Storage y registros pueden seguir facturándose o consumiendo crédito incluso si la VM está desasignada. NAT y Private Endpoint no disponen de un apagado equivalente a una VM; se conservan porque se solicitó no eliminar recursos. El presupuesto alerta pero no detiene el consumo por sí solo. Verificar consumo real y crédito en Azure Education / Cost Management.

Al reanudar: iniciar la VM `vm-wimiline-integracion` desde Azure Portal o `az vm start --resource-group rg-wimiline-multicloud --name vm-wimiline-integracion`; comprobar agente, DNS privado y acceso S3/Blob antes de ejecutar cualquier copia. Para parar: `az vm deallocate --resource-group rg-wimiline-multicloud --name vm-wimiline-integracion` y verificar `az vm get-instance-view` o el estado en el portal. Detener solo desde dentro del sistema puede dejar cómputo facturable.
## Estado al finalizar

La VM quedó VM deallocated, verificado en Azure. El agente quedó Creating y no se comprobó la instalación de herramientas. Presupuesto mensual del grupo: 20 USD, con avisos de consumo real al 50 %, 80 % y 100 % a wimiline.info@gmail.com. Es un aviso, no un límite de gasto, no cubre otros grupos ni garantiza impedir que se agote el crédito; su entrega no fue probada. NAT, IP, endpoint privado y disco siguen creados y pueden generar costos. No se eliminó ningún recurso.
