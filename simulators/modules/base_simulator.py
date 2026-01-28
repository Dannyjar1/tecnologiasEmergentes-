import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import json
import time
import threading
import random
from datetime import datetime

class BaseSimulator(threading.Thread):
    def __init__(self, device_id, topic_suffix, interval=5, broker="localhost", port=1883):
        super().__init__()
        self.device_id = device_id
        self.interval = interval
        self.broker = broker
        self.port = port
        self.topic = f"campus/{device_id}/{topic_suffix}"
        self.running = False
        self.client = None
        self.connected = False  # Track connection status
        self.daemon = True  # Daemon thread stops when main program stops

    def run(self):
        self.running = True
        self._connect_mqtt()
        print(f"🚀 [{self.device_id}] Simulator started. Publishing to {self.topic}")
        
        while self.running:
            try:
                if not self.connected:
                    print(f"⚠️ [{self.device_id}] Reconnecting...")
                    self._connect_mqtt()
                
                # Only publish if connected
                if self.connected:
                    payload = self._generate_payload()
                    result = self.client.publish(self.topic, json.dumps(payload), qos=1)
                    result.wait_for_publish()  # Wait for message to be sent
                    
                    # Log only occasionally or on first publish to avoid console spam
                    print(f"📤 [{self.device_id}] Published data to {self.topic}") 
                
            except Exception as e:
                print(f"❌ [{self.device_id}] Error: {e}")
                self.connected = False
            
            time.sleep(self.interval)

        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
            print(f"🛑 [{self.device_id}] Stopped.")

    def stop(self):
        self.running = False
        print(f"🛑 [{self.device_id}] Stopping...")

    def _connect_mqtt(self):
        try:
            self.connected = False
            self.client = mqtt.Client(CallbackAPIVersion.VERSION2, client_id=f"sim_{self.device_id}")
            
            # Set up callbacks
            def on_connect(client, userdata, flags, rc, properties):
                if rc == 0:
                    self.connected = True
                else:
                    print(f"❌ [{self.device_id}] Connection failed with code {rc}")
            
            def on_disconnect(client, userdata, disconnect_flags, rc, properties):
                self.connected = False
            
            self.client.on_connect = on_connect
            self.client.on_disconnect = on_disconnect
            
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
            
            # Wait up to 5 seconds for connection
            wait_time = 0
            while not self.connected and wait_time < 5:
                time.sleep(0.1)
                wait_time += 0.1
                
            if not self.connected:
                print(f"❌ [{self.device_id}] Connection timeout")
        except Exception as e:
            print(f"❌ [{self.device_id}] MQTT Connection Failed: {e}")
            self.connected = False


    def _generate_payload(self):
        # Override this in child classes
        return {}
