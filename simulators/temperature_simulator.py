import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

# Configuration
BROKER = "localhost"
PORT = 1883
DEVICE_ID = "lab-01-temp"
TOPIC = f"campus/{DEVICE_ID}/temperature"

# Create client
client = mqtt.Client(client_id=DEVICE_ID)

# Connect
client.connect(BROKER, PORT)
client.loop_start()

print(f"🌡️  Simulator started: {DEVICE_ID}")

try:
    while True:
        # Generate random temperature (20-35°C)
        temperature = round(random.uniform(20, 35), 2)

        # Create payload
        payload = {
            "value": temperature,
            "unit": "celsius",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "metadata": {
                "battery": random.randint(70, 100),
                "signal": random.randint(-60, -30)
            }
        }

        # Publish
        client.publish(TOPIC, json.dumps(payload), qos=1)
        print(f"📤 Published: {temperature}°C")

        # Wait 5 seconds
        time.sleep(5)

except KeyboardInterrupt:
    print("\n🛑 Simulator stopped")
    client.loop_stop()
    client.disconnect()
