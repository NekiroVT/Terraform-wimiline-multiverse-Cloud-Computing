# Continuidad del Negocio y Recuperación ante Desastres (DR) — Wimiline

Este documento define la estrategia de continuidad, el procedimiento de contingencia paso a paso y los resultados empíricos obtenidos en los ensayos de recuperación multicloud, vinculando cada prueba con sus evidencias en [06_Pruebas](../06_Pruebas/).

---

## 1. Alcance y Objetivos de Negocio (RTO / RPO)

- **Activos Críticos Protegidos:** Base de datos transaccional PostgreSQL, API Spring Boot empaquetada, frontend web, balanceador ALB, configuración Terraform y secretos en Parameter Store.
- **RTO (Recovery Time Objective):** Meta fijada en **$\le 60$ minutos** para recuperar la operatividad funcional de la aplicación y la base de datos.
- **RPO (Recovery Point Objective):** Meta fijada en **$\le 6$ horas** como máxima pérdida aceptable de transacciones de datos.

---

## 2. Pipeline de Respaldo Automatizado

1. **Frecuencia del Respaldo:** Cron programado cada 3 horas (`15 */3 * * *` UTC) en ambas instancias EC2 del Auto Scaling Group.
2. **Generación de Artefactos de Respaldo:**
   - Volcado lógico de PostgreSQL generado con `pg_dump`.
   - Cálculo de huella digital SHA-256 del volcado (`respaldo.dump.sha256`).
   - Generación de `release.sha256` vinculando la base con la versión exacta de la aplicación (`multiverso-release.zip`, 54 MB).
3. **Copia Dual y Réplica Multicloud:**
   - Almacenamiento primario en bucket privado de Amazon S3: [73_AWS_S3_bucket_carpetas_respaldos.png](../06_Pruebas/Capturas%20Entregable%203/73_AWS_S3_bucket_carpetas_respaldos.png), [74_AWS_S3_respaldo_base_y_SHA256.png](../06_Pruebas/Capturas%20Entregable%203/74_AWS_S3_respaldo_base_y_SHA256.png).
   - Transmisión inmediata vía HTTPS directo hacia Azure Blob Storage: [49_Azure_Blob_Storage_cuenta_listado.png](../06_Pruebas/Capturas%20Entregable%203/49_Azure_Blob_Storage_cuenta_listado.png).
4. **Seguridad en la Transmisión:** El endpoint público de Azure Blob rechaza todo tráfico de Internet (HTTP 403) excepto el proveniente de las IPs elásticas del NAT Gateway de AWS (`35.172.14.7` y `100.48.128.175`), validando además la firma de acceso compartido (SAS) de escritura temporal.

---

## 3. Protocolo de Recuperación en Contingencia (Azure DR)

En caso de indisponibilidad severa de la infraestructura en AWS:
1. **Declaración del Incidente:** Registrar marca temporal de inicio y seleccionar el último respaldo íntegro depositado en Azure Blob.
2. **Descarga Segura en Azure:** Desde la VM de contingencia ARM64 (`Standard_B2pts_v2`), conectarse a Azure Blob vía Private Endpoint ([45_Azure_Private_Endpoint_Blob_aprobado.png](../06_Pruebas/Capturas%20Entregable%203/45_Azure_Private_Endpoint_Blob_aprobado.png)) mediante la identidad administrada asignada. Descargar `respaldo.dump`, `respaldo.dump.sha256`, `release.sha256` y el paquete `multiverso-release.zip`.
3. **Validación de Integridad Criptográfica:** Contrastar los hashes SHA-256 de ambos archivos contra sus manifiestos.
4. **Restauración de Base de Datos:** Restaurar el volcado con `pg_restore` en una instancia PostgreSQL aislada compatible.
5. **Arranque y Verificación de Aplicación:** Levantar el backend Spring Boot y el servidor frontend apuntando a la base restaurada; verificar respuestas HTTP 200 en estado, registro y autenticación.
6. **Conmutación Operativa:** Apuntar registros DNS y habilitar el servicio exterior de contingencia.

---

## 4. Evidencias Empíricas y Ensayos Cuantitativos Registrados

Todos los ensayos fueron instrumentados y guardados en registros JSON estructurados en `06_Pruebas`:

| Ensayo | Tiempo Medido | Resultado y Alcance | Registro Técnico |
|---|:---:|---|---|
| **Recuperación Autónoma en Azure (DR Oficial)** | **268.2 s (~4 min 28 s)** | Restauración de base PostgreSQL y despliegue del binario de aplicación vinculado por SHA-256 en VM aislada en entorno restringido. Endpoints `/`, `/api/public/status`, registro y login con código HTTP 200. El ensayo de restauración aislada queda holgadamente por debajo del objetivo de 60 minutos, pero no demuestra una conmutación completa del servicio público ni del DNS productivo. *(Evidencia 80 del informe)* | [recuperacion-autonoma-azure.json](../06_Pruebas/recuperacion-autonoma-azure.json) |
| **Recuperación Aislada con Certificado HTTPS** | **338.7 s (~5 min 39 s)** | Verificación con resolución local forzada y certificado TLS preemitido para `multiverso.wimiline.com`. Respuestas HTTPS 200 en web y API. *(Evidencia 81 del informe)* | [rto-https-temporal.json](../06_Pruebas/rto-https-temporal.json) |
| **Recuperación Pública Temporal** | **446 s (7 min 26 s)** | Primera prueba preliminar con despliegue de frontend y verificación de respuesta de endpoints públicos. | [rto-publico-temporal.json](../06_Pruebas/rto-publico-temporal.json) |
| **Idempotencia y Rechazo de Accesos no Autorizados** | Inmediato | Doble carga sucesiva con verificación de hash idéntico (`acc25a7f6a...`) y confirmación de respuesta HTTP 403 ante peticiones externas no autorizadas. | [idempotencia-blob-2026-11-20.json](../06_Pruebas/idempotencia-blob-2026-11-20.json) |
| **Disparo Automático de Cron (21:15 UTC)** | Margen RPO < 3h | Comprobación en producción del disparo programado en ambas EC2, con entrega y validación de hash íntegra en Azure Blob Storage. | [verificacion-2026-11-20.json](../06_Pruebas/verificacion-2026-11-20.json) |
