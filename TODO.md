# 6502 open issues:
- clean up state machines
- illegal opcodes

# PPU open issues:
- screen masking 
- not sure vblank timing is 100% correct...

# Games/mapper status
## SMB
- Some minor sprite flicker/studder issues
- elevators scanline 1 artifact
## Zelda
- vertical scrolling is not smooth
- graphic artifacts on screen edge
- can get stuck on a screen, all exits return to same screen
## Pacman
- Freeze on start
## Support more mappers...

# Audio
- Noise channel
- DMC channel
- HDMI audio

# System
- resource optimization? target smaller device?
- load new mappers via partial reconfiguration?
