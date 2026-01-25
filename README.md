# Sword of Vermilion - Disassembly Project

Sega Genesis / Mega Drive disassembly of Sword of Vermilion (1989)

## Quick Start

### Build the ROM
```batch
build.bat
```

### Verify Bit-Perfect Build
```batch
verify.bat
```

From Git Bash/WSL: `cmd //c build.bat` or `cmd //c verify.bat`

---

## Documentation

### For AI Coding Agents
- **[AGENTS.md](AGENTS.md)** - Instructions for AI agents working on this project

### For Developers
- **[SYSTEMS_DOCUMENTATION.md](SYSTEMS_DOCUMENTATION.md)** - Complete guide to game systems
- **[FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md)** - Quick function/address lookup
- **[TASKLIST.md](TASKLIST.md)** - Project improvement roadmap
- **[notes.txt](notes.txt)** - RAM locations and data formats

### Session Logs
- **[SESSION_PROGRESS.md](SESSION_PROGRESS.md)** - Latest analysis session (2026-01-25)

---

## Game Systems Overview

### Maps
- Compression: Custom RLE format
- Overworld: 128 sectors (8x16 grid)
- Caves: 44 individual rooms
- Memory: 9 sectors loaded (3x3 grid)

### NPCs & Entities  
- Max 29 NPCs per town
- Two data formats (building/town)
- Dynamic spawning based on story

### Treasure Chests
- Types: Items, Equipment, Money
- Total: 45 chests documented
- Flag-based opened state

### Enemy Encounters
- Overworld: 128 sector mappings
- Caves: 44 room mappings
- 4 encounter types per group

### Towns
- Total: 16 towns
- 3 tileset types
- Hierarchical structure

---

## Key Function Locations

| Function | Line | Description |
|----------|------|-------------|
| loc_0000633C | 6363 | Map RLE decompressor |
| loc_00006E1C | 7088 | NPC loader |
| SetupEquipmentTreasure | 35854 | Equipment treasure setup |
| InitMoneyTreasure | 35858 | Money treasure setup |
| CheckForEncounter | 3031 | Battle trigger |

---

## Current State

- ✅ Builds bit-perfect
- ✅ Core systems documented
- ✅ 45 treasure chests mapped
- ⏳ Data extraction pending
- ⏳ Code splitting pending

---

## Tools

- **tools_treasure_analyzer.js** - Scans for all treasure chests
- **tools_map_rle.js** - RLE map decompressor module

---

*Last updated: 2026-01-25*
