# CPU open issues:
- ST IDY,Y take 5 cycles vs 6
- clean up state machines

# PPU open issues:
- screen masking 
- not sure vblank timing is 100% correct...

# games/mapper status
- mapper 0, SMB: mostly works (w/o sound).
- mapper 1, zelda: in progess, doesnt work yet
## SMB
- Some minor sprite flicker/studder issues
- elevators scanline 1 artifact


# audio
- Not stared other than basic pwm tone
- HDMI audio

# system
- sd card for game load/save
- PS tools, e.g. menu?
- debug sidebar? (hmdi?)
- resource optimization? target smaller device?

# environment
- better work flow for managing mappers/games