# Wimiline: Terraform AWS y operación

Reconstrucción iniciada el 20/11/2026 en AWS Academy, región us-east-1. La infraestructura se gestiona desde esta carpeta. El estado local, planes y credenciales contienen información sensible y no deben compartirse. No se deben borrar los archivos de estado.

## Aplicar y revisar

Desde esta carpeta ejecutar `terraform init`, `terraform plan` y, después de revisar, `terraform apply`. El certificado ACM del dominio requiere validación DNS. La AMI Ubuntu usada está fijada en `ami_id` para evitar que el último parche publicado cambie el plan; revisar y actualizarla deliberadamente cuando corresponda. El código usa `multiverso-release-v3.zip` en esta carpeta, creado con el frontend existente y el backend compilado más reciente. Conservarlo junto con el código Terraform. Los secretos de base de datos y JWT están en Parameter Store y también en el estado sensible de Terraform.

## Particularidad AWS Academy y S3

La política de la organización deniega `s3:GetBucketObjectLockConfiguration`, lo que impide que el recurso `aws_s3_bucket` del proveedor lea incluso un bucket recién creado. Por ello los tres buckets se crean y eliminan mediante recursos `terraform_data` y `bucket_lifecycle.py`, que invoca AWS CLI. Los bloqueos públicos, versionado, objetos, política y retención se declaran con recursos Terraform normales. La existencia y el contenido de los buckets no se detectan como drift mediante `terraform_data`; comprobarlos con `aws s3api` al revisar el entorno. No crear otros buckets con estos nombres fuera de este estado.

## Respaldo y continuidad

Se acordó cambiar el flujo: dos EC2 ejecutan cron cada tres horas. Cada una exporta PostgreSQL a S3, descarga el archivo desde S3 y lo sube por HTTPS a Azure Blob con una SAS limitada de creación y escritura. La URL y la SAS se mantienen en SSM; el estado Terraform también contiene información sensible. Se verificó manualmente una ejecución automática de extremo a extremo y SHA-256 desde la VM Azure. Se probó además una restauración aislada con datos sintéticos. Aún falta observar un disparo automático del nuevo cron de tres horas sin intervención y medir el RTO integral.

El endpoint público de Storage permite solo las IP del NAT regional AWS (35.172.14.7 y 100.48.128.175); el Private Endpoint sigue para la VM Azure. La SAS configurada vence el 20/12/2026 a las 00:00 UTC (19/12 a las 19:00 en Lima); se debe renovar antes mediante Terraform en Azure y reaplicar AWS para actualizar Parameter Store. Las IP del NAT regional pueden cambiar o ampliarse: contrastarlas y actualizar la lista de Azure cuando ocurra. La alarma CopyFailure indica error y CopySuccess ausente durante 4 horas indica falta de copias. No almacenar SAS ni credenciales en documentos o capturas.

El despliegue depende de `respaldo.auto.tfvars` en cada carpeta: Azure habilita `habilitar_respaldo_desde_aws` y define `ips_nat_aws`; AWS habilita `habilitar_respaldo_azure`. El estado de AWS lee el estado local Azure, por lo que ambos deben conservarse juntos. La sesión AWS fue revocada durante una renovación; al reanudar se recuperaron instancias y servicio. Comprobar siempre la versión y salud de las instancias tras reiniciar el laboratorio.

## Eliminación futura

El usuario pidió poder eliminar lo creado con Terraform más adelante. La orden de destrucción debe ejecutarse solo cuando lo solicite expresamente. Revisar el plan y guardar antes cualquier dato requerido: este código elimina los objetos y sus versiones de los buckets y el RDS no genera snapshot final. La eliminación de AWS y Azure se ejecuta desde sus respectivas carpetas de estado; no borrar estados manualmente. IAM, permisos del laboratorio o retenciones ajenos podrían impedir parte de la limpieza y habría que verificar ambos inventarios al finalizar.

AWS Academy denegó StartInstanceRefresh mediante una política organizacional. Para desplegar el backend autorizado se actualizó la versión de la plantilla y se sustituyeron las instancias una a una, esperando destinos saludables; las sustituciones operativas por CLI no forman parte de terraform apply. El código elimina los recursos del grupo mediante Terraform cuando el usuario lo pida.

El parámetro `/multiverso/prod/gmail-app-password` fue creado directamente por el usuario y no está administrado en el estado Terraform. Al realizar una futura eliminación, consultar si debe conservarse o eliminarse por separado; no incluir su valor en archivos o capturas.
