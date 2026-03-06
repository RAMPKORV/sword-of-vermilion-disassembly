'use strict';

const state = {
  ws: null,
  activePanel: 'build-verify',
  panelCache: new Map(),
  breadcrumbs: ['Home'],
  activity: [],
  terminals: new Map(),
  lastBuildOk: null,
  data: {},
};

const panelDefinitions = [
  {
    group: 'Build',
    panels: [{ id: 'build-verify', label: 'Build & Verify' }],
  },
  {
    group: 'Editors',
    panels: [
      { id: 'enemy-editor', label: 'Enemy Editor' },
      { id: 'shop-editor', label: 'Shop Editor' },
      { id: 'stats-editor', label: 'Player Stats Editor' },
      { id: 'text-editor', label: 'Script/Text Editor' },
      { id: 'map-editor', label: 'Map Viewer & Editor' },
    ],
  },
  {
    group: 'Viewers',
    panels: [
      { id: 'palette-viewer', label: 'Palette Viewer' },
      { id: 'encounter-analyzer', label: 'Encounter Analyzer' },
      { id: 'script-disasm', label: 'Script Disassembler' },
      { id: 'magic-viewer', label: 'Magic Tables' },
      { id: 'service-prices', label: 'Service Prices' },
    ],
  },
  {
    group: 'Randomizer',
    panels: [{ id: 'randomizer', label: 'Randomizer' }],
  },
  {
    group: 'Data Pipeline',
    panels: [
      { id: 'data-pipeline', label: 'Extract / Inject' },
      { id: 'rom-diff', label: 'ROM Diff' },
    ],
  },
  {
    group: 'Analysis',
    panels: [
      { id: 'lint-dashboard', label: 'Lint & Analysis' },
      { id: 'symbol-browser', label: 'Symbol Browser' },
    ],
  },
  {
    group: 'Reference',
    panels: [
      { id: 'docs', label: 'Documentation' },
      { id: 'glossary', label: 'Glossary' },
    ],
  },
];

function $(selector, root = document) {
  return root.querySelector(selector);
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

async function apiGet(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`GET ${url} failed (${response.status})`);
  return response.json();
}

async function apiPost(url, body = {}) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    let message = `POST ${url} failed (${response.status})`;
    try {
      const data = await response.json();
      if (data.error) message = data.error;
    } catch (error) {
      // ignore parse failure
    }
    throw new Error(message);
  }
  return response.json();
}

function addActivity(message, type = 'info') {
  state.activity.unshift({ message, type, time: new Date().toLocaleTimeString() });
  state.activity = state.activity.slice(0, 200);
  renderActivity();
}

function renderActivity() {
  const log = $('#activity-log');
  log.textContent = state.activity.map((entry) => `[${entry.time}] ${entry.message}`).join('\n');
}

function toast(message, type = 'good') {
  let wrap = $('.toast-wrap');
  if (!wrap) {
    wrap = el('div', 'toast-wrap');
    document.body.appendChild(wrap);
  }
  const item = el('div', `toast ${type}`, message);
  wrap.appendChild(item);
  setTimeout(() => item.remove(), 4000);
}

function setStatus(selector, text, tone) {
  const node = $(selector);
  node.textContent = text;
  node.className = `status-pill ${tone || ''}`.trim();
}

function buildNav() {
  const host = $('#nav-groups');
  host.innerHTML = '';
  for (const group of panelDefinitions) {
    const wrap = el('section', 'nav-group');
    wrap.appendChild(el('div', 'nav-group-title', group.group));
    for (const panel of group.panels) {
      const button = el('button', 'nav-item', panel.label);
      button.type = 'button';
      button.dataset.panel = panel.id;
      button.addEventListener('click', () => {
        location.hash = panel.id;
      });
      wrap.appendChild(button);
    }
    host.appendChild(wrap);
  }
}

function updateNav() {
  document.querySelectorAll('.nav-item').forEach((button) => {
    button.classList.toggle('active', button.dataset.panel === state.activePanel);
  });
}

function setBreadcrumbs(parts) {
  state.breadcrumbs = parts;
  $('#breadcrumbs').textContent = parts.join(' > ');
}

function createTerminal(title = 'Output') {
  const template = $('#terminal-template');
  const fragment = template.content.cloneNode(true);
  $('.section-header h3', fragment).textContent = title;
  const terminal = $('.terminal-output', fragment);
  return { fragment, terminal };
}

function appendTerminal(terminal, text) {
  terminal.textContent += text;
  terminal.scrollTop = terminal.scrollHeight;
}

function clearTerminal(terminal) {
  terminal.textContent = '';
}

function formatJson(value) {
  return JSON.stringify(value, null, 2);
}

function summaryMetrics(items) {
  const grid = el('div', 'metric-grid');
  for (const item of items) {
    const card = el('div', 'metric');
    card.appendChild(el('div', 'small-label', item.label));
    card.appendChild(el('div', 'value', String(item.value)));
    if (item.note) card.appendChild(el('div', 'panel-subtitle', item.note));
    grid.appendChild(card);
  }
  return grid;
}

function createCard(title, subtitle) {
  const card = el('section', 'card');
  const header = el('div', 'section-header');
  const left = el('div');
  left.appendChild(el('h3', null, title));
  if (subtitle) left.appendChild(el('div', 'panel-subtitle', subtitle));
  header.appendChild(left);
  card.appendChild(header);
  return card;
}

function commandPreview(command) {
  const box = el('div', 'cmd-preview');
  box.textContent = command;
  return box;
}

function randomizerFlagsToHex(flags) {
  let value = 0;
  if (flags.enemies) value |= 0x01;
  if (flags.shops) value |= 0x02;
  if (flags.chests) value |= 0x04;
  if (flags.encounters) value |= 0x08;
  if (flags.stats) value |= 0x10;
  if (flags.maps) value |= 0x20;
  return value.toString(16).toUpperCase().padStart(2, '0');
}

function renderMapPreviewGrid(rows) {
  return renderMapPreviewGridWithAssets(rows, []);
}

function renderMapPreviewGridWithAssets(rows, assetLayout) {
  const wrap = el('div', 'map-preview-wrap');
  const legend = el('div', 'map-preview-legend');
  const assetMap = new Map((assetLayout || []).map((entry) => [`${entry.slotX},${entry.slotY}`, entry]));
  legend.append(
    el('span', 'legend-chip fixed', 'Fixed critical sector'),
    el('span', 'legend-chip moved', 'Moved filler sector'),
    el('span', 'legend-chip generated', 'Generated route sector'),
    el('span', 'legend-chip same', 'Unchanged filler sector')
  );
  const grid = el('div', 'map-preview-grid');

  rows.forEach((row) => {
    row.forEach((slot) => {
      if (slot.missing) return;
      const asset = assetMap.get(slot.slotId);
      const generated = !!asset?.generated;
      const tone = generated ? 'generated' : (slot.fixed ? 'fixed' : (slot.moved ? 'moved' : 'same'));
      const cell = el('div', `map-slot ${tone}`);
      cell.title = `Slot ${slot.slotId} <= sector ${slot.sourceId}${slot.fixed ? ' (fixed critical)' : ''}`;
      cell.appendChild(el('div', 'slot-id', slot.slotId));
      cell.appendChild(el('div', 'slot-source', slot.sourceId));
      const meta = [];
      if (slot.specialCount) meta.push(`${slot.specialCount} anchor`);
      if (slot.fixed) cell.appendChild(el('div', 'slot-note', 'fixed'));
      else if (slot.moved) cell.appendChild(el('div', 'slot-note', 'moved'));
      if (generated) cell.appendChild(el('div', 'slot-note generated-note', 'generated'));
      if (meta.length) cell.appendChild(el('div', 'slot-meta', meta.join(' • ')));
      grid.appendChild(cell);
    });
  });

  wrap.append(legend, grid);
  return wrap;
}

function createInfoChips(items, className = '') {
  const wrap = el('div', `info-chips ${className}`.trim());
  items.forEach((item) => {
    if (!item) return;
    const chip = el('span', `info-chip ${item.tone || ''}`.trim());
    chip.textContent = item.label;
    wrap.appendChild(chip);
  });
  return wrap;
}

function renderStageValidation(stages) {
  const card = createCard('Progression Route', 'Stage-by-stage reachability through the randomized world.');
  const list = el('div', 'stage-list');
  (stages || []).forEach((stage) => {
    const row = el('div', `stage-row ${stage.ok ? 'good' : 'bad'}`);
    const head = el('div', 'stage-head');
    head.appendChild(el('div', 'stage-id', stage.id.replaceAll('_', ' ')));
    head.appendChild(el('div', `stage-status ${stage.ok ? 'good' : 'bad'}`, stage.ok ? 'PASS' : 'FAIL'));
    row.appendChild(head);
    row.appendChild(createInfoChips((stage.required || []).map((key) => ({ label: key, tone: 'muted' }))));
    if (stage.missing && stage.missing.length) {
      row.appendChild(createInfoChips(stage.missing.map((key) => ({ label: `Missing ${key}`, tone: 'bad' }))));
    }
    list.appendChild(row);
  });
  card.appendChild(list);
  return card;
}

function renderNarrativeSummary(data) {
  const card = createCard('Seed Story', 'A quick read on how this layout changes the journey.');
  const bullets = el('div', 'story-list');
  const lines = [
    `${data.summary.movedSectors} sectors move, including ${data.summary.specialSwaps || 0} special-location swaps.`,
    `${data.summary.generatedSectors || 0} filler sectors are rebuilt with road-heavy routes and loops.`,
    `${data.validation.stageValidation?.stages?.length || 0} progression checkpoints were tested before the seed was accepted.`,
  ];
  if (data.generatedSlots?.length) lines.push(`Fresh generated routes appear at ${data.generatedSlots.slice(0, 6).join(', ')}${data.generatedSlots.length > 6 ? '…' : ''}.`);
  if (data.fallback) lines.push(`Fallback note: ${data.fallback.reason} at ${data.fallback.failedStage}.`);
  lines.forEach((line) => {
    const item = el('div', 'story-item');
    item.appendChild(el('span', 'story-dot', '•'));
    item.appendChild(el('span', null, line));
    bullets.appendChild(item);
  });
  card.appendChild(bullets);
  return card;
}

function renderSwapTable(title, subtitle, rows, columns) {
  const card = createCard(title, subtitle);
  if (!rows || rows.length === 0) {
    card.appendChild(el('div', 'panel-subtitle', 'No swaps in this preview.'));
    return card;
  }
  const tableWrap = el('div', 'table-wrap compact-table');
  const table = el('table');
  const thead = el('thead');
  const headRow = el('tr');
  columns.forEach((column) => headRow.appendChild(el('th', null, column.label)));
  thead.appendChild(headRow);
  const tbody = el('tbody');
  rows.forEach((rowData) => {
    const row = el('tr');
    columns.forEach((column) => row.appendChild(el('td', null, String(column.get(rowData) ?? ''))));
    tbody.appendChild(row);
  });
  table.append(thead, tbody);
  tableWrap.appendChild(table);
  card.appendChild(tableWrap);
  return card;
}

function renderWarpTable(warpTables) {
  const card = createCard('Warp Tables', 'Runtime overworld coordinates derived from the current layout preview.');
  const sections = el('div', 'panel-grid two-col');
  const towns = renderSwapTable('Town Entrances', 'Town entry tiles now land at these overworld coordinates.', warpTables?.towns || [], [
    { label: 'Town', get: (row) => row.label },
    { label: 'Sector', get: (row) => `${row.slotX},${row.slotY}` },
    { label: 'Tile', get: (row) => `${row.x},${row.y}` },
  ]);
  const caves = renderSwapTable('Cave Entrances', 'Critical cave doors exposed by the current map.', warpTables?.caves || [], [
    { label: 'Cave', get: (row) => row.label },
    { label: 'Sector', get: (row) => `${row.slotX},${row.slotY}` },
    { label: 'Tile', get: (row) => `${row.x},${row.y}` },
  ]);
  sections.append(towns, caves);
  card.appendChild(sections);
  return card;
}

function simpleList(items, getLabel, onSelect, activeId) {
  const wrap = el('div', 'list-scroll');
  for (const item of items) {
    const button = el('button', 'list-item');
    button.type = 'button';
    button.textContent = getLabel(item);
    if (activeId && activeId(item)) button.classList.add('active');
    button.addEventListener('click', () => onSelect(item));
    wrap.appendChild(button);
  }
  return wrap;
}

function drawLineChart(canvas, series, labels) {
  const ctx = canvas.getContext('2d');
  const width = canvas.width;
  const height = canvas.height;
  ctx.clearRect(0, 0, width, height);
  ctx.fillStyle = '#03070d';
  ctx.fillRect(0, 0, width, height);
  const margin = 32;
  const allValues = series.flatMap((entry) => entry.values);
  const max = Math.max(...allValues, 1);
  ctx.strokeStyle = '#27405a';
  ctx.lineWidth = 1;
  for (let i = 0; i < 5; i += 1) {
    const y = margin + ((height - margin * 2) * i / 4);
    ctx.beginPath();
    ctx.moveTo(margin, y);
    ctx.lineTo(width - margin, y);
    ctx.stroke();
  }
  series.forEach((entry) => {
    ctx.strokeStyle = entry.color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    entry.values.forEach((value, index) => {
      const x = margin + (width - margin * 2) * (index / Math.max(labels.length - 1, 1));
      const y = height - margin - ((height - margin * 2) * value / max);
      if (index === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();
  });
}

async function renderBuildVerify(host) {
  const card = createCard('Build & Verify', 'Use bit-perfect verification for reverse-engineering work, or build a playable hacked ROM with checksum patching.');
  const actions = el('div', 'button-row');
  const buildBtn = el('button', null, 'Build ROM');
  const verifyBtn = el('button', null, 'Verify Build');
  const hackBuildBtn = el('button', 'secondary', 'Build Patched ROM');
  const terminalView = createTerminal('Build Output');
  const cmd = commandPreview('cmd /c build.bat | cmd /c verify.bat   or   cmd /c build.bat + checksum patch');
  actions.append(buildBtn, verifyBtn, hackBuildBtn);
  card.append(actions, cmd, terminalView.fragment);
  host.appendChild(card);
  const terminal = $('.terminal-output', card);

  const run = async (url, label) => {
    clearTerminal(terminal);
    appendTerminal(terminal, `${label}...\n`);
    addActivity(`${label} requested`);
    try {
      const result = await apiPost(url);
      appendTerminal(terminal, result.stdout || '');
      if (result.stderr) appendTerminal(terminal, `\n[stderr]\n${result.stderr}`);
      if (url.endsWith('/verify')) {
        state.lastBuildOk = !!result.bitPerfect;
        setStatus('#build-state', `Verify: ${result.bitPerfect ? 'pass' : 'fail'}`, result.bitPerfect ? 'good' : 'bad');
      }
      toast(`${label} complete`, result.success ? 'good' : 'bad');
    } catch (error) {
      appendTerminal(terminal, `\nERROR: ${error.message}`);
      toast(error.message, 'bad');
    }
  };

  buildBtn.addEventListener('click', () => run('/api/build', 'Build'));
  verifyBtn.addEventListener('click', () => run('/api/verify', 'Verify'));
  hackBuildBtn.addEventListener('click', () => run('/api/build-hack', 'Build patched ROM'));
}

async function renderEnemyEditor(host) {
  const data = await apiGet('/api/enemies');
  let selected = data.enemies[0] || null;
  const grid = el('div', 'panel-grid two-col');
  const left = createCard('Enemies', 'Search and select an enemy to edit.');
  const right = createCard('Enemy Details', 'Edit stats and apply through the existing CLI tool.');
  const search = el('input');
  search.type = 'search';
  search.placeholder = 'Filter enemies';
  left.appendChild(search);
  const listWrap = el('div', 'list-scroll');
  left.appendChild(listWrap);

  const detail = el('div');
  right.appendChild(detail);
  grid.append(left, right);
  host.appendChild(grid);

  function refreshList() {
    const query = search.value.trim().toLowerCase();
    listWrap.innerHTML = '';
    data.enemies
      .filter((enemy) => enemy.stats.name.toLowerCase().includes(query))
      .forEach((enemy) => {
        const button = el('button', 'list-item', `${enemy.stats.name}  HP:${enemy.stats.hp}  DMG:${enemy.stats.damage_per_hit}`);
        button.type = 'button';
        if (selected && selected.stats.name === enemy.stats.name) button.classList.add('active');
        button.addEventListener('click', () => {
          selected = enemy;
          refreshList();
          renderDetail();
        });
        listWrap.appendChild(button);
      });
  }

  function renderDetail() {
    if (!selected) return;
    detail.innerHTML = '';
    detail.appendChild(summaryMetrics([
      { label: 'Enemy', value: selected.stats.name },
      { label: 'AI', value: selected.stats.ai_fn },
      { label: 'Tile', value: selected.stats.tile_id },
      { label: 'Speed', value: selected.stats.speed },
    ]));
    const form = el('div', 'field-grid');
    const editable = ['hp', 'damage_per_hit', 'speed', 'xp_reward', 'kim_reward', 'behavior_flag', 'max_spawn'];
    const inputs = {};
    editable.forEach((key) => {
      const field = el('div', 'field');
      field.appendChild(el('label', null, key));
      const input = el('input');
      input.type = 'number';
      input.value = selected.stats[key];
      inputs[key] = input;
      field.appendChild(input);
      form.appendChild(field);
    });
    const actions = el('div', 'button-row');
    const preview = el('button', 'secondary', 'Preview Dry Run');
    const apply = el('button', null, 'Apply Changes');
    const terminalView = createTerminal('Enemy Editor Output');
    const terminal = $('.terminal-output', terminalView.fragment);
    actions.append(preview, apply);
    detail.append(form, actions, commandPreview(`node tools/editor/enemy_editor.js --enemy ${selected.stats.name} --set hp=<value> ...`), terminalView.fragment);

    async function submit(dryRun) {
      clearTerminal(terminal);
      const updates = {};
      for (const [key, input] of Object.entries(inputs)) updates[key] = Number(input.value);
      const response = await apiPost(`/api/enemies/${encodeURIComponent(selected.stats.name)}`, { updates, dryRun });
      appendTerminal(terminal, response.stdout || '');
      if (response.stderr) appendTerminal(terminal, `\n${response.stderr}`);
      if (response.enemy) selected = response.enemy;
      refreshList();
      toast(dryRun ? 'Enemy dry run complete' : 'Enemy updated', response.success ? 'good' : 'bad');
    }

    preview.addEventListener('click', () => submit(true).catch((error) => toast(error.message, 'bad')));
    apply.addEventListener('click', () => submit(false).catch((error) => toast(error.message, 'bad')));
  }

  search.addEventListener('input', refreshList);
  refreshList();
  renderDetail();
}

async function renderShopEditor(host) {
  const data = await apiGet('/api/shops');
  let selected = data.towns[0] || null;
  const grid = el('div', 'panel-grid two-col');
  const left = createCard('Towns', 'Select a town to inspect its inventories.');
  const right = createCard('Shop Inventories', 'Edit the JSON shape, then inject through the data pipeline.');
  const list = el('div', 'list-scroll');
  left.appendChild(list);
  grid.append(left, right);
  host.appendChild(grid);

  function renderList() {
    list.innerHTML = '';
    data.towns.forEach((town) => {
      const button = el('button', 'list-item', town.town_name);
      button.type = 'button';
      if (selected && selected.town_name === town.town_name) button.classList.add('active');
      button.addEventListener('click', () => {
        selected = town;
        renderList();
        renderTown();
      });
      list.appendChild(button);
    });
  }

  function inventoryTable(shopEntry, label) {
    const section = createCard(label, shopEntry ? shopEntry.assortment_label : 'No shop');
    if (!shopEntry) return section;
    const wrap = el('div', 'table-wrap');
    const table = el('table');
    table.innerHTML = '<thead><tr><th>Slot</th><th>Item</th><th>Price</th></tr></thead>';
    const body = el('tbody');
    shopEntry.assortment.items.forEach((item, index) => {
      const row = el('tr');
      row.innerHTML = `<td>${index + 1}</td><td>${item.item_name || item.item_constant || item.equip_id_constant || item.magic_constant || ''}</td><td>${shopEntry.prices[index] ?? ''}</td>`;
      body.appendChild(row);
    });
    table.appendChild(body);
    wrap.appendChild(table);
    section.appendChild(wrap);
    return section;
  }

  function renderTown() {
    right.innerHTML = '';
    if (!selected) return;
    right.appendChild(summaryMetrics([{ label: 'Town', value: selected.town_name }, { label: 'Town ID', value: selected.town_id }]));
    const cols = el('div', 'panel-grid three-col');
    cols.append(
      inventoryTable(selected.shops.item, 'Item Shop'),
      inventoryTable(selected.shops.equipment, 'Equipment Shop'),
      inventoryTable(selected.shops.magic_buy || selected.shops.magic_sell, 'Magic Shop')
    );
    right.appendChild(cols);
    const jsonCard = createCard('Town JSON', 'Edit directly, then inject through the backend.');
    const textarea = el('textarea');
    textarea.value = formatJson(selected);
    const row = el('div', 'button-row');
    const preview = el('button', 'secondary', 'Preview');
    const apply = el('button', null, 'Save & Inject');
    row.append(preview, apply);
    jsonCard.append(textarea, row, commandPreview('node tools/inject_game_data.js --shops'));
    right.appendChild(jsonCard);
    preview.addEventListener('click', () => {
      try {
        JSON.parse(textarea.value);
        toast('JSON valid', 'good');
      } catch (error) {
        toast(error.message, 'bad');
      }
    });
    apply.addEventListener('click', async () => {
      const town = JSON.parse(textarea.value);
      await apiPost(`/api/shops/${encodeURIComponent(selected.town_name)}`, { town });
      toast('Shop data injected', 'good');
    });
  }

  renderList();
  renderTown();
}

async function renderStatsEditor(host) {
  const data = await apiGet('/api/player-stats');
  const card = createCard('Player Stat Curves', 'Interactive view of per-level stat gains.');
  card.appendChild(summaryMetrics([
    { label: 'Levels', value: data.level_count },
    { label: 'First XP Target', value: data.level_ups[0].xp_to_next },
    { label: 'Final XP Target', value: data.level_ups[data.level_ups.length - 1].xp_to_next },
  ]));
  const canvasWrap = el('div', 'canvas-wrap');
  const canvas = document.createElement('canvas');
  canvas.width = 960;
  canvas.height = 320;
  canvasWrap.appendChild(canvas);
  card.appendChild(canvasWrap);
  const tableWrap = el('div', 'table-wrap');
  const table = el('table');
  table.innerHTML = '<thead><tr><th>Lvl</th><th>MHP</th><th>MMP</th><th>STR</th><th>AC</th><th>INT</th><th>DEX</th><th>LUK</th><th>XP</th></tr></thead>';
  const tbody = el('tbody');
  data.level_ups.forEach((row) => {
    const tr = el('tr');
    tr.innerHTML = `<td>${row.level}</td><td>${row.mhp_gain}</td><td>${row.mmp_gain}</td><td>${row.str_gain}</td><td>${row.ac_gain}</td><td>${row.int_gain}</td><td>${row.dex_gain}</td><td>${row.luk_gain}</td><td>${row.xp_to_next}</td>`;
    tbody.appendChild(tr);
  });
  table.appendChild(tbody);
  tableWrap.appendChild(table);
  card.appendChild(tableWrap);
  host.appendChild(card);
  drawLineChart(canvas, [
    { color: '#d4a74a', values: data.level_ups.map((row) => row.mhp_gain) },
    { color: '#4ca8d8', values: data.level_ups.map((row) => row.mmp_gain) },
    { color: '#5bc47a', values: data.level_ups.map((row) => row.str_gain) },
  ], data.level_ups.map((row) => row.level));
}

async function renderTextEditor(host) {
  const scripts = await apiGet('/api/scripts');
  let selected = scripts[0] || null;
  const grid = el('div', 'panel-grid two-col');
  const left = createCard('Scripts', 'Searchable script label browser.');
  const right = createCard('Text Editor', 'Patch one script label at a time.');
  const search = el('input');
  search.type = 'search';
  search.placeholder = 'Find label or text';
  const list = el('div', 'list-scroll');
  left.append(search, list);
  grid.append(left, right);
  host.appendChild(grid);

  function refreshList() {
    const q = search.value.trim().toLowerCase();
    list.innerHTML = '';
    scripts.filter((entry) => entry.label.toLowerCase().includes(q) || entry.text.toLowerCase().includes(q)).slice(0, 300).forEach((entry) => {
      const button = el('button', 'list-item', `${entry.label}  (${entry.byteCount} bytes)`);
      button.type = 'button';
      if (selected && selected.label === entry.label) button.classList.add('active');
      button.addEventListener('click', async () => {
        selected = entry;
        refreshList();
        await renderDetail();
      });
      list.appendChild(button);
    });
  }

  async function renderDetail() {
    right.innerHTML = '';
    if (!selected) return;
    const detail = await apiGet(`/api/scripts/${encodeURIComponent(selected.label)}`);
    const textarea = el('textarea');
    const currentText = detail.instructions.map((instruction) => {
      if (instruction.mnemonic === 'TEXT') return instruction.text || '';
      if (instruction.mnemonic === 'NEWLINE') return '\n';
      if (instruction.mnemonic === 'CONTINUE') return '\f';
      if (instruction.mnemonic === 'PLAYER_NAME') return '\p';
      return instruction.mnemonic === 'END' ? '' : `[${instruction.mnemonic}]`;
    }).join('');
    textarea.value = currentText;
    const counter = el('div', 'panel-subtitle', `Address: ${detail.start_addr || detail.address || ''}`);
    const row = el('div', 'button-row');
    const validate = el('button', 'secondary', 'Validate');
    const dryRun = el('button', 'secondary', 'Dry Run');
    const apply = el('button', null, 'Apply Patch');
    const terminalView = createTerminal('Script Tool Output');
    const terminal = $('.terminal-output', terminalView.fragment);
    row.append(validate, dryRun, apply);
    right.append(counter, textarea, row, commandPreview(`node tools/script_patch.js --patch <tmp> ; label=${selected.label}`), terminalView.fragment);
    validate.addEventListener('click', async () => {
      const result = await apiPost(`/api/scripts/${encodeURIComponent(selected.label)}/validate`, { newText: textarea.value });
      clearTerminal(terminal);
      appendTerminal(terminal, result.stdout || 'Validation complete');
    });
    dryRun.addEventListener('click', async () => {
      const result = await apiPost(`/api/scripts/${encodeURIComponent(selected.label)}`, { newText: textarea.value, dryRun: true });
      clearTerminal(terminal);
      appendTerminal(terminal, result.stdout || '');
    });
    apply.addEventListener('click', async () => {
      const result = await apiPost(`/api/scripts/${encodeURIComponent(selected.label)}`, { newText: textarea.value });
      clearTerminal(terminal);
      appendTerminal(terminal, result.stdout || '');
      toast('Script patch applied', result.success ? 'good' : 'bad');
    });
  }

  search.addEventListener('input', refreshList);
  refreshList();
  await renderDetail();
}

async function renderMapEditor(host) {
  const overworld = await apiGet('/api/maps/overworld');
  let selected = overworld[0];
  const grid = el('div', 'panel-grid two-col');
  const left = createCard('Overworld Sectors', 'Choose a sector to inspect and paint tiles.');
  const right = createCard('Map Detail', 'Canvas preview plus single-tile edits through map_editor.js.');
  const list = el('div', 'list-scroll');
  left.appendChild(list);
  grid.append(left, right);
  host.appendChild(grid);

  function renderList() {
    list.innerHTML = '';
    overworld.forEach((sector) => {
      const button = el('button', 'list-item', `Sector ${sector.x},${sector.y}`);
      button.type = 'button';
      if (selected && selected.x === sector.x && selected.y === sector.y) button.classList.add('active');
      button.addEventListener('click', async () => {
        selected = sector;
        renderList();
        await renderDetail();
      });
      list.appendChild(button);
    });
  }

  async function renderDetail() {
    right.innerHTML = '';
    const map = await apiGet(`/api/maps/overworld/${selected.x}/${selected.y}`);
    const canvasWrap = el('div', 'canvas-wrap');
    const canvas = document.createElement('canvas');
    canvas.width = 512;
    canvas.height = 512;
    canvasWrap.appendChild(canvas);
    const ctx = canvas.getContext('2d');
    const tileSize = 32;
    map.grid.forEach((row, rowIndex) => {
      row.forEach((tile, colIndex) => {
        ctx.fillStyle = map.colors[String(tile)] || '#333333';
        ctx.fillRect(colIndex * tileSize, rowIndex * tileSize, tileSize, tileSize);
        ctx.strokeStyle = 'rgba(255,255,255,0.08)';
        ctx.strokeRect(colIndex * tileSize, rowIndex * tileSize, tileSize, tileSize);
      });
    });
    const form = el('div', 'inline-form');
    const col = el('input'); col.type = 'number'; col.placeholder = 'Col'; col.min = '0'; col.max = '15';
    const row = el('input'); row.type = 'number'; row.placeholder = 'Row'; row.min = '0'; row.max = '15';
    const tile = el('input'); tile.type = 'number'; tile.placeholder = 'Tile';
    const apply = el('button', null, 'Set Tile');
    form.append(col, row, tile, apply);
    const pre = el('pre', 'terminal-output compact');
    pre.textContent = map.ascii;
    right.append(canvasWrap, form, commandPreview(`node tools/editor/map_editor.js overworld ${selected.x} ${selected.y} set <col> <row> <tile>`), pre);
    apply.addEventListener('click', async () => {
      await apiPost(`/api/maps/overworld/${selected.x}/${selected.y}/tile`, { col: Number(col.value), row: Number(row.value), tileId: Number(tile.value) });
      toast('Tile updated', 'good');
      await renderDetail();
    });
  }

  renderList();
  await renderDetail();
}

async function renderPaletteViewer(host) {
  const palettes = await apiGet('/api/palettes');
  const card = createCard('Palette Viewer', 'Genesis CRAM palettes rendered as HTML swatches.');
  host.appendChild(card);
  palettes.slice(0, 16).forEach((palette) => {
    const row = createCard(`Palette ${palette.index}`, palette.name || 'Generated from palette_data.bin');
    const swatches = el('div', 'swatch-grid');
    palette.colors.forEach((color) => {
      const swatch = el('div', 'swatch');
      const colorBox = el('div', 'swatch-color');
      colorBox.style.background = color.hex;
      const meta = el('div', 'swatch-meta');
      meta.textContent = `${color.cram} ${color.hex}`;
      swatch.append(colorBox, meta);
      swatches.appendChild(swatch);
    });
    row.appendChild(swatches);
    card.appendChild(row);
  });
}

async function renderEncounterAnalyzer(host) {
  const [curve, groups] = await Promise.all([
    apiGet('/api/encounters/curve'),
    apiGet('/api/encounters/groups'),
  ]);
  const card = createCard('Encounter Analyzer', 'Read-only views over encounter data and difficulty curves.');
  host.appendChild(card);
  card.appendChild(summaryMetrics([
    { label: 'Overworld Entries', value: (curve.overworld || curve.overworldGrid || []).length || 'n/a' },
    { label: 'Group Count', value: Object.keys(groups.groups || groups || {}).length },
  ]));
  const code = el('pre', 'terminal-output');
  code.textContent = formatJson(curve).slice(0, 15000);
  card.appendChild(code);
}

async function renderRandomizer(host) {
  const presets = await apiGet('/api/randomizer/presets');
  const card = createCard('Randomizer Studio', 'Shape a seed, preview the world shift, then apply it once the route looks fun and safe.');
  const form = el('div', 'field-grid');
  const seed = el('input');
  seed.value = String(Date.now());
  const variance = el('input');
  variance.type = 'number';
  variance.step = '0.1';
  variance.value = '0.5';
  const mapMode = el('select');
  mapMode.append(new Option('Special Shuffle + Generated Routes', 'special-shuffle-generated'));
  const flags = ['enemies', 'shops', 'chests', 'encounters', 'stats', 'maps'];
  form.append(Object.assign(el('div', 'field'), { innerHTML: '<label>Seed</label>' }));
  form.lastChild.appendChild(seed);
  form.append(Object.assign(el('div', 'field'), { innerHTML: '<label>Variance</label>' }));
  form.lastChild.appendChild(variance);
  form.append(Object.assign(el('div', 'field'), { innerHTML: '<label>Map Mode</label>' }));
  form.lastChild.appendChild(mapMode);
  const checks = el('div', 'field-grid');
  const inputs = {};
  flags.forEach((flag) => {
    const wrap = el('label', 'metric');
    const input = document.createElement('input');
    input.type = 'checkbox';
    input.checked = true;
    inputs[flag] = input;
    wrap.append(input, document.createTextNode(` ${flag}`));
    checks.appendChild(wrap);
  });
  const presetRow = el('div', 'button-row');
  presets.forEach((preset) => {
    const button = el('button', 'secondary', preset.name);
    button.type = 'button';
    button.addEventListener('click', () => {
      flags.forEach((flag) => { inputs[flag].checked = !!preset.flags[flag]; });
    });
    presetRow.appendChild(button);
  });
  const buttons = el('div', 'button-row');
  const dryRun = el('button', 'secondary', 'Dry Run');
  const previewMaps = el('button', 'secondary', 'Preview Maps');
  const apply = el('button', null, 'Run Randomizer');
  buttons.append(dryRun, previewMaps, apply);
  const terminalView = createTerminal('Randomizer Output');
  const terminal = $('.terminal-output', terminalView.fragment);
  const cmdPreview = commandPreview('');
  card.append(form, checks, presetRow, buttons, cmdPreview, terminalView.fragment);
  host.appendChild(card);

  const previewCard = createCard('Map Preview', 'See the route structure, special-location movement, and stage validation before you commit to a seed.');
  const previewHost = el('div', 'panel-grid');
  previewCard.appendChild(previewHost);
  host.appendChild(previewCard);

  function buildPayload() {
    return {
      seed: seed.value,
      variance: Number(variance.value),
      mapMode: mapMode.value,
      flags: Object.fromEntries(flags.map((flag) => [flag, inputs[flag].checked])),
    };
  }

  function updateCommand() {
    const payload = buildPayload();
    const command = ['node tools/randomizer/randomize.js', `--seed ${payload.seed || '<seed>'}`, `--flags ${randomizerFlagsToHex(payload.flags)}`];
    if (!Number.isNaN(payload.variance)) command.push(`--variance ${payload.variance}`);
    if (payload.flags.maps) command.push(`--maps-mode ${payload.mapMode}`);
    cmdPreview.textContent = command.join(' ');
  }

  function renderPreview(data) {
    previewHost.innerHTML = '';
    const hero = createCard(`Seed ${data.seed}`, 'This preview combines sector swaps, special-location movement, generated routes, and progression validation.');
    hero.appendChild(createInfoChips([
      { label: data.validation.ok ? 'Completable route' : 'Route failed', tone: data.validation.ok ? 'good' : 'bad' },
      { label: `${data.summary.specialSwaps || 0} special swaps`, tone: 'info' },
      { label: `${data.summary.generatedSectors || 0} generated sectors`, tone: 'warn' },
      { label: `${data.summary.fillerSwaps || 0} filler swaps`, tone: 'muted' },
    ], 'hero-chips'));
    hero.appendChild(summaryMetrics([
      { label: 'Fixed Sectors', value: data.summary.fixedSectors },
      { label: 'Movable Sectors', value: data.summary.movableSectors },
      { label: 'Moved Sectors', value: data.summary.movedSectors },
      { label: 'Generated Sectors', value: data.summary.generatedSectors || 0, note: 'Fresh road-heavy filler sectors written as real binary assets on apply' },
      { label: 'Reachable Specials', value: `${data.summary.reachableSpecials}/${data.summary.reachableSpecials + data.summary.unreachableSpecials}` },
      { label: 'Validation', value: data.validation.ok ? 'PASS' : 'FAIL', note: data.validation.ok ? 'Spatial + stage checks passed' : 'Preview needs a different seed or ruleset' },
    ]));
    previewHost.appendChild(hero);
    previewHost.appendChild(renderNarrativeSummary(data));
    previewHost.appendChild(renderMapPreviewGridWithAssets(data.layout.rows, data.assetLayout));
    previewHost.appendChild(renderStageValidation(data.validation.stageValidation?.stages || []));
    const swapsGrid = el('div', 'panel-grid two-col');
    swapsGrid.append(
      renderSwapTable('Special Swaps', 'Important anchors that changed homes in this seed.', data.specialSwaps || [], [
        { label: 'Kind', get: (row) => row.kind },
        { label: 'ID', get: (row) => row.id },
        { label: 'A', get: (row) => row.slotA },
        { label: 'B', get: (row) => row.slotB },
      ]),
      renderSwapTable('Generated Routes', 'Freshly rebuilt sectors with more deliberate local pathing.', (data.generatedSlots || []).map((slotId) => ({ slotId })), [
        { label: 'Slot', get: (row) => row.slotId },
      ])
    );
    previewHost.appendChild(swapsGrid);
    previewHost.appendChild(renderWarpTable(data.warpTables));
    const detailsCard = createCard('Debug JSON', 'Full preview payload for deeper inspection or debugging.');
    const details = el('pre', 'json-view');
    details.textContent = formatJson({
      notes: data.notes,
      generatedSlots: data.generatedSlots,
      specialSwaps: data.specialSwaps,
      warpTables: data.warpTables,
      stageValidation: data.validation.stageValidation,
      missingReachable: data.validation.missingReachable,
      unexpectedReachable: data.validation.unexpectedReachable,
      sampleRoutes: data.validation.sampleRoutes,
      movedPreview: data.movedSectors.slice(0, 24),
    });
    detailsCard.appendChild(details);
    previewHost.appendChild(detailsCard);
    state.data.lastMapPreview = data;
  }

  [seed, variance, mapMode].forEach((node) => node.addEventListener('input', updateCommand));
  flags.forEach((flag) => inputs[flag].addEventListener('change', updateCommand));
  updateCommand();

  async function run(dry) {
    clearTerminal(terminal);
    const result = await apiPost(dry ? '/api/randomizer/dry-run' : '/api/randomizer/run', buildPayload());
    appendTerminal(terminal, result.stdout || '');
    if (result.stderr) appendTerminal(terminal, `\n${result.stderr}`);
  }

  async function preview() {
    previewHost.innerHTML = '';
    const loading = createCard('Generating Preview', 'Building route graph, shuffling sectors, validating milestones, and preparing warp tables.');
    loading.appendChild(createInfoChips([
      { label: 'Analyzing world graph', tone: 'info' },
      { label: 'Testing progression stages', tone: 'warn' },
      { label: 'Preparing preview payload', tone: 'muted' },
    ]));
    previewHost.appendChild(loading);
    const data = await apiPost('/api/randomizer/maps/preview', buildPayload());
    renderPreview(data);
  }

  dryRun.addEventListener('click', () => run(true).catch((error) => toast(error.message, 'bad')));
  previewMaps.addEventListener('click', () => preview().catch((error) => toast(error.message, 'bad')));
  apply.addEventListener('click', () => run(false).catch((error) => toast(error.message, 'bad')));
}

async function renderDataPipeline(host) {
  const [files, magic, services] = await Promise.all([
    apiGet('/api/data/files'),
    apiGet('/api/magic'),
    apiGet('/api/services'),
  ]);
  const card = createCard('Data Pipeline', 'Extract and inject JSON-backed data sets.');
  const actions = el('div', 'button-row');
  const extract = el('button', null, 'Extract All');
  const inject = el('button', 'secondary', 'Inject All');
  actions.append(extract, inject);
  card.appendChild(actions);
  const tableWrap = el('div', 'table-wrap');
  const table = el('table');
  table.innerHTML = '<thead><tr><th>File</th><th>Size</th><th>Updated</th><th>Records</th></tr></thead>';
  const tbody = el('tbody');
  files.forEach((file) => {
    const row = el('tr');
    row.innerHTML = `<td>${file.file}</td><td>${file.size}</td><td>${file.updatedAt}</td><td>${file.recordCount ?? ''}</td>`;
    tbody.appendChild(row);
  });
  table.appendChild(tbody);
  tableWrap.appendChild(table);
  card.appendChild(tableWrap);
  const split = el('div', 'panel-grid two-col');
  const magicCard = createCard('Magic JSON', null);
  magicCard.appendChild(el('pre', 'json-view', formatJson(magic)));
  const serviceCard = createCard('Service Prices JSON', null);
  serviceCard.appendChild(el('pre', 'json-view', formatJson(services)));
  split.append(magicCard, serviceCard);
  card.appendChild(split);
  host.appendChild(card);
  extract.addEventListener('click', async () => {
    await apiPost('/api/data/extract');
    toast('Data extracted', 'good');
  });
  inject.addEventListener('click', async () => {
    await apiPost('/api/data/inject', { targets: ['all'] });
    toast('Data injected', 'good');
  });
}

async function renderRomDiff(host) {
  const card = createCard('ROM Diff', 'Compare current out.bin against another ROM file path.');
  const form = el('div', 'field-grid');
  const romA = el('input'); romA.value = 'out.bin';
  const romB = el('input'); romB.value = 'orig_backup.bin';
  const button = el('button', null, 'Compare');
  const output = el('pre', 'terminal-output');
  form.append(Object.assign(el('div', 'field'), { innerHTML: '<label>ROM A</label>' }), Object.assign(el('div', 'field'), { innerHTML: '<label>ROM B</label>' }));
  form.children[0].appendChild(romA);
  form.children[1].appendChild(romB);
  card.append(form, button, output);
  host.appendChild(card);
  button.addEventListener('click', async () => {
    const result = await apiPost('/api/rom-diff', { romA: romA.value, romB: romB.value, context: 8, max: 50 });
    output.textContent = formatJson(result);
  });
}

async function renderLintDashboard(host) {
  const [coverage, density, deadCode, magic, progression] = await Promise.all([
    apiGet('/api/lint/label-coverage'),
    apiGet('/api/lint/comment-density'),
    apiGet('/api/lint/dead-code'),
    apiGet('/api/lint/magic-numbers'),
    apiGet('/api/lint/progression'),
  ]);
  const card = createCard('Lint & Analysis', 'Aggregated static analysis reports.');
  card.appendChild(summaryMetrics([
    { label: 'Label Coverage', value: `${coverage.percentage}%` },
    { label: 'loc_ Remaining', value: coverage.locRemaining },
    { label: 'Comment Files', value: density.length },
    { label: 'Dead Labels', value: deadCode.deadLabels.length },
    { label: 'Magic Numbers', value: magic.entries.length },
    { label: 'Completable', value: progression.result || progression.summary || 'see JSON' },
  ]));
  const button = el('button', null, 'Run All Checks');
  const terminalView = createTerminal('Lint Output');
  const terminal = $('.terminal-output', terminalView.fragment);
  card.append(button, terminalView.fragment);
  const reports = el('div', 'panel-grid two-col');
  const left = createCard('Coverage / Comment Density', null);
  left.appendChild(el('pre', 'json-view', formatJson({ coverage, density: density.slice(0, 20) })));
  const right = createCard('Dead Code / Magic Numbers / Progression', null);
  right.appendChild(el('pre', 'json-view', formatJson({ deadCode: deadCode.deadLabels.slice(0, 50), magic: magic.entries.slice(0, 20), progression })));
  reports.append(left, right);
  card.appendChild(reports);
  host.appendChild(card);
  button.addEventListener('click', async () => {
    const result = await apiPost('/api/lint/run-all');
    clearTerminal(terminal);
    appendTerminal(terminal, result.raw || result.stdout || '');
  });
}

async function renderScriptDisasm(host) {
  const list = await apiGet('/api/script-disasm/list');
  const opcodes = await apiGet('/api/index/script-opcodes').catch(() => null);
  const card = createCard('Script Disassembler', 'Browse generated script bytecode output.');
  card.appendChild(el('pre', 'json-view', formatJson(list.slice(0, 100))));
  if (opcodes) card.appendChild(el('pre', 'json-view', formatJson(opcodes)));
  host.appendChild(card);
}

async function renderSymbolBrowser(host) {
  const [symbols, functions, callsites, ram, includeGraph] = await Promise.all([
    apiGet('/api/index/symbols'),
    apiGet('/api/index/functions'),
    apiGet('/api/index/callsites'),
    apiGet('/api/index/ram-symbols'),
    apiGet('/api/index/include-graph'),
  ]);
  const card = createCard('Symbol Browser', 'Searchable view of generated indexes.');
  card.appendChild(summaryMetrics([
    { label: 'Symbols', value: symbols.length },
    { label: 'Functions', value: functions.length },
    { label: 'RAM Symbols', value: ram.symbols.length },
    { label: 'Tracked Calls', value: callsites._meta.total_callsites },
  ]));
  const split = el('div', 'panel-grid two-col');
  split.append(
    Object.assign(createCard('Top Symbols', null), { }),
    Object.assign(createCard('Include Graph', null), { })
  );
  split.children[0].appendChild(el('pre', 'json-view', formatJson(symbols.slice(0, 120))));
  split.children[1].appendChild(el('pre', 'json-view', formatJson(includeGraph)));
  card.appendChild(split);
  host.appendChild(card);
}

async function renderMagicViewer(host) {
  const data = await apiGet('/api/magic');
  const card = createCard('Magic Tables', 'Read-only spell data extracted from ASM.');
  const tableWrap = el('div', 'table-wrap');
  const table = el('table');
  table.innerHTML = '<thead><tr><th>ID</th><th>Name</th><th>MP</th><th>Tier</th><th>Base</th><th>Element</th></tr></thead>';
  const tbody = el('tbody');
  data.magic.forEach((spell) => {
    const row = el('tr');
    row.innerHTML = `<td>${spell.id}</td><td>${spell.name}</td><td>${spell.mp_cost}</td><td>${spell.damage_tier}</td><td>${spell.damage_base}</td><td>${spell.element}</td>`;
    tbody.appendChild(row);
  });
  table.appendChild(tbody);
  tableWrap.appendChild(table);
  card.appendChild(tableWrap);
  host.appendChild(card);
}

async function renderServicePrices(host) {
  const data = await apiGet('/api/services');
  const card = createCard('Service Prices', 'Town-by-town service cost comparison.');
  card.appendChild(el('pre', 'json-view', formatJson(data)));
  host.appendChild(card);
}

async function renderDocs(host, fileOverride) {
  const docs = await apiGet('/api/docs');
  const selected = fileOverride || (docs[0] ? docs[0].file : null);
  const [leftDoc, content] = await Promise.all([
    Promise.resolve(docs),
    selected ? apiGet(`/api/docs/${selected}`) : Promise.resolve({ html: '<p>No docs.</p>' }),
  ]);
  const grid = el('div', 'panel-grid two-col');
  const left = createCard('Documents', 'Browse markdown documentation bundled with the repo.');
  const right = createCard(selected || 'Documentation', null);
  const list = el('div', 'list-scroll');
  leftDoc.forEach((doc) => {
    const button = el('button', 'list-item', doc.title);
    button.type = 'button';
    if (doc.file === selected) button.classList.add('active');
    button.addEventListener('click', () => {
      location.hash = `docs:${doc.file}`;
    });
    list.appendChild(button);
  });
  left.appendChild(list);
  const view = el('div', 'doc-view');
  view.innerHTML = content.html;
  right.appendChild(view);
  grid.append(left, right);
  host.appendChild(grid);
}

const renderers = {
  'build-verify': renderBuildVerify,
  'enemy-editor': renderEnemyEditor,
  'shop-editor': renderShopEditor,
  'stats-editor': renderStatsEditor,
  'text-editor': renderTextEditor,
  'map-editor': renderMapEditor,
  'palette-viewer': renderPaletteViewer,
  'encounter-analyzer': renderEncounterAnalyzer,
  randomizer: renderRandomizer,
  'data-pipeline': renderDataPipeline,
  'rom-diff': renderRomDiff,
  'lint-dashboard': renderLintDashboard,
  'script-disasm': renderScriptDisasm,
  'symbol-browser': renderSymbolBrowser,
  'magic-viewer': renderMagicViewer,
  'service-prices': renderServicePrices,
  docs: (host) => renderDocs(host, (location.hash.split(':')[1] || '').trim() || null),
  glossary: (host) => renderDocs(host, 'glossary.md'),
};

async function showPanel(panelId) {
  const host = $('#panel-host');
  host.innerHTML = '';
  state.activePanel = panelId;
  updateNav();
  const label = document.querySelector(`.nav-item[data-panel="${panelId}"]`)?.textContent || panelId;
  $('#panel-title').textContent = label;
  $('#panel-subtitle').textContent = panelId === 'randomizer'
    ? 'Preview solvable seeds, inspect route quality, and apply randomized worlds with confidence.'
    : 'Tooling hub for build checks, editors, analysis, and guided randomizer workflows.';
  setBreadcrumbs(['Home', label]);
  try {
    await (renderers[panelId] || renderBuildVerify)(host);
  } catch (error) {
    const card = createCard('Error', 'This panel failed to load.');
    card.appendChild(el('pre', 'terminal-output', error.stack || error.message));
    host.appendChild(card);
    toast(error.message, 'bad');
  }
}

function currentPanelFromHash() {
  const hash = location.hash.replace(/^#/, '');
  if (!hash) return 'build-verify';
  const base = hash.split(':')[0];
  return renderers[base] ? base : 'build-verify';
}

function connectWebSocket() {
  const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const ws = new WebSocket(`${protocol}//${location.host}/ws`);
  state.ws = ws;
  ws.addEventListener('open', () => {
    setStatus('#server-state', 'Server: connected', 'good');
    addActivity('WebSocket connected');
  });
  ws.addEventListener('close', () => {
    setStatus('#server-state', 'Server: reconnecting', 'warn');
    addActivity('WebSocket disconnected');
    setTimeout(connectWebSocket, 1500);
  });
  ws.addEventListener('message', (event) => {
    try {
      const message = JSON.parse(event.data);
      if (message.type === 'tool-output') {
        addActivity(`${message.taskId} ${message.stream}: ${message.data.trim().slice(0, 80)}`);
      } else if (message.type === 'build-status') {
        setStatus('#build-state', `Verify: ${message.bitPerfect ? 'pass' : (message.success ? 'ok' : 'fail')}`, message.bitPerfect ? 'good' : (message.success ? 'info' : 'bad'));
      } else if (message.type === 'file-changed') {
        addActivity(`File changed: ${message.file}`);
      }
    } catch (error) {
      // ignore malformed messages
    }
  });
}

async function bootstrap() {
  buildNav();
  $('#sidebar-toggle').addEventListener('click', () => {
    $('#nav-groups').classList.toggle('collapsed');
  });
  $('#clear-activity').addEventListener('click', () => {
    state.activity = [];
    renderActivity();
  });
  $('#global-search').addEventListener('keydown', (event) => {
    if (event.key !== 'Enter') return;
    location.hash = 'symbol-browser';
  });
  window.addEventListener('hashchange', () => showPanel(currentPanelFromHash()));
  connectWebSocket();
  try {
    const health = await apiGet('/api/health');
    setStatus('#server-state', `Server: ${health.status}`, 'good');
  } catch (error) {
    setStatus('#server-state', 'Server: offline', 'bad');
  }
  await showPanel(currentPanelFromHash());
}

bootstrap();
