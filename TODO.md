# Games/mapper
Mappers 0-3 are implemented.  Following games have been tested
- Super Mario Bros
- Legend of Zelda
- Metroid
- Tetris
- Pacman (freezes on load)
- California Games (major grpahics issues)
- Castlevania
- Contra
- Megaman
- MLB
- Paperboy

# 6502 open issues:
- implement illegal opcodes

# PPU open issues:
- screen masking 

# APU open issues:
- DMC implemented but not working well yet
- DMC/OMA DMA comflicts cause some sprite flickering and artifacts

# Audio
- add HDMI audio

# System
- resource optimization? target smaller device?
- load new mappers via partial reconfiguration?
