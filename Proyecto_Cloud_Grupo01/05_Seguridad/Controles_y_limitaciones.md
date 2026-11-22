# Controles y limitaciones de seguridad — Wimiline

- Entrada: ALB público con HTTPS/ACM y redirección desde HTTP; los grupos de seguridad permiten a las EC2 únicamente tráfico del ALB en 80/8080.
- Datos: RDS PostgreSQL privado solo admite TCP 5432 desde el grupo de aplicación. La prueba desde el equipo externo resolvió una IP privada y agotó el tiempo de conexión; esto no sustituye una auditoría completa.
- Cifrado: EBS y RDS configurados cifrados; HTTPS hasta el ALB. Evitar afirmar cifrado extremo a extremo hasta verificar TLS también entre el ALB y la aplicación.
- Identidades: AWS Academy usa voclabs y LabInstanceProfile/LabRole. El entorno académico limita IAM; no se afirma mínimo privilegio integral. Azure usa identidad administrada con rol de contribución limitado al contenedor para la VM.
- Almacenamiento Azure: el endpoint público está habilitado con firewall predeterminado Deny, limitado a las IP del NAT AWS, y exige una SAS de escritura. La VM Azure accede mediante Private Endpoint. Revisar cambios de IP y renovar la SAS antes de 19/12/2026 19:00 Lima.
- Secretos: DB, JWT y SAS están en Parameter Store; estados y planes Terraform pueden contener secretos y deben protegerse. La política académica de LabRole impide afirmar que el acceso local a SSM esté limitado únicamente a un proceso.
- Auditoría y alerta: CloudTrail entrega registros a S3; CloudWatch/SNS supervisan aplicación y respaldos. Azure Monitor está configurado. El usuario confirmó la recepción de un correo de bienvenida de prueba. La contraseña de aplicación se guardó directamente como SecureString en Parameter Store; el parámetro fue creado por el usuario fuera del estado Terraform y requiere gestión independiente.
