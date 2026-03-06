'use strict';
// tools/update_todos_stats.js
//
// Reads todos.json, counts tasks by status, priority, and category, then
// rewrites the "statistics" block in-place with fresh counts.
//
// Usage:
//   node tools/update_todos_stats.js [--todos <path>]
//
// Exit 0 on success.  The file is rewritten atomically (write to temp, rename).

const fs   = require('fs');
const path = require('path');

const repoRoot  = path.resolve(__dirname, '..');
const args      = process.argv.slice(2);
const todosPath = path.resolve(repoRoot,
  args[args.indexOf('--todos') + 1] || 'todos.json');

if (!fs.existsSync(todosPath)) {
  console.error(`ERROR: file not found: ${todosPath}`);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Load
// ---------------------------------------------------------------------------
let raw;
try {
  raw = fs.readFileSync(todosPath, 'utf8');
} catch (e) {
  console.error(`ERROR reading ${todosPath}: ${e.message}`);
  process.exit(1);
}

let todos;
try {
  todos = JSON.parse(raw);
} catch (e) {
  console.error(`ERROR parsing JSON in ${todosPath}: ${e.message}`);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Count
// ---------------------------------------------------------------------------
const byStatus   = {};
const byPriority = {};
const byCategory = {};
let   total      = 0;

for (const [catName, cat] of Object.entries(todos.categories || {})) {
  const tasks = Array.isArray(cat.tasks) ? cat.tasks : [];
  byCategory[catName] = tasks.length;
  total += tasks.length;
  for (const t of tasks) {
    byStatus[t.status]     = (byStatus[t.status]     || 0) + 1;
    byPriority[t.priority] = (byPriority[t.priority] || 0) + 1;
  }
}

// ---------------------------------------------------------------------------
// Update statistics block
// ---------------------------------------------------------------------------
todos.statistics = {
  total_tasks:  total,
  by_status:    byStatus,
  by_priority:  byPriority,
  by_category:  byCategory,
};

// ---------------------------------------------------------------------------
// Write back (preserve trailing newline if present)
// ---------------------------------------------------------------------------
const outText = JSON.stringify(todos, null, 2) + '\n';
const tmpPath = todosPath + '.tmp';
fs.writeFileSync(tmpPath, outText, 'utf8');
fs.renameSync(tmpPath, todosPath);

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------
console.log(`update_todos_stats.js: updated statistics in ${path.relative(repoRoot, todosPath)}`);
console.log(`  total tasks  : ${total}`);
for (const [k, v] of Object.entries(byStatus))   console.log(`  status  ${k.padEnd(12)}: ${v}`);
for (const [k, v] of Object.entries(byPriority)) console.log(`  priority ${k.padEnd(11)}: ${v}`);
