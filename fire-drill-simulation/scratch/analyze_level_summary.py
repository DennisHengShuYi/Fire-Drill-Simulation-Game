import re

scene_path = r"c:\Users\den51\FireDrill-Simulation\fire-drill-simulation\scenes\level.tscn"

node_pattern = re.compile(r'^\[node name="([^"]+)" type="([^"]+)"(?: parent="([^"]+)")?.*\]')

nodes = []
current_node = None

with open(scene_path, 'r', encoding='utf-8') as f:
    for line in f:
        node_match = node_pattern.match(line)
        if node_match:
            if current_node:
                nodes.append(current_node)
            current_node = {
                'name': node_match.group(1),
                'type': node_match.group(2),
                'parent': node_match.group(3),
                'properties': {}
            }
        elif current_node:
            prop_match = re.match(r'^([\w_/\.]+)\s*=\s*(.*)', line.strip())
            if prop_match:
                current_node['properties'][prop_match.group(1)] = prop_match.group(2)

if current_node:
    nodes.append(current_node)

print(f"Total nodes in scene: {len(nodes)}")

by_type = {}
for node in nodes:
    by_type[node['type']] = by_type.get(node['type'], 0) + 1

print("\nNode Counts by Type:")
for t, count in sorted(by_type.items(), key=lambda x: x[1], reverse=True):
    print(f"  {t}: {count}")

print("\nSummary of CPUParticles3D amount of particles:")
total_particles = 0
for node in nodes:
    if node['type'] == "CPUParticles3D":
        amount = int(node['properties'].get('amount', '8'))
        total_particles += amount
        print(f"  Particle Node: {node['name']} | amount = {amount} | emitting = {node['properties'].get('emitting', 'true')}")
print(f"Total particle nodes: {by_type.get('CPUParticles3D', 0)}")
print(f"Total particles in active emission: {total_particles}")
