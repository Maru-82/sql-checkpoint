
-- ══════════════════════════════════════════
-- Pre-entrega: Consultas con JOINs para el proyecto
-- Título: Cruzando tablas para enriquecer el análisis
-- Autor: Marina Mónaco
-- Fecha: 11-09-26
-- ═══════════════════════════════════

USE Ventas_Tech_DB; -- Equivalente en PostgreSQL: no requiere USE, se selecciona la base al conectar

-- Consulta 1 — Vista base del proyecto (INNER JOIN)
-- Cruza ventas con clientes, productos y categorías para obtener la vista enriquecida

SELECT
    v.fecha_venta,                                 -- Fecha de la venta
    v.id_cliente,                                  -- Identificación del cliente
    p.nombre_producto,                             -- Descripción del producto
    v.cantidad,                                    -- Cantidad vendida
    v.precio_unitario,                             -- Precio unitario al momento de la venta
    v.cantidad * v.precio_unitario AS total_venta, -- Total de la venta (columna calculada)
    c.ciudad,                                      -- Columna descriptiva: dimensión geográfica del cliente
    c.fecha_registro,                              -- Columna descriptiva: antigüedad del cliente
    cat.nombre_categoria                           -- Columna descriptiva: categoría del producto
FROM ventas AS v
INNER JOIN clientes AS c ON v.id_cliente = c.id_cliente            -- Trae los datos del cliente que hizo la venta
INNER JOIN productos AS p ON v.id_producto = p.id_producto         -- Trae los datos del producto vendido
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria; -- Trae la categoría del producto

-- Consulta 2 — Clientes sin ventas (LEFT JOIN)
-- Identifica clientes registrados que todavía no realizaron ninguna compra,
-- aislando con WHERE ... IS NULL los casos donde el LEFT JOIN no encontró venta asociada.

SELECT
    c.nombre,          -- Nombre del cliente
    c.email,           -- Email de contacto
    c.fecha_registro   -- Fecha de alta del cliente
FROM clientes AS c
LEFT JOIN ventas AS v ON c.id_cliente = v.id_cliente
WHERE v.id_cliente IS NULL;  -- Clientes sin ninguna venta asociada

-- Con los datos cargados en M3, no hay ningún cliente registrado que no tenga una venta asociada, por lo que esta consulta devuelve 0 filas.

-- Consulta 3 — Productos sin ventas (LEFT JOIN)
-- Identifica productos del catálogo que nunca fueron vendidos,
-- aislando con WHERE ... IS NULL los casos donde el LEFT JOIN no encontró venta asociada.
 
SELECT
    p.nombre_producto,    -- Nombre del producto
    cat.nombre_categoria, -- Categoría a la que pertenece
    p.precio              -- Precio de venta
FROM productos AS p
LEFT JOIN ventas AS v ON p.id_producto = v.id_producto
LEFT JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
WHERE v.id_producto IS NULL;  -- Productos sin ninguna venta registrada

-- Con los datos cargados en M3, los 6 productos tienen al menos una venta, por lo que esta consulta devuelve 0 filas.


-- Consulta 4 — Consolidado por canal (UNION ALL)
-- Criterio: fecha de venta, dividida en dos períodos (corte en el 10/03).

SELECT
    canal,
    SUM(total) AS total_por_canal              -- Total facturado por cada período
FROM (
    SELECT
        cantidad * precio_unitario AS total,   -- Total de cada venta individual
        'Período 1' AS canal                   -- Columna creada (no existe en las tablas); ventas hasta el 10/03 inclusive
    FROM ventas
    WHERE fecha_venta <= '2024-03-10'          -- Corte del período 1

    UNION ALL                                  -- UNION ALL y no UNION para no perder ventas repetidas entre sí

    SELECT
        cantidad * precio_unitario AS total,   -- Total de cada venta individual
        'Período 2' AS canal                   -- Columna creada (no existe en las tablas); ventas desde el 11/03
    FROM ventas
    WHERE fecha_venta > '2024-03-10'           -- Corte del período 2
) AS ventas_por_periodo
GROUP BY canal;                                -- Agrupa para obtener el total por período