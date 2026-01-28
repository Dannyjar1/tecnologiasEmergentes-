from .base_simulator import BaseSimulator
import random
import time

class TemperatureSimulator(BaseSimulator):
    def __init__(self, device_id, interval=5):
        super().__init__(device_id, "temperature", interval)

    def _generate_payload(self):
        return {
            "value": round(random.uniform(20, 35), 2),
            "unit": "celsius",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "metadata": {
                "battery": random.randint(70, 100),
                "signal": random.randint(-60, -30)
            }
        }
