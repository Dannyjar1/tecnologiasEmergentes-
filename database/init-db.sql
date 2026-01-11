-- Crear extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla: devices
CREATE TABLE devices (
  device_id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,  -- 'temperature', 'occupancy', 'humidity', etc.
  location VARCHAR(255),
  building VARCHAR(100),
  floor INTEGER,
  protocol VARCHAR(20) NOT NULL,  -- 'mqtt', 'http'
  status VARCHAR(20) DEFAULT 'active',  -- 'active', 'inactive', 'maintenance'
  api_key VARCHAR(64) UNIQUE,  -- Para autenticación de dispositivos HTTP
  metadata JSONB,  -- Información adicional flexible
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_seen TIMESTAMP
);

-- Índices
CREATE INDEX idx_devices_type ON devices(type);
CREATE INDEX idx_devices_location ON devices(location);
CREATE INDEX idx_devices_status ON devices(status);

-- Tabla: telemetry
CREATE TABLE telemetry (
  id BIGSERIAL PRIMARY KEY,
  device_id VARCHAR(50) NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
  metric VARCHAR(50) NOT NULL,  -- 'temperature', 'occupancy', 'humidity'
  value NUMERIC(10, 2) NOT NULL,
  unit VARCHAR(20),  -- 'celsius', 'percent', 'persons'
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB,  -- battery, signal, etc.
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices críticos para consultas de series temporales
CREATE INDEX idx_telemetry_device_metric ON telemetry(device_id, metric);
CREATE INDEX idx_telemetry_timestamp ON telemetry(timestamp DESC);
CREATE INDEX idx_telemetry_device_timestamp ON telemetry(device_id, timestamp DESC);

-- Tabla: rules
CREATE TABLE rules (
  rule_id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  condition JSONB NOT NULL,  -- Condición compleja en JSON
  action JSONB NOT NULL,  -- Acción a ejecutar
  severity VARCHAR(20) DEFAULT 'info',  -- 'info', 'warning', 'critical'
  enabled BOOLEAN DEFAULT true,
  triggered_count INTEGER DEFAULT 0,
  last_triggered TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rules_enabled ON rules(enabled);

-- Tabla: alerts
CREATE TABLE alerts (
  alert_id VARCHAR(50) PRIMARY KEY,
  rule_id VARCHAR(50) REFERENCES rules(rule_id) ON DELETE SET NULL,
  device_id VARCHAR(50) REFERENCES devices(device_id) ON DELETE CASCADE,
  metric VARCHAR(50),
  severity VARCHAR(20) NOT NULL,  -- 'info', 'warning', 'critical'
  message TEXT NOT NULL,
  value NUMERIC(10, 2),
  threshold NUMERIC(10, 2),
  status VARCHAR(20) DEFAULT 'active',  -- 'active', 'acknowledged', 'closed'
  acknowledged_by VARCHAR(100),
  acknowledged_at TIMESTAMP,
  notes TEXT,
  timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_device ON alerts(device_id);
CREATE INDEX idx_alerts_timestamp ON alerts(timestamp DESC);

-- Tabla: users
CREATE TABLE users (
  user_id VARCHAR(50) PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,  -- Bcrypt hash
  full_name VARCHAR(255),
  role VARCHAR(20) DEFAULT 'viewer',  -- 'admin', 'operator', 'viewer'
  active BOOLEAN DEFAULT true,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Vista: Últimas lecturas por dispositivo
CREATE VIEW latest_telemetry AS
SELECT DISTINCT ON (device_id, metric)
  device_id,
  metric,
  value,
  unit,
  timestamp
FROM telemetry
ORDER BY device_id, metric, timestamp DESC;

-- Vista: Dashboard de alertas activas
CREATE VIEW active_alerts_summary AS
SELECT 
  a.severity,
  COUNT(*) as count,
  MAX(a.timestamp) as latest_alert
FROM alerts a
WHERE a.status = 'active'
GROUP BY a.severity;

-- Insertar datos de prueba
INSERT INTO devices (device_id, name, type, location, building, floor, protocol, api_key) 
VALUES (
  'lab-01-temp',
  'Sensor Temperatura Lab 01',
  'temperature',
  'Laboratorio 01',
  'Edificio A',
  2,
  'mqtt',
  'sk_a1b2c3d4e5f6'
);

INSERT INTO rules (rule_id, name, condition, action, severity) 
VALUES (
  'rule-temp-high-lab01',
  'Temperatura Alta Lab 01',
  '{
    "deviceId": "lab-01-temp",
    "metric": "temperature",
    "operator": ">",
    "threshold": 30
  }'::jsonb,
  '{
    "type": "alert",
    "notification": {
      "email": "admin@universidad.edu",
      "message": "Temperatura excede límite"
    }
  }'::jsonb,
  'warning'
);

INSERT INTO users (user_id, email, password_hash, full_name, role) 
VALUES (
  'user-e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
  'admin@universidad.edu',
  '$2b$10$E.qFS5VvV.Nl3YwzJj3/B.A.5.TkB5C.xGzXjA2B.C/e.A.2.C.0m',
  'Admin',
  'admin'
);

SELECT 'Database initialized successfully' AS status;