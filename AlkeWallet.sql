-- ============================================================
-- Alke Wallet: base de datos relacional
-- Motor recomendado: MySQL 8.0+
-- Los datos incluidos son ficticios y solo para demostración.
-- ============================================================

CREATE DATABASE IF NOT EXISTS AlkeWallet
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE AlkeWallet;

-- Para permitir una ejecución limpia durante el desarrollo.
DROP TABLE IF EXISTS transaccion;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS moneda;

CREATE TABLE moneda (
    currency_id INT AUTO_INCREMENT,
    currency_name VARCHAR(50) NOT NULL,
    currency_symbol VARCHAR(10) NOT NULL,
    PRIMARY KEY (currency_id),
    UNIQUE (currency_name),
    UNIQUE (currency_symbol)
);

CREATE TABLE usuario (
    user_id INT AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(150) NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    currency_id INT NOT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE (correo_electronico),
    CONSTRAINT fk_usuario_moneda
        FOREIGN KEY (currency_id)
        REFERENCES moneda(currency_id),
    CONSTRAINT chk_usuario_saldo
        CHECK (saldo >= 0)
);

CREATE TABLE transaccion (
    transaction_id INT AUTO_INCREMENT,
    sender_user_id INT NOT NULL,
    receiver_user_id INT NOT NULL,
    currency_id INT NOT NULL,
    importe DECIMAL(12,2) NOT NULL,
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transaccion_emisor
        FOREIGN KEY (sender_user_id)
        REFERENCES usuario(user_id),
    CONSTRAINT fk_transaccion_receptor
        FOREIGN KEY (receiver_user_id)
        REFERENCES usuario(user_id),
    CONSTRAINT fk_transaccion_moneda
        FOREIGN KEY (currency_id)
        REFERENCES moneda(currency_id),
    CONSTRAINT chk_transaccion_importe
        CHECK (importe > 0),
    CONSTRAINT chk_usuarios_diferentes
        CHECK (sender_user_id <> receiver_user_id),
    INDEX idx_usuario_fecha (sender_user_id, transaction_date)
);

-- Datos de prueba
INSERT INTO moneda (currency_name, currency_symbol)
VALUES
    ('Peso chileno', 'CLP'),
    ('Dólar estadounidense', 'USD'),
    ('Euro', 'EUR');

-- Las cadenas de la columna contrasena son marcadores ficticios.
-- En producción, el backend debe generar hashes con Argon2id o bcrypt.
INSERT INTO usuario
    (nombre, correo_electronico, contrasena, saldo, currency_id)
VALUES
    ('Fabián Oñate', 'fabian@alkewallet.example', 'HASH_DEMO_USUARIO_01', 850000.00, 1),
    ('Camila Soto', 'camila@alkewallet.example', 'HASH_DEMO_USUARIO_02', 420000.00, 1),
    ('Diego Pérez', 'diego@alkewallet.example', 'HASH_DEMO_USUARIO_03', 3000.00, 2),
    ('Valentina Rojas', 'valentina@alkewallet.example', 'HASH_DEMO_USUARIO_04', 1800.00, 2),
    ('Martín López', 'martin@alkewallet.example', 'HASH_DEMO_USUARIO_05', 2500.00, 3);

INSERT INTO transaccion
    (sender_user_id, receiver_user_id, currency_id, importe, transaction_date)
VALUES
    (1, 2, 1, 50000.00, '2026-07-15 10:30:00'),
    (2, 1, 1, 25000.00, '2026-07-16 12:15:00'),
    (1, 2, 1, 100000.00, '2026-07-17 18:45:00'),
    (3, 4, 2, 300.00, '2026-07-18 09:20:00'),
    (4, 3, 2, 150.00, '2026-07-19 16:10:00'),
    (2, 1, 1, 35000.00, '2026-07-20 20:30:00');

-- Consultar los usuarios junto con su moneda.
SELECT
    u.user_id,
    u.nombre,
    u.correo_electronico,
    u.saldo,
    m.currency_name AS moneda,
    m.currency_symbol AS simbolo
FROM usuario AS u
INNER JOIN moneda AS m
    ON u.currency_id = m.currency_id
ORDER BY u.user_id;

-- Consultar las transferencias con emisor, receptor y moneda.
SELECT
    t.transaction_id,
    emisor.nombre AS usuario_emisor,
    receptor.nombre AS usuario_receptor,
    t.importe,
    m.currency_symbol AS moneda,
    t.transaction_date
FROM transaccion AS t
INNER JOIN usuario AS emisor
    ON t.sender_user_id = emisor.user_id
INNER JOIN usuario AS receptor
    ON t.receiver_user_id = receptor.user_id
INNER JOIN moneda AS m
    ON t.currency_id = m.currency_id
ORDER BY t.transaction_date DESC;

-- Ejemplos DML
UPDATE usuario
SET correo_electronico = 'martin.lopez@alkewallet.example'
WHERE user_id = 5;

DELETE FROM transaccion
WHERE transaction_id = 6;

-- Transferencia confirmada con COMMIT.
START TRANSACTION;

UPDATE usuario
SET saldo = saldo - 20000.00
WHERE user_id = 1
  AND saldo >= 20000.00;

UPDATE usuario
SET saldo = saldo + 20000.00
WHERE user_id = 2;

INSERT INTO transaccion
    (sender_user_id, receiver_user_id, currency_id, importe)
VALUES
    (1, 2, 1, 20000.00);

COMMIT;

-- Comprobar los saldos resultantes.
SELECT user_id, nombre, saldo
FROM usuario
WHERE user_id IN (1, 2);

-- Demostración de ROLLBACK.
START TRANSACTION;

UPDATE usuario
SET saldo = saldo - 100000.00
WHERE user_id = 1;

ROLLBACK;

-- El saldo permanece igual porque la operación fue revertida.
SELECT user_id, nombre, saldo
FROM usuario
WHERE user_id = 1;
