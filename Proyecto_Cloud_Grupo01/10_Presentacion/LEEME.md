# 10_Presentacion — Sustentación Técnica y Material Expositivo

Esta carpeta contiene todo el material necesario para la exposición académica, defensa ante el jurado y la entrega del video obligatorio conforme a la rúbrica y la página 18 de la plantilla del curso.

## Archivos de esta Carpeta

| Archivo | Formato | Propósito |
| --- | --- | --- |
| [Wimiline_sustentacion_v11.pptx](Wimiline_sustentacion_v11.pptx) | Presentación PowerPoint | Diapositivas oficiales de soporte para la sustentación (versión v11 consolidada). |
| [Guia_sustentacion.md](Guia_sustentacion.md) | Guía técnica | Guion estructurado de exposición, ruta para la demo en vivo y respuestas a preguntas clave. |
| [ENLACE_VIDEO_SUSTENTACION.txt](ENLACE_VIDEO_SUSTENTACION.txt) | Registro de enlace | Archivo formal para consignar el enlace del video explicativo obligatorio de 5 a 10 minutos. |
| [.build/](.build/) | Directorio de compilación | Scripts Node.js (`crear.mjs`, `redes.mjs`) e imágenes PNG generadas de cada diapositiva para auditoría rápida. |

## Requisito Obligatorio: Video Explicativo (5 a 10 Minutos)

El curso exige un video grabado con una duración de entre 5 y 10 minutos que demuestre la funcionalidad de la arquitectura multicloud sin requerir que el docente ingrese con credenciales a las consolas de AWS Academy o Azure for Students.

### Estructura Recomendada de Grabación:
1. **Min 0:00 – 1:30 | Presentación:** Presentar al equipo, la empresa Wimiline E.I.R.L. y la arquitectura multicloud adoptada.
2. **Min 1:30 – 3:30 | Portal en Producción:** Navegar en `https://multiverso.wimiline.com/`, verificar certificado TLS de navegador (candado verde) y consultar `/api/public/status`.
3. **Min 3:30 – 5:30 | Nube Principal (AWS):** Mostrar ALB con destinos saludables en dos AZs, instancias EC2 privadas, RDS PostgreSQL Multi-AZ y el dashboard de CloudWatch `wimiline-operacion`.
4. **Min 5:30 – 7:30 | Nube Secundaria (Azure):** Mostrar VNet de integración, Private Endpoint, contenedor Blob con respaldos recibidos, VM ARM64 y el presupuesto de alerta de USD 20.
5. **Min 7:30 – 9:00 | Pruebas de Continuidad y Contingencia:** Explicar el cron de 3 horas, el respaldo cruzado HTTPS con SAS/firewall y los resultados empíricos:
   - Reemplazo de EC2 con 75/75 respuestas HTTP 200 (100% disponibilidad).
   - Recuperación autónoma de base y datos en 268.2 s (~4 min 28 s), cumpliendo el RTO $\le 60$ min.
6. **Min 9:00 – 10:00 | Cierre:** Costo integral proyectado (USD 214.72/mes), conclusiones y recomendaciones.

> [!TIP]
> Una vez grabado el video en OBS, Teams, Zoom o similar, súbelo a YouTube (como *No listado* u *Oculto*) o a Google Drive/OneDrive institucional con permiso de lectura público e inserta el enlace en [ENLACE_VIDEO_SUSTENTACION.txt](ENLACE_VIDEO_SUSTENTACION.txt).
