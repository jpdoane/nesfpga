## NESFPGA

Lets build a Nintedo from scratch! Uses my [6502 core](https://github.com/jpdoane/6502).  Base HDMI code is borrowed from [here](https://github.com/hdl-util/hdmi), modified to upscale native NES 240p to 720p.

Current status:
- Core NES functionality is implemented
- Mappers [0](https://nesdir.github.io/mapper0.html) and [1](https://nesdir.github.io/mapper1.html) are supported
- ROMS load from SD card
- Custom ROM loader utility, which is itself just a simple NES ROM.  (Hold Select+Start to return to menu)

A limited number of games have been tested and (mostly) work
- Super Mario Bros, 
- The Legend of Zelda (some minro rendering artifacts)
- Metroid
- Tetris

The only mapper 0-1 game known not to work yet is pacman (but no attempt to troubleshoot yet)

See [here](TODO.md) for open issues