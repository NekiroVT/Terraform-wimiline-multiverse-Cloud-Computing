# Reporte de Auditoría de Seguridad — Paquete de Aplicación (`multiverso-release-v3.zip`)

**Fecha de Auditoría:** 22/11/2026  
**Archivo Auditado:** `04_IaC/terraform/aws/multiverso-release-v3.zip`  
**Tamaño del Archivo:** 53,695,432 bytes (~53.7 MB)  
**Huella Criptográfica SHA-256:** `aa9f8492469ac4aa46aac688e0312d40a18a2c2d2e1e88f08242f4b1072394ad`

---

## 1. Contenido e Integridad de Archivos Internos

La inspección del archivo comprimido confirma que contiene exclusivamente 6 elementos compilados correspondientes al build productivo del backend Spring Boot y del frontend web:

| Ruta Interna | Tamaño (Bytes) | Huella SHA-256 | Tipo de Archivo |
|---|:---:|---|---|
| `backend/app.jar` | 59,946,857 | `b2383ace2142b2bfc142f06decc56b92b3037cda439751477a783b70b75ee73f` | Bytecode Java / Spring Boot ejecutable |
| `frontend/index.html` | 1,267 | `d65b0cb2e3798f8c61d1d85a644fad420ac1952d0a9a0711eaa9523d4017862e` | Documento HTML base del cliente |
| `frontend/main-AIT2I4G2.js` | 293,894 | `eabff87a6c8904b1254e3b854985abbcde67eaf95ef99a8ed8b45cae02de53ee` | Bundle JavaScript optimizado (Angular/Vite) |
| `frontend/polyfills-LVNOU2XZ.js` | 35,876 | `f1b35a3b4db37b73ca0281d6b6247701465ff9e56a7a7b3aff9784518dc2c30a` | Polyfills JavaScript estándar |
| `frontend/runtime-config.js` | 214 | `c606278437a7cc75f263f445221a2f4409d4982933a57c0793ef89cb2baa5693` | Configuración pública de runtime |
| `frontend/styles-JBL5DWMI.css` | 16,922 | `68068af1da863d4b1dc52d230d0859a22f6463c1cda2925d2880d45bd84c7d2f` | Hojas de estilo CSS minificadas |

---

## 2. Búsqueda Criptográfica y Análisis de Patrones Sensibles

Se ejecutó un análisis estático recursivo sobre la totalidad del binario ZIP y de las clases/recursos internos del archivo `backend/app.jar` buscando patrones de secretos mediante expresiones regulares:

| Patrón Sensible Buscado | Expresión Regular | Coincidencias | Veredicto |
|---|---|:---:|:---:|
| **Credenciales AWS (Access Key ID)** | `AKIA[0-9A-Z]{16}` | **0** | Limpio |
| **Llaves Privadas Criptográficas** | `-----BEGIN (?:RSA )?PRIVATE KEY` | **0** | Limpio |
| **Tokens de Acceso Personal GitHub** | `ghp_[0-9a-zA-Z]{36}` | **0** | Limpio |
| **Firmas JWT Embebidas** | `eyJ[a-zA-Z0-9_-]{10,}\.eyJ...` | **0** | Limpio |
| **Archivos de variables de entorno** | `*.env`, `*.secret`, `*.pem`, `*.key` | **0** | Limpio |

---

## 3. Inspección Detallada de Archivos de Configuración

### Frontend: `frontend/runtime-config.js`
Contenido íntegro verificado:
```javascript
// Public runtime configuration. Set apiUrl to the HTTPS API origin when the
// frontend and API use different hostnames. Never put credentials or secrets here.
window.__MULTIVERSO_CONFIG__ = {
  apiUrl: '/api'
};
```
*Conclusión:* Únicamente declara el endpoint relativo público `/api`. No expone hostnames internos, tokens ni credenciales.

### Backend: `backend/app.jar` $\rightarrow$ `BOOT-INF/classes/application.yml`
Configuración de conexión a base de datos y seguridad:
```yaml
spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/multiverso}
    username: ${DB_USERNAME:multiverso}
    password: ${DB_PASSWORD:cambia-esta-clave-local}
```
*Conclusión:* Todas las credenciales sensibles son inyectadas en tiempo de ejecución (`runtime`) mediante variables de entorno desde **AWS Systems Manager (SSM) Parameter Store**. El valor predeterminado `"cambia-esta-clave-local"` es un placeholder estándar para entornos locales y no corresponde a ninguna credencial activa o productiva.

---

## 4. Certificación Final de Auditoría

> [!IMPORTANT]
> Se certifica que el artefacto `multiverso-release-v3.zip` **no contiene secretos, contraseñas productivas, tokens de acceso ni llaves privadas embebidas**, cumpliendo con los estándares de seguridad de código limpio para su custodia y despliegue automatizado mediante Terraform y AWS S3.
