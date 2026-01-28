from .base_simulator import BaseSimulator
import random
import time
from datetime import datetime

class EnergySimulator(BaseSimulator):
    def __init__(self, device_id, interval=5):
        super().__init__(device_id, "power", interval)

    def _generate_payload(self):
        hour = datetime.now().hour
        if 7 <= hour < 9:
            val = round(random.uniform(2.5, 4.0), 2)
        elif 9 <= hour < 12:
            val = round(random.uniform(4.0, 6.5), 2)
        elif 12 <= hour < 14:
            val = round(random.uniform(3.0, 4.5), 2)
        elif 14 <= hour < 18:
            val = round(random.uniform(4.5, 7.0), 2)
        elif 18 <= hour < 22:
            val = round(random.uniform(2.0, 3.5), 2)
        else:
            val = round(random.uniform(0.5, 1.5), 2)

        return {
            "value": val,
            "unit": "kW",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "metadata": {
                "voltage": round(random.uniform(220, 230), 1),
                "frequency": round(random.uniform(59.8, 60.2), 1)
            }
        }
