# 06_Pruebas — Evidencias, Verificaciones y Ensayos Técnicos

Esta carpeta reúne el conjunto integral de evidencias cuantitativas, capturas de pantalla de auditoría y registros técnicos generados durante la construcción y validación de la solución multicloud para Wimiline E.I.R.L.

---

## 1. Inventario Exacto de Evidencias (142 archivos en total)

El directorio consolida **142 archivos** organizados de la siguiente forma:

| Subcarpeta / Ubicación | Cantidad | Descripción |
| --- | :---: | --- |
| [Capturas Entregable 3/](Capturas%20Entregable%203/) | **114 archivos** | Capturas de pantalla numeradas y fechadas que respaldan cada recurso desplegado en AWS y Azure (VPC, subredes, ALB, ASG, RDS Multi-AZ, S3, IAM, Azure VNet, Private Endpoint, Storage, Monitor y pruebas en terminal/navegador). |
| [V4_Verificaciones/](V4_Verificaciones/) | **15 archivos** | Reportes de consola y archivos de texto (`01_AWS_rutas.txt` hasta `14_Prueba_funcional_V7.json`, incluyendo validaciones de plan para AWS y Azure) que certifican configuraciones de red, NSGs, tablas de rutas, sesiones TLS y pruebas de integración. |
| **Archivos JSON en raíz** | **10 archivos** | Mediciones cuantitativas de rendimiento, ensayos de recuperación (RTO aislado), disponibilidad, carga sintética e inyección de fallos (`alerta-azure`, `carga-api`, `escalamiento-cpu`, `fallo-copia-aws`, `idempotencia-blob`, `recuperacion-autonoma-azure`, `rto-https-temporal`, `rto-publico-temporal`, `sustitucion-ec2`, `verificacion`). |
| **Archivos TXT en raíz** | **2 archivos** | Registros de hashes y huellas de identidad (`identidad-integracion.txt`, `identidad-prueba.txt`). |
| **Guía de auditoría** | **1 archivo** | Este documento [LEEME.md](LEEME.md). |
| **TOTAL CONSOLIDADO** | **142 archivos** | Inventario completo de pruebas y verificaciones técnicas. |

---

## 2. Ensayos Cuantitativos y Resultados Clave

### A. Alta Disponibilidad y Tolerancia a Fallos
- **[sustitucion-ec2-2026-11-20.json](sustitucion-ec2-2026-11-20.json):** Durante la terminación deliberada de una de las instancias EC2 del Auto Scaling Group, se realizaron **75 sondeos HTTP continuos con un 100% de éxito (75/75 respuestas HTTP 200)**. El Application Load Balancer retiró de inmediato la instancia degradada y enrutó todo el tráfico a la instancia redundante en la otra zona de disponibilidad sin interrumpir el servicio.
- **[escalamiento-cpu-2026-11-20.json](escalamiento-cpu-2026-11-20.json):** Se aplicó una carga sintética de CPU sobre las instancias de aplicación. Se constató la activación de la política de escalado dinámico de CloudWatch, incrementando la capacidad deseada de 2 a 3 y posteriormente a 4 instancias EC2, con retorno automático a la capacidad base una vez normalizada la demanda.

### B. Recuperación Ante Desastres y Continuidad en Entorno Aislado
- **[recuperacion-autonoma-azure.json](recuperacion-autonoma-azure.json):** Ensayo de recuperación aislada en Azure. A partir del volcado lógico de PostgreSQL y el paquete de aplicación (`multiverso-release.zip`) vinculados por huella digital SHA-256 en Azure Blob:
  - **Tiempo de Recuperación Medido:** **268.2 segundos (~4 minutos con 28 segundos)**.
  - **Endpoints Validados en Entorno Aislado:** HTTP 200 en `/`, `/api/public/status`, registro de nuevos usuarios y autenticación (login).
  - *Delimitación Técnica:* La medición cronometrada corresponde exclusivamente a la restauración de datos y arranque del servicio en la VM de contingencia. **No incluye ni mide la conmutación real de registros DNS públicos ni del certificado TLS productivo.**
- **[rto-https-temporal.json](rto-https-temporal.json):** Ensayo complementario con certificado TLS preemitido y resolución de nombre forzada localmente (`multiverso.wimiline.com` $\rightarrow$ IP de contingencia) completado en 338.7 segundos hasta login, sin alterar el DNS productivo.
- **[rto-publico-temporal.json](rto-publico-temporal.json):** Ensayo preliminar completado en 446 segundos (7 min 26 s).
- **[idempotencia-blob-2026-11-20.json](idempotencia-blob-2026-11-20.json):** Validación de consistencia e integridad de hash SHA-256 (`acc25a7f6a...`) tras múltiples cargas sucesivas, confirmando además el rechazo con HTTP 403 (Forbidden) ante accesos directos de clientes no autorizados.

### C. Observabilidad y Monitoreo Notificado
- **[fallo-copia-aws-2026-11-20.json](fallo-copia-aws-2026-11-20.json):** Inyección controlada de error en el script de respaldo. Se verificó que el sistema emitió la métrica personalizada `CopyFailure=1`, la alarma de CloudWatch pasó a estado `ALARM` y Amazon SNS despachó la notificación de incidente por correo electrónico.
- **[alerta-azure-2026-11-20.json](alerta-azure-2026-11-20.json):** Validación de alerta de métricas en Azure Monitor ante sobrecarga de CPU en la VM de integración, con entrega exitosa de correo a `wimiline.info@gmail.com`.

---

## 3. Precisión Metodológica sobre Verificaciones PS03 y PB04

En concordancia con el informe final (Apartado 22 y Anexo H):
- **Control PS03 (Cifrado de Transporte JDBC API–RDS):**
  - *Alcance Demostrado:* El registro técnico [V4_Verificaciones/12_TLS_sesiones_API_V6.txt](V4_Verificaciones/12_TLS_sesiones_API_V6.txt) y la Evidencia 114 acreditan objetivamente la existencia de sesiones activas del driver PostgreSQL JDBC negociadas con **TLSv1.3** y suite de cifrado `TLS_AES_256_GCM_SHA384`.
  - *Delimitación:* La validación complementaria del nombre de host y de la cadena de confianza CA del cliente no dispone de un registro técnico independiente en este expediente y figura como confirmación de conformidad comunicada por el responsable del proyecto.
- **Control PB04 (Continuidad Operativa DNS/HTTPS):**
  - *Alcance Demostrado:* Los archivos JSON prueban que los datos y el aplicativo son recuperables en Azure en condiciones controladas y aisladas (268.2 s por HTTP y 338.7 s por HTTPS con resolución local forzada).
  - *Delimitación:* **No se realizó un cambio efectivo en la zona DNS pública ni una reemisión de certificados productivos**, por lo que estos tiempos cronometrados no deben interpretarse como un RTO integral de conmutación externa. Dicho procedimiento consta cualitativamente en la bitácora de alcance del Anexo H como verificación operativa complementaria.
