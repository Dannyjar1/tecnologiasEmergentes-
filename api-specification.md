# Especificación de API REST - Plataforma IoT Campus

## Base URL
```
http://localhost:3000/api
```

## Autenticación
- **Versión actual:** Sin autenticación (desarrollo)
- **Versión futura:** JWT Bearer Token + API Keys para dispositivos

---

## Endpoints Implementados

### 1. Dispositivos

#### POST /api/devices
Registrar nuevo dispositivo en el sistema.

**Request Body:**
```json
{
  "deviceId": "lab-01-temp",
  "name": "Sensor Temperatura Lab 01",
  "type": "temperature",
  "location": "Laboratorio 01",
  "protocol": "mqtt",
  "metadata": {
    "building": "Edificio A",
    "floor": 2
  }
}
```

**Response 201 Created:**
```json
{
  "deviceId": "lab-01-temp",
  "name": "Sensor Temperatura Lab 01",
  "type": "temperature",
  "location": "Laboratorio 01",
  "protocol": "mqtt",
  "status": "active",
  "createdAt": "2025-11-26T10:30:00Z",
  "metadata": {
    "building": "Edificio A",
    "floor": 2
  }
}
```

**Response 400 Bad Request:**
```json
{
  "error": "Missing required fields: deviceId, name, type"
}
```

---

#### GET /api/devices
Listar todos los dispositivos registrados.

**Query Parameters:**
- `status` (optional): `active` | `inactive`
- `type` (optional): `temperature` | `occupancy` | `humidity` | etc.
- `location` (optional): Filtrar por ubicación

**Response 200 OK:**
```json
[
  {
    "deviceId": "lab-01-temp",
    "name": "Sensor Temperatura Lab 01",
    "type": "temperature",
    "location": "Laboratorio 01",
    "status": "active",
    "lastSeen": "2025-11-26T10:30:00Z",
    "protocol": "mqtt"
  },
  {
    "deviceId": "aula-201-occ",
    "name": "Sensor Ocupación Aula 201",
    "type": "occupancy",
    "location": "Aula 201",
    "status": "active",
    "lastSeen": "2025-11-26T10:28:00Z",
    "protocol": "http"
  }
]
```

---

#### GET /api/devices/:deviceId
Obtener detalles de un dispositivo específico.

**Response 200 OK:**
```json
{
  "deviceId": "lab-01-temp",
  "name": "Sensor Temperatura Lab 01",
  "type": "temperature",
  "location": "Laboratorio 01",
  "status": "active",
  "protocol": "mqtt",
  "createdAt": "2025-11-26T09:00:00Z",
  "lastSeen": "2025-11-26T10:30:00Z",
  "metadata": {
    "building": "Edificio A",
    "floor": 2
  }
}
```

**Response 404 Not Found:**
```json
{
  "error": "Device not found"
}
```

---

#### PATCH /api/devices/:deviceId
Actualizar información de un dispositivo.

**Request Body:**
```json
{
  "name": "Sensor Temperatura Lab 01 (Actualizado)",
  "status": "inactive"
}
```

**Response 200 OK:**
```json
{
  "deviceId": "lab-01-temp",
  "name": "Sensor Temperatura Lab 01 (Actualizado)",
  "status": "inactive",
  "updatedAt": "2025-11-26T10:35:00Z"
}
```

---

#### DELETE /api/devices/:deviceId
Eliminar dispositivo (baja lógica).

**Response 204 No Content**

---

## Endpoints Pendientes de Implementar

### 2. Telemetría

#### POST /api/telemetry
Recibir datos de telemetría vía HTTP.

**Request Body:**
```json
{
  "deviceId": "lab-01-temp",
  "metric": "temperature",
  "value": 28.5,
  "unit": "celsius",
  "timestamp": "2025-11-26T10:30:00Z"
}
```

**Response 201 Created:**
```json
{
  "id": "tel-123456",
  "deviceId": "lab-01-temp",
  "metric": "temperature",
  "value": 28.5,
  "timestamp": "2025-11-26T10:30:00Z",
  "processed": true
}
```

---

#### GET /api/telemetry
Consultar histórico de telemetría.

**Query Parameters:**
- `deviceId` (required): ID del dispositivo
- `metric` (optional): Tipo de métrica
- `startDate` (optional): ISO 8601 date
- `endDate` (optional): ISO 8601 date
- `limit` (optional): Número de registros (default: 100)

**Response 200 OK:**
```json
{
  "deviceId": "lab-01-temp",
  "metric": "temperature",
  "data": [
    {
      "timestamp": "2025-11-26T10:30:00Z",
      "value": 28.5
    },
    {
      "timestamp": "2025-11-26T10:25:00Z",
      "value": 27.8
    }
  ],
  "count": 2
}
```

---

### 3. Reglas

#### POST /api/rules
Crear nueva regla de alerta.

**Request Body:**
```json
{
  "name": "Temperatura Alta Lab 01",
  "condition": {
    "deviceId": "lab-01-temp",
    "metric": "temperature",
    "operator": ">",
    "threshold": 30
  },
  "action": {
    "type": "alert",
    "severity": "warning",
    "notification": {
      "email": "admin@universidad.edu",
      "message": "Temperatura excede límite permitido"
    }
  },
  "enabled": true
}
```

**Response 201 Created:**
```json
{
  "ruleId": "rule-789",
  "name": "Temperatura Alta Lab 01",
  "condition": { ... },
  "action": { ... },
  "enabled": true,
  "createdAt": "2025-11-26T10:40:00Z"
}
```

---

#### GET /api/rules
Listar todas las reglas.

**Response 200 OK:**
```json
[
  {
    "ruleId": "rule-789",
    "name": "Temperatura Alta Lab 01",
    "enabled": true,
    "triggeredCount": 5,
    "lastTriggered": "2025-11-26T10:30:00Z"
  }
]
```

---

#### DELETE /api/rules/:ruleId
Eliminar regla.

**Response 204 No Content**

---

### 4. Alertas

#### GET /api/alerts
Listar alertas generadas.

**Query Parameters:**
- `status` (optional): `active` | `acknowledged` | `closed`
- `severity` (optional): `info` | `warning` | `critical`
- `startDate` (optional): ISO 8601 date
- `endDate` (optional): ISO 8601 date

**Response 200 OK:**
```json
[
  {
    "alertId": "alert-456",
    "ruleId": "rule-789",
    "deviceId": "lab-01-temp",
    "severity": "warning",
    "message": "Temperatura excede límite permitido",
    "value": 32.5,
    "timestamp": "2025-11-26T10:30:00Z",
    "status": "active"
  }
]
```

---

#### PATCH /api/alerts/:alertId
Actualizar estado de alerta.

**Request Body:**
```json
{
  "status": "acknowledged",
  "acknowledgedBy": "admin@universidad.edu",
  "notes": "En revisión por equipo de mantenimiento"
}
```

**Response 200 OK:**
```json
{
  "alertId": "alert-456",
  "status": "acknowledged",
  "acknowledgedAt": "2025-11-26T10:45:00Z"
}
```

---

## Códigos de Estado HTTP

| Código | Significado |
|--------|-------------|
| 200 | OK - Solicitud exitosa |
| 201 | Created - Recurso creado |
| 204 | No Content - Eliminación exitosa |
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - Autenticación requerida |
| 404 | Not Found - Recurso no encontrado |
| 500 | Internal Server Error - Error del servidor |

---

## Notas de Implementación

### Validaciones Requeridas
- `deviceId`: alfanumérico, guiones permitidos, 3-50 caracteres
- `type`: valores predefinidos
- `value`: numérico para métricas cuantitativas
- `timestamp`: formato ISO 8601

### Rate Limiting (Futura implementación)
- Dispositivos: 100 requests/minuto
- Usuarios: 1000 requests/hora

### Versionado
- Versión actual: v1
- URL futura: `/api/v1/...`