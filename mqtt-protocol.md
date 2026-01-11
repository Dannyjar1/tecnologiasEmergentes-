# Especificación del Protocolo MQTT - Plataforma IoT Campus

## Configuración del Broker

### Mosquitto
- **Host:** localhost (desarrollo) / mqtt.campus.edu (producción)
- **Puerto:** 1883 (sin TLS) / 8883 (con TLS)
- **Autenticación:** Sin credenciales (v1) / Usuario/contraseña (v2)
- **QoS Recomendado:** QoS 1 (entrega al menos una vez)

---

## Estructura de Topics

### Convención de Nombres
```
campus/{deviceId}/{metric}
```

**Componentes:**
- `campus`: Prefijo raíz de la institución
- `{deviceId}`: Identificador único del dispositivo (e.g., `lab-01-temp`)
- `{metric}`: Tipo de métrica (e.g., `temperature`, `occupancy`, `humidity`)

### Topics Definidos

#### 1. Telemetría de Dispositivos
```
campus/+/+
```
Suscripción con wildcards para recibir todas las métricas de todos los dispositivos.

**Ejemplos:**
- `campus/lab-01-temp/temperature`
- `campus/aula-201-occ/occupancy`
- `campus/parking-a/available_spots`
- `campus/lab-02-hum/humidity`

---

#### 2. Alertas del Sistema
```
campus/alerts
```
Topic donde el backend publica alertas generadas por el motor de reglas.

---

#### 3. Comandos a Dispositivos (Futuro)
```
campus/commands/{deviceId}
```
Para enviar comandos de control a actuadores (apagar luces, ajustar temperatura, etc.).

---

## Formato de Mensajes (Payload)

### Telemetría - Mensaje Estándar

**Topic:** `campus/lab-01-temp/temperature`

**Payload JSON:**
```json
{
  "value": 28.5,
  "unit": "celsius",
  "timestamp": "2025-11-26T10:30:00Z",
  "metadata": {
    "battery": 85,
    "signal": -45
  }
}
```

**Campos:**
- `value` (required): Valor de la métrica (número o booleano)
- `unit` (optional): Unidad de medida
- `timestamp` (required): Marca de tiempo ISO 8601
- `metadata` (optional): Información adicional del dispositivo

---

### Alertas - Mensaje del Sistema

**Topic:** `campus/alerts`

**Payload JSON:**
```json
{
  "alertId": "alert-456",
  "ruleId": "rule-789",
  "deviceId": "lab-01-temp",
  "metric": "temperature",
  "severity": "warning",
  "message": "Temperatura excede límite permitido en Lab 01",
  "value": 32.5,
  "threshold": 30,
  "timestamp": "2025-11-26T10:30:00Z"
}
```

---

### Comandos - Mensaje de Control (Futuro)

**Topic:** `campus/commands/lab-01-ac`

**Payload JSON:**
```json
{
  "action": "set_temperature",
  "parameters": {
    "target": 22,
    "mode": "cool"
  },
  "requestId": "cmd-123",
  "timestamp": "2025-11-26T10:35:00Z"
}
```

---

## Implementación en Backend (Node.js)

### Cliente MQTT Suscriptor
```javascript
const mqtt = require('mqtt');

// Conectar al broker
const client = mqtt.connect('mqtt://localhost:1883', {
  clientId: 'campus-iot-backend',
  clean: true,
  reconnectPeriod: 1000
});

// Evento: Conexión exitosa
client.on('connect', () => {
  console.log('✅ Conectado a Mosquitto');
  
  // Suscribirse a todos los dispositivos
  client.subscribe('campus/+/+', { qos: 1 }, (err) => {
    if (!err) {
      console.log('📡 Suscrito a campus/+/+');
    }
  });
  
  // Suscribirse a alertas
  client.subscribe('campus/alerts', { qos: 1 });
});

// Evento: Mensaje recibido
client.on('message', async (topic, message) => {
  try {
    // Parsear topic
    const parts = topic.split('/');
    const [prefix, deviceId, metric] = parts;
    
    // Parsear payload
    const payload = JSON.parse(message.toString());
    
    console.log(`📊 [${deviceId}] ${metric}: ${payload.value}`);
    
    // Guardar en base de datos
    await saveTelemetry({
      deviceId,
      metric,
      value: payload.value,
      timestamp: payload.timestamp,
      unit: payload.unit
    });
    
    // Evaluar reglas
    await evaluateRules(deviceId, metric, payload.value);
    
  } catch (error) {
    console.error('❌ Error procesando mensaje:', error);
  }
});

// Evento: Error de conexión
client.on('error', (error) => {
  console.error('❌ Error MQTT:', error);
});

// Evento: Reconexión
client.on('reconnect', () => {
  console.log('🔄 Reconectando a Mosquitto...');
});
```

---

## Simulador de Dispositivo (Python)

### Sensor de Temperatura
```python
import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

# Configuración
BROKER = "localhost"
PORT = 1883
DEVICE_ID = "lab-01-temp"
TOPIC = f"campus/{DEVICE_ID}/temperature"

# Crear cliente
client = mqtt.Client(client_id=DEVICE_ID)

# Conectar
client.connect(BROKER, PORT)
client.loop_start()

print(f"🌡️  Simulador iniciado: {DEVICE_ID}")

try:
    while True:
        # Generar temperatura aleatoria (20-35°C)
        temperature = round(random.uniform(20, 35), 2)
        
        # Crear payload
        payload = {
            "value": temperature,
            "unit": "celsius",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "metadata": {
                "battery": random.randint(70, 100),
                "signal": random.randint(-60, -30)
            }
        }
        
        # Publicar
        client.publish(TOPIC, json.dumps(payload), qos=1)
        print(f"📤 Publicado: {temperature}°C")
        
        # Esperar 5 segundos
        time.sleep(5)
        
except KeyboardInterrupt:
    print("\n⛔ Simulador detenido")
    client.loop_stop()
    client.disconnect()
```

---

### Sensor de Ocupación (con horarios realistas)
```python
import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime

BROKER = "localhost"
PORT = 1883
DEVICE_ID = "aula-201-occ"
TOPIC = f"campus/{DEVICE_ID}/occupancy"

client = mqtt.Client(client_id=DEVICE_ID)
client.connect(BROKER, PORT)
client.loop_start()

def get_realistic_occupancy():
    """Retorna ocupación según la hora del día"""
    hour = datetime.now().hour
    
    # Horario de clases: 7am - 10pm
    if 7 <= hour < 12:
        return random.randint(20, 45)  # Mañana: alta ocupación
    elif 12 <= hour < 14:
        return random.randint(5, 15)   # Almuerzo: baja
    elif 14 <= hour < 18:
        return random.randint(25, 40)  # Tarde: alta
    elif 18 <= hour < 22:
        return random.randint(10, 25)  # Noche: media
    else:
        return 0  # Fuera de horario

try:
    while True:
        occupancy = get_realistic_occupancy()
        
        payload = {
            "value": occupancy,
            "unit": "persons",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        client.publish(TOPIC, json.dumps(payload), qos=1)
        print(f"📤 Ocupación: {occupancy} personas")
        
        time.sleep(10)
        
except KeyboardInterrupt:
    client.loop_stop()
    client.disconnect()
```

---

## Docker Compose - Mosquitto
```yaml
version: '3.8'

services:
  mosquitto:
    image: eclipse-mosquitto:2.0
    container_name: campus-mqtt-broker
    ports:
      - "1883:1883"  # MQTT sin TLS
      - "9001:9001"  # WebSocket (opcional)
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
    restart: unless-stopped
```

### Configuración Mosquitto (`mosquitto/config/mosquitto.conf`)
```conf
# Permitir conexiones anónimas (desarrollo)
allow_anonymous true

# Escuchar en puerto 1883
listener 1883

# Persistencia de mensajes
persistence true
persistence_location /mosquitto/data/

# Logs
log_dest file /mosquitto/log/mosquitto.log
log_type all
```

---

## Herramientas de Prueba

### 1. Mosquitto CLI (Publicar)
```bash
mosquitto_pub -h localhost -t "campus/test-device/temperature" \
  -m '{"value": 25.5, "timestamp": "2025-11-26T10:30:00Z"}'
```

### 2. Mosquitto CLI (Suscribirse)
```bash
mosquitto_sub -h localhost -t "campus/#" -v
```

### 3. MQTT Explorer (GUI)
- Descargar: https://mqtt-explorer.com/
- Conectar a `localhost:1883`
- Ver topics en tiempo real

---

## Consideraciones de Seguridad

### Versión Actual (Desarrollo)
- ✅ Sin autenticación
- ✅ Sin cifrado (puerto 1883)
- ⚠️ Solo para entorno local

### Versión Futura (Producción)
- 🔒 Autenticación usuario/contraseña
- 🔒 TLS/SSL (puerto 8883)
- 🔒 ACL (Access Control Lists) por dispositivo
- 🔒 Certificados cliente para dispositivos críticos

---

## QoS (Quality of Service)

| Nivel | Descripción | Uso Recomendado |
|-------|-------------|-----------------|
| QoS 0 | Fire and forget | Telemetría no crítica |
| QoS 1 | Al menos una entrega | **Telemetría estándar** ✅ |
| QoS 2 | Exactamente una entrega | Comandos críticos |

**Recomendación:** Usar QoS 1 para balance entre confiabilidad y rendimiento.