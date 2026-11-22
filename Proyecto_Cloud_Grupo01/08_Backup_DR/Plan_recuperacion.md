# Continuidad y recuperación — Wimiline

## Alcance y objetivos del proyecto

Activos críticos: frontend, API, PostgreSQL, ALB, configuración, almacenamiento y permisos. El responsable del proyecto aceptó un RTO de 60 minutos para recuperar la aplicación y un RPO de 6 horas para los datos. Son objetivos del proyecto; no son una garantía automática. La recuperación integral del servicio público aún requiere ensayo y medición.

## Respaldo implementado

RDS dispone de copias automáticas con retención configurada de siete días. Cada EC2 de aplicación tiene un cron a los minutos 15 de las horas 00, 03, 06, 09, 12, 15, 18 y 21 UTC. Crea pg_dump de PostgreSQL, manifiesto SHA-256, carga ambos a S3 privado, descarga el archivo desde S3 y lo envía a Azure Blob por HTTPS. Cada instancia genera su propia copia; esto puede duplicar almacenamiento. La SAS solo permite escritura/creación y caduca el 20/12/2026 00:00 UTC (19/12 a las 19:00 en Lima). Se gestiona en Terraform/SSM; no incluirla en capturas o informes. Azure acepta tráfico al endpoint público solo de las IP actuales del NAT regional AWS; la VM Azure usa Private Endpoint.

CloudWatch tiene alarmas ante errores y ausencia de copias durante cuatro horas; el período de alerta no garantiza el RPO objetivo de seis horas. La confirmación SNS fue aceptada. Revisar los avisos, las IP del NAT y la vigencia de SAS. Si se interrumpe el laboratorio AWS, los respaldos también pueden detenerse; verificar el tiempo real del último respaldo.

## Procedimiento de recuperación

1. Declarar el incidente, registrar hora de inicio y comprobar el alcance. Seleccionar el último respaldo íntegro y registrar su marca temporal.
2. En un entorno aislado, recuperar respaldo.dump, respaldo.dump.sha256 y release.sha256 desde el contenedor Blob con identidad autorizada y Private Endpoint. Verificar la base; leer la huella de release.sha256, descargar releases/<huella>/multiverso-release.zip y verificar también su SHA-256. Los respaldos anteriores a la actualización no tienen release.sha256 y requieren identificar una versión de aplicación compatible.
3. Restaurar con pg_restore en una base PostgreSQL aislada de versión compatible, sin sobrescribir la base productiva. Confrontar cantidades y huellas de tablas relevantes.
4. Preparar la aplicación con configuración y secretos autorizados para apuntar a la base recuperada; verificar registro/inicio de sesión, rutas, permisos y datos representativos.
5. Autorizar y ejecutar el cambio al servicio recuperado, comprobar HTTPS y destinos saludables. Registrar el tiempo hasta servicio útil y la antigüedad del último dato recuperado para comparar con RTO/RPO establecidos.
6. Registrar evidencias, incidentes y responsabilidades; restaurar configuraciones temporales y mantener la última copia válida.

## Pruebas observadas

El 20/11 se comprobó copia S3→Azure con SHA-256. Se restauró una copia anterior con datos sintéticos en PostgreSQL aislado: app_user=1, registration_outbox=1 y flyway_schema_history=2; la huella de app_user coincidió con AWS. La copia y restauración demoraron 7 segundos para un archivo pequeño, sin recuperación integral de la aplicación: no equivale al RTO empresarial. Después de renovar AWS se ejecutó el mismo script mediante un cron de prueba de una sola vez y se verificó el archivo en Azure. Posteriormente se observó el cron regular anterior de seis horas.

En una prueba adicional, se inició temporalmente el backend en localhost de la VM Azure contra la base restaurada; el estado, el registro y el inicio de sesión devolvieron HTTP 200. El arranque y verificaciones tardaron 10 segundos, excluyendo la descarga del artefacto, preparación, frontend y publicación externa. La prueba no establece el RTO integral.

El cron regular de las 12:15 UTC del 20/11 produjo dos copias que se verificaron en Azure mediante SHA-256. A las 15:09:23 UTC la última copia comprobada, iniciada a las 12:15:04 UTC, tenía 2 h 54 min 19 s de antigüedad: menor que la meta de 6 horas en esa observación, sin demostrar el RPO bajo cualquier falla.

Tras la autorización del usuario se configuró cron `15 */3 * * *` en las dos instancias y una alarma por ausencia de copia durante cuatro horas. El 20/11, ambas instancias ejecutaron manualmente el mismo script y Azure verificó sus archivos por SHA-256. El 20/11 a las 21:15 UTC, ambas instancias produjeron copias programadas en S3 que se descargaron desde Azure y pasaron SHA-256. Esas copias preceden a la actualización que incorpora el paquete de aplicación.

## Ensayo público aislado del 20/11/2026

El 20/11/2026 se ensayó una recuperación aislada en una VM temporal de Azure, a partir de una copia verificada por SHA-256. La web y API respondieron en 7 min 26 s; el registro y el inicio de sesión devolvieron HTTP 200 al cabo de 9 min 21 s desde el inicio, incluyendo demoras de comprobación. La copia tenía aproximadamente 5 min 50 s al iniciar el ensayo. Esta prueba usó HTTP restringido a una IP y no midió la conmutación real del dominio, DNS ni certificado HTTPS productivos; por ello no demuestra el RTO integral ni garantiza el RPO.

## Ensayo HTTPS aislado

El 20/11/2026 se realizó un segundo ensayo aislado con HTTPS, certificado emitido previamente para multiverso.wimiline.com, resolución local forzada a la VM de recuperación y origen restringido a una IP. Web y API respondieron HTTP 200 a los 337,1 s; registro y login devolvieron HTTP 200 a los 338,7 s (5 min 39 s), desde la creación inicial del entorno. Incluye una corrección y reintento durante la recuperación. La copia tenía aproximadamente 32 min de antigüedad al iniciar. La emisión del certificado y el cambio de DNS productivo no forman parte del tiempo; no se realizó una conmutación real.


## Reintento y acceso no autorizado

Se cargó dos veces un mismo objeto sintético a la misma ruta de Azure Blob desde EC2 usando el flujo HTTPS autorizado. Desde la VM privada de Azure se recuperó el objeto con identidad administrada y se verificó SHA-256 acc25a7f6a85c33f6098b00537991b5a005ff2a848def3b53cd46bf7d42b8582; luego se eliminó el objeto sintético. Una solicitud al endpoint público sin autorización desde el equipo de prueba devolvió HTTP 403. La prueba verifica el objeto vigente y no evalúa versiones históricas si la configuración de almacenamiento cambia.


## Recuperación de datos y aplicación desde Azure

El paquete de la aplicación se conserva en Blob mediante una ruta identificada por su SHA-256. Cada nuevo respaldo incluye release.sha256, que vincula la base con la versión instalada en la EC2 que lo produjo. La copia se hace por el flujo EC2 → Blob aprobado y la identidad privada de Azure permite recuperarla sin solicitar un enlace de S3. Las EC2 guardan una marca local por cuenta/contenedor y huella para evitar subir el mismo paquete de 54 MB en cada ejecución; si se borra o altera manualmente el objeto de Azure, esa marca no detecta el cambio y se debe reparar la copia.

Una VM aislada recuperó desde Blob respaldo.dump y el paquete vinculado, verificó ambos con SHA-256 y arrancó frontend y API; registro y login dieron HTTP 200 a los 268,2 segundos desde el inicio del ensayo. La prueba fue HTTP restringido y no conmutó DNS o TLS productivo. Se conserva la prueba anterior de HTTPS con resolución local forzada como evidencia separada.
