# 01_Informe — Entregable 3 final de Wimiline

**Curso:** Cloud Computing · Universidad Peruana Unión  
**Proyecto:** Diseño e implementación de una arquitectura multicloud empresarial con AWS y Microsoft Azure para Wimiline E.I.R.L.  
**Aplicación:** [Multiverso](https://multiverso.wimiline.com/)  
**Repositorio:** [Terraform-wimiline-multiverse-Cloud-Computing](https://github.com/NekiroVT/Terraform-wimiline-multiverse-Cloud-Computing)

## ¿Qué es esta carpeta?

Contiene **el informe final del Entregable 3**. El Word y el PDF son **dos formatos del mismo informe**, no proyectos diferentes. `Proyecto_Final.pdf` es el nombre de archivo solicitado por la plantilla del curso.

## Archivos

| Archivo | Función |
| --- | --- |
| [`Proyecto_Final.pdf`](Proyecto_Final.pdf) | **Informe final en PDF**, listo para evaluación. Contiene 52 páginas, las secciones técnicas y los anexos A–J. |
| [`Entregable_3_Final_Wimiline_V12.docx`](Entregable_3_Final_Wimiline_V12.docx) | El **mismo informe en Word editable**, revisión V12 con correcciones de índice y estado de GitHub. |
| `LEEME.md` | Esta guía de consulta y trazabilidad del informe. |

## Contenido del informe

- **Secciones 2–8:** resumen, empresa, problemática, requerimientos y arquitectura cloud.
- **Secciones 9–13:** redes AWS/Azure, cómputo, almacenamiento, base de datos y seguridad.
- **Secciones 14–18:** alta disponibilidad, balanceo, escalabilidad, monitoreo y Terraform.
- **Secciones 19–23:** RTO/RPO, respaldos, recuperación, integración multicloud, costos, pruebas y resultados.
- **Secciones 24–27:** conclusiones, recomendaciones, referencias y **anexos A–J**.

Las cifras y resultados técnicos se presentan con el alcance y las limitaciones registrados en el propio informe. El PDF no acredita por sí solo el estado actual de los servicios en la nube.

## Documentación técnica complementaria

Los archivos originales del proyecto se organizan en las otras carpetas del mismo repositorio:

| Carpeta | Contenido relacionado |
| --- | --- |
| [`02_Arquitectura`](../02_Arquitectura/) | Diagramas e imágenes de la arquitectura AWS–Azure. |
| [`03_Redes`](../03_Redes/) | Direccionamiento IP, rutas y segmentación. |
| [`04_IaC`](../04_IaC/) | Código Terraform real de AWS y Azure, scripts y guías de operación. |
| [`05_Seguridad`](../05_Seguridad/) | Controles y restricciones de seguridad. |
| [`06_Pruebas`](../06_Pruebas/) | Evidencias, capturas y registros de ejecución. |
| [`07_Monitoreo`](../07_Monitoreo/) | Métricas, dashboards, alarmas y notificaciones documentadas. |
| [`08_Backup_DR`](../08_Backup_DR/) | Procedimiento de respaldo y recuperación. |
| [`09_Costos`](../09_Costos/) | Estimación de gastos y control presupuestario. |
| [`10_Presentacion`](../10_Presentacion/) | Material de exposición y guías. |

## Cómo incorporar esta carpeta a GitHub

1. Extraer el ZIP del paquete en tu equipo.
2. Abrir `Proyecto_Cloud_Grupo01/01_Informe/` dentro del repositorio.
3. Subir **los tres archivos** de esta carpeta, no el ZIP completo dentro de `01_Informe`.
4. Confirmar los cambios con **Commit changes**.
5. Abrir los enlaces del PDF y del Word en GitHub para comprobar que la carga terminó correctamente.

**Importante:** este `LEEME.md` no afirma que los archivos ya estuvieran publicados. Su disponibilidad en GitHub solo queda confirmada después de efectuar el commit. El archivo `.gitkeep`, si todavía está presente, es únicamente un marcador de carpeta.

## Seguridad y revisión

No compartir contraseñas, claves SSH privadas, SAS, tokens de sesión, estados `terraform.tfstate`, carpetas `.terraform/` ni variables privadas. La revisión de recursos de AWS Academy y Azure for Students debe utilizar los mecanismos autorizados por cada plataforma; el informe no concede permisos de acceso automáticamente.

**Fecha de preparación del informe:** 22 de noviembre de 2026.  
**Formato oficial de entrega del informe:** PDF; Word añadido como versión editable.
