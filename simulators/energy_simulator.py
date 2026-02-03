import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import json
import time
import random
from datetime import datetime

# Configuration
BROKER = "68.183.174.210"     # IP pública del VPS (o mqtt.uidehub.tech)
PORT = 1883
MQTT_USER = "mqtt_user"       # el usuario real creado en mosquitto_passwd
MQTT_PASS = "mysecretpws"     # tu clave real
DEVICE_ID = "lab-01-energy"
TOPIC = f"campus/{DEVICE_ID}/power"

def get_realistic_power():
    """Returns power consumption based on time of day (kW)"""
    hour = datetime.now().hour
    
    # Simulate lab equipment power consumption patterns
    if 7 <= hour < 9:
        return round(random.uniform(2.5, 4.0), 2)   # Morning startup
    elif 9 <= hour < 12:
        return round(random.uniform(4.0, 6.5), 2)   # Peak usage (classes)
    elif 12 <= hour < 14:
        return round(random.uniform(3.0, 4.5), 2)   # Lunch (reduced)
    elif 14 <= hour < 18:
        return round(random.uniform(4.5, 7.0), 2)   # Afternoon peak
    elif 18 <= hour < 22:
        return round(random.uniform(2.0, 3.5), 2)   # Evening (cleanup)
    else:
        return round(random.uniform(0.5, 1.5), 2)   # Night (base load: AC, servers)

# Connection callback
def on_connect(client, userdata, flags, rc, properties):
    if rc == 0:
        print(f"✅ Connected to MQTT Broker at {BROKER}:{PORT}")
    else:
        print(f"❌ Failed to connect, return code {rc}")

# Publish callback
def on_publish(client, userdata, mid, rc, properties):
    print(f"✅ Message {mid} confirmed by broker")

# Create MQTT client
client = mqtt.Client(CallbackAPIVersion.VERSION2, client_id=DEVICE_ID)
client.on_connect = on_connect
client.on_publish = on_publish

client.username_pw_set(MQTT_USER, MQTT_PASS)

# Connect to broker
print(f"🔌 Connecting to MQTT broker at {BROKER}:{PORT}...")
client.connect(BROKER, PORT, 60)
client.loop_start()

# Wait for connection
time.sleep(2)

print(f"⚡ Energy Simulator started: {DEVICE_ID}")
print(f"📡 Publishing to topic: {TOPIC}\n")

try:
    while True:
        power = get_realistic_power()

        payload = {
            "value": power,
            "unit": "kW",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "metadata": {
                "voltage": round(random.uniform(220, 230), 1),
                "frequency": round(random.uniform(59.8, 60.2), 1)
            }
        }

        # Publish via MQTT
        result = client.publish(TOPIC, json.dumps(payload), qos=1)
        result.wait_for_publish()
        print(f"📤 Published: {power} kW")

        # Wait 5 seconds
        time.sleep(5)

except KeyboardInterrupt:
    print("\n🛑 Simulator stopped")
    client.loop_stop()
    client.disconnect()
