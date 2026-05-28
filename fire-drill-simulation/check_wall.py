import re

with open("scenes/level.tscn", "r") as f:
    content = f.read()

# Let's find nodes with name "CorridorMiddleWall"
matches = re.findall(r'\[node name="CorridorMiddleWall"[^\]]*\](?:[^\[]*)', content)
for m in matches:
    print("MATCH:")
    print(m)
