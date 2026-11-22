# Monitoreo y alertas

## AWS

CloudWatch tiene el dashboard `wimiline-operacion`, alarmas de destinos no saludables para web y API, CPU de RDS y errores 5XX del ALB. El tema SNS `wimiline-alertas` tiene una suscripción de correo confirmada. CloudTrail registra eventos administrativos y se verificó la entrega de registros al bucket privado de auditoría.

El respaldo publica las métricas `Wimiline/Backup/CopySuccess` y `CopyFailure`. La alarma de error evalúa cinco minutos y la alarma de ausencia evalúa una ventana de cuatro horas. Se observó CopySuccess tras la prueba de copia. Una alarma de ausencia pasó a OK tras recibir datos. El aviso de fallo real de respaldo y su entrega por correo no se provocaron como prueba.

La política de CPU de Auto Scaling dispone de alarmas administradas por AWS. Una carga sintética elevó la capacidad deseada 2→3→4. Tras el ensayo, Terraform devolvió el valor deseado a 2 y los procesos de carga se detuvieron.

## Azure

La VM de integración dispone de Azure Monitor Linux Agent, Log Analytics, una regla de recopilación de syslog, grupo de acciones y alerta de CPU. La instalación y la asociación se crearon por Terraform. Un evento de prueba de syslog de la VM se recibió en Log Analytics el 20/11/2026 a las 11:54:55 UTC. Falta probar el envío de un aviso por correo de Azure. El presupuesto de USD 20 genera alertas, pero no detiene el gasto.


## Corrección verificada del monitoreo RDS (20/11)

La alarma y el panel usaban el identificador interno inmutable de RDS, que no coincide con la dimensión DBInstanceIdentifier publicada en CloudWatch. Terraform se corrigió para usar `multiverso-db`; la alarma pasó a OK tras evaluar dos muestras aproximadas de 4,11 % y 4,30 %, por debajo del umbral de 80 %. La alarma de escala descendente del ASG puede estar en ALARM por CPU baja: es una señal de la política de escalamiento y no implica por sí sola una caída.


## Prueba de notificación Azure Monitor

El 20/11/2026 a las 20:04:17 UTC, una regla temporal de Azure Monitor para la CPU de la VM de integración pasó a Fired y el usuario confirmó la recepción del correo de ensayo en wimiline.info@gmail.com. La regla temporal se retiró mediante Terraform; la alerta real de CPU permaneció configurada. El comando de prueba incorporado del grupo de acciones devolvió Conflict: Free subscription not supported; por eso se utilizó una regla de prueba real.


## Fallo simulado de copia y aviso AWS

En una copia temporal del script se insertó un fallo intencional después de instalar el manejador de errores. El script publicó CopyFailure=1, la alarma wimiline-respaldo-azure-error pasó a ALARM y el usuario confirmó el correo SNS. La prueba no alteró respaldos reales. Es una inyección controlada y no demuestra todos los tipos de fallo.
