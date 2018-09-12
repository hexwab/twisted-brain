beebasm -D SAVE_FILES=1 -i just-rasters.asm || exit 1
#pucrunch -d -c0 -l0x1000 Hazel hazel.pu
#pucrunch -d -c0 -l0x1000 Music music.pu
#pucrunch -d -c0 -l0x1000 Bank2 bank2.pu
#pucrunch -d -c0 -l0x1000 Bank1 bank1.pu
#pucrunch -d -c0 -l0x1000 Bank0 bank0.pu
wine bin/pucrunch.exe -d -c0 -l0x1000 Main main.pu || exit 1
wine bin/pucrunch.exe -d -c0 -l0x1000 Bank0 bank0.pu || exit 1
wine bin/pucrunch.exe -d -c0 -l0x1000 Bank1 bank1.pu || exit 1
wine bin/pucrunch.exe -d -c0 -l0x1000 Bank2 bank2.pu || exit 1
#pucrunch -u bank0.pu | dd bs=2 skip=1 2>/dev/null | cmp - Bank0 || exit 1
#pucrunch -u bank1.pu | dd bs=2 skip=1 2>/dev/null | cmp - Bank1 || exit 1
#pucrunch -u bank2.pu | dd bs=2 skip=1 2>/dev/null | cmp - Bank2 || exit 1
beebasm -D SAVE_FILES=0 -i just-rasters.asm -di template.ssd -do twisted.ssd -v > compile.txt || exit 1
echo all OK
