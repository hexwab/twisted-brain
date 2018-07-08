10DEFFNO(A%,X%)=((USR&FFF4)AND&FF00)DIV256
20C%=FNO(0,1):IF C%<3 ORC%>6:PRINT"Sorry, BBC Master required!":END
30IF FNO(68,0)<>15:PRINT"Sorry, need sideways RAM in banks 4-7."'"(Set LK18 and LK19 west?)":END
40IFHIMEM<&7C00:MODE7
50PRINT'"BITSHIFTERS are about to twist"
60PRINT"your 6845 CRTC video chip..."
70PRINT'"(We also broke your emulator a bit)"
80PRINT'"If you experience any glitches"
90PRINT"please report them to us at:"
100PRINT'"https://bitshifters.github.io"
110PRINT'"0. EMULATOR (default)"
120PRINT"1. REAL HARDWARE"
130T=20
140PRINT'"Please choose within ";
150REPEAT
160PRINT;T;" seconds: ";
170K=INKEY(100)
180VDU8,8,8,8,8,8,8,8,8,8,8
190IF T>9:VDU8
200T=T-1
210UNTIL (K>=48 AND K<=49) OR T<0
220IF T<0 THEN K=48:T=0
230PRINT;T;" seconds: ";CHR$(K)
240!&80=&70:?&84=K-48:A%=6:X%=&80:Y%=0:CALL&FFF1
250PRINT'"TWISTING...";
260ON ERROR GOTO 280
270*OPT1
280ON ERROR OFF
290*FX234
300*RUN Brain
