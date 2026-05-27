import os
import random
import math
from PIL import Image, ImageDraw

def generate_drywall(path):
    width, height = 512, 512
    # Base beige/off-white plaster color
    base_color = (220, 215, 210)
    img = Image.new("RGB", (width, height), base_color)
    pixels = img.load()
    
    # Add fine plaster noise
    for y in range(height):
        for x in range(width):
            n = random.randint(-6, 6)
            r = min(255, max(0, base_color[0] + n))
            g = min(255, max(0, base_color[1] + n))
            b = min(255, max(0, base_color[2] + n))
            pixels[x, y] = (r, g, b)
            
    img.save(path)
    print(f"Generated drywall texture: {path}")

def generate_wood_door(path):
    width, height = 512, 512
    # Base warm wood brown
    img = Image.new("RGB", (width, height))
    pixels = img.load()
    
    # Generate wood grain
    for y in range(height):
        for x in range(width):
            # Use sine waves to simulate wood grain rings
            noise = math.sin(x * 0.05 + math.sin(y * 0.02) * 2.0) * 15.0
            noise += random.randint(-4, 4) # Fine grain noise
            
            r = min(255, max(0, 110 + int(noise)))
            g = min(255, max(0, 70 + int(noise * 0.8)))
            b = min(255, max(0, 40 + int(noise * 0.6)))
            pixels[x, y] = (r, g, b)
            
    img.save(path)
    print(f"Generated wood door texture: {path}")

def generate_floor_tiles(path):
    width, height = 512, 512
    tile_size = 64
    grout_color = (130, 130, 130)
    
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    
    # Fill tiles with dark slate/charcoal noise
    pixels = img.load()
    for y in range(height):
        for x in range(width):
            n = random.randint(-8, 8)
            r = min(255, max(0, 45 + n))
            g = min(255, max(0, 47 + n))
            b = min(255, max(0, 52 + n))
            pixels[x, y] = (r, g, b)
            
    # Draw grout lines
    for i in range(0, width, tile_size):
        draw.line([(i, 0), (i, height)], fill=grout_color, width=3)
        draw.line([(0, i), (width, i)], fill=grout_color, width=3)
        
    img.save(path)
    print(f"Generated floor tiles: {path}")

def generate_bathroom_tiles(path):
    width, height = 512, 512
    tile_size = 32
    grout_color = (235, 240, 245)
    
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    
    # Fill tiles with light blue-gray ceramic noise
    pixels = img.load()
    for y in range(height):
        for x in range(width):
            n = random.randint(-5, 5)
            r = min(255, max(0, 160 + n))
            g = min(255, max(0, 185 + n))
            b = min(255, max(0, 195 + n))
            pixels[x, y] = (r, g, b)
            
    # Draw grout lines
    for i in range(0, width, tile_size):
        draw.line([(i, 0), (i, height)], fill=grout_color, width=2)
        draw.line([(0, i), (width, i)], fill=grout_color, width=2)
        
    img.save(path)
    print(f"Generated bathroom tiles: {path}")

def generate_particle_texture(path):
    width, height = 128, 128
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = img.load()
    cx, cy = width / 2.0, height / 2.0
    max_radius = width / 2.0
    for y in range(height):
        for x in range(width):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist < max_radius:
                factor = 1.0 - (dist / max_radius)
                alpha = int(255 * (factor ** 1.5))
                alpha = max(0, min(255, alpha))
                pixels[x, y] = (255, 255, 255, alpha)
    img.save(path)
    print(f"Generated particle texture: {path}")

if __name__ == "__main__":
    assets_dir = os.path.dirname(os.path.abspath(__file__))
    generate_drywall(os.path.join(assets_dir, "drywall texture.png"))
    generate_wood_door(os.path.join(assets_dir, "door texture.png"))
    generate_floor_tiles(os.path.join(assets_dir, "floor-tiles.png"))
    generate_bathroom_tiles(os.path.join(assets_dir, "bathroom-tiles.png"))
    generate_particle_texture(os.path.join(assets_dir, "particle_soft.png"))

