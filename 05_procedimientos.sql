USE comercializadora_norte;

DESCRIBE cliente;
DESCRIBE municipio;

DROP PROCEDURE IF EXISTS sp_cliente_crear;

DELIMITER $$

CREATE PROCEDURE sp_cliente_crear(
    IN p_nit VARCHAR(20),
    IN p_nombres VARCHAR(100),
    IN p_apellidos VARCHAR(100),
    IN p_genero VARCHAR(1),
    IN p_fecha_nacimiento DATE,
    IN p_telefono VARCHAR(8),
    IN p_correo VARCHAR(150),
    IN p_direccion VARCHAR(200),
    IN p_id_municipio INT
)
BEGIN

    IF fn_validar_nit(p_nit) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El formato del NIT no es valido';
    END IF;

    IF p_nombres IS NULL OR TRIM(p_nombres) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los nombres son obligatorios';
    END IF;

    IF p_apellidos IS NULL OR TRIM(p_apellidos) = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Los apellidos son obligatorios';
    END IF;

    IF p_genero NOT IN ('M','F') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El genero debe ser M o F';
    END IF;

    IF p_fecha_nacimiento IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de nacimiento es obligatoria';
    END IF;

    IF p_telefono IS NULL
       OR p_telefono NOT REGEXP '^[0-9]{8}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El telefono debe contener 8 digitos';
    END IF;

    IF fn_validar_correo(p_correo) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electronico no es valido';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM municipio
        WHERE id_municipio = p_id_municipio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El municipio indicado no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya existe un cliente con este NIT';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM cliente
        WHERE correo = p_correo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ya existe un cliente con este correo';
    END IF;

    INSERT INTO cliente (
        nit,
        nombres,
        apellidos,
        genero,
        fecha_nacimiento,
        telefono,
        correo,
        direccion,
        id_municipio,
        estado
    )
    VALUES (
        p_nit,
        p_nombres,
        p_apellidos,
        p_genero,
        p_fecha_nacimiento,
        p_telefono,
        p_correo,
        p_direccion,
        p_id_municipio,
        'activo'
    );

    SELECT
        LAST_INSERT_ID() AS id_cliente_creado,
        'Cliente creado correctamente' AS mensaje;

END$$

DELIMITER ;

SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
  AND Name = 'sp_cliente_crear';
  
  SELECT
    m.id_municipio,
    m.nombre AS municipio,
    d.nombre AS departamento
FROM municipio m
JOIN departamento d
    ON d.id_departamento = m.id_departamento
ORDER BY m.id_municipio
LIMIT 10;

CALL sp_cliente_crear(
    '9999999-9',
    'Carlos Antonio',
    'Lopez Garcia',
    'M',
    '2000-05-15',
    '55551234',
    'carlos.prueba.bd2@correo.com',
    'Zona 1, Guatemala',
    10
);

SELECT
    id_cliente,
    nit,
    nombres,
    apellidos,
    genero,
    fecha_nacimiento,
    telefono,
    correo,
    direccion,
    id_municipio,
    estado
FROM cliente
WHERE nit = '9999999-9';

CALL sp_cliente_crear(
    '8888888-8',
    'Ana Lucia',
    'Perez Lopez',
    'F',
    '2001-03-20',
    '123',
    'ana.prueba.bd2@correo.com',
    'Zona 1, Guatemala',
    10
);

SELECT nit, nombres, correo
FROM cliente
WHERE nit IN (
    '9999999-9',
    '8888888-8',
    '7777777-7'
);

CALL sp_cliente_crear(
    '7777777-7',
    'Luis Fernando',
    'Garcia Perez',
    'M',
    '1999-08-10',
    '55559999',
    'correo_incorrecto',
    'Zona 1, Guatemala',
    10
);



SELECT
    nit,
    nombres,
    correo
FROM cliente
WHERE nit IN (
    '9999999-9',
    '8888888-8',
    '7777777-7'
);



DROP PROCEDURE IF EXISTS sp_cliente_actualizar;

DELIMITER $$

CREATE PROCEDURE sp_cliente_actualizar(
    IN p_nit VARCHAR(20),
    IN p_telefono VARCHAR(8),
    IN p_correo VARCHAR(150),
    IN p_direccion VARCHAR(200),
    IN p_id_municipio INT
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
          AND estado = 'activo'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no existe o esta inactivo';
    END IF;

    IF p_telefono IS NULL
       OR p_telefono NOT REGEXP '^[0-9]{8}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El telefono debe contener 8 digitos';
    END IF;

    IF fn_validar_correo(p_correo) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electronico no es valido';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM municipio
        WHERE id_municipio = p_id_municipio
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El municipio indicado no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM cliente
        WHERE correo = p_correo
          AND nit <> p_nit
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo ya pertenece a otro cliente';
    END IF;

    UPDATE cliente
    SET
        telefono = p_telefono,
        correo = p_correo,
        direccion = p_direccion,
        id_municipio = p_id_municipio
    WHERE nit = p_nit;

    SELECT
        'Cliente actualizado correctamente' AS mensaje;

END$$

DELIMITER ;

SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
  AND Name = 'sp_cliente_actualizar';
  
  CALL sp_cliente_actualizar(
    '9999999-9',
    '55554321',
    'carlos.actualizado.bd2@correo.com',
    'Mixco, Guatemala',
    8
);

SELECT
    c.nit,
    c.nombres,
    c.telefono,
    c.correo,
    c.direccion,
    m.nombre AS municipio,
    c.estado
FROM cliente c
JOIN municipio m
    ON m.id_municipio = c.id_municipio
WHERE c.nit = '9999999-9';

CALL sp_cliente_actualizar(
    '0000000-0',
    '55554321',
    'inexistente@correo.com',
    'Guatemala',
    10
);

CALL sp_cliente_actualizar(
    '9999999-9',
    '123',
    'carlos.actualizado.bd2@correo.com',
    'Mixco, Guatemala',
    8
);

SELECT
    nit,
    nombres,
    telefono,
    correo,
    direccion,
    id_municipio,
    estado
FROM cliente
WHERE nit = '9999999-9';




DROP PROCEDURE IF EXISTS sp_cliente_eliminar;

DELIMITER $$

CREATE PROCEDURE sp_cliente_eliminar(
    IN p_nit VARCHAR(20)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
          AND estado = 'inactivo'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente ya se encuentra inactivo';
    END IF;

    UPDATE cliente
    SET estado = 'inactivo'
    WHERE nit = p_nit
      AND estado = 'activo';

    SELECT
        'Cliente dado de baja correctamente' AS mensaje;

END$$

DELIMITER ;



DROP PROCEDURE IF EXISTS sp_cliente_eliminar;

DELIMITER $$

CREATE PROCEDURE sp_cliente_eliminar(
    IN p_nit VARCHAR(20)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
          AND estado = 'inactivo'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente ya se encuentra inactivo';
    END IF;

    UPDATE cliente
    SET estado = 'inactivo'
    WHERE nit = p_nit
      AND estado = 'activo';

    SELECT 'Cliente dado de baja correctamente' AS mensaje;

END$$

DELIMITER ;

SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
  AND Name = 'sp_cliente_eliminar';
  
  SELECT nit, nombres, estado
FROM cliente
WHERE nit = '9999999-9';

CALL sp_cliente_eliminar('9999999-9');

SELECT nit, nombres, estado
FROM cliente
WHERE nit = '9999999-9';


CALL sp_cliente_eliminar('9999999-9');


CALL sp_cliente_eliminar('0000000-0');


SELECT nit, nombres, estado
FROM cliente
WHERE nit = '9999999-9';


DROP PROCEDURE IF EXISTS sp_cliente_consultar;

DELIMITER $$

CREATE PROCEDURE sp_cliente_consultar(
    IN p_nit VARCHAR(20)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM cliente
        WHERE nit = p_nit
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no existe';
    END IF;

    SELECT
        c.id_cliente,
        c.nit,
        c.nombres,
        c.apellidos,
        c.genero,
        c.fecha_nacimiento,
        c.telefono,
        c.correo,
        c.direccion,
        m.nombre AS municipio,
        d.nombre AS departamento,
        c.estado
    FROM cliente c
    INNER JOIN municipio m
        ON m.id_municipio = c.id_municipio
    INNER JOIN departamento d
        ON d.id_departamento = m.id_departamento
    WHERE c.nit = p_nit;

END$$

DELIMITER ;


SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
  AND Name = 'sp_cliente_consultar';
  
  CALL sp_cliente_consultar('9999999-9');

CALL sp_cliente_consultar('0000000-0');

IF fn_validar_nit(p_nit) = 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'El formato del NIT no es valido';
END IF;

CALL sp_cliente_consultar('NIT-MALO');


SELECT id_categoria, nombre
FROM categoria
LIMIT 10;

SELECT id_marca, nombre
FROM marca
LIMIT 10;

SELECT id_categoria, nombre
FROM categoria
LIMIT 10;

SELECT id_marca, nombre
FROM marca
LIMIT 10;

DROP PROCEDURE IF EXISTS sp_producto_crear;

DELIMITER $$

CREATE PROCEDURE sp_producto_crear(
    IN p_codigo VARCHAR(20),
    IN p_nombre VARCHAR(150),
    IN p_id_categoria INT,
    IN p_id_marca INT,
    IN p_precio DECIMAL(12,2)
)
BEGIN

    IF EXISTS (
        SELECT 1
        FROM producto
        WHERE codigo = p_codigo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El codigo del producto ya existe';
    END IF;

    IF p_precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor que cero';
    END IF;

    INSERT INTO producto(
        codigo,
        nombre,
        id_categoria,
        id_marca,
        precio_actual,
        estado
    )
    VALUES(
        p_codigo,
        p_nombre,
        p_id_categoria,
        p_id_marca,
        p_precio,
        'activo'
    );

    SELECT 'Producto creado correctamente' AS mensaje;

END$$

DELIMITER ;


SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
AND Name = 'sp_producto_crear';

SELECT id_categoria, nombre
FROM categoria
ORDER BY id_categoria
LIMIT 1;

CALL sp_producto_crear(
    'PRUEBA-BD2',
    'Producto de prueba BD2',
    1,
    4,
    25.00
);


SELECT
    codigo,
    nombre,
    precio_actual,
    estado
FROM producto
WHERE codigo = 'PRUEBA-BD2';

DROP PROCEDURE IF EXISTS sp_producto_actualizar;

DELIMITER $$

CREATE PROCEDURE sp_producto_actualizar(
    IN p_codigo VARCHAR(20),
    IN p_nombre VARCHAR(150),
    IN p_precio DECIMAL(12,2)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM producto
        WHERE codigo = p_codigo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto no existe';
    END IF;

    IF p_precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio debe ser mayor que cero';
    END IF;

    UPDATE producto
    SET
        nombre = p_nombre,
        precio_actual = p_precio
    WHERE codigo = p_codigo;

    SELECT 'Producto actualizado correctamente' AS mensaje;

END$$

DELIMITER ;



CALL sp_producto_actualizar(
    'PRUEBA-BD2',
    'Producto BD2 actualizado',
    30.00
);

SELECT
    codigo,
    nombre,
    precio_actual,
    estado
FROM producto
WHERE codigo = 'PRUEBA-BD2';



DROP PROCEDURE IF EXISTS sp_producto_consultar;

DELIMITER $$

CREATE PROCEDURE sp_producto_consultar(
    IN p_codigo VARCHAR(20)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM producto
        WHERE codigo = p_codigo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto no existe';
    END IF;

    SELECT
        p.codigo,
        p.nombre,
        c.nombre AS categoria,
        m.nombre AS marca,
        p.precio_actual,
        p.estado
    FROM producto p
    INNER JOIN categoria c
        ON c.id_categoria = p.id_categoria
    INNER JOIN marca m
        ON m.id_marca = p.id_marca
    WHERE p.codigo = p_codigo;

END$$

DELIMITER ;

CALL sp_producto_consultar('PRUEBA-BD2');


DROP PROCEDURE IF EXISTS sp_producto_eliminar;

DELIMITER $$

CREATE PROCEDURE sp_producto_eliminar(
    IN p_codigo VARCHAR(20)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM producto
        WHERE codigo = p_codigo
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto no existe';
    END IF;

    UPDATE producto
    SET estado = 'inactivo'
    WHERE codigo = p_codigo;

    SELECT 'Producto dado de baja correctamente' AS mensaje;

END$$

DELIMITER ;





SELECT
    s.id_sucursal,
    s.codigo AS codigo_sucursal,
    s.nombre AS sucursal,
    v.id_vendedor,
    v.codigo AS codigo_vendedor,
    v.nombres,
    v.apellidos
FROM sucursal s
INNER JOIN vendedor v
    ON v.id_sucursal = s.id_sucursal
WHERE s.estado = 'activa'
  AND v.estado = 'activo'
LIMIT 5;



SELECT
    id_cliente,
    nit,
    nombres,
    apellidos
FROM cliente
WHERE estado = 'activo'
LIMIT 5;


SELECT
    id_producto,
    codigo,
    nombre,
    precio_actual,
    estado
FROM producto
WHERE codigo = 'PRUEBA-BD2';



SELECT
    s.codigo AS codigo_sucursal,
    v.codigo AS codigo_vendedor,
    c.nit AS nit_cliente,
    'PRUEBA-BD2' AS codigo_producto
FROM sucursal s
JOIN vendedor v
    ON v.id_sucursal = s.id_sucursal
CROSS JOIN cliente c
WHERE s.estado = 'activa'
  AND v.estado = 'activo'
  AND c.estado = 'activo'
LIMIT 1;


SELECT
    MAX(numero_factura) AS ultima_factura,
    MAX(numero_factura) + 1 AS siguiente_factura
FROM factura;


SHOW COLUMNS
FROM factura
LIKE 'metodo_pago';



DROP PROCEDURE IF EXISTS sp_venta_registrar;

DELIMITER $$

CREATE PROCEDURE sp_venta_registrar(
    IN p_codigo_sucursal VARCHAR(20),
    IN p_codigo_vendedor VARCHAR(20),
    IN p_nit_cliente VARCHAR(20),
    IN p_codigo_producto VARCHAR(20),
    IN p_cantidad INT,
    IN p_metodo_pago VARCHAR(20)
)
BEGIN

    DECLARE v_id_sucursal INT;
    DECLARE v_id_vendedor INT;
    DECLARE v_id_cliente INT;
    DECLARE v_id_producto INT;
    DECLARE v_precio DECIMAL(12,2);
    DECLARE v_id_factura BIGINT;
    DECLARE v_numero_factura BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT id_sucursal
    INTO v_id_sucursal
    FROM sucursal
    WHERE codigo = p_codigo_sucursal
      AND estado = 'activa'
    LIMIT 1;

    SELECT id_vendedor
    INTO v_id_vendedor
    FROM vendedor
    WHERE codigo = p_codigo_vendedor
      AND id_sucursal = v_id_sucursal
      AND estado = 'activo'
    LIMIT 1;

    SELECT id_cliente
    INTO v_id_cliente
    FROM cliente
    WHERE nit = p_nit_cliente
      AND estado = 'activo'
    LIMIT 1;

    SELECT id_producto, precio_actual
    INTO v_id_producto, v_precio
    FROM producto
    WHERE codigo = p_codigo_producto
      AND estado = 'activo'
    LIMIT 1;

    IF p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cantidad debe ser mayor que cero';
    END IF;

    IF p_metodo_pago NOT IN (
        'Efectivo',
        'Tarjeta',
        'Transferencia'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Metodo de pago no valido';
    END IF;

    SELECT COALESCE(MAX(numero_factura), 0) + 1
    INTO v_numero_factura
    FROM factura;

    INSERT INTO factura(
        numero_factura,
        fecha_venta,
        hora_venta,
        id_sucursal,
        id_vendedor,
        id_cliente,
        metodo_pago,
        estado
    )
    VALUES(
        v_numero_factura,
        CURDATE(),
        CURTIME(),
        v_id_sucursal,
        v_id_vendedor,
        v_id_cliente,
        p_metodo_pago,
        'vigente'
    );

    SET v_id_factura = LAST_INSERT_ID();

    INSERT INTO detalle_factura(
        id_factura,
        linea,
        id_producto,
        precio_unitario,
        cantidad,
        subtotal
    )
    VALUES(
        v_id_factura,
        1,
        v_id_producto,
        v_precio,
        p_cantidad,
        v_precio * p_cantidad
    );

    COMMIT;

    SELECT
        v_numero_factura AS numero_factura,
        v_precio * p_cantidad AS total,
        'Venta registrada correctamente' AS mensaje;

END$$

DELIMITER ;



SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte'
AND Name = 'sp_venta_registrar';


SELECT
    s.codigo AS codigo_sucursal,
    v.codigo AS codigo_vendedor,
    c.nit AS nit_cliente
FROM sucursal s
JOIN vendedor v
    ON v.id_sucursal = s.id_sucursal
CROSS JOIN cliente c
WHERE s.estado = 'activa'
  AND v.estado = 'activo'
  AND c.estado = 'activo'
LIMIT 1;


CALL sp_venta_registrar(
    'SUC08',
    'VEN042',
    '19754541-6',
    'PRUEBA-BD2',
    2,
    'Efectivo'
);


SELECT
    numero_factura,
    fecha_venta,
    hora_venta,
    metodo_pago,
    estado
FROM factura
ORDER BY id_factura DESC
LIMIT 1;


SELECT
    d.linea,
    p.codigo,
    p.nombre,
    d.precio_unitario,
    d.cantidad,
    d.subtotal
FROM detalle_factura d
JOIN producto p
    ON p.id_producto = d.id_producto
ORDER BY d.id_detalle DESC
LIMIT 1;

SELECT
    numero_factura,
    fecha_venta,
    hora_venta,
    metodo_pago,
    estado
FROM factura
ORDER BY id_factura DESC
LIMIT 1;


DROP PROCEDURE IF EXISTS sp_venta_consultar;

DELIMITER $$

CREATE PROCEDURE sp_venta_consultar(
    IN p_numero_factura BIGINT
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM factura
        WHERE numero_factura = p_numero_factura
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La factura no existe';
    END IF;

    SELECT
        f.numero_factura,
        f.fecha_venta,
        f.hora_venta,
        f.metodo_pago,
        f.estado,
        fn_total_factura(f.id_factura) AS total
    FROM factura f
    WHERE f.numero_factura = p_numero_factura;

    SELECT
        d.linea,
        p.codigo,
        p.nombre,
        d.precio_unitario,
        d.cantidad,
        d.subtotal
    FROM factura f
    JOIN detalle_factura d
        ON d.id_factura = f.id_factura
    JOIN producto p
        ON p.id_producto = d.id_producto
    WHERE f.numero_factura = p_numero_factura
    ORDER BY d.linea;

END$$

DELIMITER ;



CALL sp_venta_consultar(107666);


DROP PROCEDURE IF EXISTS sp_venta_anular;

DELIMITER $$

CREATE PROCEDURE sp_venta_anular(
    IN p_numero_factura BIGINT,
    IN p_motivo VARCHAR(255)
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM factura
        WHERE numero_factura = p_numero_factura
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La factura no existe';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM factura
        WHERE numero_factura = p_numero_factura
          AND estado = 'anulada'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La factura ya esta anulada';
    END IF;

    UPDATE factura
    SET
        estado = 'anulada',
        fecha_anulacion = NOW(),
        motivo_anulacion = p_motivo
    WHERE numero_factura = p_numero_factura;

    SELECT 'Factura anulada correctamente' AS mensaje;

END$$

DELIMITER ;


CALL sp_venta_anular(
    107666,
    'Prueba academica BD2'
);



SELECT
    numero_factura,
    estado,
    fecha_anulacion,
    motivo_anulacion
FROM factura
WHERE numero_factura = 107666;

DESCRIBE bitacora;




DROP TRIGGER IF EXISTS trg_factura_au;

DELIMITER $$

CREATE TRIGGER trg_factura_au
AFTER UPDATE ON factura
FOR EACH ROW
BEGIN

    INSERT INTO bitacora(
        fecha_hora,
        usuario_bd,
        tabla_afectada,
        operacion,
        llave_registro,
        descripcion,
        datos_anteriores,
        datos_nuevos
    )
    VALUES(
        NOW(),
        CURRENT_USER(),
        'factura',
        'UPDATE',
        OLD.numero_factura,
        'Actualizacion de factura',

        JSON_OBJECT(
            'estado', OLD.estado,
            'motivo', OLD.motivo_anulacion
        ),

        JSON_OBJECT(
            'estado', NEW.estado,
            'motivo', NEW.motivo_anulacion
        )
    );

END$$

DELIMITER ;



DROP TRIGGER IF EXISTS trg_factura_bd;

DELIMITER $$

CREATE TRIGGER trg_factura_bd
BEFORE DELETE ON factura
FOR EACH ROW
BEGIN

    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT =
        'No se permite eliminar facturas; utilice sp_venta_anular';

END$$

DELIMITER ;

SHOW TRIGGERS
FROM comercializadora_norte;


DELETE FROM factura
WHERE numero_factura = 107666;

UPDATE factura
SET motivo_anulacion = 'Prueba academica BD2 - auditoria'
WHERE numero_factura = 107666;



SELECT
    fecha_hora,
    usuario_bd,
    tabla_afectada,
    operacion,
    llave_registro,
    descripcion
FROM bitacora
ORDER BY id_bitacora DESC
LIMIT 5;




SELECT COUNT(*) FROM factura;
SELECT COUNT(*) FROM detalle_factura;
SELECT ROUND(SUM(subtotal),2) FROM detalle_factura;

SHOW PROCEDURE STATUS
WHERE Db = 'comercializadora_norte';

SHOW TRIGGERS
FROM comercializadora_norte;