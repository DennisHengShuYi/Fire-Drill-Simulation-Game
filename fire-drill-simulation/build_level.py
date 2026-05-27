#!/usr/bin/env python3
"""
Generates scenes/level.tscn for the Malaysian Condominium Fire Drill game.
Level 8, Unit 8A. Fire in kitchen. Player must use fire stairwell to escape.
"""

lines = []

# ── helpers ─────────────────────────────────────────────────────────────────

def tf(x, y, z):
    return f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z})"

def tf_rot_x(deg, x, y, z):
    import math
    r = math.radians(deg)
    c = round(math.cos(r), 8)
    s = round(math.sin(r), 8)
    return f"Transform3D(1, 0, 0, 0, {c}, {s}, 0, {-s}, {c}, {x}, {y}, {z})"

def tf_rot_y(deg, x, y, z):
    import math
    r = math.radians(deg)
    c = round(math.cos(r), 8)
    s = round(math.sin(r), 8)
    return f"Transform3D({c}, 0, {s}, 0, 1, 0, {-s}, 0, {c}, {x}, {y}, {z})"

def color(r, g, b, a=1):
    return f"Color({r}, {g}, {b}, {a})"

def vec3(x, y, z):
    return f"Vector3({x}, {y}, {z})"

# Sub-resource counter
_sub_id = [0]
sub_resources = []   # list of (id_str, lines_list)

def new_sub(type_name):
    _sub_id[0] += 1
    sid = f"SubRes_{_sub_id[0]}"
    return sid

def add_sub(sid, type_name, props):
    """props: list of "key = value" strings"""
    block = [f'[sub_resource type="{type_name}" id="{sid}"]']
    block.extend(props)
    block.append("")
    sub_resources.append(block)
    return sid

# Node counter for unique parent paths
def node(name, type_, parent, props=None, instance=None):
    """Emit a [node] block."""
    if parent == "" or parent is None:
        if instance:
            lines.append(f'[node name="{name}" instance=ExtResource("{instance}")]')
        else:
            lines.append(f'[node name="{name}" type="{type_}"]')
    else:
        if instance:
            lines.append(f'[node name="{name}" parent="{parent}" instance=ExtResource("{instance}")]')
        else:
            lines.append(f'[node name="{name}" type="{type_}" parent="{parent}"]')
    if props:
        for p in props:
            lines.append(p)
    lines.append("")

# ── ext_resources ────────────────────────────────────────────────────────────

ext_resources = [
    '[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1_player"]',
    '[ext_resource type="Script" path="res://scripts/interactable.gd" id="2_interactable"]',
    '[ext_resource type="Script" path="res://scripts/smoke_area.gd" id="3_smoke_area"]',
    '[ext_resource type="Script" path="res://scripts/light_flicker.gd" id="4_light_flicker"]',
    '[ext_resource type="Script" path="res://scripts/synth_audio.gd" id="5_synth_audio"]',
    '[ext_resource type="Script" path="res://scripts/synth_audio_3d.gd" id="6_synth_audio_3d"]',
    '[ext_resource type="Script" path="res://scripts/elevator.gd" id="7_elevator"]',
    '[ext_resource type="Script" path="res://scripts/fire_area.gd" id="8_fire_area"]',
    '[ext_resource type="Script" path="res://scripts/npc.gd" id="9_npc"]',
    '[ext_resource type="Texture2D" path="res://assets/particle_soft.png" id="10_particle_soft"]',
]

# ── materials as sub-resources ───────────────────────────────────────────────

def mat(sid, col_str, roughness=0.9, metallic=0.0, emission=None, emit_energy=1.0, transparency=0):
    props = [f'albedo_color = {col_str}', f'roughness = {roughness}']
    if metallic > 0:
        props.append(f'metallic = {metallic}')
    if emission:
        props.append('emission_enabled = true')
        props.append(f'emission = {emission}')
        props.append(f'emission_energy_multiplier = {emit_energy}')
    if transparency:
        props.append(f'transparency = {transparency}')
    return add_sub(sid, "StandardMaterial3D", props)

# Create all named materials
M_CARPET_MASTER   = mat("Mat_CarpetMaster",  color(0.25, 0.18, 0.12))
M_CARPET_BED2     = mat("Mat_CarpetBed2",    color(0.22, 0.18, 0.14))
M_DRYWALL         = mat("Mat_Drywall",       color(0.85, 0.82, 0.78))
M_DRYWALL2        = mat("Mat_Drywall2",      color(0.88, 0.85, 0.80))
M_TILE_WHITE      = mat("Mat_TileWhite",     color(0.92, 0.92, 0.90), roughness=0.3)
M_WOOD_FLOOR      = mat("Mat_WoodFloor",     color(0.45, 0.30, 0.15), roughness=0.5)
M_CONCRETE        = mat("Mat_Concrete",      color(0.55, 0.52, 0.50), roughness=0.95)
M_CONCRETE_DARK   = mat("Mat_ConcreteDark",  color(0.50, 0.48, 0.45), roughness=0.95)
M_ANTISLIP        = mat("Mat_AntiSlip",      color(0.48, 0.46, 0.42), roughness=0.98)
M_KITCHEN_FLOOR   = mat("Mat_KitchenFloor",  color(0.10, 0.10, 0.10), roughness=0.85)
M_CHARRED         = mat("Mat_Charred",       color(0.06, 0.06, 0.06), roughness=0.95)
M_OUTDOOR_TILE    = mat("Mat_OutdoorTile",   color(0.60, 0.58, 0.55), roughness=0.8)
M_RAILING         = mat("Mat_Railing",       color(0.70, 0.70, 0.70), roughness=0.4, metallic=0.3)
M_WOOD_DOOR       = mat("Mat_WoodDoor",      color(0.35, 0.20, 0.10), roughness=0.6)
M_STEEL_DOOR      = mat("Mat_SteelDoor",     color(0.40, 0.40, 0.42), roughness=0.4, metallic=0.6)
M_GREEN_DOOR      = mat("Mat_GreenDoor",     color(0.10, 0.50, 0.15), roughness=0.5)
M_LIFT_DOOR       = mat("Mat_LiftDoor",      color(0.70, 0.70, 0.75), roughness=0.2, metallic=0.9)
M_CARPET_CORRIDOR = mat("Mat_CarpetCorridor",color(0.20, 0.18, 0.25), roughness=0.9)
M_MARBLE          = mat("Mat_Marble",        color(0.85, 0.83, 0.80), roughness=0.1, metallic=0.1)
M_ASPHALT         = mat("Mat_Asphalt",       color(0.18, 0.18, 0.18), roughness=1.0)
M_ASSEMBLY        = mat("Mat_Assembly",      color(0.35, 0.60, 0.35), roughness=0.8)
M_WOOD_PROP       = mat("Mat_WoodProp",      color(0.30, 0.18, 0.10), roughness=0.7)
M_FABRIC          = mat("Mat_Fabric",        color(0.28, 0.35, 0.45), roughness=0.9)
M_EXIT_SIGN       = mat("Mat_ExitSign",      color(0.0, 0.8, 0.2),
                         emission=color(0.0, 1.0, 0.2), emit_energy=3.0)
M_WARN_SIGN       = mat("Mat_WarnSign",      color(1.0, 0.1, 0.1),
                         emission=color(1.0, 0.1, 0.1), emit_energy=2.0)
M_FLOOR_NUM       = mat("Mat_FloorNum",      color(1.0, 1.0, 1.0),
                         emission=color(1.0, 1.0, 1.0), emit_energy=2.0)
M_PUSH_BAR        = mat("Mat_PushBar",       color(0.8, 0.6, 0.1), roughness=0.3, metallic=0.5)
M_GUARD           = mat("Mat_Guard",         color(0.15, 0.25, 0.40), roughness=0.8)
M_PHONE_BOX       = mat("Mat_PhoneBox",      color(0.8, 0.1, 0.1), roughness=0.5)
M_BALCONY_SIGN    = mat("Mat_BalconySign",   color(0.9, 0.85, 0.1),
                         emission=color(0.9, 0.85, 0.1), emit_energy=1.5)
M_SMOKE           = mat("Mat_Smoke",         color(0.15, 0.15, 0.15, 0.55),
                         transparency=1)
M_SIGN_POST       = mat("Mat_SignPost",      color(0.5, 0.5, 0.5), roughness=0.6)

# Particle System Resources
add_sub("Mat_FireParticle", "StandardMaterial3D", [
    'transparency = 1',
    'shading_mode = 0',
    'vertex_color_use_as_albedo = true',
    'albedo_color = Color(1, 1, 1, 1)',
    'albedo_texture = ExtResource("10_particle_soft")',
    'billboard_mode = 1',
    'billboard_keep_scale = true',
])
add_sub("Mesh_FireParticle", "QuadMesh", [
    'material = SubResource("Mat_FireParticle")',
    'size = Vector2(0.6, 0.6)',
])
add_sub("Grad_Fire", "Gradient", [
    'offsets = PackedFloat32Array(0, 0.15, 0.55, 1)',
    'colors = PackedColorArray(1, 1, 0.3, 1, 1, 0.45, 0, 1, 0.8, 0.08, 0, 0.8, 0.15, 0.15, 0.15, 0)',
])
add_sub("Mat_SmokeParticle", "StandardMaterial3D", [
    'transparency = 1',
    'vertex_color_use_as_albedo = true',
    'albedo_color = Color(1, 1, 1, 1)',
    'albedo_texture = ExtResource("10_particle_soft")',
    'billboard_mode = 1',
    'billboard_keep_scale = true',
])
add_sub("Mesh_SmokeParticle", "QuadMesh", [
    'material = SubResource("Mat_SmokeParticle")',
    'size = Vector2(1.0, 1.0)',
])
add_sub("Grad_Smoke", "Gradient", [
    'offsets = PackedFloat32Array(0, 0.3, 0.8, 1)',
    'colors = PackedColorArray(0.35, 0.35, 0.35, 0.3, 0.25, 0.25, 0.25, 0.5, 0.15, 0.15, 0.3, 0.1, 0.1, 0.1, 0)',
])

# Particle Scale Curves
add_sub("Curve_FireScale", "Curve", [
    '_data = [Vector2(0, 1.2), 0.0, -1.0, 0, 0, Vector2(1, 0.2), -1.0, 0.0, 0, 0]'
])
add_sub("Curve_SmokeScale", "Curve", [
    '_data = [Vector2(0, 0.4), 0.0, 1.8, 0, 0, Vector2(1, 2.2), 1.8, 0.0, 0, 0]'
])

# Collision shapes
def box_shape(sid, sx, sy, sz):
    return add_sub(sid, "BoxShape3D", [f'size = Vector3({sx}, {sy}, {sz})'])


# Sky / environment
SKY_MAT = add_sub("SkyMat", "ProceduralSkyMaterial", [
    f'sky_top_color = {color(0.01, 0.01, 0.03)}',
    f'sky_horizon_color = {color(0.02, 0.02, 0.05)}',
    f'ground_bottom_color = {color(0, 0, 0)}',
    f'ground_horizon_color = {color(0.02, 0.02, 0.05)}',
])
SKY = add_sub("Sky_1", "Sky", [f'sky_material = SubResource("{SKY_MAT}")'])
ENV = add_sub("Env_1", "Environment", [
    'background_mode = 2',
    f'sky = SubResource("{SKY}")',
    'ambient_light_source = 2',
    f'ambient_light_color = {color(0.5, 0.5, 0.55)}',
    'ambient_light_energy = 0.8',
    'tonemap_mode = 2',
    'glow_enabled = true',
    'glow_intensity = 1.0',
    'glow_strength = 1.2',
    'glow_hdr_threshold = 0.8',
    'fog_enabled = true',
    'fog_density = 0.02',
    f'fog_light_color = {color(0.15, 0.12, 0.10)}',
])

# Collision shapes for doors
SHP_DOOR_STD  = box_shape("Shp_DoorStd",   1.0, 2.0, 0.1)
SHP_CABIN     = box_shape("Shp_Cabin",     4.0, 2.0, 1.6)
SHP_GUARD     = box_shape("Shp_Guard",     0.5, 1.6, 0.5)
SHP_PHONE     = box_shape("Shp_Phone",     0.4, 1.6, 0.4)
SHP_EXTINGUISH= box_shape("Shp_Extinguish",0.2, 0.6, 0.2)

# ── SCENE HEADER ─────────────────────────────────────────────────────────────

# Header is built AFTER sub-resources so we can count load_steps accurately
# Placeholder — will be updated at assembly time
header_lines = []  # filled at bottom
header_lines.extend(ext_resources)
header_lines.append("")

# ── NODE EMISSION HELPERS ─────────────────────────────────────────────────────

def csg_box(name, parent, px, py, pz, sx, sy, sz, mat_id, collision=True, extra_props=None):
    props = [
        f'transform = {tf(px, py, pz)}',
    ]
    if collision:
        props.append('use_collision = true')
    props.append(f'size = Vector3({sx}, {sy}, {sz})')
    props.append(f'material = SubResource("{mat_id}")')
    if extra_props:
        props.extend(extra_props)
    node(name, "CSGBox3D", parent, props)

def omni_light(name, parent, px, py, pz, energy, col, flicker=False,
               fl_min=None, fl_max=None, fl_speed=12.0, shadow=False, omni_range=6.0):
    props = [
        f'transform = {tf(px, py, pz)}',
        f'light_color = {col}',
        f'light_energy = {energy}',
        f'omni_range = {omni_range}',
    ]
    if shadow:
        props.append('shadow_enabled = true')
    if flicker:
        props.append(f'script = ExtResource("4_light_flicker")')
        if fl_min is not None:
            props.append(f'min_energy = {fl_min}')
        if fl_max is not None:
            props.append(f'max_energy = {fl_max}')
        props.append(f'flicker_speed = {fl_speed}')
    node(name, "OmniLight3D", parent, props)

def door_static(name, parent, px, py, pz,
                is_hot=False, is_lift=False, is_stairs=False, is_phone=False,
                is_sink=False, is_door=True, can_feel=True, is_locked=False,
                open_angle=90.0, prompt="",
                door_mat=None, rot_y=0,
                width=1.0, height=2.0):
    """Emit a StaticBody3D interactable door with CollisionShape and Mesh."""
    import math
    r = math.radians(rot_y)
    c = round(math.cos(r), 8)
    s = round(math.sin(r), 8)

    # Calculate hinge position (left edge of the door)
    hx = px - (width / 2.0) * c
    hy = py
    hz = pz + (width / 2.0) * s

    if rot_y != 0:
        tf_str = tf_rot_y(rot_y, hx, hy, hz)
    else:
        tf_str = tf(hx, hy, hz)

    props = [
        f'transform = {tf_str}',
        'collision_layer = 2',
        f'script = ExtResource("2_interactable")',
    ]
    if prompt:
        props.append(f'prompt_message = "{prompt}"')
    if is_door:
        props.append('is_door = true')
    if is_hot:
        props.append('is_hot = true')
    if not can_feel:
        props.append('can_feel = false')
    if is_lift:
        props.append('is_lift = true')
    if is_stairs:
        props.append('is_stairs = true')
    if is_phone:
        props.append('is_phone = true')
    if is_sink:
        props.append('is_sink = true')
    if is_locked:
        props.append('is_locked_door = true')
    if is_door and not is_lift and not is_stairs and not is_phone:
        props.append(f'open_angle = {open_angle}')
    node(name, "StaticBody3D", parent, props)

    dmat = door_mat if door_mat else M_WOOD_DOOR
    shp_sid = add_sub(f"Shp_{name}", "BoxShape3D", [f'size = Vector3({width}, {height}, 0.1)'])
    mesh_sid = add_sub(f"Mesh_{name}", "BoxMesh", [f'size = Vector3({width}, {height}, 0.1)'])

    node(f"CollisionShape3D", "CollisionShape3D", f"{parent}/{name}", [
        f'transform = {tf(width/2.0, height/2.0, 0)}',
        f'shape = SubResource("{shp_sid}")',
    ])
    node("Mesh", "MeshInstance3D", f"{parent}/{name}", [
        f'transform = {tf(width/2.0, height/2.0, 0)}',
        f'mesh = SubResource("{mesh_sid}")',
        f'material_override = SubResource("{dmat}")',
    ])

def sink_static(name, parent, px, py, pz, sx, sy, sz):
    """Emit a StaticBody3D interactable sink with CollisionShape and Mesh."""
    props = [
        f'transform = {tf(px, py, pz)}',
        'collision_layer = 2',
        f'script = ExtResource("2_interactable")',
        'prompt_message = "Sink (Get Wet Towel)"',
        'is_sink = true',
        'can_feel = false',
    ]
    node(name, "StaticBody3D", parent, props)

    shp_sid = add_sub(f"Shp_{name}", "BoxShape3D", [f'size = Vector3({sx}, {sy}, {sz})'])
    mesh_sid = add_sub(f"Mesh_{name}", "BoxMesh", [f'size = Vector3({sx}, {sy}, {sz})'])

    node("CollisionShape3D", "CollisionShape3D", f"{parent}/{name}", [
        f'shape = SubResource("{shp_sid}")',
    ])
    node("Mesh", "MeshInstance3D", f"{parent}/{name}", [
        f'mesh = SubResource("{mesh_sid}")',
        f'material_override = SubResource("{M_TILE_WHITE}")',
    ])

def tree_static(name, parent, px, py, pz):
    """Emit a static tree with a trunk and foliage."""
    # Trunk
    csg_box(f"{name}_Trunk", parent, px, py + 1.0, pz, 0.25, 2.0, 0.25, M_WOOD_PROP)
    # Foliage
    csg_box(f"{name}_Leaves", parent, px, py + 2.5, pz, 1.8, 1.8, 1.8, M_ASSEMBLY, collision=False)

def streetlight_static(name, parent, px, py, pz):
    """Emit a static streetlight with a post, head, and active light source."""
    # Post
    csg_box(f"{name}_Post", parent, px, py + 2.0, pz, 0.1, 4.0, 0.1, M_SIGN_POST)
    # Head
    csg_box(f"{name}_Head", parent, px, py + 4.1, pz, 0.5, 0.2, 0.5, M_FLOOR_NUM, collision=False)
    # Light source
    omni_light(f"{name}_Light", parent, px, py + 3.8, pz, 1.5, color(1.0, 0.9, 0.7), omni_range=12.0)

def smoke_particle(name, parent, px, py, pz, col=(0.15,0.15,0.15,0.6),
                   vel=0.5, spread=40, lifetime=3.0, is_fire=False):
    """Emit a dynamic CPUParticles3D for high visibility and realistic animation."""
    if is_fire:
        props = [
            f'transform = {tf(px, py, pz)}',
            'amount = 50',
            f'lifetime = {lifetime}',
            'mesh = SubResource("Mesh_FireParticle")',
            'emission_shape = 1', # Sphere
            'emission_sphere_radius = 0.4',
            'direction = Vector3(0, 1, 0)',
            f'spread = {spread}',
            'gravity = Vector3(0, 3.0, 0)',
            f'initial_velocity_min = {vel * 0.8}',
            f'initial_velocity_max = {vel * 1.6}',
            'angular_velocity_min = -90.0',
            'angular_velocity_max = 90.0',
            'angle_min = -180.0',
            'angle_max = 180.0',
            'scale_amount_min = 0.6',
            'scale_amount_max = 1.4',
            'scale_amount_curve = SubResource("Curve_FireScale")',
            'color_ramp = SubResource("Grad_Fire")',
            'local_coords = true',
        ]
        node(name, "CPUParticles3D", parent, props)

        # Add a fire hazard Area3D trigger to detect and penalize player when they stand in it
        area_name = f"{name}_Hazard"
        node(area_name, "Area3D", parent, [
            f'transform = {tf(px, py + 0.6, pz)}',
            'collision_mask = 1',
            'script = ExtResource("8_fire_area")',
        ])
        shp_fire = add_sub(f"Shp_{area_name}", "BoxShape3D", ['size = Vector3(1.2, 1.2, 1.2)'])
        node("CollisionShape3D", "CollisionShape3D", f"{parent}/{area_name}", [
            f'shape = SubResource("{shp_fire}")',
        ])
    else:
        props = [
            f'transform = {tf(px, py, pz)}',
            'amount = 60',
            f'lifetime = {lifetime}',
            'mesh = SubResource("Mesh_SmokeParticle")',
            'emission_shape = 1', # Sphere
            'emission_sphere_radius = 0.8',
            'direction = Vector3(0, 1, 0)',
            f'spread = {spread}',
            'gravity = Vector3(0, 0.8, 0)',
            f'initial_velocity_min = {vel * 0.4}',
            f'initial_velocity_max = {vel * 1.0}',
            'angular_velocity_min = -25.0',
            'angular_velocity_max = 25.0',
            'angle_min = -180.0',
            'angle_max = 180.0',
            'scale_amount_min = 0.6',
            'scale_amount_max = 1.8',
            'scale_amount_curve = SubResource("Curve_SmokeScale")',
            'color_ramp = SubResource("Grad_Smoke")',
            'local_coords = true',
        ]
        node(name, "CPUParticles3D", parent, props)

# ─────────────────────────────────────────────────────────────────────────────
# BEGIN BUILDING NODES
# ─────────────────────────────────────────────────────────────────────────────

# ROOT
node("Level", "Node3D", "", [])

# WorldEnvironment
node("WorldEnvironment", "WorldEnvironment", ".", [
    f'environment = SubResource("{ENV}")',
])

# Directional light (night exterior)
node("DirectionalLight3D", "DirectionalLight3D", ".", [
    f'transform = Transform3D(0.866, -0.354, 0.354, 0, 0.707, 0.707, -0.5, -0.613, 0.613, 0, 15, 0)',
    f'light_color = {color(0.4, 0.5, 0.7)}',
    'light_energy = 0.8',
    'shadow_enabled = true',
])

# Alarm Audio
node("AlarmAudio", "AudioStreamPlayer", ".", [
    f'script = ExtResource("5_synth_audio")',
    'synth_type = "alarm"',
])

# Player (instanced from player.tscn)
# Starts in master bedroom. teleport_target_pos = outside assembly point
lines.append('[node name="Player" parent="." instance=ExtResource("1_player")]')
lines.append(f'transform = {tf_rot_y(-90, -4, 0.1, -7)}')
lines.append('teleport_target_pos = Vector3(-8, -22.3, 22)')
lines.append("")

# ── GEOMETRY ─────────────────────────────────────────────────────────────────
node("Geometry", "Node3D", ".", [])

# ── UNIT 8A ──────────────────────────────────────────────────────────────────
node("Unit8A", "Node3D", "Geometry", [])

G = "Geometry/Unit8A"

# --- Master Bedroom ---
node("MasterBedroom", "Node3D", G, [])
MB = G + "/MasterBedroom"
# Floor spans X = [-9.0, -2.0], Z = [-11.0, -5.0]
csg_box("Floor", MB, -5.5, -0.05, -8.0, 7.0, 0.1, 6.0, M_CARPET_MASTER)
# Ceiling spans X = [-9.0, -2.0], Z = [-11.0, -5.0]
csg_box("Ceiling", MB, -5.5, 2.75, -8.0, 7.0, 0.1, 6.0, M_DRYWALL)
# North wall spans X = [-9.0, -2.0] at Z = -11.1
csg_box("WallNorth", MB, -5.5, 1.4, -11.1, 7.0, 2.8, 0.2, M_DRYWALL)
# South wall spans X = [-6.0, -2.0] at Z = -4.9 (leaving SW corner free for Ensuite)
csg_box("WallSouth", MB, -4.0, 1.4, -4.9, 4.0, 2.8, 0.2, M_DRYWALL)
# West wall spans Z = [-11.0, -8.0] at X = -9.1
csg_box("WallWest", MB, -9.1, 1.4, -9.5, 0.2, 2.8, 3.0, M_DRYWALL)

# East wall at X = -2.0 (has door cutout at Z = [-6.5, -5.5])
# North of the door: spans Z = [-11.0, -6.5] (length 4.5)
csg_box("WallEast_N", MB, -2.0, 1.4, -8.75, 0.2, 2.8, 4.5, M_DRYWALL)
# South of the door: spans Z = [-5.5, -5.0] (length 0.5)
csg_box("WallEast_S", MB, -2.0, 1.4, -5.25, 0.2, 2.8, 0.5, M_DRYWALL)
# Above the door: spans Z = [-11.0, -5.0] (length 6.0)
csg_box("WallEast_Top", MB, -2.0, 2.4, -8.0, 0.2, 0.8, 6.0, M_DRYWALL)

# Hallway (centered at X = -0.5, Z = [-11.0, -5.0])
node("Hallway", "Node3D", G, [])
HW = G + "/Hallway"
# Floor spans X = [-2.0, 1.0], Z = [-11.0, -5.0]
csg_box("Floor", HW, -0.5, -0.05, -8.0, 3.0, 0.1, 6.0, M_WOOD_FLOOR)
# Ceiling spans X = [-2.0, 1.0], Z = [-11.0, -5.0]
csg_box("Ceiling", HW, -0.5, 2.75, -8.0, 3.0, 0.1, 6.0, M_DRYWALL2)
# North wall spans X = [-2.0, 1.0] at Z = -11.1
csg_box("WallNorth", HW, -0.5, 1.4, -11.1, 3.0, 2.8, 0.2, M_DRYWALL2)

# Smoke drifting into Hallway from Living Room
smoke_particle("HallwaySmoke", HW, -0.5, 2.5, -8.0, vel=0.2, lifetime=4.0)

# Props in Master Bedroom
csg_box("Bed", MB, -4.6, 0.3, -9.4, 1.8, 0.6, 2.2, M_WOOD_PROP, collision=True)
csg_box("BedMattress", MB, -4.6, 0.62, -9.4, 1.7, 0.15, 2.1, M_FABRIC, collision=False)
csg_box("Desk", MB, -7.8, 0.4, -9.8, 1.2, 0.8, 1.4, M_WOOD_PROP)
csg_box("Chair", MB, -7.8, 0.4, -8.5, 0.6, 0.8, 0.6, M_FABRIC)

# Light smoke seeping into Master Bedroom
smoke_particle("MasterBedroomSmoke", MB, -5.5, 2.5, -8.0, vel=0.15, lifetime=3.5)

# Bedroom door (on East wall at X = -2.0, spanning Z = [-6.5, -5.5])
door_static("BedroomDoor", G, -2.0, 0, -6.0,
            is_hot=False, can_feel=True, open_angle=-90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Master Bedroom Light
omni_light("BedroomLight", MB, -5.5, 2.5, -8.0, 1.5, color(1.0, 0.95, 0.85),
           flicker=True, fl_min=1.2, fl_max=1.8, fl_speed=5.0)

# --- Bedroom 2 ---
node("Bedroom2", "Node3D", G, [])
B2 = G + "/Bedroom2"
# Floor spans X = [1.0, 5.5], Z = [-11.0, -5.0]
csg_box("Floor", B2, 3.25, -0.05, -8.0, 4.5, 0.1, 6.0, M_CARPET_BED2)
# Ceiling spans X = [1.0, 5.5], Z = [-11.0, -5.0]
csg_box("Ceiling", B2, 3.25, 2.75, -8.0, 4.5, 0.1, 6.0, M_DRYWALL)
# North wall spans X = [1.0, 5.5] at Z = -11.1
csg_box("WallNorth", B2, 3.25, 1.4, -11.1, 4.5, 2.8, 0.2, M_DRYWALL)
# South wall spans X = [1.0, 5.5] at Z = -4.9 (with door cutout at X = [2.0, 3.0])
# West of the door: spans X = [1.0, 2.0] (width 1.0)
csg_box("WallSouth_W", B2, 1.5, 1.4, -4.9, 1.0, 2.8, 0.2, M_DRYWALL)
# East of the door: spans X = [3.0, 5.5] (width 2.5)
csg_box("WallSouth_E", B2, 4.25, 1.4, -4.9, 2.5, 2.8, 0.2, M_DRYWALL)
# Above the door: spans X = [1.0, 5.5] (width 4.5)
csg_box("WallSouth_Top", B2, 3.25, 2.4, -4.9, 4.5, 0.8, 0.2, M_DRYWALL)
# West wall spans Z = [-11.0, -5.0] at X = 1.0 (separates from Hallway)
csg_box("WallWest", B2, 1.0, 1.4, -8.0, 0.2, 2.8, 6.0, M_DRYWALL)
# East wall at X = 5.5 (separates from Common Bathroom, has door cutout at Z = [-6.5, -5.5])
# North of the door: spans Z = [-11.0, -6.5] (length 4.5)
csg_box("WallEast_N", B2, 5.5, 1.4, -8.75, 0.2, 2.8, 4.5, M_DRYWALL)
# South of the door: spans Z = [-5.5, -5.0] (length 0.5)
csg_box("WallEast_S", B2, 5.5, 1.4, -5.25, 0.2, 2.8, 0.5, M_DRYWALL)
# Above the door: spans Z = [-11.0, -5.0] (length 6.0)
csg_box("WallEast_Top", B2, 5.5, 2.4, -8.0, 0.2, 0.8, 6.0, M_DRYWALL)

# Props in Bedroom 2
csg_box("Bed2", B2, 4.6, 0.3, -10.0, 1.6, 0.6, 2.0, M_WOOD_PROP)
csg_box("Desk2", B2, 1.6, 0.4, -10.0, 1.0, 0.8, 1.6, M_WOOD_PROP)

# Light smoke seeping into Bedroom 2
smoke_particle("Bedroom2Smoke", B2, 3.25, 2.5, -8.0, vel=0.15, lifetime=3.5)

# Bedroom 2 door (on South wall at Z = -5.0, centered at X = 2.5)
door_static("Bedroom2Door", G, 2.5, 0, -5.0,
            is_hot=False, can_feel=True, open_angle=-90.0,
            door_mat=M_WOOD_DOOR, rot_y=180)

# Bedroom 2 Light
omni_light("Bedroom2Light", B2, 3.25, 2.5, -8.0, 1.4, color(1.0, 0.95, 0.85),
           flicker=True, fl_min=1.1, fl_max=1.6, fl_speed=5.0)

# --- Common Bathroom ---
node("CommonBathroom", "Node3D", G, [])
CB = G + "/CommonBathroom"
# Floor spans X = [5.5, 9.0], Z = [-11.0, -5.0]
csg_box("Floor", CB, 7.25, -0.05, -8.0, 3.5, 0.1, 6.0, M_TILE_WHITE)
# Ceiling spans X = [5.5, 9.0], Z = [-11.0, -5.0]
csg_box("Ceiling", CB, 7.25, 2.75, -8.0, 3.5, 0.1, 6.0, M_TILE_WHITE)
# North wall spans X = [5.5, 9.0] at Z = -11.1
csg_box("WallNorth", CB, 7.25, 1.4, -11.1, 3.5, 2.8, 0.2, M_TILE_WHITE)
# South wall spans X = [5.5, 9.0] at Z = -4.9
csg_box("WallSouth", CB, 7.25, 1.4, -4.9, 3.5, 2.8, 0.2, M_TILE_WHITE)

# Light smoke seeping into Common Bathroom
smoke_particle("CommonBathroomSmoke", CB, 7.25, 2.5, -8.0, vel=0.15, lifetime=3.5)
# East wall spans Z = [-11.0, -5.0] at X = 9.1
csg_box("WallEast", CB, 9.1, 1.4, -8.0, 0.2, 2.8, 6.0, M_TILE_WHITE)
# Props in Common Bathroom
csg_box("Toilet", CB, 8.0, 0.35, -9.5, 0.5, 0.7, 0.7, M_TILE_WHITE)
sink_static("Sink", CB, 6.5, 0.8, -9.5, 0.4, 0.1, 0.5)

# Bathroom door (on West wall at X = 5.5, spanning Z = [-6.5, -5.5])
door_static("BathroomDoor", G, 5.5, 0, -6.0,
            is_hot=False, can_feel=False, open_angle=-90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Bathroom Light
omni_light("BathroomLight", CB, 7.25, 2.5, -8.0, 1.5, color(1.0, 1.0, 1.0),
           flicker=True, fl_min=1.2, fl_max=1.6, fl_speed=6.0)

# --- En Suite ---
node("EnsuiteBath", "Node3D", G, [])
ES = G + "/EnsuiteBath"
# Floor spans X = [-9.0, -6.0], Z = [-8.0, -5.0] (inside Master Bedroom)
csg_box("Floor", ES, -7.5, -0.05, -6.5, 3.0, 0.1, 3.0, M_TILE_WHITE)
# Ceiling spans X = [-9.0, -6.0], Z = [-8.0, -5.0] (inside Master Bedroom)
csg_box("Ceiling", ES, -7.5, 2.75, -6.5, 3.0, 0.1, 3.0, M_TILE_WHITE)
# North wall spans X = [-9.0, -6.0] at Z = -8.1
csg_box("WallNorth", ES, -7.5, 1.4, -8.1, 3.0, 2.8, 0.2, M_TILE_WHITE)
# South wall spans X = [-9.0, -6.0] at Z = -4.9
csg_box("WallSouth", ES, -7.5, 1.4, -4.9, 3.0, 2.8, 0.2, M_TILE_WHITE)
# East wall at X = -6.0 (has door cutout at Z = [-6.5, -5.5])
# North of the door: spans Z = [-8.0, -6.5] (length 1.5)
csg_box("WallEast_N", ES, -6.0, 1.4, -7.25, 0.2, 2.8, 1.5, M_TILE_WHITE)
# South of the door: spans Z = [-5.5, -5.0] (length 0.5)
csg_box("WallEast_S", ES, -6.0, 1.4, -5.25, 0.2, 2.8, 0.5, M_TILE_WHITE)
# Above the door: spans Z = [-8.0, -5.0] (length 3.0)
csg_box("WallEast_Top", ES, -6.0, 2.4, -6.5, 0.2, 0.8, 3.0, M_TILE_WHITE)
# West wall spans Z = [-8.0, -5.0] at X = -9.1
csg_box("WallWest", ES, -9.1, 1.4, -6.5, 0.2, 2.8, 3.0, M_TILE_WHITE)

# Props in Ensuite Bathroom
csg_box("Toilet", ES, -8.5, 0.35, -7.5, 0.5, 0.7, 0.7, M_TILE_WHITE)
sink_static("EnsuiteSink", ES, -7.0, 0.8, -7.5, 0.4, 0.1, 0.5)

# Ensuite door (on East wall at X = -6.0, spanning Z = [-6.5, -5.5])
door_static("EnsuiteDoor", G, -6.0, 0, -6.0,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Ensuite Light
omni_light("EnsuiteLight", ES, -7.5, 2.5, -6.5, 1.5, color(1.0, 1.0, 1.0),
           flicker=True, fl_min=1.2, fl_max=1.6, fl_speed=6.0)

# --- Living / Dining ---
node("LivingDining", "Node3D", G, [])
LV = G + "/LivingDining"
# Floor spans X = [-5.0, 4.0], Z = [-5.0, 1.0]
csg_box("Floor", LV, -0.5, -0.05, -2.0, 9.0, 0.1, 6.0, M_WOOD_FLOOR)
# Ceiling spans X = [-5.0, 4.0], Z = [-5.0, 1.0]
csg_box("Ceiling", LV, -0.5, 2.75, -2.0, 9.0, 0.1, 6.0, M_DRYWALL2)

# South wall with front door cutout at X = [-0.5, 0.5] and balcony door cutout at X = [2.5, 3.5]
# Left of front door: spans X = [-5.0, -0.5] (width 4.5)
csg_box("WallSouth_W", LV, -2.75, 1.4, 1.0, 4.5, 2.8, 0.2, M_DRYWALL2)
# Foyer to Balcony segment: spans X = [0.5, 2.5] (width 2.0)
csg_box("WallSouth_Mid", LV, 1.5, 1.4, 1.0, 2.0, 2.8, 0.2, M_DRYWALL2)
# East of balcony door: spans X = [3.5, 4.0] (width 0.5)
csg_box("WallSouth_E", LV, 3.75, 1.4, 1.0, 0.5, 2.8, 0.2, M_DRYWALL2)
# Above doors: spans X = [-5.0, 4.0] (width 9.0)
csg_box("WallSouth_Top", LV, -0.5, 2.4, 1.0, 9.0, 0.8, 0.2, M_DRYWALL2)

# Balcony door (leads to Balcony, at Z = 1.0, centered at X = 3.0)
door_static("BalconyDoor", G, 3.0, 0, 1.0,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR)

# Props in Living Room
# Sofa placed clear of the utility door (centered at X = -3.5, Z = -0.5)
csg_box("Sofa", LV, -3.5, 0.4, -0.5, 2.0, 0.8, 0.8, M_FABRIC)
csg_box("SofaBack", LV, -3.5, 0.95, -0.1, 2.0, 0.5, 0.2, M_FABRIC)
csg_box("DiningTable", LV, 2.0, 0.4, -1.5, 1.6, 0.8, 1.0, M_CHARRED)
# TV Unit against the west wall, north of utility door (Z = -4.3)
csg_box("TVUnit", LV, -4.0, 0.3, -4.3, 1.8, 0.6, 0.4, M_WOOD_PROP)
csg_box("TVScreen", LV, -4.0, 0.95, -4.4, 1.2, 0.7, 0.1, M_CHARRED)

# Fire Spread in Living Room (from Kitchen)
smoke_particle("LivingRoomFire1", LV, 2.0, 0.8, -1.5, is_fire=True)
smoke_particle("LivingRoomFire2", LV, 3.5, 0.5, -2.5, is_fire=True)
omni_light("LivingRoomFireGlow", LV, 2.0, 1.2, -1.5, 4.0, color(1.0, 0.35, 0.0),
           flicker=True, fl_min=2.5, fl_max=5.5, fl_speed=22.0, shadow=True, omni_range=7.0)

# Dense Smoke in Living Room Ceiling
smoke_particle("LivingRoomSmoke1", LV, 2.0, 2.5, -1.5, vel=0.3, lifetime=4.5)
smoke_particle("LivingRoomSmoke2", LV, -2.0, 2.5, -1.5, vel=0.25, lifetime=5.0)
smoke_particle("LivingRoomSmoke3", LV, 0.0, 2.5, 0.5, vel=0.25, lifetime=4.5)

# Living Room Light
omni_light("LivingLight", LV, -0.5, 2.5, -2.0, 1.6, color(1.0, 0.95, 0.88),
           flicker=True, fl_min=1.3, fl_max=1.8, fl_speed=4.0)

# Fire extinguisher in living room
node("FireExtinguisher", "StaticBody3D", G, [
    f'transform = {tf(-3.8, 0.8, -0.2)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "Fire extinguisher — [E] Use (PASS method: Pull, Aim, Squeeze, Sweep)"',
    'can_feel = false',
])
node("CollisionShape3D", "CollisionShape3D", G + "/FireExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'shape = SubResource("{SHP_EXTINGUISH}")',
])
node("Mesh", "MeshInstance3D", G + "/FireExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'mesh = SubResource("{SHP_EXTINGUISH}")',
    f'material_override = SubResource("{M_PHONE_BOX}")',
])

# Unit Front Door (at Z = 1.0, centered at X = 0.0)
door_static("UnitFrontDoor", G, 0.0, 0, 1.0,
            is_hot=False, can_feel=True, open_angle=90.0,
            door_mat=M_WOOD_DOOR)

# Kitchen door (on East wall of Living Room at X = 4.0, spanning Z = [-3.0, -2.0])
door_static("KitchenDoor", G, 4.0, 0, -2.5,
            is_hot=True, can_feel=True, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Utility door (on West wall of Living Room at X = -5.0, spanning Z = [-3.0, -2.0])
door_static("UtilityDoor", G, -5.0, 0, -2.5,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# --- Kitchen (fire room) ---
node("Kitchen", "Node3D", G, [])
KT = G + "/Kitchen"
# Floor spans X = [4.0, 9.0], Z = [-5.0, 1.0]
csg_box("Floor", KT, 6.5, -0.05, -2.0, 5.0, 0.1, 6.0, M_KITCHEN_FLOOR)
# Ceiling spans X = [4.0, 9.0], Z = [-5.0, 1.0]
csg_box("Ceiling", KT, 6.5, 2.75, -2.0, 5.0, 0.1, 6.0, M_CHARRED)
# South wall spans X = [4.0, 9.0] at Z = 1.1
csg_box("WallSouth", KT, 6.5, 1.4, 1.1, 5.0, 2.8, 0.2, M_CHARRED)
# East wall spans Z = [-5.0, 1.0] at X = 9.1
csg_box("WallEast", KT, 9.1, 1.4, -2.0, 0.2, 2.8, 6.0, M_CHARRED)
# Kitchen Counter
csg_box("Counter", KT, 6.5, 0.9, -2.0, 1.0, 0.9, 3.0, M_CHARRED)

# West wall at X = 4.0 (separates from Living Room, has door cutout at Z = [-3.0, -2.0])
# North of the door: spans Z = [-5.0, -3.0] (length 2.0)
csg_box("WallWest_N", KT, 4.0, 1.4, -4.0, 0.2, 2.8, 2.0, M_DRYWALL)
# South of the door: spans Z = [-2.0, 1.0] (length 3.0)
csg_box("WallWest_S", KT, 4.0, 1.4, -0.5, 0.2, 2.8, 3.0, M_DRYWALL)
# Above the door: spans Z = [-5.0, 1.0] (length 6.0)
csg_box("WallWest_Top", KT, 4.0, 2.4, -2.0, 0.2, 0.8, 6.0, M_DRYWALL)

# Fire Glow & Audio
omni_light("FireGlow", KT, 6.5, 1.5, -2.0, 5.0, color(1.0, 0.3, 0.0),
           flicker=True, fl_min=3.0, fl_max=7.0, fl_speed=20.0, shadow=True, omni_range=8.0)
omni_light("FireGlow2", KT, 6.5, 0.8, -1.5, 3.5, color(1.0, 0.4, 0.0),
           flicker=True, fl_min=2.0, fl_max=5.0, fl_speed=18.0)

smoke_particle("FireParticle1", KT, 5.5, 0.5, -2.0, is_fire=True)
smoke_particle("FireParticle2", KT, 6.5, 0.5, -2.5, is_fire=True)
smoke_particle("FireParticle3", KT, 6.5, 0.5, -1.5, is_fire=True)

smoke_particle("SmokeParticle1", KT, 5.5, 2.5, -2.0)
smoke_particle("SmokeParticle2", KT, 6.5, 2.5, -2.5)

node("FireCrackle", "AudioStreamPlayer3D", KT, [
    f'transform = {tf(6.5, 1.0, -2.0)}',
    'max_distance = 12.0',
    f'script = ExtResource("6_synth_audio_3d")',
    'synth_type = "fire_crackle"',
])

# --- Utility ---
node("Utility", "Node3D", G, [])
UT = G + "/Utility"
# Floor spans X = [-9.0, -5.0], Z = [-5.0, 1.0]
csg_box("Floor", UT, -7.0, -0.05, -2.0, 4.0, 0.1, 6.0, M_CONCRETE)
# Ceiling spans X = [-9.0, -5.0], Z = [-5.0, 1.0]
csg_box("Ceiling", UT, -7.0, 2.75, -2.0, 4.0, 0.1, 6.0, M_DRYWALL)
# South wall spans X = [-9.0, -5.0] at Z = 1.1
csg_box("WallSouth", UT, -7.0, 1.4, 1.1, 4.0, 2.8, 0.2, M_DRYWALL)
# West wall spans Z = [-5.0, 1.0] at X = -9.1
csg_box("WallWest", UT, -9.1, 1.4, -2.0, 0.2, 2.8, 6.0, M_DRYWALL)

omni_light("UtilityLight", UT, -7.0, 2.5, -2.0, 0.8, color(0.9, 0.9, 1.0),
           flicker=True, fl_min=0.6, fl_max=1.0, fl_speed=5.0)

# Light smoke seeping into Utility Room
smoke_particle("UtilitySmoke", UT, -7.0, 2.5, -2.0, vel=0.15, lifetime=3.5)

# East wall at X = -5.0 (separates from Living Room, has door cutout at Z = [-3.0, -2.0])
# North of the door: spans Z = [-5.0, -3.0] (length 2.0)
csg_box("WallEast_N", UT, -5.0, 1.4, -4.0, 0.2, 2.8, 2.0, M_DRYWALL)
# South of the door: spans Z = [-2.0, 1.0] (length 3.0)
csg_box("WallEast_S", UT, -5.0, 1.4, -0.5, 0.2, 2.8, 3.0, M_DRYWALL)
# Above the door: spans Z = [-5.0, 1.0] (length 6.0)
csg_box("WallEast_Top", UT, -5.0, 2.4, -2.0, 0.2, 0.8, 6.0, M_DRYWALL)

# Props in Utility Room
# Washing machine against North wall
csg_box("WashingMachine", UT, -8.3, 0.45, -4.5, 0.7, 0.9, 0.7, M_TILE_WHITE)
csg_box("WashingMachineDoor", UT, -8.3, 0.45, -4.12, 0.4, 0.4, 0.05, M_DRYWALL2, collision=False)
# Dryer next to washing machine
csg_box("Dryer", UT, -7.4, 0.45, -4.5, 0.7, 0.9, 0.7, M_TILE_WHITE)
csg_box("DryerDoor", UT, -7.4, 0.45, -4.12, 0.4, 0.4, 0.05, M_DRYWALL2, collision=False)
# Shelf unit against West wall
csg_box("Shelf_Bottom", UT, -8.85, 0.5, -1.5, 0.3, 0.05, 2.0, M_WOOD_PROP)
csg_box("Shelf_Mid", UT, -8.85, 1.1, -1.5, 0.3, 0.05, 2.0, M_WOOD_PROP)
csg_box("Shelf_Top", UT, -8.85, 1.7, -1.5, 0.3, 0.05, 2.0, M_WOOD_PROP)
csg_box("Shelf_Post_L", UT, -8.85, 1.0, -0.55, 0.05, 2.0, 0.05, M_WOOD_PROP)
csg_box("Shelf_Post_R", UT, -8.85, 1.0, -2.45, 0.05, 2.0, 0.05, M_WOOD_PROP)
# Laundry basket in South-West corner
csg_box("LaundryBasket", UT, -8.5, 0.3, 0.55, 0.6, 0.6, 0.5, M_FABRIC)

# --- Foyer ---
node("Foyer", "Node3D", G, [])
FY = G + "/Foyer"
# Floor spans X = [-1.5, 1.5], Z = [1.0, 3.5]
csg_box("Floor", FY, 0.0, -0.05, 2.25, 3.0, 0.1, 2.5, M_WOOD_FLOOR)
csg_box("Ceiling", FY, 0.0, 2.75, 2.25, 3.0, 0.1, 2.5, M_DRYWALL2)
csg_box("WallWest", FY, -1.6, 1.4, 2.25, 0.2, 2.8, 2.5, M_DRYWALL2)
csg_box("WallEast", FY, 1.6, 1.4, 2.25, 0.2, 2.8, 2.5, M_DRYWALL2)

# Smoke filling the Foyer from Living Room
smoke_particle("FoyerSmoke", FY, 0.0, 2.5, 2.25, vel=0.2, lifetime=4.0)

# --- Balcony ---
node("Balcony", "Node3D", G, [])
BL = G + "/Balcony"
# Floor spans X = [1.5, 4.5], Z = [1.0, 3.5]
csg_box("Floor", BL, 3.0, -0.05, 2.25, 3.0, 0.1, 2.5, M_OUTDOOR_TILE)
# Railings (south and east)
csg_box("RailSouth", BL, 3.0, 0.5, 3.55, 3.0, 1.0, 0.1, M_RAILING, collision=True)
csg_box("RailEast", BL, 4.55, 0.5, 2.25, 0.1, 1.0, 2.5, M_RAILING, collision=True)

# Warning sign prop
node("BalconySign", "StaticBody3D", G, [
    f'transform = {tf(3.0, 1.5, 3.55)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "Do not jump — assembly point is 8 floors below. Use the fire stairwell!"',
    'can_feel = false',
])
node("Mesh", "MeshInstance3D", G + "/BalconySign", [
    f'mesh = SubResource("Shp_BalconySign")',
    f'material_override = SubResource("{M_BALCONY_SIGN}")',
])
# Redefine BalconySign shape sub-resource
add_sub("Shp_BalconySign", "BoxMesh", ['size = Vector3(1.5, 0.4, 0.05)'])

# ── SHARED CORRIDOR ───────────────────────────────────────────────────────────
node("SharedCorridor", "Node3D", "Geometry", [])
SC = "Geometry/SharedCorridor"

# Corridor Floor spans Z = [3.5, 6.5] - extended to X = -10.1
csg_box("CorridorFloor", SC, 2.45, -0.05, 5.0, 25.1, 0.1, 3.0, M_CARPET_CORRIDOR)
csg_box("CorridorCeiling", SC, 2.45, 2.85, 5.0, 25.1, 0.1, 3.0, M_DRYWALL)

# North wall split around foyer opening (X = [-1.5, 1.5])
# West segment: X = [-10.1, -1.5] (width 8.6)
csg_box("WallNorth_W", SC, -5.8, 1.4, 3.4, 8.6, 2.8, 0.2, M_DRYWALL)
# East segments split around Unit 8B door (X = [10.5, 11.5]) and Unit 8C door (X = [13.5, 14.5]):
# Segment 1 (foyer to 8B door): X = [1.5, 10.5] (width 9.0)
csg_box("WallNorth_E1", SC, 6.0, 1.4, 3.4, 9.0, 2.8, 0.2, M_DRYWALL)
# Above Unit 8B Door: X = [10.5, 11.5] (width 1.0, Y = [2.0, 2.8])
csg_box("WallNorth_E_8B_Top", SC, 11.0, 2.4, 3.4, 1.0, 0.8, 0.2, M_DRYWALL)
# Segment 2 (between 8B and 8C doors): X = [11.5, 13.5] (width 2.0)
csg_box("WallNorth_E2", SC, 12.5, 1.4, 3.4, 2.0, 2.8, 0.2, M_DRYWALL)
# Above Unit 8C Door: X = [13.5, 14.5] (width 1.0, Y = [2.0, 2.8])
csg_box("WallNorth_E_8C_Top", SC, 14.0, 2.4, 3.4, 1.0, 0.8, 0.2, M_DRYWALL)
# Segment 3 (8C door to lobby wall): X = [14.5, 15.0] (width 0.5)
csg_box("WallNorth_E3", SC, 14.75, 1.4, 3.4, 0.5, 2.8, 0.2, M_DRYWALL)

csg_box("WallSouth", SC, 2.45, 1.4, 6.6, 25.1, 2.8, 0.2, M_DRYWALL)

# Smoke Area (covers corridor)
node("SmokeArea", "Area3D", SC, [
    f'transform = {tf(3, 1.25, 5.0)}',
    'collision_mask = 1',
    f'script = ExtResource("3_smoke_area")',
])
shp_smoke = add_sub("Shp_SmokeArea", "BoxShape3D", ['size = Vector3(22, 1.5, 2.8)'])
node("CollisionShape3D", "CollisionShape3D", f"{SC}/SmokeArea", [
    f'shape = SubResource("{shp_smoke}")',
])
# Smoke particles in corridor
smoke_particle("CorridorSmoke1", SC, -1, 1.5, 5.0, col=(0.18,0.15,0.12,0.4), vel=0.25, spread=60, lifetime=4.0)
smoke_particle("CorridorSmoke2", SC, 5,  1.5, 5.0, col=(0.15,0.13,0.10,0.35), vel=0.2, spread=55, lifetime=4.5)
smoke_particle("CorridorSmoke3", SC, 10, 1.5, 5.0, col=(0.16,0.14,0.11,0.3), vel=0.2, spread=50, lifetime=4.0)

# Corridor lights (emergency green flicker)
for i, cx in enumerate([-1, 5, 10]):
    omni_light(f"CorrLight_{i+1}", SC, cx, 2.7, 5.0, 0.5,
               color(0.9, 1.0, 0.9), flicker=True, fl_min=0.4, fl_max=0.6, fl_speed=3.0)

# Exit signs on ceiling
node("ExitSigns", "Node3D", SC, [])
for i, cx in enumerate([0, 5, 10]):
    csg_box(f"ExitSign_{i+1}", f"{SC}/ExitSigns", cx, 2.82, 5.0, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# Corridor extinguisher (south wall)
node("CorridorExtinguisher", "StaticBody3D", SC, [
    f'transform = {tf(-2, 0.8, 6.4)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "[E] Fire extinguisher — Pull pin, Aim low, Squeeze, Sweep side to side"',
    'can_feel = false',
])
node("CollisionShape3D", "CollisionShape3D", f"{SC}/CorridorExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'shape = SubResource("{SHP_EXTINGUISH}")',
])
node("Mesh", "MeshInstance3D", f"{SC}/CorridorExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'mesh = SubResource("{SHP_EXTINGUISH}")',
    f'material_override = SubResource("{M_PHONE_BOX}")',
])

# Unlocked, interactable door for the new neighbor unit (Unit 8B) at X = 11.0, leading into Unit 8B room
door_static("Unit8B_CorridorDoor", SC, 11.0, 0, 3.4,
            is_door=True, is_locked=False, can_feel=True,
            open_angle=90.0, door_mat=M_WOOD_DOOR,
            prompt="Unit 8B Door — [E] Open")

# Locked decorative Unit 8C door shifted to X = 14.0
door_static("Unit8C_CorridorDoor", SC, 14.0, 0, 3.4,
            is_door=False, is_locked=True, can_feel=False,
            open_angle=90.0, door_mat=M_WOOD_DOOR,
            prompt="Unit 8C — locked")

# ── UNIT 8B (NEIGHBOUR UNIT) ─────────────────────────────────────────────────
# Layout  (all Y referenced from floor Y=0):
#   Living / Dining (open plan): X=[9.0,14.5], Z=[-2.5, 3.35] (5.5m × 5.85m)
#   Bedroom:                     X=[9.0,12.0], Z=[-7.5,-2.5]  (3.0m × 5.0m)
#   Bathroom:                    X=[12.0,14.5],Z=[-7.5,-2.5]  (2.5m × 5.0m)
#   South wall = shared with corridor north wall (already built above)
node("Unit8B", "Node3D", "Geometry", [])
U8B = "Geometry/Unit8B"

# ── Floors & Ceilings ──
csg_box("LivingFloor",    U8B,  11.75, -0.05,  0.425, 5.5, 0.1, 5.85, M_WOOD_FLOOR)
csg_box("LivingCeiling",  U8B,  11.75,  2.75,  0.425, 5.5, 0.1, 5.85, M_DRYWALL2)
csg_box("BedFloor",       U8B,  10.5,  -0.05, -5.0,   3.0, 0.1, 5.0,  M_CARPET_BED2)
csg_box("BedCeiling",     U8B,  10.5,   2.75, -5.0,   3.0, 0.1, 5.0,  M_DRYWALL2)
csg_box("BathFloor",      U8B,  13.25, -0.05, -5.0,   2.5, 0.1, 5.0,  M_TILE_WHITE)
csg_box("BathCeiling",    U8B,  13.25,  2.75, -5.0,   2.5, 0.1, 5.0,  M_DRYWALL2)

# ── Outer Walls ──
# North wall (Z = -7.5, exterior face)
csg_box("WallNorth", U8B, 11.75, 1.4, -7.6, 5.5, 2.8, 0.2, M_DRYWALL2)
# West wall (X = 9.0, exterior face) — spans Z=[-7.5, 3.35]
csg_box("WallWest",  U8B,  8.9,  1.4, -2.05, 0.2, 2.8, 10.9, M_DRYWALL2)
# East wall (X = 14.5, exterior face)
csg_box("WallEast",  U8B, 14.6,  1.4, -2.05, 0.2, 2.8, 10.9, M_DRYWALL2)

# ── Interior Partition: Living ↔ Bedroom / Bathroom (Z = -2.5) ──
# West segment: X=[9.0,10.5] (no door here)
csg_box("PartW",       U8B,  9.75, 1.4, -2.5, 1.5, 2.8, 0.2, M_DRYWALL2)
# Lintel above bedroom door opening X=[10.5,11.5]
csg_box("PartDoorTop", U8B, 11.0,  2.4, -2.5, 1.0, 0.8, 0.2, M_DRYWALL2)
# East segment: X=[11.5,14.5]
csg_box("PartE",       U8B, 13.0,  1.4, -2.5, 3.0, 2.8, 0.2, M_DRYWALL2)

# Bedroom door — hinge at X=10.5, swings northward into bedroom (-90°)
door_static("U8B_BedroomDoor", U8B, 11.0, 0, -2.5,
            is_door=True, is_locked=False, can_feel=False,
            open_angle=-90.0, door_mat=M_WOOD_DOOR, rot_y=0,
            prompt="Bedroom — [E] Open")

# ── Wall between Bedroom and Bathroom (X = 12.0) ──
csg_box("BedBathWall", U8B, 12.0, 1.4, -5.0, 0.2, 2.8, 5.0, M_DRYWALL2)

# ── Furniture: Living / Dining ──
csg_box("U8B_Sofa",      U8B, 10.5,  0.4,  -0.5, 2.0, 0.8, 0.8, M_FABRIC)
csg_box("U8B_SofaBack",  U8B, 10.5,  0.95, -0.1, 2.0, 0.5, 0.2, M_FABRIC)
csg_box("U8B_Coffee",    U8B, 10.5,  0.3,   0.8, 1.0, 0.4, 0.5, M_WOOD_PROP)
csg_box("U8B_TVUnit",    U8B,  9.7,  0.3,  -2.0, 1.4, 0.6, 0.4, M_WOOD_PROP)
csg_box("U8B_TVScreen",  U8B,  9.7,  0.9,  -2.1, 1.0, 0.65,0.1, M_CONCRETE_DARK)
csg_box("U8B_DinTable",  U8B, 13.5,  0.4,   1.0, 1.4, 0.8, 0.8, M_WOOD_PROP)
csg_box("U8B_DinChair1", U8B, 13.0,  0.4,   0.3, 0.5, 0.8, 0.5, M_WOOD_PROP)
csg_box("U8B_DinChair2", U8B, 14.0,  0.4,   0.3, 0.5, 0.8, 0.5, M_WOOD_PROP)
# Kitchen counter along east wall
csg_box("U8B_Counter",   U8B, 14.1,  0.9,  -1.0, 0.8, 0.9, 3.0, M_TILE_WHITE)
csg_box("U8B_CounterTop",U8B, 14.1,  0.95, -1.0, 0.9, 0.05,3.2, M_MARBLE)

# ── Furniture: Bedroom ──
csg_box("U8B_Bed",      U8B, 10.5,  0.3, -6.0, 2.2, 0.6, 1.8, M_FABRIC)
csg_box("U8B_BedPillow",U8B, 10.5,  0.65,-5.25,1.6, 0.15,0.4, M_DRYWALL2)
csg_box("U8B_Bedside",  U8B,  9.4,  0.4, -5.3, 0.5, 0.8, 0.5, M_WOOD_PROP)
csg_box("U8B_Wardrobe", U8B, 11.6,  1.2, -7.2, 0.7, 2.4, 1.2, M_WOOD_DOOR)
csg_box("U8B_Desk",     U8B,  9.8,  0.4, -3.2, 1.2, 0.8, 0.6, M_WOOD_PROP)

# ── Furniture: Bathroom ──
csg_box("U8B_Toilet",   U8B, 12.5,  0.4, -7.0, 0.5, 0.8, 0.7, M_TILE_WHITE)
csg_box("U8B_Sink",     U8B, 13.5,  0.9, -7.1, 0.6, 0.9, 0.4, M_TILE_WHITE)
csg_box("U8B_Bathtub",  U8B, 14.0,  0.3, -5.5, 0.8, 0.6, 1.8, M_TILE_WHITE)

# ── Lights ──
omni_light("U8B_LivingLight",  U8B, 11.75, 2.5,  0.45,  1.6, color(1.0, 0.95, 0.88),
           flicker=True, fl_min=1.1, fl_max=1.5, fl_speed=3.0)
omni_light("U8B_BedLight",     U8B, 10.5,  2.5, -5.0,   1.0, color(0.9, 0.88, 1.0))
omni_light("U8B_BathLight",    U8B, 13.25, 2.5, -5.0,   0.8, color(0.95, 0.95, 1.0))

# ── Exit sign inside Unit 8B pointing toward the door ──
csg_box("U8B_ExitSign", U8B, 11.0, 2.5, -2.1, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# ── Smoke Area for Unit 8B (light seepage from corridor) ──
node("U8B_SmokeArea", "Area3D", U8B, [
    f'transform = {tf(11.75, 1.25, 0.45)}',
    'collision_mask = 1',
    f'script = ExtResource("3_smoke_area")',
])
shp_u8b_smoke = add_sub("Shp_U8B_Smoke", "BoxShape3D", ['size = Vector3(5.5, 1.5, 5.8)'])
node("CollisionShape3D", "CollisionShape3D", f"{U8B}/U8B_SmokeArea", [
    f'shape = SubResource("{shp_u8b_smoke}")',
])
# Light ceiling smoke seeping under the door from the corridor
smoke_particle("U8B_Smoke1", U8B, 11.0, 2.4, 1.5, vel=0.1, lifetime=5.0)
smoke_particle("U8B_Smoke2", U8B, 11.75, 2.4, -0.5, vel=0.08, lifetime=6.0)

# ── ELEVATOR LOBBY ───────────────────────────────────────────────────────────
node("ElevatorLobby", "Node3D", "Geometry", [])
EL = "Geometry/ElevatorLobby"

csg_box("LobbyFloor", EL, 18.0, -0.05, 5.0, 6.0, 0.1, 5.0, M_MARBLE)
csg_box("LobbyCeiling", EL, 18.0, 2.85, 5.0, 6.0, 0.1, 5.0, M_DRYWALL)
csg_box("LobbyWallNorth", EL, 18.0, 1.4, 2.4, 6.0, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallEast", EL, 21.1, 1.4, 5.0, 0.2, 2.8, 5.0, M_DRYWALL)

# West walls to seal lobby side voids around corridor opening (Z = [3.5, 6.5])
csg_box("LobbyWallWest_N", EL, 14.9, 1.4, 3.0, 0.2, 2.8, 1.0, M_DRYWALL)
csg_box("LobbyWallWest_S", EL, 14.9, 1.4, 7.0, 0.2, 2.8, 1.0, M_DRYWALL)

# Split LobbyWallSouth around Lift A and Lift B doors (at X=16.6 and X=19.4, width 1.2m each)
csg_box("LobbyWallSouth_Left", EL, 15.5, 1.4, 7.5, 1.0, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth_Mid", EL, 18.0, 1.4, 7.5, 1.6, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth_Right", EL, 20.5, 1.4, 7.5, 1.0, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth_Top", EL, 18.0, 2.4, 7.5, 6.0, 0.8, 0.2, M_DRYWALL)

# Lift Cabin floors and enclosure walls
# Each cabin is now 2.2m wide x 2.8m deep (interior) — much more spacious
# Interior Z: 7.5 (door face) to 10.3 (back wall face); center = 8.9
csg_box("LiftFloor",       EL, 18.0, -0.05, 8.9, 4.0, 0.1, 2.8, M_MARBLE)
csg_box("LiftCeiling",     EL, 18.0,  2.85, 8.9, 4.0, 0.1, 2.8, M_DRYWALL)
csg_box("LiftWallBack",    EL, 18.0,  1.4,  10.4, 4.4, 2.8, 0.2, M_DRYWALL)
csg_box("LiftWallLeft",    EL, 15.9,  1.4,  8.9, 0.2, 2.8, 2.8, M_DRYWALL)
csg_box("LiftWallRight",   EL, 20.1,  1.4,  8.9, 0.2, 2.8, 2.8, M_DRYWALL)
csg_box("LiftWallDivider", EL, 18.0,  1.4,  8.9, 0.2, 2.8, 2.8, M_DRYWALL)

omni_light("LobbyLight", EL, 18, 2.5, 5.0, 1.2, color(0.92, 0.95, 0.92),
           flicker=True, fl_min=0.9, fl_max=1.3, fl_speed=4.0)

# Lift A
door_static("LiftA", EL, 16.6, 0, 7.5,
            is_lift=True, is_door=False, can_feel=False,
            door_mat=M_LIFT_DOOR, width=1.2, height=2.0,
            prompt="[E] Press lift button — DANGER during fire!")

# Lift B  
door_static("LiftB", EL, 19.4, 0, 7.5,
            is_lift=True, is_door=False, can_feel=False,
            door_mat=M_LIFT_DOOR, width=1.2, height=2.0,
            prompt="[E] Press lift button — DANGER during fire!")

# Elevator cabin area (trigger) — centered inside the deeper cabins
node("ElevatorCabinArea", "Area3D", EL, [
    f'transform = {tf(18, 1.0, 9.5)}',
    'collision_mask = 1',
    f'script = ExtResource("7_elevator")',
])
node("CollisionShape3D", "CollisionShape3D", f"{EL}/ElevatorCabinArea", [
    f'shape = SubResource("{SHP_CABIN}")',
])

# Warning sign
csg_box("WarnSign", EL, 20.8, 1.8, 4.5, 0.8, 0.4, 0.05, M_WARN_SIGN, collision=False)

# Lobby hum audio
node("ElevatorHum", "AudioStreamPlayer3D", EL, [
    f'transform = {tf(18, 1.5, 5.0)}',
    'max_distance = 6.0',
    f'script = ExtResource("6_synth_audio_3d")',
    'synth_type = "elevator_hum"',
])

# Cabin light — repositioned to centre of the now-deeper cabin
omni_light("CabinLight", EL, 18, 2.5, 8.9, 1.2, color(0.85, 0.92, 1.0))

# ── STAIRWELL ────────────────────────────────────────────────────────────────
node("Stairwell", "Node3D", "Geometry", [])
SW = "Geometry/Stairwell"

# Stairwell shaft walls
shaft_h = 26.0
shaft_cx = -12.5
shaft_cy = -10.0  # Center Y

# Shaft North, South (split), East (split), West walls
csg_box("ShaftWallNorth", SW, shaft_cx, shaft_cy, -4.9, 4.6, shaft_h, 0.3, M_CONCRETE)
csg_box("ShaftWallWest", SW, -14.9, shaft_cy, 0.5, 0.3, shaft_h, 10.6, M_CONCRETE)

# Split South wall around Ground exit door (at X = -12.5, Y = [-22.4, -20.4], Z = 5.9)
csg_box("ShaftWallSouth_Below", SW, -12.5, -22.7, 5.9, 4.6, 0.6, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth_Above", SW, -12.5, -8.7, 5.9, 4.6, 23.4, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth_West", SW, -13.9, -21.4, 5.9, 1.8, 2.0, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth_East", SW, -11.1, -21.4, 5.9, 1.8, 2.0, 0.3, M_CONCRETE)

# Split East wall around Level 8 entry fire door (at X = -10.1, Y = [0.0, 2.0], Z = [4.5, 5.5])
csg_box("ShaftWallEast_Below", SW, -10.1, -11.5, 0.5, 0.3, 23.0, 10.6, M_CONCRETE)
csg_box("ShaftWallEast_Above", SW, -10.1, 2.5, 0.5, 0.3, 1.0, 10.6, M_CONCRETE)
csg_box("ShaftWallEast_North", SW, -10.1, 1.0, -0.15, 0.3, 2.0, 9.3, M_CONCRETE)
csg_box("ShaftWallEast_South", SW, -10.1, 1.0, 5.65, 0.3, 2.0, 0.3, M_CONCRETE)

# Fire door (Level 8 entry) - aligned to East wall cutout at Z = 5.0, X = -10.1
door_static("FireDoor_L8", SW, -10.1, 0, 5.0,
            is_hot=False, can_feel=True, open_angle=90.0,
            door_mat=M_STEEL_DOOR, rot_y=90,
            prompt="Fire Exit — Feel door before opening [F]")

# Exit sign above fire door - parallel to Z axis aligned to East wall at X = -10.1
csg_box("ExitSignFireDoor", SW, -10.1, 2.5, 5.0, 0.05, 0.3, 0.6, M_EXIT_SIGN, collision=False)

# Shaft ceiling (roof) and bottom floor
csg_box("ShaftRoof", SW, shaft_cx, 2.75, 0.5, 4.8, 0.1, 10.6, M_CONCRETE)
csg_box("ShaftFloor", SW, shaft_cx, -22.45 - 0.05, 0.5, 4.8, 0.1, 10.6, M_CONCRETE_DARK)


import math

# Parameters
FLOOR_HEIGHT = 2.8
FLIGHT_Z_LEN = 6.0   # horizontal run per flight
LANDING_DEPTH = 2.4
STAIR_WIDTH = 4.8    # Expanded to 4.8m to perfectly span the entire shaft width

# Generate landings L8 down to Ground (9 landings: L8 to L1 and Ground)
for floor_idx in range(9):
    floor_num = 8 - floor_idx
    y_land = -(floor_idx * FLOOR_HEIGHT)
    
    # Alternate Z position for switchback
    if floor_idx % 2 == 0:
        z_land = 4.7   # even landings (L8, L6, L4, L2, Ground)
    else:
        z_land = -3.7  # odd landings (L7, L5, L3, L1)
        
    landing_name = f"Landing_L{floor_num}" if floor_idx < 8 else "Landing_Ground"
    node(landing_name, "Node3D", SW, [])
    lnd = f"{SW}/{landing_name}"
    
    csg_box("Floor", lnd, shaft_cx, y_land - 0.05, z_land, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE_DARK)
    csg_box("Ceiling", lnd, shaft_cx, y_land + 2.75, z_land, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE)
    
    # Floor number sign
    sign_z = z_land - 0.9 if (floor_idx % 2 == 0) else z_land + 0.9  # placed relative to landing
    csg_box("FloorSign", lnd, shaft_cx, y_land + 1.4, sign_z, 0.4, 0.6, 0.05, M_FLOOR_NUM, collision=False)
    
    # Emergency light
    omni_light("EmergLight", lnd, shaft_cx, y_land + 2.6, z_land, 0.8,
               color(0.8, 1.0, 0.8), flicker=True, fl_min=0.6, fl_max=0.9, fl_speed=4.0)
    
    # Exit sign above going back to corridor (only L8)
    if floor_idx == 0:
        csg_box("ExitSignBack", lnd, shaft_cx, y_land + 2.5, 5.0, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

    # Stair flight descending from this landing (8 flights: L8->L7 down to L1->Ground)
    if floor_idx < 8:
        flight_name = f"Flight_L{floor_num}_to_L{floor_num-1}" if floor_idx < 7 else "Flight_L1_to_Ground"
        node(flight_name, "Node3D", SW, [])
        flt = f"{SW}/{flight_name}"
        
        # Determine direction: even floors go north, odd go south
        z_sign = 1 if (floor_idx % 2 == 0) else -1
        rot_deg = z_sign * 25.01689  # Slope angle for 2.8m drop over 6.0m run
        
        y_ramp = y_land - FLOOR_HEIGHT / 2
        flt_z_center = 0.5
        flt_len = math.sqrt(FLIGHT_Z_LEN**2 + FLOOR_HEIGHT**2)
        
        STAIR_WIDTH_HALF = 2.4   # Widen each flight to perfectly cover one half of the 4.8m shaft
        if floor_idx % 2 == 0:
            ramp_cx = -13.7
        else:
            ramp_cx = -11.3

        props = [
            f'transform = {tf_rot_x(rot_deg, ramp_cx, y_ramp, flt_z_center)}',
            'use_collision = true',
            f'size = Vector3({STAIR_WIDTH_HALF}, 0.2, {flt_len:.2f})',
            f'material = SubResource("{M_ANTISLIP}")',
        ]
        node("Ramp", "CSGBox3D", flt, props)
        
        # Handrails - rotated properly with the ramp
        node("HandrailL", "CSGBox3D", flt, [
            f'transform = {tf_rot_x(rot_deg, ramp_cx - STAIR_WIDTH_HALF/2.0 + 0.05, y_ramp + 0.9, flt_z_center)}',
            f'size = Vector3(0.05, 0.05, {flt_len:.2f})',
            f'material = SubResource("{M_RAILING}")',
        ])
        node("HandrailR", "CSGBox3D", flt, [
            f'transform = {tf_rot_x(rot_deg, ramp_cx + STAIR_WIDTH_HALF/2.0 - 0.05, y_ramp + 0.9, flt_z_center)}',
            f'size = Vector3(0.05, 0.05, {flt_len:.2f})',
            f'material = SubResource("{M_RAILING}")',
        ])

# Ground exit door - aligned to South wall cutout at Z = 5.9, X = -12.5, Y = -22.4
door_static("GroundExitDoor", SW, shaft_cx, -22.4, 5.9,
            is_stairs=True, is_door=True, can_feel=False,
            door_mat=M_GREEN_DOOR, rot_y=0,
            prompt="GROUND FLOOR — [E] Exit to Assembly Point")

# Exit sign above ground exit door
csg_box("GroundExitSign", SW, shaft_cx, -22.4 + 2.3, 4.2, 1.0, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# NPCs (Evacuating residents descending stairs)
# NPC 1 starts on L7 landing (waypoint index 2) - East side
node("Evacuee_L7", "CharacterBody3D", SW, [
    f'transform = {tf(-11.3, -2.7, -3.7)}',
    'collision_layer = 4',
    'collision_mask = 3',
    f'script = ExtResource("9_npc")',
    'start_waypoint = 2',
])

# NPC 2 starts on L5 landing (waypoint index 6) - East side
node("Evacuee_L5", "CharacterBody3D", SW, [
    f'transform = {tf(-11.3, -8.3, -3.7)}',
    'collision_layer = 4',
    'collision_mask = 3',
    f'script = ExtResource("9_npc")',
    'start_waypoint = 6',
])

# NPC 3 starts on L3 landing (waypoint index 10) - East side
node("Evacuee_L3", "CharacterBody3D", SW, [
    f'transform = {tf(-11.3, -13.9, -3.7)}',
    'collision_layer = 4',
    'collision_mask = 3',
    f'script = ExtResource("9_npc")',
    'start_waypoint = 10',
])

# NPC 4 starts on L2 landing (waypoint index 12) - West side
node("Evacuee_L2", "CharacterBody3D", SW, [
    f'transform = {tf(-13.7, -16.7, 4.7)}',
    'collision_layer = 4',
    'collision_mask = 3',
    f'script = ExtResource("9_npc")',
    'start_waypoint = 12',
])


# ── OUTSIDE ──────────────────────────────────────────────────────────────────
node("Outside", "Node3D", ".", [])
OUT = "Outside"

# Huge Street / driveway covering all voids
csg_box("StreetFloor", OUT, 0, -22.6, 15, 80, 0.1, 60, M_ASPHALT)

# Condo Tower main building block (floors 1-7 below the level 8 apartment)
# Positioned at Y = -11.25 (height 22.5m, sitting on Y = -22.5 street floor, extending to Y = 0.0)
# Covers X = [-10, 21] (width 31m) and Z = [-11, 7.5] (depth 18.5m)
csg_box("CondoBuildingBody", OUT, 5.5, -11.25, -1.75, 31.0, 22.5, 18.5, M_CONCRETE)

# Background Condo Tower A (West side, non-enterable decorative skyscraper)
# Positioned at Y = -2.6 (height 40m, sitting on Y = -22.6, extending to Y = 17.4)
csg_box("CondoTowerA", OUT, -35.0, -2.6, 10.0, 16.0, 40.0, 16.0, M_CONCRETE_DARK)
# Add decorative windows for Tower A on the East face (X = -27.0)
for f in range(1, 13):
    y_win = -22.6 + f * 3.0 + 0.5
    for z_win in [4.0, 10.0, 16.0]:
        csg_box(f"TowerA_Win_{f}_{int(z_win)}", OUT, -26.98, y_win, z_win, 0.05, 1.4, 1.2, M_ASPHALT, collision=False)

# Background Condo Tower B (East side, non-enterable decorative skyscraper)
# Positioned at Y = 2.4 (height 50m, sitting on Y = -22.6, extending to Y = 27.4)
csg_box("CondoTowerB", OUT, 35.0, 2.4, 20.0, 16.0, 50.0, 16.0, M_DRYWALL)
# Add decorative windows for Tower B on the West face (X = 27.0)
for f in range(1, 16):
    y_win = -22.6 + f * 3.0 + 0.5
    for z_win in [14.0, 20.0, 26.0]:
        csg_box(f"TowerB_Win_{f}_{int(z_win)}", OUT, 26.98, y_win, z_win, 0.05, 1.4, 1.2, M_ASPHALT, collision=False)

# Background Condo Tower C (North-East background tower)
# Positioned at Y = -5.1 (height 35m, sitting on Y = -22.6, extending to Y = 12.4)
csg_box("CondoTowerC", OUT, 25.0, -5.1, -18.0, 18.0, 35.0, 18.0, M_CONCRETE)
# Add decorative windows for Tower C on the South face (Z = -9.0)
for f in range(1, 11):
    y_win = -22.6 + f * 3.2 + 0.5
    for x_win in [18.0, 25.0, 32.0]:
        csg_box(f"TowerC_Win_{f}_{int(x_win)}", OUT, x_win, y_win, -8.98, 1.2, 1.4, 0.05, M_ASPHALT, collision=False)

# Add decorative windows for floors 1 to 7 on the South face (Z = 7.5)
# Y levels correspond to floor heights: -22.4 base + floor offset + window height offset
for f_idx in range(1, 8):
    y_win = -22.4 + (f_idx - 1) * 2.8 + 1.2
    for x_win in [0.0, 5.0, 10.0, 15.0]:
        csg_box(f"Window_S_{f_idx}_{int(x_win)}", OUT, x_win, y_win, 7.52, 1.2, 1.4, 0.05, M_CONCRETE_DARK, collision=False)

# Grass borders on sides of driveway to populate the void
csg_box("GrassWest", OUT, -25.0, -22.58, 15.0, 20.0, 0.05, 50.0, M_ASSEMBLY, collision=True)
csg_box("GrassEast", OUT, 25.0, -22.58, 25.0, 20.0, 0.05, 30.0, M_ASSEMBLY, collision=True)

# Trees on grass
tree_static("Tree_W1", OUT, -18.0, -22.6, 15.0)
tree_static("Tree_W2", OUT, -18.0, -22.6, 25.0)
tree_static("Tree_E1", OUT, 22.0, -22.6, 20.0)
tree_static("Tree_E2", OUT, 22.0, -22.6, 30.0)

# Streetlights along walk path and driveway
streetlight_static("Streetlight_W", OUT, -14.0, -22.6, 15.0)
streetlight_static("Streetlight_E", OUT, 14.0, -22.6, 20.0)

# Assembly point
csg_box("AssemblyZone", OUT, -8, -22.55, 22, 8, 0.05, 6, M_ASSEMBLY)
csg_box("SignPost", OUT, -8, -21.5, 20, 0.1, 2, 0.1, M_SIGN_POST)
csg_box("SignBoard", OUT, -8, -20.5, 20, 1.5, 0.8, 0.05, M_EXIT_SIGN)
omni_light("AssemblyLight", OUT, -8, -20, 22, 2.0, color(0.5, 1.0, 0.5), omni_range=10.0)

# Guard post
node("GuardPost", "StaticBody3D", OUT, [
    f'transform = {tf(-4, -22.2, 21)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "[E] Report to guard — tell them your unit and that you have evacuated."',
    'can_feel = false',
])
node("CollisionShape3D", "CollisionShape3D", f"{OUT}/GuardPost", [
    f'transform = {tf(0, 0.8, 0)}',
    f'shape = SubResource("{SHP_GUARD}")',
])
node("Mesh", "CSGBox3D", f"{OUT}/GuardPost", [
    f'transform = {tf(0, 0.8, 0)}',
    f'size = Vector3(0.5, 1.6, 0.5)',
    f'material = SubResource("{M_GUARD}")',
])

# Emergency phone
node("EmergencyPhone", "StaticBody3D", OUT, [
    f'transform = {tf(-2, -21.8, 20)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "[E] Emergency phone — Call BOMBA (999)"',
    'is_phone = true',
    'can_feel = false',
])
node("CollisionShape3D", "CollisionShape3D", f"{OUT}/EmergencyPhone", [
    f'transform = {tf(0, 0.8, 0)}',
    f'shape = SubResource("{SHP_PHONE}")',
])
node("Mesh", "CSGBox3D", f"{OUT}/EmergencyPhone", [
    f'transform = {tf(0, 0.8, 0)}',
    f'size = Vector3(0.4, 1.6, 0.4)',
    f'material = SubResource("{M_PHONE_BOX}")',
])
omni_light("PhoneLight", OUT, -2, -20.5, 20, 1.5, color(1.0, 0.3, 0.3), omni_range=4.0)

# Night directional light for exterior
node("NightLight", "DirectionalLight3D", OUT, [
    f'transform = Transform3D(1, 0, 0, 0, 0.9, 0.4, 0, -0.4, 0.9, 0, 20, 0)',
    f'light_color = {color(0.4, 0.5, 0.7)}',
    'light_energy = 0.6',
])

# ── ASSEMBLE THE FILE ────────────────────────────────────────────────────────

all_lines = []
all_lines.extend(header_lines)

# Sub-resources
for block in sub_resources:
    all_lines.extend(block)

# Nodes
all_lines.extend(lines)

content = "\n".join(all_lines)
# Clean up excessive blank lines
import re
content = re.sub(r'\n{4,}', '\n\n', content)

# Now build the correct header with load_steps count
n_ext = len(ext_resources)
n_sub = len(sub_resources)
load_steps = n_ext + n_sub + 1  # +1 for the root node
final_header = f'[gd_scene load_steps={load_steps} format=3 uid="uid://condo_firedrill_l8"]\n'
content = final_header + content

out_path = r"scenes\level.tscn"
with open(out_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Done! Written to {out_path}")
print(f"  Sub-resources: {len(sub_resources)}")
print(f"  Node lines: {len(lines)}")
