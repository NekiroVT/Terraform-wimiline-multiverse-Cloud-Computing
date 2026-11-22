# Rutas y segmentación implementadas — 20/11/2026

Comprobación mediante Terraform y consultas de tablas de rutas AWS. La VPC usa 10.10.0.0/16; Azure VNet usa 10.20.0.0/16. No hay peering o VPN entre ambas: la integración se realiza mediante HTTPS al endpoint autorizado de Blob.

| Capa | Red / subred | Rutas y acceso |
|---|---|---|
| AWS pública | web1 10.10.1.0/24 y web2 10.10.6.0/24 | Ruta local 10.10.0.0/16 y 0.0.0.0/0 hacia Internet Gateway; ALB TCP 80 y 443. |
| AWS aplicación | app1 10.10.3.0/24 y app2 10.10.4.0/24 | Ruta local, ruta por defecto a NAT regional y lista de prefijos S3 al Gateway Endpoint. Entrada TCP 80/8080 desde el SG del ALB. |
| AWS base de datos | db1 10.10.2.0/24 y db2 10.10.5.0/24 | Utilizan tabla principal con ruta local; no tienen ruta por defecto a Internet. TCP 5432 solo desde el SG de aplicación. |
| Azure integración | 10.20.2.0/24 | VM privada sin IP pública; salida por NAT. La resolución privada dirige Blob a Private Endpoint. |
| Azure Private Endpoint | 10.20.3.0/24 | Dirección privada de Blob dentro de la VNet; la VM usa identidad administrada con permisos al contenedor. |

El endpoint público de Azure Storage se usa para recibir desde AWS y está limitado por firewall a las IP de salida autorizadas y por SAS; el Private Endpoint de la VM sigue operativo. La tabla asociada al NAT regional tiene su propia ruta al IGW; no es la tabla principal de las subredes de base de datos.
