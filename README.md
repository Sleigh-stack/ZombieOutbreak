# ProjectOutbreak

A **Roblox multiplayer wave-defense game** built with Rojo. Players defend a small town against waves of infected creatures. Earn coins, unlock better equipment, and survive as many waves as possible with your team.

---

## 1. Installation

### Prerequisites
- [Roblox Studio](https://create.roblox.com/)
- [Rojo](https://rojo.space/) (version 7.x or later)

### Installing Rojo
#### Via Aftman (recommended)
```bash
# Install Aftman from https://github.com/LPGhatguy/aftman
aftman add rojo-rbx/rojo
```

#### Via Foreman
```bash
foreman add rojo-rbx/rojo
```

#### Manual install
Download the appropriate binary from [Rojo Releases](https://github.com/rojo-rbx/rojo/releases) and place it in your system PATH.

### Verifying Installation
```bash
rojo --version
```

---

## 2. Opening the Project

Clone or download this repository:
```bash
git clone https://github.com/your-username/ProjectOutbreak.git
cd ProjectOutbreak
```

---

## 3. Syncing with Roblox Studio

### Method 1: Live Sync (development)
1. Open Roblox Studio and create a new **Baseplate** place (File → New → Baseplate).
2. In the terminal (from the project root), run:
   ```bash
   rojo serve
   ```
3. In Roblox Studio, go to the **Plugins** tab and click **Rojo** → **Connect**.
4. Enter the address shown in the terminal (usually `127.0.0.1:6587`).
5. The project syncs automatically. Changes to files on disk update Studio in real-time.

### Method 2: Build Sync (one-time)
```bash
rojo build default.project.json --output ProjectOutbreak.rbxlx
```
Open the generated `ProjectOutbreak.rbxlx` in Roblox Studio.

---

## 4. Project Structure

```
ProjectOutbreak/
├── default.project.json         # Rojo project definition
├── README.md                    # This file
├── src/
│   ├── ReplicatedStorage/       # Shared between server and client
│   │   ├── Shared/              # Configuration and utility modules
│   │   │   ├── Constants.lua    # Game constants
│   │   │   ├── Types.lua        # Luau type definitions
│   │   │   ├── Utility.lua      # Shared helper functions
│   │   │   └── GameConfig.lua   # Central balance configuration
│   │   ├── Assets/              # Asset definitions
│   │   │   └── CreatureConfigs.lua  # Creature type configurations
│   │   └── Remotes/             # RemoteEvent definitions (init.lua creates all)
│   │       └── init.lua         # Creates CreatureHit, ShopPurchase, UpdateCoins, etc.
│   ├── ServerScriptService/     # Server-only logic
│   │   ├── Main.server.lua      # Bootstrap/entry point
│   │   ├── WaveManager.server.lua       # Wave flow and progression
│   │   ├── CreatureSpawner.server.lua   # Creature spawning from spawn points
│   │   ├── CreatureAI.server.lua        # Pathfinding and combat AI
│   │   ├── Economy.server.lua           # Coin reward system
│   │   ├── ShopManager.server.lua       # Equipment purchase validation
│   │   └── PlayerData.server.lua        # Per-player data management
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       ├── UIController.client.lua      # UI updates and HUD
│   │       ├── EquipmentController.client.lua  # Weapon/shooting logic
│   │       └── ShopController.client.lua    # Shop interface
│   ├── StarterGui/
│   │   └── MainUI.rbxmx         # Roblox GUI XML (ScreenGui)
│   └── Workspace/
│       ├── Map/                 # Map model (add terrain/buildings here)
│       └── CreatureSpawns/      # Spawn point parts (Parts placed here)
```

---

## 5. Folder Explanations

| Folder | Purpose |
|---|---|
| `ReplicatedStorage/Shared/` | Modules available to both server and client code |
| `ReplicatedStorage/Assets/` | Configuration tables for creatures and other game assets |
| `ReplicatedStorage/Remotes/` | RemoteEvent instances for client-server communication |
| `ServerScriptService/` | All server-authoritative game logic scripts |
| `StarterPlayer/StarterPlayerScripts/` | Client scripts that run per-player |
| `StarterGui/` | GUI layout files |
| `Workspace/Map/` | The 3D map model (terrain, buildings, props) |
| `Workspace/CreatureSpawns/` | Folder containing spawn point BaseParts |

---

## 6. How to Add New Creature Types

1. Open `src/ReplicatedStorage/Assets/CreatureConfigs.lua`.
2. Add a new entry to the table:
   ```lua
   Poison = {
       Name = "Poison Infected",
       Speed = 10,
       Health = 25,
       Damage = 12,
       Reward = 15,
   },
   ```
3. Open `src/ReplicatedStorage/Shared/GameConfig.lua` and add coin rewards under `CoinReward`:
   ```lua
   CoinReward = {
       -- existing entries...
       Poison = 15,
   },
   ```
4. Open `src/ReplicatedStorage/Shared/GameConfig.lua` and add stats under `CreatureStats`:
   ```lua
   CreatureStats = {
       -- existing entries...
       Poison = {
           Speed = 10,
           Health = 25,
           Damage = 12,
           Reward = 15,
       },
   },
   ```
5. (Optional) To have the new type spawn automatically, update the wave spawning logic in `WaveManager.server.lua` (`BuildWaveConfig` function).
6. Sync with Rojo — the new creature type is available.

---

## 7. How to Add New Equipment

1. Open `src/ReplicatedStorage/Shared/GameConfig.lua`.
2. Add a new entry under `Equipment`:
   ```lua
   SniperBlaster = {
       Name = "Sniper Blaster",
       Cost = 1000,
       Damage = 75,
       FireRate = 1.5,
       MaxAmmo = 8,
       ReloadTime = 4,
   },
   ```
3. The shop UI automatically lists new equipment from the config.
4. No code changes needed beyond the config — the EquipmentController reads from GameConfig.

---

## 8. How to Add New Maps

1. Build your map in Roblox Studio inside `Workspace`.
2. Group all map parts into a single Model.
3. Export the model as a `.rbxmx` file:
   - Right-click the model → **Save to File**.
4. Place the file in `src/Workspace/Map/`.
5. Update `default.project.json` if needed to point to the new file.
6. Sync with Rojo.

Alternatively, build directly in the `Map` folder inside Rojo's live sync session.

---

## 9. How to Add Creature Spawn Locations

1. In Roblox Studio (connected via Rojo), navigate to `Workspace → CreatureSpawns`.
2. Insert **Part** objects into the CreatureSpawns folder.
3. Position each part where creatures should spawn.
4. Name them descriptively (e.g., `SpawnPoint1`, `NorthGate`, `EastRoad`).
5. The `CreatureSpawner` automatically detects all Parts in `CreatureSpawns` and uses them as spawn points.
6. New spawn points are picked up in real-time — no code changes needed.

---

## 10. Gameplay Overview

### Round Flow
1. **Lobby**: Players spawn in town. A 10-second countdown starts.
2. **Wave**: Creatures spawn from points and attack players. Defeat all to progress.
3. **Intermission**: 15-second break before the next wave begins.

### Wave Scaling
| Wave | Standard | Swift | Heavy | Total |
|---|---|---|---|---|
| 1 | 10 | 0 | 0 | 10 |
| 2 | 15 | 0 | 0 | 15 |
| 3 | 17 | 3 | 0 | 20 |
| 4 | 25 | 0 | 0 | 25 |
| 5 | 22 | 0 | 3 | 25 |
| 6 | 27 | 8 | 0 | 35 |

- After wave 3: +5 creatures per wave.
- Every 3 waves: Swift creatures spawn (30% of total).
- Every 5 waves: Heavy creatures spawn (20% of total).
- Creature health scales by 10% per wave.

### Controls
| Key | Action |
|---|---|
| **Left Click** | Fire weapon |
| **R** | Reload |
| **B** | Open/close shop |

### Economy
| Action | Reward |
|---|---|
| Defeat Standard creature | 10 Coins |
| Defeat Swift creature | 15 Coins |
| Defeat Heavy creature | 25 Coins |
| Complete a wave | 50 Coins |

### Equipment Shop
| Weapon | Cost | Damage | Fire Rate | Ammo |
|---|---|---|---|---|
| Basic Blaster | Free | 15 | 0.5s | 30 |
| Rapid Blaster | 250 Coins | 8 | 0.15s | 50 |
| Heavy Blaster | 500 Coins | 40 | 1.2s | 15 |

---

## License

MIT — see LICENSE file for details.