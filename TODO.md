# Games/mapper
Mappers 0-3 are implemented.  Following games have been tested
## Mostly working games
- Super Mario Bros
- Legend of Zelda (minor rendering issues)
- Metroid
- Tetris
- Castlevania
- Contra
- Megaman
- MLB
- Paperboy
## Non-playable games
- Pacman (freezes on load)
- California Games (major graphics issues)

# 6502 open issues:
- implement illegal opcodes

# PPU open issues:
- screen masking
- common artifacts on first scanline

# APU open issues:
- DMC implemented but not fully tested

# Audio
- HDMI audio not working

# System
- Resource optimization? target smaller device?
- Currently a few mappers are implemented in parallel with muxed logic, which isnt very scalable. Better approach: dynamically load each mapper via partial reconfiguration?
