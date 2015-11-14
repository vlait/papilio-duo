
Early Williams (Robotron/Joust/Bubbles etc) hardware implementation for Papilio DUO + Computing Shield.
( http://www.gadgetfactory.net )

The original was Jared Boone's work with a real 6809 CPU paired with an fpga
which handled the other cpu and sound board functions.
( https://github.com/sharebrained/robotron-fpga )

Alex spent quite a lot of time fixing stuff for other games than Robotron  and adding a 6809 softcore 
to get things running on the Pipistrello board ( http://pipistrello.saanlima.com )
You can find the longish thread in the GadgetFactory forum
http://forum.gadgetfactory.net/index.php?/topic/1739-robotronic-adventures/

The DUO port is just cut/paste to place most of the rom code in the external SRAM 
and adding a bootloader to load them from flash as the S6LX9 does not have enough internal ram to 
hold the code and vram.
...and most likely breaking something along the way :)

Output is via the VGA and controls mapped to a PS/2 keyboard.
F1 coin
F5 p1 start
arrows p1 move
ijkl p1 fire
F7 auto up
F8 advance
(obviously mapped for Robotron, the top level file contains the keyboard mapping should you want to 
change them)

All rom images are appended to the bitfile on the flash memory and 
loaded to internal memory / SRAM at reset.
The "papilio-duo" directory contains example scripts to build the flash images.
build-rom-*** to concatenate the roms into one big file and 
merge* to build the final bitfile (fpga.bit) ready for burning.

The cmos ram is not loaded from flash so it will contain garbage as far as the game is concerned.
This causes the game to stop at "Factory Settings Initialized" after the powerup checks, 
press the reset button on the board to cause a warm restart to continue. (ESC/F6/F7 on keyboard might work too)

Things that should be fixed:
-wrong audio clock speed
-the blitter timing is not correct.
-the VGA timing apparently is not quite ok for some monitors. 
-an initialized cmos ram image should be in the rom blob so the games would boot up correctly 
-Defender uses an earlier version of the boardset, needs memory address mapper


If you have time fix some of the issues/add new functionality please do share :D

