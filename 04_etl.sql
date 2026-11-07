USE comercializadora_norte;
DELIMITER $$

CREATE PROCEDURE sp_etl_cargar_datos()
BEGIN
 DECLARE v_id BIGINT;
 DECLARE v_error TEXT DEFAULT NULL;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
   GET DIAGNOSTICS CONDITION 1 v_error = MESSAGE_TEXT;
   ROLLBACK;
   UPDATE etl_control SET fin=NOW(),estado='FALLIDO',mensaje_error=v_error
   WHERE id_ejecucion=v_id;
   RESIGNAL;
 END;

 INSERT INTO etl_control(inicio,estado) VALUES(NOW(),'EN_PROCESO');
 SET v_id=LAST_INSERT_ID();
 START TRANSACTION;

 IF (SELECT COUNT(*) FROM tmp_ventas)=0 THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La tabla temporal tmp_ventas está vacía.';
 END IF;

 IF EXISTS(SELECT 1 FROM tmp_ventas WHERE fn_validar_nit(nit_cliente)=0) THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ETL cancelado: existe un NIT con formato inválido.';
 END IF;

 IF EXISTS(
   SELECT numero_factura FROM tmp_ventas
   GROUP BY numero_factura
   HAVING COUNT(DISTINCT nit_cliente)>1 OR COUNT(DISTINCT codigo_sucursal)>1
      OR COUNT(DISTINCT codigo_vendedor)>1 OR COUNT(DISTINCT metodo_pago)>1
 ) THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ETL cancelado: encabezado de factura inconsistente.';
 END IF;

 INSERT IGNORE INTO departamento(nombre)
 SELECT DISTINCT departamento_sucursal FROM tmp_ventas
 UNION SELECT DISTINCT departamento_cliente FROM tmp_ventas;

 INSERT IGNORE INTO municipio(nombre,id_departamento)
 SELECT DISTINCT t.municipio_sucursal,d.id_departamento
 FROM tmp_ventas t JOIN departamento d ON d.nombre=t.departamento_sucursal
 UNION
 SELECT DISTINCT t.municipio_cliente,d.id_departamento
 FROM tmp_ventas t JOIN departamento d ON d.nombre=t.departamento_cliente;

 INSERT IGNORE INTO sucursal(codigo,nombre,direccion,id_municipio)
 SELECT DISTINCT t.codigo_sucursal,t.nombre_sucursal,t.direccion_sucursal,m.id_municipio
 FROM tmp_ventas t
 JOIN departamento d ON d.nombre=t.departamento_sucursal
 JOIN municipio m ON m.nombre=t.municipio_sucursal AND m.id_departamento=d.id_departamento;

 INSERT IGNORE INTO categoria(nombre) SELECT DISTINCT categoria FROM tmp_ventas;
 INSERT IGNORE INTO marca(nombre) SELECT DISTINCT marca FROM tmp_ventas;

 INSERT IGNORE INTO vendedor(codigo,nombres,apellidos,id_sucursal)
 SELECT DISTINCT t.codigo_vendedor,t.nombres_vendedor,t.apellidos_vendedor,s.id_sucursal
 FROM tmp_ventas t JOIN sucursal s ON s.codigo=t.codigo_sucursal;

 INSERT IGNORE INTO cliente(nit,nombres,apellidos,genero,fecha_nacimiento,telefono,correo,direccion,id_municipio)
 SELECT DISTINCT t.nit_cliente,t.nombres_cliente,t.apellidos_cliente,t.genero_cliente,
 STR_TO_DATE(t.fecha_nacimiento_cliente,'%d/%m/%Y'),t.telefono_cliente,t.correo_cliente,
 t.direccion_cliente,m.id_municipio
 FROM tmp_ventas t
 JOIN departamento d ON d.nombre=t.departamento_cliente
 JOIN municipio m ON m.nombre=t.municipio_cliente AND m.id_departamento=d.id_departamento;

 INSERT IGNORE INTO producto(codigo,nombre,id_categoria,id_marca,precio_actual)
 SELECT t.codigo_producto,
        MAX(t.nombre_producto),
        c.id_categoria,m.id_marca,
        CAST(SUBSTRING_INDEX(GROUP_CONCAT(t.precio_unitario ORDER BY
          STR_TO_DATE(t.fecha_venta,'%d/%m/%Y') DESC, t.hora_venta DESC),',',1) AS DECIMAL(12,2))
 FROM tmp_ventas t
 JOIN categoria c ON c.nombre=t.categoria
 JOIN marca m ON m.nombre=t.marca
 GROUP BY t.codigo_producto,c.id_categoria,m.id_marca;

 INSERT INTO factura(numero_factura,fecha_venta,hora_venta,id_sucursal,id_vendedor,id_cliente,metodo_pago)
 SELECT DISTINCT CAST(t.numero_factura AS UNSIGNED),
 STR_TO_DATE(t.fecha_venta,'%d/%m/%Y'),STR_TO_DATE(t.hora_venta,'%H:%i'),
 s.id_sucursal,v.id_vendedor,c.id_cliente,t.metodo_pago
 FROM tmp_ventas t
 JOIN sucursal s ON s.codigo=t.codigo_sucursal
 JOIN vendedor v ON v.codigo=t.codigo_vendedor
 JOIN cliente c ON c.nit=t.nit_cliente;

 INSERT INTO detalle_factura(id_factura,id_producto,linea,precio_unitario,cantidad,subtotal)
 SELECT f.id_factura,p.id_producto,CAST(t.linea AS UNSIGNED),
 CAST(t.precio_unitario AS DECIMAL(12,2)),CAST(t.cantidad AS UNSIGNED),
 CAST(t.subtotal AS DECIMAL(12,2))
 FROM tmp_ventas t
 JOIN factura f ON f.numero_factura=CAST(t.numero_factura AS UNSIGNED)
 JOIN producto p ON p.codigo=t.codigo_producto;

 UPDATE etl_control SET fin=NOW(),filas_leidas=(SELECT COUNT(*) FROM tmp_ventas),
 filas_sucursal=(SELECT COUNT(*) FROM sucursal),
 filas_vendedor=(SELECT COUNT(*) FROM vendedor),
 filas_cliente=(SELECT COUNT(*) FROM cliente),
 filas_producto=(SELECT COUNT(*) FROM producto),
 filas_factura=(SELECT COUNT(*) FROM factura),
 filas_detalle=(SELECT COUNT(*) FROM detalle_factura),
 estado='EXITOSO',mensaje_error=NULL WHERE id_ejecucion=v_id;
 COMMIT;
 SELECT CONCAT('ETL exitoso. Ejecución: ',v_id) AS mensaje;
END$$
DELIMITER ;
-- Ejecutar después de cargar tmp_ventas:
-- CALL sp_etl_cargar_datos();


SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
  AND Name = 'sp_etl_cargar_datos';
  
  DESCRIBE etl_control;
  
  SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    COLUMN_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'comercializadora_norte'
  AND TABLE_NAME = 'etl_control'
ORDER BY ORDINAL_POSITION;


ALTER TABLE etl_control
    CHANGE COLUMN fecha_inicio inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHANGE COLUMN fecha_fin fin DATETIME NULL;
    
    DESCRIBE etl_control;
    
    
    SELECT
    (SELECT COUNT(*) FROM departamento) AS departamentos,
    (SELECT COUNT(*) FROM municipio) AS municipios,
    (SELECT COUNT(*) FROM sucursal) AS sucursales,
    (SELECT COUNT(*) FROM vendedor) AS vendedores,
    (SELECT COUNT(*) FROM cliente) AS clientes,
    (SELECT COUNT(*) FROM categoria) AS categorias,
    (SELECT COUNT(*) FROM marca) AS marcas,
    (SELECT COUNT(*) FROM producto) AS productos,
    (SELECT COUNT(*) FROM factura) AS facturas,
    (SELECT COUNT(*) FROM detalle_factura) AS detalles;
    
    
    SELECT COUNT(*) AS lineas_fuente
FROM tmp_ventas;

CALL sp_etl_cargar_datos();

SELECT
    metodo_pago,
    COUNT(*) AS cantidad
FROM tmp_ventas
GROUP BY metodo_pago
ORDER BY metodo_pago;

SHOW COLUMNS
FROM factura
LIKE 'metodo_pago';


SELECT
    CONCAT('[', metodo_pago, ']') AS valor,
    LENGTH(metodo_pago) AS bytes,
    CHAR_LENGTH(metodo_pago) AS caracteres,
    HEX(metodo_pago) AS hexadecimal,
    COUNT(*) AS cantidad
FROM tmp_ventas
GROUP BY
    metodo_pago,
    LENGTH(metodo_pago),
    CHAR_LENGTH(metodo_pago),
    HEX(metodo_pago);
    
    
    LOAD DATA LOCAL INFILE 'C:/ProyectoBD2/ventas.csv'
INTO TABLE tmp_ventas
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

TRUNCATE TABLE tmp_ventas;

LOAD DATA LOCAL INFILE 'C:/ProyectoBD2/ventas.csv'
INTO TABLE tmp_ventas
CHARACTER SET latin1
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT COUNT(*) AS filas
FROM tmp_ventas;

SELECT
    CONCAT('[', metodo_pago, ']') AS valor,
    LENGTH(metodo_pago) AS bytes,
    CHAR_LENGTH(metodo_pago) AS caracteres,
    HEX(metodo_pago) AS hexadecimal,
    COUNT(*) AS cantidad
FROM tmp_ventas
GROUP BY
    metodo_pago,
    LENGTH(metodo_pago),
    CHAR_LENGTH(metodo_pago),
    HEX(metodo_pago);
    
    CALL sp_etl_cargar_datos();
    DESCRIBE tmp_ventas;
    
    SHOW CREATE TABLE detalle_factura;
    
    SHOW COLUMNS FROM tmp_ventas LIKE '%linea%';
    
    SHOW COLUMNS FROM detalle_factura LIKE '%linea%';
    
    ALTER TABLE detalle_factura
CHANGE COLUMN numero_linea linea INT NOT NULL;

DESCRIBE detalle_factura;

SHOW INDEX FROM detalle_factura;

SELECT
    (SELECT COUNT(*) FROM departamento) AS departamentos,
    (SELECT COUNT(*) FROM municipio) AS municipios,
    (SELECT COUNT(*) FROM sucursal) AS sucursales,
    (SELECT COUNT(*) FROM vendedor) AS vendedores,
    (SELECT COUNT(*) FROM cliente) AS clientes,
    (SELECT COUNT(*) FROM categoria) AS categorias,
    (SELECT COUNT(*) FROM marca) AS marcas,
    (SELECT COUNT(*) FROM producto) AS productos,
    (SELECT COUNT(*) FROM factura) AS facturas,
    (SELECT COUNT(*) FROM detalle_factura) AS detalles;
    
    
    
    SELECT
    (SELECT COUNT(*) FROM departamento) AS departamentos,
    (SELECT COUNT(*) FROM municipio) AS municipios,
    (SELECT COUNT(*) FROM sucursal) AS sucursales,
    (SELECT COUNT(*) FROM vendedor) AS vendedores,
    (SELECT COUNT(*) FROM cliente) AS clientes,
    (SELECT COUNT(*) FROM categoria) AS categorias,
    (SELECT COUNT(*) FROM marca) AS marcas,
    (SELECT COUNT(*) FROM producto) AS productos,
    (SELECT COUNT(*) FROM factura) AS facturas,
    (SELECT COUNT(*) FROM detalle_factura) AS detalles;
    
    DESCRIBE detalle_factura;
    
    
    SELECT COUNT(*) AS productos
FROM producto;

SELECT COUNT(*) AS facturas
FROM factura;

SELECT COUNT(*) AS detalles
FROM detalle_factura;

SHOW COLUMNS
FROM detalle_factura
LIKE '%linea%';

SELECT
    fecha_venta,
    STR_TO_DATE(fecha_venta, '%d/%m/%Y') AS fecha_convertida
FROM tmp_ventas
LIMIT 10;


SELECT COUNT(*) AS fechas_invalidas
FROM tmp_ventas
WHERE STR_TO_DATE(fecha_venta, '%d/%m/%Y') IS NULL;

SELECT
    hora_venta,
    CAST(hora_venta AS TIME) AS hora_convertida
FROM tmp_ventas
LIMIT 10;

SELECT COUNT(*) AS horas_invalidas
FROM tmp_ventas
WHERE CAST(hora_venta AS TIME) IS NULL;

CALL sp_etl_cargar_datos();

SHOW CREATE PROCEDURE sp_etl_cargar_datos;

SELECT ROUTINE_DEFINITION
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'comercializadora_norte'
  AND ROUTINE_NAME = 'sp_etl_cargar_datos';
  
  
  DESCRIBE etl_control;
  
  ALTER TABLE etl_control
    CHANGE COLUMN sucursales_insertadas filas_sucursales INT NOT NULL DEFAULT 0,
    CHANGE COLUMN vendedores_insertados filas_vendedores INT NOT NULL DEFAULT 0,
    CHANGE COLUMN clientes_insertados filas_clientes INT NOT NULL DEFAULT 0,
    CHANGE COLUMN productos_insertados filas_productos INT NOT NULL DEFAULT 0,
    CHANGE COLUMN facturas_insertadas filas_facturas INT NOT NULL DEFAULT 0,
    CHANGE COLUMN detalles_insertados filas_detalles INT NOT NULL DEFAULT 0;
    
    CALL sp_etl_cargar_datos();
    
    SELECT
    ROUTINE_DEFINITION LIKE '%filas_sucursal%'   AS usa_filas_sucursal,
    ROUTINE_DEFINITION LIKE '%filas_sucursales%' AS usa_filas_sucursales,

    ROUTINE_DEFINITION LIKE '%filas_vendedor%'   AS usa_filas_vendedor,
    ROUTINE_DEFINITION LIKE '%filas_vendedores%' AS usa_filas_vendedores,

    ROUTINE_DEFINITION LIKE '%filas_cliente%'     AS usa_filas_cliente,
    ROUTINE_DEFINITION LIKE '%filas_clientes%'    AS usa_filas_clientes,

    ROUTINE_DEFINITION LIKE '%filas_producto%'    AS usa_filas_producto,
    ROUTINE_DEFINITION LIKE '%filas_productos%'   AS usa_filas_productos,

    ROUTINE_DEFINITION LIKE '%filas_factura%'     AS usa_filas_factura,
    ROUTINE_DEFINITION LIKE '%filas_facturas%'    AS usa_filas_facturas,

    ROUTINE_DEFINITION LIKE '%filas_detalle%'     AS usa_filas_detalle,
    ROUTINE_DEFINITION LIKE '%filas_detalles%'    AS usa_filas_detalles
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'comercializadora_norte'
  AND ROUTINE_NAME = 'sp_etl_cargar_datos';
  
  ALTER TABLE etl_control
    CHANGE COLUMN filas_sucursales filas_sucursal INT NOT NULL DEFAULT 0,
    CHANGE COLUMN filas_vendedores filas_vendedor INT NOT NULL DEFAULT 0,
    CHANGE COLUMN filas_clientes filas_cliente INT NOT NULL DEFAULT 0,
    CHANGE COLUMN filas_productos filas_producto INT NOT NULL DEFAULT 0,
    CHANGE COLUMN filas_facturas filas_factura INT NOT NULL DEFAULT 0,
    CHANGE COLUMN filas_detalles filas_detalle INT NOT NULL DEFAULT 0;
    
    
    DESCRIBE etl_control;
    
    SELECT COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'comercializadora_norte'
  AND TABLE_NAME = 'etl_control'
ORDER BY ORDINAL_POSITION;

CALL sp_etl_cargar_datos();

SELECT
    (SELECT COUNT(*) FROM departamento) AS departamentos,
    (SELECT COUNT(*) FROM municipio) AS municipios,
    (SELECT COUNT(*) FROM sucursal) AS sucursales,
    (SELECT COUNT(*) FROM vendedor) AS vendedores,
    (SELECT COUNT(*) FROM cliente) AS clientes,
    (SELECT COUNT(*) FROM categoria) AS categorias,
    (SELECT COUNT(*) FROM marca) AS marcas,
    (SELECT COUNT(*) FROM producto) AS productos,
    (SELECT COUNT(*) FROM factura) AS facturas,
    (SELECT COUNT(*) FROM detalle_factura) AS detalles;
    
    SELECT COUNT(*) AS facturas
FROM factura;

SELECT COUNT(*) AS detalles
FROM detalle_factura;


SELECT
    YEAR(f.fecha_venta) AS anio,
    COUNT(DISTINCT f.id_factura) AS facturas,
    ROUND(SUM(d.subtotal), 2) AS ventas
FROM factura f
INNER JOIN detalle_factura d
    ON d.id_factura = f.id_factura
GROUP BY YEAR(f.fecha_venta)
ORDER BY anio;

SELECT COUNT(*) AS facturas
FROM factura;

SELECT COUNT(*) AS detalles
FROM detalle_factura;

SELECT ROUND(SUM(subtotal), 2) AS ventas_totales
FROM detalle_factura;