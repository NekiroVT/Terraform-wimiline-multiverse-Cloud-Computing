# Diagramas de Arquitectura — Wimiline (Entregable 3)

Esta carpeta reúne las representaciones visuales independientes exigidas por la plantilla del proyecto de Cloud Computing (página 18), así como los diagramas oficiales integrados en el informe final.

## Inventario de Diagramas Independientes

| Archivo | Figura en Informe | Descripción y Alcance |
| --- | --- | --- |
| [Arquitectura_general.png](Arquitectura_general.png) | **Figura 1** | **Arquitectura lógica general multicloud:** Vista conceptual de alto nivel que ilustra la interacción entre clientes, DNS, AWS (capas web, app, datos) y Microsoft Azure (contingencia). |
| [Arquitectura_AWS.png](Arquitectura_AWS.png) | **Figura 2** | **Arquitectura AWS V3 implementada:** Despliegue en `us-east-1`, Application Load Balancer público con HTTPS (ACM), Auto Scaling Group con EC2 privadas en dos AZs (`us-east-1a` y `us-east-1b`), RDS PostgreSQL Multi-AZ, buckets S3 privados, colas SQS, funciones Lambda y CloudWatch. |
| [Arquitectura_Azure_implementada.png](Arquitectura_Azure_implementada.png) | **Figura 3** | **Arquitectura de integración Microsoft Azure:** VNet (`10.20.0.0/16`), subredes privadas en `South Central US`, Private Endpoint para Blob Storage, NAT Gateway, Azure Monitor con Log Analytics y VM ARM64 (`Standard_B2pts_v2`) con identidad administrada. |
| [Arquitectura_multicloud_implementada_2026-11-20.png](Arquitectura_multicloud_implementada_2026-11-20.png) | **Figura 4** | **Arquitectura empresarial multicloud integral:** Flujo físico y operativo definitivo verificado el 20/11/2026. Detalla la extracción PostgreSQL $\rightarrow$ S3 $\rightarrow$ EC2 $\rightarrow$ Azure Blob vía HTTPS protegida con SAS y firewall de IPs NAT elásticas de AWS. |
| [Arquitectura_multicloud_implementada_2026-11-20.svg](Arquitectura_multicloud_implementada_2026-11-20.svg) | Figura 4 (Vectorial) | Versión vectorial SVG de alta definición generada automáticamente por código. |
| [generar_diagrama.py](generar_diagrama.py) | Herramienta | Script en Python (`matplotlib`) que genera programáticamente los diagramas PNG y SVG de la arquitectura multicloud. |
| [Wimiline_Arquitectura_V3_implementada.html](Wimiline_Arquitectura_V3_implementada.html) | Histórico | Visor interactivo preliminar conservado como trazabilidad de diseño. |

## Notas Técnicas sobre la Implementación

1. **Flujo Efectivo de Respaldo:** El diseño definitivo ejecuta el respaldo desde las instancias EC2 en AWS enviando los volcados y el paquete de aplicación (`multiverso-release.zip`, identificado por SHA-256) hacia Azure Blob Storage a través de HTTPS. La cuenta de almacenamiento en Azure deniega todo tráfico público excepto las IPs públicas fijas de salida del NAT Gateway de AWS (`35.172.14.7` y `100.48.128.175`) y exige un token SAS de escritura temporal.
2. **Acceso Privado en Azure:** La máquina virtual de Azure (`Standard_B2pts_v2`) accede al contenedor de Blob mediante Private Endpoint (`10.20.3.0/24`) y resolución DNS privada, autenticada mediante identidad administrada con rol de colaborador de datos.
3. **Vigencia del Token SAS:** La SAS operativa vence el **19/12/2026 a las 19:00 hora de Lima (20/12/2026 00:00 UTC)**. Su renovación se gestiona mediante Terraform en Azure y se sincroniza en Parameter Store de AWS.
