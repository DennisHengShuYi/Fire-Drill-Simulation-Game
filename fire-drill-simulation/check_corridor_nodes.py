import re

with open("scenes/level.tscn", "r") as f:
    content = f.read()

# Let's find all nodes under "Geometry/SharedCorridor"
nodes = re.split(r'\[node ', content)
for n in nodes:
    if 'parent="Geometry/SharedCorridor"' in n:
        print("--- NODE ---")
        print("[node " + n.strip())
