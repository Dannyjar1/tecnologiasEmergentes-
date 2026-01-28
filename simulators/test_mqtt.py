import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import json
import time

# Configuration
BROKER = "localhost"
PORT = 1883
TEST_TOPIC = "test/connection"

def on_connect(client, userdata, flags, rc, properties):
    print(f"Connection result: {rc}")
    if rc == 0:
        print("✅ SUCCESS: Connected to broker")
    else:
        print(f"❌ FAILED: Connection error code {rc}")

def on_publish(client, userdata, mid, rc, properties):
    print(f"✅ Message {mid} published successfully")

# Create client
print("Creating MQTT client...")
client = mqtt.Client(CallbackAPIVersion.VERSION2, client_id="test-client")
client.on_connect = on_connect
client.on_publish = on_publish

# Connect
print(f"Connecting to {BROKER}:{PORT}...")
try:
    client.connect(BROKER, PORT, 60)
    client.loop_start()
    time.sleep(2)
    
    # Publish test message
    print("Publishing test message...")
    result = client.publish(TEST_TOPIC, json.dumps({"test": "message"}), qos=1)
    print(f"Publish result code: {result.rc}")
    result.wait_for_publish()
    
    print("Waiting 3 seconds...")
    time.sleep(3)
    
except Exception as e:
    print(f"❌ Error: {e}")
finally:
    client.loop_stop()
    client.disconnect()
    print("Test complete")
