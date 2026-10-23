-- =============================================================================
-- SCHEMA DEFINITIVO PostgreSQL
-- Modelo de Datos - Distribución Recurrente de Agua Purificada V2
-- =============================================================================
-- Características:
--   • PK / FK con ON DELETE / ON UPDATE explícitos
--   • CHECK constraints de negocio
--   • UNIQUE naturales e índices de rendimiento
--   • TIMESTAMPTZ para zonas horarias
--   • JSONB para snapshots y auditoría
--   • Reglas XOR (Pago y Factura vinculados a Venta O Pedido)
--   • Soft-delete vía columna estado donde aplica
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid() si se prefiere UUID
CREATE EXTENSION IF NOT EXISTS "btree_gist"; -- exclusiones futuras si se necesitan

-- =============================================================================
-- 1. EMPRESA Y ORGANIZACIÓN
-- =============================================================================

CREATE TABLE empresa (
    empresa_id          SERIAL PRIMARY KEY,
    nombre              VARCHAR(150)  NOT NULL,
    razon_social        VARCHAR(200),
    ruc                 VARCHAR(20)   NOT NULL,
    telefono            VARCHAR(20),
    email               VARCHAR(150),
    direccion           TEXT,
    estado              VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',
    fecha_creacion      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ,

    CONSTRAINT uq_empresa_ruc UNIQUE (ruc),
    CONSTRAINT ck_empresa_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDO'))
);

CREATE TABLE sucursal (
    sucursal_id     SERIAL PRIMARY KEY,
    empresa_id      INTEGER       NOT NULL REFERENCES empresa(empresa_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    codigo          VARCHAR(20),
    nombre          VARCHAR(150)  NOT NULL,
    tipo            VARCHAR(50),          -- PLANTA, LOCAL, DEPOSITO...
    direccion       TEXT,
    telefono        VARCHAR(20),
    email           VARCHAR(150),
    latitud         NUMERIC(10,7),
    longitud        NUMERIC(10,7),
    estado          VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',
    fecha_creacion  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_sucursal_codigo_empresa UNIQUE (empresa_id, codigo),
    CONSTRAINT ck_sucursal_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'CERRADO'))
);

CREATE INDEX idx_sucursal_empresa ON sucursal(empresa_id);

-- =============================================================================
-- 2. USUARIOS Y ROLES
-- =============================================================================

CREATE TABLE usuario (
    usuario_id          SERIAL PRIMARY KEY,
    empresa_id          INTEGER       NOT NULL REFERENCES empresa(empresa_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    sucursal_id         INTEGER       REFERENCES sucursal(sucursal_id) ON DELETE SET NULL ON UPDATE CASCADE, -- NULL = corporativo
    nombre              VARCHAR(100)  NOT NULL,
    apellido            VARCHAR(100),
    cedula              VARCHAR(20),
    telefono            VARCHAR(20),
    email               VARCHAR(150)  NOT NULL,
    password_hash       VARCHAR(255)  NOT NULL,
    estado              VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',
    ultimo_acceso       TIMESTAMPTZ,
    fecha_creacion      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ,

    CONSTRAINT uq_usuario_email UNIQUE (email),
    CONSTRAINT ck_usuario_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'BLOQUEADO'))
);

CREATE INDEX idx_usuario_empresa  ON usuario(empresa_id);
CREATE INDEX idx_usuario_sucursal ON usuario(sucursal_id);

CREATE TABLE rol (
    rol_id      SERIAL PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    descripcion TEXT,
    estado      VARCHAR(20)  NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT uq_rol_nombre UNIQUE (nombre),
    CONSTRAINT ck_rol_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE TABLE usuario_rol (
    usuario_id       INTEGER NOT NULL REFERENCES usuario(usuario_id) ON DELETE CASCADE ON UPDATE CASCADE,
    rol_id           INTEGER NOT NULL REFERENCES rol(rol_id) ON DELETE CASCADE ON UPDATE CASCADE,
    fecha_asignacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (usuario_id, rol_id)
);

-- Especialización de Usuario
CREATE TABLE repartidor (
    usuario_id                 INTEGER PRIMARY KEY REFERENCES usuario(usuario_id) ON DELETE CASCADE ON UPDATE CASCADE,
    licencia                   VARCHAR(30),
    tipo_licencia              VARCHAR(20),
    fecha_vencimiento_licencia DATE,
    estado                     VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT ck_repartidor_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'VACACIONES', 'SUSPENDIDO'))
);

-- =============================================================================
-- 3. CLIENTES Y DIRECCIONES
-- =============================================================================

CREATE TABLE cliente (
    cliente_id          SERIAL PRIMARY KEY,
    empresa_id          INTEGER       NOT NULL REFERENCES empresa(empresa_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    tipo_cliente        VARCHAR(20)   NOT NULL,
    nombre              VARCHAR(100),
    apellido            VARCHAR(100),
    razon_social        VARCHAR(200),
    cedula_ruc          VARCHAR(20),
    telefono            VARCHAR(20),
    whatsapp            VARCHAR(20),
    email               VARCHAR(150),
    estado              VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',
    fecha_registro      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ,

    CONSTRAINT ck_cliente_tipo   CHECK (tipo_cliente IN ('PERSONA', 'EMPRESA')),
    CONSTRAINT ck_cliente_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'MOROSO', 'BLOQUEADO')),
    CONSTRAINT ck_cliente_persona_datos CHECK (
        (tipo_cliente = 'PERSONA'  AND nombre IS NOT NULL) OR
        (tipo_cliente = 'EMPRESA'  AND razon_social IS NOT NULL)
    )
);

CREATE INDEX idx_cliente_empresa   ON cliente(empresa_id);
CREATE INDEX idx_cliente_whatsapp  ON cliente(whatsapp);
CREATE INDEX idx_cliente_cedula    ON cliente(cedula_ruc);

CREATE TABLE sector (
    sector_id    SERIAL PRIMARY KEY,
    sucursal_id  INTEGER       NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nombre       VARCHAR(100)  NOT NULL,
    descripcion  TEXT,
    estado       VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT uq_sector_nombre_sucursal UNIQUE (sucursal_id, nombre),
    CONSTRAINT ck_sector_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE INDEX idx_sector_sucursal ON sector(sucursal_id);

CREATE TABLE direccion (
    direccion_id     SERIAL PRIMARY KEY,
    cliente_id       INTEGER       NOT NULL REFERENCES cliente(cliente_id) ON DELETE CASCADE ON UPDATE CASCADE,
    sector_id        INTEGER       REFERENCES sector(sector_id) ON DELETE SET NULL ON UPDATE CASCADE,
    alias            VARCHAR(50),           -- Casa, Oficina, Negocio...
    calle_principal  VARCHAR(150),
    calle_secundaria VARCHAR(150),
    numero           VARCHAR(20),
    referencia       TEXT,
    codigo_postal       VARCHAR(20),
    latitud          NUMERIC(10,7),
    longitud         NUMERIC(10,7),
    es_principal     BOOLEAN       NOT NULL DEFAULT FALSE,
    estado           VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT ck_direccion_estado CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE INDEX idx_direccion_cliente ON direccion(cliente_id);
CREATE INDEX idx_direccion_sector  ON direccion(sector_id);

-- Solo una dirección principal por cliente
CREATE UNIQUE INDEX uq_direccion_principal_cliente
    ON direccion (cliente_id)
    WHERE es_principal = TRUE AND estado = 'ACTIVO';

-- =============================================================================
-- 4. RUTAS Y HORARIOS
-- =============================================================================

CREATE TABLE ruta (
    ruta_id      SERIAL PRIMARY KEY,
    sucursal_id  INTEGER       NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    nombre       VARCHAR(100)  NOT NULL,
    descripcion  TEXT,
    estado       VARCHAR(20)   NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT uq_ruta_nombre_sucursal UNIQUE (sucursal_id, nombre),
    CONSTRAINT ck_ruta_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'SUSPENDIDA'))
);

CREATE INDEX idx_ruta_sucursal ON ruta(sucursal_id);

CREATE TABLE horario_ruta (
    horario_ruta_id SERIAL PRIMARY KEY,
    ruta_id         INTEGER    NOT NULL REFERENCES ruta(ruta_id) ON DELETE CASCADE ON UPDATE CASCADE,
    dia_semana      SMALLINT   NOT NULL,   -- 1=Lunes ... 7=Domingo
    hora_inicio     TIME       NOT NULL,
    hora_fin        TIME       NOT NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT uq_horario_ruta_dia UNIQUE (ruta_id, dia_semana),
    CONSTRAINT ck_horario_dia      CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_horario_ventana  CHECK (hora_fin > hora_inicio),
    CONSTRAINT ck_horario_estado   CHECK (estado IN ('ACTIVO', 'INACTIVO'))
);

CREATE TABLE ruta_sector (
    ruta_id    INTEGER NOT NULL REFERENCES ruta(ruta_id) ON DELETE CASCADE ON UPDATE CASCADE,
    sector_id  INTEGER NOT NULL REFERENCES sector(sector_id) ON DELETE CASCADE ON UPDATE CASCADE,
    orden      INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (ruta_id, sector_id)
);

-- =============================================================================
-- 5. PRODUCTOS
-- =============================================================================

CREATE TABLE producto (
    producto_id      SERIAL PRIMARY KEY,
    empresa_id       INTEGER        NOT NULL REFERENCES empresa(empresa_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    codigo           VARCHAR(30)    NOT NULL,
    nombre           VARCHAR(150)   NOT NULL,
    descripcion      TEXT,
    categoria        VARCHAR(50),
    capacidad_litros NUMERIC(8,2),
    precio           NUMERIC(12,2)  NOT NULL,
    costo            NUMERIC(12,2),
    requiere_envase  BOOLEAN        NOT NULL DEFAULT FALSE,
    estado           VARCHAR(20)    NOT NULL DEFAULT 'ACTIVO',
    fecha_creacion   TIMESTAMPTZ    NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_producto_codigo_empresa UNIQUE (empresa_id, codigo),
    CONSTRAINT ck_producto_precio  CHECK (precio >= 0),
    CONSTRAINT ck_producto_costo   CHECK (costo IS NULL OR costo >= 0),
    CONSTRAINT ck_producto_estado  CHECK (estado IN ('ACTIVO', 'INACTIVO', 'DESCONTINUADO'))
);

CREATE INDEX idx_producto_empresa ON producto(empresa_id);

-- =============================================================================
-- 6. SUSCRIPCIONES (núcleo del negocio recurrente)
-- =============================================================================

CREATE TABLE suscripcion (
    suscripcion_id    SERIAL PRIMARY KEY,
    cliente_id        INTEGER       NOT NULL REFERENCES cliente(cliente_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    direccion_id      INTEGER       NOT NULL REFERENCES direccion(direccion_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    sucursal_id       INTEGER       NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ruta_id           INTEGER       REFERENCES ruta(ruta_id) ON DELETE SET NULL ON UPDATE CASCADE,
    frecuencia        VARCHAR(30)   NOT NULL,   -- SEMANAL, QUINCENAL, MENSUAL...
    dia_semana        SMALLINT,                 -- día preferido de generación
    hora_inicio       TIME,
    hora_fin          TIME,
    fecha_inicio      DATE          NOT NULL,
    fecha_fin         DATE,
    proxima_entrega   DATE,                     -- cuándo debe generarse el siguiente pedido
    ultima_generacion TIMESTAMPTZ,              -- última vez que se generó un pedido automático
    estado            VARCHAR(20)   NOT NULL DEFAULT 'ACTIVA',
    observaciones     TEXT,
    fecha_creacion    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_suscripcion_frecuencia CHECK (frecuencia IN ('SEMANAL', 'QUINCENAL', 'MENSUAL', 'PERSONALIZADA')),
    CONSTRAINT ck_suscripcion_dia        CHECK (dia_semana IS NULL OR dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_suscripcion_fechas     CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT ck_suscripcion_estado     CHECK (estado IN ('ACTIVA', 'PAUSADA', 'CANCELADA', 'FINALIZADA'))
);

CREATE INDEX idx_suscripcion_cliente         ON suscripcion(cliente_id);
CREATE INDEX idx_suscripcion_proxima_entrega ON suscripcion(proxima_entrega) WHERE estado = 'ACTIVA';
CREATE INDEX idx_suscripcion_ruta            ON suscripcion(ruta_id);

CREATE TABLE detalle_suscripcion (
    detalle_suscripcion_id SERIAL PRIMARY KEY,
    suscripcion_id         INTEGER       NOT NULL REFERENCES suscripcion(suscripcion_id) ON DELETE CASCADE ON UPDATE CASCADE,
    producto_id            INTEGER       NOT NULL REFERENCES producto(producto_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cantidad               INTEGER       NOT NULL,
    precio_unitario        NUMERIC(12,2) NOT NULL,  -- snapshot al momento de crear/actualizar la suscripción

    CONSTRAINT ck_detalle_suscripcion_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_suscripcion_precio   CHECK (precio_unitario >= 0),
    CONSTRAINT uq_detalle_suscripcion_producto UNIQUE (suscripcion_id, producto_id)
);

-- =============================================================================
-- 7. PEDIDOS
-- =============================================================================

CREATE TABLE pedido (
    pedido_id                SERIAL PRIMARY KEY,
    cliente_id               INTEGER       NOT NULL REFERENCES cliente(cliente_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    sucursal_id              INTEGER       NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    direccion_id             INTEGER       NOT NULL REFERENCES direccion(direccion_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    suscripcion_id           INTEGER       REFERENCES suscripcion(suscripcion_id) ON DELETE SET NULL ON UPDATE CASCADE,
    canal_origen             VARCHAR(30)   NOT NULL DEFAULT 'ADMIN',  -- WEB, WHATSAPP, VENDEDOR, ADMIN, APP
    fecha_pedido             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    fecha_entrega_solicitada DATE,
    estado                   VARCHAR(30)   NOT NULL DEFAULT 'PENDIENTE',
    subtotal                 NUMERIC(14,2) NOT NULL DEFAULT 0,
    descuento                NUMERIC(14,2) NOT NULL DEFAULT 0,
    impuesto                 NUMERIC(14,2) NOT NULL DEFAULT 0,
    total                    NUMERIC(14,2) NOT NULL DEFAULT 0,
    observaciones            TEXT,
    fecha_creacion           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_pedido_canal  CHECK (canal_origen IN ('WEB', 'WHATSAPP', 'VENDEDOR', 'ADMIN', 'APP', 'SUSCRIPCION')),
    CONSTRAINT ck_pedido_estado CHECK (estado IN (
        'PENDIENTE', 'CONFIRMADO', 'PREPARADO', 'EN_RUTA',
        'ENTREGADO', 'CANCELADO', 'NO_ENTREGADO'
    )),
    CONSTRAINT ck_pedido_montos CHECK (
        subtotal >= 0 AND descuento >= 0 AND impuesto >= 0 AND total >= 0
    )
);

CREATE INDEX idx_pedido_cliente      ON pedido(cliente_id);
CREATE INDEX idx_pedido_sucursal     ON pedido(sucursal_id);
CREATE INDEX idx_pedido_estado       ON pedido(estado);
CREATE INDEX idx_pedido_fecha        ON pedido(fecha_pedido);
CREATE INDEX idx_pedido_suscripcion  ON pedido(suscripcion_id);

CREATE TABLE detalle_pedido (
    detalle_pedido_id SERIAL PRIMARY KEY,
    pedido_id         INTEGER       NOT NULL REFERENCES pedido(pedido_id) ON DELETE CASCADE ON UPDATE CASCADE,
    producto_id       INTEGER       NOT NULL REFERENCES producto(producto_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cantidad          INTEGER       NOT NULL,
    precio_unitario   NUMERIC(12,2) NOT NULL,   -- snapshot
    descuento         NUMERIC(12,2) NOT NULL DEFAULT 0,
    subtotal          NUMERIC(14,2) NOT NULL,

    CONSTRAINT ck_detalle_pedido_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_pedido_precio   CHECK (precio_unitario >= 0),
    CONSTRAINT ck_detalle_pedido_subtotal CHECK (subtotal >= 0)
);

CREATE INDEX idx_detalle_pedido_pedido ON detalle_pedido(pedido_id);

-- =============================================================================
-- 8. LOGÍSTICA (VEHÍCULOS, ASIGNACIONES, ENTREGAS)
-- =============================================================================

CREATE TABLE vehiculo (
    vehiculo_id  SERIAL PRIMARY KEY,
    sucursal_id  INTEGER      NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    placa        VARCHAR(15)  NOT NULL,
    marca        VARCHAR(50),
    modelo       VARCHAR(50),
    anio         SMALLINT,
    tipo         VARCHAR(30),
    capacidad    INTEGER,
    estado       VARCHAR(20)  NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT uq_vehiculo_placa UNIQUE (placa),
    CONSTRAINT ck_vehiculo_estado CHECK (estado IN ('ACTIVO', 'MANTENIMIENTO', 'INACTIVO', 'BAJA'))
);

CREATE INDEX idx_vehiculo_sucursal ON vehiculo(sucursal_id);

CREATE TABLE asignacion_ruta (
    asignacion_ruta_id SERIAL PRIMARY KEY,
    ruta_id            INTEGER    NOT NULL REFERENCES ruta(ruta_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    repartidor_id      INTEGER    NOT NULL REFERENCES repartidor(usuario_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    vehiculo_id        INTEGER    NOT NULL REFERENCES vehiculo(vehiculo_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    fecha              DATE       NOT NULL,
    hora_inicio        TIME,
    hora_fin           TIME,
    estado             VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA',

    CONSTRAINT uq_asignacion_ruta_fecha UNIQUE (ruta_id, fecha),
    CONSTRAINT ck_asignacion_estado CHECK (estado IN ('PROGRAMADA', 'EN_CURSO', 'FINALIZADA', 'CANCELADA'))
);

CREATE INDEX idx_asignacion_fecha       ON asignacion_ruta(fecha);
CREATE INDEX idx_asignacion_repartidor  ON asignacion_ruta(repartidor_id);

CREATE TABLE entrega (
    entrega_id             SERIAL PRIMARY KEY,
    pedido_id              INTEGER       NOT NULL REFERENCES pedido(pedido_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cliente_id             INTEGER       NOT NULL REFERENCES cliente(cliente_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    direccion_id           INTEGER       NOT NULL REFERENCES direccion(direccion_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    ruta_id                INTEGER       REFERENCES ruta(ruta_id) ON DELETE SET NULL ON UPDATE CASCADE,
    repartidor_id          INTEGER       REFERENCES repartidor(usuario_id) ON DELETE SET NULL ON UPDATE CASCADE,
    vehiculo_id            INTEGER       REFERENCES vehiculo(vehiculo_id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha_programada       DATE          NOT NULL,
    hora_programada_inicio TIME,
    hora_programada_fin    TIME,
    hora_salida            TIMESTAMPTZ,
    hora_llegada           TIMESTAMPTZ,
    hora_entrega           TIMESTAMPTZ,
    estado                 VARCHAR(30)   NOT NULL DEFAULT 'PROGRAMADA',
    observaciones          TEXT,
    latitud_entrega        NUMERIC(10,7),
    longitud_entrega       NUMERIC(10,7),
    -- Snapshots históricos (evidencia)
    direccion_snapshot     TEXT,
    referencia_snapshot    TEXT,

    CONSTRAINT ck_entrega_estado CHECK (estado IN (
        'PROGRAMADA', 'PREPARADA', 'EN_RUTA', 'ENTREGADA',
        'NO_ENTREGADA', 'REPROGRAMADA', 'CANCELADA'
    ))
);

CREATE INDEX idx_entrega_pedido           ON entrega(pedido_id);
CREATE INDEX idx_entrega_fecha_programada ON entrega(fecha_programada);
CREATE INDEX idx_entrega_estado           ON entrega(estado);
CREATE INDEX idx_entrega_repartidor       ON entrega(repartidor_id);
CREATE INDEX idx_entrega_ruta_fecha       ON entrega(ruta_id, fecha_programada);

CREATE TABLE detalle_entrega (
    detalle_entrega_id  SERIAL PRIMARY KEY,
    entrega_id          INTEGER NOT NULL REFERENCES entrega(entrega_id) ON DELETE CASCADE ON UPDATE CASCADE,
    producto_id         INTEGER NOT NULL REFERENCES producto(producto_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cantidad_programada INTEGER NOT NULL,
    cantidad_entregada  INTEGER,
    cantidad_rechazada  INTEGER NOT NULL DEFAULT 0,
    motivo_rechazo      TEXT,

    CONSTRAINT ck_detalle_entrega_prog CHECK (cantidad_programada > 0),
    CONSTRAINT ck_detalle_entrega_ent  CHECK (cantidad_entregada IS NULL OR cantidad_entregada >= 0),
    CONSTRAINT ck_detalle_entrega_rec  CHECK (cantidad_rechazada >= 0)
);

CREATE INDEX idx_detalle_entrega_entrega ON detalle_entrega(entrega_id);

-- =============================================================================
-- 9. VENTAS POS
-- =============================================================================

CREATE TABLE venta (
    venta_id    SERIAL PRIMARY KEY,
    sucursal_id INTEGER       NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cliente_id  INTEGER       REFERENCES cliente(cliente_id) ON DELETE SET NULL ON UPDATE CASCADE, -- puede ser venta anónima
    usuario_id  INTEGER       NOT NULL REFERENCES usuario(usuario_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    fecha_venta TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    subtotal    NUMERIC(14,2) NOT NULL DEFAULT 0,
    descuento   NUMERIC(14,2) NOT NULL DEFAULT 0,
    impuesto    NUMERIC(14,2) NOT NULL DEFAULT 0,
    total       NUMERIC(14,2) NOT NULL DEFAULT 0,
    estado      VARCHAR(20)   NOT NULL DEFAULT 'COMPLETADA',

    CONSTRAINT ck_venta_estado CHECK (estado IN ('COMPLETADA', 'ANULADA', 'DEVUELTA')),
    CONSTRAINT ck_venta_montos CHECK (subtotal >= 0 AND descuento >= 0 AND impuesto >= 0 AND total >= 0)
);

CREATE INDEX idx_venta_sucursal ON venta(sucursal_id);
CREATE INDEX idx_venta_fecha    ON venta(fecha_venta);

CREATE TABLE detalle_venta (
    detalle_venta_id SERIAL PRIMARY KEY,
    venta_id         INTEGER       NOT NULL REFERENCES venta(venta_id) ON DELETE CASCADE ON UPDATE CASCADE,
    producto_id      INTEGER       NOT NULL REFERENCES producto(producto_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cantidad         INTEGER       NOT NULL,
    precio_unitario  NUMERIC(12,2) NOT NULL,
    descuento        NUMERIC(12,2) NOT NULL DEFAULT 0,
    subtotal         NUMERIC(14,2) NOT NULL,

    CONSTRAINT ck_detalle_venta_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_venta_precio   CHECK (precio_unitario >= 0)
);

-- =============================================================================
-- 10. PAGOS (XOR: Venta POS  O  Pedido de distribución)
-- =============================================================================

CREATE TABLE pago (
    pago_id     SERIAL PRIMARY KEY,
    venta_id    INTEGER       REFERENCES venta(venta_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    pedido_id   INTEGER       REFERENCES pedido(pedido_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    fecha_pago  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    metodo_pago VARCHAR(30)   NOT NULL,
    monto       NUMERIC(14,2) NOT NULL,
    referencia  VARCHAR(100),
    estado      VARCHAR(20)   NOT NULL DEFAULT 'CONFIRMADO',

    CONSTRAINT ck_pago_xor CHECK (
        (venta_id IS NOT NULL AND pedido_id IS NULL) OR
        (venta_id IS NULL AND pedido_id IS NOT NULL)
    ),
    CONSTRAINT ck_pago_metodo CHECK (metodo_pago IN (
        'EFECTIVO', 'TRANSFERENCIA', 'TARJETA', 'CHEQUE',
        'DEPOSITO', 'CREDITO', 'OTRO'
    )),
    CONSTRAINT ck_pago_monto  CHECK (monto > 0),
    CONSTRAINT ck_pago_estado CHECK (estado IN ('PENDIENTE', 'CONFIRMADO', 'RECHAZADO', 'ANULADO'))
);

CREATE INDEX idx_pago_venta  ON pago(venta_id);
CREATE INDEX idx_pago_pedido ON pago(pedido_id);
CREATE INDEX idx_pago_fecha  ON pago(fecha_pago);

-- =============================================================================
-- 11. FACTURACIÓN (XOR: Venta POS  O  Pedido de distribución)
-- =============================================================================

CREATE TABLE factura (
    factura_id              SERIAL PRIMARY KEY,
    venta_id                INTEGER       REFERENCES venta(venta_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    pedido_id               INTEGER       REFERENCES pedido(pedido_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cliente_id              INTEGER       NOT NULL REFERENCES cliente(cliente_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    numero_factura          VARCHAR(50)   NOT NULL,
    clave_acceso            VARCHAR(100),
    fecha_emision           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    subtotal                NUMERIC(14,2) NOT NULL DEFAULT 0,
    impuesto                NUMERIC(14,2) NOT NULL DEFAULT 0,
    total                   NUMERIC(14,2) NOT NULL DEFAULT 0,
    estado                  VARCHAR(20)   NOT NULL DEFAULT 'BORRADOR',
    xml_url                 TEXT,
    pdf_url                 TEXT,
    datos_fiscales_snapshot JSONB,        -- RUC, razón social, dirección fiscal del momento

    CONSTRAINT uq_factura_numero       UNIQUE (numero_factura),
    CONSTRAINT uq_factura_clave        UNIQUE (clave_acceso),
    CONSTRAINT ck_factura_xor CHECK (
        (venta_id IS NOT NULL AND pedido_id IS NULL) OR
        (venta_id IS NULL AND pedido_id IS NOT NULL)
    ),
    CONSTRAINT ck_factura_estado CHECK (estado IN (
        'BORRADOR', 'GENERADA', 'FIRMADA', 'ENVIADA',
        'AUTORIZADA', 'RECHAZADA', 'ANULADA'
    )),
    CONSTRAINT ck_factura_montos CHECK (subtotal >= 0 AND impuesto >= 0 AND total >= 0)
);

CREATE INDEX idx_factura_cliente ON factura(cliente_id);
CREATE INDEX idx_factura_venta   ON factura(venta_id);
CREATE INDEX idx_factura_pedido  ON factura(pedido_id);
CREATE INDEX idx_factura_fecha   ON factura(fecha_emision);

CREATE TABLE detalle_factura (
    detalle_factura_id SERIAL PRIMARY KEY,
    factura_id         INTEGER       NOT NULL REFERENCES factura(factura_id) ON DELETE CASCADE ON UPDATE CASCADE,
    producto_id        INTEGER       REFERENCES producto(producto_id) ON DELETE SET NULL ON UPDATE CASCADE,
    descripcion        VARCHAR(200)  NOT NULL,
    cantidad           INTEGER       NOT NULL,
    precio_unitario    NUMERIC(12,2) NOT NULL,
    descuento          NUMERIC(12,2) NOT NULL DEFAULT 0,
    subtotal           NUMERIC(14,2) NOT NULL,

    CONSTRAINT ck_detalle_factura_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_factura_precio   CHECK (precio_unitario >= 0)
);

-- =============================================================================
-- 12. INVENTARIO
-- =============================================================================

CREATE TABLE inventario (
    inventario_id       SERIAL PRIMARY KEY,
    sucursal_id         INTEGER NOT NULL REFERENCES sucursal(sucursal_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    producto_id         INTEGER NOT NULL REFERENCES producto(producto_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cantidad_disponible INTEGER NOT NULL DEFAULT 0,
    cantidad_reservada  INTEGER NOT NULL DEFAULT 0,
    stock_minimo        INTEGER NOT NULL DEFAULT 0,
    fecha_actualizacion TIMESTAMPTZ,

    CONSTRAINT uq_inventario_sucursal_producto UNIQUE (sucursal_id, producto_id),
    CONSTRAINT ck_inventario_disponible CHECK (cantidad_disponible >= 0),
    CONSTRAINT ck_inventario_reservada  CHECK (cantidad_reservada >= 0),
    CONSTRAINT ck_inventario_reservada_vs_disp CHECK (cantidad_reservada <= cantidad_disponible),
    CONSTRAINT ck_inventario_minimo     CHECK (stock_minimo >= 0)
);

CREATE TABLE movimiento_inventario (
    movimiento_id   SERIAL PRIMARY KEY,
    inventario_id   INTEGER       NOT NULL REFERENCES inventario(inventario_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    usuario_id      INTEGER       REFERENCES usuario(usuario_id) ON DELETE SET NULL ON UPDATE CASCADE,
    tipo_movimiento VARCHAR(30)   NOT NULL,
    cantidad        INTEGER       NOT NULL,
    referencia_tipo VARCHAR(50),          -- PEDIDO, ENTREGA, VENTA, AJUSTE, TRANSFERENCIA...
    referencia_id   INTEGER,
    fecha           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    observacion     TEXT,

    CONSTRAINT ck_mov_inv_tipo     CHECK (tipo_movimiento IN (
        'ENTRADA', 'SALIDA', 'AJUSTE', 'TRANSFERENCIA', 'DEVOLUCION', 'RESERVA', 'LIBERACION'
    )),
    CONSTRAINT ck_mov_inv_cantidad CHECK (cantidad <> 0)
);

CREATE INDEX idx_mov_inv_inventario ON movimiento_inventario(inventario_id);
CREATE INDEX idx_mov_inv_fecha      ON movimiento_inventario(fecha);

-- =============================================================================
-- 13. ENVASES RETORNABLES
-- =============================================================================

CREATE TABLE envase (
    envase_id         SERIAL PRIMARY KEY,
    empresa_id        INTEGER      NOT NULL REFERENCES empresa(empresa_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    codigo            VARCHAR(50)  NOT NULL,
    tipo              VARCHAR(50),
    capacidad_litros  NUMERIC(8,2),
    fecha_adquisicion DATE,
    estado            VARCHAR(20)  NOT NULL DEFAULT 'DISPONIBLE',

    CONSTRAINT uq_envase_codigo_empresa UNIQUE (empresa_id, codigo),
    CONSTRAINT ck_envase_estado CHECK (estado IN (
        'DISPONIBLE', 'LLENO', 'EN_CLIENTE', 'VACIO',
        'EN_LAVADO', 'DANADO', 'BAJA'
    ))
);

CREATE INDEX idx_envase_estado ON envase(estado);

CREATE TABLE movimiento_envase (
    movimiento_envase_id SERIAL PRIMARY KEY,
    envase_id            INTEGER     NOT NULL REFERENCES envase(envase_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cliente_id           INTEGER     REFERENCES cliente(cliente_id) ON DELETE SET NULL ON UPDATE CASCADE,
    entrega_id           INTEGER     REFERENCES entrega(entrega_id) ON DELETE SET NULL ON UPDATE CASCADE,
    fecha                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tipo_movimiento      VARCHAR(30) NOT NULL,
    estado_anterior      VARCHAR(20),
    estado_nuevo         VARCHAR(20) NOT NULL,
    observacion          TEXT,

    CONSTRAINT ck_mov_envase_tipo CHECK (tipo_movimiento IN (
        'ASIGNACION', 'ENTREGA', 'DEVOLUCION', 'LAVADO',
        'DANIO', 'BAJA', 'AJUSTE'
    ))
);

CREATE INDEX idx_mov_envase_envase  ON movimiento_envase(envase_id);
CREATE INDEX idx_mov_envase_cliente ON movimiento_envase(cliente_id);

-- =============================================================================
-- 14. WHATSAPP / IA / NOTIFICACIONES
-- =============================================================================

CREATE TABLE conversacion_whatsapp (
    conversacion_id      SERIAL PRIMARY KEY,
    cliente_id           INTEGER     REFERENCES cliente(cliente_id) ON DELETE SET NULL ON UPDATE CASCADE,
    telefono             VARCHAR(20) NOT NULL,
    fecha_inicio         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_ultimo_mensaje TIMESTAMPTZ,
    estado               VARCHAR(20) NOT NULL DEFAULT 'ABIERTA',

    CONSTRAINT ck_conversacion_estado CHECK (estado IN ('ABIERTA', 'CERRADA', 'ESPERANDO', 'ARCHIVADA'))
);

CREATE INDEX idx_conversacion_cliente  ON conversacion_whatsapp(cliente_id);
CREATE INDEX idx_conversacion_telefono ON conversacion_whatsapp(telefono);

CREATE TABLE mensaje_whatsapp (
    mensaje_id          SERIAL PRIMARY KEY,
    conversacion_id     INTEGER     NOT NULL REFERENCES conversacion_whatsapp(conversacion_id) ON DELETE CASCADE ON UPDATE CASCADE,
    remitente           VARCHAR(20) NOT NULL,   -- CLIENTE | SISTEMA | AGENTE
    tipo                VARCHAR(30) NOT NULL DEFAULT 'TEXTO',
    contenido           TEXT,
    fecha               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    message_external_id VARCHAR(100),
    estado              VARCHAR(20),

    CONSTRAINT uq_mensaje_external_id UNIQUE (message_external_id),
    CONSTRAINT ck_mensaje_remitente CHECK (remitente IN ('CLIENTE', 'SISTEMA', 'AGENTE')),
    CONSTRAINT ck_mensaje_tipo      CHECK (tipo IN ('TEXTO', 'IMAGEN', 'AUDIO', 'DOCUMENTO', 'UBICACION', 'PLANTILLA'))
);

CREATE INDEX idx_mensaje_conversacion ON mensaje_whatsapp(conversacion_id);
CREATE INDEX idx_mensaje_fecha        ON mensaje_whatsapp(fecha);

CREATE TABLE solicitud_ia (
    solicitud_ia_id       SERIAL PRIMARY KEY,
    conversacion_id       INTEGER     REFERENCES conversacion_whatsapp(conversacion_id) ON DELETE SET NULL ON UPDATE CASCADE,
    tipo_accion           VARCHAR(50) NOT NULL,
    entrada               TEXT,
    respuesta             TEXT,
    herramienta_utilizada VARCHAR(100),
    resultado             VARCHAR(30),
    modelo                VARCHAR(50),
    tokens_entrada        INTEGER,
    tokens_salida         INTEGER,
    duracion_ms           INTEGER,
    fecha                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_solicitud_ia_resultado CHECK (resultado IN ('EXITOSO', 'ERROR', 'PENDIENTE', 'RECHAZADO'))
);

CREATE INDEX idx_solicitud_ia_conversacion ON solicitud_ia(conversacion_id);
CREATE INDEX idx_solicitud_ia_fecha        ON solicitud_ia(fecha);

CREATE TABLE notificacion (
    notificacion_id  SERIAL PRIMARY KEY,
    cliente_id       INTEGER     REFERENCES cliente(cliente_id) ON DELETE CASCADE ON UPDATE CASCADE,
    entrega_id       INTEGER     REFERENCES entrega(entrega_id) ON DELETE SET NULL ON UPDATE CASCADE,
    tipo             VARCHAR(50) NOT NULL,
    canal            VARCHAR(20) NOT NULL,
    titulo           VARCHAR(150),
    mensaje          TEXT        NOT NULL,
    fecha_programada TIMESTAMPTZ,
    fecha_enviada    TIMESTAMPTZ,
    estado           VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',

    CONSTRAINT ck_notificacion_canal  CHECK (canal IN ('WHATSAPP', 'EMAIL', 'SMS', 'PUSH')),
    CONSTRAINT ck_notificacion_estado CHECK (estado IN ('PENDIENTE', 'ENVIADA', 'FALLIDA', 'CANCELADA'))
);

CREATE INDEX idx_notificacion_estado ON notificacion(estado) WHERE estado = 'PENDIENTE';
CREATE INDEX idx_notificacion_cliente ON notificacion(cliente_id);

-- =============================================================================
-- 15. AUDITORÍA
-- =============================================================================

CREATE TABLE auditoria (
    auditoria_id     SERIAL PRIMARY KEY,
    usuario_id       INTEGER     REFERENCES usuario(usuario_id) ON DELETE SET NULL ON UPDATE CASCADE,
    entidad          VARCHAR(50) NOT NULL,
    entidad_id       INTEGER,
    accion           VARCHAR(30) NOT NULL,
    datos_anteriores JSONB,
    datos_nuevos     JSONB,
    ip               VARCHAR(45),
    fecha            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_auditoria_accion CHECK (accion IN ('CREAR', 'MODIFICAR', 'ELIMINAR', 'LOGIN', 'LOGOUT', 'EXPORTAR'))
);

CREATE INDEX idx_auditoria_entidad ON auditoria(entidad, entidad_id);
CREATE INDEX idx_auditoria_usuario ON auditoria(usuario_id);
CREATE INDEX idx_auditoria_fecha   ON auditoria(fecha);

-- =============================================================================
-- COMENTARIOS DE DOCUMENTACIÓN
-- =============================================================================

COMMENT ON TABLE suscripcion IS 'Núcleo del negocio recurrente. proxima_entrega controla la generación automática de pedidos.';
COMMENT ON COLUMN suscripcion.proxima_entrega IS 'Fecha en que el job debe generar el siguiente pedido a partir de esta suscripción.';
COMMENT ON COLUMN pago.venta_id IS 'XOR con pedido_id: exactamente uno debe estar informado.';
COMMENT ON COLUMN pago.pedido_id IS 'XOR con venta_id: exactamente uno debe estar informado.';
COMMENT ON COLUMN factura.venta_id IS 'XOR con pedido_id: exactamente uno debe estar informado.';
COMMENT ON COLUMN factura.pedido_id IS 'XOR con venta_id: exactamente uno debe estar informado.';
COMMENT ON COLUMN entrega.direccion_snapshot IS 'Copia textual de la dirección al momento de la entrega (evidencia histórica).';
COMMENT ON COLUMN factura.datos_fiscales_snapshot IS 'JSONB con RUC, razón social y dirección fiscal del cliente al emitir.';
COMMENT ON COLUMN auditoria.datos_anteriores IS 'Estado previo del registro en formato JSONB.';
COMMENT ON COLUMN auditoria.datos_nuevos IS 'Estado nuevo del registro en formato JSONB.';

COMMIT;

-- =============================================================================
-- FIN DEL SCHEMA
-- =============================================================================
