import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import json
import time
import random
from datetime import datetime

# Configuration  
BROKER = "localhost"  # Use localhost for local development
PORT = 1883
DEVICE_ID = "lab-01-temp"
TOPIC = f"campus/{DEVICE_ID}/temperature"

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

print(f"🌡️  Temperature Simulator started: {DEVICE_ID}")
print(f"📡 Publishing to topic: {TOPIC}\n")

try:
    while True:
        # Generate random temperature (20-35°C)
        temperature = round(random.uniform(20, 35), 2)

        # Create MQTT payload
        payload = {
            "value": temperature,
            "unit": "celsius",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "metadata": {
                "battery": random.randint(70, 100),
                "signal": random.randint(-60, -30)
            }
        }

        # Publish via MQTT
        result = client.publish(TOPIC, json.dumps(payload), qos=1)
        result.wait_for_publish()  
        print(f"📤 Published: {temperature}°C")

        # Wait 5 seconds
        time.sleep(5)

except KeyboardInterrupt:
    print("\n🛑 Simulator stopped")
    client.loop_stop()
    client.disconnect()
