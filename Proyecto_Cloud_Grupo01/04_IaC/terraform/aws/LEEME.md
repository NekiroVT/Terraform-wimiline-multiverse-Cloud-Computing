# Wimiline: Terraform AWS y Operación (Entregable 3)

Reconstrucción implementada y validada el 20/11/2026 en AWS Academy, región `us-east-1`. La infraestructura productiva se gestiona desde esta carpeta. El estado local, planes y credenciales contienen información sensible y no deben compartirse.

## Aplicar y Revisar

Desde esta carpeta ejecutar `terraform init`, `terraform plan` y, después de revisar, `terraform apply`.
- **Certificado ACM:** El certificado TLS/ACM del dominio está validado y asociado al ALB HTTPS (puerto 443 con redirección forzada desde HTTP 80).
- **AMI Ubuntu:** Fijada en `ami_id` para garantizar inmutabilidad y predictibilidad en los planes de despliegue.
- **Paquete de Aplicación:** Se utiliza `multiverso-release-v3.zip` ubicado en esta carpeta, que contiene los binarios compilados de la API Spring Boot (`app.jar`) y el bundle empaquetado del frontend web.
- **Secretos:** Las credenciales de base de datos PostgreSQL y llaves JWT se gestionan mediante AWS Systems Manager (SSM) Parameter Store.

## Particularidad AWS Academy y S3

La directiva organizacional del entorno de laboratorio de AWS Academy deniega explícitamente `s3:GetBucketObjectLockConfiguration`. Debido a esto, el recurso estándar `aws_s3_bucket` falla al intentar leer buckets recién aprovisionados. 

Para sortear esta restricción sin comprometer la arquitectura:
- Los tres buckets (aplicación, respaldos y auditoría CloudTrail) se crean y eliminan mediante el recurso `terraform_data` ejecutando [bucket_lifecycle.py](bucket_lifecycle.py), que utiliza AWS CLI.
- El bloqueo de acceso público (`aws_s3_bucket_public_access_block`), el versionado, las políticas de bucket y la encriptación se configuran con recursos estándar de Terraform.
- Para verificar el contenido o drift de los buckets, consultar directamente con `aws s3api` o AWS CLI.

## Respaldo y Continuidad Verificados

El pipeline de continuidad y contingencia opera bajo un esquema multicloud activo-contingencia:
1. **Cron Automatizado de 3 Horas:** Ambas instancias EC2 del Auto Scaling Group ejecutan de forma sincronizada el cron `15 */3 * * *` (a los minutos 15 de las horas 00, 03, 06, 09, 12, 15, 18 y 21 UTC).
2. **Generación de Respaldos:** Cada ejecución produce un volcado lógico de PostgreSQL (`pg_dump`), calcula su huella digital SHA-256 (`respaldo.dump.sha256`) y genera el archivo `release.sha256` con la huella del paquete de aplicación instalado.
3. **Sincronización Multicloud:** El volcado se almacena en el bucket privado de S3 y se transmite de forma directa por HTTPS hacia Azure Blob Storage mediante una SAS limitada de escritura. El firewall de Azure Blob Storage restringe el ingreso exclusivamente a las IPs elásticas del NAT Gateway de AWS (`35.172.14.7` y `100.48.128.175`).
4. **Verificación en Producción:**
   - **Disparo Automático Comprobado:** El 20/11/2026 a las 21:15 UTC se observó y constató la ejecución automática del cron en ambas instancias, con recepción y validación de hash íntegra en Azure Blob.
   - **Medición de RTO Autónomo:** Se ejecutó con éxito el ensayo de recuperación aislada en Azure (`06_Pruebas/recuperacion-autonoma-azure.json`), logrando restaurar la base de datos y desplegar la versión vinculada de la aplicación en **268.2 segundos (~4 minutos con 28 segundos)** con respuestas HTTP 200 en todos los servicios, superando ampliamente la meta de RTO $\le 60$ min.
5. **Monitoreo y Alerta:** La métrica personalizada `CopySuccess` y `CopyFailure` supervisa las transferencias. Si no se registra una copia exitosa en una ventana de 4 horas, CloudWatch activa la alarma `wimiline-respaldo-azure-error` y notifica por SNS.

## Eliminación Futura y Desmantelamiento

Para destruir los recursos cuando finalice la evaluación académica:
1. Seguir la secuencia descrita en [../GUIA_OPERACION_Y_RETIRO.md](../GUIA_OPERACION_Y_RETIRO.md).
2. Recordar que `terraform destroy` en AWS vaciará y eliminará los buckets creados mediante el script auxiliar `bucket_lifecycle.py`.
3. El parámetro `/multiverso/prod/gmail-app-password` fue creado manualmente como `SecureString` fuera de Terraform y requiere ser conservado o retirado de forma independiente.
