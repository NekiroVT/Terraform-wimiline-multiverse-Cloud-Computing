# Operación y retiro de infraestructura

No ejecutar esta guía mientras se desee conservar el servicio. El retiro elimina aplicación, red, bases de datos y respaldos gestionados; decidir primero qué datos se deben conservar y verificar las cuentas y suscripciones activas. Los estados contienen secretos y no deben compartirse.

## Antes de operar

- Usar los directorios originales `aws` y `azure`, sus estados y las credenciales de las cuentas correctas. La carpeta de revisión excluye estados y no sirve para administrar los recursos activos.
- Confirmar en AWS la sesión de Academy y región `us-east-1`; en Azure confirmar suscripción y establecer `TF_VAR_subscription_id` sin publicar su contenido.
- Para cambios habituales, obtener y revisar `terraform plan` antes de aplicar; evaluar costo y disponibilidad. La SAS Azure caduca el 19/12/2026 a las 19:00 hora de Lima y debe renovarse antes mediante Terraform Azure y después actualizar AWS.

## Retiro futuro, únicamente cuando se solicite

1. Respaldar o exportar lo que se deba conservar y revisar explícitamente que la destrucción es deseada. `terraform destroy` destruye los objetos y versiones de los buckets controlados por el proyecto.
2. En el directorio original `aws`, revisar `terraform plan -destroy` y después ejecutar `terraform destroy`. Este orden conserva el estado de Azure mientras AWS consulta sus salidas. El mecanismo de buckets usa Terraform y un script con AWS CLI; mantener Python, AWS CLI y el archivo `bucket_lifecycle.py` disponibles.
3. Al terminar AWS y verificar su inventario, revisar `terraform plan -destroy` y ejecutar `terraform destroy` en `azure` con la misma suscripción. Comprobar en ambos proveedores que no queden recursos ni cargos activos atribuibles al proyecto.
4. El SecureString `/multiverso/prod/gmail-app-password` fue creado por el usuario fuera del estado Terraform; no se eliminará automáticamente. Decidir expresamente si se conserva o retira por separado. Eliminarlo detiene el envío de bienvenidas, sin eliminar la cuenta de Gmail.
5. El DNS del dominio y el certificado externo temporal de ensayo no están gestionados por esos estados. El certificado temporal de prueba se revocó; revisar y retirar manualmente únicamente los registros DNS que el responsable indique.

El script de buckets se probó localmente con 1001 versiones simuladas, en lotes de 1000 y 1; esto no equivale a haber ejecutado una destrucción real. Las restricciones o permisos de Academy pueden variar cuando se intente el retiro.
