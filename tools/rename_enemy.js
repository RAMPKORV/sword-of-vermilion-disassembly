// tools/rename_enemy.js
// DOC-006: Rename meaningless _LoopN / _DoneN sub-labels in src/enemy.asm
// Run with: node tools/rename_enemy.js
// Process highest-numbered suffixes first to avoid prefix-collision bugs.

const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'src', 'enemy.asm');
let src = fs.readFileSync(filePath, 'utf8');

// Helper: whole-word rename (label references and definitions)
function rename(oldName, newName) {
  const re = new RegExp(`\\b${oldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'g');
  const before = src;
  src = src.replace(re, newName);
  const count = (before.match(re) || []).length;
  if (count === 0) {
    console.warn(`  WARN: no occurrences of "${oldName}"`);
  } else {
    console.log(`  ${oldName} -> ${newName}  (${count} occurrence${count > 1 ? 's' : ''})`);
  }
}

console.log('=== enemy.asm sub-label renames ===\n');

// -----------------------------------------------------------------------
// CalculateAngleToObjectCentered / CalculateAngleBetweenObjects_common
// -----------------------------------------------------------------------
console.log('-- CalculateAngleToObjectCentered / CalculateAngleBetweenObjects_common --');
rename('CalculateAngleBetweenObjects_common_Loop5', 'CalculateAngleBetweenObjects_common_SetOctantBit');
rename('CalculateAngleBetweenObjects_common_Loop4', 'CalculateAngleBetweenObjects_common_HalvedX');
rename('CalculateAngleBetweenObjects_common_Loop3', 'CalculateAngleBetweenObjects_common_SwapAxes');
rename('CalculateAngleBetweenObjects_common_Loop2', 'CalculateAngleBetweenObjects_common_NegateY');
rename('CalculateAngleToObjectCentered_Loop2',      'CalculateAngleToObjectCentered_OffsetY');

// -----------------------------------------------------------------------
// CheckEnemyCollision
// -----------------------------------------------------------------------
console.log('\n-- CheckEnemyCollision --');
rename('CheckEnemyCollision_Done2', 'CheckEnemyCollision_SkipInactive');

// -----------------------------------------------------------------------
// EnemyTick_StandardMelee
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_StandardMelee --');
rename('EnemyTick_StandardMelee_Loop6',  'EnemyTick_StandardMelee_RandomWander');
rename('EnemyTick_StandardMelee_Loop5',  'EnemyTick_StandardMelee_ApplyTurn');
rename('EnemyTick_StandardMelee_Loop4',  'EnemyTick_StandardMelee_TurnRight');
rename('EnemyTick_StandardMelee_Loop3',  'EnemyTick_StandardMelee_ChooseDirection');
rename('EnemyTick_StandardMelee_Loop2',  'EnemyTick_StandardMelee_CheckAttackTimer');
rename('EnemyTick_StandardMelee_Loop',   'EnemyTick_StandardMelee_Alive');
rename('EnemyMovementTick_UpdateVelocity_Loop3', 'EnemyMovementTick_UpdateVelocity_OffsetChild');
rename('EnemyMovementTick_UpdateVelocity_Loop2', 'EnemyMovementTick_UpdateVelocity_SetFlip');
rename('EnemyMovementTick_UpdateVelocity_Loop',  'EnemyMovementTick_UpdateVelocity_CheckMoving');

// -----------------------------------------------------------------------
// EnemyTick_StalkPause
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_StalkPause --');
rename('EnemyTick_StalkPause_Loop9', 'EnemyTick_StalkPause_SetFlip');
rename('EnemyTick_StalkPause_Loop8', 'EnemyTick_StalkPause_CheckMoving');
rename('EnemyTick_StalkPause_Loop7', 'EnemyTick_StalkPause_RollPauseTimer');
rename('EnemyTick_StalkPause_Loop6', 'EnemyTick_StalkPause_HandleDamage');
rename('EnemyTick_StalkPause_Loop5', 'EnemyTick_StalkPause_CheckStalkTimer');
rename('EnemyTick_StalkPause_Loop4', 'EnemyTick_StalkPause_MoveToPlayer');
rename('EnemyTick_StalkPause_Loop3', 'EnemyTick_StalkPause_CheckPauseTimer');
rename('EnemyTick_StalkPause_Loop2', 'EnemyTick_StalkPause_AddToDisplay');
rename('EnemyTick_StalkPause_Loop',  'EnemyTick_StalkPause_Alive');

// -----------------------------------------------------------------------
// EnemyTick_ProximityChase
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_ProximityChase --');
rename('EnemyTick_ProximityChase_Loop11', 'EnemyTick_ProximityChase_SetFlip');
rename('EnemyTick_ProximityChase_Loop10', 'EnemyTick_ProximityChase_CheckMoving');
rename('EnemyTick_ProximityChase_Loop9',  'EnemyTick_ProximityChase_HandleDamage');
rename('EnemyTick_ProximityChase_Loop8',  'EnemyTick_ProximityChase_ChasePlayer');
rename('EnemyTick_ProximityChase_Loop7',  'EnemyTick_ProximityChase_AbsY');
rename('EnemyTick_ProximityChase_Loop6',  'EnemyTick_ProximityChase_StandStill');
rename('EnemyTick_ProximityChase_Loop5',  'EnemyTick_ProximityChase_AbsX');
rename('EnemyTick_ProximityChase_Loop4',  'EnemyTick_ProximityChase_Chase');
rename('EnemyTick_ProximityChase_Loop3',  'EnemyTick_ProximityChase_CheckProximity');
rename('EnemyTick_ProximityChase_Loop2',  'EnemyTick_ProximityChase_AddToDisplay');
rename('EnemyTick_ProximityChase_Loop',   'EnemyTick_ProximityChase_Alive');

// -----------------------------------------------------------------------
// EnemyTick_FleeChase
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_FleeChase --');
rename('EnemyTick_FleeChase_Loop7', 'EnemyTick_FleeChase_SetFlip');
rename('EnemyTick_FleeChase_Loop6', 'EnemyTick_FleeChase_CheckMoving');
rename('EnemyTick_FleeChase_Loop5', 'EnemyTick_FleeChase_SetFleeDir');
rename('EnemyTick_FleeChase_Loop4', 'EnemyTick_FleeChase_Chase');
rename('EnemyTick_FleeChase_Loop3', 'EnemyTick_FleeChase_CheckFlee');
rename('EnemyTick_FleeChase_Loop2', 'EnemyTick_FleeChase_AddToDisplay');
rename('EnemyTick_FleeChase_Loop',  'EnemyTick_FleeChase_Alive');

// -----------------------------------------------------------------------
// EnemyTick_Bouncing
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_Bouncing --');
rename('EnemyTick_Bouncing_Loop7', 'EnemyTick_Bouncing_RollPauseTimer');
rename('EnemyTick_Bouncing_Loop6', 'EnemyTick_Bouncing_UpdateBounceAnim');
rename('EnemyTick_Bouncing_Loop5', 'EnemyTick_Bouncing_CheckStalkTimer');
rename('EnemyTick_Bouncing_Loop4', 'EnemyTick_Bouncing_Chase');
rename('EnemyTick_Bouncing_Loop3', 'EnemyTick_Bouncing_CheckPauseTimer');
rename('EnemyTick_Bouncing_Loop2', 'EnemyTick_Bouncing_AddToDisplay');
rename('EnemyTick_Bouncing_Loop',  'EnemyTick_Bouncing_Alive');

// -----------------------------------------------------------------------
// EnemyTick_ProjectileFire
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_ProjectileFire --');
rename('EnemyTick_ProjectileFire_Loop6',       'EnemyTick_ProjectileFire_ApplyTurn');
rename('EnemyTick_ProjectileFire_Loop5',       'EnemyTick_ProjectileFire_TurnRight');
rename('EnemyTick_ProjectileFire_Loop4',       'EnemyTick_ProjectileFire_TrackPlayer');
rename('EnemyTick_ProjectileFire_Loop3',       'EnemyTick_ProjectileFire_ChooseDirection');
rename('EnemyTick_ProjectileFire_Loop2',       'EnemyTick_ProjectileFire_CheckAttackTimer');
rename('EnemyTick_ProjectileFire_Loop',        'EnemyTick_ProjectileFire_Alive');
rename('EnemyTick_ProjectileFire_Move_Loop2',  'EnemyTick_ProjectileFire_Move_CheckMoving');
rename('EnemyTick_ProjectileFire_Move_Loop',   'EnemyTick_ProjectileFire_Move_HandleDamage');

// -----------------------------------------------------------------------
// EnemyTick_StationaryShooter (body contains EnemyTakeDamage_CheckDeath labels)
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_StationaryShooter --');
rename('EnemyTick_StationaryShooter_Loop2', 'EnemyTick_StationaryShooter_SpawnProjectile');
rename('EnemyHoming_UpdateSprite_Loop',     'EnemyHoming_UpdateSprite_SetFlip');

// -----------------------------------------------------------------------
// ProjectileTick_HomingAlt
// -----------------------------------------------------------------------
console.log('\n-- ProjectileTick_HomingAlt --');
rename('ProjectileTick_HomingAlt_Loop4', 'ProjectileTick_HomingAlt_CheckMoving');
rename('ProjectileTick_HomingAlt_Loop3', 'ProjectileTick_HomingAlt_Retarget');
rename('ProjectileTick_HomingAlt_Loop2', 'ProjectileTick_HomingAlt_HandleDamage');
rename('ProjectileTick_HomingAlt_Loop',  'ProjectileTick_HomingAlt_Active');

// -----------------------------------------------------------------------
// EnemyTick_IntermittentChase
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_IntermittentChase --');
rename('EnemyTick_IntermittentChase_Loop6',      'EnemyTick_IntermittentChase_ApplyDirection');
rename('EnemyTick_IntermittentChase_Loop5',      'EnemyTick_IntermittentChase_HomingDir');
rename('EnemyTick_IntermittentChase_Loop4',      'EnemyTick_IntermittentChase_TrackPlayer');
rename('EnemyTick_IntermittentChase_Loop3',      'EnemyTick_IntermittentChase_ChooseMove');
rename('EnemyTick_IntermittentChase_Loop2',      'EnemyTick_IntermittentChase_CheckMoveTimer');
rename('EnemyTick_IntermittentChase_Loop',       'EnemyTick_IntermittentChase_Alive');
rename('EnemyCharge_UpdateSprite_Loop2',         'EnemyCharge_UpdateSprite_SetFlip');
rename('EnemyCharge_UpdateSprite_Loop',          'EnemyCharge_UpdateSprite_AddToDisplay');

// -----------------------------------------------------------------------
// EnemyTick_RandomShooter
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_RandomShooter --');
rename('EnemyTick_RandomShooter_Loop4',       'EnemyTick_RandomShooter_TrackPlayer');
rename('EnemyTick_RandomShooter_Loop3',       'EnemyTick_RandomShooter_RollShoot');
rename('EnemyTick_RandomShooter_Loop2',       'EnemyTick_RandomShooter_CheckAttackTimer');
rename('EnemyTick_RandomShooter_Loop',        'EnemyTick_RandomShooter_Alive');
rename('EnemyTick_RandomShooter_Move_Loop3',  'EnemyTick_RandomShooter_Move_UpdateAnim');
rename('EnemyTick_RandomShooter_Move_Loop2',  'EnemyTick_RandomShooter_Move_HandleDamage');
rename('EnemyTick_RandomShooter_Move_Loop',   'EnemyTick_RandomShooter_Move_AddToDisplay');

// -----------------------------------------------------------------------
// EnemyTick_Teleporter
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_Teleporter --');
rename('EnemyTick_Teleporter_Loop4', 'EnemyTick_Teleporter_Return');
rename('EnemyTick_Teleporter_Loop3', 'EnemyTick_Teleporter_UpdateAnim');
rename('EnemyTick_Teleporter_Loop2', 'EnemyTick_Teleporter_Alive');
rename('EnemyTick_Teleporter_Loop',  'EnemyTick_Teleporter_Countdown');

// -----------------------------------------------------------------------
// EnemyAiChasePause_Tick (BurstFire AI)
// -----------------------------------------------------------------------
console.log('\n-- EnemyAiChasePause_Tick --');
rename('EnemyAiChasePause_Tick_Loop4',        'EnemyAiChasePause_Tick_ChaseAdvance');
rename('EnemyAiChasePause_Tick_Loop3',        'EnemyAiChasePause_Tick_AdvancePhase');
rename('EnemyAiChasePause_HandleDamage_Loop2','EnemyAiChasePause_HandleDamage_SetFlip');
rename('EnemyAiChasePause_HandleDamage_Loop', 'EnemyAiChasePause_HandleDamage_CheckMoving');

// -----------------------------------------------------------------------
// ProjectileTick_Straight
// -----------------------------------------------------------------------
console.log('\n-- ProjectileTick_Straight --');
rename('ProjectileTick_Straight_Loop', 'ProjectileTick_Straight_Return');

// -----------------------------------------------------------------------
// EnemyTick_HomingShooter
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_HomingShooter --');
rename('EnemyTick_HomingShooter_Loop2_Done', 'EnemyTick_HomingShooter_SpawnNext');
rename('EnemyTick_HomingShooter_Loop2',      'EnemyTick_HomingShooter_SpawnProjectiles');
rename('EnemyTick_HomingShooter_Loop',       'EnemyTick_HomingShooter_Alive');
rename('EnemyMultiProjectile_UpdateSprite_Loop', 'EnemyMultiProjectile_UpdateSprite_SetFlip');

// -----------------------------------------------------------------------
// ProjectileTick_Homing
// -----------------------------------------------------------------------
console.log('\n-- ProjectileTick_Homing --');
rename('ProjectileTick_Homing_Loop2',  'ProjectileTick_Homing_ArmingDelay');
rename('ProjectileTick_Homing_Loop',   'ProjectileTick_Homing_Active');
rename('EnemyChase_Move_Loop2',        'EnemyChase_Move_UpdateAnim');
rename('EnemyChase_Move_Loop',         'EnemyChase_Move_HandleDamage');

// -----------------------------------------------------------------------
// EnemyTick_FastBurstShooter
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_FastBurstShooter --');
rename('EnemyTick_FastBurstShooter_Loop2_Done', 'EnemyTick_FastBurstShooter_SpawnNext');
rename('EnemyTick_FastBurstShooter_Loop2',      'EnemyTick_FastBurstShooter_SpawnProjectiles');
rename('EnemyTick_FastBurstShooter_Loop',       'EnemyTick_FastBurstShooter_Alive');
rename('EnemySpreadShot_UpdateSprite_Loop',     'EnemySpreadShot_UpdateSprite_SetFlip');

// -----------------------------------------------------------------------
// EnemyTick_SequentialFire / EnemyAiChaseFireJumpTable
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_SequentialFire / EnemyAiChaseFireJumpTable --');
rename('EnemyTick_SequentialFire_Loop',          'EnemyTick_SequentialFire_Alive');
rename('EnemyAiChaseFireJumpTable_Loop4',         'EnemyAiChaseFireJumpTable_RetargetStop');
rename('EnemyAiChaseFireJumpTable_Loop3',         'EnemyAiChaseFireJumpTable_ChaseStop');
rename('EnemyAiChaseFireJumpTable_Loop2',         'EnemyAiChaseFireJumpTable_RetargetPhase');
rename('EnemyAiChaseFireJumpTable_Loop',          'EnemyAiChaseFireJumpTable_ChasePhase');
rename('ProjectileTick_Phase2_Done',              'ProjectileTick_Phase2_SpawnNext');
rename('ProjectileTick_PostCollision_Loop3',      'ProjectileTick_PostCollision_DrawSprite');
// NOTE: ProjectileTick_PostCollision_Loop2 is a DATA label (LEA target) — must NOT be renamed
rename('ProjectileTick_PostCollision_Loop',       'ProjectileTick_PostCollision_SetFlip');

// -----------------------------------------------------------------------
// ProjectileTick_Spiral
// -----------------------------------------------------------------------
console.log('\n-- ProjectileTick_Spiral --');
rename('ProjectileTick_Spiral_OutOfBounds_Loop2', 'ProjectileTick_Spiral_OutOfBounds_Return');
rename('ProjectileTick_Spiral_OutOfBounds_Loop',  'ProjectileTick_Spiral_OutOfBounds_Render');

// -----------------------------------------------------------------------
// EnemyTick_SpiralBurst / EnemyAiSpiralJumpTable
// -----------------------------------------------------------------------
console.log('\n-- EnemyTick_SpiralBurst / EnemyAiSpiralJumpTable --');
rename('EnemyTick_SpiralBurst_Loop',          'EnemyTick_SpiralBurst_Alive');
rename('EnemyAiSpiralJumpTable_Loop4',        'EnemyAiSpiralJumpTable_RetargetStop');
rename('EnemyAiSpiralJumpTable_Loop3',        'EnemyAiSpiralJumpTable_ChaseStop');
rename('EnemyAiSpiralJumpTable_Loop2',        'EnemyAiSpiralJumpTable_RetargetPhase');
rename('EnemyAiSpiralJumpTable_Loop',         'EnemyAiSpiralJumpTable_ChasePhase');
rename('ProjectileTick2_Phase1_Loop',         'ProjectileTick2_Phase1_Advance');
rename('ProjectileTick2_Phase2_Done',         'ProjectileTick2_Phase2_SpawnNext');
rename('ProjectileTick2_PostCollision_Loop2', 'ProjectileTick2_PostCollision_SetFlip');
rename('ProjectileTick2_PostCollision_Loop',  'ProjectileTick2_PostCollision_CheckMoving');

// -----------------------------------------------------------------------
// ProjectileTick_OrbitingSpiral
// -----------------------------------------------------------------------
console.log('\n-- ProjectileTick_OrbitingSpiral --');
rename('ProjectileTick_OrbitingSpiral_OutOfBounds_Loop2', 'ProjectileTick_OrbitingSpiral_OutOfBounds_Return');
rename('ProjectileTick_OrbitingSpiral_OutOfBounds_Loop',  'ProjectileTick_OrbitingSpiral_OutOfBounds_Render');
rename('ProjectileTick_OrbitingSpiral_Loop2', 'ProjectileTick_OrbitingSpiral_UpdatePos');
rename('ProjectileTick_OrbitingSpiral_Loop',  'ProjectileTick_OrbitingSpiral_Orbiting');

// -----------------------------------------------------------------------
// EnemyTakeDamage2_CheckDeath (BossTick_OrbShield body)
// -----------------------------------------------------------------------
console.log('\n-- EnemyTakeDamage2_CheckDeath --');
rename('EnemyTakeDamage2_CheckDeath_Loop5', 'EnemyTakeDamage2_CheckDeath_CheckRadiusSign');
rename('EnemyTakeDamage2_CheckDeath_Loop4', 'EnemyTakeDamage2_CheckDeath_ClampRadius');
rename('EnemyTakeDamage2_CheckDeath_Loop3', 'EnemyTakeDamage2_CheckDeath_ResetAngle');
rename('EnemyTakeDamage2_CheckDeath_Loop2', 'EnemyTakeDamage2_CheckDeath_AnglePhase');
rename('EnemyTakeDamage2_CheckDeath_Loop',  'EnemyTakeDamage2_CheckDeath_Alive');

// -----------------------------------------------------------------------
// BossTakeDamage_CheckDeath (BossTick_MultiOrb body)
// -----------------------------------------------------------------------
console.log('\n-- BossTakeDamage_CheckDeath --');
rename('BossTakeDamage_CheckDeath_Loop6_Done', 'BossTakeDamage_CheckDeath_UpdateOrbPositions');
rename('BossTakeDamage_CheckDeath_Loop6',      'BossTakeDamage_CheckDeath_AbsWobble');
rename('BossTakeDamage_CheckDeath_Loop5',      'BossTakeDamage_CheckDeath_WobblePhase');
rename('BossTakeDamage_CheckDeath_Loop4',      'BossTakeDamage_CheckDeath_ResetAngle');
rename('BossTakeDamage_CheckDeath_Loop3_Done', 'BossTakeDamage_CheckDeath_ResetOrbPositions');
rename('BossTakeDamage_CheckDeath_Loop3',      'BossTakeDamage_CheckDeath_AnglePhase');
rename('BossTakeDamage_CheckDeath_Loop2',      'BossTakeDamage_CheckDeath_StaticPhase');
rename('BossTakeDamage_CheckDeath_Loop',       'BossTakeDamage_CheckDeath_Alive');

// -----------------------------------------------------------------------
// BossTakeDamage2_CheckDeath (BossTick_OrbRing body)
// -----------------------------------------------------------------------
console.log('\n-- BossTakeDamage2_CheckDeath --');
rename('BossTakeDamage2_CheckDeath_Loop6',      'BossTakeDamage2_CheckDeath_CheckAngleRange');
rename('BossTakeDamage2_CheckDeath_Loop5',      'BossTakeDamage2_CheckDeath_CheckAngleDir');
rename('BossTakeDamage2_CheckDeath_Loop4',      'BossTakeDamage2_CheckDeath_SkipLaunch');
rename('BossTakeDamage2_CheckDeath_Loop3_Done', 'BossTakeDamage2_CheckDeath_RotateOrbs');
rename('BossTakeDamage2_CheckDeath_Loop3',      'BossTakeDamage2_CheckDeath_ResetAngle');
rename('BossTakeDamage2_CheckDeath_Loop2',      'BossTakeDamage2_CheckDeath_AnglePhase');
rename('BossTakeDamage2_CheckDeath_Loop',       'BossTakeDamage2_CheckDeath_Alive');

// -----------------------------------------------------------------------
// ApplyDamageToPlayer
// -----------------------------------------------------------------------
console.log('\n-- ApplyDamageToPlayer --');
rename('ApplyDamageToPlayer_Loop2', 'ApplyDamageToPlayer_ClampZero');
rename('ApplyDamageToPlayer_Loop',  'ApplyDamageToPlayer_ClampMin');

// -----------------------------------------------------------------------
// SetRandomEnemyPosition
// -----------------------------------------------------------------------
console.log('\n-- SetRandomEnemyPosition --');
rename('SetRandomEnemyPosition_SetX_Loop2', 'SetRandomEnemyPosition_SetY');
rename('SetRandomEnemyPosition_SetX_Loop',  'SetRandomEnemyPosition_WrapY');
rename('SetRandomEnemyPosition_Loop',       'SetRandomEnemyPosition_WrapX');

// -----------------------------------------------------------------------
// InitBoss1_Common
// -----------------------------------------------------------------------
console.log('\n-- InitBoss1_Common --');
rename('InitBoss1_Common_Done6', 'InitBoss1_Common_WingLoop');
rename('InitBoss1_Common_Done5', 'InitBoss1_Common_TailLoop');
rename('InitBoss1_Common_Done4', 'InitBoss1_Common_MidBodyLoop');
rename('InitBoss1_Common_Done3', 'InitBoss1_Common_UpperBodyLoop');
rename('InitBoss1_Common_Done2', 'InitBoss1_Common_NeckLoop');

// -----------------------------------------------------------------------
// Boss1State_AttackWait
// -----------------------------------------------------------------------
console.log('\n-- Boss1State_AttackWait --');
rename('Boss1State_AttackWait_Loop2', 'Boss1State_AttackWait_Return');
rename('Boss1State_AttackWait_Loop',  'Boss1State_AttackWait_CheckLunge');

// -----------------------------------------------------------------------
// Write output
// -----------------------------------------------------------------------
fs.writeFileSync(filePath, src, 'utf8');
console.log('\nDone. File written.');
