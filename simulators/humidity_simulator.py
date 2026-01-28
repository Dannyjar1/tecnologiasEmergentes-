import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import json
import time
import random
from datetime import datetime

# Configuration
BROKER = "localhost"
PORT = 1883
DEVICE_ID = "lab-01-humidity"
TOPIC = f"campus/{DEVICE_ID}/humidity"

def get_realistic_humidity():
    """Returns humidity level based on time of day and weather simulation"""
    hour = datetime.now().hour
    
    # Simulate indoor humidity variations
    if 6 <= hour < 9:
        return round(random.uniform(55, 65), 1)  # Morning (higher)
    elif 9 <= hour < 12:
        return round(random.uniform(45, 55), 1)  # Mid-morning (AC kicks in)
    elif 12 <= hour < 15:
        return round(random.uniform(40, 50), 1)  # Afternoon (lowest)
    elif 15 <= hour < 18:
        return round(random.uniform(45, 55), 1)  # Late afternoon
    elif 18 <= hour < 22:
        return round(random.uniform(50, 60), 1)  # Evening (rising)
    else:
        return round(random.uniform(55, 70), 1)  # Night (highest, no AC)

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

print(f"💧 Humidity Simulator started: {DEVICE_ID}")
print(f"📡 Publishing to topic: {TOPIC}\n")

try:
    while True:
        humidity = get_realistic_humidity()

        payload = {
            "value": humidity,
            "unit": "%",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "metadata": {
                "battery": random.randint(70, 100),
                "signal": random.randint(-60, -30)
            }
        }

        # Publish via MQTT
        result = client.publish(TOPIC, json.dumps(payload), qos=1)
        result.wait_for_publish()
        print(f"📤 Published: {humidity}%")

        # Wait 5 seconds
        time.sleep(5)

except KeyboardInterrupt:
    print("\n🛑 Simulator stopped")
    client.loop_stop()
    client.disconnect()
