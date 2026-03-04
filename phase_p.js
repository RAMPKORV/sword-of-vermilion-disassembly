// phase_p.js  – Add function/section headers to src/enemy.asm
// Run with: node phase_p.js
// Safe to re-run: only inserts lines that are not already present.

const fs = require('fs');
const FILE = 'src/enemy.asm';

// Each insertion: { beforeLabel, header[] }
// header[] lines are inserted immediately before the "beforeLabel:" line.
const insertions = [

  // ======================================================================
  // Utility functions near the top
  // ======================================================================
  {
    beforeLabel: 'EnemyObjectTick_DeadCode',
    header: [
      '; EnemyObjectTick_DeadCode',
      '; Unreferenced dead code.  Iterates the enemy list and clears the',
      '; active flag on every slot.  Never called in shipping code.',
    ],
  },
  {
    beforeLabel: 'CalculateVelocityFromAngle',
    header: [
      '; CalculateVelocityFromAngle',
      '; Convert obj_direction (0-7) into a fixed-point velocity vector',
      '; using SineTable and obj_pos_x_fixed as the speed scalar.',
      '; Output: obj_vel_x / obj_vel_y set on A5.',
    ],
  },

  // ======================================================================
  // Collision / screen-bounds helpers
  // ======================================================================
  {
    beforeLabel: 'UpdateObjectScreenPosition',
    header: [
      '; UpdateObjectScreenPosition',
      '; Like CheckObjectOnScreen but deactivates the object instead of',
      '; randomising direction when it leaves the battle field.',
    ],
  },
  {
    beforeLabel: 'HandlePlayerTakeDamage',
    header: [
      '; ======================================================================',
      '; Collision and Damage Helpers',
      '; ======================================================================',
    ],
  },
  {
    beforeLabel: 'CalculateAngleToObjectCentered',
    header: [
      '; CalculateAngleToObjectCentered',
      '; Variant of CalculateAngleBetweenObjects that biases the angle',
      '; toward the screen centre before computing the direction.',
    ],
  },
  {
    beforeLabel: 'CheckEnemyCollision',
    header: [
      '; CheckEnemyCollision',
      '; AABB test between A5 and all active enemies in Enemy_list_ptr.',
      '; Zeroes velocity on A5 if an overlap is found.',
    ],
  },

  // ======================================================================
  // Death reward / animation
  // ======================================================================
  {
    beforeLabel: 'EnemyDeathReward_OneSprite',
    header: [
      '; ======================================================================',
      '; Death Rewards and Death Animation',
      '; ======================================================================',
      '',
      '; EnemyDeathReward_OneSprite',
      '; Award XP/kims, decrement enemy count, start death animation.',
      '; Deactivates the single child sprite slot.',
    ],
  },
  {
    beforeLabel: 'EnemyDeathReward_TwoSprites',
    header: [
      '; EnemyDeathReward_TwoSprites',
      '; As EnemyDeathReward_OneSprite but deactivates two child sprite slots.',
    ],
  },
  {
    beforeLabel: 'EnemyDeathAnimation',
    header: [
      '; EnemyDeathAnimation',
      '; Per-frame tick for the death flash sequence.  Cycles through',
      '; EnemyDeathAnimation_Data tile indices; deactivates when done.',
    ],
  },

  // ======================================================================
  // Enemy type groups
  // ======================================================================
  {
    beforeLabel: 'InitEnemy_StandardMelee',
    header: [
      '; ======================================================================',
      '; Enemy Type: StandardMelee',
      '; ======================================================================',
      '',
      '; InitEnemy_StandardMelee / InitEnemy_StandardMeleeAlt / InitEnemy_StandardMeleeFast',
      '; Set up two-sprite melee enemies that walk toward the player.',
      '; Alt uses a slightly wider primary sprite.',
      '; Fast uses a shorter animation mask for quicker walking animation.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_StalkPause',
    header: [
      '; ======================================================================',
      '; Enemy Type: StalkPause',
      '; ======================================================================',
      '',
      '; InitEnemy_StalkPause / InitEnemy_StalkPauseAlt',
      '; Two-sprite melee enemy that randomly pauses its movement for a',
      '; period before resuming the chase.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_ProximityChase',
    header: [
      '; ======================================================================',
      '; Enemy Type: ProximityChase',
      '; ======================================================================',
      '',
      '; InitEnemy_ProximityChase',
      '; Two-sprite enemy that only chases when the player is within',
      '; ENEMY_CHASE_PROXIMITY pixels; otherwise stands still facing the player.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_FleeChase',
    header: [
      '; ======================================================================',
      '; Enemy Type: FleeChase',
      '; ======================================================================',
      '',
      '; InitEnemy_FleeChase',
      '; Two-sprite enemy with random brief fleeing bursts mixed into',
      '; the normal chase behaviour.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_Bouncing',
    header: [
      '; ======================================================================',
      '; Enemy Type: Bouncing',
      '; ======================================================================',
      '',
      '; InitEnemy_Bouncing',
      '; Two-sprite enemy that uses a stalk-pause movement style with a',
      '; bounce animation (child sprite offset above the main sprite).',
    ],
  },
  {
    beforeLabel: 'InitEnemy_ProjectileFire',
    header: [
      '; ======================================================================',
      '; Enemy Type: ProjectileFire',
      '; ======================================================================',
      '',
      '; InitEnemy_ProjectileFire',
      '; Two-sprite melee enemy that also spawns a linear projectile child',
      '; (ProjectileTick_Linear) from its current position.',
    ],
  },
  {
    beforeLabel: 'ProjectileTick_Linear',
    header: [
      '; ======================================================================',
      '; Projectile: Linear',
      '; ======================================================================',
    ],
  },
  {
    beforeLabel: 'InitEnemy_RandomShooter',
    header: [
      '; ======================================================================',
      '; Enemy Type: RandomShooter',
      '; ======================================================================',
      '',
      '; InitEnemy_RandomShooter',
      '; Two-sprite enemy that periodically randomises its facing direction',
      '; and fires a linear projectile when idle.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_Teleporter',
    header: [
      '; ======================================================================',
      '; Enemy Type: Teleporter',
      '; ======================================================================',
      '',
      '; InitEnemy_Teleporter',
      '; Single-sprite stationary enemy that teleports to a random position',
      '; on a random timer using SetRandomEnemyPosition.  Uses',
      '; CheckAndUpdateBattleTimer so it dies when the encounter timer runs out.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_BurstFire',
    header: [
      '; ======================================================================',
      '; Enemy Type: BurstFire',
      '; ======================================================================',
      '',
      '; InitEnemy_BurstFire',
      '; Enemy that alternates between chasing and firing an 8-way burst of',
      '; ProjectileTick_Straight projectiles.  Uses the 4-state',
      '; EnemyAiChasePauseJumpTable.',
    ],
  },
  {
    beforeLabel: 'ProjectileTick_Straight',
    header: [
      '; ======================================================================',
      '; Projectile: Straight (8-direction burst)',
      '; ======================================================================',
      '',
      '; ProjectileTick_Straight',
      '; Single-sprite projectile that travels in a fixed direction until it',
      '; leaves the battle field.  Used by BurstFire and FastBurstShooter.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_HomingShooter',
    header: [
      '; ======================================================================',
      '; Enemy Type: HomingShooter',
      '; ======================================================================',
      '',
      '; InitEnemy_HomingShooter',
      '; Stationary enemy (uses CheckAndUpdateBattleTimer).  Randomly fires',
      '; an 8-way fan of ProjectileTick_Homing projectiles that home toward',
      '; the player.',
    ],
  },
  {
    beforeLabel: 'ProjectileTick_Homing',
    header: [
      '; ======================================================================',
      '; Projectile: Homing',
      '; ======================================================================',
      '',
      '; ProjectileTick_Homing',
      '; Homing projectile with a two-timer system: obj_attack_timer counts',
      '; down a brief arming delay before the projectile begins homing;',
      '; obj_knockback_timer is the total lifetime.',
    ],
  },
  {
    beforeLabel: 'EnemyChildSpriteTick',
    header: [
      '; ======================================================================',
      '; Child Sprite Helpers',
      '; ======================================================================',
      '',
      '; EnemyChildSpriteTick',
      '; Default tick function for passive child sprites; just adds them to',
      '; the display list.',
    ],
  },
  {
    beforeLabel: 'CopyPositionToLinkedSprite',
    header: [
      '; CopyPositionToLinkedSprite',
      '; Copy sprite_flags, screen_x, and screen_y (offset -16 px) from A5',
      '; to A6 for two-part enemy sprites drawn side-by-side.',
    ],
  },
  {
    beforeLabel: 'CopyEnemyPositionToChildObject',
    header: [
      '; CopyEnemyPositionToChildObject',
      '; Same as CopyPositionToLinkedSprite but offsets screen_y by -24 px',
      '; (used by enemies where the child sprite sits higher above the main).',
    ],
  },
  {
    beforeLabel: 'InitEnemy_FastBurstShooter',
    header: [
      '; ======================================================================',
      '; Enemy Type: FastBurstShooter',
      '; ======================================================================',
      '',
      '; InitEnemy_FastBurstShooter',
      '; Like HomingShooter but fires 8 ProjectileTick_Straight projectiles',
      '; at speed $380 instead of homing ones.  Uses CheckAndUpdateBattleTimer.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_SequentialFire',
    header: [
      '; ======================================================================',
      '; Enemy Type: SequentialFire',
      '; ======================================================================',
      '',
      '; InitEnemy_SequentialFire',
      '; Moves toward the player, pauses, then fires a slow spread of',
      '; ProjectileTick_Spiral projectiles via an 8-phase jump table.',
    ],
  },
  {
    beforeLabel: 'ProjectileTick_Spiral',
    header: [
      '; ======================================================================',
      '; Projectile: Spiral',
      '; ======================================================================',
      '',
      '; ProjectileTick_Spiral',
      '; Projectile that travels outward in an expanding spiral.  Uses',
      '; obj_xp_reward as a radius counter and obj_direction as the current',
      '; angle into SineTable.',
    ],
  },
  {
    beforeLabel: 'InitEnemy_SpiralBurst',
    header: [
      '; ======================================================================',
      '; Enemy Type: SpiralBurst',
      '; ======================================================================',
      '',
      '; InitEnemy_SpiralBurst',
      '; Boss-tier enemy that spawns groups of ProjectileTick_OrbitingSpiral',
      '; projectiles that orbit it before flying outward.  Uses',
      '; CheckAndUpdateBattleTimer and the EnemyAiSpiralJumpTable.',
    ],
  },
  {
    beforeLabel: 'ProjectileTick_OrbitingSpiral',
    header: [
      '; ======================================================================',
      '; Projectile: OrbitingSpiral',
      '; ======================================================================',
      '',
      '; ProjectileTick_OrbitingSpiral',
      '; Orbits a centre point (obj_orbit_center_x / obj_attack_timer as Y)',
      '; with growing radius until ORBITING_SPIRAL_ORBIT_COUNT is reached,',
      '; then transitions to straight outward movement.',
    ],
  },

  // ======================================================================
  // Boss types
  // ======================================================================
  {
    beforeLabel: 'InitBoss_OrbShield',
    header: [
      '; ======================================================================',
      '; Boss Type: OrbShield',
      '; ======================================================================',
      '',
      '; InitBoss_OrbShield',
      '; Initialises a large boss enemy with a single orbiting shield orb.',
      '; Main body uses BossTick_OrbShield; orb uses BossOrbTick_Static.',
    ],
  },
  {
    beforeLabel: 'BossTick_OrbShield',
    header: [
      '; BossTick_OrbShield',
      '; Per-frame tick: processes damage / invulnerability, then moves the',
      '; orb in a circular scatter pattern around the boss.',
    ],
  },
  {
    beforeLabel: 'InitBoss_MultiOrb',
    header: [
      '; ======================================================================',
      '; Boss Type: MultiOrb',
      '; ======================================================================',
      '',
      '; InitBoss_MultiOrb',
      '; Large boss surrounded by 9 orbiting shield orbs (BossOrbTick_Static).',
      '; Uses BossTick_MultiOrb / BossDeathReward_MultiSprite.',
    ],
  },
  {
    beforeLabel: 'BossTick_MultiOrb',
    header: [
      '; BossTick_MultiOrb',
      '; Per-frame tick: damage / invulnerability; scatter-moves all 9 orbs',
      '; outward when HP falls below threshold.',
    ],
  },
  {
    beforeLabel: 'InitBoss_OrbRing',
    header: [
      '; ======================================================================',
      '; Boss Type: OrbRing',
      '; ======================================================================',
      '',
      '; InitBoss_OrbRing',
      '; Large boss with a ring of 9 orbs positioned on a circle using',
      '; CalculateCircularPosition.  Uses BossTick_OrbRing.',
    ],
  },
  {
    beforeLabel: 'BossTick_OrbRing',
    header: [
      '; BossTick_OrbRing',
      '; Per-frame tick: damage / invulnerability; rotates all ring orbs by',
      '; incrementing their angle index each frame.',
    ],
  },
  {
    beforeLabel: 'BossOrbTick_Static',
    header: [
      '; BossOrbTick_Static',
      '; Per-frame tick for individual boss orbs.  Zeroes velocity, syncs',
      '; screen position from world position, and calls HandlePlayerTakeDamage.',
      '; Skips AddSpriteToDisplayList if the orb is off-screen.',
    ],
  },

  // Boss 1 main tick
  {
    beforeLabel: 'Boss1_MainTick',
    header: [
      '; Boss1_MainTick',
      '; Per-frame tick: dispatch through BossAiStateJumpTable, then run',
      '; damage/palette, parallax, and player-collision helpers.',
    ],
  },
  {
    beforeLabel: 'Boss1_DeathSequence',
    header: [
      '; Boss1_DeathSequence',
      '; Transition to death: sets all body-segment velocities to fall',
      '; downward and installs Boss1_DeathFall as the next tick.',
    ],
  },
];

// -----------------------------------------------------------------------
// Apply insertions
// -----------------------------------------------------------------------
// Normalise CRLF → LF so label matching works correctly
let raw = fs.readFileSync(FILE, 'utf8').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
let lines = raw.split('\n');

// Remove trailing newline split artifact
if (lines[lines.length - 1] === '') lines.pop();

let changed = 0;
for (const ins of insertions) {
  const searchLabel = ins.beforeLabel + ':';
  const idx = lines.findIndex(l => l.trim() === searchLabel);
  if (idx === -1) {
    console.warn(`  SKIP (not found): ${ins.beforeLabel}`);
    continue;
  }
  // Check if already inserted (look 1–(header.length+2) lines above)
  const checkStr = ins.header[0];
  if (checkStr && lines.slice(Math.max(0, idx - ins.header.length - 2), idx).some(l => l.trim() === checkStr.trim())) {
    console.log(`  ALREADY DONE: ${ins.beforeLabel}`);
    continue;
  }
  // Insert a blank line then the header lines
  const toInsert = ['', ...ins.header];
  lines.splice(idx, 0, ...toInsert);
  console.log(`  INSERTED before ${ins.beforeLabel} (${toInsert.length} lines)`);
  changed++;
}

if (changed === 0) {
  console.log('No changes needed.');
} else {
  fs.writeFileSync(FILE, lines.join('\n') + '\n', 'utf8');
  console.log(`\nWrote ${FILE}  (${changed} insertions)`);
}
