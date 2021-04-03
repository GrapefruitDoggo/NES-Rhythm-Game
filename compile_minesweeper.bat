@del minesweeper.o
@del minesweeper.nes
@del minesweeper.map.txt
@del minesweeper.labels.txt
@del minesweeper.nes.ram.nl
@del minesweeper.nes.0.nl
@del minesweeper.nes.1.nl
@del minesweeper.nes.dbg
@echo.
@echo Compiling...
ca65 minesweeper.asm -g -o minesweeper.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
ld65 -o minesweeper.nes -C minesweeper.cfg minesweeper.o -m minesweeper.map.txt -Ln minesweeper.labels.txt --dbgfile minesweeper.nes.dbg
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Generating FCEUX debug symbols...
python minesweeper_fceux_symbols.py
@echo.
@echo Success!
@pause
@GOTO endbuild
:failure
@echo.
@echo Build error!
@pause
:endbuild
