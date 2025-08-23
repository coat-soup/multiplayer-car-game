# 🚀 Voidburn
*An immersive online co-op space combat experience*

Voidburn is an ambitious multiplayer space simulation game where you and your crew work together to operate a massive space carrier, engaging in intense combat while managing complex ship systems. Experience the thrill of coordinated teamwork as you battle enemies, explore dangerous nebulae, and frantically repair critical systems to keep your ship operational.

![Godot Engine](https://img.shields.io/badge/Godot-4.4.1-blue?logo=godotengine)
![Steam Integration](https://img.shields.io/badge/Steam-Multiplayer-green?logo=steam)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?logo=windows)

## 🎮 Game Overview

### Core Concept
Voidburn transforms traditional space combat by emphasizing **cooperative ship management**. Each player takes on specialized roles aboard a capital ship, from weapons operators and engineers to pilots and damage control specialists. Success depends on seamless coordination and communication as your crew faces overwhelming odds in the depths of space.

### Current Status
- 🔒 **Closed Alpha**: Currently in testing on Steam
- 🚀 **Active Development**: Regular updates and improvements
- 🎯 **Planned Release**: Wider audience access coming soon

## ✨ Impressive Features

### 🔧 Advanced Ship Systems
- **Complex Power Management**: Dynamic power distribution with capacitor systems
- **Cooling Systems**: Manage heat buildup and prevent system overheating  
- **Fire Suppression**: Real-time fire hazard management and emergency response
- **Component Damage**: Detailed damage modeling affecting ship functionality
- **Repair Mechanics**: Hands-on repair gameplay with specialized tools

### ⚔️ Combat Systems
- **Multi-Role Turret Operations**: Player-controlled weapon systems with:
  - Autocannons with multiple ammunition types
  - Laser repeaters with energy management
  - Massive ship-to-ship cannons
- **Advanced Targeting**: Radar signatures, target locking, and lead pip calculation
- **Projectile Physics**: Realistic ballistics and weapon behavior
- **Damage Systems**: Component-based destruction and system failures

### 🛰️ Multiplayer Architecture
- **Steam Integration**: Seamless multiplayer lobbies via Steamworks
- **Hybrid Networking**: Local and Steam-based connectivity options
- **Authority System**: Robust multiplayer synchronization
- **Lobby Management**: Easy-to-use lobby creation and joining system

### 🎯 Mission System
- **Dynamic Mission Generation**: Procedurally created objectives
- **Varied Mission Types**:
  - Search and Destroy operations
  - Cargo Transport missions
  - Component Destruction objectives
- **Real-time Objectives**: Live mission tracking and updates

### 🚁 Hangar Operations
- **Launch System**: Automated ship deployment from carrier hangars
- **Docking Mechanics**: Precision landing and storage systems
- **Fleet Management**: Multi-ship operations and coordination

### 🎨 Visual & Audio
- **Professional 3D Models**: Created in Blender with detailed textures
- **Advanced Shading**: Substance 3D Painter materials
- **Immersive Audio**: Professional sound design with REAPER
- **Dynamic UI**: Comprehensive interface for all ship operations

## 🛠️ Technical Architecture

### Core Technologies
- **[Godot 4.4.1](https://godotengine.org/)** - Primary game engine
- **[GodotSteam 4.15](https://godotsteam.com/)** - Steam integration and multiplayer
- **Custom Networking** - Built on Godot's high-level multiplayer API
- **[Terrain3D](https://github.com/TokisanGames/Terrain3D)** - Advanced terrain generation

### Content Creation Pipeline  
- **[Blender 3.3.0](https://www.blender.org/)** - 3D modeling and animation
- **[Substance 3D Painter](https://www.adobe.com/products/substance3d/apps/painter.html)** - Texturing and materials
- **[REAPER](https://www.reaper.fm/)** - Audio production and mixing
- **[Photoshop](https://www.adobe.com/products/photoshop.html)** - 2D assets and UI design

### Advanced Systems
- **Component-Based Architecture**: Modular ship systems design
- **Real-time Physics**: Advanced physics simulation for combat and movement
- **State Management**: Robust multiplayer state synchronization
- **Event System**: Comprehensive game event handling

## 🚀 Getting Started

### System Requirements

**Minimum Requirements:**
- **OS**: Windows 10/11 (64-bit)
- **Processor**: Intel i5-4590 / AMD FX 8350 equivalent
- **Memory**: 8 GB RAM
- **Graphics**: NVIDIA GTX 970 / AMD Radeon R9 280 equivalent
- **DirectX**: Version 11
- **Network**: Broadband Internet connection
- **Storage**: 5 GB available space

**Recommended:**
- **OS**: Windows 11 (64-bit)
- **Processor**: Intel i7-8700K / AMD Ryzen 5 3600X or better
- **Memory**: 16 GB RAM
- **Graphics**: NVIDIA GTX 1070 / AMD RX 580 or better
- **Network**: Stable broadband connection
- **Storage**: 10 GB available space (SSD recommended)

### Installation

#### Option 1: Steam (Recommended)
1. **Request Alpha Access**: Contact developers for closed alpha invitation
2. **Steam Library**: Game will appear in your Steam library once access is granted
3. **Download & Install**: Standard Steam installation process
4. **Launch**: Start game through Steam for full multiplayer functionality

#### Option 2: Development Build
1. **Download**: Get latest build from [GitHub Releases](https://github.com/coat-soup/multiplayer-car-game/releases)
2. **Extract**: Unzip the game files to your preferred directory
3. **Dependencies**: Ensure you have the latest Visual C++ Redistributable
4. **Run**: Launch `Voidburn.exe` (Note: Limited multiplayer functionality)

### Development Setup

#### Prerequisites
- **Godot 4.4.1** with GodotSteam custom build
- **Git** for version control
- **Steam SDK** for multiplayer features (development)

#### Building from Source
```bash
# Clone the repository
git clone https://github.com/velocitatem/multiplayer-car-game.git
cd multiplayer-car-game

# Open in Godot
# 1. Launch Godot Engine
# 2. Import the project.godot file
# 3. Install required addons (Terrain3D, Script-IDE)
# 4. Build project dependencies

# For Steam integration (requires Steam SDK)
# Place required DLLs in build/ directory:
# - steam_api64.dll
# - godot-jolt_windows-x64.dll
# - libterrain.windows.release.x86_64.dll
```

#### Project Structure
```
├── addons/          # Godot plugins (Terrain3D, Script-IDE)
├── enemies/         # Enemy AI and behavior systems
├── equipment/       # Player tools and equipment
├── levels/          # Game levels and scenes
├── missions/        # Mission system and objectives
├── player/          # Player controller and mechanics
├── ship/            # Ship management and systems
├── ship_weapons/    # Weapon systems and combat
├── stations/        # Dockable station systems  
├── system/          # Core game systems
├── ui/              # User interface components
└── vehicles/        # Vehicle systems and models
```

## 🎮 How to Play

### Basic Controls
- **WASD**: Movement
- **Mouse**: Camera/Aiming
- **F**: Interact with systems
- **Left Click**: Primary fire/Select
- **Right Click**: Secondary fire/Freelook
- **R**: Reload weapon
- **T**: Target radar signature
- **G**: Drop item
- **Shift**: Sprint
- **Ctrl**: Crouch
- **Space**: Jump/Thrust

### Getting Started
1. **Join/Host Lobby**: Create or join a Steam lobby with friends
2. **Choose Your Role**: Select your station and responsibilities
3. **Learn the Systems**: Familiarize yourself with ship controls
4. **Coordinate**: Communicate with your crew
5. **Complete Missions**: Work together to achieve objectives

### Ship Stations

#### Pilot/Helm Station
- Control ship movement and navigation
- Manage power distribution
- Coordinate with weapons operators

#### Weapons Station
- Operate turret systems
- Target enemy vessels
- Manage ammunition and power

#### Engineering Station
- Monitor ship systems
- Perform repairs and maintenance
- Manage cooling and power systems

#### Damage Control
- Respond to emergencies
- Fight fires and system failures
- Coordinate repair efforts

## 🔧 Development & Contribution

### Architecture Highlights

#### Networking Implementation
The game uses a sophisticated networking architecture combining:
- **Godot's Multiplayer API**: Core synchronization and RPC systems
- **Steamworks Integration**: Lobby management and friend systems  
- **Custom Authority**: Role-based control systems for ship operations
- **State Synchronization**: Real-time ship system state management

#### Ship Component System
```gdscript
# Example: Power management integration
@export var power_manager : ShipPowerManager
@export var cooling_manager : ShipCoolingManager
@export var component_manager : ShipComponentManager

func _process(delta):
    # Real-time system monitoring
    ui.toggle_power_warning(power_ratio() == 0)
    update_capacitor_levels()
```

#### Mission Generation
Dynamic mission system with procedural objectives:
```gdscript
func generate_missions():
    current_mission = mission_template.duplicate()
    current_mission.generate_mission(level_manager, random_position)
    current_mission.on_completed.connect(on_mission_completed)
```

### Development Workflow

#### Code Standards
- **GDScript Style**: Follow Godot's official style guide
- **Component Architecture**: Modular, reusable systems
- **Multiplayer Safety**: All networked code must handle authority
- **Performance**: Optimize for real-time multiplayer gameplay

#### Testing
- **Local Testing**: Use network_testing.tscn for development
- **Steam Integration**: Test with actual Steam lobbies
- **Stress Testing**: Multiple players, complex scenarios

## 📦 Release Information

### Version History
- **v0.2.1d**: Current development build
- **Closed Alpha**: Steam testing phase
- **Future Releases**: Open beta and full release planned

### Platform Support
- **Primary**: Windows (x64)
- **Planned**: Linux support under consideration
- **VR**: Future VR support being explored

## 🌟 Community & Support

### Stay Updated
- **YouTube**: [Development Updates](https://www.youtube.com/@coatsoup)
- **GitHub**: [Latest Builds](https://github.com/coat-soup/multiplayer-car-game/releases)
- **Steam**: Closed alpha testing community

### Contributing
We welcome contributions! Please see our contribution guidelines for:
- Bug reports and feature requests
- Code contributions and pull requests
- Art assets and content creation
- Testing and feedback

### Support
For technical issues or questions:
1. Check existing GitHub Issues
2. Join our development community
3. Report bugs with detailed reproduction steps

## 📄 License & Credits

### Development Team
- **Lead Developer**: [CoatSoup](https://www.youtube.com/@coatsoup)
- **Engine**: Godot Foundation
- **Community**: Alpha testers and contributors

### Technology Credits
- **Godot Engine**: Open-source game engine
- **GodotSteam**: Steam integration by GodotSteam team
- **Terrain3D**: Advanced terrain system
- **Community Addons**: Various Godot community plugins

### Asset Credits
- **3D Models**: Created with Blender
- **Textures**: Substance 3D Painter workflow
- **Audio**: Professional audio production with REAPER
- **UI Design**: Custom interface design

---

*Voidburn represents the future of cooperative space combat gaming. Join the crew, master the systems, and help forge the ultimate spacefaring experience.*
