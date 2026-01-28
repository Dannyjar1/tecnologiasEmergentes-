from .base_simulator import BaseSimulator
import random
import time
from datetime import datetime

class LightSimulator(BaseSimulator):
    def __init__(self, device_id, interval=5):
        super().__init__(device_id, "illumination", interval)

    def _generate_payload(self):
        hour = datetime.now().hour
        if 6 <= hour < 8:
            val = random.randint(100, 300)
        elif 8 <= hour < 12:
            val = random.randint(400, 800)
        elif 12 <= hour < 14:
            val = random.randint(600, 1000)
        elif 14 <= hour < 18:
            val = random.randint(400, 700)
        elif 18 <= hour < 20:
            val = random.randint(200, 400)
        elif 20 <= hour < 22:
            val = random.randint(100, 300)
        else:
            val = random.randint(0, 50)

        return {
            "value": val,
            "unit": "lux",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "metadata": {
                "battery": random.randint(70, 100)
            }
        }
