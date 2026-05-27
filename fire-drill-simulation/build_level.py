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
SHP_CABIN     = box_shape("Shp_Cabin",     4.0, 2.0, 1.4)
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

    node(f"CollisionShape3D", "CollisionShape3D", f"{parent}/{name}", [
        f'transform = {tf(width/2.0, height/2.0, 0)}',
        f'shape = SubResource("{shp_sid}")',
    ])
    node("Mesh", "CSGBox3D", f"{parent}/{name}", [
        f'transform = {tf(width/2.0, height/2.0, 0)}',
        f'size = Vector3({width}, {height}, 0.1)',
        f'material = SubResource("{dmat}")',
    ])

def smoke_particle(name, parent, px, py, pz, col=(0.15,0.15,0.15,0.6),
                   vel=0.5, spread=40, lifetime=3.0, is_fire=False):
    """Emit a visible smoke/fire marker using a glowing CSGBox3D.
    CPUParticles3D API is complex and version-sensitive; a static
    semi-transparent glowing box is a safe cross-version stand-in."""
    if is_fire:
        mat_id = M_EXIT_SIGN  # bright green glow repurposed as fire glow marker
        # Use the flickering fire material instead
        sx, sy, sz = 0.6, 0.8, 0.6
        # Emit an OmniLight for the fire glow effect (already done in Kitchen)
        # Just add a small semi-transparent box as visual marker
        node(name, "CSGBox3D", parent, [
            f'transform = {tf(px, py, pz)}',
            f'size = Vector3({sx}, {sy}, {sz})',
            f'material = SubResource("{M_WARN_SIGN}")',
        ])
    else:
        # Smoke: a dark semi-transparent box
        node(name, "CSGBox3D", parent, [
            f'transform = {tf(px, py, pz)}',
            f'size = Vector3(0.8, 0.8, 0.8)',
            f'material = SubResource("{M_SMOKE}")',
        ])

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
lines.append(f'transform = {tf(-2, 0.1, -5)}')
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
# Floor spans X = [-6.0, -1.0], Z = [-8.0, -4.0]
csg_box("Floor", MB, -3.5, -0.05, -6.0, 5.0, 0.1, 4.0, M_CARPET_MASTER)
# Ceiling spans X = [-6.0, -1.0], Z = [-8.0, -4.0]
csg_box("Ceiling", MB, -3.5, 2.75, -6.0, 5.0, 0.1, 4.0, M_DRYWALL)
# North wall spans X = [-6.0, -1.0] at Z = -8.1
csg_box("WallNorth", MB, -3.5, 1.4, -8.1, 5.0, 2.8, 0.2, M_DRYWALL)
# South wall spans X = [-4.5, -1.0] at Z = -3.9 (avoid Ensuite south wall overlap)
csg_box("WallSouth", MB, -2.75, 1.4, -3.9, 3.5, 2.8, 0.2, M_DRYWALL)
# West wall spans Z = [-8.0, -4.0] at X = -6.1
csg_box("WallWest", MB, -6.1, 1.4, -6.0, 0.2, 2.8, 4.0, M_DRYWALL)
# East wall at X = -1.0 (has door cutout at Z = [-5.0, -4.0])
# North of the door: spans Z = [-8.0, -5.0] (length 3.0)
csg_box("WallEast_N", MB, -1.0, 1.4, -6.5, 0.2, 2.8, 3.0, M_DRYWALL)
# Above the door: spans Z = [-8.0, -4.0] (length 4.0)
csg_box("WallEast_Top", MB, -1.0, 2.4, -6.0, 0.2, 0.8, 4.0, M_DRYWALL)

# Hallway (widened and centered at X=0)
node("Hallway", "Node3D", G, [])
HW = G + "/Hallway"
# Floor spans X = [-1.0, 1.0], Z = [-8.0, -4.0]
csg_box("Floor", HW, 0.0, -0.05, -6.0, 2.0, 0.1, 4.0, M_WOOD_FLOOR)
# Ceiling spans X = [-1.0, 1.0], Z = [-8.0, -4.0]
csg_box("Ceiling", HW, 0.0, 2.75, -6.0, 2.0, 0.1, 4.0, M_DRYWALL2)
# North wall spans X = [-1.0, 1.0] at Z = -8.1
csg_box("WallNorth", HW, 0.0, 1.4, -8.1, 2.0, 2.8, 0.2, M_DRYWALL2)

# Props in Master Bedroom
csg_box("Bed", MB, -3.0, 0.3, -6.2, 1.8, 0.6, 2.2, M_WOOD_PROP, collision=True)
csg_box("BedMattress", MB, -3.0, 0.62, -6.2, 1.7, 0.15, 2.1, M_FABRIC, collision=False)
csg_box("Desk", MB, -5.2, 0.4, -4.8, 1.2, 0.8, 2.0, M_WOOD_PROP)
csg_box("Chair", MB, -4.5, 0.4, -4.8, 0.6, 0.8, 0.6, M_FABRIC)

# Bedroom door (on East wall at X = -1.0, spanning Z = [-5.0, -4.0])
door_static("BedroomDoor", G, -1.0, 0, -4.5,
            is_hot=False, can_feel=True, open_angle=-90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Master Bedroom Light
omni_light("BedroomLight", MB, -3.5, 2.5, -6.0, 1.5, color(1.0, 0.95, 0.85),
           flicker=True, fl_min=1.2, fl_max=1.8, fl_speed=5.0)

# --- Bedroom 2 ---
node("Bedroom2", "Node3D", G, [])
B2 = G + "/Bedroom2"
# Floor spans X = [1.0, 4.0], Z = [-8.0, -4.0]
csg_box("Floor", B2, 2.5, -0.05, -6.0, 3.0, 0.1, 4.0, M_CARPET_BED2)
# Ceiling spans X = [1.0, 4.0], Z = [-8.0, -4.0]
csg_box("Ceiling", B2, 2.5, 2.75, -6.0, 3.0, 0.1, 4.0, M_DRYWALL)
# North wall spans X = [1.0, 4.0] at Z = -8.1
csg_box("WallNorth", B2, 2.5, 1.4, -8.1, 3.0, 2.8, 0.2, M_DRYWALL)
# South wall spans X = [1.0, 4.0] at Z = -3.9 (with door cutout at X = [1.5, 2.5])
# West of the door: spans X = [1.0, 1.5] (width 0.5)
csg_box("WallSouth_W", B2, 1.25, 1.4, -3.9, 0.5, 2.8, 0.2, M_DRYWALL)
# East of the door: spans X = [2.5, 4.0] (width 1.5)
csg_box("WallSouth_E", B2, 3.25, 1.4, -3.9, 1.5, 2.8, 0.2, M_DRYWALL)
# Above the door: spans X = [1.0, 4.0] (width 3.0)
csg_box("WallSouth_Top", B2, 2.5, 2.4, -3.9, 3.0, 0.8, 0.2, M_DRYWALL)
# West wall spans Z = [-8.0, -4.0] at X = 1.0 (separates from Hallway)
csg_box("WallWest", B2, 1.0, 1.4, -6.0, 0.2, 2.8, 4.0, M_DRYWALL)
# East wall at X = 4.0 (separates from Common Bathroom, has door cutout at Z = [-5.0, -4.0])
# North of the door: spans Z = [-8.0, -5.0] (length 3.0)
csg_box("WallEast_N", B2, 4.0, 1.4, -6.5, 0.2, 2.8, 3.0, M_DRYWALL)
# Above the door: spans Z = [-8.0, -4.0] (length 4.0)
csg_box("WallEast_Top", B2, 4.0, 2.4, -6.0, 0.2, 0.8, 4.0, M_DRYWALL)

# Props in Bedroom 2
csg_box("Bed2", B2, 2.5, 0.3, -6.2, 1.6, 0.6, 2.0, M_WOOD_PROP)
csg_box("Desk2", B2, 3.5, 0.4, -4.8, 1.0, 0.8, 1.6, M_WOOD_PROP)

# Bedroom 2 door (on South wall at Z = -4.0, centered at X = 2.0)
door_static("Bedroom2Door", G, 2.0, 0, -4.0,
            is_hot=False, can_feel=True, open_angle=-90.0,
            door_mat=M_WOOD_DOOR)

# Bedroom 2 Light
omni_light("Bedroom2Light", B2, 2.5, 2.5, -6.0, 1.4, color(1.0, 0.95, 0.85),
           flicker=True, fl_min=1.1, fl_max=1.6, fl_speed=5.0)

# --- Common Bathroom ---
node("CommonBathroom", "Node3D", G, [])
CB = G + "/CommonBathroom"
# Floor spans X = [4.0, 6.0], Z = [-8.0, -4.0]
csg_box("Floor", CB, 5.0, -0.05, -6.0, 2.0, 0.1, 4.0, M_TILE_WHITE)
# Ceiling spans X = [4.0, 6.0], Z = [-8.0, -4.0]
csg_box("Ceiling", CB, 5.0, 2.75, -6.0, 2.0, 0.1, 4.0, M_TILE_WHITE)
# North wall spans X = [4.0, 6.0] at Z = -8.1
csg_box("WallNorth", CB, 5.0, 1.4, -8.1, 2.0, 2.8, 0.2, M_TILE_WHITE)
# South wall spans X = [4.0, 6.0] at Z = -3.9
csg_box("WallSouth", CB, 5.0, 1.4, -3.9, 2.0, 2.8, 0.2, M_TILE_WHITE)
# East wall spans Z = [-8.0, -4.0] at X = 6.1
csg_box("WallEast", CB, 6.1, 1.4, -6.0, 0.2, 2.8, 4.0, M_TILE_WHITE)
# Props in Common Bathroom
csg_box("Toilet", CB, 5.5, 0.35, -7.0, 0.5, 0.7, 0.7, M_TILE_WHITE)
csg_box("Sink", CB, 4.5, 0.8, -7.0, 0.4, 0.1, 0.5, M_TILE_WHITE)

# Bathroom door (on West wall at X = 4.0, spanning Z = [-5.0, -4.0])
door_static("BathroomDoor", G, 4.0, 0, -4.5,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Bathroom Light
omni_light("BathroomLight", CB, 5.0, 2.5, -6.0, 1.5, color(1.0, 1.0, 1.0),
           flicker=True, fl_min=1.2, fl_max=1.6, fl_speed=6.0)

# --- En Suite ---
node("EnsuiteBath", "Node3D", G, [])
ES = G + "/EnsuiteBath"
# Floor spans X = [-6.0, -4.5], Z = [-6.0, -4.0] (inside Master Bedroom)
csg_box("Floor", ES, -5.25, -0.05, -5.0, 1.5, 0.1, 2.0, M_TILE_WHITE)
# Ceiling spans X = [-6.0, -4.5], Z = [-6.0, -4.0] (inside Master Bedroom)
csg_box("Ceiling", ES, -5.25, 2.75, -5.0, 1.5, 0.1, 2.0, M_TILE_WHITE)
# North wall spans X = [-6.0, -4.5] at Z = -6.1
csg_box("WallNorth", ES, -5.25, 1.4, -6.1, 1.5, 2.8, 0.2, M_TILE_WHITE)
# South wall spans X = [-6.0, -4.5] at Z = -3.9
csg_box("WallSouth", ES, -5.25, 1.4, -3.9, 1.5, 2.8, 0.2, M_TILE_WHITE)
# East wall at X = -4.5 (has door cutout at Z = [-5.0, -4.0])
# North of the door: spans Z = [-6.0, -5.0] (length 1.0)
csg_box("WallEast_N", ES, -4.5, 1.4, -5.5, 0.2, 2.8, 1.0, M_TILE_WHITE)
# Above the door: spans Z = [-6.0, -4.0] (length 2.0)
csg_box("WallEast_Top", ES, -4.5, 2.4, -5.0, 0.2, 0.8, 2.0, M_TILE_WHITE)

# Ensuite door (on East wall at X = -4.5, spanning Z = [-5.0, -4.0])
door_static("EnsuiteDoor", G, -4.5, 0, -4.5,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Ensuite Light
omni_light("EnsuiteLight", ES, -5.25, 2.5, -5.0, 1.5, color(1.0, 1.0, 1.0),
           flicker=True, fl_min=1.2, fl_max=1.6, fl_speed=6.0)

# --- Living / Dining ---
node("LivingDining", "Node3D", G, [])
LV = G + "/LivingDining"
# Floor spans X = [-3.5, 2.5], Z = [-4.0, 0.0]
csg_box("Floor", LV, -0.5, -0.05, -2.0, 6.0, 0.1, 4.0, M_WOOD_FLOOR)
# Ceiling spans X = [-3.5, 2.5], Z = [-4.0, 0.0]
csg_box("Ceiling", LV, -0.5, 2.75, -2.0, 6.0, 0.1, 4.0, M_DRYWALL2)
# South wall with front door cutout at X = [-0.5, 0.5] and balcony door cutout at X = [1.15, 2.15]
# Left of front door: spans X = [-3.5, -0.8] (width 2.7)
csg_box("WallSouth_W", LV, -2.15, 1.4, 0.0, 2.7, 2.8, 0.2, M_DRYWALL2)
# Small segment west of front door: spans X = [-0.8, -0.5] (width 0.3)
csg_box("WallSouth_Foyer_W", LV, -0.65, 1.4, 0.0, 0.3, 2.8, 0.2, M_DRYWALL2)
# Small segment east of front door: spans X = [0.5, 0.8] (width 0.3)
csg_box("WallSouth_Foyer_E", LV, 0.65, 1.4, 0.0, 0.3, 2.8, 0.2, M_DRYWALL2)
# Small segment between Foyer and Balcony door: spans X = [0.8, 1.15] (width 0.35)
csg_box("WallSouth_Balcony_W", LV, 0.975, 1.4, 0.0, 0.35, 2.8, 0.2, M_DRYWALL2)
# Small segment east of Balcony door: spans X = [2.15, 2.5] (width 0.35)
csg_box("WallSouth_Balcony_E", LV, 2.325, 1.4, 0.0, 0.35, 2.8, 0.2, M_DRYWALL2)
# Above doors: spans X = [-3.5, 2.5] (width 6.0)
csg_box("WallSouth_Top", LV, -0.5, 2.4, 0.0, 6.0, 0.8, 0.2, M_DRYWALL2)

# Balcony door (leads to Balcony, at Z = 0.0, centered at X = 1.65)
door_static("BalconyDoor", G, 1.65, 0, 0.0,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR)

# Props in Living Room
# Sofa placed against the west wall (X = -3.5) and facing north (towards TV unit at Z = -4.0)
# Centered at X = -2.3, leaving hallway exit (X > -1.0) completely clear
csg_box("Sofa", LV, -2.3, 0.4, -2.0, 2.0, 0.8, 0.8, M_FABRIC)
csg_box("SofaBack", LV, -2.3, 0.95, -1.5, 2.0, 0.5, 0.2, M_FABRIC)
csg_box("DiningTable", LV, 1.0, 0.4, -1.5, 1.6, 0.8, 1.0, M_WOOD_PROP)
# TV Unit against the north wall (Z = -4.0)
csg_box("TVUnit", LV, -2.3, 0.3, -3.8, 1.8, 0.6, 0.4, M_WOOD_PROP)
csg_box("TVScreen", LV, -2.3, 0.95, -3.9, 1.2, 0.7, 0.1, M_CHARRED)

# Living Room Light
omni_light("LivingLight", LV, -0.5, 2.5, -2.0, 1.6, color(1.0, 0.95, 0.88),
           flicker=True, fl_min=1.3, fl_max=1.8, fl_speed=4.0)

# Fire extinguisher in living room
node("FireExtinguisher", "StaticBody3D", G, [
    f'transform = {tf(-2.8, 0.8, -0.5)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "Fire extinguisher — [E] Use (PASS method: Pull, Aim, Squeeze, Sweep)"',
    'can_feel = false',
])
node("CollisionShape3D", "CollisionShape3D", G + "/FireExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'shape = SubResource("{SHP_EXTINGUISH}")',
])
node("Mesh", "CSGBox3D", G + "/FireExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'size = Vector3(0.2, 0.6, 0.2)',
    f'material = SubResource("{M_PHONE_BOX}")',
])

# Unit Front Door (at Z = 0.0, centered at X = 0.0)
door_static("UnitFrontDoor", G, 0.0, 0, 0.0,
            is_hot=False, can_feel=True, open_angle=90.0,
            door_mat=M_WOOD_DOOR)

# Kitchen door (on East wall of Living Room at X = 2.5, spanning Z = [-2.5, -1.5])
door_static("KitchenDoor", G, 2.5, 0, -2.0,
            is_hot=True, can_feel=True, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Utility door (on West wall of Living Room at X = -3.5, spanning Z = [-2.5, -1.5])
door_static("UtilityDoor", G, -3.5, 0, -2.0,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# --- Kitchen (fire room) ---
node("Kitchen", "Node3D", G, [])
KT = G + "/Kitchen"
# Floor spans X = [2.5, 6.0], Z = [-4.0, 0.0]
csg_box("Floor", KT, 4.25, -0.05, -2.0, 3.5, 0.1, 4.0, M_KITCHEN_FLOOR)
# Ceiling spans X = [2.5, 6.0], Z = [-4.0, 0.0]
csg_box("Ceiling", KT, 4.25, 2.75, -2.0, 3.5, 0.1, 4.0, M_CHARRED)
# South wall spans X = [2.5, 6.0] at Z = 0.1
csg_box("WallSouth", KT, 4.25, 1.4, 0.1, 3.5, 2.8, 0.2, M_CHARRED)
# East wall spans Z = [-4.0, 0.0] at X = 6.1
csg_box("WallEast", KT, 6.1, 1.4, -2.0, 0.2, 2.8, 4.0, M_CHARRED)
# Kitchen Counter
csg_box("Counter", KT, 5.0, 0.9, -2.0, 1.0, 0.9, 3.0, M_CHARRED)

# West wall at X = 2.5 (separates from Living Room, has door cutout at Z = [-2.5, -1.5])
# North of the door: spans Z = [-4.0, -2.5] (length 1.5)
csg_box("WallWest_N", KT, 2.5, 1.4, -3.25, 0.2, 2.8, 1.5, M_DRYWALL)
# South of the door: spans Z = [-1.5, 0.0] (length 1.5)
csg_box("WallWest_S", KT, 2.5, 1.4, -0.75, 0.2, 2.8, 1.5, M_DRYWALL)
# Above the door: spans Z = [-4.0, 0.0] (length 4.0)
csg_box("WallWest_Top", KT, 2.5, 2.4, -2.0, 0.2, 0.8, 4.0, M_DRYWALL)

# Fire Glow & Audio
omni_light("FireGlow", KT, 4.25, 1.5, -2.0, 5.0, color(1.0, 0.3, 0.0),
           flicker=True, fl_min=3.0, fl_max=7.0, fl_speed=20.0, shadow=True, omni_range=8.0)
omni_light("FireGlow2", KT, 4.5, 0.8, -1.5, 3.5, color(1.0, 0.4, 0.0),
           flicker=True, fl_min=2.0, fl_max=5.0, fl_speed=18.0)

smoke_particle("FireParticle1", KT, 3.5, 0.5, -2.0, is_fire=True)
smoke_particle("FireParticle2", KT, 4.25, 0.5, -2.5, is_fire=True)
smoke_particle("FireParticle3", KT, 4.5, 0.5, -1.5, is_fire=True)

smoke_particle("SmokeParticle1", KT, 3.5, 2.5, -2.0)
smoke_particle("SmokeParticle2", KT, 4.5, 2.5, -2.5)

node("FireCrackle", "AudioStreamPlayer3D", KT, [
    f'transform = {tf(4.25, 1.0, -2.0)}',
    'max_distance = 12.0',
    f'script = ExtResource("6_synth_audio_3d")',
    'synth_type = "fire_crackle"',
])

# --- Utility ---
node("Utility", "Node3D", G, [])
UT = G + "/Utility"
# Floor spans X = [-6.0, -3.5], Z = [-4.0, 0.0]
csg_box("Floor", UT, -4.75, -0.05, -2.0, 2.5, 0.1, 4.0, M_CONCRETE)
# Ceiling spans X = [-6.0, -3.5], Z = [-4.0, 0.0]
csg_box("Ceiling", UT, -4.75, 2.75, -2.0, 2.5, 0.1, 4.0, M_DRYWALL)
# South wall spans X = [-6.0, -3.5] at Z = 0.1
csg_box("WallSouth", UT, -4.75, 1.4, 0.1, 2.5, 2.8, 0.2, M_DRYWALL)
# West wall spans Z = [-4.0, 0.0] at X = -6.1
csg_box("WallWest", UT, -6.1, 1.4, -2.0, 0.2, 2.8, 4.0, M_DRYWALL)

omni_light("UtilityLight", UT, -4.75, 2.5, -2.0, 0.8, color(0.9, 0.9, 1.0),
           flicker=True, fl_min=0.6, fl_max=1.0, fl_speed=5.0)

# East wall at X = -3.5 (separates from Living Room, has door cutout at Z = [-2.5, -1.5])
# North of the door: spans Z = [-4.0, -2.5] (length 1.5)
csg_box("WallEast_N", UT, -3.5, 1.4, -3.25, 0.2, 2.8, 1.5, M_DRYWALL)
# South of the door: spans Z = [-1.5, 0.0] (length 1.5)
csg_box("WallEast_S", UT, -3.5, 1.4, -0.75, 0.2, 2.8, 1.5, M_DRYWALL)
# Above the door: spans Z = [-4.0, 0.0] (length 4.0)
csg_box("WallEast_Top", UT, -3.5, 2.4, -2.0, 0.2, 0.8, 4.0, M_DRYWALL)

# --- Foyer ---
node("Foyer", "Node3D", G, [])
FY = G + "/Foyer"
csg_box("Floor", FY, 0.0, -0.05, 1.0, 1.6, 0.1, 2.0, M_WOOD_FLOOR)
csg_box("Ceiling", FY, 0.0, 2.75, 1.0, 1.6, 0.1, 2.0, M_DRYWALL2)
csg_box("WallWest", FY, -0.9, 1.4, 1.0, 0.2, 2.8, 2.0, M_DRYWALL2)
csg_box("WallEast", FY, 0.9, 1.4, 1.0, 0.2, 2.8, 2.0, M_DRYWALL2)

# --- Balcony ---
node("Balcony", "Node3D", G, [])
BL = G + "/Balcony"
# Floor spans X = [0.8, 2.5], Z = [0.0, 2.0] (south of living room, east of foyer)
csg_box("Floor", BL, 1.65, -0.05, 1.0, 1.7, 0.1, 2.0, M_OUTDOOR_TILE)
# Railings (south and east)
csg_box("RailSouth", BL, 1.65, 0.5, 2.05, 1.7, 1.0, 0.1, M_RAILING, collision=True)
csg_box("RailEast", BL, 2.55, 0.5, 1.0, 0.1, 1.0, 2.0, M_RAILING, collision=True)

# Warning sign prop
node("BalconySign", "StaticBody3D", G, [
    f'transform = {tf(1.65, 1.5, 2.05)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "Do not jump — assembly point is 8 floors below. Use the fire stairwell!"',
    'can_feel = false',
])
node("Mesh", "CSGBox3D", G + "/BalconySign", [
    f'size = Vector3(1.5, 0.4, 0.05)',
    f'material = SubResource("{M_BALCONY_SIGN}")',
])

# ── SHARED CORRIDOR ───────────────────────────────────────────────────────────
node("SharedCorridor", "Node3D", "Geometry", [])
SC = "Geometry/SharedCorridor"

csg_box("CorridorFloor", SC, 2.25, -0.05, 3.4, 22.5, 0.1, 2.8, M_CARPET_CORRIDOR)
csg_box("CorridorCeiling", SC, 2.25, 2.85, 3.4, 22.5, 0.1, 2.8, M_DRYWALL)

# North wall split around foyer opening (X = [-0.8, 0.8])
# West segment: X = [-9.0, -0.8] (width 8.2)
csg_box("WallNorth_W", SC, -4.9, 1.4, 2.0, 8.2, 2.8, 0.2, M_DRYWALL)
# East segment: X = [0.8, 13.5] (width 12.7)
csg_box("WallNorth_E", SC, 7.15, 1.4, 2.0, 12.7, 2.8, 0.2, M_DRYWALL)

csg_box("WallSouth", SC, 2.25, 1.4, 4.8, 22.5, 2.8, 0.2, M_DRYWALL)

# Smoke Area (covers corridor)
node("SmokeArea", "Area3D", SC, [
    f'transform = {tf(3, 1.25, 3.4)}',
    'collision_mask = 1',
    f'script = ExtResource("3_smoke_area")',
])
shp_smoke = add_sub("Shp_SmokeArea", "BoxShape3D", ['size = Vector3(22, 1.5, 2.6)'])
node("CollisionShape3D", "CollisionShape3D", f"{SC}/SmokeArea", [
    f'shape = SubResource("{shp_smoke}")',
])
# Smoke particles in corridor
smoke_particle("CorridorSmoke1", SC, -1, 1.5, 3.4, col=(0.18,0.15,0.12,0.4), vel=0.25, spread=60, lifetime=4.0)
smoke_particle("CorridorSmoke2", SC, 5,  1.5, 3.4, col=(0.15,0.13,0.10,0.35), vel=0.2, spread=55, lifetime=4.5)
smoke_particle("CorridorSmoke3", SC, 10, 1.5, 3.4, col=(0.16,0.14,0.11,0.3), vel=0.2, spread=50, lifetime=4.0)

# Corridor lights (emergency green flicker)
for i, cx in enumerate([-1, 5, 10]):
    omni_light(f"CorrLight_{i+1}", SC, cx, 2.7, 3.4, 0.5,
               color(0.9, 1.0, 0.9), flicker=True, fl_min=0.4, fl_max=0.6, fl_speed=3.0)

# Exit signs on ceiling
node("ExitSigns", "Node3D", SC, [])
for i, cx in enumerate([0, 5, 10]):
    csg_box(f"ExitSign_{i+1}", f"{SC}/ExitSigns", cx, 2.82, 3.4, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# Corridor extinguisher (south wall)
node("CorridorExtinguisher", "StaticBody3D", SC, [
    f'transform = {tf(-2, 0.8, 4.6)}',
    'collision_layer = 2',
    f'script = ExtResource("2_interactable")',
    'prompt_message = "[E] Fire extinguisher — Pull pin, Aim low, Squeeze, Sweep side to side"',
    'can_feel = false',
])
node("CollisionShape3D", "CollisionShape3D", f"{SC}/CorridorExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'shape = SubResource("{SHP_EXTINGUISH}")',
])
node("Mesh", "CSGBox3D", f"{SC}/CorridorExtinguisher", [
    f'transform = {tf(0, 0.3, 0)}',
    f'size = Vector3(0.2, 0.6, 0.2)',
    f'material = SubResource("{M_PHONE_BOX}")',
])

# Decorative unit doors for other units along north corridor wall (placed at X=8.0 and X=11.0, outside Unit 8A)
door_static("Unit8B_CorridorDoor", SC, 8.0, 0, 2.0,
            is_door=False, is_locked=True, can_feel=False,
            open_angle=90.0, door_mat=M_WOOD_DOOR,
            prompt="Unit 8B — locked")

door_static("Unit8C_CorridorDoor", SC, 11.0, 0, 2.0,
            is_door=False, is_locked=True, can_feel=False,
            open_angle=90.0, door_mat=M_WOOD_DOOR,
            prompt="Unit 8C — locked")

# ── ELEVATOR LOBBY ───────────────────────────────────────────────────────────
node("ElevatorLobby", "Node3D", "Geometry", [])
EL = "Geometry/ElevatorLobby"

csg_box("LobbyFloor", EL, 16.25, -0.05, 3.3, 5.5, 0.1, 5.0, M_MARBLE)
csg_box("LobbyCeiling", EL, 16.25, 2.85, 3.3, 5.5, 0.1, 5.0, M_DRYWALL)
csg_box("LobbyWallNorth", EL, 16.25, 1.4, 0.7, 5.5, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallEast", EL, 19.1, 1.4, 3.3, 0.2, 2.8, 5.0, M_DRYWALL)

# West walls to seal lobby side voids around corridor opening
csg_box("LobbyWallWest_N", EL, 13.4, 1.4, 1.4, 0.2, 2.8, 1.2, M_DRYWALL)
csg_box("LobbyWallWest_S", EL, 13.4, 1.4, 5.3, 0.2, 2.8, 1.0, M_DRYWALL)

# Split LobbyWallSouth around Lift A and Lift B doors (at X=16.0 and X=18.0, width 1.2m each)
csg_box("LobbyWallSouth_Left", EL, 14.45, 1.4, 5.9, 1.9, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth_Mid", EL, 17.0, 1.4, 5.9, 0.8, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth_Right", EL, 18.8, 1.4, 5.9, 0.4, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth_Top", EL, 16.25, 2.4, 5.9, 5.5, 0.8, 0.2, M_DRYWALL)

# Lift Cabin floors and enclosure walls
csg_box("LiftFloor", EL, 17.0, -0.05, 6.6, 4.0, 0.1, 1.6, M_MARBLE)
csg_box("LiftCeiling", EL, 17.0, 2.85, 6.6, 4.0, 0.1, 1.6, M_DRYWALL)
csg_box("LiftWallBack", EL, 17.0, 1.4, 7.5, 4.4, 2.8, 0.2, M_DRYWALL)
csg_box("LiftWallLeft", EL, 14.9, 1.4, 6.6, 0.2, 2.8, 1.6, M_DRYWALL)
csg_box("LiftWallRight", EL, 19.1, 1.4, 6.6, 0.2, 2.8, 1.6, M_DRYWALL)
csg_box("LiftWallDivider", EL, 17.0, 1.4, 6.6, 0.2, 2.8, 1.6, M_DRYWALL)

omni_light("LobbyLight", EL, 16, 2.5, 3.3, 1.2, color(0.92, 0.95, 0.92),
           flicker=True, fl_min=0.9, fl_max=1.3, fl_speed=4.0)

# Lift A
door_static("LiftA", EL, 16.0, 0, 5.9,
            is_lift=True, is_door=False, can_feel=False,
            door_mat=M_LIFT_DOOR, width=1.2, height=2.0,
            prompt="[E] Press lift button — DANGER during fire!")

# Lift B  
door_static("LiftB", EL, 18.0, 0, 5.9,
            is_lift=True, is_door=False, can_feel=False,
            door_mat=M_LIFT_DOOR, width=1.2, height=2.0,
            prompt="[E] Press lift button — DANGER during fire!")

# Elevator cabin area (trigger)
node("ElevatorCabinArea", "Area3D", EL, [
    f'transform = {tf(17, 1.0, 6.6)}',
    'collision_mask = 1',
    f'script = ExtResource("7_elevator")',
])
node("CollisionShape3D", "CollisionShape3D", f"{EL}/ElevatorCabinArea", [
    f'shape = SubResource("{SHP_CABIN}")',
])

# Warning sign
csg_box("WarnSign", EL, 19.2, 1.8, 4.5, 0.8, 0.4, 0.05, M_WARN_SIGN, collision=False)

# Lobby hum audio
node("ElevatorHum", "AudioStreamPlayer3D", EL, [
    f'transform = {tf(16, 1.5, 4.5)}',
    'max_distance = 6.0',
    f'script = ExtResource("6_synth_audio_3d")',
    'synth_type = "elevator_hum"',
])

# Cabin light
omni_light("CabinLight", EL, 17, 2.5, 6.6, 1.2, color(0.85, 0.92, 1.0))

# ── STAIRWELL ────────────────────────────────────────────────────────────────
node("Stairwell", "Node3D", "Geometry", [])
SW = "Geometry/Stairwell"

# Stairwell shaft walls (from Y = 3.0 down to Y = -23.0, total 26.0m)
shaft_h = 26.0
shaft_cx = -10
shaft_cy = -10.0  # Center Y

# Shaft North, South (split), East (split), West walls
csg_box("ShaftWallNorth", SW, shaft_cx, shaft_cy, -6.4, 4.6, shaft_h, 0.3, M_CONCRETE)
csg_box("ShaftWallWest", SW, -12.3, shaft_cy, -1.1, 0.3, shaft_h, 10.6, M_CONCRETE)

# Split South wall around Ground exit door (at X = -10.0, Y = [-22.4, -20.4], Z = 4.2)
csg_box("ShaftWallSouth_Below", SW, -10.0, -22.7, 4.2, 4.6, 0.6, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth_Above", SW, -10.0, -8.7, 4.2, 4.6, 23.4, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth_West", SW, -11.4, -21.4, 4.2, 1.8, 2.0, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth_East", SW, -8.6, -21.4, 4.2, 1.8, 2.0, 0.3, M_CONCRETE)

# Split East wall around Level 8 entry fire door (at X = -7.7, Y = [0.0, 2.0], Z = [2.9, 3.9])
csg_box("ShaftWallEast_Below", SW, -7.7, -11.5, -1.1, 0.3, 23.0, 10.6, M_CONCRETE)
csg_box("ShaftWallEast_Above", SW, -7.7, 2.5, -1.1, 0.3, 1.0, 10.6, M_CONCRETE)
csg_box("ShaftWallEast_North", SW, -7.7, 1.0, -1.75, 0.3, 2.0, 9.3, M_CONCRETE)
csg_box("ShaftWallEast_South", SW, -7.7, 1.0, 4.05, 0.3, 2.0, 0.3, M_CONCRETE)

# Fire door (Level 8 entry) - aligned to East wall cutout at Z = 3.4, X = -7.7
door_static("FireDoor_L8", SW, -7.7, 0, 3.4,
            is_hot=False, can_feel=True, open_angle=90.0,
            door_mat=M_STEEL_DOOR, rot_y=90,
            prompt="Fire Exit — Feel door before opening [F]")

# Push bar on fire door
csg_box("PushBar", SW, -7.7, 0.9, 3.4, 0.9, 0.08, 0.05, M_PUSH_BAR, collision=False)

# Exit sign above fire door
csg_box("ExitSignFireDoor", SW, -7.7, 2.5, 3.4, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# Shaft ceiling (roof) and bottom floor
csg_box("ShaftRoof", SW, shaft_cx, 2.75, -1.1, 4.6, 0.1, 10.6, M_CONCRETE)
csg_box("ShaftFloor", SW, shaft_cx, -22.45 - 0.05, -1.1, 4.6, 0.1, 10.6, M_CONCRETE_DARK)

import math

# Parameters
FLOOR_HEIGHT = 2.8
FLIGHT_Z_LEN = 6.0   # horizontal run per flight
LANDING_DEPTH = 2.0
STAIR_WIDTH = 4.3

# Generate landings L8 down to Ground (9 landings: L8 to L1 and Ground)
for floor_idx in range(9):
    floor_num = 8 - floor_idx
    y_land = -(floor_idx * FLOOR_HEIGHT)
    
    # Alternate Z position for switchback
    if floor_idx % 2 == 0:
        z_land = 2.9   # even landings (L8, L6, L4, L2, Ground)
    else:
        z_land = -5.1  # odd landings (L7, L5, L3, L1)
        
    landing_name = f"Landing_L{floor_num}" if floor_idx < 8 else "Landing_Ground"
    node(landing_name, "Node3D", SW, [])
    lnd = f"{SW}/{landing_name}"
    
    csg_box("Floor", lnd, shaft_cx, y_land - 0.05, z_land, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE_DARK)
    csg_box("Ceiling", lnd, shaft_cx, y_land + 2.75, z_land, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE)
    
    # Floor number sign
    sign_z = 2.0 + z_land if (floor_idx % 2 == 0) else z_land - 1.0  # placed relative to landing
    csg_box("FloorSign", lnd, shaft_cx, y_land + 1.4, sign_z, 0.4, 0.6, 0.05, M_FLOOR_NUM, collision=False)
    
    # Emergency light
    omni_light("EmergLight", lnd, shaft_cx, y_land + 2.6, z_land, 0.8,
               color(0.8, 1.0, 0.8), flicker=True, fl_min=0.6, fl_max=0.9, fl_speed=4.0)
    
    # Exit sign above going back to corridor (only L8)
    if floor_idx == 0:
        csg_box("ExitSignBack", lnd, shaft_cx, y_land + 2.5, 3.9, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

    # Stair flight descending from this landing (8 flights: L8->L7 down to L1->Ground)
    if floor_idx < 8:
        flight_name = f"Flight_L{floor_num}_to_L{floor_num-1}" if floor_idx < 7 else "Flight_L1_to_Ground"
        node(flight_name, "Node3D", SW, [])
        flt = f"{SW}/{flight_name}"
        
        # Determine direction: even floors go north, odd go south
        z_sign = -1 if (floor_idx % 2 == 0) else 1
        rot_deg = z_sign * 25.01689  # Slope angle for 2.8m drop over 6.0m run
        
        y_ramp = y_land - FLOOR_HEIGHT / 2
        flt_z_center = -1.1
        flt_len = math.sqrt(FLIGHT_Z_LEN**2 + FLOOR_HEIGHT**2)
        
        props = [
            f'transform = {tf_rot_x(rot_deg, shaft_cx, y_ramp, flt_z_center)}',
            'use_collision = true',
            f'size = Vector3({STAIR_WIDTH}, 0.2, {flt_len:.2f})',
            f'material = SubResource("{M_ANTISLIP}")',
        ]
        node("Ramp", "CSGBox3D", flt, props)
        
        # Handrails - rotated properly with the ramp
        node("HandrailL", "CSGBox3D", flt, [
            f'transform = {tf_rot_x(rot_deg, shaft_cx - STAIR_WIDTH/2 + 0.1, y_ramp + 0.9, flt_z_center)}',
            f'size = Vector3(0.05, 0.05, {flt_len:.2f})',
            f'material = SubResource("{M_RAILING}")',
        ])
        node("HandrailR", "CSGBox3D", flt, [
            f'transform = {tf_rot_x(rot_deg, shaft_cx + STAIR_WIDTH/2 - 0.1, y_ramp + 0.9, flt_z_center)}',
            f'size = Vector3(0.05, 0.05, {flt_len:.2f})',
            f'material = SubResource("{M_RAILING}")',
        ])

# Ground exit door - aligned to South wall cutout at Z = 4.2, X = -10.0, Y = -22.4
door_static("GroundExitDoor", SW, shaft_cx, -22.4, 4.2,
            is_stairs=True, is_door=True, can_feel=False,
            door_mat=M_GREEN_DOOR, rot_y=0,
            prompt="GROUND FLOOR — [E] Exit to Assembly Point")

# Exit sign above ground exit door
csg_box("GroundExitSign", SW, shaft_cx, -22.4 + 2.3, 4.2, 1.0, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# ── OUTSIDE ──────────────────────────────────────────────────────────────────
node("Outside", "Node3D", ".", [])
OUT = "Outside"

# Huge Street / driveway covering all voids
csg_box("StreetFloor", OUT, 0, -22.6, 15, 80, 0.1, 60, M_ASPHALT)

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
