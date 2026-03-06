'use strict';

const { spawn } = require('child_process');
const crypto = require('crypto');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..', '..');

function makeTaskId() {
  return crypto.randomBytes(8).toString('hex');
}

function runCommand(options) {
  const {
    command,
    args = [],
    cwd = PROJECT_ROOT,
    env = {},
    timeout = 120000,
    shell = false,
    input = null,
    taskId = makeTaskId(),
    onStdout = null,
    onStderr = null,
    onExit = null,
  } = options;

  return new Promise((resolve, reject) => {
    const startedAt = Date.now();
    const child = spawn(command, args, {
      cwd,
      env: { ...process.env, ...env },
      shell,
      windowsHide: true,
    });

    let stdout = '';
    let stderr = '';
    let settled = false;

    const finish = (result) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (onExit) onExit(result);
      resolve(result);
    };

    const fail = (error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      reject(error);
    };

    const timer = timeout > 0
      ? setTimeout(() => {
          try {
            child.kill();
          } catch (error) {
            // ignore kill errors on timeout cleanup
          }
          finish({
            taskId,
            command,
            args,
            cwd,
            stdout,
            stderr: `${stderr}${stderr ? '\n' : ''}Timed out after ${timeout}ms`,
            exitCode: null,
            signal: 'SIGTERM',
            duration: Date.now() - startedAt,
            timedOut: true,
            ok: false,
          });
        }, timeout)
      : null;

    child.stdout.on('data', (chunk) => {
      const text = chunk.toString();
      stdout += text;
      if (onStdout) onStdout(text, taskId);
    });

    child.stderr.on('data', (chunk) => {
      const text = chunk.toString();
      stderr += text;
      if (onStderr) onStderr(text, taskId);
    });

    child.on('error', (error) => {
      fail(error);
    });

    child.on('close', (exitCode, signal) => {
      finish({
        taskId,
        command,
        args,
        cwd,
        stdout,
        stderr,
        exitCode,
        signal,
        duration: Date.now() - startedAt,
        timedOut: false,
        ok: exitCode === 0,
      });
    });

    if (input !== null && input !== undefined) {
      child.stdin.write(input);
      child.stdin.end();
    }
  });
}

function runNodeScript(scriptPath, scriptArgs = [], options = {}) {
  return runCommand({
    command: process.execPath,
    args: [scriptPath, ...scriptArgs],
    ...options,
  });
}

module.exports = {
  PROJECT_ROOT,
  makeTaskId,
  runCommand,
  runNodeScript,
};
