const fs = require('fs');
const content = fs.readFileSync('E:/Romhacking/vermilion/src/townbuild.asm', 'utf8');
const lines = content.split('\n');

// Lines to skip (NPC AI data blobs that incidentally contain F8/F9/FC bytes)
const skipLines = new Set([985, 1314, 2817, 2820, 2826, 3073, 3373, 3810, 4072, 4178, 4495, 5497]);

// Helper: get leading whitespace from a line
function indent(line) {
  const m = line.match(/^(\t+|\s+)/);
  return m ? m[1] : '\t';
}

// Trigger constant lookup (reverse: offset -> symbol)
const triggerSymbols = {
  0x00: 'TRIGGER_Blade_is_dead',
  0x02: 'TRIGGER_Treasure_of_troy_challenge_issued',
  0x03: 'TRIGGER_Fake_king_killed',
  0x04: 'TRIGGER_Treasure_of_troy_given_to_king',
  0x05: 'TRIGGER_Talked_to_real_king',
  0x06: 'TRIGGER_Treasure_of_troy_found',
  0x07: 'TRIGGER_Talked_to_king_after_given_treasure_of_troy',
  0x08: 'TRIGGER_Player_chose_to_stay_in_parma',
  0x0A: 'TRIGGER_Watling_villagers_asked_about_rings',
  0x0B: 'TRIGGER_Truffle_collected',
  0x0D: 'TRIGGER_Deepdale_king_secret_kept',
  0x0E: 'TRIGGER_Sanguios_book_offered',
  0x0F: 'TRIGGER_Accused_of_theft',
  0x10: 'TRIGGER_Stow_thief_defeated',
  0x11: 'TRIGGER_Asti_monster_defeated',
  0x12: 'TRIGGER_Stow_innocence_proven',
  0x13: 'TRIGGER_Sent_to_malaga',
  0x14: 'TRIGGER_Bearwulf_met',
  0x15: 'TRIGGER_Bearwulf_returned_home',
  0x16: 'TRIGGER_Helwig_old_woman_quest_started',
  0x1B: 'TRIGGER_Malaga_king_crowned',
  0x1C: 'TRIGGER_Barrow_map_received',
  0x1D: 'TRIGGER_Imposter_killed',
  0x1E: 'TRIGGER_Watling_monster_encounter',
  0x1F: 'TRIGGER_Tadcaster_treasure_quest_started',
  0x20: 'TRIGGER_Tadcaster_treasure_found',
  0x21: 'TRIGGER_Bully_first_fight_won',
  0x22: 'TRIGGER_Tadcaster_bully_triggered',
  0x24: 'TRIGGER_Helwig_men_rescued',
  0x25: 'TRIGGER_Uncle_tibor_visited',
  0x26: 'TRIGGER_Old_man_waiting_for_letter',
  0x27: 'TRIGGER_Old_man_and_woman_paired',
  0x28: 'TRIGGER_Swaffham_ruined',
  0x29: 'TRIGGER_Ring_of_earth_obtained',
  0x2A: 'TRIGGER_White_crystal_quest_started',
  0x2B: 'TRIGGER_Ring_of_wind_received',
  0x2C: 'TRIGGER_Red_crystal_quest_started',
  0x2D: 'TRIGGER_Red_crystal_received',
  0x2E: 'TRIGGER_Blue_crystal_quest_started',
  0x2F: 'TRIGGER_Blue_crystal_received',
  0x30: 'TRIGGER_Ate_spy_dinner',
  0x31: 'TRIGGER_Swaffham_ate_poisoned_food',
  0x32: 'TRIGGER_Digot_plant_received',
  0x33: 'TRIGGER_Spy_dinner_poisoned_flag',
  0x34: 'TRIGGER_Pass_to_carthahena_purchased',
  0x35: 'TRIGGER_Sword_stolen_by_blacksmith',
  0x36: 'TRIGGER_Sword_retrieved_from_blacksmith',
  0x37: 'TRIGGER_Player_has_sword_of_vermilion',
  0x38: 'TRIGGER_Tsarkon_is_dead',
  0x39: 'TRIGGER_Carthahena_boss_met',
  0x3A: 'TRIGGER_Alarm_clock_rang',
  0x3B: 'TRIGGER_Crown_received',
  0x3C: 'TRIGGER_Girl_left_for_stow',
  0x3E: 'TRIGGER_Keltwick_girl_sleeping',
  0x3F: 'TRIGGER_Old_man_has_received_sketch',
  0x40: 'TRIGGER_Dragon_shield_offered',
};

function triggerSym(v) {
  return triggerSymbols[v] || ('$' + v.toString(16).toUpperCase().padStart(2, '0'));
}

function parseDcbTokens(str) {
  str = str.replace(/;.*$/, '').trim();
  return str.split(',').map(function(s) { return s.trim(); }).filter(function(s) { return s.length > 0; });
}

function tokenToNum(tok) {
  if (!tok) return null;
  tok = tok.trim();
  if (tok.match(/^\$[0-9A-Fa-f]+$/)) return parseInt(tok.slice(1), 16);
  return null;
}

function getComment(line) {
  const m = line.match(/;(.*)$/);
  return m ? ' ' + m[0] : '';
}

function isF8Line(line) { return /^\s*dc\.b\s+\$F8\b/i.test(line); }
function isScriptTriggersLine(line) { return /^\s*dc\.b\s+SCRIPT_TRIGGERS\b/i.test(line); }
function isF9Line(line) { return /^\s*dc\.b\s+\$F9\b/i.test(line); }
function isFBLine(line) { return /^\s*dc\.b\s+\$FB\b/i.test(line); }
function isFCLine(line) { return /^\s*dc\.b\s+\$FC\b/i.test(line); }

// Matches entry lines: dc.b $00, $XX  or  dc.b $01, $XX
function isF9EntryLine(line) {
  return /^\s*dc\.b\s+\$(00|01),\s*\$[0-9A-Fa-f]{2}\s*(;.*)?$/i.test(line);
}

// Emit F9 entries from a token array starting at index j, consuming 'remaining' entries.
// Returns { outLines, nextJ } where outLines are the macro lines to emit and nextJ is the
// index after the last consumed token.
function emitF9Entries(toks, j, remaining, tab) {
  const outLines = [];
  while (remaining > 0 && j < toks.length) {
    const discV = tokenToNum(toks[j]);
    if (discV === 2) {
      const b1 = toks[j+1] || '$00';
      const b2 = toks[j+2] || '$00';
      const b3 = toks[j+3] || '$00';
      const b4 = toks[j+4] || '$00';
      const n1 = tokenToNum(b1) || 0;
      const n2 = tokenToNum(b2) || 0;
      const n3 = tokenToNum(b3) || 0;
      const n4 = tokenToNum(b4) || 0;
      const bcd = (n1 * 0x1000000 + n2 * 0x10000 + n3 * 0x100 + n4);
      const bcdHex = '$' + bcd.toString(16).toUpperCase().padStart(8, '0');
      outLines.push(tab + 'script_give_kims ' + bcdHex);
      j += 5;
    } else if (discV === 1) {
      outLines.push(tab + 'script_reveal_map ' + toks[j+1]);
      j += 2;
    } else if (discV === 0) {
      const v = tokenToNum(toks[j+1]);
      const sym = v !== null ? triggerSym(v) : (toks[j+1] || '$00');
      outLines.push(tab + 'script_set_trigger ' + sym);
      j += 2;
    } else {
      // Unknown discriminator — stop
      break;
    }
    remaining--;
  }
  return { outLines: outLines, nextJ: j };
}

const out = [];
let i = 0;
let changed = 0;

while (i < lines.length) {
  const lineNum = i + 1;
  const line = lines[i];
  const tab = indent(line);

  if (skipLines.has(lineNum)) {
    out.push(line);
    i++;
    continue;
  }

  // --- $F8 standalone ---
  if (isF8Line(line)) {
    const dcbContent = line.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
    const toks = parseDcbTokens(dcbContent);
    const count = tokenToNum(toks[1]);
    if (count !== null) {
      const args = toks.slice(2, 2 + count);
      const symArgs = args.map(function(t) {
        const v = tokenToNum(t);
        return v !== null ? triggerSym(v) : t;
      });
      const comment = getComment(line);
      if (symArgs.length === 1) {
        out.push(tab + 'script_cmd_triggers ' + symArgs[0] + comment);
      } else if (symArgs.length === 2) {
        out.push(tab + 'script_cmd_triggers ' + symArgs[0] + ', ' + symArgs[1] + comment);
      } else {
        out.push(line);
      }
      // Emit any trailing $00 tokens after the consumed args
      const trailingStart = 2 + count;
      for (let k = trailingStart; k < toks.length; k++) {
        const v = tokenToNum(toks[k]);
        if (v === 0) {
          out.push(tab + 'dc.b\t$00');
        }
      }
      changed++;
    } else {
      out.push(line);
    }
    i++;
    continue;
  }

  // --- SCRIPT_TRIGGERS (already partially symbolic) ---
  if (isScriptTriggersLine(line)) {
    const dcbContent = line.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
    const toks = parseDcbTokens(dcbContent);
    const count = tokenToNum(toks[1]);
    if (count !== null) {
      const args = toks.slice(2, 2 + count);
      const symArgs = args.map(function(t) {
        const v = tokenToNum(t);
        if (v === 0) return null; // skip zero (it's not a valid trigger, may be padding)
        return v !== null ? triggerSym(v) : t;
      }).filter(function(t) { return t !== null; });
      const comment = getComment(line);
      if (symArgs.length === 1) {
        out.push(tab + 'script_cmd_triggers ' + symArgs[0] + comment);
      } else if (symArgs.length === 2) {
        out.push(tab + 'script_cmd_triggers ' + symArgs[0] + ', ' + symArgs[1] + comment);
      } else {
        // Keep original if we can't parse cleanly
        out.push(line);
      }
      // Emit any trailing $00 tokens after consumed args
      const trailingStart = 2 + count;
      for (let k = trailingStart; k < toks.length; k++) {
        const v = tokenToNum(toks[k]);
        if (v === 0) {
          out.push(tab + 'dc.b\t$00');
        }
      }
    } else {
      // count is a symbol, not a number — handle specially
      // e.g. SCRIPT_TRIGGERS, $01, TRIGGER_Truffle_collected
      const trigArg = toks[2]; // already symbolic
      const comment = getComment(line);
      out.push(tab + 'script_cmd_triggers ' + trigArg + comment);
      changed++;
    }
    changed++;
    i++;
    continue;
  }

  // --- $FB SCRIPT_YES_NO ---
  if (isFBLine(line)) {
    const dcbContent = line.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
    const toks = parseDcbTokens(dcbContent);
    const response = toks[1];
    const triggerTok = toks[2];
    const extTrigger = toks[3] || '$00';
    const triggerV = tokenToNum(triggerTok);
    const triggerStr = triggerV !== null ? triggerSym(triggerV) : triggerTok;
    const comment = getComment(line);
    out.push(tab + 'script_cmd_yes_no ' + response + ', ' + triggerStr + ', ' + extTrigger + comment);
    // Emit any trailing $00 tokens after the 3 consumed args ($FB, response, trigger, ext_trigger)
    for (let k = 4; k < toks.length; k++) {
      const v = tokenToNum(toks[k]);
      if (v === 0) {
        out.push(tab + 'dc.b\t$00');
      }
    }
    changed++;
    i++;
    continue;
  }

  // --- $FC SCRIPT_QUESTION (standalone line) ---
  if (isFCLine(line)) {
    const dcbContent = line.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
    const toks = parseDcbTokens(dcbContent);
    const response = toks[1];
    const comment = getComment(line);
    out.push(tab + 'script_cmd_question ' + response + comment);
    changed++;
    i++;
    continue;
  }

  // --- $FC inline in string with arg on SAME line: "text.", $FC, $NN ---
  if (/dc\.b\s+"/i.test(line) && /,\s*\$FC,\s*\$[0-9A-Fa-f]{2}/i.test(line)) {
    const m = line.match(/^(\s*dc\.b\s+"[^"]*"(?:,\s*\$FE)*),\s*\$FC,\s*(\$[0-9A-Fa-f]{2})(.*)?$/i);
    if (m) {
      out.push(m[1]);
      const responseToken = m[2];
      out.push(tab + 'script_cmd_question ' + responseToken);
      changed++;
      i++;
      continue;
    }
  }

  // --- $FC inline in string with arg on NEXT line: "text.", $FC\n$08, $00 ---
  if (/dc\.b\s+"/i.test(line) && /,\s*\$FC\s*(;.*)?$/i.test(line)) {
    const nextLine = lines[i + 1];
    if (nextLine) {
      const nextContent = nextLine.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
      const nextToks = parseDcbTokens(nextContent);
      const responseV = tokenToNum(nextToks[0]);
      if (responseV !== null) {
        // Strip the $FC from end of current line
        const strippedLine = line.replace(/,\s*\$FC\s*(;.*)?$/, '');
        out.push(strippedLine);
        out.push(tab + 'script_cmd_question ' + nextToks[0]);
        // Emit ALL remaining tokens after the response byte as raw dc.b
        if (nextToks.length > 1) {
          out.push(tab + 'dc.b\t' + nextToks.slice(1).join(', '));
        }
        changed++;
        i += 2;
        continue;
      }
    }
  }

  // --- $F9 with entries packed on ONE line (has more than just count token) ---
  if (isF9Line(line)) {
    const rawDcbContent = line.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
    let toks = parseDcbTokens(rawDcbContent);
    const count = tokenToNum(toks[1]);
    if (count !== null && toks.length > 2) {
      // Check if line ends with an incomplete last entry (odd number of data tokens)
      // An incomplete line means we need to read the next dc.b line to get remaining bytes.
      const dataToks = toks.slice(2);
      const linesConsumed = [line];

      // Build a combined token list if the line ends with an odd number of data tokens
      // (meaning the last entry is split across lines). We keep reading continuation lines
      // until we have enough tokens for all 'count' entries.
      // For type-0 and type-1 entries: 2 tokens each. For type-2: 5 tokens each.
      // Since we don't know types in advance, we use a simpler heuristic:
      // if the number of remaining data tokens is odd (not fully paired), read next line.
      // More precisely: attempt to consume entries and if we run out of tokens mid-entry,
      // fetch the next line's tokens.
      let allToks = toks.slice(2); // data tokens only (after $F9 and count)
      let nextLineIdx = i + 1;
      // Try to determine if we need more tokens by simulating consumption
      function needsMoreTokens(dataToks, needed) {
        let pos = 0;
        let consumed = 0;
        while (consumed < needed && pos < dataToks.length) {
          const disc = tokenToNum(dataToks[pos]);
          if (disc === 2) { pos += 5; }
          else if (disc === 0 || disc === 1) { pos += 2; }
          else { break; }
          consumed++;
        }
        return consumed < needed;
      }

      // If we need more tokens, read continuation lines
      while (needsMoreTokens(allToks, count) && nextLineIdx < lines.length) {
        const nextLine = lines[nextLineIdx];
        const nextContent = nextLine.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
        const nextToks = parseDcbTokens(nextContent);
        linesConsumed.push(nextLine);
        allToks = allToks.concat(nextToks);
        nextLineIdx++;
      }

      const comment = getComment(line);
      out.push(tab + 'script_cmd_actions ' + count + comment);
      const result = emitF9Entries(allToks, 0, count, tab);
      for (const l of result.outLines) out.push(l);

      // Emit any trailing $00 tokens after consumed entries
      for (let k = result.nextJ; k < allToks.length; k++) {
        const v = tokenToNum(allToks[k]);
        if (v === 0) {
          out.push(tab + 'dc.b\t$00');
        }
      }

      changed++;
      // Advance i past all consumed source lines
      i += linesConsumed.length;
      continue;
    }

    // $F9 header-only line (count only, entries follow on next lines)
    if (count !== null && toks.length === 2) {
      const comment = getComment(line);
      out.push(tab + 'script_cmd_actions ' + count + comment);
      changed++;
      i++;
      continue;
    }
  }

  // --- $F9 entry lines: dc.b $01, $XX  or  dc.b $00, $XX ---
  if (isF9EntryLine(line)) {
    const dcbContent = line.replace(/^\s*dc\.b\s+/i, '').replace(/;.*$/, '').trim();
    const toks = parseDcbTokens(dcbContent);
    const disc = tokenToNum(toks[0]);
    const val = toks[1];
    const comment = getComment(line);
    if (disc === 1) {
      out.push(tab + 'script_reveal_map ' + val + comment);
    } else if (disc === 0) {
      const v = tokenToNum(val);
      const sym = v !== null ? triggerSym(v) : val;
      out.push(tab + 'script_set_trigger ' + sym + comment);
    } else {
      out.push(line);
    }
    changed++;
    i++;
    continue;
  }

  out.push(line);
  i++;
}

console.log('Changed lines:', changed);
fs.writeFileSync('E:/Romhacking/vermilion/src/townbuild.asm', out.join('\n'), 'utf8');
