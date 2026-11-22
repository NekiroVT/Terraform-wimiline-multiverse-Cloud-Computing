# Monitoreo y Alertas — Wimiline (Entregable 3)

Este documento describe la arquitectura de observabilidad, paneles de telemetría y mecanismos de notificación configurados en AWS y Microsoft Azure, vinculando cada componente con sus evidencias en [06_Pruebas](../06_Pruebas/).

---

## 1. Observabilidad en AWS

### Paneles y Métricas Centralizadas
- **Dashboard CloudWatch `wimiline-operacion`:** Consolida en una vista única el estado operativo del Application Load Balancer (tráfico, latencia, targets saludables), la utilización de CPU del cluster Auto Scaling y las métricas de Amazon RDS.
  - *Evidencias:* [61_AWS_CloudWatch_paneles_listado.png](../06_Pruebas/Capturas%20Entregable%203/61_AWS_CloudWatch_paneles_listado.png), [62_AWS_CloudWatch_dashboard_metricas_RDS_ALB.png](../06_Pruebas/Capturas%20Entregable%203/62_AWS_CloudWatch_dashboard_metricas_RDS_ALB.png).

### Alarmas Operativas y Notificaciones SNS
- **Alarmas de Salud del Balanceador:** Notifican ante destinos no saludables (`UnhealthyHostCount > 0`) para web y API, así como incrementos en errores HTTP 5XX.
  - *Evidencia:* [63_AWS_CloudWatch_alarmas_estados.png](../06_Pruebas/Capturas%20Entregable%203/63_AWS_CloudWatch_alarmas_estados.png).
- **Alarma de CPU de RDS:** Supervisa la carga de la base de datos PostgreSQL utilizando la dimensión inmutable corregida `DBInstanceIdentifier: multiverso-db`. El umbral está fijado al 80% (operando nominalmente en ~4.2%).
  - *Evidencia:* [102_AWS_RDS_panel_general.png](../06_Pruebas/Capturas%20Entregable%203/102_AWS_RDS_panel_general.png).
- **Canal SNS `wimiline-alertas`:** Tema de notificaciones críticas con suscripción de correo electrónico confirmada hacia `wimiline.info@gmail.com`.
  - *Evidencias:* [64_AWS_SNS_temas_listado.png](../06_Pruebas/Capturas%20Entregable%203/64_AWS_SNS_temas_listado.png), [65_AWS_SNS_alertas_suscripcion_confirmada.png](../06_Pruebas/Capturas%20Entregable%203/65_AWS_SNS_alertas_suscripcion_confirmada.png), [66_AWS_SNS_alertas_politica_acceso.png](../06_Pruebas/Capturas%20Entregable%203/66_AWS_SNS_alertas_politica_acceso.png).

### Supervisión del Pipeline de Respaldos
- El script de respaldo emite las métricas personalizadas `Wimiline/Backup/CopySuccess` y `CopyFailure`.
- **Alarma de Fallo Inmediato:** Se activa ante cualquier evento `CopyFailure >= 1` evaluado en 5 minutos.
- **Alarma de Ausencia de Respaldos:** Se dispara si no se recibe ningún evento `CopySuccess` en una ventana móvil de 4 horas, aportando margen preventivo frente al RPO de 6 horas.
- **Ensayo de Fallo Simulado:** Se inyectó un error sintético en el manejador del script, verificando el paso a estado `ALARM` y el despacho del correo de alerta:
  - *Registro de Prueba:* [fallo-copia-aws-2026-11-20.json](../06_Pruebas/fallo-copia-aws-2026-11-20.json).

### Auto Scaling y Escalamiento Dinámico
- Alarma de escalado vinculada a la política de seguimiento de CPU objetivo (60%).
- Bajo carga sintética, la capacidad deseada escaló de 2 a 3 y luego a 4 instancias EC2, retornando automáticamente a 2 al cesar el estrés:
  - *Registro de Prueba:* [escalamiento-cpu-2026-11-20.json](../06_Pruebas/escalamiento-cpu-2026-11-20.json).

---

## 2. Observabilidad en Microsoft Azure

### Agente y Recolección de Logs
- **Azure Monitor Linux Agent (AMA):** Instalado y gestionado mediante Terraform en la VM de integración ARM64 (`Standard_B2pts_v2`).
- **Data Collection Rules (DCR) y Log Analytics:** Workspace centralizado configurado para ingerir eventos de syslog del sistema operativo Linux.
  - *Verificación:* Evento de syslog recibido con éxito el 20/11/2026 a las 11:54:55 UTC.

### Alertas de Métricas y Notificaciones
- Se desplegó una regla de alerta sobre el consumo de CPU de la máquina virtual de contingencia.
- El 20/11/2026 a las 20:04:17 UTC la alerta pasó a estado `Fired` y se verificó la recepción del correo de alerta en `wimiline.info@gmail.com`:
  - *Registro de Prueba:* [alerta-azure-2026-11-20.json](../06_Pruebas/alerta-azure-2026-11-20.json).

### Control de Presupuesto
- Presupuesto mensual configurado en **USD 20.00** con alertas tempranas al 50%, 80% y 100% para prevenir consumo imprevisto de créditos educativos.
