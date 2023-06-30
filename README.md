# NES-Minesweeper

A simple minesweeper game, coded in 6502 for the Nintendo Entertainment System, and assembled using the ca65 assembler.  
Big thanks to BattleLineGames for their [NES Starter Kit](https://github.com/battlelinegames/nes-starter-kit), which I used as a template for this project!

## Description
If you know minesweeper, you know this game!  
Get ready for an action packed puzzle experience, dodging and weaving through a maze of mines! Use the cursor to dig up tiles, and flag any mines you find.  
Flag all the mines to win, but be careful - if you unearth into a mine, you will explode!  



## Controls
- D-Pad: Directional movement of the cursor  
- A Button: Clear tile  
- B Button: Flag tile  
- Start: Start game, reset after loss/win  



## Building
#### Linux
On Linux systems, simply run the build.sh script in terminal in the file that it's located.  
`(.../NES-Minesweeper/build/scripts)`

---

#### Other
On other systems (or if you don't want to run a script from an unknown third party), either mimicking the commands in the build.sh shell script in your system's terminal or following the simplified version below should work:
- In terminal, navigate to the `NES-Minesweeper` folder
- Run the assembler on the code by entering `ca65 src/main.asm -o build/main.o`
- Run the linker on the assembled file by typing `ld65 -o build/NES-Mines.nes -C src/linker.cfg build/main.o`



## Notes
This build is, in its current and likely final state, almost a full game, albeit a somewhat buggy one. While I've ironed out most of the bugs, so that 90% of the time you'll have a playable experience, you might have to reset a couple of times if a flag randomly disappears or the colour palette screws up.  

---

#### Intention
My intention for this project is mostly as a learning exercise for myself. I wanted to learn an assembly language, and I think the NES is a pretty cool system with a surprising amount of potential, so I wanted to make a cool original game on it. When I began researching, however, I realised how much I still had to learn, so I decided it was worth it to make a simple clone game to build my skills. The culmination of that effort is the game you see before you.
####
I'm not sure exactly what I want to make for my next NES project (likely something rhythm-based, or some kind of bullet hell or roguelike), but I do know I'll have a lot of fun making it!
####
A secondary intention for this project is using as a finished project on my portfolio, as I have vanishingly few of those to my name (at time of writing). If you're here from [my website](https://www.smallcode.dev), welcome! I hope you like what you see!

---

#### Flashing bug
There's an annoying bug in the game where a few actions - specifically, revealing a large number of tiles and placing flags when there are either a lot already on the field, or the counter for said flags is displaying a high number on any of the digits.  
####
I have an idea as to what causes this - something to do with taking too long to do certain tasks, and messing up the NES' render for a frame. The only solution I can find is to go through and optimise my code - if this were a project I cared about, I would bite the bullet and write better code, but as this was more of an experiment than a "real" project, I don't intend on spending my time doing so. If anyone, for whatever reason, has some dying wish to fix it, be my guest to raise an issue proposing a solution or simply fork and commit your own code for review. I'll keep an eye out for any updates