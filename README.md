# 🧯 Fire-Drill Simulation Game

[![Godot Engine](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/Platform-PC%20%7C%20Mobile%20(Android%2FiOS)-success)](https://github.com/)
[![Render Pipeline](https://img.shields.io/badge/Renderer-GL%20Compatibility-orange)](https://docs.godotengine.org/)

An interactive, 3D educational **Serious Game** designed to simulate realistic fire evacuation drills in high-rise condominium complexes. Built using **Godot Engine 4.6 (GL Compatibility)**, the simulation aligns with safety guidelines set by Malaysia's Fire and Rescue Department (**BOMBA**) to teach critical survival behaviors, hazard assessment, and decision-making during emergencies.

---

## 🎯 Project Overview & Objective

The player starts inside **Unit 8A on the 8th Floor** of a condominium as a fire breaks out in the kitchen. Heavy smoke begins seeping into the hallway, and the main exit is threatened. 

Instead of traditional action-game tropes where players rush through fire, the game teaches **realistic emergency survival protocols**:
* **Evacuate safely** while keeping exposure to heat, flames, and toxic smoke minimal.
* **Make critical safety decisions** under time pressure, balancing personal survival, rescuing others, and alert procedures.
* **Reinforce learning** through a detailed safety scorecard and an educational quiz at the end of the simulation.

---

## 🎮 Core Educational Gameplay Features

### 1. Realistic Smoke & Oxygen Mechanics
* **Stay Low (Crouching)**: Toxic smoke and gas rise, leaving a cooler, breathable air layer near the floor. Standing in smoke depletes the player's oxygen bar rapidly, triggering heavy coughing fits and screen distortion. Crouching (`C`/`Ctrl`) dramatically reduces smoke inhalation.
* **Wet Towel Protection**: Wetting a towel at the bathroom sink halves the rate of smoke inhalation or can be consumed to seal doors.
* **Door Sealing**: When trapped in a bedroom, players can seal the door gaps using a wet towel (`X`). This blocks smoke entry and secures a safe environment while waiting for rescue.
* **Vignette Indicators**: A pulsing dark-red screen vignette warns players when oxygen drops to critical levels, and a flickering orange-red overlay indicates direct thermal damage.

### 2. Physical Hazard Assessment
* **Feel Doors First**: Open doors blindly risk introducing oxygen into a burning room, causing a backdraft explosion. Players must feel doors with the back of their hand (`F`) first. If a door is hot, opening it is fatal.
* **No Elevators**: Entering the elevator triggers a power-failure sequence. The lift gets stuck, fills with smoke, and results in suffocation, demonstrating how lift shafts act like chimneys during structural fires.
* **Fire Stairs Escape**: Players must navigate through the designated fire exit doors and walk down the stairwell switchbacks.

### 3. Malaysia Emergency Dialer (Hotline: 999)
* Players can access a fully functional emergency dialer (`P` on mobile phone or using wall phones) to dial **999**.
* **Adaptive Dispatcher Tree**:
  * Route the call to **BOMBA** (Fire and Rescue Department).
  * State emergency details and locations.
  * **Dynamic Rescue Scenarios**:
    * If calling from a **Balcony**, the dispatcher sends a ladder truck, spawning a climbable yellow safety ladder.
    * If calling from a **Sealed Bedroom**, the dispatcher sends a breaching squad to extract the player.
    * If calling from the **Outdoor Assembly Point**, it logs the escape time and ends the drill in victory.

### 4. Interactive Resident Dilemmas & NPC AI
* **Panicking Neighbor (Luggage)**: An evacuating resident carries a heavy suitcase down the stairs. The player must choose to correct them (heavy luggage clogs stairwells and trips crowds) or ignore them.
* **Trapped Neighbor (Unit 8C)**: An NPC cries out behind a locked door. The player faces a dilemma: spend precious time (15 seconds and high oxygen loss) kicking the door open to save them, or instruct them to utilize their balcony exit.

### 5. P.A.S.S. Extinguisher Minigame
* Pick up fire extinguishers to combat local fire points.
* Forces players to complete the **P.A.S.S.** procedure step-by-step:
  1. **P**ull the pin
  2. **A**im at the base of the fire
  3. **S**queeze the handle
  4. **S**weep side-to-side

---

## 📊 Evaluation Scorecard & Educational Quiz

Upon successfully evacuating or securing rescue, the game displays a detailed **compliance checklist**:

| Safety Protocol Checked | Points Modifier | Educational Rationale |
| :--- | :---: | :--- |
| Felt Bedroom Door before opening | **+15** | Prevents opening a door directly into active flames. |
| Crouched / Stayed Low in smoke | **+20** | Keeps player in the cooler, breathable layer of air near the ground. |
| Checked Kitchen Door temperature | **+15** | Prevents feeding oxygen to a room fire, avoiding backdrafts. |
| Obtained Wet Towel from Bathroom | **+10** | Filters out toxic smoke particles and cools inhaled air. |
| Used Stairs instead of Lift | **+20** | Prevents getting trapped in elevator power cuts and smoke shafts. |
| Called BOMBA (999) from safe zone | **+20** | Directs rescue services to the scene with accurate reports. |
| Pulled Fire Alarm Manual Call Point | **+10** | Triggers alarms to alert the rest of the building's residents. |
| Sealed Bedroom Door with Wet Towel | **+10** | Blocks smoke seepage and secures air supply if trapped. |
| Corrected Panicking Neighbor | **+10** | Heavy luggage blocks fire evacuation routes. |
| Fire Safety Quiz Answers | **+5 / q** | Reinforces knowledge of safety protocols (e.g. PASS, smoke behavior). |
| Evacuation Time Bonus | **+5 to +15**| Rewards rapid, safe, and deliberate evacuations. |

### High Score Ledger
The game automatically stores personal bests (`best_score` and `best_time`) in a secure local config (`user://save.cfg`). Beating these records displays a celebratory **★ NEW BEST! ★** banner on the victory screen.

---

## 🛠️ Technical Highlights

### ⚡ Pure Script Sound Synthesizer
To avoid heavy audio asset footprints, sound effects are generated programmatically in real-time through Godot's audio server (`synth_audio.gd` and `synth_audio_3d.gd`):
* **Synth sounds**: Coughing fit spasms, fire crackling hums, warning tick-beeps, alarm bell oscillations, footstep impacts, and door sizzles are synthesized directly via code math.

### 📱 Mobile Optimizer & HUD
* Detects mobile platforms (`Android`/`iOS`) and dynamically switches layouts.
* Loads a custom touchscreen virtual joystick and context-sensitive touch pads.
* Runs **MobileOptimizer**: lowers particle amount (50 ➔ 12), caps particle lifetimes, disables shadow maps on lights, and adjusts physics loops to 30Hz to guarantee high frame rates on low-end mobile devices.

### 🏗️ Procedural Level Builder
* The 3D condominium level layout (`scenes/level.tscn`) is procedurally built using a dedicated Python automation script (`build_level.py`).
* Spawns CSG geometries, collision bodies, lighting flickers, smoke area boxes, waypoints, and props programmatically to maintain structured scene data.

---

## ⌨️ Control Scheme

| Action | PC Keyboard Input | Mobile Touch Control |
| :--- | :--- | :--- |
| **Move** | `W` / `A` / `S` / `D` or Arrows | Left Virtual Joystick |
| **Look Around**| Mouse Movement | Drag on Right Side of Screen |
| **Interact** | `E` / Left-Click | Contextual "Interact" Button |
| **Feel Door** | `F` | "Feel Door" Button |
| **Seal Door** | `X` (requires Wet Towel) | "Seal Door" Button |
| **Knock Door** | `K` (trapped NPCs) | "Knock" Button |
| **Sprint** | `Shift` (drains stamina) | Virtual Sprint Toggle |
| **Crouch** | `C` / `Ctrl` (toggles low stance) | Virtual Crouch Toggle |
| **Phone** | `P` (opens Emergency UI) | Virtual Phone Button |
| **Dilemmas** | `1` or `2` key selection | Interactive Dialog Buttons |
| **Toggle Objectives**| `Tab` | HUD Toggle |
| **Cycle Objectives Tab**| `O` | Switch active ending tab |
| **Pause Game**| `Escape` | Pause Icon |

---

## 📁 Directory Structure

```
FireDrill-Simulation/
├── README.md                      # Project documentation
├── fire_drill_simulation.apk      # Compiled Android test build
├── screen.png                     # Gameplay preview image
└── fire-drill-simulation/         # Godot Project Folder
    ├── project.godot              # Godot project configuration
    ├── export_presets.cfg         # Platform export parameters
    ├── build_level.py             # Python script generating the level scene
    ├── check_corridor_nodes.py    # Geometry node validation script
    ├── check_wall.py              # Wall alignment validator
    ├── verify_wall.gd             # In-engine wall collision helper
    ├── assets/                    # Soft-particles, UI textures, and shapes
    ├── scenes/                    # Main screens (.tscn files)
    │   ├── main_menu.tscn         # Game start screen
    │   ├── level.tscn             # Simulated 8th Floor Condominium level
    │   ├── mobile_hud.tscn        # Touch-control virtual joystick overlay
    │   ├── victory_screen.tscn    # Scoreboard, quiz, and metrics
    │   ├── game_over.tscn         # Tips and reload on failure
    │   └── player.tscn            # Player character capsule & camera rig
    └── scripts/                   # Game systems logic (.gd files)
        ├── game_manager.gd        # Global state and scorecard trackers
        ├── player.gd              # Movement, phone dialing, and oxygen rules
        ├── npc.gd                 # Evacuating AI resident paths & dilemmas
        ├── interactable.gd        # Door feels, water, alarms, and item pick-up
        ├── elevator.gd            # Lift entrapment failure sequence
        ├── mobile_optimizer.gd    # Dynamic mobile graphics scaler
        ├── synth_audio.gd         # Procedural sound effect synthesizer
        └── synth_audio_3d.gd      # 3D spatial procedural synthesizer
```

---

## 🚀 Getting Started (Development)

### Requirements
1. **Godot Engine 4.6** (or newer, with Compatibility Renderer support).
2. **Python 3.x** (only if regenerating the level geometries).

### Building and Running the Game
1. Clone the repository and navigate to the project directory.
2. *(Optional)* Regenerate the level scene if you changed layout attributes:
   ```bash
   python build_level.py
   ```
3. Open Godot Engine and import the project directory `fire-drill-simulation/`.
4. Press **F5** to run the project. The main menu will load, allowing you to begin the fire drill simulation.