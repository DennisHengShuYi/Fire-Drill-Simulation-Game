import os
import re
from PIL import Image

assets_dir = r"c:\Users\den51\FireDrill-Simulation\fire-drill-simulation\assets"

def update_import_file(import_path):
    if not os.path.exists(import_path):
        return
    
    with open(import_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Let's check if [params] section exists
    if "[params]" not in content:
        print(f"Warning: [params] section not found in {import_path}")
        return
    
    # We want to replace/insert parameters under [params] section
    # Let's split into pre-params and params
    parts = content.split("[params]")
    pre_params = parts[0]
    params_body = parts[1]
    
    # Define replacements
    replacements = {
        r"compress/mode\s*=.*": "compress/mode=2",
        r"compress/high_quality\s*=.*": "compress/high_quality=false",
        r"process/size_limit\s*=.*": "process/size_limit=1024"
    }
    
    for pattern, replacement in replacements.items():
        if re.search(pattern, params_body):
            params_body = re.sub(pattern, replacement, params_body)
        else:
            # If not found, append to the end of the params section
            params_body = params_body.strip() + "\n" + replacement + "\n"
            
    new_content = pre_params + "[params]\n" + params_body
    with open(import_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Updated import settings for {os.path.basename(import_path)}")

# Main loop
for root, dirs, files in os.walk(assets_dir):
    for f in files:
        if f.lower().endswith(('.png', '.jpg', '.jpeg')):
            img_path = os.path.join(root, f)
            import_path = img_path + ".import"
            
            try:
                resized = False
                with Image.open(img_path) as img:
                    width, height = img.size
                    if width > 1024 or height > 1024:
                        # Calculate new size maintaining aspect ratio
                        if width > height:
                            new_width = 1024
                            new_height = int(height * (1024.0 / width))
                        else:
                            new_height = 1024
                            new_width = int(width * (1024.0 / height))
                        
                        print(f"Resizing {os.path.relpath(img_path, assets_dir)}: {width}x{height} -> {new_width}x{new_height}")
                        
                        # Get resampling filter
                        try:
                            resample_filter = Image.Resampling.LANCZOS
                        except AttributeError:
                            resample_filter = Image.LANCZOS
                            
                        resized_img = img.resize((new_width, new_height), resample_filter)
                        resized = True
                
                # Save resized image
                if resized:
                    # Save back using same format/quality
                    resized_img.save(img_path)
                    
                # Update import settings regardless if it was resized or we just want VRAM compression
                update_import_file(import_path)
                
            except Exception as e:
                print(f"Error processing {f}: {e}")

print("Texture resizing and import configuration complete!")
