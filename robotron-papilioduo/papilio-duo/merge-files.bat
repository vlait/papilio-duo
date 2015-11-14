@echo off
rem bitmerge.exe does not automatically determine the blob offset so it is manually set 
rem i.e 53400:rom-blob.bin appends the rom-blob.bin at 0x53400
rem which is ok for lx9 but not necessarily for others, address is hardcoded in bootstrap.vhd
..\bitmerge-source\bitmerge.exe ..\build\papilio_duo_top.bit 53400:rom-blob.bin fpga.bit
echo .......................................................................
echo .                                                                     .
echo .                                                                     .
echo . "Merged bitfile in fpga.bit, remember to write to FLASH - not FPGA" .
echo .                                                                     .	
echo .                                                                     .
echo .......................................................................