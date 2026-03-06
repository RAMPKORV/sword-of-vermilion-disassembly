@echo off
setlocal
cd /d "%~dp0tools\server"
if not exist node_modules (
  npm install --silent
)
node server.js
