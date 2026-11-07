USE comercializadora_norte;
DROP TABLE IF EXISTS tmp_ventas;
CREATE TABLE tmp_ventas (
 `numero_factura` VARCHAR(255) NULL,
`fecha_venta` VARCHAR(255) NULL,
`hora_venta` VARCHAR(255) NULL,
`linea` VARCHAR(255) NULL,
`codigo_sucursal` VARCHAR(255) NULL,
`nombre_sucursal` VARCHAR(255) NULL,
`direccion_sucursal` VARCHAR(255) NULL,
`municipio_sucursal` VARCHAR(255) NULL,
`departamento_sucursal` VARCHAR(255) NULL,
`codigo_vendedor` VARCHAR(255) NULL,
`nombres_vendedor` VARCHAR(255) NULL,
`apellidos_vendedor` VARCHAR(255) NULL,
`nit_cliente` VARCHAR(255) NULL,
`nombres_cliente` VARCHAR(255) NULL,
`apellidos_cliente` VARCHAR(255) NULL,
`genero_cliente` VARCHAR(255) NULL,
`fecha_nacimiento_cliente` VARCHAR(255) NULL,
`telefono_cliente` VARCHAR(255) NULL,
`correo_cliente` VARCHAR(255) NULL,
`direccion_cliente` VARCHAR(255) NULL,
`municipio_cliente` VARCHAR(255) NULL,
`departamento_cliente` VARCHAR(255) NULL,
`codigo_producto` VARCHAR(255) NULL,
`nombre_producto` VARCHAR(255) NULL,
`categoria` VARCHAR(255) NULL,
`marca` VARCHAR(255) NULL,
`precio_unitario` VARCHAR(255) NULL,
`cantidad` VARCHAR(255) NULL,
`subtotal` VARCHAR(255) NULL,
`metodo_pago` VARCHAR(255) NULL
) ENGINE=InnoDB;
-- Cargar el CSV desde una ruta local accesible para MySQL.
-- Ajuste únicamente la ruta del archivo. Si usa LOAD DATA LOCAL, habilite local_infile.
LOAD DATA LOCAL INFILE 'C:\ProyectoBD2\ventas.csv'
INTO TABLE tmp_ventas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(`numero_factura`, `fecha_venta`, `hora_venta`, `linea`, `codigo_sucursal`, `nombre_sucursal`, `direccion_sucursal`, `municipio_sucursal`, `departamento_sucursal`, `codigo_vendedor`, `nombres_vendedor`, `apellidos_vendedor`, `nit_cliente`, `nombres_cliente`, `apellidos_cliente`, `genero_cliente`, `fecha_nacimiento_cliente`, `telefono_cliente`, `correo_cliente`, `direccion_cliente`, `municipio_cliente`, `departamento_cliente`, `codigo_producto`, `nombre_producto`, `categoria`, `marca`, `precio_unitario`, `cantidad`, `subtotal`, `metodo_pago`);


DESCRIBE tmp_ventas;

SELECT COUNT(*) AS filas_actuales
FROM tmp_ventas;

LOAD DATA LOCAL INFILE 'C:/ProyectoBD2/ventas.csv'
INTO TABLE tmp_ventas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

SHOW SESSION VARIABLES LIKE 'local_infile';

USE comercializadora_norte;

LOAD DATA LOCAL INFILE 'C:/ProyectoBD2/ventas.csv'
INTO TABLE tmp_ventas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT COUNT(*) AS filas_actuales
FROM tmp_ventas;


USE comercializadora_norte;

TRUNCATE TABLE tmp_ventas;

SELECT COUNT(*) AS filas_actuales

LOAD DATA LOCAL INFILE 'C:/ProyectoBD2/ventas.csv'
INTO TABLE tmp_ventas
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
FROM tmp_ventas;

SELECT COUNT(*) AS filas_cargadas

SELECT *
FROM tmp_ventas
LIMIT 10;
FROM tmp_ventas;

SELECT
    numero_factura,
    fecha_venta,
    hora_venta,
    linea,
    codigo_sucursal,
    nombre_sucursal,
    municipio_sucursal,
    departamento_sucursal,
    codigo_vendedor,
    nombres_vendedor,
    apellidos_vendedor,
    nit_cliente,
    nombres_cliente
FROM tmp_ventas
LIMIT 10;


SELECT DISTINCT
    nombres_cliente,
    apellidos_cliente
FROM tmp_ventas
LIMIT 20;


SELECT COUNT(*) AS filas_cargadas


SELECT COUNT(*) AS filas_vacias
FROM tmp_ventas
WHERE numero_factura IS NULL
   OR TRIM(numero_factura) = '';
   
   
   SELECT
    COUNT(DISTINCT numero_factura) AS facturas,
    COUNT(DISTINCT nit_cliente) AS clientes,
    COUNT(DISTINCT codigo_producto) AS productos,
    COUNT(DISTINCT codigo_vendedor) AS vendedores,
    COUNT(DISTINCT codigo_sucursal) AS sucursales
FROM tmp_ventas;

FROM tmp_ventas;
