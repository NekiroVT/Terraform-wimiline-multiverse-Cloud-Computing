# Terraform Microsoft Azure — Wimiline (Entregable 3)

Esta carpeta contiene la configuración completa de Infraestructura como Código (IaC) para los componentes de contingencia, monitoreo y respaldo en Microsoft Azure (`South Central US`).

## Estado Actual de la Infraestructura (Actualizado: 20/11/2026)

> [!NOTE]
> **Historial de Despliegue y Reconstrucción:**
> Tras una pausa inicial el 12/11/2026 para preservar créditos estudiantiles, la infraestructura de Azure fue **completamente reconstruida, configurada y verificada el 20/11/2026** con la arquitectura definitiva de contingencia multicloud:
> - **Cómputo:** VM Linux ARM64 (`Standard_B2pts_v2`) en subred privada `10.20.2.0/24`.
> - **Red y Seguridad:** VNet `10.20.0.0/16`, NAT Gateway para salida controlada, Network Security Groups (NSGs) bloqueando tráfico entrante de Internet.
> - **Almacenamiento:** Azure Blob Storage con Private Endpoint (`10.20.3.0/24`) y regla de firewall perimetral que autoriza exclusivamente las IPs del NAT Gateway de AWS (`35.172.14.7` y `100.48.128.175`) junto con una SAS limitada de escritura.
> - **Observabilidad:** Azure Monitor Linux Agent (AMA), Log Analytics Workspace, recopilación de eventos syslog y alerta por umbral de CPU.
> - **Presupuesto:** Presupuesto de alerta mensual configurado en **USD 20.00** con notificaciones preventivas por correo electrónico.

## Módulos y Archivos de Configuración

| Archivo | Propósito |
| --- | --- |
| [main.tf](main.tf) | Configuración del proveedor `azurerm` y definición del Resource Group principal (`rg-wimiline-multicloud`). |
| [integracion.tf](integracion.tf) | VNet (`10.20.0.0/16`), subredes (`snet-integracion`, `snet-private-endpoint`), NSGs, NAT Gateway e IP pública estática. |
| [respaldo_desde_aws.tf](respaldo_desde_aws.tf) | Storage Account, contenedor privado `respaldos-multicloud`, Private Endpoint con DNS privado, firewall de IPs NAT y token SAS de escritura. |
| [herramientas.tf](herramientas.tf) | Aprovisionamiento de la VM ARM64 (`Standard_B2pts_v2`) con identidad administrada asignada por el sistema y herramientas de restauración (AzCopy, AWS CLI ARM64). |
| [monitoreo.tf](monitoreo.tf) | Workspace de Log Analytics, Azure Monitor Linux Agent, Data Collection Rules (DCR) y alertas de CPU. |
| [presupuesto.tf](presupuesto.tf) | Configuración del presupuesto mensual de control de gasto (USD 20.00). |
| [ensayo_rto.tf](ensayo_rto.tf) | Recursos efímeros utilizados para la validación del RTO de recuperación autónoma. |
| [OPERACION_Y_PENDIENTES.md](OPERACION_Y_PENDIENTES.md) | Guía detallada de operación técnica, costos medidos y registros de verificación. |

## Seguridad y Retiro

- **Token SAS:** Expira el **19/12/2026 a las 19:00 (hora de Lima)**. Debe renovarse mediante este módulo antes de su vencimiento si se requiere continuar con la sincronización automática.
- **Desmantelamiento:** Seguir las instrucciones de [../GUIA_OPERACION_Y_RETIRO.md](../GUIA_OPERACION_Y_RETIRO.md) respetando el orden de destrucción para no dejar recursos con facturación fija activa (como NAT Gateway o Private Endpoint).
