10 MODE 2
15 ?&FE34 = ?&FE34 AND &FB
20 *LOAD BRAIN 3000
30 ?&FE34 = ?&FE34 OR &4
50 *LOAD FLASH 3000
60 FOR A%=&3000 TO &7FFF
70 ?&FE34 = ?&FE34 OR &4
80 B% = ?A%
90 ?&FE34 = ?&FE34 AND &FB
95 C% = ?A%
100 IF B%<>&C0 AND B%=(C% OR &C0) THEN ?A% = B%
120 NEXT
130 *SAVE TEST 3000+5000

