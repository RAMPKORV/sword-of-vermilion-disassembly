// Phase O: Add missing function headers to combat.asm
// Uses line numbers from analysis; inserts comment blocks before specific labels.
const fs = require('fs');

const filePath = 'src/combat.asm';
let content = fs.readFileSync(filePath, 'utf8');
// Normalize to LF for processing
const useCRLF = content.includes('\r\n');
content = content.replace(/\r\n/g, '\n');
const lines = content.split('\n');

// Each entry: { beforeLabel, header }
// beforeLabel: the exact label line to insert before
// header: array of comment lines to insert before the label
const insertions = [
    {
        beforeLabel: 'CastVoltio:',
        header: [
            '; ----------------------------------------------------------------------',
            '; CastVoltio',
            ';',
            '; Fires 7 orbiting projectiles (1 lead + 2 followers + 4 ground) from',
            '; VoltioProjectileOffsetData.  The lead uses UpdateVoltioLeadOrbitProjectile',
            '; (orbits and fades after obj_attack_timer hits 0); followers use',
            '; UpdateProjectileFollowPlayer (clones that track the lead tile and player',
            '; position); ground projectiles use UpdateVoltioGroundProjectile (on-floor',
            '; damage zones offset from the player).',
            '; D6 = tile index: orbit slots $0245, ground slots $025D.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'InitMagicProjectile:',
        header: [
            '; ----------------------------------------------------------------------',
            '; InitMagicProjectile',
            ';',
            '; Shared initialiser for Voltio orbit/ground projectile slots.',
            '; Reads 4 words from (A0)+ per slot: offset_x, offset_y, knockback_timer,',
            '; flip_flags (bit 0 = H-flip, bit 1 = V-flip).  Sets obj_attack_timer to',
            '; $0096 (150 frames) and advances A6 to the next object slot via',
            '; obj_next_offset.  Called in a loop from CastVoltio.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'CastVoltios:',
        header: [
            '; ----------------------------------------------------------------------',
            '; CastVoltios',
            ';',
            '; Casts the Voltios lightning-bolt rain spell.  Activates slot 02,',
            '; spawns it above the player (Y - $20), then cycles through four phases:',
            ';   UpdateVoltiosDescendPhase       - bolts appear from top, one per tick',
            ';   UpdateVoltiosClearDescendPhase  - deactivate descending bolts',
            ';   UpdateVoltiosAscendPhase        - bolts rise from ground, one per tick',
            ';   UpdateVoltiosClearAscendPhase   - deactivate ascending bolts',
            '; After all phases VoltiosSpawnExplosion creates a damage explosion.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'FindActiveEnemyPosition:',
        header: [
            '; ----------------------------------------------------------------------',
            '; FindActiveEnemyPosition',
            ';',
            '; Scans the enemy list for the first slot that is active (bit 7 set),',
            '; flagged alive (bit 6 set), and has HP > 0.  Writes the enemy pointer,',
            '; world_x, world_y, and sort_key into A5 fields.  If no live enemy is',
            '; found, writes a default screen-centre position ($00A0, $0070) and clears',
            '; the stored pointer.  Iterates 8 slots, advancing 3 links per step.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'DrawSpriteAtCurrentPosition:',
        header: [
            '; ----------------------------------------------------------------------',
            '; DrawSpriteAtCurrentPosition',
            ';',
            '; Copies obj_world_x/obj_world_y to obj_screen_x/obj_screen_y and calls',
            '; AddSpriteToDisplayList.  Convenience wrapper used by several projectile',
            '; tick functions.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'CastFerros:',
        header: [
            '; ----------------------------------------------------------------------',
            '; CastFerros',
            ';',
            '; Fires a spinning iron-ball projectile that orbits the player.',
            '; Uses slot 02 with tick function UpdateFerrosOrbit.  The projectile',
            '; orbits using an angle index stored in obj_invuln_timer (0-7); each',
            '; frame the angle is advanced and the position is set by rotating',
            '; obj_proj_offset_x/Y around the player via the sine table.',
            '; On timeout (obj_attack_timer == 0) the slot is deactivated.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'UpdatePlayerSpriteFrame:',
        header: [
            '; ----------------------------------------------------------------------',
            '; UpdatePlayerSpriteFrame',
            ';',
            '; Selects the current animation frame for the metal-spell player sprite.',
            '; Maps obj_direction >> 4 to a 0-3 cardinal index, mirrors the H-flip',
            '; flag for left-facing directions, then indexes MetalSpellSpriteFrameTable',
            '; with (cardinal * 8 + (move_counter >> 1 & 6)) for a 4-frame walk cycle.',
            '; Used by Ferros and similar melee-zone spell objects.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'FindNthEnemyInList:',
        header: [
            '; ----------------------------------------------------------------------',
            '; FindNthEnemyInList',
            ';',
            '; Input:  D1 = 0-based index into the enemy list; A6 = destination object.',
            '; Scans the enemy list, advancing 3 links per iteration, until the',
            '; Nth active slot is found.  Stores the enemy pointer in obj_hp(A6).',
            '; If no matching slot is found, stores 0 in obj_hp(A6).',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'SetPositionFromActiveEnemy:',
        header: [
            '; ----------------------------------------------------------------------',
            '; SetPositionFromActiveEnemy',
            ';',
            '; Sets obj_world_x/Y of A6 to match the first active, alive enemy.',
            '; Y is offset by +8 to centre the spell on the enemy sprite.',
            '; Falls back to ($00A0, $0070) if no active enemy is found.',
            '; Called by CastHydro and CastHydrios to anchor the spell target.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'CheckCursedAndConsumeReadiedMagicMp:',
        header: [
            '; ----------------------------------------------------------------------',
            '; CheckCursedAndConsumeReadiedMagicMp',
            ';',
            '; Pre-cast guard: verifies the player is not cursed (CheckIfCursed),',
            '; then looks up the MP cost of Readied_magic in MagicMpConsumptionMap',
            '; and deducts it from Player_mp.  Returns D0=0 (Z set) on success,',
            '; D0=$FFFF (NE) on failure (cursed or insufficient MP).',
            '; Used as the first call in every CastXxx function.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'DeductMagicMP:',
        header: [
            '; ----------------------------------------------------------------------',
            '; DeductMagicMP',
            ';',
            '; Deducts MP for the spell currently selected in the magic menu',
            '; (Magic_list_cursor_index -> Possessed_magics_list -> MagicMpConsumptionMap).',
            '; Returns D0=0 on success, D0=$FFFF if Player_mp would go negative.',
            '; Used by the magic-menu confirm path (distinct from the battle cast path).',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'InitMagicDamageAndFlags:',
        header: [
            '; ----------------------------------------------------------------------',
            '; InitMagicDamageAndFlags',
            ';',
            '; Computes projectile damage for A6 based on Readied_magic and Player_int.',
            '; High-damage spells (Volti, Copperos, Argentos, Hydro, Hydrios,',
            '; Terrafissi) scale INT by >> 8 (low scale); others use >> 4 (high scale).',
            '; Looks up base damage from MagicBaseDamageTable[spell] and adds the',
            '; scaled INT value, storing in obj_max_hp(A6).  Also sets obj_behavior_flag',
            '; from MagicElementTypeTable[spell] to encode elemental type.',
            '; ----------------------------------------------------------------------',
        ],
    },
    {
        beforeLabel: 'ItemMenu_ScriptDone:',
        header: [
            '; ----------------------------------------------------------------------',
            '; ItemMenu_ScriptDone / ItemMenu state machine',
            ';',
            '; Called after a UseItemXxx function prints its result text.  Draws the',
            '; status HUD and sets Item_menu_state to ITEM_MENU_STATE_SCRIPT_DONE,',
            '; then re-draws the short item list and marks the tilemap row as pending.',
            '; The caller loops here each tick until the script text scrolls out.',
            '; UseItemDescription_Build builds the item-description string for display.',
            '; ----------------------------------------------------------------------',
        ],
    },
];

// Apply insertions by scanning line-by-line
const result = [];
for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trimEnd();
    // Check if this line exactly matches any beforeLabel
    for (const ins of insertions) {
        if (trimmed === ins.beforeLabel) {
            // Insert blank line + header before this label
            if (result.length > 0 && result[result.length - 1].trim() !== '') {
                result.push('');
            }
            for (const h of ins.header) {
                result.push(h);
            }
            break;
        }
    }
    result.push(lines[i]);
}

let output = result.join('\n');
if (useCRLF) output = output.replace(/\n/g, '\r\n');
fs.writeFileSync(filePath, output, 'utf8');
console.log('Phase O: Added function headers to combat.asm');
