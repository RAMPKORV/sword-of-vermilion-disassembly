const fs = require('fs');
let src = fs.readFileSync('E:/Romhacking/vermilion/src/sram.asm', 'utf8');

const renames = [
  // SaveGameToSram loops
  ['SaveGameToSram_Done10', 'SaveGameToSram_CopyEventsLoop'],
  ['SaveGameToSram_Done9', 'SaveGameToSram_CopyKimsLoop'],
  ['SaveGameToSram_Done8', 'SaveGameToSram_CopyEquippedLoop'],
  ['SaveGameToSram_Done7', 'SaveGameToSram_CopyEquipmentLoop'],
  ['SaveGameToSram_Done6', 'SaveGameToSram_CopyMagicsLoop'],
  ['SaveGameToSram_Done5', 'SaveGameToSram_CopyItemsLoop'],
  ['SaveGameToSram_Done4', 'SaveGameToSram_CopyPositionLoop'],
  ['SaveGameToSram_Done3', 'SaveGameToSram_CopyTownsVisitedLoop'],
  ['SaveGameToSram_Done', 'SaveGameToSram_CopyNameLoop'],
  // CalculateChecksumAndBackupSram (most specific first)
  ['CalculateChecksumAndBackupSram_Loop_Done', 'CalculateChecksumAndBackupSram_BackupCopyLoop'],
  ['CalculateChecksumAndBackupSram_Done', 'CalculateChecksumAndBackupSram_ChecksumLoop'],
  ['CalculateChecksumAndBackupSram_Loop', 'CalculateChecksumAndBackupSram_ChecksumNext'],
  // FileMenu labels (most specific first)
  ['FileMenu_VerifyChecksum_Loop6', 'FileMenu_RestoreFromBackup'],
  ['FileMenu_VerifyChecksum_Loop5', 'FileMenu_LoadFromSlot'],
  ['FileMenu_VerifyChecksum_Loop4', 'FileMenu_NoSave'],
  ['FileMenu_VerifyChecksum_Loop3', 'FileMenu_MoveCursor'],
  ['FileMenu_VerifyChecksum_Loop', 'FileMenu_VerifyBackup'],
  ['FileMenu_VerifyChecksum_Return', 'FileMenuPhase_WaitSelection_Return'],
  ['FileMenu_VerifyChecksum', 'FileMenu_ChecksumAndLoad'],
  // LoadGameFromSave loops (most specific first)
  ['LoadGameFromSave_Done10', 'LoadGameFromSave_CopyEventsLoop'],
  ['LoadGameFromSave_Done9', 'LoadGameFromSave_CopyKimsLoop'],
  ['LoadGameFromSave_Done8', 'LoadGameFromSave_CopyEquippedLoop'],
  ['LoadGameFromSave_Done7', 'LoadGameFromSave_CopyEquipmentLoop'],
  ['LoadGameFromSave_Done6', 'LoadGameFromSave_CopyMagicsLoop'],
  ['LoadGameFromSave_Done5', 'LoadGameFromSave_CopyItemsLoop'],
  ['LoadGameFromSave_Done4', 'LoadGameFromSave_CopyPositionLoop'],
  ['LoadGameFromSave_Done3', 'LoadGameFromSave_CopyTownsVisitedLoop'],
  ['LoadGameFromSave_Done', 'LoadGameFromSave_CopyNameLoop'],
  // VerifySaveChecksum (most specific first)
  ['VerifySaveChecksum_Done', 'VerifySaveChecksum_Loop'],
  ['VerifySaveChecksum_Loop', 'VerifySaveChecksum_Next'],
  // CopySramBackupToSlot
  ['CopySramBackupToSlot_Done', 'CopySramBackupToSlot_CopyLoop'],
];

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

for (const [from, to] of renames) {
  const re = new RegExp('(?<![\\w])' + escapeRegex(from) + '(?![\\w])', 'g');
  const matches = src.match(re);
  const count = matches ? matches.length : 0;
  src = src.replace(re, to);
  if (count > 0) console.log(from + ' -> ' + to + ' (' + count + ' occurrences)');
}

fs.writeFileSync('E:/Romhacking/vermilion/src/sram.asm', src);
console.log('Done.');
