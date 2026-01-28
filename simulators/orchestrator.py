import requests
import time
import threading
from modules.temperature import TemperatureSimulator
from modules.occupancy import OccupancySimulator
from modules.light import LightSimulator
from modules.humidity import HumiditySimulator
from modules.energy import EnergySimulator

API_URL = "http://localhost:8080/api/devices"
POLL_INTERVAL = 10  # seconds

# Map device types to Simulator classes
SIMULATOR_MAP = {
    "temperature": TemperatureSimulator,
    "occupancy": OccupancySimulator,
    "light": LightSimulator,
    "illumination": LightSimulator, # handle variations
    "humidity": HumiditySimulator,
    "energy": EnergySimulator,
    "power": EnergySimulator
}

class Orchestrator:
    def __init__(self):
        self.active_simulators = {} # unique_key -> simulator_instance

    def fetch_devices(self):
        try:
            response = requests.get(API_URL, timeout=5)
            if response.status_code == 200:
                data = response.json()
                return data.get('devices', []) if isinstance(data, dict) else data
            else:
                print(f"⚠️ API returned {response.status_code}")
                return []
        except Exception as e:
            print(f"❌ API Error: {e}")
            return []

    def update_simulators(self):
        devices = self.fetch_devices()
        current_sim_keys = set()

        for device in devices:
            device_id = device.get('device_id') or device.get('deviceId')
            if not device_id: continue
            
            protocol = device.get('protocol', '').upper()
            status = device.get('status', 'active')
            device_type = device.get('type', '').lower()
            metadata = device.get('metadata') or {}
            
            # We only care about active MQTT devices
            if protocol != 'MQTT' or status != 'active':
                continue

            # Determine which sensors to run for this device
            sensors_to_run = []
            
            # Check for multi-sensor definition in metadata
            if 'sensors' in metadata and isinstance(metadata['sensors'], list):
                for s_type in metadata['sensors']:
                    sensors_to_run.append(s_type.lower())
            else:
                # Fallback to single type
                sensors_to_run.append(device_type)

            # Process each sensor for this device
            for s_type in sensors_to_run:
                sim_class = SIMULATOR_MAP.get(s_type)
                if not sim_class:
                    if s_type != 'multi-sensor': # Ignore generic parent type
                       print(f"⚠️ Unknown sensor type '{s_type}' for {device_id}")
                    continue

                # Unique key for this specific simulation thread
                sim_key = f"{device_id}::{s_type}"
                current_sim_keys.add(sim_key)

                # Start simulator if not running
                if sim_key not in self.active_simulators:
                    print(f"➕ Starting {s_type} simulator for: {device_id}")
                    # Instantiate simulator (simulator classes take device_id)
                    # Note: They publish to f"campus/{device_id}/{topic_suffix}"
                    # BaseSimulator handles the topic suffix based on type usually, 
                    # but our subclasses hardcode it in __init__ call to super.
                    # e.g. TemperatureSimulator passes "temperature".
                    sim = sim_class(device_id) 
                    sim.start()
                    self.active_simulators[sim_key] = sim
                    # Small delay to avoid overwhelming MQTT broker with simultaneous connections
                    time.sleep(0.2)

        # Stop simulators that are no longer needed
        # (Device deleted, status changed, or sensor type removed from metadata)
        for sim_key in list(self.active_simulators.keys()):
            if sim_key not in current_sim_keys:
                print(f"➖ Stopping simulator: {sim_key}")
                self.active_simulators[sim_key].stop()
                del self.active_simulators[sim_key]

    def run(self):
        print("🎹 Simulator Orchestrator Started (Multi-Sensor Supported)")
        print(f"📡 Monitoring API: {API_URL}")
        print("--------------------------------")
        
        try:
            while True:
                self.update_simulators()
                time.sleep(POLL_INTERVAL)
        except KeyboardInterrupt:
            print("\n🛑 Orchestrator stopping...")
            for sim in self.active_simulators.values():
                sim.stop()
            print("✅ All simulators stopped.")

if __name__ == "__main__":
    orchestrator = Orchestrator()
    orchestrator.run()
