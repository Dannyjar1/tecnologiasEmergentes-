import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import json
import time
import random
from datetime import datetime

# Configuration
BROKER = "localhost"  # Use localhost for local development
PORT = 1883
DEVICE_ID = "lab-01-light"
TOPIC = f"campus/{DEVICE_ID}/illumination"

def get_realistic_light():
    """Returns light level based on time of day"""
    hour = datetime.now().hour
    
    # Simulate natural and artificial lighting
    if 6 <= hour < 8:
        return random.randint(100, 300)   # Dawn
    elif 8 <= hour < 12:
        return random.randint(400, 800)   # Morning (windows + lights)
    elif 12 <= hour < 14:
        return random.randint(600, 1000)  # Noon (peak)
    elif 14 <= hour < 18:
        return random.randint(400, 700)   # Afternoon
    elif 18 <= hour < 20:
        return random.randint(200, 400)   # Evening (artificial lights)
    elif 20 <= hour < 22:
        return random.randint(100, 300)   # Night (reduced lighting)
    else:
        return random.randint(0, 50)      # Closed (security lights only)

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

# Connect to broker
print(f"🔌 Connecting to MQTT broker at {BROKER}:{PORT}...")
client.connect(BROKER, PORT, 60)
client.loop_start()

# Wait for connection
time.sleep(2)

print(f"💡 Lighting Simulator started: {DEVICE_ID}")
print(f"📡 Publishing to topic: {TOPIC}\n")

try:
    while True:
        light_level = get_realistic_light()

        payload = {
            "value": light_level,
            "unit": "lux",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "metadata": {
                "battery": random.randint(70, 100),
                "signal": random.randint(-60, -30)
            }
        }

        # Publish via MQTT
        result = client.publish(TOPIC, json.dumps(payload), qos=1)
        result.wait_for_publish()
        print(f"📤 Published: {light_level} lux")

        # Wait 5 seconds
        time.sleep(5)

except KeyboardInterrupt:
    print("\n🛑 Simulator stopped")
    client.loop_stop()
    client.disconnect()
