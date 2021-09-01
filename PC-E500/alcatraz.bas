' Escape from Alcatraz for the PC-E500
' By Robert A. van Engelen
'
' RUN to start
' GOTO *C to continue after BRK

' VARIABLES
'  P              prisoner position 0 to 10
'  G(0),G(1),G(2) guard positions 0 to 10
'  M              last move 0 to 29
'  S              board score, a unique number between 0 and 1319
'  W              number of player wins
'  E              number of prisoner escapes
'  A$(5)*8        animation graphics for Prisoner (first 4) and Guards (last 2)
'  P(10),Q(10)    pixel coordinates for the 11 board positions to draw
'  D$(10)*6       graphics for digits and ':'
'  C$(10)*8       room connections
'  M$(1319)*1     prisoner's memory (1320 addresses of one byte)
'  R$(29)*1       rooms visited by prisoner up to move M
'  S(29)          board scores when rooms were visited by prisoner up to move M
'  V(7)           neighboring rooms to visit

10 CLEAR: CLS: WAIT 0: RANDOMIZE: RESTORE: GOSUB 900
20 *C: GOSUB 700: IF RND 2=1 GOSUB 300
30 GOSUB 200: GOSUB 300: IF P>0 IF M<30 GOTO 30
40 IF P=0 OR M=30 LOCATE 19,0: PRINT "I win": E=E+1
50 IF M=30 LOCATE 19,1: PRINT "TIMED": LOCATE 19,2: PRINT "OUT"
60 WAIT 200: GPRINT: GOTO 20

' animate while waiting for a key press, updates animation counters A and N, return key K value (ASCII '0' to ':')
100 X=P(P)+6,Y=Q(P)+7
110 GCURSOR (X,Y): GPRINT A$(A AND 3)
120 GCURSOR (P(G(N))+6,Q(G(N))+7): GPRINT A$(4+(A AND 1)): A=A+.1,N=N+.1: IF N=3 LET N=0
130 K$=INKEY$: IF K$="" GOTO 110
140 K=ASC K$: IF K<48 OR K>58 LET K=58
150 IF ASC INKEY$=K GOTO 150
160 RETURN

' move guard, determine F=from room (0 to 10), T=to room (0 to 10), K=key press, H=guard moved (0,1,2)
200 LOCATE 19,1: PRINT "move": LOCATE 19,2: PRINT "guard": LOCATE 19,3: PRINT "?    "
210 GOSUB 100: F=K-48,H=-(G(0)=F)+2*-(G(1)=F)+3*-(G(2)=F)-1: IF H<0 BEEP 1: GOTO 210
220 LOCATE 19,3: PRINT CHR$ K;"->?"
230 GOSUB 100: T=K-48: IF T=P OR T=G(0) OR T=G(1) OR T=G(2) OR (F<10 AND P(T)<P(F)) BEEP 1: GOTO 230
240 FOR I=1 TO LEN C$(F)
250 IF K=ASC MID$(C$(F),I,1) LET I=8: NEXT I: GOTO 270
260 NEXT I: GOTO 230
270 LOCATE 22,3: PRINT CHR$ K: X=P(F),Y=Q(F),G(H)=T: LINE (X+6,Y+1)-(X+9,Y+6),R,BF
280 GCURSOR (P(T)+6,Q(T)+7): GPRINT A$(4)
290 RETURN

' move prisoner from room P to room Q at move M, where Q is the best room
' compute V(0..F-1)=possible moves to connected rooms, F=number of moves possible
300 F=0
310 FOR I=1 TO LEN C$(P)
320 J=ASC MID$(C$(P),I,1)-48
330 IF J<>P IF J<>G(0) IF J<>G(1) IF J<>G(2) LET V(F)=J,F=F+1
340 NEXT I
350 LOCATE 19,3: PRINT L$: LOCATE 19,0: PRINT L$: LOCATE 19,1: PRINT L$: LOCATE 19,2: PRINT L$
' the prisoner can still move to another room when F>0 but not if F=0 (no freedom)
360 IF F GOTO 500
370 LOCATE 19,0: PRINT "JAIL": LOCATE 19,1: PRINT "TIME": LOCATE 20,2: PRINT "you": LOCATE 20,3: PRINT "win": W=W+1,P=-1
' prisoner cannot move (F=0 no freedom), learn from past mistakes
380 FOR I=M-1 TO 0 STEP -1
' R$(0..M-1)=room choice made at moves 0 to M-1, S=memorized(0..M-1) board position score 0..1319,M$()=memory,B=bitmask to clear
390 S=S(I)
' set memory M$() bit to 1 to mark off the room choice
400 B=2^ASC R$(I) OR ASC M$(S),M$(S)=CHR$ B
' exit loop if a move is still possible from room I, otherwise B=255 and no move is possible so continue marking off moves down the history
410 IF B<255 LET I=0
420 NEXT I
430 RETURN
'
' compute board position score S, 0<=S<1320=NCR(11,3)*8, loop I=0 to 10 where J=piece count
500 S=0,J=0
510 FOR I=0 TO 10
' if room of prisoner, then update S=S+330*J and continue loop
520 IF I=P LET S=S+330*J,J=J+1: GOTO 570
' if room of a guard, then continue loop
530 IF I=G(0) OR I=G(1) OR I=G(2) LET J=J+1: GOTO 570
560 S=S+NCR(10-I,3-J)
' if all pieces visited, then exit loop, else continue
570 IF J=4 LET I=10
580 NEXT I

' set unused bits in memory M$(S), memory(S) |= 0xff<<freedom, B=bitmask, M$()=memory, F=freedom
600 B=(ASC M$(S) OR 255*2^F) AND 255,M$(S)=CHR$ B
' first two moves are random
610 J=0: IF M<2 LET J=RND F-1: GOTO 650
' find non-trapping move J using B=bitmask
620 IF B AND 1 LET J=J+1,B=B/2: GOTO 620
' if J=8 then prisoner will be trapped, make a random move J=random(0..freedom-1) to room V(J)
630 IF J=8 LOCATE 19,0: PRINT "oh no": LET J=RND F-1: GOTO 650
' prisoner avoided a trap
640 IF J LOCATE 19,0: PRINT "ha ha"
' move to room V(J),record board score S and Jth room choice made for move M
650 Q=V(J),S(M)=S,R$(M)=CHR$ J,M=M+1
' erase prisoner in room P and move him to room Q
660 X=P(P),Y=Q(P): LINE (X+6,Y+1)-(X+9,Y+6),R,BF
670 P=Q,X=P(P): IF X<=P(G(0)) IF X<=P(G(1)) IF X<=P(G(2)) LET P=0
680 GCURSOR (P(P)+6,Q(P)+7): GPRINT A$(0)
690 RETURN

' build game board and place guards and prisoner on the board
' place guards in rooms 0,1,7 prisoner in room 10, A=animation counter, N=animation counter, M=moves
700 CLS: WAIT 0: G(0)=0,G(1)=1,G(2)=7,P=10,A=0,N=0,M=0
710 FOR I=0 TO 10
720 X=P(I),Y=Q(I)
' room with number
730 GCURSOR (X+1,Y+7): GPRINT D$(I): LINE (X,Y+1)-(X+4,Y+7),B: LINE (X+4,Y)-(X+11,Y+7),B
' stairs down left
740 IF I=5 OR I=7 OR I=9 OR I=10 LINE (X-2,Y+9)-(X-11,Y+18): LINE (X-3,Y+9)-(X-12,Y+18),&AAAA
' elevator down
750 IF I>3 IF I<10 IF Y<48 LINE (X+1,Y+8)-(X+3,Y+12),BF
' stairs down right
760 IF I=0 OR I=5 OR I=7 OR I=9 LINE (X+13,Y+9)-(X+22,Y+18): LINE (X+14,Y+9)-(X+23,Y+18),&AAAA
' floor
770 IF I<>3 IF I<9 LINE (X+13,Y+7)-(X+22,Y+7)
780 NEXT I
' display number of escapes
790 GCURSOR (0,7): X=INT(E/10): GPRINT A$(0);&81;&FE;D$(X);&FE;D$(E-10*X);&FE
' display number of wins
800 GCURSOR (89,7): X=INT(W/10): GPRINT &FE;D$(10);&FE;&81;A$(1);&FE;D$(X);&FE;D$(W-10*X);&FE
810 RETURN

' P()=room x-positions, Q()=room y-positions, D$()=digit pixels, C$()=room connections,
' A$()=animation pixels, G()=guard rooms, M$()=1320 memory cells, R$()=rooms visited, S()=board scores visited, V()=temp viable rooms
900 DIM P(10),Q(10),D$(10)*6,C$(10)*8,A$(5)*8
910 FOR I=0 TO 10: READ P(I),Q(I),D$(I),C$(I): LOCATE I,0: PRINT " * Alcatraz *": NEXT I
920 FOR I=0 TO 5: READ A$(I): NEXT I
930 PRINT "Don't let the prisoner": PRINT "escape"
940 GCURSOR (140,15): GPRINT &FE;D$(10);&FF;A$(0): GCURSOR (46,23): GPRINT A$(4);A$(3)
950 DIM G(2),M$(1319)*1,R$(29)*1,S(29),V(7): E=0,W=0,L$="     "
960 WAIT 200: GPRINT
970 RETURN

980 DATA 0,12,"C6BAC6","417"
981 DATA 24,24,"B682BE","0452"
982 DATA 48,24,"B69AA6","153"
983 DATA 72,24,"BAAAD2","256:"
984 DATA 24,12,"E6EE82","0175"
985 DATA 48,12,"A2AADA","41728396"
986 DATA 72,12,"C6AADE","539:"
987 DATA 24,0,"9AEAF2","0458"
988 DATA 48,0,"D6AAD6","759"
989 DATA 72,0,"F6AAC6","856:"
990 DATA 96,12,"AAFEAA","639"

' prisoner (4) and guard (2) animations
991 DATA "C9A9FD89","E99DE981","89FDA9C9","81E99DE9","F99DE985","99FD89BD"

' ####
' 
'   #
' ####
'   #
'  ##
' # #
' ####
' 
'  #
' ###
'  #
' # #
' # #
' ####
' 
'  #
' ####
'  #
'  ## 
'  # # 
' ####
' 
'   #
'  ###
'   #
'  # #
'  # # 
' ####
' 
'  # #
' ###
' ##
' # #
' # # 
' ####
' 
'  # #
' ####
' ## #
'  # #
'  #  
' ####
