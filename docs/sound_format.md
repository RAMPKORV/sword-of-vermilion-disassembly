# Sound Format — Sword of Vermilion

Reference for the music and sound-effects system in `src/sound.asm`.

---

## Overview

The sound system is a custom 68000-side driver. It maintains up to 13 simultaneous
channels (9 FM + 4 FM bank-2) plus one DAC/special channel. Each channel reads a
compact bytecode script that encodes notes and control commands.

The Z80 CPU is used only for DAC sample playback; all YM2612 register writes are done
by the 68000 after acquiring the Z80 bus.

---

## Channel RAM Layout

All channel state is stored in 68000 RAM. Each channel occupies a **$30-byte struct**
(field names defined in `constants.asm` as `fmch_*` equates):

| Offset | Name               | Size | Description |
|--------|--------------------|------|-------------|
| `$00`  | `fmch_flags`       | byte | Status bits (see below) |
| `$01`  | `fmch_channel_id`  | byte | YM2612 channel index + mode flags |
| `$02`  | `fmch_tempo_flags` | byte | Tempo modifier (bit1 = double-tempo) |
| `$03`  | `fmch_script_ptr_hi` | byte | High byte of script offset (base `$00093C00`) |
| `$04`  | `fmch_script_ptr_lo` | byte | Low byte of script offset |
| `$05`  | `fmch_transpose`   | byte | Semitone transpose added to all notes |
| `$06`  | `fmch_vibrato_idx` | byte | LFO vibrato table index (0 = none) |
| `$07`  | `fmch_arpeggio_idx`| byte | Arpeggio sequence table index (0 = none) |
| `$08`  | `fmch_volume`      | byte | Channel volume (added to operator TL) |
| `$09`  | `fmch_call_sp`     | byte | Script subroutine call-stack pointer (struct offset) |
| `$0A`  | `fmch_tick_ctr`    | word | Tick countdown; triggers next note when it reaches 0 |
| `$0C`  | `fmch_note_freq`   | word | Current note frequency (PSG: period; FM: F-number) |
| `$0E`  | `fmch_note_duration` | word | Duration in ticks; reloaded into tick_ctr on new note |
| `$10`  | `fmch_pitch_slide` | byte | Pitch-slide rate (signed; added to note_freq each frame) |
| `$11`  | `fmch_lfo_phase`   | byte | LFO vibrato table read position |
| `$13`  | `fmch_arp_phase`   | byte | Arpeggio sequence read position |
| `$14`  | `fmch_pitch_bend`  | byte | Pitch-bend counter (`$1F`=note-end, `$FF`=no-bend) |
| `$16`  | `fmch_lfo_depth`   | byte | LFO depth/amplitude accumulator |
| `$1C`  | `fmch_op_algo`     | byte | FM algorithm/feedback byte (first of 5-byte instrument block) |
| `$1D`  | `fmch_op1_tl`      | byte | Operator 1 total-level offset |
| `$1E`  | `fmch_op3_tl`      | byte | Operator 3 total-level offset |
| `$1F`  | `fmch_op2_tl`      | byte | Operator 2 total-level offset |
| `$20`  | `fmch_op4_tl`      | byte | Operator 4 total-level offset |
| `$21`  | `fmch_pan_stereo`  | byte | Stereo panning written to YM2612 reg `$B4` |

### `fmch_flags` bit definitions

| Bit | Meaning |
|-----|---------|
| 7   | Channel active (set = process this channel each tick) |
| 6   | DAC/echo mode enabled |
| 5   | Pitch-slide mode active |
| 2   | Channel muted (suppress YM2612 key-on/off) |
| 1   | Key-off pending |

### `fmch_channel_id` bit definitions

| Bit | Meaning |
|-----|---------|
| 7   | Use data-sequencer path (FM channels with external instrument data) |
| 4   | Hold/sustain flag (suppress new note attacks) |
| 2   | FM port select: 0 = port A (`$A04000`), 1 = port B (`$A04002`) |
| 1-0 | YM2612 channel index within the selected port (0-2) |

---

## Channel Address Map

| Range | Contents |
|-------|----------|
| `$FFF430` – `$FFF5AF` | Bank 1: 9 FM channels, stride `$30` (channels 0–8) |
| `$FFF520`             | DAC / special channel struct |
| `$FFF5E0` – `$FFF66F` | Bank 2: 4 FM channels, stride `$30` (channels 0–3) |
| `$FFF670` – `$FFF678` | Bank-2 instrument data buffer |

---

## Sound Driver RAM Variables

| Address  | Name                  | Description |
|----------|-----------------------|-------------|
| `$FFF400` | `Sound_cmd_queue`    | Pending sound command byte (`$80` = idle) |
| `$FFF401` | `Sound_tempo_ctr`    | Tempo tick countdown |
| `$FFF402` | `Sound_tempo_reload` | Tempo reload value (frames per beat) |
| `$FFF404` |                      | Command routing byte (read by `ProcessSound_CommandQueue`) |
| `$FFF41C` | `Sound_fade_volume`  | Fade-out volume level (`$00` = off/complete) |
| `$FFF41D` | `Sound_fade_speed`   | Fade-out tick rate |
| `$FFF421` | `Sound_part_flag`    | FM bank selector (`$00` = bank 1, `$80` = bank 2) |

---

## Sound Command Byte Ranges (top-level)

The `ProcessSound_CommandQueue` function reads `$FFF404` each frame and routes by value:

| Range         | Action |
|---------------|--------|
| `$00–$7F`     | Idle (bit 7 clear) — no command |
| `$81–$9C`     | Start music track: index = value − `$81`; loads channel scripts from `SoundCommand_JumpTable_Loop_Data2` |
| `$9D–$9F`     | Stop all sounds |
| `$A0–$C1`     | Start SFX: index = value − `$A0`; reads SFX descriptor from `SoundCommand_JumpTable_Loop2_Data` |
| `$C2–$DE`     | Stop all sounds |
| `$E0–$E3`     | Special commands via `SoundCommand_JumpTable` (e.g., `$E0` = trigger fade-out) |
| `$E4+`        | Stop all sounds |

After processing, `$FFF404` is reset to `$80`.

---

## Sound Script Bytecode

Each channel's script is a stream of bytes pointed to by `fmch_script_ptr_hi/lo` relative
to base address `$00093C00`. All music/SFX data is stored in `data/sound/sound_cmd_data.bin`
(22,350 bytes).

### Byte interpretation

A script byte is interpreted as either a **note** or a **command**:

- **Bytes `$00–$DF`** — note/duration data (below the `SOUND_SCRIPT_CMD_THRESHOLD = $E0` boundary)
- **Bytes `$E0–$FF`** — script commands (handled by `ProcessSoundScriptCommand`)

### Note bytes (< `$E0`)

| Value        | Meaning |
|--------------|---------|
| `$00–$7F`    | Duration value. Written to `fmch_tick_ctr` and `fmch_note_duration`. If `fmch_tempo_flags` bit 1 is set, the value is doubled. |
| `$80`        | PSG rest (sets key-off flag in `fmch_flags`) |
| `$81–$DF`    | PSG note. Subtract `$80`, add `fmch_transpose`, look up 16-bit period from `SetPSGNoteFrequency_Loop2_Data` (128-entry table). |

For FM channels (bit 7 of `fmch_channel_id` clear): a negative note byte (bit 7 set)
overrides the FM F-number directly; the following byte provides the duration.

### Script Commands (`$E0`–`$FF`)

Index = command byte − `$E0`. Dispatched via `SoundScriptCommandJumpTable` (31 entries,
4 bytes each).

| Index | Byte  | Actual Handler | Description |
|-------|-------|----------------|-------------|
| 0–3   | `$E0`–`$E3` | `SoundScript_NopCommand` | No-op |
| 4     | `$E4` | `SoundScript_NopCommand_Loop` | **Set tempo**: next byte is added to `$FFF402` (tempo reload); resets `$FFF401` to 1 |
| 5     | `$E5` | `SoundScript_NopCommand_Loop2` | **Enable DAC**: sets bit 4 of `fmch_channel_id` |
| 6     | `$E6` | `SoundScript_NopCommand_Loop3` | **Disable DAC**: clears bit 4, writes `$2B`/`$00` to YM2612 (DAC off) |
| 7     | `$E7` | `SoundScript_NopCommand` | No-op |
| 8     | `$E8` | `SoundScript_NopCommand_Loop4` | **Set echo/reverb flag**: next byte non-zero sets bit 6 of `fmch_flags`, zero clears it |
| 9     | `$E9` | `SoundScript_NopCommand_Loop5` | **Set arpeggio / load DAC sample**: next byte = arpeggio index or DAC slot; if non-zero triggers DAC upload via `LoadDAC_SampleToZ80` |
| 10    | `$EA` | `SoundCmd_SetFrequency` | **Set note duration override**: next byte = duration; doubles if double-tempo flag set |
| 11    | `$EB` | `SoundCmd_SetFrequency` | (same as `$EA`) |
| 12    | `$EC` | `SoundCmd_JumpToOffset_Loop` | **Add to volume**: next byte added to `fmch_volume`, then updates FM TL registers |
| 13    | `$ED` | `SoundCmd_SetFrequency` | (same as `$EA`) |
| 14    | `$EE` | `SoundScript_NopCommand` | No-op |
| 15    | `$EF` | `SoundCmd_SetFrequency_Loop` | **Set arpeggio + load instrument**: next byte = arpeggio index; loads FM algorithm from `FM_FrequencyTable` |
| 16    | `$F0` | `LoadFM_AlgorithmData_Return_Loop` | **Set volume (absolute)**: next byte written directly to `fmch_volume`, updates TL |
| 17    | `$F1` | `SoundScript_NopCommand` | No-op |
| 18    | `$F2` | `LoadFM_AlgorithmData_Return_Loop2` | **Key-off / stop channel**: clears `fmch_flags`, optionally calls `WriteFMChannelRegisters` |
| 19    | `$F3` | `LoadFM_AlgorithmData_Return_Loop3` | **PSG volume**: next byte masked to `$E0`, written to `PSG_port` |
| 20    | `$F4` | `LoadFM_AlgorithmData_Return_Loop4` | **Set vibrato**: next byte written to `fmch_vibrato_idx` |
| 21    | `$F5` | `SoundScript_NopCommand` | No-op |
| 22    | `$F6` | `SoundCmd_JumpToOffset` | **Jump**: next 2 bytes = big-endian 16-bit offset; sets `A4` to `$00093C00 + offset` |
| 23    | `$F7` | `SoundCmd_JumpToOffset_Loop2` | **Counted loop**: next byte = counter slot (struct offset), following byte = initial count; jumps to offset until counter expires |
| 24    | `$F8` | `SoundCmd_JumpToOffset_Loop3` | **Call subroutine**: pushes current script pointer onto call stack (at `fmch_call_sp`), then jumps |
| 25    | `$F9` | `SoundCmd_JumpToOffset_Loop4` | **Return from subroutine**: pops call stack into `A4` |
| 26    | `$FA` | `SoundCmd_JumpToOffset_Loop5` | **Set tempo flags**: next byte written to `fmch_tempo_flags` |
| 27    | `$FB` | `SoundCmd_JumpToOffset_Loop6` | **Transpose**: next byte added to `fmch_transpose` |
| 28    | `$FC` | `SoundCmd_JumpToOffset_Loop7` | **Set pitch-slide mode**: next byte non-zero sets bit 5 of `fmch_flags`, zero clears it |
| 29    | `$FD` | `SoundCmd_JumpToOffset_Loop8` | **Pan left**: writes `$C0` to `fmch_pan_stereo`, updates YM2612 reg `$B4` |
| 30    | `$FE` | `SoundCmd_JumpToOffset_Loop9` | **Pan right**: writes `$40` to `fmch_pan_stereo`, updates YM2612 reg `$B4` |
| 31    | `$FF` | `SoundCmd_JumpToOffset_Loop10` | **Pan center**: writes `$80` to `fmch_pan_stereo`, updates YM2612 reg `$B4` |

---

## Script Pointer Encoding

Script pointers are stored in the channel struct as two bytes relative to base
`$00093C00`:

```
absolute_address = $00093C00 + (fmch_script_ptr_hi << 8) | fmch_script_ptr_lo
```

`LoadSoundScriptPointer` reconstructs `A4` from these two bytes each tick.
`StoreSoundScriptPointer` saves `A4` back to the struct.

---

## Tempo System

- `$FFF402` (`Sound_tempo_reload`): frames-per-beat reload value. Set by music header or `$E4` command.
- `$FFF401` (`Sound_tempo_ctr`): decrements each frame. When it reaches 0, reloads from `$FFF402` and increments `fmch_tick_ctr` on all 9 bank-1 channels by 1.
- Each note's duration value in the script is the number of tempo ticks the note lasts.
- Double-tempo mode (bit 1 of `fmch_tempo_flags`) doubles the raw duration byte when it is stored.

---

## FM Frequency / Instrument Tables

### `FM_FrequencyTable` (src/sound.asm:1813)
Big-endian 16-bit F-number entries for FM notes. Indexed by arpeggio/instrument index
via `GetSoundDataPointer` (which resolves a relative offset from base `$00093C00`).

### `SetPSGNoteFrequency_Loop2_Data` (src/sound.asm:1309)
128 big-endian 16-bit PSG period values, one per semitone. Note byte `$81` maps to
index 1, `$FE` to index 126, etc. (index = note − `$80`, masked to 7 bits).

### `SoundCommand_JumpTable_Loop_Data` (src/sound.asm:1643)
32-byte table of per-track tempo reload values. Index = music command − `$81`.

### `SoundCommand_JumpTable_Loop_Data2` (src/sound.asm:1808)
Per-track script header table: pairs of (channel-count byte, relative-offset word)
describing how many channels each music track uses and where their scripts start.

### `SoundCommand_JumpTable_Loop2_Data` (src/sound.asm:1811)
SFX descriptor table, loaded from `data/sound/sound_cmd_data.bin` (22,350 bytes).
SFX index = command − `$A0`. Each entry is 9 bytes:
- byte 0: number of channels used − 1
- byte 1: channel slot assignment (2 = FM ch 0, 3–9 = FM ch 1–7)
- bytes 2–8: instrument/script data (copied into the channel struct at offset `$00`)

---

## LFO (Vibrato) System

`SoundLFO_PointerTable` (src/sound.asm:1658) contains 48 longword pointers to waveform
data. The vibrato index in `fmch_vibrato_idx` is used as a 1-based index into this
table (index 0 = no vibrato; indices 5–9 point to `SoundLFO_NullEntry`).

Each waveform is a stream of signed pitch-offset bytes with control terminators:

| Byte  | Meaning |
|-------|---------|
| `$80` | End of waveform (stop vibrato) |
| `$81` | Loop back to start |
| `$83` | Set repeat count (next byte = count) |
| `$84` | Pitch-bend up (next byte = rate) |
| `$85` | Pitch-bend down (next byte = rate) |

---

## DAC Sample System

Up to 10 PCM sample slots are defined in `LoadDAC_SampleToZ80_Data`
(src/sound.asm:1990). Each slot is a (start, end) longword pointer pair:

| Slot | Label / File |
|------|-------------|
| 0    | Null (no sample, start pointer = `$00000000`) |
| 1    | `data/sound/dac/dac_sample_99cc8.bin` |
| 2    | `data/sound/dac/dac_sample_9aab4.bin` |
| 3    | `data/sound/dac/dac_sample_9b492.bin` |
| 4    | Inline PCM data at `LoadDAC_SampleToZ80_Data_Entry_9C888` |
| 5    | Inline PCM data at `LoadDAC_SampleToZ80_Data_Entry_9CAF0` |
| 6    | `data/sound/dac/dac_sample_9cf28.bin` |
| 7    | Alias: `LoadDAC_SampleToZ80_Data_Entry_9CF28 + $1AB0` |
| 8    | `data/sound/dac/dac_sample_9ec38.bin` |
| 9    | Alias: `LoadDAC_SampleToZ80_Data_Entry_9EC38 + $114E` |
| 10   | All-`$FF` padding at `LoadDAC_SampleToZ80_Data_Entry_9FF7E` |

DAC upload (`LoadDAC_SampleToZ80`): acquires Z80 bus, copies sample bytes to Z80 RAM
at `$A00200` in 16-byte bursts via DBF loop, then releases bus and writes panning to
YM2612 reg `$B4`.

The DAC channel struct lives at `$FFF520`; `fmch_arp_phase` at `$FFF533` holds the
active sample slot index.

---

## YM2612 Register Write Protocol

All YM2612 access goes through `WriteYM2612Register` / `WriteYM2612Register_Part1`:

1. Acquire Z80 bus: write `$0100` to `Z80_bus_request` (`$A11100`).
2. Spin-wait until bus grant bit (bit 0) clears.
3. Poll YM2612 busy flag: bit 7 of `$A01FFD`; if busy, release bus, wait, retry.
4. Write register address to `$A04000` (port A) or `$A04002` (port B).
5. Three NOPs.
6. Write register value to `$A04001` or `$A04003`.
7. Release Z80 bus: write `$0000` to `Z80_bus_request`.

Port B is used when bit 2 of `fmch_channel_id` is set (FM channels 4–6 on the YM2612).

---

## Fade-Out System

Triggered by sound command `$E0`:
- Sets `$FFF41C` (fade level) to `$3F`, `$FFF41D` (fade speed) to `2`.
- Clears the DAC channel at `$FFF520`.

Each frame `ProcessSound_FadeOut` checks `$FFF41C`:
- Zero → no active fade.
- Non-zero → decrement `$FFF41D` counter; when it expires, decrement `$FFF41C` by 1
  and add 1 to `fmch_volume` on all 9 bank-1 channels (increasing attenuation).
- When `$FFF41C` reaches zero, calls `StopAllActiveSounds`.

---

## Misplaced Data Note

`TownTilesetPtrs_Gfx_8FEE6` and `TownTilesetPtrs_Gfx_9239A` are town tileset index
lookup tables that belong logically in `gfxdata.asm`. They are stranded at the start
of `src/sound.asm` because the disassembler placed them at these ROM addresses inside
the sound driver region. Physical relocation would change all downstream ROM offsets and
break bit-perfect output. See MOVE-006 note in the file header.

Similarly, `LoadBattleHudGraphics_Data` / `LoadBattleHudGraphics_Done_Data` (battle HUD
tile incbins) appear between the two tileset tables for the same reason.
