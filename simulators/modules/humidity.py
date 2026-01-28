from .base_simulator import BaseSimulator
import random
import time
from datetime import datetime

class HumiditySimulator(BaseSimulator):
    def __init__(self, device_id, interval=5):
        super().__init__(device_id, "humidity", interval)

    def _generate_payload(self):
        hour = datetime.now().hour
        if 6 <= hour < 9:
            val = round(random.uniform(55, 65), 1)
        elif 9 <= hour < 12:
            val = round(random.uniform(45, 55), 1)
        elif 12 <= hour < 15:
            val = round(random.uniform(40, 50), 1)
        elif 15 <= hour < 18:
            val = round(random.uniform(45, 55), 1)
        elif 18 <= hour < 22:
            val = round(random.uniform(50, 60), 1)
        else:
            val = round(random.uniform(55, 70), 1)

        return {
            "value": val,
            "unit": "%",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "metadata": {
                "battery": random.randint(70, 100)
            }
        }
