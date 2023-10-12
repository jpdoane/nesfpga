## NESFPGA

Lets build a Nintedo from scratch! Uses my [6502 core](https://github.com/jpdoane/6502).  Base HDMI code is borrowed from [here](https://github.com/hdl-util/hdmi), modified to upscale native NES 240p to 720p.

Current status:
- Core NES functionality is implemented
- [Mappers](https://nesdir.github.io/mapper0.html) 0-3 are currently implemented
- ROMS load from SD card
- Custom ROM loader utility (which is itself just a simple custom ROM). Hold Select+Start for >2sec to return to loader screen

See [here](TODO.md) for open issues