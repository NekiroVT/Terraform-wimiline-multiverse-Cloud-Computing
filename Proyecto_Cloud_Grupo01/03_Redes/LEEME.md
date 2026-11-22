# 03_Redes — Segmentación, Direccionamiento y Topología

Esta carpeta contiene el diseño de red, direccionamiento IP y la topología técnica exigida por la plantilla del proyecto (página 18) y detallada en el informe del Entregable 3.

## Archivos de esta Carpeta

| Archivo | Formato / Referencia | Descripción |
| --- | --- | --- |
| [Topologia.png](Topologia.png) | **Figura 5 del informe** | **Topología detallada de red AWS–Azure V3:** Diagrama gráfico formal que ilustra las VPC/VNet, subredes públicas y privadas, zonas de disponibilidad (`us-east-1a`, `us-east-1b`, `South Central US`), puertas de enlace (IGW, NAT), Private Endpoints y controles perimetrales (Security Groups y NSGs). |
| [Direccionamiento_IP.xlsx](Direccionamiento_IP.xlsx) | Hoja de cálculo Excel | Matriz completa de segmentación con CIDRs, tipos de subred, zonas y propósitos. |
| [direccionamiento-preview.png](direccionamiento-preview.png) | Imagen PNG | Captura de vista previa de la tabla de direccionamiento. |
| [Rutas_y_segmentacion.md](Rutas_y_segmentacion.md) | Documento Markdown | Detalle técnico de las tablas de enrutamiento aplicadas en AWS y Azure, políticas de salida y aislamiento. |

## Resumen del Plan de Direccionamiento

### AWS (`us-east-1`) — VPC `10.10.0.0/16`
- **Subredes Públicas (Capa Web / ALB):**
  - `web-01`: `10.10.1.0/24` (AZ `us-east-1a`) — ALB interfaz A
  - `web-02`: `10.10.6.0/24` (AZ `us-east-1b`) — ALB interfaz B
  - *Rutas:* Local `10.10.0.0/16` y default `0.0.0.0/0` hacia Internet Gateway (IGW).
- **Subredes Privadas (Capa de Aplicación / EC2):**
  - `app-private-01`: `10.10.3.0/24` (AZ `us-east-1a`) — Nginx + Spring Boot API
  - `app-private-02`: `10.10.4.0/24` (AZ `us-east-1b`) — Nginx + Spring Boot API
  - *Rutas:* Local `10.10.0.0/16`, default `0.0.0.0/0` hacia NAT Gateway y Gateway Endpoint hacia Amazon S3 (`pl-63a5400a`).
- **Subredes Privadas (Capa de Datos / Amazon RDS):**
  - `db-01`: `10.10.2.0/24` (AZ `us-east-1b`) — PostgreSQL Multi-AZ
  - `db-02`: `10.10.5.0/24` (AZ `us-east-1a`) — PostgreSQL Multi-AZ
  - *Rutas:* Únicamente ruta local `10.10.0.0/16`. Sin acceso ni ruta por defecto a Internet.

### Microsoft Azure (`South Central US`) — VNet `10.20.0.0/16`
- **Subred de Integración y Recuperación:**
  - `snet-integracion`: `10.20.2.0/24` — VM de contingencia ARM64 (`Standard_B2pts_v2`). Salida a Internet vía Azure NAT Gateway; sin IP pública asignada a la interfaz.
- **Subred de Private Endpoint:**
  - `snet-private-endpoint`: `10.20.3.0/24` — Interfaz de red privada conectada directamente a la cuenta de Azure Storage (Blob).
