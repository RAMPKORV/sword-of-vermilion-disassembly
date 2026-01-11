# Sword of Vermilion Disassembly Improvement Task List

The following tasks are required to bring the Sword of Vermilion disassembly project up to the standards of the Sonic the Hedgehog 2 reference disassembly.

## Phase 1: Structural Reorganization
- [ ] **Split Main Assembly**: Break down `vermilion.asm` (~80,000 lines) into smaller, logical modules (e.g., `header.asm`, `init.asm`, `vdp.asm`, `combat.asm`, `scripts/`, etc.).
    - [x] Create `header.asm` and include in `vermilion.asm`.
- [ ] **Asset Extraction**: Move large `dc.b` / `dc.w` data blobs (graphics, maps, sound) to external binary files and use `incbin` to include them.
- [ ] **Directory Hierarchy**: Create a standard folder structure:
    - `/art`: Graphics and palettes
    - `/data`: Level data, combat tables, etc.
    - `/sound`: Music and sound effect data
    - `/tools`: Build-time compression/conversion tools

## Phase 2: Build System Modernization
- [ ] **Advanced Build Scripting**: Replace `build.bat` with a more flexible system (e.g., PowerShell or Lua) that handles asset processing.
- [ ] **Integrated Compression**: Identify game-specific compression algorithms (LZ, RLE, etc.) and integrate tools to compress assets during the build.
- [ ] **Automated Verification**: Enhance `chkbitperfect` to provide more detailed diffs when a build isn't bit-perfect.

## Phase 3: Code Readability & Documentation
- [ ] **Descriptive Labeling**: Replace remaining `loc_XXXXXXXX` labels with meaningful names.
- [ ] **Macro Implementation**: Create macros for common data structures (e.g., entity definitions, script commands, palette blocks) to remove magic numbers.
- [ ] **RAM Documentation**: Expand `constants.asm` to include all known RAM addresses and hardware registers.
- [ ] **Interrupt Handlers**: Fully document the VBlank and HBlank routines.

## Phase 4: Tools & Interoperability
- [ ] **Map Editor Support**: Document map formats to enable the use of external editors (like Tiled).
- [ ] **Script Decompiler**: Develop a tool to convert binary script data into readable assembly macros for easier dialogue editing.
