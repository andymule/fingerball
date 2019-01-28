!DEBUG.ON      % enables all debug calls
DEBUG.ECHO.ON  % only actually enabled if debug.on
!TODO flip game so current user is always on bottom of screen
!XXXXXXXXXXXX MENU UI XXXXXXXXXXXXXXXXXXXXXXXXX
!GW_COLOR$ = "#101010"
GW_SILENT_LOAD = 1
INCLUDE "GW.bas"
GW_LOAD_THEME ("native-droid-dark-red")
GW_DEFAULT_TRANSITIONS("page=fade, panel=fade, dialog_message=fade")
page = GW_NEW_PAGE()
GW_ADD_TITLEBAR (page, GW_ADD_BAR_TITLE$("FINGERBALL 20K"))
GW_START_CENTER(page)
GW_ADD_TEXT (page, "Ready your fingers... Ready your balls...")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_CENTER_PAGE_VER(page)
GW_ADD_BUTTON (page, "Host the server", "wifihost")
GW_ADD_BUTTON (page, "Connect to host", "wificlient")
!GW_ADD_BUTTON (page, "Bluetooth,..., "bluetooth")
GW_STOP_CENTER(page)
GW_RENDER(page)
DO
r$ = GW_WAIT_ACTION$()
until r$ = "BACK"
END

!XXXXXXXXXXXX START FUNCTION DEFS XXXXXXXXXXXXXXX
FN.DEF UpdatePhysics (b[])
 GOSUB MakeKeys %makes keys to treat arrays like a class
 b[vx] = b[vx]+b[vx]*b[ax]
 b[vy] = b[vy]+b[vy]*b[ay]
 b[px] = b[px] + b[vx]
 b[py] = b[py] + b[vy]
FN.END

FN.DEF CheckBalls (b1[], b2[])
 GOSUB MakeKeys
 difx = b1[px]-b2[px]
 dify = b1[py]-b2[py]
 dist = POW(difx,2)+POW(dify,2)
 dist = SQR(dist)
 IF dist < b1[rad]+b2[rad]
  ARRAY.LOAD vib[],1,3
  VIBRATE vib[], -1
  b2[vx] = b2[vx]-difx/5
  b2[vy] = b2[vy]-dify/5
  b1[vx] = b1[vx]+difx/5
  b1[vy] = b1[vy]+dify/5
 ENDIF
FN.END

FN.DEF CheckWalls (ball[], walls[])
 GOSUB MakeKeys
 ARRAY.LENGTH w, walls[]
 FOR x=1 TO w
  IF GR_COLLISION(ball[gn], walls[x])
   ARRAY.LOAD vib[],1,3
   VIBRATE vib[], -1
   SW.BEGIN x
    SW.CASE 1
     ball[vy] = ABS(ball[vy])
     SW.BREAK
    SW.CASE 2
     ball[vx] = -ABS(ball[vx])
     SW.BREAK
    SW.CASE 3
     ball[vy] = -ABS(ball[vy])
     SW.BREAK
    SW.CASE 4
     ball[vx] = ABS(ball[vx])
     SW.BREAK
   SW.END
  ENDIF
 NEXT x
FN.END

FN.DEF sNum$(num, scale)
 dataRes=2000
 FN.RTN STR$(INT(num/scale*dataRes))
FN.END

!XXXXXXXXX Main Menu and Start Network XXXXXXXXX
ARRAY.LOAD type$[],"WIFI: Connect to host", "WIFI: Be the host", "BLUETOOTH (slow/laggy): Connect to host", "BLUETOOTH (slow/laggy): Be the host", "Free Play"
SELECT conntype, type$[], "Select Mode"
GOSUB StartWifi
GOSUB StartBluetooth
IF MOD(conntype, 2) = 0 | conntype=5
 IsServer = 1
ELSE
 IsClient = 1
ENDIF
!XXXXXXXXXXXXXXXX Start Game Engine XXXXXXXXXXXXXXXXXX
GR.OPEN 255, 0, 0, 0,0,1
GR.SCREEN w, h
whalf = w/2
hhalf = h/2
h20 = h/20 
w20 = w/20
w40 = w/40

!XXXXXXXXXXXXXXXX GAME TWEAK VARS XXXXXXXXXXXXXXXZ
ballfrict = -0.03
flixfrict = -0.025
ballspeedlimit = h/120
dataRes = 2000 %also in function needz changed twice lol
bscore = INT(0)
tscore = INT(0)

GOSUB MakeKeys %makes keys to treat arrays like a class

mystart = hhalf-hhalf/2
ustart = hhalf+hhalf/2
IF isServer
 mystart = hhalf+hhalf/2
 ustart = hhalf-hhalf/2
ENDIF
ARRAY.LOAD ball[], -1, whalf,mystart,0,0,~
w20,ballfrict, ballfrict
ARRAY.LOAD you[] , -1, whalf,ustart,0,0,~
w20,ballfrict, ballfrict
ARRAY.LOAD flix[],   -1, whalf,hhalf,0,0,~
w40,flixfrict, flixfrict
ARRAY.LOAD touch[],-1,0,0
ARRAY.LOAD touch2[],-1,0,0
! gfxnums of goals
ARRAY.LOAD goals[],0,0
! gfxnums of borders
ARRAY.LOAD walls[],0,0,0,0

ARRAY.LOAD ttext[],0,w/2,h/4  %gfn, x, y
ARRAY.LOAD btext[],0,w/2,h-h/17
GR.TEXT.ALIGN 2
GR.TEXT.BOLD 1
GR.TEXT.SIZE h/4

RENDER:  %XXXXXXXXXX MAIN RENDER LOOP XXXXXXXX
GR.CLS
GOSUB blue
GR.CIRCLE ball[gn], ball[px], ball[py], ball[rad]
GOSUB red
GR.CIRCLE you[gn], you[px], you[py], you[rad]
GR.COLOR 255,255,255,255,1
GR.CIRCLE flix[gn], flix[px], flix[py], flix[rad]
GR.COLOR 255,255,255,255,1
! l t r b, bounce vector
GR.RECT walls[1], 0, 0, w, 10
GR.RECT walls[2], w-10, 0, w, h
GR.RECT walls[3], 0,h-10, w, h
GR.RECT walls[4], 0,0,10,h

GOSUB red
GR.RECT goals[1], whalf-w20, 0, whalf+w20, w40
GOSUB blue
GR.RECT goals[2], whalf-w20, h-w40, whalf+w20, h

GOSUB CheckTouch

UpdatePhysics(ball[])
CheckWalls(ball[], walls[])
UpdatePhysics(you[])
CheckWalls(you[], walls[])
CheckBalls(ball[], you[])
UpdatePhysics(flix[])
CheckBalls(ball[], flix[])
CheckWalls(flix[], walls[])
CheckBalls(flix[], you[])

tstr$=FORMAT$("%",tscore)
bstr$=FORMAT$("%",bscore)
GR.GET.TEXTBOUNDS tstr$,tl,tt,tr,tb
GR.GET.TEXTBOUNDS bstr$,bl,bt,br,bb
GR.COLOR 35,255,0,0,1
GR.TEXT.DRAW ttext[gn],ttext[px]-tl/2,ttext[py],tstr$
GR.COLOR 35,0,0,255,1
GR.TEXT.DRAW btext[gn],btext[px]-bl/2,btext[py],bstr$
GR.RENDER

!XXXXXXXXXXXXXX TRANSMIT GAME DATA XXXXXXXXXXXX
SENDSTR$ = sNum$(ball[px],w) + " " + sNum$(ball[py],h)~
+ " " + sNum$(ball[vx],1) + " " + sNum$(ball[vy],1)~
+ " " + sNum$(flix[px],w) + " " + sNum$(flix[py],h)~
+ " " + sNum$(flix[vx],1) + " " + sNum$(flix[vy],1)~
+ " " + STR$(tscore) + " " + STR$(bscore)
! store current flix in case we dont get an update
ARRAY.COPY flix[], yourflix[]
GOSUB HandleTCP
GOSUB HandleBluetooth
GOSUB SmoothFlix

! did someone score? only server checks
IF IsServer
 IF GR_COLLISION(flix[gn], goals[1])
  bscore += 1
  GOSUB ResetFlix
 ENDIF
 IF GR_COLLISION(flix[gn], goals[2])
  tscore += 1
  GOSUB ResetFlix
 ENDIF
ENDIF

GOTO render
!XXXXXXXXXXXXXXX END MAIN LOOP XXXXXXXXXXXXXXXX

MakeKeys:
gn = 1
px = 2
py = 3
vx = 4
vy = 5
rad= 6
ax = 7
ay = 8
RETURN

CheckTouch: %TODO circular speed limit
GR.TOUCH flag, touch[px], touch[py]
IF flag
 !TODO better controls, powerup shot
 ball[vx] = touch[px]-ball[px]
 ball[vy] = touch[py]-ball[py]
 totalv = ABS(ball[vx])+ABS(ball[vy])+0.00001
 xpercent = ABS(ball[vx]/totalv)
 ypercent = ABS(ball[vy]/totalv)
 IF totalv > ballspeedlimit
  ball[vx] = SGN(ball[vx])*ballspeedlimit*xpercent
  ball[vy] = SGN(ball[vy])*ballspeedlimit*ypercent
 ENDIF
ENDIF
!GR.TOUCH2 flag2, touch2[px], touch2[py]
RETURN

ResetFlix:
flix[px]=whalf
flix[py]=hhalf
flix[vx]=0
flix[vy]=0
ARRAY.COPY flix[], yourflix[]
RETURN 

ParseMessage: %restore and load network msg data
youx    = VAL(WORD$(rmsg$, 1))
youy    = VAL(WORD$(rmsg$, 2))
youvx   = VAL(WORD$(rmsg$, 3))
youvy   = VAL(WORD$(rmsg$, 4))
you[px] = youx/dataRes*w
you[py] = youy/dataRes*h
you[vx] = youvx/dataRes
you[vy] = youvy/dataRes

IF IsClient
 uflixx  = VAL(WORD$(rmsg$, 5))
 uflixy  = VAL(WORD$(rmsg$, 6))
 uflixvx = VAL(WORD$(rmsg$, 7))
 uflixvy = VAL(WORD$(rmsg$, 8))
 utscore = VAL(WORD$(rmsg$, 9))
 ubscore = VAL(WORD$(rmsg$, 10))
 flix[px]=uflixx/dataRes*w
 flix[py]=uflixy/dataRes*h
 flix[vx]=uflixvx/dataRes
 flix[vy]=uflixvy/dataRes
 IF utscore > tscore
  tscore = utscore
  GOSUB ResetFlix
 ENDIF
 IF ubscore > bscore
  bscore = ubscore
  GOSUB ResetFlix
 ENDIF
ENDIF
RETURN

SmoothFlix: 

%interps both players flix data
!flix[px] = (flix[px] + yourflix[px])/2
!flix[py] = (flix[py] + yourflix[py])/2
!IF ABS(flix[vx]) < ABS(yourflix[vx]) %if hit make sure it counts
! flix[vx] = yourflix[vx]
!ENDIF
!IF ABS(flix[vy]) < ABS(yourflix[vy])
! flix[vy] = yourflix[vy]
!ENDIF
RETURN

blue:
GR.COLOR 255,0,50,255,1
RETURN

red:
GR.COLOR 255,255,0,0,1
RETURN

HandleTCP:
IF conntype = 1
 SOCKET.CLIENT.WRITE.LINE sendstr$
 SOCKET.CLIENT.READ.READY readyflag
 WHILE readyflag
  SOCKET.CLIENT.READ.LINE rmsg$
  GOSUB ParseMessage
  SOCKET.CLIENT.READ.READY readyflag
 REPEAT 
ENDIF
IF conntype = 2
 SOCKET.SERVER.WRITE.LINE sendstr$
 SOCKET.SERVER.READ.READY readyflag
 WHILE readyflag
  SOCKET.SERVER.READ.LINE rmsg$
  GOSUB ParseMessage
  SOCKET.SERVER.READ.READY readyflag
 REPEAT
ENDIF
RETURN

HandleBluetooth:
IF conntype = 3 | conntype = 4 
 BT.WRITE SENDSTR$
 DO
  BT.READ.READY rr
  IF rr
   BT.READ.BYTES rmsg$
   GOSUB ParseMessage
  ENDIF
 UNTIL rr = 0
ENDIF
RETURN

StartWifi:
IF conntype=1
 INPUT "Enter Host IP:", hostip$
 SOCKET.CLIENT.CONNECT hostip$, 12345
 PRINT "CONNECTED!"
ENDIF

IF conntype = 2
 SOCKET.MYIP myip$
 PRINT "LAN IP: " + myip$
 !GRABURL mywanip$, "http://icanhazip.com"
 !print "WAN IP: " + mywanip$
 SOCKET.SERVER.CREATE 12345
 PRINT "waiting for connection...."
 SOCKET.SERVER.CONNECT 0
 DO
  SOCKET.SERVER.STATUS st
 UNTIL st=3
 SOCKET.SERVER.CLIENT.IP youip$
 PRINT "CONNECTED! to: " + youip$
 !maxclock = CLOCK() + 10000
 !do 
 ! socket.server.read.ready readyflag
 ! if CLOCK() > maxclock
 !  print "READ TIME OUT"
 !  end
 ! endif
 !until flag
 ! todo detect loss of connection
ENDIF
RETURN

StartBluetooth:
IF conntype = 3 | conntype = 4
 BT.OPEN
ENDIF
IF conntype = 3
 BT.CONNECT
ENDIF
IF conntype = 4 | conntype = 3
 ln = 0
 DO
  BT.STATUS s
  IF s = 1
   ln = ln + 1
   PRINT "Listening "; INT(ln); " seconds..."
  ELSEIF s = 2
   PRINT "Connecting"
  ELSEIF s = 3
   PRINT "Connected!!!"
  ELSE
   PRINT s
  ENDIF
  PAUSE 1000
 UNTIL s = 3
 BT.DEVICE.NAME device$
ENDIF

!todo make sure still open
! BT.STATUS s
! IF s<> 3
!  PRINT "Connection lost"
!  GOTO new_connection
! ENDIF
RETURN

ONERROR:
PRINT GETERROR$()
END
