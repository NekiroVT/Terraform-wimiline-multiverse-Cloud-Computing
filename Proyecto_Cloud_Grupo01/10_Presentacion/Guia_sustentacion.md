# Guía para la sustentación técnica

## Explicación de la solución

Wimiline partía de una instancia y respaldos manuales. La aplicación reconstruida recibe HTTPS mediante un ALB en AWS, que distribuye peticiones a dos instancias EC2 privadas en distintas zonas. La API usa PostgreSQL administrado con RDS Multi-AZ. El grupo Auto Scaling mantiene dos instancias y puede escalar hasta cuatro con un objetivo de CPU de 60 %.

Las copias lógicas se generan cada tres horas; se observó el disparo de las 21:15 UTC y se verificaron dos copias en Azure. El flujo autorizado es PostgreSQL → S3 → EC2 → Azure Blob: la EC2 envía por HTTPS con SAS limitada; el firewall de Storage acepta las IP NAT autorizadas. La VM de integración Azure accede a Blob por Private Endpoint y usa identidad administrada. En Blob se conserva también el paquete de aplicación vinculado por SHA-256 a cada nuevo respaldo; la recuperación aislada de datos y aplicación desde Azure se verificó en 4 min 28 s por HTTP restringido.

## Demostración sugerida

1. Abrir `https://multiverso.wimiline.com/` y mostrar el estado de la API en `/api/public/status`.
2. Mostrar en AWS las dos zonas, subredes, rutas, ALB, destinos saludables, ASG y RDS Multi-AZ. Explicar que las IP e identificadores pueden cambiar.
3. Mostrar un backup reciente en S3 y su par en Blob, sin revelar firmas SAS ni contraseñas. Consultar la alarma por ausencia de respaldos y la fecha de la última copia.
4. Mostrar dashboard CloudWatch, alarmas y suscripción SNS; en Azure, la VNet, Private Endpoint, Storage y Log Analytics. El estado de una alarma de escala descendente por CPU baja no representa necesariamente una avería.
5. Mostrar los archivos Terraform y ejecutar un plan de solo lectura desde los directorios originales con la sesión vigente. La copia de revisión no contiene estados ni variables sensibles y no debe usarse para administrar recursos activos.
6. Presentar las pruebas de sustitución de una instancia, escalamiento y recuperación con sus resultados y límites en `06_Pruebas` y `08_Backup_DR`.

## Preguntas y respuestas breves

- **¿Por qué Azure?** El responsable informó que el docente acepta Azure como segundo proveedor. La transferencia está implementada y probada entre ambas nubes.
- **¿Por qué cambió el flujo del diagrama V3?** AWS Academy no permitió crear la identidad federada prevista. Se autorizó que AWS envíe el respaldo a Azure con firewall y SAS limitados; la VM Azure conserva acceso privado a Blob.
- **¿Qué pasa si una EC2 falla?** El ALB deja de dirigirle tráfico cuando falla el health check y el ASG la sustituye. Se registraron 75 de 75 sondeos HTTP 200 durante una sustitución controlada.
- **¿Qué significan RTO y RPO?** Son metas de recuperación en 60 minutos y pérdida máxima aceptable de seis horas. Las copias cada tres horas y la alarma de cuatro horas aportan margen; su cumplimiento depende de la operación y de que el laboratorio permanezca activo.
- **¿Todo es Terraform?** La configuración de infraestructura se administra con Terraform; AWS Academy obliga a usar AWS CLI desde Terraform para el ciclo de buckets y una sustitución gradual de instancias. El SecureString de Gmail lo creó el usuario y está fuera del estado.
- **¿Cuánto cuesta?** La referencia parcial combinada es USD 198,70/mes con supuestos y fechas distintas; faltan cargos variables, impuestos y créditos. El presupuesto Azure de USD 20 avisa, pero no impide el gasto.

Comprobar estado y consumo antes de la exposición. Renovar la SAS antes del 19/12/2026 a las 19:00 hora de Lima.
