import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime
import random

BROKER = "localhost"
PORT = 1883
DEVICE_ID = "aula-201-occ"
TOPIC = f"campus/{DEVICE_ID}/occupancy"

client = mqtt.Client(client_id=DEVICE_ID)
client.connect(BROKER, PORT)
client.loop_start()

def get_realistic_occupancy():
    """Returns occupancy based on the time of day"""
    hour = datetime.now().hour

    # Class schedule: 7am - 10pm
    if 7 <= hour < 12:
        return random.randint(20, 45)  # Morning: high occupancy
    elif 12 <= hour < 14:
        return random.randint(5, 15)   # Lunch: low
    elif 14 <= hour < 18:
        return random.randint(25, 40)  # Afternoon: high
    elif 18 <= hour < 22:
        return random.randint(10, 25)  # Night: medium
    else:
        return 0  # Off hours

try:
    print(f"👨‍👩‍👧‍👦 Simulator started: {DEVICE_ID}")
    while True:
        occupancy = get_realistic_occupancy()

        payload = {
            "value": occupancy,
            "unit": "persons",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }

        client.publish(TOPIC, json.dumps(payload), qos=1)
        print(f"📤 Published: {occupancy} persons")

        time.sleep(10)

except KeyboardInterrupt:
    print("\n🛑 Simulator stopped")
    client.loop_stop()
    client.disconnect()
