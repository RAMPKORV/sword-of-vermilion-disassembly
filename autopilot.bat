@echo off
setlocal

:loop
echo.
echo ============================================================
echo  %date% %time% - Starting conjecture exploration...
echo ============================================================
echo.

opencode run "Execute todos.json, one task at a time. Mark your progress in the file as you go. 
Build the ROM often and verify bit perfect as you go - between each task this needs to be done.
If you discover more things to improve the disassembly as you go, append a task to todos.json with your new insight/idea.
In case todos.json happens to have no items left to do, do the most useful action given where the project stands."

echo.
echo  Finished iteration. Waiting 10 seconds...
echo.
timeout /t 10 /nobreak >nul

goto loop
