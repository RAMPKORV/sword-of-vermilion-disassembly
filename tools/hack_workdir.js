'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const TEMP_ROOT = path.join(ROOT, '..', 'vermilion-hack-work');

function shouldCopy(relPath) {
  if (!relPath) return true;
  const parts = relPath.split(path.sep);
  if (parts[0] === '.git') return false;
  if (parts[0] === 'tools' && parts[1] === 'tmp') return false;
  if (parts[0] === 'tools' && parts[1] === 'server' && parts[2] === 'node_modules') return false;
  if (relPath === 'out.bin' || relPath === 'vermilion.lst' || relPath === 'nul') return false;
  return true;
}

function createWorkspace(label) {
  const id = `${label}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
  const workspace = path.join(TEMP_ROOT, id);
  fs.mkdirSync(TEMP_ROOT, { recursive: true });
  fs.cpSync(ROOT, workspace, {
    recursive: true,
    filter(src) {
      const rel = path.relative(ROOT, src);
      return shouldCopy(rel);
    },
  });
  return workspace;
}

function cleanupWorkspace(workspace) {
  fs.rmSync(workspace, { recursive: true, force: true });
}

function writeWorkspaceFile(workspace, relativePath, contents) {
  const target = path.join(workspace, relativePath);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, contents, 'utf8');
}

function copyOutBin(workspace, outputName = 'out.bin') {
  fs.copyFileSync(path.join(workspace, 'out.bin'), path.join(ROOT, outputName));
}

function runInWorkspace(workspace, command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: workspace,
    env: { ...process.env, ...options.env },
    stdio: options.stdio || 'inherit',
    encoding: options.encoding || 'utf8',
    shell: options.shell || false,
    windowsHide: true,
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    const error = new Error(`${command} exited with status ${result.status}`);
    error.result = result;
    throw error;
  }

  return result;
}

module.exports = {
  ROOT,
  cleanupWorkspace,
  copyOutBin,
  createWorkspace,
  runInWorkspace,
  writeWorkspaceFile,
};
