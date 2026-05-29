import os
from PIL import Image

assets_dir = r"c:\Users\den51\FireDrill-Simulation\fire-drill-simulation\assets"
for root, dirs, files in os.walk(assets_dir):
    for f in files:
        if f.lower().endswith(('.png', '.jpg', '.jpeg')):
            path = os.path.join(root, f)
            try:
                with Image.open(path) as img:
                    width, height = img.size
                    size_mb = os.path.getsize(path) / (1024 * 1024)
                    print(f"{os.path.relpath(path, assets_dir)}: {width}x{height} ({size_mb:.2f} MB)")
            except Exception as e:
                print(f"Error opening {f}: {e}")
