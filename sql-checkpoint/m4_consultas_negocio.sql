-- Pre-entrega: Consultas SQL de negocio

-- Título: Extrayendo métricas clave con SQL

USE Ventas_Tech_DB; -- Equivalente en PostgreSQL: no requiere USE, se selecciona la base al conectar

-- Consulta 1 — Resumen ejecutivo mensual 
-- Total facturado, cantidad de pedidos y ticket promedio, agrupados por mes.
SELECT
    MONTH(fecha_venta) AS mes, -- Equivalente en PostgreSQL: EXTRACT(MONTH FROM fecha_venta)
    SUM(cantidad * precio_unitario) AS total_facturado,
    COUNT(*) AS cantidad_pedidos,
    AVG(cantidad * precio_unitario) AS ticket_promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY mes;

-- Consulta 2 — Ranking de productos
-- Top 5 de id_producto por total facturado, con unidades vendidas y total generado.
SELECT TOP 5 -- Equivalente en PostgreSQL: LIMIT 5 (al final de la consulta)
    id_producto,
    SUM(cantidad) AS unidades_vendidas,
    SUM(cantidad * precio_unitario) AS total_generado
FROM ventas
GROUP BY id_producto
ORDER BY total_generado DESC;

-- Consulta 3 — Clientes recurrentes
-- id_cliente con más de un pedido, con cantidad de pedidos y total gastado.
SELECT
    id_cliente,
    COUNT(*) AS cantidad_pedidos,
    SUM(cantidad * precio_unitario) AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;

-- Consulta 4 — Meses por encima/por debajo del promedio
-- Total facturado por mes, etiquetado según el promedio mensual general.
SELECT
    mes,
    total_facturado,
CASE -- Se repite la subconsulta para obtener el promedio general (un solo número) y compararlo contra el total_facturado de cada fila.
WHEN total_facturado > (
SELECT AVG(total_facturado)
FROM (SELECT MONTH(fecha_venta) AS mes, SUM(cantidad * precio_unitario) AS total_facturado
FROM ventas
GROUP BY MONTH(fecha_venta)) AS totales_mes_promedio) 
THEN 'Por encima'
ELSE 'Por debajo'
END AS comparacion_promedio
FROM (SELECT MONTH(fecha_venta) AS mes, SUM(cantidad * precio_unitario) AS total_facturado -- Subconsulta que arma la tabla base: total facturado por mes
FROM ventas
GROUP BY MONTH(fecha_venta)) AS totales_mes
ORDER BY mes;

-- Bloque de cierre: Hallazgos
-- 1. El id_producto 1 concentra el 56% de la facturación total con 3.600 sobre 6.444; más del doble que el segundo puesto del ranking (id_producto 3 con 1.350).
-- 2. Los 5 clientes son recurrentes, con 2 pedidos cada uno.
-- 3. El id_cliente 1 es quien más gastó en total con 2.640, seguido por el id_cliente 5 con 2.100. Entre ambos representan casi el 74% de la facturación del período.