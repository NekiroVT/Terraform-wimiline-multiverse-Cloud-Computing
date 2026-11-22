# Costos y control — revisión 20/11/2026

## Estimación base orientativa

Se consideran 730 horas al mes con los recursos principales permanentemente activos. No es una cotización ni una factura: las tarifas, créditos y consumo varían. Los datos AWS son referencias del Entregable 2 consultadas el 04/11/2026; las tarifas Azure se consultaron en Azure Retail Prices el 20/11/2026.

| Concepto | Supuesto | USD/mes |
|---|---|---:|
| AWS V2 reconstruida | Referencia histórica del Entregable 2, sin V1, misma capacidad básica | 145,99 |
| Azure VM Linux B2pts v2 | 0,0101/h × 730 h | 7,37 |
| Azure NAT Gateway estándar | 0,045/h × 730 h | 32,85 |
| Azure Private Endpoint | 0,010/h × 730 h | 7,30 |
| Azure IP pública estándar | 0,005/h × 730 h | 3,65 |
| Azure disco HDD S4 LRS | Disco de 30 GiB, facturado en nivel 32 GiB | 1,54 |
| **Azure base parcial** | Suma de las cinco partidas Azure, antes de redondeo | **52,71** |
| **Referencia conjunta parcial** | AWS histórica + Azure base parcial | **198,70** |

AWS sigue siendo una referencia anterior, no una cotización confirmada de la reconstrucción. Se excluyen capacidad adicional temporal del escalamiento, LCU del ALB, procesamiento y transferencia NAT, tráfico entre nubes, solicitudes, Blob/S3, DNS, logs, monitoreo, impuestos y otros consumos. Azure NAT añade una tarifa de referencia de USD 0,045 por GB procesado. Los componentes variables y el uso real pueden elevar el total. El resultado de Cost Explorer de USD 0 no confirma gasto nulo: puede existir retraso o tratamiento particular de créditos académicos.

Fuente Azure: API pública https://prices.azure.com/api/retail/prices, consultas por SKU/región y por medidores Standard Gateway, Standard Private Endpoint, Standard IPv4 Static Public IP y S4 LRS Disk. Fuente AWS: tabla detallada del Entregable 2 final; volver a contrastar en la calculadora de AWS y facturación de la cuenta.

## Presupuesto y acciones

Azure tiene un presupuesto mensual del grupo de USD 20 con avisos al 50 %, 80 % y 100 %. **Es una alerta y no detiene el gasto.** La base parcial de Azure estimada supera ese presupuesto si funciona 730 horas. NAT, IP, Private Endpoint y disco pueden continuar facturándose aunque la VM se desasigne. Consultar consumo real y créditos de ambos proveedores; planificar las horas de operación y eliminar los recursos mediante Terraform cuando el usuario lo solicite.
