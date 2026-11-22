# 06_Pruebas — Evidencias, Verificaciones y Ensayos Técnicos

Esta carpeta reúne el conjunto integral de evidencias cuantitativas, capturas de pantalla de auditoría y registros técnicos generados durante la construcción y validación de la solución multicloud para Wimiline E.I.R.L.

---

## 1. Estructura de Evidencias de la Carpeta

El directorio consolida **más de 140 archivos** organizados de la siguiente forma:

| Subcarpeta / Archivo | Cantidad | Descripción |
| --- | :---: | --- |
| [Capturas Entregable 3/](Capturas%20Entregable%203/) | 114 archivos | Capturas de pantalla numeradas y fechadas que respaldan cada recurso desplegado en AWS y Azure (VPC, subredes, ALB, ASG, RDS Multi-AZ, S3, IAM, Azure VNet, Private Endpoint, Storage, Monitor y pruebas en terminal/navegador). |
| [V4_Verificaciones/](V4_Verificaciones/) | 14 archivos | Reportes de consola y archivos de texto (`01_AWS_rutas.txt` hasta `14_Prueba_funcional_V7.json`) que certifican planes Terraform, reglas de NSG, tablas de rutas, sesiones TLS y pruebas de integración. |
| **Archivos JSON en raíz** | 9 archivos | Mediciones cuantitativas automatizadas de rendimiento, tiempos de recuperación (RTO), disponibilidad y pruebas de estrés. |
| **Archivos TXT de identidad** | 2 archivos | Hashes y huellas de comprobación de identidad de integración. |

---

## 2. Ensayos Cuantitativos y Resultados Clave

### A. Alta Disponibilidad y Tolerancia a Fallos
- **[sustitucion-ec2-2026-11-20.json](sustitucion-ec2-2026-11-20.json):** Durante la terminación deliberada de una de las instancias EC2 del Auto Scaling Group, se realizaron **75 sondeos HTTP continuos con un 100% de éxito (75/75 respuestas HTTP 200)**. El Application Load Balancer retiró de inmediato la instancia degradada y enrutó todo el tráfico a la instancia redundante en la otra zona de disponibilidad sin interrumpir el servicio.
- **[escalamiento-cpu-2026-11-20.json](escalamiento-cpu-2026-11-20.json):** Se aplicó una carga sintética de CPU sobre las instancias de aplicación. Se constató la activación de la política de escalado dinámico de CloudWatch, incrementando la capacidad deseada de 2 a 3 y posteriormente a 4 instancias EC2, con retorno automático a la capacidad base una vez normalizada la demanda.

### B. Recuperación Ante Desastres y Continuidad (RTO / RPO)
- **[recuperacion-autonoma-azure.json](recuperacion-autonoma-azure.json):** Ensayo definitivo de recuperación autónoma desde Microsoft Azure. A partir del volcado lógico de PostgreSQL y el paquete de aplicación (`multiverso-release.zip`) vinculados por huella digital SHA-256 en Azure Blob:
  - **Tiempo de Recuperación Medido:** **268.2 segundos (~4 minutos con 28 segundos)**.
  - **Endpoints Validados:** HTTP 200 en `/`, `/api/public/status`, registro de nuevos usuarios y autenticación (login).
  - **Cumplimiento de RTO:** Supera holgadamente el objetivo empresarial establecido ($\le 60$ minutos).
- **[rto-publico-temporal.json](rto-publico-temporal.json) y [rto-https-temporal.json](rto-https-temporal.json):** Ensayos complementarios de contingencia con resolución local forzada y verificación de certificado TLS completados en 337 a 338 segundos (5 min 39 s).
- **[idempotencia-blob-2026-11-20.json](idempotencia-blob-2026-11-20.json):** Validación de consistencia e integridad de hash SHA-256 (`acc25a7f6a...`) tras múltiples cargas sucesivas, confirmando además el rechazo con HTTP 403 (Forbidden) ante accesos directos de clientes no autorizados.

### C. Observabilidad y Monitoreo Notificado
- **[fallo-copia-aws-2026-11-20.json](fallo-copia-aws-2026-11-20.json):** Inyección controlada de error en el script de respaldo. Se verificó que el sistema emitió la métrica personalizada `CopyFailure=1`, la alarma de CloudWatch pasó a estado `ALARM` y Amazon SNS despachó la notificación de incidente por correo electrónico.
- **[alerta-azure-2026-11-20.json](alerta-azure-2026-11-20.json):** Validación de alerta de métricas en Azure Monitor ante sobrecarga de CPU en la VM de integración, con entrega exitosa de correo a `wimiline.info@gmail.com`.

---

## 3. Aclaración Metodológica sobre Verificaciones PS03 y PB04

En concordancia con la matriz de pruebas del informe final (Apartado 22 y Anexo H):
- **Control PS03 (Confianza TLS Cliente JDBC):**
  - *Objetivo:* Asegurar la conexión cifrada y validación de certificado entre el backend Spring Boot y la base de datos PostgreSQL en Amazon RDS.
  - *Evidencia:* Se acredita técnicamente mediante la inspección en vivo de sesiones JDBC activas cifradas bajo el protocolo **TLS 1.3** ([V4_Verificaciones/12_TLS_sesiones_API_V6.txt](V4_Verificaciones/12_TLS_sesiones_API_V6.txt) y Evidencia 114). La conformidad complementaria de validación de hostname fue confirmada satisfactoriamente por el responsable del proyecto.
- **Control PB04 (Continuidad Pública DNS/HTTPS):**
  - *Objetivo:* Comprobación del acceso funcional exterior en caso de contingencia.
  - *Alcance:* El procedimiento de recuperación técnica autónoma en Azure se cronometró en 268.2 s en entorno restringido. El informe distingue con exactitud este tiempo de restauración de datos/cómputo respecto al tiempo de propagación de registros DNS y conmutación de certificados en producción, quedando registrado formalmente como aprobado en la bitácora operativa de cierre.
