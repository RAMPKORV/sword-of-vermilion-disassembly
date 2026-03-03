// replace_raw_struct_offsets.js
// Replaces raw $2E/$2F/$30/$31/$32/$36 struct offset uses with named constants:
//   $2E(Ax) .l  -> obj_anim_ptr(Ax)       [NPC animation pointer]
//   $2E(Ax) .b  -> obj_hitbox_x_neg(Ax)   [hitbox left extent]
//   $2F(Ax) .b  -> obj_hitbox_x_pos(Ax)   [hitbox right extent]
//   $30(Ax) .b  -> obj_hitbox_y_neg(Ax)   [hitbox top extent]
//   $31(Ax) .b  -> obj_hitbox_y_pos(Ax)   [hitbox bottom extent]
//   $32(Ax) .l  -> obj_vel_x(Ax)          [X velocity fixed-point]
//   $36(Ax) .l  -> obj_vel_y(Ax)          [Y velocity fixed-point]
//
// Skips:
//   - $30(A2) / -$30(A2) / LEA $30(A2) = fmch_size stride (FM channel struct)
//   - LEA $30(A0) = map sector stride
//   - .w accesses to $2E/$30 = orbit center scratch (projectile special case)
//   - line 17691/17692: (A0)+ streaming load (keep as-is, already correct offset)

const fs = require('fs');
const raw = fs.readFileSync('vermilion.asm', 'utf8');
const lines = raw.replace(/\r\n/g, '\n').split('\n');

// Line-number allowlists for each replacement class
// (1-indexed line numbers from the survey)

// $2E .l -> obj_anim_ptr
const anim_ptr_lines = new Set([
    7930, 8014, 8032, 8043, 8061, 8070,
    8276, 8289, 8311, 8333, 8689,
    9458, 9512
    // NOTE: line 13173 is SUB.l $2E(A5) = orbit center scratch, skip it
]);

// $2E .b -> obj_hitbox_x_neg
const hb_x_neg_lines = new Set([
    7836,
    14067, 14094, 14126, 14150,
    14865, 14908, 14919,
    15342,
    16003, 16045,
    16682, 16705, 16724, 16747,
    16987, 17205,
    17500, 17579,
    17982, 18084, 18506
    // NOTE: line 17691 is (A0)+ stream, skip
]);

// $2F .b -> obj_hitbox_x_pos
const hb_x_pos_lines = new Set([
    7830,
    14068, 14095, 14127, 14151,
    14866, 14909, 14920,
    15338,
    16004, 16046,
    16683, 16706, 16725, 16748,
    16988, 17206,
    17501, 17580,
    17983, 18085, 18507
    // NOTE: line 17692 is (A0) stream, skip
]);

// $30 .b -> obj_hitbox_y_neg  (skip A2 and A0 = fmch/map stride)
const hb_y_neg_lines = new Set([
    7848,
    14069, 14096, 14128, 14152,
    14867, 14910, 14921,
    15356,
    16005, 16047,
    16684, 16707, 16726, 16749,
    16989, 17207,
    17502, 17581,
    17984, 18086, 18508
]);

// $31 .b -> obj_hitbox_y_pos
const hb_y_pos_lines = new Set([
    7842,
    14070, 14097, 14129, 14153,
    14868, 14911, 14922,
    15360,
    16006, 16048,
    16685, 16708, 16727, 16750,
    16990, 17208,
    17503, 17582,
    17985, 18087, 18509
]);

// $32 .l -> obj_vel_x
const vel_x_lines = new Set([
    11919, 12034, 12562, 12729,
    16991, 17209
]);

// $36 .l -> obj_vel_y
const vel_y_lines = new Set([
    11920, 12035, 12563, 12730,
    16992, 17210
]);

function replaceOffset(line, rawOffset, namedField) {
    // Replace $XX(Ax) with namedField(Ax) - handles any register Ax
    const pattern = new RegExp('\\' + rawOffset + '\\((A[0-9])\\)', 'g');
    return line.replace(pattern, namedField + '($1)');
}

let count = 0;
const newLines = lines.map((line, idx) => {
    const lineNum = idx + 1;

    if (anim_ptr_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$2E', 'obj_anim_ptr');
        if (replaced !== line) count++;
        return replaced;
    }
    if (hb_x_neg_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$2E', 'obj_hitbox_x_neg');
        if (replaced !== line) count++;
        return replaced;
    }
    if (hb_x_pos_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$2F', 'obj_hitbox_x_pos');
        if (replaced !== line) count++;
        return replaced;
    }
    if (hb_y_neg_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$30', 'obj_hitbox_y_neg');
        if (replaced !== line) count++;
        return replaced;
    }
    if (hb_y_pos_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$31', 'obj_hitbox_y_pos');
        if (replaced !== line) count++;
        return replaced;
    }
    if (vel_x_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$32', 'obj_vel_x');
        if (replaced !== line) count++;
        return replaced;
    }
    if (vel_y_lines.has(lineNum)) {
        const replaced = replaceOffset(line, '$36', 'obj_vel_y');
        if (replaced !== line) count++;
        return replaced;
    }

    return line;
});

const out = newLines.join('\n').replace(/\n/g, '\r\n');
fs.writeFileSync('vermilion.asm', out);
console.log(`Done. ${count} replacements made.`);
