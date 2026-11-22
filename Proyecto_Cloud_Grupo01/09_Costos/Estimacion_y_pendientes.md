# Análisis de Costos y Control Presupuestario — Revisión V3

Este documento presenta la evaluación económica de la infraestructura multicloud de Wimiline E.I.R.L. para el Entregable 3. Distingue con rigor la **base fija referencial** de la **estimación integral de la arquitectura V3**, considerando tanto los recursos computacionales permanentes como los factores de consumo variable inter-cloud.

---

## 1. Desglose de la Base Fija Parcial (USD 198.70 / mes)

Calculada sobre un régimen estándar de **730 horas mensuales** con la capacidad mínima permanentemente encendida:

| Proveedor | Partida / Recurso | Supuesto Técnico | Costo (USD/mes) |
|---|---|---|---:|
| **AWS** | Capacidad base V2 histórica | ALB, 2 EC2 privadas base, RDS PostgreSQL Multi-AZ (`db.t3.micro`), almacenamiento EBS y S3 inicial (consulta 04/11/2026) | 145.99 |
| **Azure** | VM Linux `Standard_B2pts_v2` | Instancia ARM64 para contingencia: USD 0.0101/h $\times$ 730 h | 7.37 |
| **Azure** | NAT Gateway Estándar | Puerta de salida para subred de contingencia: USD 0.045/h $\times$ 730 h | 32.85 |
| **Azure** | Private Endpoint | Enlace privado a Azure Storage: USD 0.010/h $\times$ 730 h | 7.30 |
| **Azure** | IP Pública Estática | IP asignada al Azure NAT Gateway: USD 0.005/h $\times$ 730 h | 3.65 |
| **Azure** | Disco Gestionado HDD S4 LRS | Disco de sistema operativo 30 GiB (tramo 32 GiB facturado) | 1.54 |
| **SUBTOTAL** | **Base Fija Azure** | **Suma de partidas fijas de contingencia en Azure** | **52.71** |
| **TOTAL** | **Referencia Conjunta Parcial** | **AWS Base Histórica + Azure Base Fija** | **198.70** |

> [!WARNING]
> **Precisión sobre la Base Parcial:**
> La cifra de **USD 198.70/mes no debe presentarse como la factura final ni como el costo integral de la V3**. Representa exclusivamente la suma de la cuota mínima de aprovisionamiento de cómputo y conectividad fija sin tráfico.

---

## 2. Estimación Integral de la Arquitectura V3 (Fijo + Variable)

En una operación real bajo la arquitectura implementada el 20/11/2026, intervienen consumos variables asociados al tráfico de usuarios, sincronización periódica de respaldos cada 3 horas y telemetría de monitoreo:

| Categoría | Concepto Operativo | Estimación Mensual | Costo Estimado (USD/mes) |
|---|---|---|---:|
| **Base Fija** | AWS Base + Azure Base (Cómputo, RDS Multi-AZ, VNet/VPC, NAT fijas) | 730 horas de operación continua | 198.70 |
| **AWS Variable** | ALB — LCU (Load Balancer Capacity Units) | 1 LCU promedio mensual (conexiones nuevas, activas y bytes procesados) | 5.84 |
| **AWS Variable** | NAT Gateway — Procesamiento de datos | Procesamiento de respaldos salientes y tráfico saliente (~20 GB/mes $\times$ USD 0.045/GB) | 0.90 |
| **AWS Variable** | Data Transfer Out (Inter-Cloud hacia Internet/Azure) | Transferencia de dumps y paquetes de aplicación (~20 GB/mes $\times$ USD 0.09/GB) | 1.80 |
| **AWS Variable** | CloudWatch Logs y Métricas Personalizadas | Ingesta de logs de aplicación, auditoría CloudTrail y métricas `CopySuccess`/`CopyFailure` | 3.20 |
| **AWS Variable** | RDS Backup Storage | Retención de snapshots automáticos durante 7 días (por encima del almacenamiento libre) | 1.50 |
| **Azure Variable** | NAT Gateway — Procesamiento de datos entrantes/salientes | Procesamiento de paquetes de recuperación (~15 GB/mes $\times$ USD 0.045/GB) | 0.68 |
| **Azure Variable** | Azure Blob Storage (Hot LRS) + Operaciones | Almacenamiento de respaldos acumulados (~50 GB) + transacciones de escritura PUT/LIST | 0.95 |
| **Azure Variable** | Azure Log Analytics Ingest | Ingesta de eventos syslog de Linux AMA (~0.5 GB/mes) | 1.15 |
| **TOTAL INTEGRAL** | **Costo Total Proyectado Multicloud V3** | **Base Fija + Consumos Variables Estimados** | **214.72** |

### Rango Operativo Real Recomendado
- **Escenario Nominal (carga moderada):** **USD 210.00 – USD 225.00 / mes**
- **Escenario con Escalamiento Puntual (ASG a 4 instancias durante picos):** **USD 225.00 – USD 245.00 / mes**

---

## 3. Consideraciones Presupuestarias y Cuentas Académicas

1. **Lectura de Cost Explorer en AWS Academy (USD 0.00):**
   - El entorno educativo de AWS Academy utiliza créditos institucionales preasignados (`voclabs`). La herramienta Cost Explorer o el panel de facturación puede reflejar USD 0.00 debido a la aplicación automática de dichos créditos educativos o al desfase en la agregación de datos de la organización administradora. Esto no implica que los servicios sean gratuitos en una cuenta comercial.
2. **Presupuesto de Seguridad en Azure (USD 20.00):**
   - Se configuró mediante Terraform un presupuesto mensual de **USD 20.00** con alertas tempranas al 50% (USD 10), 80% (USD 16) y 100% (USD 20).
   - **Finalidad:** Servir como mecanismo de alerta preventiva para evitar consumir la totalidad de los créditos de Azure for Students.
   - **Comportamiento Crítico:** El presupuesto de Azure **es una alerta informativa por correo electrónico y NO detiene automáticamente los recursos**. Elementos como el NAT Gateway (USD 32.85/mes) y el Private Endpoint continúan facturando mientras existan en el grupo de recursos, incluso si la máquina virtual se encuentra desasignada.
3. **Recomendación para la Sustentación:**
   - Presentar primero la tabla de **Base Fija (USD 198.70)** como piso de partida garantizado de infraestructura.
   - Explicar a continuación el **Modelo Integral V3 (USD 214.72)** para demostrar dominio técnico en la estimación de costos variables inter-cloud (LCUs, transferencias de salida NAT y monitoreo).
   - Ejecutar el procedimiento de retiro (`terraform destroy`) una vez concluida la evaluación para cesar los costos fijos de Azure.
