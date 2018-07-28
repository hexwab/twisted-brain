#dd if=data/flash-mode2.bin bs=256 skip=13 count=54 of=data/flash-mode2.smaller.bin
bin\pucrunch.exe -d -c0 -l0x1000 data\dither.bin data\dither.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\hdither.bin data\hdither.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\hdither2.bin data\hdither2.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\shift2.bin data\shift.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\parallax1-mode1.bin data\parallax1.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\parallax2-mode1.bin data\parallax2.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\twist.bin data\twist.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\twist2.bin data\twist2.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\nova-mode1.bin data\nova.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\brain-mode2.bin data\brain.pu

bin\pucrunch.exe -d -c0 -l0x1000 data\logo-only-mode2.bin data\twisted-logo.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\brain-only-mode2.bin data\brain-only.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\twisted-brain-mode2.bin data\twisted-brain.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\smiley-mode2.bin data\smiley.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\flash-mode2.smaller.bin data\brain-flash.pu
bin\pucrunch.exe -d -c0 -l0x1000 data\brain-mask-mode2.bin data\brain-mask.pu

bin\pucrunch.exe -d -c0 -l0x1000 data\font_razor.bin data\font_razor.pu
