# 🛒 Análisis de Datos e E-Commerce (Olist)

Proyecto integral de ingeniería de datos y Business Intelligence para analizar el comportamiento logístico y comercial de la plataforma Olist.

## 🛠️ Stack Tecnológico
* **Base de Datos & SQL:** Microsoft SQL Server (T-SQL).
* **ETL:** Power Query, BULK INSERT (UTF-8).
* **Visualización:** Power BI.
* **Big Data (Benchmark):** PySpark, Pandas.

## ⚙️ Arquitectura y ETL
* **Modelado 3NF:** Diseño relacional de 8 entidades, centralizando la geolocalización para eliminar redundancias operativas.
* **Carga Masiva y Calidad:** Procesamiento de más de 560,000 registros históricos alcanzando un 100% de integridad referencial.

## 🚀 Desarrollo SQL
Como Desarrollador SQL, se implementó lógica de negocio avanzada directamente en la base de datos:
* **Triggers (Cortafuegos):** Bloqueo automático de compras con direcciones inválidas para prevenir sobrecostos por fletes muertos.
* **Stored Procedures:** Herramienta de auditoría en tiempo real para evaluar ventas, ingresos y reputación de cualquier vendedor.
* **Vistas & Consultas Avanzadas:** Uso de subconsultas y `JOINs` múltiples para encapsular el cálculo de eficiencia logística (SLA) y aislar transacciones de alto ticket.

## 📊 Impacto y Resultados (Power BI)
* **Eficiencia Logística:** El 92.13% de los pedidos llegaron a tiempo. Se comprobó una correlación inversa donde entregas mayores a 14 días desploman la calificación a 1 estrella.
* **Foco Comercial:** São Paulo y Río de Janeiro concentran más del 60% de la demanda, justificando la priorización de infraestructura (Dark Stores) en estas zonas.