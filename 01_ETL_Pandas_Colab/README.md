# Procesamiento de Datos y Pipelines ETL con Pandas

Este directorio contiene casos prácticos de ingeniería de datos desarrollados en Python (Google Colab), divididos por contexto de negocio. Se enfoca en pipelines ETL secuenciales para limpieza, transformación y validación de datos.

## Estructura de Proyectos

### 📁 [Caso_1_Alquiler_Vehiculos](./Caso_1_Alquiler_Vehiculos)
Pipeline ETL para gestión de flotas.
* **Extracción y Perfilado:** Lectura de CSV, detección de nulos y duplicados.
* **Limpieza y Transformación:** Imputación de ceros en variables numéricas, formato de texto (Title/Upper) y cálculo de `costo_total`.
* **Validación:** Reglas de negocio (días positivos, montos válidos, límite de año de fabricación).

### 📁 [Caso_2_Pacientes_Clinica](./Caso_2_Pacientes_Clinica)
Pipeline ETL para registros epidemiológicos.
* **Limpieza:** Normalización de nombres (mayúsculas) y estandarización de la variable sexo.
* **Validación Lógica:** Filtro de edades válidas (0 a 120 años).
* **Deduplicación:** Eliminación de registros duplicados usando el DNI como llave primaria.