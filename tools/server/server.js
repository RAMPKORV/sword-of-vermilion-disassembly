'use strict';

const express = require('express');
const fs = require('fs');
const http = require('http');
const path = require('path');
const { WebSocketServer } = require('ws');

const { PROJECT_ROOT, runCommand, runNodeScript, makeTaskId } = require('./tool-runner');

const PORT = parseInt(process.env.PORT || '3000', 10);
const PUBLIC_DIR = path.join(__dirname, 'public');
const TMP_DIR = path.join(__dirname, 'tmp');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const TOOLS_DIR = path.join(PROJECT_ROOT, 'tools');
const DATA_DIR = path.join(TOOLS_DIR, 'data');
const INDEX_DIR = path.join(TOOLS_DIR, 'index');
const DOCS_DIR = path.join(PROJECT_ROOT, 'docs');
const SRC_DIR = path.join(PROJECT_ROOT, 'src');
const MAPS_DIR = path.join(PROJECT_ROOT, 'data', 'maps');

for (const dir of [TMP_DIR, UPLOAD_DIR]) {
  fs.mkdirSync(dir, { recursive: true });
}

const app = express();
app.use(express.json({ limit: '10mb' }));
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  next();
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });
const sockets = new Set();
const activeTasks = new Map();

function nowIso() {
  return new Date().toISOString();
}

function broadcast(message) {
  const text = JSON.stringify(message);
  for (const socket of sockets) {
    if (socket.readyState === 1) {
      socket.send(text);
    }
  }
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2) + '\n');
}

function safeName(name) {
  return String(name || '').toLowerCase();
}

function getBody(req) {
  return req.body || {};
}

function sendError(res, error, status = 500) {
  res.status(status).json({
    error: error && error.message ? error.message : String(error),
  });
}

async function runStreamingTask(config) {
  const taskId = config.taskId || makeTaskId();
  activeTasks.set(taskId, { startedAt: Date.now(), label: config.label || config.command });
  broadcast({ type: 'tool-start', taskId, label: config.label || config.command, timestamp: nowIso() });
  try {
    const result = await runCommand({
      ...config,
      taskId,
      onStdout(data) {
        broadcast({ type: 'tool-output', taskId, stream: 'stdout', data, timestamp: nowIso() });
        if (config.onStdout) config.onStdout(data);
      },
      onStderr(data) {
        broadcast({ type: 'tool-output', taskId, stream: 'stderr', data, timestamp: nowIso() });
        if (config.onStderr) config.onStderr(data);
      },
    });
    activeTasks.delete(taskId);
    broadcast({ type: 'tool-complete', taskId, exitCode: result.exitCode, duration: result.duration, ok: result.ok, timestamp: nowIso() });
    return result;
  } catch (error) {
    activeTasks.delete(taskId);
    broadcast({ type: 'tool-complete', taskId, exitCode: null, duration: null, ok: false, error: error.message, timestamp: nowIso() });
    throw error;
  }
}

async function runNodeStreaming(label, relativeScriptPath, args = [], options = {}) {
  return runStreamingTask({
    label,
    command: process.execPath,
    args: [path.join(PROJECT_ROOT, relativeScriptPath), ...args],
    cwd: PROJECT_ROOT,
    timeout: options.timeout || 120000,
  });
}

function constantsFromPrefix(prefix) {
  const filePath = path.join(PROJECT_ROOT, 'constants.asm');
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  const values = [];
  const regex = new RegExp(`^\\s*(${prefix}[A-Z0-9_]+)\\s*(?:equ|=)\\s*(\\$[0-9A-Fa-f]+|[0-9]+)`);
  for (const line of lines) {
    const match = line.match(regex);
    if (!match) continue;
    const raw = match[2];
    const value = raw.startsWith('$') ? parseInt(raw.slice(1), 16) : parseInt(raw, 10);
    values.push({ constant: match[1], value, name: match[1].replace(prefix, '') });
  }
  return values;
}

const catalogs = {
  items: constantsFromPrefix('ITEM_').filter((entry) => !entry.constant.startsWith('ITEM_MENU_') && !entry.constant.startsWith('ITEM_TYPE_') && !entry.constant.startsWith('ITEM_STATE_')),
  equipment: constantsFromPrefix('EQUIPMENT_').filter((entry) => !entry.constant.startsWith('EQUIPMENT_TYPE_') && !entry.constant.startsWith('EQUIPMENT_FLAG_')),
  magic: constantsFromPrefix('MAGIC_').filter((entry) => !entry.constant.startsWith('MAGIC_TYPE_') && entry.constant !== 'MAGIC_NONE'),
  towns: constantsFromPrefix('TOWN_').filter((entry) => /^TOWN_[A-Z0-9]+/.test(entry.constant)),
};

function getEnemiesData() {
  return readJson(path.join(DATA_DIR, 'enemies.json'));
}

function findEnemy(name) {
  const data = getEnemiesData();
  const match = data.enemies.find((enemy) => safeName(enemy.stats.name) === safeName(name))
    || data.enemies.find((enemy) => safeName(enemy.stats.name).includes(safeName(name)));
  return { data, enemy: match || null };
}

function getShopsData() {
  return readJson(path.join(DATA_DIR, 'shops.json'));
}

function findTown(name) {
  const data = getShopsData();
  const town = data.town_shops.find((entry) => safeName(entry.town_name) === safeName(name))
    || data.town_shops.find((entry) => safeName(entry.town_name).includes(safeName(name)));
  return { data, town: town || null };
}

function getStatsData() {
  return readJson(path.join(DATA_DIR, 'player_stats.json'));
}

function getStringsData() {
  return readJson(path.join(INDEX_DIR, 'strings.json'));
}

function getScriptEntriesData() {
  return readJson(path.join(INDEX_DIR, 'script_entries.json'));
}

function parseMarkdown(markdown) {
  let html = markdown
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
  html = html.replace(/^###\s+(.*)$/gm, '<h3>$1</h3>');
  html = html.replace(/^##\s+(.*)$/gm, '<h2>$1</h2>');
  html = html.replace(/^#\s+(.*)$/gm, '<h1>$1</h1>');
  html = html.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>');
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
  html = html.replace(/^\-\s+(.*)$/gm, '<li>$1</li>');
  html = html.replace(/(<li>.*<\/li>)/gs, '<ul>$1</ul>');
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/\n\n+/g, '</p><p>');
  html = '<p>' + html + '</p>';
  return html.replace(/<p><\/p>/g, '');
}

function parseLabelCoverage(output) {
  const total = output.match(/Total labels\s*:\s*(\d+)/);
  const named = output.match(/Named labels\s*:\s*(\d+)\s+\(([0-9.]+)%\)/);
  const loc = output.match(/loc_ labels\s*:\s*(\d+)/);
  return {
    total: total ? parseInt(total[1], 10) : 0,
    named: named ? parseInt(named[1], 10) : 0,
    percentage: named ? parseFloat(named[2]) : 0,
    locRemaining: loc ? parseInt(loc[1], 10) : 0,
    raw: output,
  };
}

function parseDeadCode(output) {
  const lines = output.split(/\r?\n/);
  const deadLabels = [];
  let inList = false;
  for (const line of lines) {
    if (line.includes('--- Full zero-reference label list ---')) {
      inList = true;
      continue;
    }
    if (!inList) continue;
    const match = line.match(/^\s+(.+):(\d+)\s+([A-Za-z_][A-Za-z0-9_.]*)$/);
    if (match) {
      deadLabels.push({ file: match[1], line: parseInt(match[2], 10), label: match[3] });
    }
  }
  return { deadLabels, raw: output };
}

function parseMagicAudit(output) {
  const entries = [];
  const lines = output.split(/\r?\n/);
  let current = null;
  let unnamed = false;
  for (const line of lines) {
    if (line.includes('UNNAMED MAGIC NUMBERS')) {
      unnamed = true;
      continue;
    }
    if (line.includes('ALREADY NAMED')) break;
    if (!unnamed) continue;
    const header = line.match(/^\s+(0x[0-9A-F]+)\s+(\d+)x$/);
    if (header) {
      current = { value: header[1], count: parseInt(header[2], 10), sites: [] };
      entries.push(current);
      continue;
    }
    const site = line.match(/^\s+\[([0-9A-F]{8})\]\s+(.*)$/);
    if (site && current) {
      current.sites.push({ address: site[1], source: site[2] });
    }
  }
  return { entries, raw: output };
}

function parseMacroOpportunities(output) {
  return { raw: output };
}

function decodeCramWord(hi, lo) {
  const word = (hi << 8) | lo;
  const table = [0, 36, 73, 109, 146, 182, 219, 255];
  return {
    raw: word,
    r: table[(word >> 1) & 7],
    g: table[(word >> 5) & 7],
    b: table[(word >> 9) & 7],
  };
}

function parsePalettes() {
  const filePath = path.join(PROJECT_ROOT, 'data', 'art', 'palettes', 'palette_data.bin');
  const buffer = fs.readFileSync(filePath);
  const paletteSize = 32;
  const palettes = [];
  for (let index = 0; index < buffer.length / paletteSize; index++) {
    const colors = [];
    const base = index * paletteSize;
    for (let slot = 0; slot < 16; slot++) {
      const off = base + slot * 2;
      const color = decodeCramWord(buffer[off], buffer[off + 1]);
      colors.push({
        slot,
        cram: '$' + color.raw.toString(16).toUpperCase().padStart(4, '0'),
        r: color.r,
        g: color.g,
        b: color.b,
        hex: '#' + [color.r, color.g, color.b].map((value) => value.toString(16).padStart(2, '0')).join('').toUpperCase(),
      });
    }
    palettes.push({ index, name: null, colors });
  }
  return palettes;
}

const MAP_WIDTH = 16;
const MAP_HEIGHT = 16;
const TILE_COLORS = {
  0x00: '#6f8f4e',
  0x01: '#1e5631',
  0x02: '#6d6d6d',
  0x03: '#888888',
  0x04: '#777777',
  0x05: '#4b4b4b',
  0x06: '#c7a252',
  0x07: '#d9c27a',
  0x08: '#2b74c8',
  0x09: '#9a8b6b',
  0x0A: '#b09a75',
  0x0B: '#2c7a4b',
  0x0C: '#a57c3c',
  0x0D: '#d0a35b',
  0x0E: '#7db564',
  0x0F: '#c9d3d9',
  0xFF: '#ff6b6b',
};

function decompressMap(buffer) {
  const tiles = [];
  let src = 0;
  while (src < buffer.length && tiles.length < 256) {
    const value = buffer[src++];
    if (value < 0x80) {
      tiles.push(value);
    } else {
      const count = value - 0x80 + 1;
      const tile = buffer[src++];
      for (let i = 0; i < count && tiles.length < 256; i += 1) {
        tiles.push(tile);
      }
    }
  }
  const grid = [];
  for (let row = 0; row < MAP_HEIGHT; row += 1) {
    grid.push(tiles.slice(row * MAP_WIDTH, row * MAP_WIDTH + MAP_WIDTH));
  }
  return grid;
}

function renderAsciiMap(grid) {
  const chars = {
    0x00: '.', 0x01: 'T', 0x02: 'R', 0x03: 'r', 0x04: 'r', 0x05: '#', 0x06: '+',
    0x07: 's', 0x08: 'w', 0x09: 'm', 0x0A: 'M', 0x0B: 'f', 0x0C: 'b', 0x0D: 'd',
    0x0E: 'g', 0x0F: 'H', 0xFF: 'X',
  };
  const lines = [];
  lines.push('  0123456789ABCDEF');
  for (let row = 0; row < grid.length; row += 1) {
    const line = grid[row].map((tile) => {
      if (chars[tile] !== undefined) return chars[tile];
      if (tile >= 0x10 && tile < 0x20) return (tile & 0x0F).toString(16).toUpperCase();
      if (tile >= 0x80 && tile < 0x90) return String.fromCharCode(65 + (tile & 0x0F));
      return tile.toString(16).slice(-1);
    }).join('');
    lines.push(row.toString(16).toUpperCase() + ' ' + line);
  }
  return lines.join('\n');
}

function listMapFiles(subdir, pattern) {
  const dir = path.join(MAPS_DIR, subdir);
  return fs.readdirSync(dir)
    .filter((file) => pattern.test(file))
    .sort();
}

function readMap(mode, argA, argB) {
  const filePath = mode === 'overworld'
    ? path.join(MAPS_DIR, 'overworld', `sector_${argA}_${argB}.bin`)
    : path.join(MAPS_DIR, 'cave', `room_${String(argA).padStart(2, '0')}.bin`);
  const buffer = fs.readFileSync(filePath);
  const grid = decompressMap(buffer);
  return {
    filePath: path.relative(PROJECT_ROOT, filePath),
    byteLength: buffer.length,
    grid,
    ascii: renderAsciiMap(grid),
    colors: Object.fromEntries(Object.entries(TILE_COLORS).map(([key, value]) => [String(key), value])),
  };
}

function diffObjects(before, after) {
  return {
    before,
    after,
  };
}

function docList() {
  return fs.readdirSync(DOCS_DIR)
    .filter((file) => file.endsWith('.md'))
    .sort()
    .map((file) => {
      const fullPath = path.join(DOCS_DIR, file);
      const content = fs.readFileSync(fullPath, 'utf8');
      const firstHeading = content.split(/\r?\n/).find((line) => line.startsWith('# '));
      const stats = fs.statSync(fullPath);
      return {
        file,
        title: firstHeading ? firstHeading.slice(2).trim() : file,
        updatedAt: stats.mtime.toISOString(),
      };
    });
}

app.use(express.static(PUBLIC_DIR));

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    version: '1.0.0',
    time: nowIso(),
    activeTasks: activeTasks.size,
  });
});

app.get('/api/catalogs', (req, res) => {
  res.json(catalogs);
});

app.post('/api/build', async (req, res) => {
  try {
    const result = await runStreamingTask({
      label: 'build',
      command: 'cmd',
      args: ['/c', 'build.bat'],
      cwd: PROJECT_ROOT,
      timeout: 240000,
    });
    broadcast({ type: 'build-status', success: result.ok, bitPerfect: null, timestamp: nowIso() });
    res.json({ success: result.ok, ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/verify', async (req, res) => {
  try {
    const result = await runStreamingTask({
      label: 'verify',
      command: 'cmd',
      args: ['/c', 'verify.bat'],
      cwd: PROJECT_ROOT,
      timeout: 240000,
    });
    const combined = (result.stdout + '\n' + result.stderr).toLowerCase();
    const bitPerfect = result.ok && !combined.includes('mismatch');
    broadcast({ type: 'build-status', success: result.ok, bitPerfect, timestamp: nowIso() });
    res.json({ success: result.ok, bitPerfect, ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/build-hack', async (req, res) => {
  try {
    const build = await runStreamingTask({
      label: 'build-hack',
      command: 'cmd',
      args: ['/c', 'build.bat'],
      cwd: PROJECT_ROOT,
      timeout: 240000,
    });
    if (!build.ok) {
      res.json({ success: false, build, checksum: null });
      return;
    }
    const checksum = await runNodeStreaming('patch-rom-checksum', 'tools/patch_rom_checksum.js', ['--rom', 'out.bin']);
    broadcast({ type: 'build-status', success: build.ok && checksum.ok, bitPerfect: false, timestamp: nowIso() });
    res.json({ success: build.ok && checksum.ok, build, checksum, bitPerfect: false });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/enemies', (req, res) => {
  const data = getEnemiesData();
  res.json({ meta: data._meta, enemies: data.enemies });
});

app.get('/api/enemies/:name', (req, res) => {
  const { enemy } = findEnemy(req.params.name);
  if (!enemy) {
    res.status(404).json({ error: 'Enemy not found' });
    return;
  }
  res.json(enemy);
});

app.post('/api/enemies/:name', async (req, res) => {
  const updates = getBody(req).updates || {};
  const dryRun = !!getBody(req).dryRun;
  const noRebuild = !!getBody(req).noRebuild;
  const args = ['tools/editor/enemy_editor.js', '--enemy', req.params.name];
  for (const [key, value] of Object.entries(updates)) {
    args.push('--set', `${key}=${value}`);
  }
  if (dryRun) args.push('--dry-run');
  if (noRebuild) args.push('--no-rebuild');
  try {
    const result = await runStreamingTask({
      label: 'enemy-editor',
      command: process.execPath,
      args,
      cwd: PROJECT_ROOT,
      timeout: 240000,
    });
    const latest = findEnemy(req.params.name).enemy;
    res.json({ success: result.ok, enemy: latest, command: [process.execPath, ...args].join(' '), ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/enemies/:name/dry-run', async (req, res) => {
  const body = { ...(req.body || {}), dryRun: true };
  const updates = body.updates || {};
  const args = ['tools/editor/enemy_editor.js', '--enemy', req.params.name];
  for (const [key, value] of Object.entries(updates)) {
    args.push('--set', `${key}=${value}`);
  }
  args.push('--dry-run');
  if (body.noRebuild) args.push('--no-rebuild');
  try {
    const result = await runStreamingTask({
      label: 'enemy-editor-dry-run',
      command: process.execPath,
      args,
      cwd: PROJECT_ROOT,
      timeout: 240000,
    });
    res.json({ success: result.ok, command: [process.execPath, ...args].join(' '), ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/shops', (req, res) => {
  const data = getShopsData();
  res.json({
    meta: data._meta,
    towns: data.town_shops,
    catalogs,
  });
});

app.get('/api/shops/:town', (req, res) => {
  const { town } = findTown(req.params.town);
  if (!town) {
    res.status(404).json({ error: 'Town not found' });
    return;
  }
  res.json(town);
});

app.post('/api/shops/:town', async (req, res) => {
  const body = getBody(req);
  const dryRun = !!body.dryRun;
  const noRebuild = !!body.noRebuild;
  const { data, town } = findTown(req.params.town);
  if (!town) {
    res.status(404).json({ error: 'Town not found' });
    return;
  }
  const replacement = body.town || town;
  const next = JSON.parse(JSON.stringify(data));
  const index = next.town_shops.findIndex((entry) => safeName(entry.town_name) === safeName(town.town_name));
  next.town_shops[index] = replacement;
  if (dryRun) {
    res.json({ success: true, dryRun: true, diff: diffObjects(town, replacement) });
    return;
  }
  try {
    writeJson(path.join(DATA_DIR, 'shops.json'), next);
    const inject = await runNodeStreaming('inject-shops', 'tools/inject_game_data.js', ['--shops']);
    let verify = null;
    if (!noRebuild) {
      verify = await runStreamingTask({ label: 'verify-after-shop', command: 'cmd', args: ['/c', 'verify.bat'], cwd: PROJECT_ROOT, timeout: 240000 });
    }
    res.json({ success: inject.ok && (!verify || verify.ok), town: replacement, inject, verify });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/player-stats', (req, res) => {
  res.json(getStatsData());
});

app.post('/api/player-stats', async (req, res) => {
  const body = getBody(req);
  const level = parseInt(body.level, 10);
  const updates = body.updates || {};
  const dryRun = !!body.dryRun;
  const noRebuild = !!body.noRebuild;
  const data = getStatsData();
  const row = data.level_ups.find((entry) => entry.level === level);
  if (!row) {
    res.status(404).json({ error: 'Level not found' });
    return;
  }
  const next = JSON.parse(JSON.stringify(data));
  const nextRow = next.level_ups.find((entry) => entry.level === level);
  Object.assign(nextRow, updates);
  if (dryRun) {
    res.json({ success: true, dryRun: true, diff: diffObjects(row, nextRow) });
    return;
  }
  try {
    writeJson(path.join(DATA_DIR, 'player_stats.json'), next);
    const inject = await runNodeStreaming('inject-player-stats', 'tools/inject_game_data.js', ['--player-stats']);
    let verify = null;
    if (!noRebuild) {
      verify = await runStreamingTask({ label: 'verify-after-stats', command: 'cmd', args: ['/c', 'verify.bat'], cwd: PROJECT_ROOT, timeout: 240000 });
    }
    res.json({ success: inject.ok && (!verify || verify.ok), row: nextRow, inject, verify });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/scripts', (req, res) => {
  const strings = getStringsData();
  const entries = getScriptEntriesData().entries || {};
  const payload = strings.map((entry) => ({
    label: entry.label,
    address: entry.address,
    text: entry.text,
    byteCount: Array.isArray(entry.raw_ops) ? entry.raw_ops.reduce((sum, op) => sum + (Array.isArray(op.bytes) ? op.bytes.length : 1), 0) : 0,
    definedIn: entries[entry.label] ? entries[entry.label].defined_in : null,
    callers: entries[entry.label] ? entries[entry.label].callers : [],
  }));
  res.json(payload);
});

app.get('/api/scripts/:label', async (req, res) => {
  try {
    const result = await runCommand({
      command: process.execPath,
      args: [path.join(PROJECT_ROOT, 'tools', 'script_disasm.js'), req.params.label, '--json'],
      cwd: PROJECT_ROOT,
      timeout: 120000,
    });
    res.json(JSON.parse(result.stdout));
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/scripts/:label/validate', async (req, res) => {
  const body = getBody(req);
  const patchPath = path.join(TMP_DIR, `script-validate-${Date.now()}.json`);
  fs.writeFileSync(patchPath, JSON.stringify([{ label: req.params.label, ...(body.rawOps ? { raw_ops: body.rawOps } : { new_text: body.newText || '' }) }], null, 2));
  try {
    const result = await runCommand({
      command: process.execPath,
      args: [path.join(PROJECT_ROOT, 'tools', 'script_patch.js'), '--validate', patchPath],
      cwd: PROJECT_ROOT,
      timeout: 120000,
    });
    fs.unlinkSync(patchPath);
    res.json({ success: result.ok, stdout: result.stdout, stderr: result.stderr, exitCode: result.exitCode });
  } catch (error) {
    try { fs.unlinkSync(patchPath); } catch (unlinkError) { /* ignore */ }
    sendError(res, error);
  }
});

app.post('/api/scripts/:label', async (req, res) => {
  const body = getBody(req);
  const patchPath = path.join(TMP_DIR, `script-patch-${Date.now()}.json`);
  fs.writeFileSync(patchPath, JSON.stringify([{ label: req.params.label, ...(body.rawOps ? { raw_ops: body.rawOps } : { new_text: body.newText || '' }) }], null, 2));
  const args = [path.join(PROJECT_ROOT, 'tools', 'script_patch.js'), '--patch', patchPath];
  if (body.dryRun) args.push('--dry-run');
  try {
    const result = await runStreamingTask({ label: 'script-patch', command: process.execPath, args, cwd: PROJECT_ROOT, timeout: 240000 });
    fs.unlinkSync(patchPath);
    res.json({ success: result.ok, ...result });
  } catch (error) {
    try { fs.unlinkSync(patchPath); } catch (unlinkError) { /* ignore */ }
    sendError(res, error);
  }
});

app.get('/api/maps/overworld', (req, res) => {
  const files = listMapFiles('overworld', /^sector_\d+_\d+\.bin$/).map((file) => {
    const match = file.match(/^sector_(\d+)_(\d+)\.bin$/);
    return { file, x: parseInt(match[1], 10), y: parseInt(match[2], 10) };
  });
  res.json(files);
});

app.get('/api/maps/caves', (req, res) => {
  const files = listMapFiles('cave', /^room_\d+\.bin$/).map((file) => {
    const match = file.match(/^room_(\d+)\.bin$/);
    return { file, room: parseInt(match[1], 10) };
  });
  res.json(files);
});

app.get('/api/maps/overworld/:x/:y', (req, res) => {
  res.json(readMap('overworld', req.params.x, req.params.y));
});

app.get('/api/maps/cave/:room', (req, res) => {
  res.json(readMap('cave', req.params.room));
});

app.post('/api/maps/overworld/:x/:y/tile', async (req, res) => {
  const body = getBody(req);
  const args = [path.join(PROJECT_ROOT, 'tools', 'editor', 'map_editor.js'), 'overworld', String(req.params.x), String(req.params.y), 'set', String(body.col), String(body.row), String(body.tileId)];
  if (body.force) args.push('--force');
  try {
    const result = await runStreamingTask({ label: 'map-edit-overworld', command: process.execPath, args, cwd: PROJECT_ROOT, timeout: 120000 });
    res.json({ success: result.ok, ...result, map: readMap('overworld', req.params.x, req.params.y) });
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/maps/cave/:room/tile', async (req, res) => {
  const body = getBody(req);
  const args = [path.join(PROJECT_ROOT, 'tools', 'editor', 'map_editor.js'), 'cave', String(req.params.room), 'set', String(body.col), String(body.row), String(body.tileId)];
  if (body.force) args.push('--force');
  try {
    const result = await runStreamingTask({ label: 'map-edit-cave', command: process.execPath, args, cwd: PROJECT_ROOT, timeout: 120000 });
    res.json({ success: result.ok, ...result, map: readMap('cave', req.params.room) });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/palettes', (req, res) => {
  res.json(parsePalettes());
});

app.get('/api/palettes/:name', (req, res) => {
  const query = safeName(req.params.name);
  const palettes = parsePalettes().filter((palette) => String(palette.index) === req.params.name || safeName(palette.name || '').includes(query));
  res.json(palettes);
});

async function encounterJson(flag) {
  const result = await runCommand({
    command: process.execPath,
    args: [path.join(PROJECT_ROOT, 'tools', 'encounter_analyzer.js'), flag, '--json'],
    cwd: PROJECT_ROOT,
    timeout: 120000,
  });
  return JSON.parse(result.stdout);
}

app.get('/api/encounters/overworld', async (req, res) => {
  try { res.json(await encounterJson('--overworld')); } catch (error) { sendError(res, error); }
});
app.get('/api/encounters/cave', async (req, res) => {
  try { res.json(await encounterJson('--cave')); } catch (error) { sendError(res, error); }
});
app.get('/api/encounters/groups', async (req, res) => {
  try { res.json(await encounterJson('--groups')); } catch (error) { sendError(res, error); }
});
app.get('/api/encounters/enemies', async (req, res) => {
  try { res.json(await encounterJson('--enemies')); } catch (error) { sendError(res, error); }
});
app.get('/api/encounters/curve', async (req, res) => {
  try { res.json(await encounterJson('--curve')); } catch (error) { sendError(res, error); }
});

app.get('/api/randomizer/presets', (req, res) => {
  res.json([
    { name: 'Casual', flags: { enemies: true, shops: false, chests: false, encounters: false, stats: false, maps: false } },
    { name: 'Standard', flags: { enemies: true, shops: true, chests: false, encounters: true, stats: false, maps: false } },
    { name: 'Cartographer', flags: { enemies: false, shops: false, chests: false, encounters: false, stats: false, maps: true } },
    { name: 'Chaos', flags: { enemies: true, shops: true, chests: true, encounters: true, stats: true, maps: true } },
  ]);
});

function randomizerFlagHex(flags) {
  let value = 0;
  if (flags.enemies) value |= 0x01;
  if (flags.shops) value |= 0x02;
  if (flags.chests) value |= 0x04;
  if (flags.encounters) value |= 0x08;
  if (flags.stats) value |= 0x10;
  if (flags.maps) value |= 0x20;
  return value.toString(16).toUpperCase().padStart(2, '0');
}

async function runRandomizer(body, dryRun) {
  const flagsHex = randomizerFlagHex(body.flags || {});
  const seedInput = String(body.seed || Date.now());
  const args = [path.join(PROJECT_ROOT, 'tools', 'randomizer', 'randomize.js'), '--seed', seedInput, '--flags', flagsHex];
  if (body.variance !== undefined) args.push('--variance', String(body.variance));
  if (body.mapMode) args.push('--maps-mode', String(body.mapMode));
  if (body.mapExport) args.push('--maps-export', String(body.mapExport));
  if (body.behavior) args.push('--behavior');
  if (dryRun) args.push('--dry-run');
  if (body.noRebuild) args.push('--no-rebuild');
  if (body.noValidate) args.push('--no-validate');
  return runStreamingTask({ label: 'randomizer', command: process.execPath, args, cwd: PROJECT_ROOT, timeout: 300000 });
}

app.post('/api/randomizer/maps/preview', async (req, res) => {
  const body = getBody(req);
  const seedInput = String(body.seed || Date.now());
  const mode = String(body.mapMode || 'safe-shuffle');
  try {
    const result = await runCommand({
      command: process.execPath,
      args: [path.join(PROJECT_ROOT, 'tools', 'randomizer', 'map_randomizer.js'), '--seed', seedInput, '--mode', mode, '--json'],
      cwd: PROJECT_ROOT,
      timeout: 120000,
    });
    res.json(JSON.parse(result.stdout));
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/randomizer/run', async (req, res) => {
  try { res.json(await runRandomizer(getBody(req), false)); } catch (error) { sendError(res, error); }
});

app.post('/api/randomizer/dry-run', async (req, res) => {
  try { res.json(await runRandomizer(getBody(req), true)); } catch (error) { sendError(res, error); }
});

app.post('/api/data/extract', async (req, res) => {
  try {
    const result = await runNodeStreaming('extract-game-data', 'tools/extract_game_data.js');
    const files = fs.readdirSync(DATA_DIR).filter((file) => file.endsWith('.json')).map((file) => {
      const full = path.join(DATA_DIR, file);
      const stats = fs.statSync(full);
      return { file, size: stats.size, updatedAt: stats.mtime.toISOString() };
    });
    res.json({ success: result.ok, files, ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/data/inject', async (req, res) => {
  const body = getBody(req);
  const targets = Array.isArray(body.targets) ? body.targets : ['all'];
  const args = [];
  if (targets.includes('all')) args.push('--all');
  if (targets.includes('enemies')) args.push('--enemies');
  if (targets.includes('magic')) args.push('--magic');
  if (targets.includes('player-stats')) args.push('--player-stats');
  if (targets.includes('shops')) args.push('--shops');
  if (body.dryRun) args.push('--dry-run');
  try {
    const result = await runNodeStreaming('inject-game-data', 'tools/inject_game_data.js', args);
    res.json({ success: result.ok, ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/data/files', (req, res) => {
  const files = fs.readdirSync(DATA_DIR).filter((file) => file.endsWith('.json')).sort().map((file) => {
    const fullPath = path.join(DATA_DIR, file);
    const stats = fs.statSync(fullPath);
    let recordCount = null;
    try {
      const parsed = readJson(fullPath);
      if (Array.isArray(parsed)) recordCount = parsed.length;
      else if (parsed && Array.isArray(parsed.enemies)) recordCount = parsed.enemies.length;
      else if (parsed && Array.isArray(parsed.town_shops)) recordCount = parsed.town_shops.length;
      else if (parsed && Array.isArray(parsed.level_ups)) recordCount = parsed.level_ups.length;
      else if (parsed && Array.isArray(parsed.magic)) recordCount = parsed.magic.length;
    } catch (error) {
      recordCount = null;
    }
    return { file, size: stats.size, updatedAt: stats.mtime.toISOString(), recordCount };
  });
  res.json(files);
});

app.post('/api/rom-diff', async (req, res) => {
  const body = getBody(req);
  const romA = body.romA || path.join(PROJECT_ROOT, 'out.bin');
  const romB = body.romB || path.join(PROJECT_ROOT, 'orig_backup.bin');
  const args = [path.join(PROJECT_ROOT, 'tools', 'rom_diff.js'), romA, romB, '--json'];
  if (body.context) args.push('--context', String(body.context));
  if (body.max) args.push('--max', String(body.max));
  try {
    const result = await runCommand({ command: process.execPath, args, cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(JSON.parse(result.stdout));
  } catch (error) {
    sendError(res, error);
  }
});

app.post('/api/lint/run-all', async (req, res) => {
  try {
    const result = await runNodeStreaming('run-checks', 'tools/run_checks.js');
    res.json({ success: result.ok, raw: result.stdout, ...result });
  } catch (error) {
    sendError(res, error);
  }
});

app.get('/api/lint/label-coverage', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'label_coverage.js')], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(parseLabelCoverage(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/lint/comment-density', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'comment_density.js'), '--json'], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(JSON.parse(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/lint/dead-code', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'deadb002_audit.js')], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(parseDeadCode(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/lint/magic-numbers', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'audit_magic_numbers.js')], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(parseMagicAudit(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/lint/macro-opportunities', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'report_macro_opportunities.js')], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(parseMacroOpportunities(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/lint/vdp-commands', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'lint_raw_vdp_cmds.js'), '--verbose'], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json({ raw: result.stdout, stderr: result.stderr, exitCode: result.exitCode });
  } catch (error) { sendError(res, error); }
});

app.get('/api/lint/progression', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'progression_validator.js'), '--json'], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(JSON.parse(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/script-disasm/list', (req, res) => {
  const strings = getStringsData().map((entry) => ({ label: entry.label, address: entry.address, text: entry.text.slice(0, 80) }));
  res.json(strings);
});

app.get('/api/script-disasm/:label', async (req, res) => {
  try {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, 'tools', 'script_disasm.js'), req.params.label, '--json'], cwd: PROJECT_ROOT, timeout: 120000 });
    res.json(JSON.parse(result.stdout));
  } catch (error) { sendError(res, error); }
});

app.get('/api/index/symbols', (req, res) => {
  const raw = readJson(path.join(INDEX_DIR, 'symbol_map.json'));
  const search = safeName(req.query.search || '');
  const items = Object.entries(raw).map(([name, info]) => ({ name, ...info }));
  const filtered = search ? items.filter((item) => safeName(item.name).includes(search)) : items;
  res.json(filtered.slice(0, 5000));
});

app.get('/api/index/functions', (req, res) => {
  res.json(readJson(path.join(INDEX_DIR, 'functions.json')));
});

app.get('/api/index/callsites', (req, res) => {
  const data = readJson(path.join(INDEX_DIR, 'callsites.json'));
  const label = req.query.label;
  if (label) {
    res.json({ label, callsites: data.callsites[label] || [] });
    return;
  }
  res.json(data);
});

app.get('/api/index/ram-symbols', (req, res) => {
  res.json(readJson(path.join(INDEX_DIR, 'ram_symbols.json')));
});

app.get('/api/index/include-graph', (req, res) => {
  res.json(readJson(path.join(INDEX_DIR, 'include_graph.json')));
});

app.get('/api/index/script-opcodes', (req, res) => {
  res.json(readJson(path.join(INDEX_DIR, 'script_opcodes.json')));
});

app.post('/api/index/rebuild', async (req, res) => {
  const scripts = [
    'tools/index/symbol_map.js',
    'tools/index/functions.js',
    'tools/index/callsites.js',
    'tools/index/ram_symbols.js',
    'tools/index/strings.js',
    'tools/index/script_entries.js',
    'tools/index/include_graph.js',
  ];
  const results = [];
  for (const script of scripts) {
    const result = await runCommand({ command: process.execPath, args: [path.join(PROJECT_ROOT, script)], cwd: PROJECT_ROOT, timeout: 120000 });
    results.push({ script, ok: result.ok, stdout: result.stdout, stderr: result.stderr, exitCode: result.exitCode });
  }
  res.json({ success: results.every((entry) => entry.ok), results });
});

app.get('/api/magic', (req, res) => {
  res.json(readJson(path.join(DATA_DIR, 'magic_tables.json')));
});

app.get('/api/services', (req, res) => {
  res.json(readJson(path.join(DATA_DIR, 'service_prices.json')));
});

app.get('/api/docs', (req, res) => {
  res.json(docList());
});

app.get('/api/docs/:filename', (req, res) => {
  const filename = path.basename(req.params.filename);
  const fullPath = path.join(DOCS_DIR, filename);
  if (!fs.existsSync(fullPath)) {
    res.status(404).json({ error: 'Document not found' });
    return;
  }
  const markdown = fs.readFileSync(fullPath, 'utf8');
  res.json({ file: filename, markdown, html: parseMarkdown(markdown) });
});

app.get('*', (req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, 'index.html'));
});

function watchTree(dir, filter) {
  if (!fs.existsSync(dir)) return;
  fs.watch(dir, { persistent: false }, (eventType, fileName) => {
    if (!fileName) return;
    if (filter && !filter(fileName)) return;
    broadcast({ type: 'file-changed', file: path.join(path.basename(dir), fileName), eventType, timestamp: nowIso() });
  });
}

watchTree(SRC_DIR, (file) => file.endsWith('.asm'));
watchTree(DATA_DIR, (file) => file.endsWith('.json'));
watchTree(DOCS_DIR, (file) => file.endsWith('.md'));

wss.on('connection', (socket) => {
  sockets.add(socket);
  socket.send(JSON.stringify({ type: 'server-status', uptime: process.uptime(), activeTasks: activeTasks.size, timestamp: nowIso() }));
  socket.on('message', (message) => {
    let parsed;
    try {
      parsed = JSON.parse(message.toString());
    } catch (error) {
      return;
    }
    if (parsed.type === 'ping') {
      socket.send(JSON.stringify({ type: 'pong', timestamp: nowIso() }));
    }
  });
  socket.on('close', () => {
    sockets.delete(socket);
  });
});

const heartbeat = setInterval(() => {
  broadcast({ type: 'server-status', uptime: process.uptime(), activeTasks: activeTasks.size, timestamp: nowIso() });
}, 30000);

function shutdown() {
  clearInterval(heartbeat);
  server.close(() => {
    process.exit(0);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

server.listen(PORT, () => {
  console.log(`Vermilion tools UI server listening on http://localhost:${PORT}`);
});
