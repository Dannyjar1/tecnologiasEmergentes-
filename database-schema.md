# Esquema de Base de Datos - Plataforma IoT Campus

## Motor de Base de Datos
- **PostgreSQL 15** (desarrollo y producción)
- **Extensión TimescaleDB** (opcional, para optimizar series temporales)

---

## Diagrama Entidad-Relación
```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   devices   │────────<│  telemetry   │>────────│    rules    │
└─────────────┘         └──────────────┘         └─────────────┘
      │                                                  │
      │                                                  │
      │                                                  ▼
      │                                           ┌─────────────┐
      │                                           │   alerts    │
      │                                           └─────────────┘
      ▼
┌─────────────┐
│    users    │
└─────────────┘
```

---

## Tabla: `devices`

Almacena información de todos los dispositivos IoT registrados.
```sql
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
```

**Ejemplo de registro:**
```sql
INSERT INTO devices (device_id, name, type, location, building, floor, protocol, api_key) 
VALUES (
  'lab-01-temp',
  'Sensor Temperatura Lab 01',
  'temperature',
  'Laboratorio 01',
  'Edificio A',
  2,
  'mqtt',
  'sk_a1b2c3d4e5f6...'
);
```

---

## Tabla: `telemetry`

Almacena las lecturas de telemetría (serie temporal).
```sql
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

-- Opcional: Convertir a hypertable con TimescaleDB
-- SELECT create_hypertable('telemetry', 'timestamp');
```

**Ejemplo de registro:**
```sql
INSERT INTO telemetry (device_id, metric, value, unit, timestamp) 
VALUES (
  'lab-01-temp',
  'temperature',
  28.5,
  'celsius',
  '2025-11-26 10:30:00'
);
```

---

## Tabla: `rules`

Define reglas de evaluación para generar alertas.
```sql
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
```

**Ejemplo de registro:**
```sql
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
```

---

## Tabla: `alerts`

Almacena alertas generadas por el motor de reglas.
```sql
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
```

**Ejemplo de registro:**
```sql
INSERT INTO alerts (alert_id, rule_id, device_id, metric, severity, message, value, threshold, timestamp) 
VALUES (
  'alert-' || gen_random_uuid(),
  'rule-temp-high-lab01',
  'lab-01-temp',
  'temperature',
  'warning',
  'Temperatura excede límite permitido en Lab 01',
  32.5,
  30,
  CURRENT_TIMESTAMP
);
```

---

## Tabla: `users`

Usuarios del sistema (administradores del panel web).
```sql
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
```

**Ejemplo de registro:**
```sql
INSERT INTO users (user_id, email, password_hash, full_name, role) 
VALUES (
  'user-' || gen_random_uuid(),
  'admin@universidad.edu',

  ---

## Vistas Útiles

### Vista: Últimas lecturas por dispositivo
```sql
CREATE VIEW latest_telemetry AS
SELECT DISTINCT ON (device_id, metric)
  device_id,
  metric,
  value,
  unit,
  timestamp
FROM telemetry
ORDER BY device_id, metric, timestamp DESC;
```

### Vista: Dashboard de alertas activas
```sql
CREATE VIEW active_alerts_summary AS
SELECT 
  a.severity,
  COUNT(*) as count,
  MAX(a.timestamp) as latest_alert
FROM alerts a
WHERE a.status = 'active'
GROUP BY a.severity;
```

---

## Políticas de Retención (TimescaleDB)
```sql
-- Retener telemetría detallada por 30 días
SELECT add_retention_policy('telemetry', INTERVAL '30 days');

-- Agregar telemetría horaria y retener por 1 año
CREATE MATERIALIZED VIEW telemetry_hourly
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', timestamp) AS hour,
  device_id,
  metric,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value
FROM telemetry
GROUP BY hour, device_id, metric;

SELECT add_retention_policy('telemetry_hourly', INTERVAL '1 year');
```

---

## Script de Inicialización
```sql
-- init-db.sql

-- Crear extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Crear tablas en orden de dependencias
\i tables/devices.sql
\i tables/telemetry.sql
\i tables/rules.sql
\i tables/alerts.sql
\i tables/users.sql

-- Crear vistas
\i views/latest_telemetry.sql
\i views/active_alerts_summary.sql

-- Insertar datos de prueba
\i seeds/sample_devices.sql
\i seeds/sample_rules.sql
\i seeds/sample_users.sql

-- Confirmar
SELECT 'Database initialized successfully' AS status;
```

---

## Consultas Comunes

### 1. Telemetría reciente de un dispositivo
```sql
SELECT 
  timestamp,
  metric,
  value,
  unit
FROM telemetry
WHERE device_id = 'lab-01-temp'
  AND timestamp >= NOW() - INTERVAL '1 hour'
ORDER BY timestamp DESC;
```

### 2. Alertas activas con información de dispositivo
```sql
SELECT 
  a.alert_id,
  a.severity,
  a.message,
  a.timestamp,
  d.name as device_name,
  d.location
FROM alerts a
JOIN devices d ON a.device_id = d.device_id
WHERE a.status = 'active'
ORDER BY a.severity DESC, a.timestamp DESC;
```

### 3. Dispositivos sin actividad reciente
```sql
SELECT 
  device_id,
  name,
  location,
  last_seen,
  NOW() - last_seen as inactive_duration
FROM devices
WHERE last_seen < NOW() - INTERVAL '10 minutes'
  AND status = 'active';
```

### 4. Resumen de telemetría diaria
```sql
SELECT 
  DATE(timestamp) as date,
  device_id,
  metric,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value,
  COUNT(*) as reading_count
FROM telemetry
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(timestamp), device_id, metric
ORDER BY date DESC, device_id;
```

---

## Docker Compose - PostgreSQL
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: campus-iot-db
    environment:
      POSTGRES_DB: campus_iot
      POSTGRES_USER: campus_admin
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql
    restart: unless-stopped

volumes:
  postgres_data:
```

---

## Modelo de Datos (TypeScript/Node.js)
```typescript
// models/Device.ts
export interface Device {
  deviceId: string;
  name: string;
  type: string;
  location?: string;
  building?: string;
  floor?: number;
  protocol: 'mqtt' | 'http';
  status: 'active' | 'inactive' | 'maintenance';
  apiKey?: string;
  metadata?: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
  lastSeen?: Date;
}

// models/Telemetry.ts
export interface Telemetry {
  id: number;
  deviceId: string;
  metric: string;
  value: number;
  unit?: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

// models/Rule.ts
export interface Rule {
  ruleId: string;
  name: string;
  description?: string;
  condition: RuleCondition;
  action: RuleAction;
  severity: 'info' | 'warning' | 'critical';
  enabled: boolean;
  triggeredCount: number;
  lastTriggered?: Date;
}

export interface RuleCondition {
  deviceId?: string;
  metric: string;
  operator: '>' | '<' | '=' | '>=' | '<=';
  threshold: number;
  location?: string;
}

export interface RuleAction {
  type: 'alert' | 'log' | 'webhook';
  notification?: {
    email?: string;
    message: string;
  };
}

// models/Alert.ts
export interface Alert {
  alertId: string;
  ruleId?: string;
  deviceId: string;
  metric: string;
  severity: 'info' | 'warning' | 'critical';
  message: string;
  value: number;
  threshold?: number;
  status: 'active' | 'acknowledged' | 'closed';
  acknowledgedBy?: string;
  acknowledgedAt?: Date;
  notes?: string;
  timestamp: Date;
}
```