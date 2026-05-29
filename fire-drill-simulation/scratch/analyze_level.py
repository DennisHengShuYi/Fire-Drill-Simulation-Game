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
            # Check for property assignments
            prop_match = re.match(r'^([\w_/\.]+)\s*=\s*(.*)', line.strip())
            if prop_match:
                current_node['properties'][prop_match.group(1)] = prop_match.group(2)

if current_node:
    nodes.append(current_node)

print(f"Total nodes in scene: {len(nodes)}")

# Group by type
by_type = {}
for node in nodes:
    by_type[node['type']] = by_type.get(node['type'], 0) + 1

print("\nNode Counts by Type:")
for t, count in sorted(by_type.items(), key=lambda x: x[1], reverse=True):
    print(f"  {t}: {count}")

print("\nDetailing CPUParticles3D nodes:")
for node in nodes:
    if "Particles" in node['type'] or "particles" in node['type'].lower():
        print(f"  Node Name: {node['name']}")
        for prop, val in node['properties'].items():
            print(f"    {prop} = {val}")

print("\nDetailing Light3D nodes with shadows:")
light_count = 0
shadow_count = 0
for node in nodes:
    if "Light3D" in node['type'] or node['type'] in ["OmniLight3D", "SpotLight3D", "DirectionalLight3D"]:
        light_count += 1
        has_shadow = node['properties'].get('shadow_enabled', 'false')
        if has_shadow == 'true':
            shadow_count += 1
        print(f"  Light: {node['name']} ({node['type']}) | shadow_enabled = {has_shadow} | energy = {node['properties'].get('light_energy', '1.0')}")

print(f"\nTotal lights: {light_count}")
print(f"Total lights with shadows: {shadow_count}")
