-- =============================================================================
-- SEED.SQL — Datos de prueba realistas
-- Distribución Recurrente de Agua Purificada
-- Flujo validado:
--   Suscripción → Pedido automático → Entrega → Pago → Factura → Dashboard
-- =============================================================================
-- La base y las tablas ya deben existir (schema.sql aplicado).
-- Este script limpia datos previos y carga el seed.
-- =============================================================================

ROLLBACK;  -- limpia cualquier transacción abortada previa
BEGIN;

-- ---------------------------------------------------------------------------
-- Limpiar datos previos (orden inverso de FKs)
-- ---------------------------------------------------------------------------
TRUNCATE TABLE
    auditoria,
    notificacion,
    solicitud_ia,
    mensaje_whatsapp,
    conversacion_whatsapp,
    movimiento_envase,
    envase,
    movimiento_inventario,
    inventario,
    detalle_factura,
    factura,
    pago,
    detalle_venta,
    venta,
    detalle_entrega,
    entrega,
    asignacion_ruta,
    vehiculo,
    detalle_pedido,
    pedido,
    detalle_suscripcion,
    suscripcion,
    ruta_sector,
    horario_ruta,
    ruta,
    direccion,
    sector,
    cliente,
    producto,
    repartidor,
    usuario_rol,
    usuario,
    rol,
    sucursal,
    empresa
RESTART IDENTITY CASCADE;

-- =============================================================================
-- 1. EMPRESA Y SUCURSALES
-- =============================================================================

INSERT INTO empresa (empresa_id, nombre, razon_social, ruc, telefono, email, direccion, estado) VALUES
(1, 'Agua Pura del Valle', 'AGUA PURA DEL VALLE CIA. LTDA.', '1792345678001',
 '02-2456789', 'info@aguapuradelvalle.com', 'Av. Amazonas N34-120 y Atahualpa, Quito', 'ACTIVO');

SELECT setval('empresa_empresa_id_seq', 1);

INSERT INTO sucursal (sucursal_id, empresa_id, codigo, nombre, tipo, direccion, telefono, email, latitud, longitud, estado) VALUES
(1, 1, 'CENTRO',  'Planta Centro',      'PLANTA', 'Av. 10 de Agosto N26-45 y Colón, Quito',       '02-2501001', 'centro@aguapuradelvalle.com',  -0.180653, -78.467834, 'ACTIVO'),
(2, 1, 'NORTE',   'Sucursal Norte',     'LOCAL',  'Av. 6 de Diciembre N34-80 y Eloy Alfaro, Quito', '02-2501002', 'norte@aguapuradelvalle.com',   -0.165000, -78.470000, 'ACTIVO'),
(3, 1, 'SUR',     'Sucursal Sur',       'LOCAL',  'Av. Maldonado Oe3-120 y Alonso de Angulo, Quito','02-2501003', 'sur@aguapuradelvalle.com',     -0.280000, -78.520000, 'ACTIVO');

SELECT setval('sucursal_sucursal_id_seq', 3);

-- =============================================================================
-- 2. ROLES Y USUARIOS
-- =============================================================================

INSERT INTO rol (rol_id, nombre, descripcion, estado) VALUES
(1, 'SUPER_ADMIN',    'Acceso total al sistema',                    'ACTIVO'),
(2, 'ADMIN_EMPRESA',  'Administrador de la empresa',                'ACTIVO'),
(3, 'ADMIN_SUCURSAL', 'Administrador de sucursal',                  'ACTIVO'),
(4, 'VENDEDOR',       'Vendedor de mostrador / POS',                'ACTIVO'),
(5, 'REPARTIDOR',     'Repartidor de ruta',                         'ACTIVO'),
(6, 'OPERADOR',       'Operador de planta / inventario',            'ACTIVO');

SELECT setval('rol_rol_id_seq', 6);

-- password_hash ficticio (bcrypt de "Password123!")
INSERT INTO usuario (usuario_id, empresa_id, sucursal_id, nombre, apellido, cedula, telefono, email, password_hash, estado, ultimo_acceso) VALUES
(1, 1, NULL, 'Carlos',  'Mendoza',  '1712345678', '0991110001', 'carlos.mendoza@aguapuradelvalle.com', '$2b$10$ejemploHashSuperAdmin001', 'ACTIVO', NOW() - INTERVAL '1 hour'),
(2, 1, 1,    'María',   'Vega',     '1712345679', '0991110002', 'maria.vega@aguapuradelvalle.com',     '$2b$10$ejemploHashAdminSuc002',   'ACTIVO', NOW() - INTERVAL '2 hours'),
(3, 1, 1,    'Luis',    'Paredes',  '1712345680', '0991110003', 'luis.paredes@aguapuradelvalle.com',   '$2b$10$ejemploHashVendedor003',  'ACTIVO', NOW() - INTERVAL '30 minutes'),
(4, 1, 1,    'Diego',   'Salazar',  '1712345681', '0991110004', 'diego.salazar@aguapuradelvalle.com',  '$2b$10$ejemploHashRepart004',    'ACTIVO', NOW() - INTERVAL '15 minutes'),
(5, 1, 1,    'Andrés',  'Castro',   '1712345682', '0991110005', 'andres.castro@aguapuradelvalle.com',  '$2b$10$ejemploHashRepart005',    'ACTIVO', NOW() - INTERVAL '20 minutes'),
(6, 1, 2,    'Patricia','Morales',  '1712345683', '0991110006', 'patricia.morales@aguapuradelvalle.com','$2b$10$ejemploHashAdminNorte006','ACTIVO', NOW() - INTERVAL '3 hours'),
(7, 1, 1,    'Jorge',   'Ruiz',     '1712345684', '0991110007', 'jorge.ruiz@aguapuradelvalle.com',      '$2b$10$ejemploHashOperador007',  'ACTIVO', NOW() - INTERVAL '1 day');

SELECT setval('usuario_usuario_id_seq', 7);

INSERT INTO usuario_rol (usuario_id, rol_id) VALUES
(1, 1), -- Carlos → SUPER_ADMIN
(2, 3), -- María  → ADMIN_SUCURSAL
(3, 4), -- Luis   → VENDEDOR
(4, 5), -- Diego  → REPARTIDOR
(5, 5), -- Andrés → REPARTIDOR
(6, 3), -- Patricia → ADMIN_SUCURSAL Norte
(7, 6); -- Jorge  → OPERADOR

INSERT INTO repartidor (usuario_id, licencia, tipo_licencia, fecha_vencimiento_licencia, estado) VALUES
(4, 'B-1234567', 'B', '2027-06-15', 'ACTIVO'),
(5, 'B-7654321', 'B', '2026-11-30', 'ACTIVO');

-- =============================================================================
-- 3. PRODUCTOS
-- =============================================================================

INSERT INTO producto (producto_id, empresa_id, codigo, nombre, descripcion, categoria, capacidad_litros, precio, costo, requiere_envase, estado) VALUES
(1, 1, 'BOT-20L',   'Botellón 20L',          'Agua purificada en botellón retornable de 20 litros', 'BOTELLON', 20.00, 3.50, 1.20, TRUE,  'ACTIVO'),
(2, 1, 'BOT-10L',   'Botellón 10L',          'Agua purificada en botellón retornable de 10 litros', 'BOTELLON', 10.00, 2.50, 0.90, TRUE,  'ACTIVO'),
(3, 1, 'PET-5L',    'Bidón 5L',              'Agua purificada en bidón desechable de 5 litros',     'BIDON',     5.00, 2.00, 0.70, FALSE, 'ACTIVO'),
(4, 1, 'PET-1L',    'Botella 1L',            'Agua purificada en botella PET de 1 litro',           'BOTELLA',   1.00, 0.80, 0.25, FALSE, 'ACTIVO'),
(5, 1, 'PACK-6X1',  'Pack 6 botellas 1L',    'Pack de 6 botellas PET de 1 litro',                   'PACK',      6.00, 4.20, 1.40, FALSE, 'ACTIVO'),
(6, 1, 'DISP-H',    'Dispensador de mesa',   'Dispensador manual de sobremesa para botellón 20L',   'ACCESORIO', NULL, 18.00, 9.00, FALSE, 'ACTIVO');

SELECT setval('producto_producto_id_seq', 6);

-- =============================================================================
-- 4. SECTORES Y RUTAS (Sucursal Centro)
-- =============================================================================

INSERT INTO sector (sector_id, sucursal_id, nombre, descripcion, estado) VALUES
(1, 1, 'La Floresta',       'Sector residencial La Floresta',              'ACTIVO'),
(2, 1, 'La Mariscal',       'Zona comercial y residencial La Mariscal',    'ACTIVO'),
(3, 1, 'Centro Histórico',  'Centro Histórico de Quito',                   'ACTIVO'),
(4, 1, 'González Suárez',   'Sector González Suárez y alrededores',        'ACTIVO'),
(5, 2, 'Carolina',          'Parque La Carolina y zonas aledañas',         'ACTIVO'),
(6, 2, 'Jipijapa',          'Sector Jipijapa',                             'ACTIVO'),
(7, 3, 'Quitumbe',          'Sector Quitumbe',                             'ACTIVO');

SELECT setval('sector_sector_id_seq', 7);

INSERT INTO ruta (ruta_id, sucursal_id, nombre, descripcion, estado) VALUES
(1, 1, 'Ruta Centro Norte',  'Cubre La Floresta y González Suárez',  'ACTIVO'),
(2, 1, 'Ruta Centro Sur',    'Cubre La Mariscal y Centro Histórico', 'ACTIVO'),
(3, 2, 'Ruta Norte A',       'Cubre Carolina y Jipijapa',            'ACTIVO'),
(4, 3, 'Ruta Sur A',         'Cubre Quitumbe',                       'ACTIVO');

SELECT setval('ruta_ruta_id_seq', 4);

INSERT INTO horario_ruta (horario_ruta_id, ruta_id, dia_semana, hora_inicio, hora_fin, estado) VALUES
-- Ruta Centro Norte: Lun, Mié, Vie
(1, 1, 1, '08:00', '12:00', 'ACTIVO'),
(2, 1, 3, '08:00', '12:00', 'ACTIVO'),
(3, 1, 5, '08:00', '12:00', 'ACTIVO'),
-- Ruta Centro Sur: Mar, Jue
(4, 2, 2, '09:00', '13:00', 'ACTIVO'),
(5, 2, 4, '09:00', '13:00', 'ACTIVO'),
-- Ruta Norte A: Lun a Vie
(6, 3, 1, '07:30', '11:30', 'ACTIVO'),
(7, 3, 2, '07:30', '11:30', 'ACTIVO'),
(8, 3, 3, '07:30', '11:30', 'ACTIVO'),
(9, 3, 4, '07:30', '11:30', 'ACTIVO'),
(10,3, 5, '07:30', '11:30', 'ACTIVO'),
-- Ruta Sur A: Mié, Sáb
(11,4, 3, '08:30', '12:30', 'ACTIVO'),
(12,4, 6, '08:30', '12:30', 'ACTIVO');

SELECT setval('horario_ruta_horario_ruta_id_seq', 12);

INSERT INTO ruta_sector (ruta_id, sector_id, orden) VALUES
(1, 1, 1),  -- Centro Norte → La Floresta
(1, 4, 2),  -- Centro Norte → González Suárez
(2, 2, 1),  -- Centro Sur   → La Mariscal
(2, 3, 2),  -- Centro Sur   → Centro Histórico
(3, 5, 1),  -- Norte A      → Carolina
(3, 6, 2),  -- Norte A      → Jipijapa
(4, 7, 1);  -- Sur A        → Quitumbe

-- =============================================================================
-- 5. CLIENTES Y DIRECCIONES
-- =============================================================================

INSERT INTO cliente (cliente_id, empresa_id, tipo_cliente, nombre, apellido, razon_social, cedula_ruc, telefono, whatsapp, email, estado, fecha_registro) VALUES
(1, 1, 'PERSONA',  'Juan',     'Pérez',     NULL,                        '1711111111', '0987654321', '0987654321', 'juan.perez@email.com',       'ACTIVO', NOW() - INTERVAL '8 months'),
(2, 1, 'PERSONA',  'Ana',      'García',    NULL,                        '1722222222', '0987654322', '0987654322', 'ana.garcia@email.com',       'ACTIVO', NOW() - INTERVAL '6 months'),
(3, 1, 'EMPRESA',  NULL,       NULL,        'CAFETERÍA EL BUEN CAFÉ',    '1798765432001','022345678', '0998765432', 'compras@elbuencafe.com',     'ACTIVO', NOW() - INTERVAL '4 months'),
(4, 1, 'PERSONA',  'Roberto',  'López',     NULL,                        '1733333333', '0987654323', '0987654323', 'roberto.lopez@email.com',    'ACTIVO', NOW() - INTERVAL '3 months'),
(5, 1, 'PERSONA',  'Sofía',    'Herrera',   NULL,                        '1744444444', '0987654324', '0987654324', 'sofia.herrera@email.com',    'ACTIVO', NOW() - INTERVAL '2 months'),
(6, 1, 'EMPRESA',  NULL,       NULL,        'OFICINAS TORRE EMPRESARIAL','1791122334001','022456789', '0991122334', 'admin@torreempresarial.com', 'ACTIVO', NOW() - INTERVAL '5 months'),
(7, 1, 'PERSONA',  'Miguel',   'Torres',    NULL,                        '1755555555', '0987654325', '0987654325', 'miguel.torres@email.com',    'ACTIVO', NOW() - INTERVAL '1 month'),
(8, 1, 'PERSONA',  'Laura',    'Jiménez',   NULL,                        '1766666666', '0987654326', '0987654326', 'laura.jimenez@email.com',    'MOROSO', NOW() - INTERVAL '10 months');

SELECT setval('cliente_cliente_id_seq', 8);

INSERT INTO direccion (direccion_id, cliente_id, sector_id, alias, calle_principal, calle_secundaria, numero, referencia, latitud, longitud, es_principal, estado) VALUES
(1, 1, 1, 'Casa',     'Calle Isabel La Católica', 'Coruña',           'N24-45',  'Casa esquinera color blanco, portón negro',     -0.203500, -78.485000, TRUE,  'ACTIVO'),
(2, 1, 2, 'Oficina',  'Av. Amazonas',             'Wilson',           'N21-10',  'Edificio Torres, piso 3 oficina 302',           -0.198000, -78.488000, FALSE, 'ACTIVO'),
(3, 2, 1, 'Casa',     'Calle Madrid',             'Lugo',             'E5-12',   'Frente al parque de La Floresta',               -0.204000, -78.486500, TRUE,  'ACTIVO'),
(4, 3, 2, 'Local',    'Calle Juan León Mera',     'Calama',           'N22-30',  'Cafetería con toldo rojo',                      -0.199500, -78.490000, TRUE,  'ACTIVO'),
(5, 4, 3, 'Casa',     'Calle Chile',              'Guayaquil',        'Oe3-18',  'Casa de dos pisos, puerta verde',               -0.220000, -78.512000, TRUE,  'ACTIVO'),
(6, 5, 4, 'Casa',     'Av. González Suárez',      'Francisco Salazar','N35-20',  'Conjunto residencial Los Pinos, casa 8',        -0.175000, -78.475000, TRUE,  'ACTIVO'),
(7, 6, 5, 'Oficina',  'Av. República',            'Naciones Unidas',  'N34-50',  'Torre Empresarial, piso 12',                    -0.176000, -78.480000, TRUE,  'ACTIVO'),
(8, 7, 6, 'Casa',     'Calle de los Shyris',      'Eloy Alfaro',      'N36-15',  'Edificio azul, depto 4B',                        -0.168000, -78.478000, TRUE,  'ACTIVO'),
(9, 8, 7, 'Casa',     'Av. Rumichaca',            'Morán Valverde',   'S42-08',  'Casa con reja negra',                           -0.295000, -78.535000, TRUE,  'ACTIVO');

SELECT setval('direccion_direccion_id_seq', 9);

-- =============================================================================
-- 6. SUSCRIPCIONES + DETALLES
-- =============================================================================

INSERT INTO suscripcion (
    suscripcion_id, cliente_id, direccion_id, sucursal_id, ruta_id,
    frecuencia, dia_semana, hora_inicio, hora_fin,
    fecha_inicio, fecha_fin, proxima_entrega, ultima_generacion,
    estado, observaciones, fecha_creacion
) VALUES
-- Juan Pérez: 2 botellones cada semana (miércoles)
(1, 1, 1, 1, 1, 'SEMANAL', 3, '09:00', '12:00',
 CURRENT_DATE - INTERVAL '3 months', NULL,
 CURRENT_DATE + ((3 - EXTRACT(DOW FROM CURRENT_DATE)::INT + 7) % 7),  -- próximo miércoles
 NOW() - INTERVAL '7 days',
 'ACTIVA', 'Cliente puntual, prefiere dejar en portería', NOW() - INTERVAL '3 months'),

-- Ana García: 1 botellón quincenal (lunes)
(2, 2, 3, 1, 1, 'QUINCENAL', 1, '08:00', '11:00',
 CURRENT_DATE - INTERVAL '2 months', NULL,
 CURRENT_DATE + 7,
 NOW() - INTERVAL '14 days',
 'ACTIVA', NULL, NOW() - INTERVAL '2 months'),

-- Cafetería El Buen Café: 5 botellones semanales (martes)
(3, 3, 4, 1, 2, 'SEMANAL', 2, '09:00', '12:00',
 CURRENT_DATE - INTERVAL '4 months', NULL,
 CURRENT_DATE + ((2 - EXTRACT(DOW FROM CURRENT_DATE)::INT + 7) % 7),
 NOW() - INTERVAL '7 days',
 'ACTIVA', 'Entregar antes de las 10:30 si es posible', NOW() - INTERVAL '4 months'),

-- Torre Empresarial: 10 botellones + 2 packs semanales (lunes)
(4, 6, 7, 2, 3, 'SEMANAL', 1, '07:30', '10:00',
 CURRENT_DATE - INTERVAL '5 months', NULL,
 CURRENT_DATE + ((1 - EXTRACT(DOW FROM CURRENT_DATE)::INT + 7) % 7),
 NOW() - INTERVAL '7 days',
 'ACTIVA', 'Recepción en lobby, pedir a seguridad', NOW() - INTERVAL '5 months'),

-- Sofía Herrera: 1 botellón semanal (viernes) — recién activada
(5, 5, 6, 1, 1, 'SEMANAL', 5, '09:00', '12:00',
 CURRENT_DATE - INTERVAL '2 weeks', NULL,
 CURRENT_DATE + ((5 - EXTRACT(DOW FROM CURRENT_DATE)::INT + 7) % 7),
 NULL,
 'ACTIVA', 'Primera entrega ya realizada', NOW() - INTERVAL '2 weeks'),

-- Roberto López: suscripción pausada
(6, 4, 5, 1, 2, 'SEMANAL', 4, '10:00', '13:00',
 CURRENT_DATE - INTERVAL '2 months', NULL,
 NULL, NOW() - INTERVAL '21 days',
 'PAUSADA', 'Cliente de viaje por 1 mes', NOW() - INTERVAL '2 months');

SELECT setval('suscripcion_suscripcion_id_seq', 6);

INSERT INTO detalle_suscripcion (detalle_suscripcion_id, suscripcion_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 2, 3.50),   -- Juan: 2× Botellón 20L
(2, 2, 1, 1, 3.50),   -- Ana:  1× Botellón 20L
(3, 3, 1, 5, 3.30),   -- Café: 5× Botellón 20L (precio corporativo)
(4, 4, 1, 10, 3.20),  -- Torre: 10× Botellón 20L
(5, 4, 5, 2, 4.00),   -- Torre: 2× Pack 6×1L
(6, 5, 1, 1, 3.50),   -- Sofía: 1× Botellón 20L
(7, 6, 1, 2, 3.50);   -- Roberto (pausada): 2× Botellón 20L

SELECT setval('detalle_suscripcion_detalle_suscripcion_id_seq', 7);

-- =============================================================================
-- 7. PEDIDOS (generados desde suscripciones + uno manual WhatsApp)
-- =============================================================================

INSERT INTO pedido (
    pedido_id, cliente_id, sucursal_id, direccion_id, suscripcion_id,
    canal_origen, fecha_pedido, fecha_entrega_solicitada, estado,
    subtotal, descuento, impuesto, total, observaciones, fecha_creacion
) VALUES
-- Pedidos generados automáticamente la semana pasada (ya entregados)
(1, 1, 1, 1, 1, 'SUSCRIPCION',
 NOW() - INTERVAL '7 days', (CURRENT_DATE - INTERVAL '7 days')::DATE,
 'ENTREGADO', 7.00, 0, 0.84, 7.84, 'Generado automáticamente desde suscripción #1',
 NOW() - INTERVAL '7 days'),

(2, 3, 1, 4, 3, 'SUSCRIPCION',
 NOW() - INTERVAL '7 days', (CURRENT_DATE - INTERVAL '6 days')::DATE,
 'ENTREGADO', 16.50, 0, 1.98, 18.48, 'Generado automáticamente desde suscripción #3',
 NOW() - INTERVAL '7 days'),

(3, 6, 2, 7, 4, 'SUSCRIPCION',
 NOW() - INTERVAL '7 days', (CURRENT_DATE - INTERVAL '7 days')::DATE,
 'ENTREGADO', 40.00, 0, 4.80, 44.80, 'Generado automáticamente desde suscripción #4',
 NOW() - INTERVAL '7 days'),

-- Pedidos de esta semana (en proceso)
(4, 1, 1, 1, 1, 'SUSCRIPCION',
 NOW() - INTERVAL '1 day', CURRENT_DATE,
 'EN_RUTA', 7.00, 0, 0.84, 7.84, 'Generado automáticamente desde suscripción #1',
 NOW() - INTERVAL '1 day'),

(5, 3, 1, 4, 3, 'SUSCRIPCION',
 NOW() - INTERVAL '1 day', CURRENT_DATE,
 'PREPARADO', 16.50, 0, 1.98, 18.48, 'Generado automáticamente desde suscripción #3',
 NOW() - INTERVAL '1 day'),

(6, 5, 1, 6, 5, 'SUSCRIPCION',
 NOW() - INTERVAL '2 days', CURRENT_DATE,
 'CONFIRMADO', 3.50, 0, 0.42, 3.92, 'Generado automáticamente desde suscripción #5',
 NOW() - INTERVAL '2 days'),

-- Pedido manual por WhatsApp (Ana pidió extra)
(7, 2, 1, 3, NULL, 'WHATSAPP',
 NOW() - INTERVAL '3 hours', CURRENT_DATE + INTERVAL '1 day',
 'CONFIRMADO', 7.00, 0, 0.84, 7.84, 'Cliente solicitó 2 botellones extras por WhatsApp',
 NOW() - INTERVAL '3 hours'),

-- Pedido cancelado
(8, 7, 2, 8, NULL, 'WEB',
 NOW() - INTERVAL '5 days', (CURRENT_DATE - INTERVAL '3 days')::DATE,
 'CANCELADO', 3.50, 0, 0.42, 3.92, 'Cliente canceló por viaje',
 NOW() - INTERVAL '5 days');

SELECT setval('pedido_pedido_id_seq', 8);

INSERT INTO detalle_pedido (detalle_pedido_id, pedido_id, producto_id, cantidad, precio_unitario, descuento, subtotal) VALUES
(1, 1, 1, 2, 3.50, 0, 7.00),
(2, 2, 1, 5, 3.30, 0, 16.50),
(3, 3, 1, 10, 3.20, 0, 32.00),
(4, 3, 5, 2, 4.00, 0, 8.00),
(5, 4, 1, 2, 3.50, 0, 7.00),
(6, 5, 1, 5, 3.30, 0, 16.50),
(7, 6, 1, 1, 3.50, 0, 3.50),
(8, 7, 1, 2, 3.50, 0, 7.00),
(9, 8, 1, 1, 3.50, 0, 3.50);

SELECT setval('detalle_pedido_detalle_pedido_id_seq', 9);

-- =============================================================================
-- 8. VEHÍCULOS Y ASIGNACIONES DE RUTA
-- =============================================================================

INSERT INTO vehiculo (vehiculo_id, sucursal_id, placa, marca, modelo, anio, tipo, capacidad, estado) VALUES
(1, 1, 'PCB-1234', 'Chevrolet', 'N300',  2021, 'CAMIONETA', 40, 'ACTIVO'),
(2, 1, 'PCB-5678', 'Hyundai',   'H100',  2020, 'CAMIONETA', 50, 'ACTIVO'),
(3, 2, 'PCC-9012', 'Chevrolet', 'N300',  2022, 'CAMIONETA', 40, 'ACTIVO'),
(4, 1, 'PCB-3456', 'Suzuki',    'Carry', 2019, 'CAMIONETA', 30, 'MANTENIMIENTO');

SELECT setval('vehiculo_vehiculo_id_seq', 4);

INSERT INTO asignacion_ruta (asignacion_ruta_id, ruta_id, repartidor_id, vehiculo_id, fecha, hora_inicio, hora_fin, estado) VALUES
-- Semana pasada
(1, 1, 4, 1, CURRENT_DATE - 7, '08:00', '12:00', 'FINALIZADA'),
(2, 2, 5, 2, CURRENT_DATE - 6, '09:00', '13:00', 'FINALIZADA'),
(3, 3, 4, 3, CURRENT_DATE - 7, '07:30', '11:30', 'FINALIZADA'),
-- Hoy
(4, 1, 4, 1, CURRENT_DATE,     '08:00', '12:00', 'EN_CURSO'),
(5, 2, 5, 2, CURRENT_DATE,     '09:00', '13:00', 'PROGRAMADA');

SELECT setval('asignacion_ruta_asignacion_ruta_id_seq', 5);

-- =============================================================================
-- 9. ENTREGAS + DETALLES
-- =============================================================================

INSERT INTO entrega (
    entrega_id, pedido_id, cliente_id, direccion_id, ruta_id, repartidor_id, vehiculo_id,
    fecha_programada, hora_programada_inicio, hora_programada_fin,
    hora_salida, hora_llegada, hora_entrega, estado, observaciones,
    latitud_entrega, longitud_entrega, direccion_snapshot, referencia_snapshot
) VALUES
-- Entregas completadas semana pasada
(1, 1, 1, 1, 1, 4, 1,
 CURRENT_DATE - 7, '09:00', '12:00',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '08:15',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '09:40',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '09:55',
 'ENTREGADA', 'Entregado en portería según instrucción del cliente',
 -0.203500, -78.485000,
 'Calle Isabel La Católica y Coruña N24-45', 'Casa esquinera color blanco, portón negro'),

(2, 2, 3, 4, 2, 5, 2,
 CURRENT_DATE - 6, '09:00', '12:00',
 (CURRENT_DATE - 6)::TIMESTAMP + TIME '09:10',
 (CURRENT_DATE - 6)::TIMESTAMP + TIME '10:05',
 (CURRENT_DATE - 6)::TIMESTAMP + TIME '10:20',
 'ENTREGADA', NULL,
 -0.199500, -78.490000,
 'Calle Juan León Mera y Calama N22-30', 'Cafetería con toldo rojo'),

(3, 3, 6, 7, 3, 4, 3,
 CURRENT_DATE - 7, '07:30', '10:00',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '07:40',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '08:30',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '08:45',
 'ENTREGADA', 'Recibido por seguridad del edificio',
 -0.176000, -78.480000,
 'Av. República y Naciones Unidas N34-50', 'Torre Empresarial, piso 12'),

-- Entrega de hoy EN_RUTA
(4, 4, 1, 1, 1, 4, 1,
 CURRENT_DATE, '09:00', '12:00',
 NOW() - INTERVAL '45 minutes',
 NULL, NULL,
 'EN_RUTA', NULL,
 NULL, NULL,
 'Calle Isabel La Católica y Coruña N24-45', 'Casa esquinera color blanco, portón negro'),

-- Entrega preparada (aún no sale)
(5, 5, 3, 4, 2, 5, 2,
 CURRENT_DATE, '09:00', '12:00',
 NULL, NULL, NULL,
 'PREPARADA', 'Botellones listos en muelle',
 NULL, NULL,
 'Calle Juan León Mera y Calama N22-30', 'Cafetería con toldo rojo'),

-- Entrega programada
(6, 6, 5, 6, 1, 4, 1,
 CURRENT_DATE, '09:00', '12:00',
 NULL, NULL, NULL,
 'PROGRAMADA', NULL,
 NULL, NULL,
 'Av. González Suárez y Francisco Salazar N35-20', 'Conjunto residencial Los Pinos, casa 8');

SELECT setval('entrega_entrega_id_seq', 6);

INSERT INTO detalle_entrega (detalle_entrega_id, entrega_id, producto_id, cantidad_programada, cantidad_entregada, cantidad_rechazada, motivo_rechazo) VALUES
(1, 1, 1, 2, 2, 0, NULL),
(2, 2, 1, 5, 5, 0, NULL),
(3, 3, 1, 10, 10, 0, NULL),
(4, 3, 5, 2, 2, 0, NULL),
(5, 4, 1, 2, NULL, 0, NULL),   -- aún en ruta
(6, 5, 1, 5, NULL, 0, NULL),   -- preparada
(7, 6, 1, 1, NULL, 0, NULL);   -- programada

SELECT setval('detalle_entrega_detalle_entrega_id_seq', 7);

-- =============================================================================
-- 10. PAGOS (asociados a pedidos entregados)
-- =============================================================================

INSERT INTO pago (pago_id, venta_id, pedido_id, fecha_pago, metodo_pago, monto, referencia, estado) VALUES
-- Juan pagó pedido #1 en efectivo al repartidor
(1, NULL, 1, (CURRENT_DATE - 7)::TIMESTAMP + TIME '09:55', 'EFECTIVO',      7.84,  NULL,              'CONFIRMADO'),
-- Cafetería pagó por transferencia
(2, NULL, 2, (CURRENT_DATE - 6)::TIMESTAMP + TIME '14:30', 'TRANSFERENCIA', 18.48, 'TRX-20260916-8841','CONFIRMADO'),
-- Torre Empresarial: pago mixto
(3, NULL, 3, (CURRENT_DATE - 7)::TIMESTAMP + TIME '09:00', 'TRANSFERENCIA', 30.00, 'TRX-20260916-9902','CONFIRMADO'),
(4, NULL, 3, (CURRENT_DATE - 7)::TIMESTAMP + TIME '09:00', 'EFECTIVO',      14.80, NULL,              'CONFIRMADO'),
-- Pedido de hoy aún sin pagar (se cobra al entregar)
-- Pedido WhatsApp de Ana: pago pendiente
(5, NULL, 7, NOW() - INTERVAL '1 hour', 'TRANSFERENCIA', 7.84, 'TRX-PENDIENTE-001', 'PENDIENTE');

SELECT setval('pago_pago_id_seq', 5);

-- =============================================================================
-- 11. FACTURAS (asociadas a pedidos entregados)
-- =============================================================================

INSERT INTO factura (
    factura_id, venta_id, pedido_id, cliente_id,
    numero_factura, clave_acceso, fecha_emision,
    subtotal, impuesto, total, estado, xml_url, pdf_url,
    datos_fiscales_snapshot
) VALUES
(1, NULL, 1, 1,
 '001-001-000000001', '2309202601171234567800110010010000000011234567811',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '10:30',
 7.00, 0.84, 7.84, 'AUTORIZADA',
 'https://storage.example.com/xml/001-001-000000001.xml',
 'https://storage.example.com/pdf/001-001-000000001.pdf',
 '{"ruc":"1711111111","razon_social":"Juan Pérez","direccion":"Calle Isabel La Católica N24-45"}'::JSONB),

(2, NULL, 2, 3,
 '001-001-000000002', '2309202601171234567800110010010000000021234567812',
 (CURRENT_DATE - 6)::TIMESTAMP + TIME '11:00',
 16.50, 1.98, 18.48, 'AUTORIZADA',
 'https://storage.example.com/xml/001-001-000000002.xml',
 'https://storage.example.com/pdf/001-001-000000002.pdf',
 '{"ruc":"1798765432001","razon_social":"CAFETERÍA EL BUEN CAFÉ","direccion":"Calle Juan León Mera N22-30"}'::JSONB),

(3, NULL, 3, 6,
 '001-002-000000001', '2309202601171234567800110010020000000011234567813',
 (CURRENT_DATE - 7)::TIMESTAMP + TIME '09:30',
 40.00, 4.80, 44.80, 'AUTORIZADA',
 'https://storage.example.com/xml/001-002-000000001.xml',
 'https://storage.example.com/pdf/001-002-000000001.pdf',
 '{"ruc":"1791122334001","razon_social":"OFICINAS TORRE EMPRESARIAL","direccion":"Av. República N34-50"}'::JSONB);

SELECT setval('factura_factura_id_seq', 3);

INSERT INTO detalle_factura (detalle_factura_id, factura_id, producto_id, descripcion, cantidad, precio_unitario, descuento, subtotal) VALUES
(1, 1, 1, 'Botellón 20L Agua Purificada', 2, 3.50, 0, 7.00),
(2, 2, 1, 'Botellón 20L Agua Purificada', 5, 3.30, 0, 16.50),
(3, 3, 1, 'Botellón 20L Agua Purificada', 10, 3.20, 0, 32.00),
(4, 3, 5, 'Pack 6 botellas 1L',           2, 4.00, 0, 8.00);

SELECT setval('detalle_factura_detalle_factura_id_seq', 4);

-- =============================================================================
-- 12. VENTA POS (mostrador)
-- =============================================================================

INSERT INTO venta (venta_id, sucursal_id, cliente_id, usuario_id, fecha_venta, subtotal, descuento, impuesto, total, estado) VALUES
(1, 1, NULL, 3, NOW() - INTERVAL '2 days',  5.60, 0, 0.67, 6.27, 'COMPLETADA'),  -- cliente anónimo
(2, 1, 7,    3, NOW() - INTERVAL '1 day',   3.50, 0, 0.42, 3.92, 'COMPLETADA'),  -- Miguel Torres
(3, 1, NULL, 3, NOW() - INTERVAL '3 hours', 22.00, 2.00, 2.40, 22.40, 'COMPLETADA'); -- compra grande

SELECT setval('venta_venta_id_seq', 3);

INSERT INTO detalle_venta (detalle_venta_id, venta_id, producto_id, cantidad, precio_unitario, descuento, subtotal) VALUES
(1, 1, 4, 4, 0.80, 0, 3.20),   -- 4 botellas 1L
(2, 1, 3, 1, 2.00, 0, 2.00),   -- 1 bidón 5L
(3, 2, 1, 1, 3.50, 0, 3.50),   -- 1 botellón
(4, 3, 1, 4, 3.50, 0, 14.00),  -- 4 botellones
(5, 3, 5, 2, 4.00, 0, 8.00);   -- 2 packs

SELECT setval('detalle_venta_detalle_venta_id_seq', 5);

INSERT INTO pago (pago_id, venta_id, pedido_id, fecha_pago, metodo_pago, monto, referencia, estado) VALUES
(6, 1, NULL, NOW() - INTERVAL '2 days',  'EFECTIVO', 6.27,  NULL, 'CONFIRMADO'),
(7, 2, NULL, NOW() - INTERVAL '1 day',   'TARJETA',  3.92,  'VISA-4532', 'CONFIRMADO'),
(8, 3, NULL, NOW() - INTERVAL '3 hours', 'EFECTIVO', 10.00, NULL, 'CONFIRMADO'),
(9, 3, NULL, NOW() - INTERVAL '3 hours', 'TARJETA',  12.40, 'MC-8891', 'CONFIRMADO');

SELECT setval('pago_pago_id_seq', 9);

INSERT INTO factura (
    factura_id, venta_id, pedido_id, cliente_id,
    numero_factura, clave_acceso, fecha_emision,
    subtotal, impuesto, total, estado
) VALUES
(4, 2, NULL, 7,
 '001-001-000000003', '2309202601171234567800110010010000000031234567814',
 NOW() - INTERVAL '1 day',
 3.50, 0.42, 3.92, 'AUTORIZADA');

SELECT setval('factura_factura_id_seq', 4);

INSERT INTO detalle_factura (detalle_factura_id, factura_id, producto_id, descripcion, cantidad, precio_unitario, descuento, subtotal) VALUES
(5, 4, 1, 'Botellón 20L Agua Purificada', 1, 3.50, 0, 3.50);

SELECT setval('detalle_factura_detalle_factura_id_seq', 5);

-- =============================================================================
-- 13. INVENTARIO Y MOVIMIENTOS
-- =============================================================================

INSERT INTO inventario (inventario_id, sucursal_id, producto_id, cantidad_disponible, cantidad_reservada, stock_minimo, fecha_actualizacion) VALUES
-- Planta Centro
(1, 1, 1, 180, 12, 50, NOW()),   -- Botellón 20L
(2, 1, 2,  90,  0, 20, NOW()),   -- Botellón 10L
(3, 1, 3, 150,  0, 30, NOW()),   -- Bidón 5L
(4, 1, 4, 400,  0, 50, NOW()),   -- Botella 1L
(5, 1, 5,  80,  0, 15, NOW()),   -- Pack 6×1L
(6, 1, 6,  12,  0,  3, NOW()),   -- Dispensador
-- Sucursal Norte
(7, 2, 1, 100, 10, 30, NOW()),
(8, 2, 4, 200,  0, 20, NOW()),
(9, 2, 5,  40,  0, 10, NOW()),
-- Sucursal Sur
(10,3, 1,  60,  0, 20, NOW()),
(11,3, 3,  80,  0, 15, NOW());

SELECT setval('inventario_inventario_id_seq', 11);

INSERT INTO movimiento_inventario (movimiento_id, inventario_id, usuario_id, tipo_movimiento, cantidad, referencia_tipo, referencia_id, fecha, observacion) VALUES
-- Entrada de producción
(1, 1, 7, 'ENTRADA', 200, 'PRODUCCION', NULL, NOW() - INTERVAL '10 days', 'Lote producción semanal'),
(2, 7, 7, 'TRANSFERENCIA', 50, 'TRANSFERENCIA', 1, NOW() - INTERVAL '9 days', 'Envío a Sucursal Norte'),
-- Salidas por entregas
(3, 1, 4, 'SALIDA', 2,  'ENTREGA', 1, NOW() - INTERVAL '7 days', 'Entrega pedido #1'),
(4, 1, 5, 'SALIDA', 5,  'ENTREGA', 2, NOW() - INTERVAL '6 days', 'Entrega pedido #2'),
(5, 7, 4, 'SALIDA', 10, 'ENTREGA', 3, NOW() - INTERVAL '7 days', 'Entrega pedido #3'),
(6, 9, 4, 'SALIDA', 2,  'ENTREGA', 3, NOW() - INTERVAL '7 days', 'Packs entrega pedido #3'),
-- Reservas de hoy
(7, 1, 2, 'RESERVA', 2, 'PEDIDO', 4, NOW() - INTERVAL '1 day', 'Reserva pedido #4 en ruta'),
(8, 1, 2, 'RESERVA', 5, 'PEDIDO', 5, NOW() - INTERVAL '1 day', 'Reserva pedido #5 preparado'),
(9, 1, 2, 'RESERVA', 1, 'PEDIDO', 6, NOW() - INTERVAL '2 days', 'Reserva pedido #6'),
-- Ventas POS
(10,1, 3, 'SALIDA', 1, 'VENTA', 2, NOW() - INTERVAL '1 day', 'Venta POS #2'),
(11,4, 3, 'SALIDA', 4, 'VENTA', 1, NOW() - INTERVAL '2 days', 'Venta POS #1'),
(12,3, 3, 'SALIDA', 1, 'VENTA', 1, NOW() - INTERVAL '2 days', 'Venta POS #1'),
(13,1, 3, 'SALIDA', 4, 'VENTA', 3, NOW() - INTERVAL '3 hours', 'Venta POS #3'),
(14,5, 3, 'SALIDA', 2, 'VENTA', 3, NOW() - INTERVAL '3 hours', 'Venta POS #3');

SELECT setval('movimiento_inventario_movimiento_id_seq', 14);

-- =============================================================================
-- 14. ENVASES RETORNABLES
-- =============================================================================

INSERT INTO envase (envase_id, empresa_id, codigo, tipo, capacidad_litros, fecha_adquisicion, estado) VALUES
(1,  1, 'ENV-00001', 'BOTELLON', 20, '2024-01-15', 'EN_CLIENTE'),
(2,  1, 'ENV-00002', 'BOTELLON', 20, '2024-01-15', 'EN_CLIENTE'),
(3,  1, 'ENV-00003', 'BOTELLON', 20, '2024-01-15', 'EN_CLIENTE'),
(4,  1, 'ENV-00004', 'BOTELLON', 20, '2024-01-15', 'EN_CLIENTE'),
(5,  1, 'ENV-00005', 'BOTELLON', 20, '2024-01-15', 'EN_CLIENTE'),
(6,  1, 'ENV-00006', 'BOTELLON', 20, '2024-03-01', 'LLENO'),
(7,  1, 'ENV-00007', 'BOTELLON', 20, '2024-03-01', 'LLENO'),
(8,  1, 'ENV-00008', 'BOTELLON', 20, '2024-03-01', 'VACIO'),
(9,  1, 'ENV-00009', 'BOTELLON', 20, '2024-03-01', 'EN_LAVADO'),
(10, 1, 'ENV-00010', 'BOTELLON', 20, '2024-06-01', 'DISPONIBLE'),
(11, 1, 'ENV-00011', 'BOTELLON', 20, '2024-06-01', 'DISPONIBLE'),
(12, 1, 'ENV-00012', 'BOTELLON', 20, '2024-06-01', 'DANADO'),
(13, 1, 'ENV-00013', 'BOTELLON', 10, '2024-06-01', 'DISPONIBLE'),
(14, 1, 'ENV-00014', 'BOTELLON', 10, '2024-06-01', 'DISPONIBLE'),
(15, 1, 'ENV-00015', 'BOTELLON', 20, '2025-01-10', 'LLENO');

SELECT setval('envase_envase_id_seq', 15);

INSERT INTO movimiento_envase (movimiento_envase_id, envase_id, cliente_id, entrega_id, fecha, tipo_movimiento, estado_anterior, estado_nuevo, observacion) VALUES
-- Ciclo de Juan (pedido #1)
(1, 1, 1, 1, NOW() - INTERVAL '7 days', 'ENTREGA',    'LLENO',      'EN_CLIENTE', 'Entrega pedido #1'),
(2, 2, 1, 1, NOW() - INTERVAL '7 days', 'ENTREGA',    'LLENO',      'EN_CLIENTE', 'Entrega pedido #1'),
-- Devolución de botellones vacíos de Juan (visita anterior)
(3, 8, 1, 1, NOW() - INTERVAL '7 days', 'DEVOLUCION', 'EN_CLIENTE', 'VACIO',      'Recogido vacío en misma visita'),
-- Cafetería
(4, 3, 3, 2, NOW() - INTERVAL '6 days', 'ENTREGA',    'LLENO',      'EN_CLIENTE', 'Entrega pedido #2'),
(5, 4, 3, 2, NOW() - INTERVAL '6 days', 'ENTREGA',    'LLENO',      'EN_CLIENTE', 'Entrega pedido #2'),
(6, 5, 3, 2, NOW() - INTERVAL '6 days', 'ENTREGA',    'LLENO',      'EN_CLIENTE', 'Entrega pedido #2'),
-- Torre
(7, 6, 6, 3, NOW() - INTERVAL '7 days', 'ENTREGA',    'LLENO',      'EN_CLIENTE',  'Entrega pedido #3 — nota: se actualizó estado luego'),
-- Lavado
(8, 9, NULL, NULL, NOW() - INTERVAL '2 days', 'LAVADO', 'VACIO', 'EN_LAVADO', 'Ingreso a línea de lavado'),
-- Daño
(9, 12, NULL, NULL, NOW() - INTERVAL '5 days', 'DANIO', 'VACIO', 'DANADO', 'Grieta en base, enviado a baja');

SELECT setval('movimiento_envase_movimiento_envase_id_seq', 9);

-- =============================================================================
-- 15. WHATSAPP / IA
-- =============================================================================

INSERT INTO conversacion_whatsapp (conversacion_id, cliente_id, telefono, fecha_inicio, fecha_ultimo_mensaje, estado) VALUES
(1, 2, '0987654322', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '30 minutes', 'ABIERTA'),
(2, 1, '0987654321', NOW() - INTERVAL '2 days',  NOW() - INTERVAL '1 day',      'CERRADA'),
(3, 5, '0987654324', NOW() - INTERVAL '5 days',  NOW() - INTERVAL '5 days',     'CERRADA');

SELECT setval('conversacion_whatsapp_conversacion_id_seq', 3);

INSERT INTO mensaje_whatsapp (mensaje_id, conversacion_id, remitente, tipo, contenido, fecha, message_external_id, estado) VALUES
-- Conversación Ana (pedido extra)
(1, 1, 'CLIENTE', 'TEXTO', 'Hola, necesito 2 botellones extras para mañana por favor', NOW() - INTERVAL '3 hours', 'wamid.HBgNODE5NzY1NDMyMhUCABIYFjNFQjA1', 'ENTREGADO'),
(2, 1, 'SISTEMA', 'TEXTO', '¡Hola Ana! 👋 Claro, puedo ayudarte. ¿Confirmas 2× Botellón 20L a $3.50 c/u (total $7.00 + IVA)?', NOW() - INTERVAL '2 hours 55 min', 'wamid.HBgNODE5NzY1NDMyMhUCABIYFjNFQjA2', 'ENTREGADO'),
(3, 1, 'CLIENTE', 'TEXTO', 'Sí, confirmo', NOW() - INTERVAL '2 hours 50 min', 'wamid.HBgNODE5NzY1NDMyMhUCABIYFjNFQjA3', 'ENTREGADO'),
(4, 1, 'SISTEMA', 'TEXTO', '✅ Pedido #7 creado. Entrega programada para mañana. Te avisaremos cuando salga el repartidor.', NOW() - INTERVAL '2 hours 45 min', 'wamid.HBgNODE5NzY1NDMyMhUCABIYFjNFQjA4', 'ENTREGADO'),
(5, 1, 'CLIENTE', 'TEXTO', 'Perfecto, gracias!', NOW() - INTERVAL '30 minutes', 'wamid.HBgNODE5NzY1NDMyMhUCABIYFjNFQjA5', 'ENTREGADO'),
-- Conversación Juan (consulta estado)
(6, 2, 'CLIENTE', 'TEXTO', 'Buenos días, ¿ya salió mi pedido de hoy?', NOW() - INTERVAL '2 days', 'wamid.HBgNODE5NzY1NDMyMQUCABIYFjNFQjB1', 'ENTREGADO'),
(7, 2, 'SISTEMA', 'TEXTO', 'Hola Juan. Tu pedido #1 fue entregado el ' || TO_CHAR(CURRENT_DATE - 7, 'DD/MM') || ' a las 09:55. ¿Necesitas algo más?', NOW() - INTERVAL '2 days' + INTERVAL '2 minutes', 'wamid.HBgNODE5NzY1NDMyMQUCABIYFjNFQjB2', 'ENTREGADO'),
(8, 2, 'CLIENTE', 'TEXTO', 'Ah ya, gracias', NOW() - INTERVAL '1 day', 'wamid.HBgNODE5NzY1NDMyMQUCABIYFjNFQjB3', 'ENTREGADO');

SELECT setval('mensaje_whatsapp_mensaje_id_seq', 8);

INSERT INTO solicitud_ia (solicitud_ia_id, conversacion_id, tipo_accion, entrada, respuesta, herramienta_utilizada, resultado, modelo, tokens_entrada, tokens_salida, duracion_ms, fecha) VALUES
(1, 1, 'CREAR_PEDIDO',
 'Cliente solicita 2 botellones extras para mañana',
 'Pedido #7 creado exitosamente: 2× Botellón 20L, total $7.84, entrega mañana',
 'crear_pedido',
 'EXITOSO', 'gpt-4o-mini', 320, 85, 1250, NOW() - INTERVAL '2 hours 50 min'),

(2, 2, 'CONSULTAR_ESTADO',
 'Cliente pregunta por estado de su pedido de hoy',
 'Pedido #1 entregado el ' || TO_CHAR(CURRENT_DATE - 7, 'DD/MM/YYYY') || ' a las 09:55',
 'consultar_pedido',
 'EXITOSO', 'gpt-4o-mini', 180, 60, 890, NOW() - INTERVAL '2 days' + INTERVAL '1 minute');

SELECT setval('solicitud_ia_solicitud_ia_id_seq', 2);

-- =============================================================================
-- 16. NOTIFICACIONES
-- =============================================================================

INSERT INTO notificacion (notificacion_id, cliente_id, entrega_id, tipo, canal, titulo, mensaje, fecha_programada, fecha_enviada, estado) VALUES
(1, 1, 1, 'ENTREGA_COMPLETADA', 'WHATSAPP',
 'Entrega realizada',
 'Hola Juan, tu pedido de 2 botellones fue entregado exitosamente. ¡Gracias por confiar en nosotros!',
 NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days' + INTERVAL '5 minutes', 'ENVIADA'),

(2, 3, 2, 'ENTREGA_COMPLETADA', 'WHATSAPP',
 'Entrega realizada',
 'Hola, su pedido de 5 botellones fue entregado en Cafetería El Buen Café. Factura enviada por correo.',
 NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days' + INTERVAL '5 minutes', 'ENVIADA'),

(3, 1, 4, 'REPARTIDOR_EN_CAMINO', 'WHATSAPP',
 'Repartidor en camino',
 'Hola Juan, Diego va en camino con tu pedido de 2 botellones. Llegada estimada en 20-40 min.',
 NOW() - INTERVAL '40 minutes', NOW() - INTERVAL '40 minutes', 'ENVIADA'),

(4, 2, NULL, 'PEDIDO_CONFIRMADO', 'WHATSAPP',
 'Pedido confirmado',
 'Hola Ana, tu pedido #7 (2 botellones) está confirmado para mañana. Total: $7.84',
 NOW() - INTERVAL '2 hours 45 min', NOW() - INTERVAL '2 hours 45 min', 'ENVIADA'),

(5, 5, 6, 'RECORDATORIO_ENTREGA', 'WHATSAPP',
 'Entrega programada para hoy',
 'Hola Sofía, hoy te entregamos 1 botellón en tu domicilio. Ventana: 09:00-12:00.',
 CURRENT_DATE::TIMESTAMP + TIME '07:00', NULL, 'PENDIENTE');

SELECT setval('notificacion_notificacion_id_seq', 5);

-- =============================================================================
-- 17. AUDITORÍA (muestra)
-- =============================================================================

INSERT INTO auditoria (auditoria_id, usuario_id, entidad, entidad_id, accion, datos_anteriores, datos_nuevos, ip, fecha) VALUES
(1, 1, 'Suscripcion', 1, 'CREAR',
 NULL,
 '{"cliente_id":1,"frecuencia":"SEMANAL","dia_semana":3,"estado":"ACTIVA"}'::JSONB,
 '10.0.0.15', NOW() - INTERVAL '3 months'),

(2, 2, 'Pedido', 4, 'CREAR',
 NULL,
 '{"cliente_id":1,"suscripcion_id":1,"canal_origen":"SUSCRIPCION","estado":"PENDIENTE","total":7.84}'::JSONB,
 '10.0.0.20', NOW() - INTERVAL '1 day'),

(3, 4, 'Entrega', 1, 'MODIFICAR',
 '{"estado":"EN_RUTA"}'::JSONB,
 jsonb_build_object(
   'estado', 'ENTREGADA',
   'hora_entrega', ((CURRENT_DATE - 7)::TIMESTAMP + TIME '09:55')::TEXT
 ),
 '10.0.1.50', NOW() - INTERVAL '7 days' + INTERVAL '2 hours'),

(4, 3, 'Venta', 3, 'CREAR',
 NULL,
 '{"sucursal_id":1,"total":22.40,"estado":"COMPLETADA"}'::JSONB,
 '10.0.0.25', NOW() - INTERVAL '3 hours'),

(5, 2, 'Suscripcion', 6, 'MODIFICAR',
 '{"estado":"ACTIVA"}'::JSONB,
 '{"estado":"PAUSADA","observaciones":"Cliente de viaje por 1 mes"}'::JSONB,
 '10.0.0.20', NOW() - INTERVAL '21 days');

SELECT setval('auditoria_auditoria_id_seq', 5);

COMMIT;

-- =============================================================================
-- CONSULTAS DE VALIDACIÓN RÁPIDA (opcionales, comentar si no se necesitan)
-- =============================================================================

-- Flujo completo de Juan Pérez (cliente #1)
/*
SELECT
    c.nombre || ' ' || c.apellido AS cliente,
    s.suscripcion_id,
    s.frecuencia,
    s.proxima_entrega,
    p.pedido_id,
    p.estado AS estado_pedido,
    p.total,
    e.entrega_id,
    e.estado AS estado_entrega,
    e.fecha_programada,
    pg.monto AS pago,
    pg.metodo_pago,
    f.numero_factura,
    f.estado AS estado_factura
FROM cliente c
JOIN suscripcion s ON s.cliente_id = c.cliente_id
LEFT JOIN pedido p ON p.suscripcion_id = s.suscripcion_id
LEFT JOIN entrega e ON e.pedido_id = p.pedido_id
LEFT JOIN pago pg ON pg.pedido_id = p.pedido_id
LEFT JOIN factura f ON f.pedido_id = p.pedido_id
WHERE c.cliente_id = 1
ORDER BY p.fecha_pedido DESC;
*/

-- Dashboard del día: entregas programadas hoy
/*
SELECT
    e.entrega_id,
    e.estado,
    c.nombre || COALESCE(' ' || c.apellido, '') AS cliente,
    e.direccion_snapshot,
    r.nombre AS ruta,
    u.nombre || ' ' || u.apellido AS repartidor,
    v.placa,
    e.hora_programada_inicio || ' - ' || e.hora_programada_fin AS ventana
FROM entrega e
JOIN cliente c ON c.cliente_id = e.cliente_id
LEFT JOIN ruta r ON r.ruta_id = e.ruta_id
LEFT JOIN usuario u ON u.usuario_id = e.repartidor_id
LEFT JOIN vehiculo v ON v.vehiculo_id = e.vehiculo_id
WHERE e.fecha_programada = CURRENT_DATE
ORDER BY e.hora_programada_inicio;
*/

-- Resumen de cobros
/*
SELECT
    COALESCE(pg.metodo_pago, 'SIN PAGO') AS metodo,
    COUNT(*) AS cantidad,
    SUM(pg.monto) AS total
FROM pago pg
WHERE pg.estado = 'CONFIRMADO'
GROUP BY pg.metodo_pago
ORDER BY total DESC;
*/
