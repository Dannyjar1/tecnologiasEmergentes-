import requests
import json
from datetime import datetime
import random
import time

# API Configuration
API_URL = "http://192.168.1.106:8080/api/telemetry"
HEADERS = {"Content-Type": "application/json"}

def inject_temperature():
    """Inject a single current temperature reading"""
    temperature = round(random.uniform(20, 35), 2)
    
    payload = {
        "deviceId": "lab-01-temp",
        "metric": "temperature",
        "value": temperature,
        "unit": "celsius",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    
    try:
        response = requests.post(API_URL, headers=HEADERS, json=payload)
        if response.status_code == 201:
            timestamp = datetime.now().strftime('%H:%M:%S')
            print(f"✅ [{timestamp}] Temperature: {temperature}°C")
            return True
        else:
            print(f"❌ Failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def inject_occupancy():
    """Inject a single current occupancy reading"""
    hour = datetime.now().hour
    
    # Realistic occupancy based on time of day
    if 7 <= hour < 12:
        occupancy = random.randint(20, 45)  # Morning: high
    elif 12 <= hour < 14:
        occupancy = random.randint(5, 15)   # Lunch: low
    elif 14 <= hour < 18:
        occupancy = random.randint(25, 40)  # Afternoon: high
    elif 18 <= hour < 22:
        occupancy = random.randint(10, 25)  # Evening: medium
    else:
        occupancy = 0  # Off hours
    
    payload = {
        "deviceId": "aula-201-occ",
        "metric": "occupancy",
        "value": occupancy,
        "unit": "persons",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    
    try:
        response = requests.post(API_URL, headers=HEADERS, json=payload)
        if response.status_code == 201:
            timestamp = datetime.now().strftime('%H:%M:%S')
            print(f"✅ [{timestamp}] Occupancy: {occupancy} persons")
            return True
        else:
            print(f"❌ Failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Starting real-time data injection...")
    print("📊 Injecting new data every 30 seconds")
    print("Press Ctrl+C to stop\n")
    
    counter = 0
    
    try:
        while True:
            counter += 1
            print(f"\n--- Update #{counter} ---")
            
            # Inject temperature
            inject_temperature()
            
            # Inject occupancy (if device is registered)
            # inject_occupancy()
            
            # Wait 30 seconds
            print("⏳ Waiting 30 seconds...")
            time.sleep(30)
            
    except KeyboardInterrupt:
        print("\n\n🛑 Stopped by user")
        print(f"Total updates sent: {counter}")
