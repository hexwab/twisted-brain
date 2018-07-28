../../bin/beebasm.exe -D SAVE_FILES=1 -i just-rasters.asm
bin/pucrunch.exe -d -c0 -l0x1000 Bank0 bank0.pu
bin/pucrunch.exe -d -c0 -l0x1000 Bank1 bank1.pu
bin/pucrunch.exe -d -c0 -l0x1000 Bank2 bank2.pu
../../Bin/beebasm.exe -D SAVE_FILES=0 -i just-rasters.asm -di template.ssd -do twisted.ssd -v > compile.txt
