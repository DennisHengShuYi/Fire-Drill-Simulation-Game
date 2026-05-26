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
SHP_CABIN     = box_shape("Shp_Cabin",     2.0, 2.0, 1.4)
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
    if rot_y != 0:
        tf_str = tf_rot_y(rot_y, px, py, pz)
    else:
        tf_str = tf(px, py, pz)

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
        f'transform = {tf(0, height/2, 0)}',
        f'shape = SubResource("{shp_sid}")',
    ])
    node("Mesh", "CSGBox3D", f"{parent}/{name}", [
        f'transform = {tf(0, height/2, 0)}',
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
node("Level", "Node3D", ".", [])

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
lines.append(f'transform = {tf(-3, 0.1, -6)}')
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
# Floor
csg_box("Floor", MB, -3, -0.05, -5, 6, 0.1, 5, M_CARPET_MASTER)
# Ceiling
csg_box("Ceiling", MB, -3, 2.75, -5, 6, 0.1, 5, M_DRYWALL)
# North wall (back)
csg_box("WallNorth", MB, -3, 1.4, -7.6, 6, 2.8, 0.2, M_DRYWALL)
# South wall (has door cutout toward living room) -- split around door
csg_box("WallSouth_W", MB, -4.6, 1.4, -2.4, 2.8, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth_E", MB, -0.9, 1.4, -2.4, 1.8, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth_Top", MB, -3.0, 2.35, -2.4, 6.2, 0.9, 0.2, M_DRYWALL)
# West wall
csg_box("WallWest", MB, -6.1, 1.4, -5, 0.2, 2.8, 5.2, M_DRYWALL)
# East wall (has door cutout to ensuite)
csg_box("WallEast_N", MB, 0.0, 1.4, -6.3, 0.2, 2.8, 2.6, M_DRYWALL)
csg_box("WallEast_S", MB, 0.0, 1.4, -3.1, 0.2, 2.8, 1.8, M_DRYWALL)
csg_box("WallEast_Top", MB, 0.0, 2.4, -5.0, 0.2, 0.8, 5.2, M_DRYWALL)

# Props: bed, desk
csg_box("Bed", MB, -3, 0.3, -6.2, 1.8, 0.6, 2.2, M_WOOD_PROP, collision=True)
csg_box("BedMattress", MB, -3, 0.62, -6.2, 1.7, 0.15, 2.1, M_FABRIC, collision=False)
csg_box("Desk", MB, -5.2, 0.4, -4, 1.2, 0.8, 2.0, M_WOOD_PROP)
csg_box("Chair", MB, -4.5, 0.4, -4, 0.6, 0.8, 0.6, M_FABRIC)

# Bedroom door (east wall, leading to living room)
door_static("BedroomDoor", G, -0.1, 0, -5,
            is_hot=False, can_feel=True, open_angle=-90.0,
            door_mat=M_WOOD_DOOR, rot_y=0)

# Light
omni_light("BedroomLight", MB, -3, 2.5, -5, 1.5, color(1.0, 0.95, 0.85),
           flicker=True, fl_min=1.2, fl_max=1.8, fl_speed=5.0)

# --- Bedroom 2 ---
node("Bedroom2", "Node3D", G, [])
B2 = G + "/Bedroom2"
csg_box("Floor", B2, 3, -0.05, -4, 4, 0.1, 4, M_CARPET_BED2)
csg_box("Ceiling", B2, 3, 2.75, -4, 4, 0.1, 4, M_DRYWALL)
csg_box("WallNorth", B2, 3, 1.4, -6.1, 4, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth_W", B2, 1.9, 1.4, -2.0, 1.8, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth_E", B2, 4.2, 1.4, -2.0, 1.6, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth_Top", B2, 3, 2.4, -2.0, 4.2, 0.8, 0.2, M_DRYWALL)
csg_box("WallWest", B2, 0.9, 1.4, -4, 0.2, 2.8, 4.2, M_DRYWALL)
csg_box("WallEast", B2, 5.1, 1.4, -4, 0.2, 2.8, 4.2, M_DRYWALL)
csg_box("Bed2", B2, 3, 0.3, -5.2, 1.6, 0.6, 2.0, M_WOOD_PROP)
csg_box("Desk2", B2, 4.5, 0.4, -3.5, 1.0, 0.8, 1.6, M_WOOD_PROP)

door_static("Bedroom2Door", G, 3, 0, -2.1,
            is_hot=False, can_feel=True, open_angle=-90.0,
            door_mat=M_WOOD_DOOR)

omni_light("Bedroom2Light", B2, 3, 2.5, -4, 1.4, color(1.0, 0.95, 0.85),
           flicker=True, fl_min=1.1, fl_max=1.6, fl_speed=5.0)

# --- Common Bathroom ---
node("CommonBathroom", "Node3D", G, [])
CB = G + "/CommonBathroom"
csg_box("Floor", CB, 5, -0.05, -4, 2, 0.1, 2, M_TILE_WHITE)
csg_box("Ceiling", CB, 5, 2.75, -4, 2, 0.1, 2, M_TILE_WHITE)
csg_box("WallNorth", CB, 5, 1.4, -5.1, 2, 2.8, 0.2, M_TILE_WHITE)
csg_box("WallSouth", CB, 5, 1.4, -2.9, 2, 2.8, 0.2, M_TILE_WHITE)
csg_box("WallEast", CB, 6.1, 1.4, -4, 0.2, 2.8, 2.2, M_TILE_WHITE)
csg_box("WallWest_N", CB, 3.9, 1.4, -4.8, 0.2, 2.8, 0.6, M_TILE_WHITE)
csg_box("WallWest_S", CB, 3.9, 1.4, -3.2, 0.2, 2.8, 0.8, M_TILE_WHITE)
csg_box("WallWest_Top", CB, 3.9, 2.4, -4.0, 0.2, 0.8, 2.2, M_TILE_WHITE)
csg_box("Toilet", CB, 5.5, 0.35, -4.7, 0.5, 0.7, 0.7, M_TILE_WHITE)
csg_box("Sink", CB, 4.3, 0.8, -4.7, 0.4, 0.1, 0.5, M_TILE_WHITE)

door_static("BathroomDoor", G, 4.0, 0, -4,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

omni_light("BathroomLight", CB, 5, 2.5, -4, 1.5, color(1.0, 1.0, 1.0),
           flicker=True, fl_min=1.2, fl_max=1.6, fl_speed=6.0)

# --- En Suite ---
node("EnsuiteBath", "Node3D", G, [])
ES = G + "/EnsuiteBath"
csg_box("Floor", ES, -5.5, -0.05, -3.5, 2, 0.1, 2, M_TILE_WHITE)
csg_box("Ceiling", ES, -5.5, 2.75, -3.5, 2, 0.1, 2, M_TILE_WHITE)
csg_box("WallNorth", ES, -5.5, 1.4, -4.6, 2, 2.8, 0.2, M_TILE_WHITE)
csg_box("WallSouth", ES, -5.5, 1.4, -2.4, 2, 2.8, 0.2, M_TILE_WHITE)
csg_box("WallWest", ES, -6.6, 1.4, -3.5, 0.2, 2.8, 2.2, M_TILE_WHITE)
csg_box("WallEast_N", ES, -4.4, 1.4, -4.2, 0.2, 2.8, 0.8, M_TILE_WHITE)
csg_box("WallEast_S", ES, -4.4, 1.4, -2.7, 0.2, 2.8, 0.8, M_TILE_WHITE)
csg_box("WallEast_Top", ES, -4.4, 2.4, -3.5, 0.2, 0.8, 2.2, M_TILE_WHITE)

door_static("EnsuiteDoor", G, -4.5, 0, -3.5,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

omni_light("EnsuiteLight", ES, -5.5, 2.5, -3.5, 1.5, color(1.0, 1.0, 1.0),
           flicker=True, fl_min=1.2, fl_max=1.6, fl_speed=6.0)

# --- Living / Dining ---
node("LivingDining", "Node3D", G, [])
LV = G + "/LivingDining"
csg_box("Floor", LV, 0, -0.05, -2, 8, 0.1, 4, M_WOOD_FLOOR)
csg_box("Ceiling", LV, 0, 2.75, -2, 8, 0.1, 4, M_DRYWALL2)
# Walls: north (connects to bedrooms), south (unit front wall), east (kitchen), west (utility)
csg_box("WallNorth_W", LV, -3.0, 1.4, -4.05, 2.2, 2.8, 0.2, M_DRYWALL2)
csg_box("WallNorth_E", LV, 2.8, 1.4, -4.05, 2.4, 2.8, 0.2, M_DRYWALL2)
csg_box("WallNorth_Top", LV, 0, 2.35, -4.05, 8.2, 0.9, 0.2, M_DRYWALL2)
# South wall with front door cutout
csg_box("WallSouth_W", LV, -3.5, 1.4, 0.1, 3.0, 2.8, 0.2, M_DRYWALL2)
csg_box("WallSouth_E", LV, 3.5, 1.4, 0.1, 3.0, 2.8, 0.2, M_DRYWALL2)
csg_box("WallSouth_Top", LV, 0, 2.35, 0.1, 8.2, 0.9, 0.2, M_DRYWALL2)
# East wall (kitchen side), with kitchen door cutout
csg_box("WallEast_N", LV, 4.1, 1.4, -3.5, 0.2, 2.8, 1.2, M_DRYWALL2)
csg_box("WallEast_S", LV, 4.1, 1.4, -0.7, 0.2, 2.8, 1.6, M_DRYWALL2)
csg_box("WallEast_Top", LV, 4.1, 2.4, -2.0, 0.2, 0.8, 4.2, M_DRYWALL2)
# West wall with utility door cutout
csg_box("WallWest_N", LV, -4.1, 1.4, -3.5, 0.2, 2.8, 1.2, M_DRYWALL2)
csg_box("WallWest_S", LV, -4.1, 1.4, -0.7, 0.2, 2.8, 1.6, M_DRYWALL2)
csg_box("WallWest_Top", LV, -4.1, 2.4, -2.0, 0.2, 0.8, 4.2, M_DRYWALL2)
# Props
csg_box("Sofa", LV, -2, 0.4, -2.5, 2.4, 0.8, 1.0, M_FABRIC)
csg_box("SofaBack", LV, -2, 0.95, -3.1, 2.4, 0.5, 0.2, M_FABRIC)
csg_box("DiningTable", LV, 2, 0.4, -1.5, 2.0, 0.8, 1.2, M_WOOD_PROP)
csg_box("TVUnit", LV, -3.8, 0.3, -3.8, 1.6, 0.6, 0.6, M_WOOD_PROP)
csg_box("TVScreen", LV, -3.8, 0.95, -3.85, 1.2, 0.7, 0.1, M_CHARRED)

omni_light("LivingLight", LV, 0, 2.5, -2, 1.6, color(1.0, 0.95, 0.88),
           flicker=True, fl_min=1.3, fl_max=1.8, fl_speed=4.0)

# Fire extinguisher in living room
node("FireExtinguisher", "StaticBody3D", G, [
    f'transform = {tf(-3.8, 0.8, -0.5)}',
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
    f'material = SubResource("{M_PHONE_BOX}")',  # red cylinder-ish
])

# Unit Front Door
door_static("UnitFrontDoor", G, 0, 0, 0.1,
            is_hot=False, can_feel=True, open_angle=90.0,
            door_mat=M_WOOD_DOOR)

# Kitchen door
door_static("KitchenDoor", G, 2.0, 0, -2,
            is_hot=True, can_feel=True, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# Utility door
door_static("UtilityDoor", G, -2.5, 0, -1.5,
            is_hot=False, can_feel=False, open_angle=90.0,
            door_mat=M_WOOD_DOOR, rot_y=90)

# --- Kitchen (fire room) ---
node("Kitchen", "Node3D", G, [])
KT = G + "/Kitchen"
csg_box("Floor", KT, 4, -0.05, -2, 4, 0.1, 4, M_KITCHEN_FLOOR)
csg_box("Ceiling", KT, 4, 2.75, -2, 4, 0.1, 4, M_CHARRED)
csg_box("WallNorth", KT, 4, 1.4, -4.1, 4, 2.8, 0.2, M_CHARRED)
csg_box("WallSouth", KT, 4, 1.4, 0.1, 4, 2.8, 0.2, M_CHARRED)
csg_box("WallEast", KT, 6.1, 1.4, -2, 0.2, 2.8, 4.2, M_CHARRED)
csg_box("WallWest_N", KT, 1.9, 1.4, -3.5, 0.2, 2.8, 1.2, M_CHARRED)
csg_box("WallWest_S", KT, 1.9, 1.4, -0.7, 0.2, 2.8, 1.6, M_CHARRED)
csg_box("WallWest_Top", KT, 1.9, 2.4, -2, 0.2, 0.8, 4.2, M_CHARRED)
csg_box("Counter", KT, 5.5, 0.9, -2.5, 1.0, 0.9, 3.0, M_CHARRED)

omni_light("FireGlow", KT, 4, 1.5, -2, 5.0, color(1.0, 0.3, 0.0),
           flicker=True, fl_min=3.0, fl_max=7.0, fl_speed=20.0, shadow=True, omni_range=8.0)
omni_light("FireGlow2", KT, 4.5, 0.8, -1.5, 3.5, color(1.0, 0.4, 0.0),
           flicker=True, fl_min=2.0, fl_max=5.0, fl_speed=18.0)

# Fire particles
smoke_particle("FireParticle1", KT, 3.5, 0.5, -2, is_fire=True)
smoke_particle("FireParticle2", KT, 4.0, 0.5, -2.5, is_fire=True)
smoke_particle("FireParticle3", KT, 4.5, 0.5, -1.5, is_fire=True)
# Smoke particles
smoke_particle("SmokeParticle1", KT, 3.5, 2.5, -2, col=(0.15,0.15,0.15,0.6), vel=0.5, lifetime=3.0)
smoke_particle("SmokeParticle2", KT, 4.5, 2.5, -2.5, col=(0.12,0.12,0.12,0.55), vel=0.4, lifetime=3.5)

# Fire crackle audio
node("FireCrackle", "AudioStreamPlayer3D", KT, [
    f'transform = {tf(4, 1.0, -2)}',
    'max_distance = 12.0',
    f'script = ExtResource("6_synth_audio_3d")',
    'synth_type = "fire_crackle"',
])

# --- Utility ---
node("Utility", "Node3D", G, [])
UT = G + "/Utility"
csg_box("Floor", UT, -4, -0.05, -2, 3, 0.1, 3, M_CONCRETE)
csg_box("Ceiling", UT, -4, 2.75, -2, 3, 0.1, 3, M_DRYWALL)
csg_box("WallNorth", UT, -4, 1.4, -3.6, 3, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth", UT, -4, 1.4, -0.4, 3, 2.8, 0.2, M_DRYWALL)
csg_box("WallWest", UT, -5.6, 1.4, -2, 0.2, 2.8, 3.2, M_DRYWALL)
csg_box("WallEast_N", UT, -2.4, 1.4, -3.3, 0.2, 2.8, 0.6, M_DRYWALL)
csg_box("WallEast_S", UT, -2.4, 1.4, -0.8, 0.2, 2.8, 0.8, M_DRYWALL)
csg_box("WallEast_Top", UT, -2.4, 2.4, -2, 0.2, 0.8, 3.2, M_DRYWALL)
omni_light("UtilityLight", UT, -4, 2.5, -2, 0.8, color(0.9, 0.9, 1.0),
           flicker=True, fl_min=0.6, fl_max=1.0, fl_speed=5.0)

# --- Balcony ---
node("Balcony", "Node3D", G, [])
BL = G + "/Balcony"
csg_box("Floor", BL, 4, -0.05, 0.5, 4, 0.1, 2, M_OUTDOOR_TILE)
# Railings (3 sides, no north as it connects to living room)
csg_box("RailSouth", BL, 4, 0.5, 1.6, 4.2, 1.0, 0.1, M_RAILING, collision=True)
csg_box("RailEast", BL, 6.1, 0.5, 0.5, 0.1, 1.0, 2.2, M_RAILING, collision=True)
csg_box("RailWest", BL, 1.9, 0.5, 0.5, 0.1, 1.0, 2.2, M_RAILING, collision=True)
# Warning sign prop
node("BalconySign", "StaticBody3D", G, [
    f'transform = {tf(4, 1.5, 1.7)}',
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

csg_box("CorridorFloor", SC, 3, -0.05, 1.5, 24, 0.1, 2.8, M_CARPET_CORRIDOR)
csg_box("CorridorCeiling", SC, 3, 2.85, 1.5, 24, 0.1, 2.8, M_DRYWALL)
csg_box("WallNorth", SC, 3, 1.4, 0.1, 24, 2.8, 0.2, M_DRYWALL)
csg_box("WallSouth", SC, 3, 1.4, 2.9, 24, 2.8, 0.2, M_DRYWALL)

# Smoke Area (covers corridor)
node("SmokeArea", "Area3D", SC, [
    f'transform = {tf(3, 1.25, 1.5)}',
    'collision_mask = 1',
    f'script = ExtResource("3_smoke_area")',
])
shp_smoke = add_sub("Shp_SmokeArea", "BoxShape3D", ['size = Vector3(22, 1.5, 2.6)'])
node("CollisionShape3D", "CollisionShape3D", f"{SC}/SmokeArea", [
    f'shape = SubResource("{shp_smoke}")',
])
# Smoke particles in corridor
smoke_particle("CorridorSmoke1", SC, -1, 1.5, 1.5, col=(0.18,0.15,0.12,0.4), vel=0.25, spread=60, lifetime=4.0)
smoke_particle("CorridorSmoke2", SC, 5,  1.5, 1.5, col=(0.15,0.13,0.10,0.35), vel=0.2, spread=55, lifetime=4.5)
smoke_particle("CorridorSmoke3", SC, 10, 1.5, 1.5, col=(0.16,0.14,0.11,0.3), vel=0.2, spread=50, lifetime=4.0)

# Corridor lights (emergency green flicker)
for i, cx in enumerate([-1, 5, 10]):
    omni_light(f"CorrLight_{i+1}", SC, cx, 2.7, 1.5, 0.5,
               color(0.9, 1.0, 0.9), flicker=True, fl_min=0.4, fl_max=0.6, fl_speed=3.0)

# Exit signs on ceiling
node("ExitSigns", "Node3D", SC, [])
for i, cx in enumerate([0, 5, 10]):
    csg_box(f"ExitSign_{i+1}", f"{SC}/ExitSigns", cx, 2.82, 1.5, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# Corridor extinguisher (south wall)
node("CorridorExtinguisher", "StaticBody3D", SC, [
    f'transform = {tf(-2, 0.8, 2.7)}',
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

# Decorative unit doors along north corridor wall
unit_door_positions = [(-1,0,0.1), (1,0,0.1), (3,0,0.1), (5,0,0.1), (7,0,0.1), (9,0,0.1)]
unit_door_names = ["Unit8A_CorridorDoor","Unit8B_CorridorDoor","Unit8C_CorridorDoor",
                   "Unit8D_CorridorDoor","Unit8E_CorridorDoor","Unit8F_CorridorDoor"]
for i, (dx, dy, dz) in enumerate(unit_door_positions):
    is_locked = (i > 0)  # only first is player's
    door_static(unit_door_names[i], SC, dx, dy, dz,
                is_door=not is_locked, is_locked=is_locked,
                can_feel=(i==0), open_angle=90.0, door_mat=M_WOOD_DOOR,
                prompt="" if i == 0 else f"Unit {chr(65+i+7)+str(8)} — locked")

# ── ELEVATOR LOBBY ───────────────────────────────────────────────────────────
node("ElevatorLobby", "Node3D", "Geometry", [])
EL = "Geometry/ElevatorLobby"

csg_box("LobbyFloor", EL, 16, -0.05, 1.5, 5, 0.1, 5, M_MARBLE)
csg_box("LobbyCeiling", EL, 16, 2.85, 1.5, 5, 0.1, 5, M_DRYWALL)
csg_box("LobbyWallNorth", EL, 16, 1.4, -0.6, 5, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallSouth", EL, 16, 1.4, 4.1, 5, 2.8, 0.2, M_DRYWALL)
csg_box("LobbyWallEast", EL, 19.1, 1.4, 1.5, 0.2, 2.8, 5, M_DRYWALL)

omni_light("LobbyLight", EL, 16, 2.5, 1.5, 1.2, color(0.92, 0.95, 0.92),
           flicker=True, fl_min=0.9, fl_max=1.3, fl_speed=4.0)

# Lift A
door_static("LiftA", EL, 16, 0, 4.0,
            is_lift=True, is_door=False, can_feel=False,
            door_mat=M_LIFT_DOOR, width=1.2, height=2.0,
            prompt="[E] Press lift button — DANGER during fire!")

# Lift B  
door_static("LiftB", EL, 18, 0, 4.0,
            is_lift=True, is_door=False, can_feel=False,
            door_mat=M_LIFT_DOOR, width=1.2, height=2.0,
            prompt="[E] Press lift button — DANGER during fire!")

# Elevator cabin area (trigger)
node("ElevatorCabinArea", "Area3D", EL, [
    f'transform = {tf(17, 1.0, 4.8)}',
    'collision_mask = 1',
    f'script = ExtResource("7_elevator")',
])
node("CollisionShape3D", "CollisionShape3D", f"{EL}/ElevatorCabinArea", [
    f'shape = SubResource("{SHP_CABIN}")',
])

# Warning sign
csg_box("WarnSign", EL, 19.2, 1.8, 3.5, 0.8, 0.4, 0.05, M_WARN_SIGN, collision=False)

# Lobby hum audio
node("ElevatorHum", "AudioStreamPlayer3D", EL, [
    f'transform = {tf(16, 1.5, 3.5)}',
    'max_distance = 6.0',
    f'script = ExtResource("6_synth_audio_3d")',
    'synth_type = "elevator_hum"',
])

# Cabin light
omni_light("CabinLight", EL, 17, 2.5, 4.8, 1.2, color(0.85, 0.92, 1.0))

# ── STAIRWELL ────────────────────────────────────────────────────────────────
node("Stairwell", "Node3D", "Geometry", [])
SW = "Geometry/Stairwell"

# Stairwell shaft walls (full height for all 8 floors: 8 * 2.8 = 22.4 m)
shaft_h = 8 * 2.8  # 22.4
shaft_cx = -10
shaft_cy = -shaft_h / 2  # -11.2 (center of the full shaft)
csg_box("ShaftWallNorth", SW, shaft_cx, shaft_cy, -0.65, 4.6, shaft_h, 0.3, M_CONCRETE)
csg_box("ShaftWallSouth", SW, shaft_cx, shaft_cy, 3.65, 4.6, shaft_h, 0.3, M_CONCRETE)
csg_box("ShaftWallEast", SW, -7.7, shaft_cy, 1.5, 0.3, shaft_h, 4.6, M_CONCRETE)
csg_box("ShaftWallWest", SW, -12.3, shaft_cy, 1.5, 0.3, shaft_h, 4.6, M_CONCRETE)

# Fire door (Level 8 entry)
door_static("FireDoor_L8", SW, -8, 0, 1.5,
            is_hot=False, can_feel=True, open_angle=90.0,
            door_mat=M_STEEL_DOOR, rot_y=90,
            prompt="Fire Exit — Feel door before opening [F]")

# Push bar on fire door
csg_box("PushBar", SW, -8, 0.9, 1.5, 0.9, 0.08, 0.05, M_PUSH_BAR, collision=False)

# Exit sign above fire door
csg_box("ExitSignFireDoor", SW, -8, 2.5, 1.5, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

import math

# Generate 8 landings and 8 flights (L8 to Ground)
# Switchback: flights alternate Z direction
# Flight 1: goes from z=1.5 to z=-4.0 (northward, -Z) while descending
# Flight 2: goes from z=-4.0 back to z=1.5 (southward, +Z)

# Parameters
FLOOR_HEIGHT = 2.8
FLIGHT_Z_LEN = 5.5   # horizontal run per flight
LANDING_DEPTH = 3.0
STAIR_WIDTH = 3.6

for floor_idx in range(8):  # 0=L8, 7=L1
    floor_num = 8 - floor_idx       # 8,7,6,5,4,3,2,1
    y_land = -(floor_idx * FLOOR_HEIGHT)  # landing Y for this floor
    
    # Landing
    node(f"Landing_L{floor_num}", "Node3D", SW, [])
    lnd = f"{SW}/Landing_L{floor_num}"
    csg_box("Floor", lnd, shaft_cx, y_land - 0.05, 1.5, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE_DARK)
    
    # Floor number sign on north wall
    csg_box("FloorSign", lnd, shaft_cx, y_land + 1.4, -0.5, 0.4, 0.6, 0.05, M_FLOOR_NUM, collision=False)
    
    # Emergency light
    omni_light("EmergLight", lnd, shaft_cx, y_land + 2.6, 1.5, 0.8,
               color(0.8, 1.0, 0.8), flicker=True, fl_min=0.6, fl_max=0.9, fl_speed=4.0)
    
    # Ceiling above landing
    csg_box("Ceiling", lnd, shaft_cx, y_land + 2.75, 1.5, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE)
    
    # Exit sign above going back to corridor (only L8)
    if floor_idx == 0:
        csg_box("ExitSignBack", lnd, shaft_cx, y_land + 2.5, 2.9, 0.6, 0.3, 0.05, M_EXIT_SIGN, collision=False)

    # Stair flight descending from this landing (except ground)
    if floor_idx < 7:
        node(f"Flight_L{floor_num}_to_L{floor_num-1}", "Node3D", SW, [])
        flt = f"{SW}/Flight_L{floor_num}_to_L{floor_num-1}"
        
        # Determine direction: even floors go -Z (north), odd go +Z (south)
        if floor_idx % 2 == 0:
            flt_z_center = 1.5 - FLIGHT_Z_LEN / 2 - LANDING_DEPTH / 2  # goes north
            z_sign = -1
        else:
            flt_z_center = 1.5 + FLIGHT_Z_LEN / 2 + LANDING_DEPTH / 2  # goes south
            z_sign = 1
        
        y_ramp = y_land - FLOOR_HEIGHT / 2
        rot_deg = z_sign * 28  # ~28 degrees slope for 2.8 drop over 5.5 run
        
        flt_len = math.sqrt(FLIGHT_Z_LEN**2 + FLOOR_HEIGHT**2)
        
        props = [
            f'transform = {tf_rot_x(rot_deg, shaft_cx, y_ramp, flt_z_center)}',
            'use_collision = true',
            f'size = Vector3({STAIR_WIDTH}, 0.2, {flt_len:.2f})',
            f'material = SubResource("{M_ANTISLIP}")',
        ]
        node("Ramp", "CSGBox3D", flt, props)
        
        # Handrails
        csg_box("HandrailL", flt, shaft_cx - STAIR_WIDTH/2 + 0.1, y_ramp + 0.9, flt_z_center, 0.05, 0.05, flt_len, M_RAILING, collision=False)
        csg_box("HandrailR", flt, shaft_cx + STAIR_WIDTH/2 - 0.1, y_ramp + 0.9, flt_z_center, 0.05, 0.05, flt_len, M_RAILING, collision=False)

# Ground floor landing (Level 1 exit landing, at y = -7*2.8 = -19.6)
y_ground_land = -(7 * FLOOR_HEIGHT)  # = -19.6 (this is L1 landing)

# Ground floor exit door (from stairwell to outside)
y_ground_door = -(8 * FLOOR_HEIGHT) + FLOOR_HEIGHT  # = -19.6, door at base
# Actually let's place ground exit at the very bottom
y_ground_exit = -(8 * FLOOR_HEIGHT - FLOOR_HEIGHT)
node("GroundExitLanding", "Node3D", SW, [])
gel = f"{SW}/GroundExitLanding"
csg_box("Floor", gel, shaft_cx, -22.45 - 0.05, 1.5, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE_DARK)
csg_box("Ceiling", gel, shaft_cx, -22.45 + 2.75, 1.5, STAIR_WIDTH, 0.1, LANDING_DEPTH, M_CONCRETE)
omni_light("GroundLight", gel, shaft_cx, -22.45 + 2.5, 1.5, 1.2,
           color(0.8, 1.0, 0.8), flicker=False)
csg_box("ExitSignGround", gel, shaft_cx, -22.45 + 2.5, 3.0, 0.8, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# Ground stairwell exit door
door_static("GroundExitDoor", SW, shaft_cx, -22.45, 4.0,
            is_stairs=True, is_door=True, can_feel=False,
            door_mat=M_GREEN_DOOR,
            prompt="GROUND FLOOR — [E] Exit to Assembly Point")
csg_box("GroundExitSign", SW, shaft_cx, -22.45 + 2.3, 4.1, 1.0, 0.3, 0.05, M_EXIT_SIGN, collision=False)

# ── OUTSIDE ──────────────────────────────────────────────────────────────────
node("Outside", "Node3D", ".", [])
OUT = "Outside"

# Street / driveway
csg_box("StreetFloor", OUT, 0, -22.6, 30, 50, 0.1, 30, M_ASPHALT)

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
