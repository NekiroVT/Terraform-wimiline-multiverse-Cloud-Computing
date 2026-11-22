# 01_Informe · Entregable 3 de Wimiline

**Proyecto:** Arquitectura multicloud AWS + Microsoft Azure para Wimiline E.I.R.L.  
**Curso:** Cloud Computing · Universidad Peruana Unión  
**Aplicación:** [Multiverso](https://multiverso.wimiline.com/)  
**Repositorio técnico:** [Terraform-wimiline-multiverse-Cloud-Computing](https://github.com/NekiroVT/Terraform-wimiline-multiverse-Cloud-Computing)

## Archivos de esta carpeta

| Archivo | Contenido |
| --- | --- |
| [Entregable_3_Final_Wimiline_V13_CC.docx](Entregable_3_Final_Wimiline_V13_CC.docx) | Informe final del Entregable 3 en Word editable. |
| [Proyecto_Final_Wimiline.pdf](Proyecto_Final_Wimiline.pdf) | El **mismo informe** en PDF (52 páginas), con las secciones 2–27 y anexos A–J. |
| [LEEME.md](LEEME.md) | Índice de consulta del informe y orientación hacia los demás archivos del proyecto. |

El archivo Word y el PDF **no son dos informes diferentes**. Son dos formatos del mismo Entregable 3. La denominación `Proyecto_Final_Wimiline.pdf` identifica el informe final del proyecto en este repositorio y conserva el contenido del Entregable 3.

## Contenido del informe

- **2–8:** resumen, empresa, problemática, requerimientos, modelos cloud y arquitectura.
- **9–13:** redes, direccionamiento, cómputo, almacenamiento, PostgreSQL y seguridad.
- **14–18:** alta disponibilidad, balanceo, escalabilidad, monitoreo y Terraform.
- **19–23:** continuidad del negocio, RTO/RPO, recuperación, costos, pruebas y resultados.
- **24–27:** conclusiones, recomendaciones, referencias y anexos oficiales A–J.

El informe conserva los resultados de las pruebas registradas. No afirma que su edición equivalga a ejecutar nuevas validaciones sobre AWS o Azure.

## Relación con el expediente digital

| Carpeta | Material complementario |
| --- | --- |
| [02_Arquitectura](../02_Arquitectura/) | Arquitecturas AWS, Azure e integración multicloud. |
| [03_Redes](../03_Redes/) | Direccionamiento, rutas y segmentación. |
| [04_IaC](../04_IaC/) | Configuración Terraform para AWS y Azure, scripts y guías. |
| [05_Seguridad](../05_Seguridad/) | Seguridad y restricciones de cuentas académicas. |
| [06_Pruebas](../06_Pruebas/) | Registros, evidencias y capturas de los ensayos. |
| [07_Monitoreo](../07_Monitoreo/) | Monitoreo de AWS y Azure, alarmas y notificaciones. |
| [08_Backup_DR](../08_Backup_DR/) | Respaldos, integridad y recuperación ante desastres. |
| [09_Costos](../09_Costos/) | Estimaciones económicas y controles de consumo. |
| [10_Presentacion](../10_Presentacion/) | Material para la explicación técnica. |

## Criterio de versiones y revisión

Esta guía describe **el contenido del paquete documental V13** y usa enlaces relativos, válidos al conservar juntos los tres archivos en `01_Informe`. No depende de un número de commit ni de afirmar si la publicación remota se produjo antes o después de preparar el documento.

El repositorio proporciona código y evidencias, pero no concede acceso automático a AWS Academy ni a Azure for Students. Los accesos autorizados y el video explicativo de 5–10 minutos se presentan aparte de este informe.

**Seguridad:** no incluir contraseñas personales, credenciales de laboratorio, tokens, SAS, claves privadas, `.tfstate`, `.tfvars` con secretos ni la carpeta `.terraform/`.
