# Restricciones y alternativas — AWS Academy y Azure

Estado contrastado el 20/11/2026. Las restricciones dependen del laboratorio y pueden cambiar; no se extrapolan a todas las cuentas AWS.

## 1. Lectura de Object Lock en buckets S3

- Operación: `s3:GetBucketObjectLockConfiguration`.
- Resultado: denegación explícita de la organización. El proveedor de Terraform necesita esta lectura para administrar el recurso S3 normal y falló después de crear el primer bucket.
- Alternativa: `terraform_data` invoca AWS CLI para crear y eliminar los buckets; los bloqueos de acceso público, objetos, políticas y versionado usan recursos Terraform. El plan de `terraform_data` no detecta todos los cambios manuales en los buckets; deben comprobarse por separado.
- Impacto en arquitectura: no cambia el flujo de S3; cambia cómo se administra. El estado y scripts deben conservarse para la eliminación futura.

## 2. Actualización automática de instancias del Auto Scaling Group

- Operación: `autoscaling:StartInstanceRefresh`.
- Resultado: denegación explícita de la organización durante el despliegue.
- Alternativa: actualizar la plantilla mediante Terraform y sustituir las instancias una por una con AWS CLI, comprobando salud entre sustituciones. Una prueba de falla registró 75 respuestas 200 de 75 sondeos. El escalamiento por CPU fue probado de 2 a 4 instancias.
- Impacto: la infraestructura y el ASG siguen gestionados con Terraform, pero la renovación gradual no se puede afirmar como completamente automática en esta cuenta.

## 3. Rol e identidad federada AWS para Azure

- Operaciones: `iam:CreateRole` e `iam:CreateOpenIDConnectProvider`.
- Resultado: la simulación IAM devolvió `implicitDeny`; no se disponía de un rol/proveedor OIDC configurado para la VM Azure.
- Alternativa autorizada por el usuario: una EC2 descarga el respaldo desde S3 y lo envía a Azure Blob con HTTPS y una SAS limitada de escritura. El endpoint público de Blob solo permite las IP de salida del NAT regional AWS y el Private Endpoint se conserva para la VM Azure. Se verificaron una transferencia y un disparo real del cron en ambas nubes.
- Impacto: cambia el sentido del flujo de la V3 inicial. La representación vigente es `02_Arquitectura/Arquitectura_multicloud_implementada_2026-11-20.png`; el SVG/HTML anteriores se conservan como referencia histórica. La SAS vence el 19/12/2026 a las 19:00 en Lima; debe renovarse y verificar las IP NAT.

## 4. Consulta de precios AWS mediante API

- Operación: `pricing:GetProducts`.
- Resultado: denegación explícita en la simulación IAM.
- Alternativa: referencia AWS del Entregable 2 y Azure Retail Prices para las partidas Azure. La combinación de USD 198,70/mes es una base parcial referencial con fechas y supuestos distintos, no cotización ni factura; faltan cargos variables y consumo real.
- Impacto: ninguno en la arquitectura; limita la precisión del presupuesto.

## 5. Sesión temporal y permisos del laboratorio

- Resultado observado: durante una suspensión se aplicó la política `voc-cancel-cred`; la sesión perdió permisos y las EC2 fallaron al iniciar por denegación temporal de KMS. La web devolvió 503. Tras renovar la sesión se lanzaron dos instancias y la web/API volvieron a 200.
- Alternativa: renovar la sesión de AWS Academy y verificar el estado; CloudWatch, Auto Scaling y RDS ayudan a supervisar y recuperar recursos mientras el laboratorio está autorizado. No son garantía contra el vencimiento o suspensión del laboratorio.
- Impacto: la disponibilidad depende del entorno académico; no se puede garantizar una auditoría integral de mínimo privilegio sobre LabRole/LabInstanceProfile.

## 6. Capacidad de VM Azure, fuera de AWS Academy

Azure rechazó B1s, B1ms y B2s por falta de capacidad en South Central US. Se seleccionó Standard_B2pts_v2 ARM64 en la misma región y se adaptaron AWS CLI y AzCopy a ARM. Se conservaron la VNet, subredes y Private Endpoint previstos.

## Parámetro Gmail y destrucción

`/multiverso/prod/gmail-app-password` es un SecureString creado directamente por el usuario en Parameter Store; Lambda lo usa y el correo de prueba fue recibido. No forma parte del estado Terraform. No contiene información que se deba añadir al informe. Ante una futura solicitud de eliminar recursos, decidir con el usuario si conservarlo o eliminarlo por separado. Los estados y planes Terraform contienen secretos y no deben compartirse.


## 7. Función de prueba de grupo de acciones Azure

La operación de prueba directa `az monitor action-group test-notifications create` devolvió `Conflict: Free subscription not supported` en esta suscripción. Para comprobar el flujo se creó con Terraform una alerta temporal de métricas; Azure registró Fired y el usuario confirmó la recepción del correo. La regla temporal se eliminó con Terraform y la alerta operativa permaneció configurada. Esta observación no implica que todas las alertas de Azure estén bloqueadas.
