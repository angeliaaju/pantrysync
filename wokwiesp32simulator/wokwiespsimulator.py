import network
import urequests
import time
import random
import utime
from umqtt.robust import MQTTClient

# Connect to WiFi   
print("Connecting to WiFi", end="")
sta_if = network.WLAN(network.STA_IF)
sta_if.active(True)
sta_if.connect('Wokwi-GUEST', '')
while not sta_if.isconnected():
    print(".", end="")
    time.sleep(0.25)
print("Connected!")

# MQTT Client Setup
def create_mqtt_client(client_id, hostname, username, password, port=8883, keepalive=120, ssl=True):
    c = MQTTClient(client_id=client_id, server=hostname, port=port, user=username, password=password, keepalive=keepalive, ssl=ssl)
    c.DEBUG = True
    return c

def get_telemetry_topic(device_id):
    return f"devices/{device_id}/messages/events/"

def get_c2d_topic(device_id):
    return f"devices/{device_id}/messages/devicebound/#"

# Parse Connection String
DELIMITER = ";"
VALUE_SEPARATOR = "="
def parse_connection(connection_string):
    cs_args = connection_string.split(DELIMITER)
    dictionary = dict(arg.split(VALUE_SEPARATOR, 1) for arg in cs_args)
    return dictionary

# Azure IoT Hub Configuration for testdevice1
connection_string = "cs"
dict_keys = parse_connection(connection_string)
hostname = dict_keys.get("HostName")
iot_device_id = dict_keys.get("DeviceId")  # This is testdevice1
shared_access_key = dict_keys.get("SharedAccessKey")

sas_token_str = "sast"
username = f"{hostname}/{iot_device_id}"

# Create MQTT Client for testdevice1
mqtt_client = create_mqtt_client(client_id=iot_device_id, hostname=hostname, username=username, password=sas_token_str)
print("Connecting to IoT Hub")
mqtt_client.reconnect()

# Callback for Cloud-to-Device Messages
def callback_handler(topic, message_receive):
    print(f"Device {iot_device_id} received message:", message_receive)

subscribe_topic = get_c2d_topic(iot_device_id)
mqtt_client.set_callback(callback_handler)
mqtt_client.subscribe(topic=subscribe_topic)

# Logical devices to simulate (d1, d2, d3)
logical_devices = [
    {
        "logical_device_id": "1",
        "d": "d1",
        "last_state": {
            "items": {"I98": 2000},  # Flour: Initial weight 2000g
            "temperature": 0.0,
            "is_disturbed": False,
            "battery_level": 100,
            "current_height": 20.0,
            "initial_total_weight": 2000  # For proportional height calculation
        },
        "updates_sent": 0,
        "max_updates": 2  # 2 incremental updates for d1
    },
    {
        "logical_device_id": "2",
        "d": "d2",
        "last_state": {
            "items": {"I21": 1000},  # Milk: Initial weight 1000ml (1 liter)
            "temperature": 0.0,
            "is_disturbed": False,
            "battery_level": 100,
            "current_height": 15.0,
            "initial_total_weight": 1000  # For proportional height calculation
        },
        "updates_sent": 0,
        "max_updates": 2  # 2 incremental updates for d2
    },
    {
        "logical_device_id": "3",
        "d": "d3",
        "last_state": {
            "items": {
                "I41": 800,  # Apples
                "I42": 600,  # Bananas
                "I43": 900,  # Oranges
                "I46": 400,  # Carrots
                "I47": 250,  # Broccoli
                "I48": 150,  # Spinach
                "I49": 300,  # Lettuce
                "I50": 500,  # Tomatoes
                "I51": 700,  # Potatoes
                "I52": 350   # Onions
            },
            "temperature": 0.0,
            "is_disturbed": False,
            "battery_level": 100,
            "current_height": 25.0,
            "initial_total_weight": 4910  # Updated total: 800 + 600 + 900 + 400 + 250 + 150 + 300 + 500 + 700 + 350
        },
        "updates_sent": 0,
        "max_updates": 5  # 5 incremental updates for d3
    }
]

# Simulated Sensor Readings
def read_temperature():
    return random.uniform(0, 10)  # Simulate temperature in Celsius (0-10°C)

def is_disturbed():
    return False  # Fixed as false for simplicity

def read_battery_level():
    return 100  # Fixed at 100% for simplicity

# Calculate total weight from individual item weights
def calculate_total_weight(items):
    return sum(weight for weight in items.values() if weight is not None)

# Generate ISO 8601 Timestamp (base date: July 12, 2025)
def get_iso_time(offset_days=0, offset_seconds=0):
    # Base timestamp: July 12, 2025 00:00:00 UTC
    base_epoch = 1752364800  # Unix timestamp for 2025-07-12T00:00:00Z
    adjusted_epoch = base_epoch + (offset_days * 86400) + offset_seconds
    # Convert epoch to datetime tuple
    time_tuple = utime.localtime(adjusted_epoch)
    year, month, day, hour, minute, second = time_tuple[0:6]
    return f"{year:04d}-{month:02d}-{day:02d}T{hour:02d}:{minute:02d}:{second:02d}Z"

# Parse ISO 8601 Timestamp to a tuple for utime.mktime
def parse_iso_time(iso_str):
    # Expected format: YYYY-MM-DDThh:mm:ssZ (e.g., "2025-07-12T00:00:00Z")
    year = int(iso_str[0:4])
    month = int(iso_str[5:7])
    day = int(iso_str[8:10])
    hour = int(iso_str[11:13])
    minute = int(iso_str[14:16])
    second = int(iso_str[17:19])
    # utime.mktime expects a tuple: (year, month, day, hour, minute, second, weekday, yearday)
    return (year, month, day, hour, minute, second, 0, 1)

# Send Initial Full State
def send_initial_state(device):
    device_id = device["d"]
    items = device["last_state"]["items"]
    total_weight = calculate_total_weight(items)
    temperature = read_temperature()
    is_disturbed_val = is_disturbed()
    battery_level = read_battery_level()

    # Set best before dates: d2 expired, d1 and d3 one month from base date (July 12, 2025)
    items_with_dates = []
    for item_id, weight in items.items():
        if device_id == "d2":  # d2 items (Milk) set to expired
            best_before = get_iso_time(offset_days=-1)  # July 11, 2025
        else:  # d1 and d3: 1 month after base date (August 12, 2025)
            best_before = get_iso_time(offset_days=31)  # July 12 + 31 days ≈ August 12, 2025
        items_with_dates.append({"id": item_id, "w": weight, "bb": best_before})

    # Set totalHeight and currentHeight
    total_height = 20.0 if device_id == "d1" else 15.0 if device_id == "d2" else 30.0
    current_height = device["last_state"]["current_height"]

    # Update last state
    device["last_state"]["temperature"] = temperature
    device["last_state"]["is_disturbed"] = is_disturbed_val
    device["last_state"]["battery_level"] = battery_level
    device["last_state"]["initial_total_weight"] = total_weight

    # Initial payload
    timestamp = get_iso_time()
    payload = {
        "id": f"update_{device_id}_{timestamp}",
        "d": device_id,
        "t": timestamp,
        "isInitial": True,
        "c": {
            "w": total_weight,
            "i": items_with_dates,
            "e": {"t": temperature, "d": is_disturbed_val},
            "s": {"b": battery_level}
        },
        "ch": current_height,
        "th": total_height
    }
    msg = str(payload).replace("'", '"')  # Convert to JSON string
    mqtt_client.publish(topic=get_telemetry_topic(iot_device_id), msg=msg)
    print(f"Logical Device {device_id} published initial state:", msg)

# Send Incremental Update
def send_incremental_update(device):
    device_id = device["d"]
    current_items = device["last_state"]["items"].copy()
    current_height = device["last_state"]["current_height"]
    initial_total_weight = device["last_state"]["initial_total_weight"]

    # Simulate changes
    items_changes = []
    if device_id == "d1":  # Device 1: Flour (I98)
        current_weight = current_items["I98"]
        new_weight = current_weight - 500  # Reduce by 500g
        current_items["I98"] = new_weight
        items_changes.append({"id": "I98", "w": new_weight})
        # Update currentHeight proportionally (20cm at 2000g → 10cm at 1000g)
        total_weight = calculate_total_weight(current_items)
        current_height = (total_weight / initial_total_weight) * 20.0
    elif device_id == "d2":  # Device 2: Milk (I21)
        current_weight = current_items["I21"]
        new_weight = current_weight - 200  # Reduce by 200ml
        current_items["I21"] = new_weight
        items_changes.append({"id": "I21", "w": new_weight})
        # Update currentHeight proportionally (15cm at 1000ml → 9cm at 600ml)
        total_weight = calculate_total_weight(current_items)
        current_height = (total_weight / initial_total_weight) * 15.0
    elif device_id == "d3":  # Device 3: Fruits and Vegetables
        if device["updates_sent"] == 0:  # First update: Remove expired items
            for item_id in list(current_items.keys()):
                best_before = get_iso_time(offset_days=31)  # August 12, 2025 for d3
                best_before_tuple = parse_iso_time(best_before)
                current_date_tuple = parse_iso_time("2025-07-12T00:00:00Z")  # Today: July 12, 2025
                best_before_timestamp = utime.mktime(best_before_tuple)
                current_date_timestamp = utime.mktime(current_date_tuple)
                if best_before_timestamp < current_date_timestamp:  # Item is expired
                    items_changes.append({"id": item_id, "r": True})
                    del current_items[item_id]
        else:  # Subsequent updates: Reduce weights of remaining items by 10%
            for item_id in list(current_items.keys()):
                current_weight = current_items[item_id]
                reduction = int(current_weight * 0.1)  # Reduce by 10%
                new_weight = current_weight - reduction
                if new_weight <= 0:  # Remove item if weight drops to 0
                    items_changes.append({"id": item_id, "r": True})
                    del current_items[item_id]
                else:
                    current_items[item_id] = new_weight
                    items_changes.append({"id": item_id, "w": new_weight})
        # Update currentHeight proportionally (25cm at 4910g → proportional to current weight)
        total_weight = calculate_total_weight(current_items)
        current_height = (total_weight / initial_total_weight) * 25.0

    current_total_weight = calculate_total_weight(current_items)
    current_temp = read_temperature()
    current_disturbed = is_disturbed()
    current_battery = read_battery_level()

    # Build changes
    changes = {}
    changes["w"] = current_total_weight
    if items_changes:
        changes["i"] = items_changes
    changes["e"] = {}
    if abs(current_temp - device["last_state"]["temperature"]) > 1.0:
        changes["e"]["t"] = current_temp
    if current_disturbed != device["last_state"]["is_disturbed"]:
        changes["e"]["d"] = current_disturbed
    if abs(current_battery - device["last_state"]["battery_level"]) > 5:
        changes["s"] = {"b": current_battery}

    # Send update
    if changes and device["updates_sent"] < device["max_updates"]:
        timestamp = get_iso_time(offset_seconds=(device["updates_sent"] + 1) * 60)  # Increment timestamp by 1 minute per update
        payload = {
            "id": f"update_{device_id}_{timestamp}",
            "d": device_id,
            "t": timestamp,
            "isInitial": False,
            "c": changes,
            "ch": current_height
        }
        msg = str(payload).replace("'", '"')
        mqtt_client.publish(topic=get_telemetry_topic(iot_device_id), msg=msg)
        print(f"Logical Device {device_id} published incremental update {device['updates_sent'] + 1}:", msg)

        # Update last state
        device["last_state"]["items"] = current_items
        device["last_state"]["current_height"] = current_height
        if "t" in changes["e"]:
            device["last_state"]["temperature"] = current_temp
        if "d" in changes["e"]:
            device["last_state"]["is_disturbed"] = current_disturbed
        if "s" in changes:
            device["last_state"]["battery_level"] = current_battery

        device["updates_sent"] += 1

# Main Loop
print("Publishing initial states")
for device in logical_devices:
    send_initial_state(device)

print("Starting incremental updates")
iteration = 0
while True:
    mqtt_client.check_msg()  # Check for incoming messages
    for device in logical_devices:
        if device["updates_sent"] < device["max_updates"]:
            send_incremental_update(device)
    iteration += 1
    if all(device["updates_sent"] >= device["max_updates"] for device in logical_devices):
        print(f"All logical devices completed updates after {iteration} iterations. Total states sent: 12. Exiting loop.")
        break
    time.sleep(5)  # Wait 5 seconds between updates