# Games/mapper
Mappers 0-4 are implemented.  Following games have been tested and are functional
- Super Mario Bros
- Legend of Zelda
- Metroid
- Tetris
- Castlevania
- Contra
- Megaman
- MLB
- Pacman
- Paperboy
- California Games

# 6502 open issues:
- implement illegal opcodes

# PPU open issues:
- screen masking

# APU open issues:
- DMC implemented (and largely functional I think?) but not passing all unti tests

# Audio
- HDMI audio not working

# System
- Resource optimization? target smaller device?
- Currently a few mappers are implemented in parallel with muxed logic, which isnt very scalable. Better approach: dynamically load each mapper via partial reconfiguration?
