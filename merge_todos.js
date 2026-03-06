const fs = require('fs');
const current = JSON.parse(fs.readFileSync('E:/Romhacking/vermilion/todos.json', 'utf8'));

const newCategories = {
  'labeling_traceability': {
    'description': 'Standardizing banners, ROM offset annotations, and symbol map exports',
    'tasks': [
      { 'id': 'LBL-001', 'title': 'Apply standard banners to all 28 src/*.asm files', 'description': 'Ensure every module has the consistent header banner with filename and description.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'LBL-002', 'title': 'Add ROM offset comments to all major function entry points', 'description': 'Annotate labels with original ROM address for easier cross-referencing with original binary.', 'priority': 'medium', 'effort': 'large' },
      { 'id': 'LBL-003', 'title': 'Implement symbol map export script (Node.js)', 'description': 'Script to extract all labels and their addresses to a format compatible with emulators like Mesen-S or BlastEm.', 'priority': 'high', 'effort': 'small' },
      { 'id': 'LBL-004', 'title': 'Standardize local labels with _ suffix', 'description': 'Ensure local sub-labels follow the repo convention (e.g. Function_Loop) and use appropriate scope.', 'priority': 'medium', 'effort': 'large' },
      { 'id': 'LBL-005', 'title': 'Audit and rename loc_ labels in header.asm', 'description': 'Finish naming the remaining 1 loc_ label in header.asm for 100% named status.', 'priority': 'critical', 'effort': 'small' },
      { 'id': 'LBL-006', 'title': 'Add size annotations to data tables', 'description': 'Comment total byte size or entry count on all major data tables in src/data/ and src/gfxdata.asm.', 'priority': 'low', 'effort': 'medium' },
      { 'id': 'LBL-007', 'title': 'Cross-reference RAM addresses with Japanese disassembly', 'description': 'Compare and merge naming conventions from known Japanese research notes for consistency.', 'priority': 'low', 'effort': 'medium' },
      { 'id': 'LBL-008', 'title': 'Export constants to header files for C-based tooling', 'description': 'Script to generate .h files from constants.asm for future C-based randomizer or editors.', 'priority': 'medium', 'effort': 'small' }
    ]
  },
  'ram_struct_documentation': {
    'description': 'Mapping object slots, event triggers, and input states',
    'tasks': [
      { 'id': 'RAM-001', 'title': 'Document $FFFFD000 Object Slot Structure', 'description': 'Define and document every field in the 64-byte object structure used by the entity system.', 'priority': 'critical', 'effort': 'medium' },
      { 'id': 'RAM-002', 'title': 'Map $FFFFC720 Event Trigger bitfield', 'description': 'Create a complete list of all 1024+ event flags and their in-game meanings.', 'priority': 'high', 'effort': 'very_large' },
      { 'id': 'RAM-003', 'title': 'Document $FFFFC000 system variables', 'description': 'Map and name all variables in the system RAM area (vblank flags, DMA queues, interrupt state).', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'RAM-004', 'title': 'Define struct for Sound Driver RAM ($FFFFF000)', 'description': 'Document the Z80 communication area and FM/PSG channel state structs.', 'priority': 'medium', 'effort': 'large' },
      { 'id': 'RAM-005', 'title': 'Map Controller Input State RAM', 'description': 'Document the structure where button presses, held states, and repeat timers are stored.', 'priority': 'high', 'effort': 'small' },
      { 'id': 'RAM-006', 'title': 'Document Dungeon State RAM ($FFFFC800)', 'description': 'Map variables used for first-person rendering, wall states, and step counters.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'RAM-007', 'title': 'Define Player Stats RAM structure', 'description': 'Document the continuous block of RAM containing HP, MP, Gold, and experience.', 'priority': 'high', 'effort': 'small' },
      { 'id': 'RAM-008', 'title': 'Identify all temporary/scratchpad RAM usage', 'description': 'Audit uses of $FFFFFB00 and similar scratchpads to prevent collision in future hacks.', 'priority': 'medium', 'effort': 'large' }
    ]
  },
  'script_vm_reverse': {
    'description': 'Script VM opcodes, runtime state, and disassembler tooling',
    'tasks': [
      { 'id': 'SVM-001', 'title': 'Map all 80+ Script VM opcodes', 'description': 'Identify and document the function of every opcode in the script interpreter (src/script.asm).', 'priority': 'critical', 'effort': 'large' },
      { 'id': 'SVM-002', 'title': 'Document Script VM stack and register state', 'description': 'Identify where the VM stores its return addresses and temporary variables.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'SVM-003', 'title': 'Create a standalone script disassembler (Node.js)', 'description': 'Build a tool to extract dialogue and logic from script.asm into a readable text format.', 'priority': 'high', 'effort': 'large' },
      { 'id': 'SVM-004', 'title': 'Reverse engineer script conditional branching logic', 'description': 'Document how the VM handles if/else and flag checks.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'SVM-005', 'title': 'Map script command to town/NPC dispatch table', 'description': 'Document the link between map entry and script execution start points.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'SVM-006', 'title': 'Document Script VM window/UI commands', 'description': 'Identify opcodes responsible for drawing menus, choices, and text boxes.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'SVM-007', 'title': 'Analyze script-based item effects', 'description': 'Map how items trigger scripts when used from the menu.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'SVM-008', 'title': 'Implement script assembler/compiler prototype', 'description': 'Initial work on a tool to compile text scripts back into the VM bytecode.', 'priority': 'low', 'effort': 'very_large' }
    ]
  },
  'tooling_lints': {
    'description': 'Node.js scripts for quality control and codebase auditing',
    'tasks': [
      { 'id': 'TL-001', 'title': 'Implement hex literal vs decimal checker', 'description': 'Node.js script to ensure dc.b/dc.w data tables only contain hex literals per project rules.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'TL-002', 'title': 'Detect hardcoded RAM addresses in instructions', 'description': 'Script to find raw $FFFF... addresses that should be replaced with constants.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'TL-003', 'title': 'Duplicate constant detector', 'description': 'Script to find multiple constants with same value or same name in constants.asm.', 'priority': 'medium', 'effort': 'small' },
      { 'id': 'TL-004', 'title': 'Validate BSR/BRA branch ranges', 'description': 'Tool to warn if a branch is approaching the 16-bit limit or can be optimized to 8-bit.', 'priority': 'low', 'effort': 'medium' },
      { 'id': 'TL-005', 'title': 'VDP command validator', 'description': 'Script to verify that hardcoded VDP longwords are valid VRAM/CRAM/VSRAM commands.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'TL-006', 'title': 'ASM-to-JSON asset metadata exporter', 'description': 'Tool to export label positions and data sizes for external asset editors.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'TL-007', 'title': 'Integrate lints into verify.bat', 'description': 'Ensure all quality scripts run as part of the standard build verification.', 'priority': 'high', 'effort': 'small' },
      { 'id': 'TL-008', 'title': 'CI-ready build wrapper', 'description': 'Script to run build/verify and return proper exit codes for GitHub Actions.', 'priority': 'low', 'effort': 'small' }
    ]
  },
  'architecture_boundaries': {
    'description': 'Module responsibility rules and VDP/DMA consolidation',
    'tasks': [
      { 'id': 'ARCH-006', 'title': 'Define Module Responsibility Rules', 'description': 'Document which modules are allowed to touch which hardware registers (e.g. only vblank.asm handles VDP status).', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'ARCH-007', 'title': 'Consolidate DMA queue management', 'description': 'Ensure all DMA requests go through a single queueing system in vblank.asm.', 'priority': 'high', 'effort': 'large' },
      { 'id': 'ARCH-008', 'title': 'Create shared VDP utility module', 'description': 'Extract common VDP setup/init routines from core.asm into a dedicated vdp.asm.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'ARCH-009', 'title': 'Standardize error trap behavior', 'description': 'Ensure all modules use a consistent ErrorTrap macro/routine for crash handling.', 'priority': 'low', 'effort': 'small' },
      { 'id': 'ARCH-010', 'title': 'Implement RAM-to-RAM copy utility', 'description': 'Create a high-performance 68000 loop for bulk memory moves to replace inline loops.', 'priority': 'medium', 'effort': 'small' },
      { 'id': 'ARCH-011', 'title': 'Formalize Object Task system API', 'description': 'Document how object slots request state changes and handle cross-entity communication.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'ARCH-012', 'title': 'Audit and reduce global variable scope', 'description': 'Identify RAM variables that are only used within one module and move them to local blocks.', 'priority': 'low', 'effort': 'large' },
      { 'id': 'ARCH-013', 'title': 'Create Z80 Interface API', 'description': 'Formalize the protocol for sending commands to the Z80 sound driver.', 'priority': 'high', 'effort': 'medium' }
    ]
  },
  'contributor_workflow': {
    'description': 'Onboarding, glossary, and debugging playbook',
    'tasks': [
      { 'id': 'CW-001', 'title': 'Create Project Glossary (glossary.md)', 'description': 'Define game-specific terms like Towns, Sectors, Slots, and Triggers.', 'priority': 'high', 'effort': 'small' },
      { 'id': 'CW-002', 'title': 'Write Onboarding Guide (CONTRIBUTING.md)', 'description': 'Step-by-step instructions for setting up the environment and making bit-perfect changes.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'CW-003', 'title': 'Develop Debugging Playbook', 'description': 'Documentation on using emulators (BlastEm/Mesen-S) with this disassembly for debugging.', 'priority': 'medium', 'effort': 'medium' },
      { 'id': 'CW-004', 'title': 'Document build flags and ASM68K quirks', 'description': 'Explain why certain flags (/k /p) are used and common assembler pitfalls.', 'priority': 'medium', 'effort': 'small' },
      { 'id': 'CW-005', 'title': 'Create PR template with verification checklist', 'description': 'Ensure contributors confirm verify.bat and lint checks pass.', 'priority': 'low', 'effort': 'small' },
      { 'id': 'CW-006', 'title': 'Map disassembly to original ROM offsets (ROM Map)', 'description': 'Create a master index of which ASM files correspond to which ROM ranges.', 'priority': 'high', 'effort': 'medium' },
      { 'id': 'CW-007', 'title': 'Document Branch naming and Git workflow', 'description': 'Standardize on feature/task-id naming and commit message format.', 'priority': 'low', 'effort': 'small' },
      { 'id': 'CW-008', 'title': 'Create issue templates for bugs and features', 'description': 'Standardize reporting of disassembly errors or needed names.', 'priority': 'low', 'effort': 'small' }
    ]
  }
};

Object.assign(current.categories, newCategories);

const newHighPriority = [
  'LBL-005 (critical: final header label)',
  'RAM-001 (critical: object slot struct)',
  'SVM-001 (critical: script opcodes)',
  'RAM-002 (high: event trigger map)',
  'TL-001 + TL-002 (high: quality lints)',
  'CW-002 (high: onboarding guide)',
  'SVM-003 (high: script disassembler)',
  'ARCH-007 (high: DMA consolidation)',
  'LBL-001 (high: module banners)',
  'LBL-003 (high: symbol map export)'
];
current.priority_order = [...newHighPriority, ...current.priority_order];

const allTasks = Object.values(current.categories).flatMap(c => c.tasks);
current.statistics.total_tasks = allTasks.length;
current.statistics.by_priority = allTasks.reduce((acc, t) => { acc[t.priority] = (acc[t.priority] || 0) + 1; return acc; }, {});
current.statistics.by_category = Object.entries(current.categories).reduce((acc, [k, v]) => { acc[k] = v.tasks.length; return acc; }, {});
current.statistics.by_effort = allTasks.reduce((acc, t) => { acc[t.effort] = (acc[t.effort] || 0) + 1; return acc; }, {});

fs.writeFileSync('E:/Romhacking/vermilion/todos.json', JSON.stringify(current, null, 2), 'utf8');
