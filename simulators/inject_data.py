import requests
import json
from datetime import datetime, timedelta
import random
import time

# API Configuration
API_URL = "http://192.168.1.106:8080/api/telemetry"
HEADERS = {"Content-Type": "application/json"}

def inject_temperature_data(count=20):
    """Inject historical temperature data for lab-01-temp"""
    print(f"📊 Injecting {count} temperature readings for lab-01-temp...")
    
    base_time = datetime.utcnow()
    
    for i in range(count):
        # Create data points going backwards in time (5 min intervals)
        timestamp = base_time - timedelta(minutes=5 * (count - i - 1))
        temperature = round(random.uniform(20, 35), 2)
        
        payload = {
            "deviceId": "lab-01-temp",
            "metric": "temperature",
            "value": temperature,
            "unit": "celsius",
            "timestamp": timestamp.isoformat() + "Z"
        }
        
        try:
            response = requests.post(API_URL, headers=HEADERS, json=payload)
            if response.status_code == 201:
                print(f"✅ {i+1}/{count}: {temperature}°C at {timestamp.strftime('%H:%M:%S')}")
            else:
                print(f"❌ Failed: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"❌ Error: {e}")
        
        time.sleep(0.1)  # Small delay to avoid overwhelming the API
    
    print(f"\n✅ Completed! Injected {count} temperature readings")

def inject_occupancy_data(count=10):
    """Inject historical occupancy data for aula-201-occ"""
    print(f"\n📊 Injecting {count} occupancy readings for aula-201-occ...")
    
    base_time = datetime.utcnow()
    
    for i in range(count):
        # Create data points going backwards in time (10 min intervals)
        timestamp = base_time - timedelta(minutes=10 * (count - i - 1))
        occupancy = random.randint(10, 45)
        
        payload = {
            "deviceId": "aula-201-occ",
            "metric": "occupancy",
            "value": occupancy,
            "unit": "persons",
            "timestamp": timestamp.isoformat() + "Z"
        }
        
        try:
            response = requests.post(API_URL, headers=HEADERS, json=payload)
            if response.status_code == 201:
                print(f"✅ {i+1}/{count}: {occupancy} persons at {timestamp.strftime('%H:%M:%S')}")
            else:
                print(f"❌ Failed: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"❌ Error: {e}")
        
        time.sleep(0.1)
    
    print(f"\n✅ Completed! Injected {count} occupancy readings")

if __name__ == "__main__":
    print("🚀 Starting data injection...\n")
    
    # Inject temperature data
    inject_temperature_data(20)
    
    # Inject occupancy data
    inject_occupancy_data(10)
    
    print("\n🎉 Data injection complete!")
    print("📱 Check your Flutter app to see the data")
