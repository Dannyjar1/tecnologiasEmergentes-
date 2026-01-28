from .base_simulator import BaseSimulator
import random
import time
from datetime import datetime

class OccupancySimulator(BaseSimulator):
    def __init__(self, device_id, interval=10):
        super().__init__(device_id, "occupancy", interval)

    def _generate_payload(self):
        hour = datetime.now().hour
        if 7 <= hour < 12:
            count = random.randint(20, 45)
        elif 12 <= hour < 14:
            count = random.randint(5, 15)
        elif 14 <= hour < 18:
            count = random.randint(25, 40)
        elif 18 <= hour < 22:
            count = random.randint(10, 25)
        else:
            count = 0
            
        return {
            "value": count,
            "unit": "persons",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        }
