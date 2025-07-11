import requests
import os

# Replace with your Pexels API key
# Obtain from https://www.pexels.com/api/new/
#Please note this API key is dummy don't use
API_KEY = "cl8fYG4oouqdxjt7RffaqQitM6Hxaxpt9568J7rQK1SIhOUB5sPrkeND"

# List of all image filenames from pubspec.yaml with corresponding keywords
image_mappings = [
    ("Fridge.jpg", "refrigerator"),
    ("images/whole_wheat_bread.jpg", "whole wheat bread"),
    ("images/white_bread.jpg", "white bread"),
    ("images/bagels_pack_of_six.jpg", "bagels"),
    ("images/croissants.jpg", "croissants"),
    ("images/muffins_pack_of_four.jpg", "muffins"),
    ("images/donuts_pack_of_six.jpg", "donuts"),
    ("images/sourdough_bread.jpg", "sourdough bread"),
    ("images/ciabatta_rolls.jpg", "ciabatta"),
    ("images/pita_bread.jpg", "pita bread"),
    ("images/baguette.jpg", "baguette"),
    ("images/rye_bread.jpg", "rye bread"),
    ("images/english_muffins.jpg", "english muffins"),
    ("images/tortilla_wraps.jpg", "tortilla"),
    ("images/dinner_rolls.jpg", "dinner rolls"),
    ("images/flatbread.jpg", "flatbread"),
    ("images/brioche.jpg", "brioche"),
    ("images/pretzels.jpg", "pretzels"),
    ("images/crackers.jpg", "crackers"),
    ("images/cookies.jpg", "cookies"),
    ("images/pancake_mix.jpg", "pancake mix"),
    ("images/milk_one.jpg", "milk"),
    ("images/cheese_cheddar.jpg", "cheddar cheese"),
    ("images/yogurt_plain.jpg", "plain yogurt"),
    ("images/butter.jpg", "butter"),
    ("images/cream_cheese.jpg", "cream cheese"),
    ("images/sour_cream.jpg", "sour cream"),
    ("images/whipped_cream.jpg", "whipped cream"),
    ("images/cottage_cheese.jpg", "cottage cheese"),
    ("images/mozzarella.jpg", "mozzarella"),
    ("images/parmesan.jpg", "parmesan"),
    ("images/greek_yogurt.jpg", "greek yogurt"),
    ("images/creamer.jpg", "creamer"),
    ("images/ricotta.jpg", "ricotta"),
    ("images/feta.jpg", "feta"),
    ("images/half_and_half.jpg", "half and half"),
    ("images/ice_cream.jpg", "ice cream"),
    ("images/gouda.jpg", "gouda"),
    ("images/provolone.jpg", "provolone"),
    ("images/brie.jpg", "brie"),
    ("images/milk_two.jpg", "milk"),
    ("images/apples.jpg", "apples"),
    ("images/bananas.jpg", "bananas"),
    ("images/oranges.jpg", "oranges"),
    ("images/grapes.jpg", "grapes"),
    ("images/strawberries.jpg", "strawberries"),
    ("images/carrots.jpg", "carrots"),
    ("images/broccoli.jpg", "broccoli"),
    ("images/spinach.jpg", "spinach"),
    ("images/tomatoes.jpg", "tomatoes"),
    ("images/potatoes.jpg", "potatoes"),
    ("images/lettuce.jpg", "lettuce"),
    ("images/cucumbers.jpg", "cucumbers"),
    ("images/bell_peppers.jpg", "bell peppers"),
    ("images/onions.jpg", "onions"),
    ("images/garlic.jpg", "garlic"),
    ("images/mushrooms.jpg", "mushrooms"),
    ("images/fridge_container_flour.jpg", "flour container"),
    ("images/fridge_container_milk.jpg", "milk container"),
    ("images/fridge_mat.jpg", "fridge mat"),
    ("images/flour.jpg", "flour")
]

# Create assets directory if it doesn't exist
if not os.path.exists("assets"):
    os.makedirs("assets")
if not os.path.exists("assets/images"):
    os.makedirs("assets/images")

# Function to download and save an image with error handling
def download_image(name, keyword):
    url = "https://api.pexels.com/v1/search"
    headers = {"Authorization": API_KEY}
    params = {"query": keyword, "per_page": 1, "page": 1}
    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        if data["photos"] and len(data["photos"]) > 0:
            photo = data["photos"][0]
            image_url = photo["src"]["medium"]  # Medium size image (e.g., 1080x720)
            image_response = requests.get(image_url, stream=True, timeout=10)
            image_response.raise_for_status()
            path = os.path.join("assets", name) if not name.startswith("images/") else os.path.join("assets", name)
            with open(path, "wb") as f:
                for chunk in image_response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            print(f"Downloaded {name} from {image_url}")
        else:
            print(f"No image found for {name} ({keyword})")
            path = os.path.join("assets", name) if not name.startswith("images/") else os.path.join("assets", name)
            open(path, 'a').close()
            print(f"Created empty placeholder for {name}")
    except requests.exceptions.RequestException as e:
        print(f"Failed to download {name} ({keyword}): {e}")
        path = os.path.join("assets", name) if not name.startswith("images/") else os.path.join("assets", name)
        open(path, 'a').close()
        print(f"Created empty placeholder for {name}")

# Download each image with appropriate keyword
for name, keyword in image_mappings:
    download_image(name, keyword)

print("Image download process completed!")