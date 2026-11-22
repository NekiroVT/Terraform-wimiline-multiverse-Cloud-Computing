# Diagramas de Wimiline — 20/11/2026

`Arquitectura_multicloud_implementada_2026-11-20.png` representa el flujo que se implementó y probó después de la autorización del usuario: RDS → S3 → EC2 → Azure Blob por HTTPS, con una SAS de escritura y firewall que permite las IP del NAT AWS. La VM Azure sigue accediendo por Private Endpoint y se usó para verificar y restaurar una copia.

El HTML y SVG conservados en `../Arquitectura V3 Oficial` son la referencia interactiva anterior. En ellos la VM Azure inicia la descarga desde S3; ese recorrido se probó una vez con URL temporal, pero no es el flujo programado adoptado finalmente. El diagrama anterior no debe usarse como evidencia del mecanismo automático sin explicar esta diferencia. La representación nueva es un resumen; la configuración detallada está en los módulos Terraform y los registros de prueba.

El endpoint público de Blob está habilitado con reglas de red de denegación predeterminada y dos IP NAT permitidas; no describir la cuenta como exclusivamente privada. La SAS vence el 19/12/2026 a las 19:00 en Lima. La aceptación de Azure como alternativa a OCI depende del docente.

El flujo actual también copia el paquete de aplicación a Azure Blob por una ruta identificada por SHA-256. Cada nuevo respaldo incluye una huella que vincula la versión instalada con el paquete. La recuperación aislada desde Azure se validó para datos y aplicación; DNS/TLS productivos no se conmutaron.
