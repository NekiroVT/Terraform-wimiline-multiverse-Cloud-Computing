# Guía para la Sustentación Técnica — Wimiline (Entregable 3)

## 1. Explicación Ejecutiva de la Solución

Wimiline E.I.R.L. partía de un esquema vulnerable: una única instancia no redundante y respaldos manuales. La solución multicloud V3 reconstruida y validada transforma esta situación en una arquitectura empresarial resiliente:
- **AWS (Producción):** Application Load Balancer (ALB) público con certificado ACM HTTPS que distribuye tráfico hacia dos instancias EC2 en subredes privadas repartidas en dos zonas de disponibilidad (`us-east-1a` y `us-east-1b`). La capa de datos utiliza Amazon RDS PostgreSQL administrado en modalidad Multi-AZ. Un Auto Scaling Group (ASG) mantiene 2 instancias base y escala automáticamente hasta 4 bajo política de uso de CPU al 60%.
- **Sincronización Multicloud de Respaldos:** Se ejecutan copias lógicas automáticas cada 3 horas mediante cron sincronizado (`15 */3 * * *` UTC) en ambas instancias. Cada respaldo genera un volcado PostgreSQL (`pg_dump`), su huella SHA-256 y un manifiesto `release.sha256` vinculado al paquete de versión instalado. El archivo se sube a S3 y se replica directamente por HTTPS hacia Azure Blob Storage.
- **Seguridad Perimetral en Azure:** Azure Blob Storage opera con firewall de red que rechaza todo tráfico de Internet salvo las IPs fijas del NAT Gateway de AWS (`35.172.14.7` y `100.48.128.175`) y exige un token SAS temporal con permisos estrictos de escritura.
- **Recuperación Ante Desastres (DR en Azure):** Una máquina virtual ARM64 (`Standard_B2pts_v2`) en subred privada accede al Blob Storage mediante Private Endpoint con identidad administrada. En el ensayo de recuperación autónoma, se restauró la base y se desplegó la aplicación vinculada en **268.2 segundos (~4 minutos con 28 segundos)** con código HTTP 200 en todos los servicios.

---

## 2. Demostración en Vivo Sugerida (Paso a Paso)

1. **Servicio en Producción:** Abrir `https://multiverso.wimiline.com/`, mostrar el candado HTTPS y comprobar el estado online de la API en `/api/public/status`.
2. **Consola AWS — Red y Alta Disponibilidad:**
   - Mostrar VPC `10.10.0.0/16`, subredes públicas (`web-01`, `web-02`) y privadas (`app-private-01`, `app-private-02`, `db-01`, `db-02`).
   - Mostrar el ALB con sus dos targets saludables y el Auto Scaling Group configurado (min 2, max 4).
   - Mostrar la instancia RDS PostgreSQL con estado Multi-AZ activo.
3. **Consola AWS — Observabilidad y Respaldo:**
   - Mostrar el bucket S3 con los respaldos recientes (`respaldo.dump`, `respaldo.dump.sha256`, `release.sha256`).
   - Mostrar el Dashboard CloudWatch `wimiline-operacion`, las métricas `CopySuccess`/`CopyFailure` y la alarma de ausencia de copias (ventana de 4 horas).
4. **Consola Microsoft Azure — Contingencia:**
   - Mostrar el Resource Group `rg-wimiline-integracion`, la VNet `10.20.0.0/16`, el Private Endpoint y el NAT Gateway.
   - Mostrar en Azure Blob Storage los volcados recibidos desde AWS por HTTPS con sus huellas coincidentes.
   - Mostrar la VM ARM64 con Azure Monitor Linux Agent (AMA) activo y el presupuesto de alerta preventiva configurado en USD 20.
5. **Código de Infraestructura (Terraform):**
   - Mostrar la organización modular en `04_IaC/terraform/aws/` y `04_IaC/terraform/azure/`.
   - Explicar cómo se gestionaron los tres buckets mediante `terraform_data` y AWS CLI para mitigar la restricción de Object Lock en AWS Academy.
6. **Resultados de Ensayos:**
   - Resaltar la prueba de sustitución controlada de EC2: **75 de 75 sondeos con código HTTP 200 (100% de disponibilidad)**.
   - Resaltar el ensayo de recuperación autónoma en Azure: **268.2 segundos**, cumpliendo holgadamente el RTO meta de 60 minutos.

---

## 3. Preguntas Frecuentes y Respuestas Clave

- **¿Por qué Microsoft Azure como segunda nube?**
  El responsable del proyecto coordinó y recibió la conformidad del docente para utilizar Azure for Students. La sincronización multicloud automatizada está plenamente implementada, protegida y probada entre ambas plataformas.
- **¿Por qué cambió el sentido de transferencia respecto al diagrama V3 inicial?**
  El entorno educativo de AWS Academy no permitió crear un proveedor OIDC federado ni un rol asumible por la VM de Azure (`implicitDeny`). Con la debida autorización de ingeniería, se implementó el envío push directo desde las EC2 hacia Azure Blob mediante HTTPS, restringido por firewall perimetral a las IPs del NAT de AWS y token SAS con fecha de expiración.
- **¿Qué ocurre si una instancia EC2 falla o se apaga?**
  El ALB detecta el fallo en los health checks y desvía inmediatamente el tráfico hacia la instancia saludable en la otra zona de disponibilidad. Simultáneamente, el Auto Scaling Group aprovisiona un reemplazo automático. Durante los ensayos se obtuvo 100% de disponibilidad (cero errores 5xx).
- **¿Qué significan RTO y RPO en este proyecto?**
  - **RTO (Recovery Time Objective):** Meta fijada en $\le 60$ minutos. En la práctica se midió una recuperación aislada en 4 min 28 s.
  - **RPO (Recovery Point Objective):** Meta fijada en $\le 6$ horas. Gracias a los respaldos cada 3 horas y la alarma de ausencia a las 4 horas, se garantiza un margen de seguridad amplio.
- **¿Cuál es el costo mensual de la solución?**
  - **Base Fija Mínima:** USD 198.70 / mes (AWS V2 histórica USD 145.99 + Azure base fija USD 52.71 a 730 horas).
  - **Costo Integral Proyectado V3:** **USD 214.72 / mes**, incorporando LCUs del balanceador, transferencias de datos salientes NAT hacia Azure, almacenamiento en S3/Blob y métricas de observabilidad.
- **¿Todo se administra con Terraform?**
  Sí, toda la topología está declarada en Terraform. En AWS se complementó con scripts invocados por `terraform_data` debido a directivas de permisos de AWS Academy (como la denegación de `StartInstanceRefresh` y Object Lock). El parámetro sensible `/multiverso/prod/gmail-app-password` fue creado manualmente en SSM Parameter Store por privacidad.

---

## 4. Requisito del Video Obligatorio

Consignar el enlace del video expositivo grabado (5 a 10 min) en el archivo [ENLACE_VIDEO_SUSTENTACION.txt](ENLACE_VIDEO_SUSTENTACION.txt).
Comprobar que el video sea accesible sin credenciales y cumpla con los 6 bloques temáticos detallados en [LEEME.md](LEEME.md).
