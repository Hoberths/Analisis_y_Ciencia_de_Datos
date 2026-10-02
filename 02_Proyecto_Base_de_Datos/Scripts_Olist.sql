/*CREACIÓN FÍSICA DE LA BASE DE DATOS*/
create database OLIST_DB
on primary (
    name = N'OlistData',
    filename = N'C:\BD\OlistData.mdf',
    size = 50MB,
    maxsize = unlimited,
    filegrowth = 10%
)
log on (
    name = N'OlistDataLog',
    filename = N'C:\BD\OlistDataLog.ldf',
    size = 10MB,
    maxsize = 500MB,
    filegrowth = 5MB
)
collate Latin1_General_100_CI_AS_SC_UTF8;
go

/*NOS UBICAMOS EN LA BASE DE DATOS*/
use OLIST_DB

-- 1. TABLA MAESTRA GEOGRÁFICA (Tu 3FN)
create table olist_geolocalizacion (
    codigo_postal varchar(10) NOT NULL,
    ciudad varchar(100) NOT NULL,
    estado char(2) NOT NULL,
    constraint PK_geolocalizacion primary key (codigo_postal)
);

-- 2. TABLA DE CLIENTES
create table olist_clientes (
    id_cliente varchar(50) NOT NULL,
    id_unico_cliente varchar(50) NOT NULL,
    codigo_postal varchar(10) NOT NULL,
    constraint PK_clientes primary key (id_cliente),
    constraint FK_clientes_geo foreign key (codigo_postal) references olist_geolocalizacion(codigo_postal),
    constraint UQ_clientes_unico unique (id_unico_cliente) 
);


-- 3. TABLA DE VENDEDORES
create table olist_vendedores (
    id_vendedor varchar(50) NOT NULL,
    codigo_postal varchar(10) NOT NULL,
    constraint PK_vendedores primary key (id_vendedor),
    constraint FK_vendedores_geo foreign key (codigo_postal) references olist_geolocalizacion(codigo_postal)
);

-- 4. TABLA DE PRODUCTOS (Ya limpia, sin columnas basura)
create table olist_productos (
    id_producto varchar(50) NOT NULL,
    categoria varchar(100) NULL,
    peso_g int NULL,
    longitud_cm int NULL,
    altura_cm int NULL,
    ancho_cm int NULL,
    constraint PK_productos primary key (id_producto),
    constraint chk_peso check (peso_g >= 0), 
    constraint chk_longitud check (longitud_cm >= 0),
    constraint chk_altura check (altura_cm >= 0), 
    constraint chk_ancho check (ancho_cm >= 0)
);

-- 5. TABLA DE PEDIDOS (Con DATETIME para las horas exactas)
create table olist_pedidos (
    id_pedido varchar(50) NOT NULL,
    id_cliente varchar(50) NOT NULL,
    estado_pedido varchar(20) NOT NULL,
    fecha_compra datetime NOT NULL,
    fecha_aprobacion datetime NULL,
    fecha_entrega_transportista datetime NULL,
    fecha_entrega_cliente datetime NULL,
    fecha_estimada_entrega datetime NULL,
    constraint PK_pedidos primary key (id_pedido),
    constraint FK_pedidos_clientes foreign key (id_cliente) references olist_clientes(id_cliente)
);

-- 6. TABLA DE DETALLE DE PEDIDOS (El cruce de todo)
create table olist_detalle_pedidos (
    id_pedido varchar(50) NOT NULL,
    id_item_pedido int NOT NULL,
    id_producto varchar(50) NOT NULL,
    id_vendedor varchar(50) NOT NULL,
    fecha_limite_envio datetime NOT NULL,
    precio decimal(10,2) NOT NULL,
    valor_flete decimal(10,2) NOT NULL,
    constraint PK_detalle_pedidos primary key (id_pedido, id_item_pedido),
    constraint FK_detalle_pedido foreign key (id_pedido) references olist_pedidos(id_pedido),
    constraint FK_detalle_producto foreign key (id_producto) references olist_productos(id_producto),
    constraint FK_detalle_vendedor foreign key (id_vendedor) references olist_vendedores(id_vendedor),
    constraint chk_precio check (precio >= 0),
    constraint chk_flete check (valor_flete >= 0)
);



-- 7. TABLA DE PAGOS (Con tu nuevo ID optimizado)
create table olist_pagos_pedido (
    id_pago varchar(50) NOT NULL, 
    id_pedido varchar(50) NOT NULL,
    secuencia_pago int NOT NULL,
    tipo_pago varchar(50) NOT NULL,
    cuotas_pago int NOT NULL,
    valor_pago decimal(10,2) NOT NULL,
    constraint PK_pagos_pedido primary key (id_pago),
    constraint FK_pagos_pedidos foreign key (id_pedido) references olist_pedidos(id_pedido),
    constraint CHK_cuotas check (cuotas_pago >= 0),
    constraint CHK_valor_pago check (valor_pago >= 0)
);



-- 8. TABLA DE VALORACIONES (Ya limpia, sin título ni fecha de creación)
create table olist_valoraciones (
    id_valoraciones varchar(50) NOT NULL,
    id_pedido varchar(50) NOT NULL,
    puntaje int NOT NULL,
    mensaje_comentario text NULL,
    fecha_creacion datetime Null,
    fecha_respuesta datetime NULL,
    constraint PK_valoraciones primary key (id_valoraciones),
    constraint FK_valoraciones_pedidos foreign key (id_pedido) references olist_pedidos(id_pedido),
    constraint chk_puntaje check (puntaje between 1 and 5)
);

ALTER TABLE olist_vendedores NOCHECK CONSTRAINT FK_vendedores_geo;
GO

-- 1. Insertamos los códigos postales "fantasma" en la tabla de geolocalización
INSERT INTO olist_geolocalizacion (codigo_postal, ciudad, estado)
SELECT DISTINCT v.codigo_postal, 'Desconocido', 'NA'
FROM olist_vendedores v
LEFT JOIN olist_geolocalizacion g ON v.codigo_postal = g.codigo_postal
WHERE g.codigo_postal IS NULL;
GO

-- 2. Volvemos a activar la llave foránea para proteger la base de datos
ALTER TABLE olist_vendedores CHECK CONSTRAINT FK_vendedores_geo;
GO

-- 1. Vaciamos la tabla por si se cargaron filas a medias en el intento anterior
TRUNCATE TABLE olist_detalle_pedidos;
GO

-- 2. Desactivamos firmemente la llave foránea de vendedores
ALTER TABLE olist_detalle_pedidos NOCHECK CONSTRAINT FK_detalle_vendedor;
GO

-- 1. Tomamos un código postal válido como respaldo para los nuevos registros
DECLARE @CodigoPostalRespaldo VARCHAR(10);
SELECT TOP 1 @CodigoPostalRespaldo = codigo_postal FROM olist_geolocalizacion;

-- 2. Insertamos de forma automática los vendedores que causaban el conflicto
INSERT INTO olist_vendedores (id_vendedor, codigo_postal)
SELECT DISTINCT dp.id_vendedor, @CodigoPostalRespaldo
FROM olist_detalle_pedidos dp
LEFT JOIN olist_vendedores v ON dp.id_vendedor = v.id_vendedor
WHERE v.id_vendedor IS NULL;
GO

-- 3. Volvemos a activar la llave foránea para garantizar la integridad del modelo
ALTER TABLE olist_detalle_pedidos CHECK CONSTRAINT FK_detalle_vendedor;
GO


/*Responder las preguntas de negocio mediante consultas SQL.*/

select top 10 p.categoria, 
              count(dp.id_producto) as [Volumen Ventas] 
from olist_detalle_pedidos dp
inner join olist_productos p 
on dp.id_producto = p.id_producto
group by p.categoria
order by [Volumen Ventas] desc;


select top 10 g.estado, g.ciudad, 
              count(p.id_pedido) as [Total Pedidos]
from olist_pedidos p
inner join olist_clientes c 
on p.id_cliente = c.id_cliente
inner join olist_geolocalizacion g 
on c.codigo_postal = g.codigo_postal
group by g.estado, g.ciudad
order by [Total Pedidos] desc;


select v.puntaje AS Estrellas, 
       avg(datediff(day, p.fecha_compra, p.fecha_entrega_cliente)) as [Promedio Dias Entrega],
       count(p.id_pedido) as [Cantidad Pedidos Evaluados]
from olist_pedidos p
inner join olist_valoraciones v 
on p.id_pedido = v.id_pedido
where p.fecha_entrega_cliente > '2015-01-01'
group by v.puntaje
order by Estrellas desc;


select top 10 id_vendedor, 
              sum(precio) as [Ingresos Totales],
              count(id_producto) as [Cantidad Articulos Vendidos]
from olist_detalle_pedidos
group by id_vendedor
order by [Ingresos Totales] desc;


select
    count(id_pedido) as [Total Pedidos Entregados],
    sum(case when fecha_entrega_cliente <= fecha_estimada_entrega then 1 else 0 end) as [Entregados A Tiempo],
    cast(sum(case when fecha_entrega_cliente <= fecha_estimada_entrega then 1 else 0 end) 
    * 100.0 / count(id_pedido) as decimal(5,2)) as [Porcentaje Eficiencia]
from olist_pedidos
where fecha_entrega_cliente is not null 
and fecha_estimada_entrega is not null;

/*Desarrollar un mínimo de 10 consultas*/

select 
    id_vendedor, 
    count(id_producto) as [Volumen Articulos],
    sum(precio) as [Ingresos Totales]
from olist_detalle_pedidos
group by id_vendedor
having sum(precio) > 50000 
order by [Ingresos Totales] desc;
GO

select top 10 g.estado, g.ciudad, 
              count(p.id_pedido) as [Total_Pedidos] 
from olist_pedidos p
inner join olist_clientes c 
on p.id_cliente = c.id_cliente
inner join olist_geolocalizacion g 
on c.codigo_postal = g.codigo_postal
group by g.estado, g.ciudad
order by Total_Pedidos desc;
GO

select g.codigo_postal, g.ciudad, g.estado,
       count(c.id_cliente) as Clientes_En_Riesgo_Logistico
from olist_geolocalizacion g
left join olist_clientes c 
on g.codigo_postal = c.codigo_postal
where g.ciudad = 'Desconocido' or g.estado = 'NA'
group by g.codigo_postal, g.ciudad, g.estado
order by Clientes_En_Riesgo_Logistico desc;
GO

select top 10 p.categoria,
    count(dp.id_pedido) as [Unidades Vendidas],
    sum(dp.precio) as [Volumen Ventas Monetario]
from olist_detalle_pedidos dp
right join olist_productos p 
on dp.id_producto = p.id_producto
where p.categoria is not null
group by p.categoria
order by [Volumen Ventas Monetario] desc;
GO

select tipo_pago, 
    count(id_pedido) as [Frecuencia Uso],
    sum(valor_pago) as [Volumen Dinero Movido],
    cast((sum(valor_pago) * 100.0) / (select sum(valor_pago) from olist_pagos_pedido) as decimal(5,2)) as [Porcentaje Del Total]
from olist_pagos_pedido
group by tipo_pago
order by [Volumen Dinero Movido] desc;
GO

select id_pedido, id_producto, precio
from olist_detalle_pedidos
where precio > (
    select AVG(precio) from olist_detalle_pedidos
)
order by precio desc;
GO

select dp.id_vendedor, dp.id_producto, dp.precio
from olist_detalle_pedidos dp
where dp.precio > (
    select avg(dp2.precio)
    from olist_detalle_pedidos dp2
    where dp2.id_vendedor = dp.id_vendedor
)
order by dp.id_vendedor;
GO

create view vw_kpi_eficiencia_logistica as
select
    count(id_pedido) as [Total Pedidos Entregados],
    sum(case when fecha_entrega_cliente <= fecha_estimada_entrega then 1 else 0 end) as [Entregados_A_Tiempo],
    cast(sum(case when fecha_entrega_cliente <= fecha_estimada_entrega then 1 else 0 end) * 100.0 / count(id_pedido) as decimal(5,2)) as [Porcentaje Eficiencia]
from olist_pedidos
where fecha_entrega_cliente is not null 
and fecha_estimada_entrega is not null;
GO

select * from vw_kpi_eficiencia_logistica


create view vw_impacto_demora_satisfaccion as
select v.puntaje as Estrellas, 
       avg(datediff(day, p.fecha_compra, p.fecha_entrega_cliente)) as [Promedio Dias Entrega],
       count(p.id_pedido) as [Cantidad Pedidos Evaluados]
from olist_pedidos p
inner join olist_valoraciones v 
on p.id_pedido = v.id_pedido
where p.fecha_entrega_cliente > '2015-01-01'
group by v.puntaje;
GO

select * from vw_impacto_demora_satisfaccion


create procedure sp_Auditoria_Vendedor
    @Id_Vendedor varchar(50)
as
begin
    set nocount on;

    select
        v.id_vendedor,
        count(dp.id_pedido) as [Total Ventas],
        sum(dp.precio) as [Volumen Dinero],
        avg(cast(val.puntaje as decimal(5,2))) as [Promedio Estrellas Recibidas]
    from olist_vendedores v
    inner join olist_detalle_pedidos dp 
    on v.id_vendedor = dp.id_vendedor
    inner join olist_pedidos p 
    on dp.id_pedido = p.id_pedido
    inner join olist_valoraciones val 
    on p.id_pedido = val.id_pedido
    where v.id_vendedor = @Id_Vendedor
    group by v.id_vendedor;
end;
GO

select top 1 id_vendedor 
from olist_detalle_pedidos;

exec sp_Auditoria_Vendedor @Id_Vendedor = '4869f7a5dfa277a7dca6462dcf3b52b2';

select * from olist_valoraciones

select id_pedido, id_cliente, estado_pedido, fecha_compra
from olist_pedidos
where (estado_pedido like 'cancel%' or estado_pedido = 'unavailable')
  and fecha_compra between '2017-11-01' and '2017-12-31'
order by fecha_compra desc;
GO

create trigger trg_Bloquear_Compra_Sin_Direccion
on olist_pedidos
after insert
as
begin
    -- Verificamos si el cliente que intenta registrar un pedido está en una 'zona ciega'
    if exists (
        select 1
        from inserted i
        inner join olist_clientes c on i.id_cliente = c.id_cliente
        inner join olist_geolocalizacion g on c.codigo_postal = g.codigo_postal
        where g.ciudad = 'Desconocido' or g.estado = 'NA'
    )
    begin
        -- Deshace la transacción inmediatamente y lanza un mensaje de error a la aplicación
        rollback transaction;
        raiserror ('Alerta: El cliente debe actualizar su dirección logística para proceder con la compra.', 16, 1);
    end
end;
GO

/* PRUEBA DE CORTAFUEGOS LOGÍSTICO (TRIGGER) */
-- PASO 1: Simulamos el registro de un NUEVO CLIENTE.
INSERT INTO olist_clientes (id_cliente, id_unico_cliente, codigo_postal)
VALUES ('CLI-RIESGO-999', 'UNI-RIESGO-999', '1001');
GO

-- Comprobamos que el cliente está creado en la base de datos:
SELECT * FROM olist_clientes WHERE id_cliente = 'CLI-RIESGO-999';
GO

-- PASO 2: El cliente intenta comprar (AQUÍ ENTRA EN ACCIÓN EL TRIGGER).
INSERT INTO olist_pedidos (id_pedido, id_cliente, estado_pedido, fecha_compra)
VALUES ('PEDIDO-TEST-001', 'CLI-RIESGO-999', 'invoiced', '2018-05-01');
GO

-- PASO 3: Limpieza del registro de prueba (Mantenimiento post-auditoría)
DELETE FROM olist_clientes 
WHERE id_cliente = 'CLI-RIESGO-999';
GO


SELECT 'olist_geolocalizacion' AS Tabla, COUNT(*) AS Total_Registros FROM olist_geolocalizacion
UNION ALL
SELECT 'olist_clientes', COUNT(*) FROM olist_clientes
UNION ALL
SELECT 'olist_vendedores', COUNT(*) FROM olist_vendedores
UNION ALL
SELECT 'olist_productos', COUNT(*) FROM olist_productos
UNION ALL
SELECT 'olist_pedidos', COUNT(*) FROM olist_pedidos
UNION ALL
SELECT 'olist_detalle_pedidos', COUNT(*) FROM olist_detalle_pedidos
UNION ALL
SELECT 'olist_pagos_pedido', COUNT(*) FROM olist_pagos_pedido
UNION ALL
SELECT 'olist_valoraciones', COUNT(*) FROM olist_valoraciones;
GO


SELECT 
    COUNT(*) AS Total_Valoraciones,
    
    -- Contamos como "Llenos" los que NO son nulos y NO están en blanco
    SUM(CASE WHEN mensaje_comentario IS NOT NULL AND CAST(mensaje_comentario AS VARCHAR(MAX)) <> '' THEN 1 ELSE 0 END) AS Comentarios_Con_Texto,
    
    -- Contamos como "Vacíos" los nulos o los que están en blanco
    SUM(CASE WHEN mensaje_comentario IS NULL OR CAST(mensaje_comentario AS VARCHAR(MAX)) = '' THEN 1 ELSE 0 END) AS Comentarios_Vacios,
    
    -- Nuevo porcentaje de completitud real
    CAST(ROUND((SUM(CASE WHEN mensaje_comentario IS NOT NULL AND CAST(mensaje_comentario AS VARCHAR(MAX)) <> '' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS DECIMAL(5,2)) AS Porcentaje_Completitud
FROM olist_valoraciones;
GO