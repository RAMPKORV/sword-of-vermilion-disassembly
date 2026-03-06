'use strict';
// tools/validate_todos.js
//
// Validates todos.json against tools/todos.schema.json (JSON Schema draft-07).
// Reports all structural errors: missing required fields, wrong types, invalid
// enum values, duplicate task IDs, and tasks with unknown category IDs.
//
// Usage:
//   node tools/validate_todos.js [--todos <path>] [--schema <path>]
//
// Exit 0 = valid, Exit 1 = validation errors found.
//
// Does NOT require any npm packages — uses a minimal built-in validator for
// the subset of JSON Schema draft-07 features used in todos.schema.json.

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------
const repoRoot = path.resolve(__dirname, '..');
const args     = process.argv.slice(2);

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 && args[i + 1] ? args[i + 1] : def;
}

const todosPath  = path.resolve(repoRoot, getArg('--todos',  'todos.json'));
const schemaPath = path.resolve(repoRoot, getArg('--schema', 'tools/todos.schema.json'));

// ---------------------------------------------------------------------------
// Load files
// ---------------------------------------------------------------------------
function loadJson(p) {
  if (!fs.existsSync(p)) {
    console.error(`ERROR: file not found: ${p}`);
    process.exit(1);
  }
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (e) {
    console.error(`ERROR: JSON parse error in ${p}: ${e.message}`);
    process.exit(1);
  }
}

const todos  = loadJson(todosPath);
const schema = loadJson(schemaPath);

// ---------------------------------------------------------------------------
// Minimal schema validator for the specific constructs used in todos.schema.json
// ---------------------------------------------------------------------------
const errors = [];

function err(path, msg) {
  errors.push(`  ${path}: ${msg}`);
}

function validateType(val, type, loc) {
  if (type === 'object'  && (typeof val !== 'object' || val === null || Array.isArray(val))) err(loc, `expected object, got ${typeof val}`);
  if (type === 'array'   && !Array.isArray(val))  err(loc, `expected array, got ${typeof val}`);
  if (type === 'string'  && typeof val !== 'string')  err(loc, `expected string, got ${typeof val}`);
  if (type === 'integer' && !Number.isInteger(val))   err(loc, `expected integer, got ${typeof val}`);
  if (type === 'boolean' && typeof val !== 'boolean') err(loc, `expected boolean, got ${typeof val}`);
}

function validateTask(task, loc) {
  // required fields
  const required = ['id', 'title', 'description', 'priority', 'effort', 'status'];
  for (const f of required) {
    if (!(f in task)) { err(loc, `missing required field "${f}"`); }
  }

  if (task.id !== undefined) {
    validateType(task.id, 'string', `${loc}.id`);
    if (typeof task.id === 'string' && !/^[A-Z]+-[0-9]+$/.test(task.id))
      err(`${loc}.id`, `"${task.id}" does not match pattern ^[A-Z]+-[0-9]+$`);
  }

  if (task.title !== undefined) {
    validateType(task.title, 'string', `${loc}.title`);
    if (typeof task.title === 'string' && task.title.length < 5)
      err(`${loc}.title`, 'minLength 5 not met');
  }

  if (task.description !== undefined) {
    validateType(task.description, 'string', `${loc}.description`);
    if (typeof task.description === 'string' && task.description.length < 10)
      err(`${loc}.description`, 'minLength 10 not met');
  }

  const VALID_PRIORITY = ['critical', 'high', 'medium', 'low'];
  if (task.priority !== undefined && !VALID_PRIORITY.includes(task.priority))
    err(`${loc}.priority`, `"${task.priority}" not in enum ${JSON.stringify(VALID_PRIORITY)}`);

  const VALID_EFFORT = ['small', 'medium', 'large', 'very_large'];
  if (task.effort !== undefined && !VALID_EFFORT.includes(task.effort))
    err(`${loc}.effort`, `"${task.effort}" not in enum ${JSON.stringify(VALID_EFFORT)}`);

  const VALID_STATUS = ['todo', 'in_progress', 'done', 'blocked', 'cancelled'];
  if (task.status !== undefined && !VALID_STATUS.includes(task.status))
    err(`${loc}.status`, `"${task.status}" not in enum ${JSON.stringify(VALID_STATUS)}`);
}

// ---------------------------------------------------------------------------
// Top-level structure
// ---------------------------------------------------------------------------
if (typeof todos !== 'object' || todos === null || Array.isArray(todos)) {
  err('todos.json', 'root must be an object');
} else {
  // Required top-level keys
  for (const k of ['schema_version', 'task_defaults', 'quality_gates', 'categories']) {
    if (!(k in todos)) err('todos.json', `missing required top-level key "${k}"`);
  }

  if ('schema_version' in todos) validateType(todos.schema_version, 'integer', 'schema_version');
  if ('categories' in todos)     validateType(todos.categories, 'object', 'categories');

  // ---------------------------------------------------------------------------
  // Validate each category and collect all task IDs for duplicate check
  // ---------------------------------------------------------------------------
  const allIds = new Map(); // id -> first location seen

  if (todos.categories && typeof todos.categories === 'object') {
    for (const [catName, cat] of Object.entries(todos.categories)) {
      const catLoc = `categories.${catName}`;
      if (typeof cat !== 'object' || cat === null || Array.isArray(cat)) {
        err(catLoc, 'category must be an object'); continue;
      }
      if (!('description' in cat)) err(catLoc, 'missing required field "description"');
      if (!('tasks' in cat))       err(catLoc, 'missing required field "tasks"');

      if (cat.tasks !== undefined) {
        if (!Array.isArray(cat.tasks)) {
          err(`${catLoc}.tasks`, 'expected array');
        } else {
          cat.tasks.forEach((task, i) => {
            const loc = `${catLoc}.tasks[${i}]`;
            if (typeof task !== 'object' || task === null || Array.isArray(task)) {
              err(loc, 'task must be an object'); return;
            }
            validateTask(task, loc);
            // Duplicate ID check
            if (task.id) {
              if (allIds.has(task.id)) {
                err(loc, `duplicate task id "${task.id}" (first seen at ${allIds.get(task.id)})`);
              } else {
                allIds.set(task.id, loc);
              }
            }
          });
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------
if (errors.length === 0) {
  const total = Object.values(todos.categories || {})
    .reduce((n, cat) => n + (Array.isArray(cat.tasks) ? cat.tasks.length : 0), 0);
  console.log(`validate_todos.js: todos.json is valid (${total} tasks checked)`);
  process.exit(0);
} else {
  console.error(`validate_todos.js: ${errors.length} validation error(s) found in todos.json:`);
  for (const e of errors) console.error(e);
  process.exit(1);
}
