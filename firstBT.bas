!DEBUG.ON
!DEBUG.ECHO.ON

!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
array.load vib[],1,10
vibrate vib[], -1
ARRAY.LOAD type$[], "WIFI: Connect to host", "WIFI: Be the host", "BLUETOOTH (slow/laggy): Connect to host", "BLUETOOTH (slow/laggy): Be the host", "Free Play"
title$ = "Select mode"
SELECT conntype, type$[], title$

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
  PRINT "Listening "; int(ln); " seconds..."
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
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

GR.OPEN 255, 0, 0, 0,0,1
!GR.ORIENTATION 1 %Force portrait
GR.SCREEN w, h
whalf = w/2
hhalf = h/2
h20 = h/20 
w20 = w/20
w40 = w/40
dataRes = 2000

gn = 1
px = 2
py = 3
vx = 4
vy = 5
rad= 6
ax = 7
ay = 8
BUNDLE.PUT _,"gn", gn
BUNDLE.PUT _,"px", px
BUNDLE.PUT _,"py", py
BUNDLE.PUT _,"vx", vx
BUNDLE.PUT _,"vy", vy
BUNDLE.PUT _,"rad", rad
BUNDLE.PUT _,"ax", ax
BUNDLE.PUT _,"ay", ay

mystart = hhalf+hhalf/2
ustart = hhalf-hhalf/2
if conntype %2
mystart = hhalf-hhalf/2
ustart = hhalf+hhalf/2
endif
ARRAY.LOAD ball[], -1, whalf,mystart,0,0,w20
ARRAY.LOAD you[] , -1, whalf,ustart,0,0,w20

!lerp/smooth previous positions w these
uOldx1 = whalf
uOldx2 = whalf
uOldy1 = ustart
uOldy2 = ustart

!real flix
ARRAY.LOAD flix[],   -1, whalf,hhalf,0,0,w40
!opponents last flix position, not rendered locally
ARRAY.LOAD yourflix[], -1, whalf,hhalf,0,0,w40
ARRAY.LOAD touch[],-1,0,0
ARRAY.LOAD touch2[],-1,0,0
! gfxnums of goals
ARRAY.LOAD goals[],0,0
! gfxnums of borders
ARRAY.LOAD walls[],0,0,0,0

FN.DEF diff (x[],y[], k$, _)
 BUNDLE.GET _,k$, key%
 FN.RTN x[key] - y[key]
FN.END

FN.DEF UpdatePhysics (b[], _)
 GOSUB LoadKeys
 b[px] = b[px] + b[vx]
 b[py] = b[py] + b[vy]
FN.END

FN.DEF CheckBalls (ball[], flix[], _)
 GOSUB LoadKeys
 difx = ball[px]-flix[px]
 dify = ball[py]-flix[py]
 dist = POW(difx,2)+POW(dify,2)
 dist = SQR(dist)
 IF dist < ball[rad]+flix[rad]
  array.load vib[],1,3
  vibrate vib[], -1
  flix[vx] = flix[vx]-difx/5
  flix[vy] = flix[vy]-dify/5
  ball[vx] = ball[vx]+difx/4
  ball[vy] = ball[vy]+dify/4
  !DoSmash(ball[], flix[], _)
  !FN.RTN 80
  FN.RTN 255
 ELSE
  FN.RTN 255
 ENDIF
FN.END

FN.DEF DoSmash (ball[], flix[], _)
 GOSUB LoadKeys
 b[px] = b[px] + b[vx]
 b[py] = b[py] + b[vy]
FN.END

FN.DEF CheckWalls (ball[], walls[], _)
 GOSUB LoadKeys
 ARRAY.LENGTH w, walls[]
 FOR x=1 TO w
  IF GR_COLLISION(ball[gn], walls[x])
   array.load vib[],1,3
   vibrate vib[], -1
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

fn.def sNum$(num, scale)
 fn.rtn STR$(INT(num/scale*dataRes))
fn.end

RENDER:
GR.CLS
a = 255
fill = 1
r = 255
g = 255
b = 255
GR.COLOR a,r,g,b,fill

GR.CIRCLE ball[gn], ball[px], ball[py], ball[rad]
GR.CIRCLE you[gn], you[px], you[py], you[rad]

GR.SET.STROKE 20

! l t r b, bounce vector
GR.RECT walls[1], 0, 0, w, 10
GR.RECT walls[2], w-10, 0, w, h
GR.RECT walls[3], 0,h-10, w, h
GR.RECT walls[4], 0,0,10,h
GR.RECT goals[1], whalf-w20, 0, whalf+w20, w40
GR.RECT goals[2], whalf-w20, h-w40, whalf+w20, h

GR.TOUCH flag, touch[px], touch[py]
IF flag
 ball[vx] = diff(touch[], ball[],"px", _)/25
 ball[vy] = diff(touch[], ball[],"py", _)/25
ELSE
 ball[vx] = ball[vx] - ball[vx]/25
 ball[vy] = ball[vy] - ball[vy]/25
ENDIF

flix[vx] = flix[vx] - flix[vx]/25
flix[vy] = flix[vy] - flix[vy]/25

GR.TOUCH2 flag2, touch2[px], touch2[py]
!IF flag2
! r = 0
!ELSE
! r = 255
!ENDIF

UpdatePhysics(ball[], _)
CheckWalls(ball[], walls[], _)

UpdatePhysics(you[], _)
CheckWalls(you[], walls[], _)

UpdatePhysics(flix[], _)

CheckBalls(ball[], flix[], _)
GR.COLOR a,r,g,b,fill
GR.CIRCLE flix[gn], flix[px], flix[py], flix[rad]
CheckWalls(flix[], walls[], _)

GR.RENDER

SENDSTR$ = sNum$(ball[px],w) + " " + sNum$(ball[py],h)~
+ " " + sNum$(ball[vx],1) + " " + sNum$(ball[vy],1)~
+ " " + sNum$(flix[px],w) + " " + sNum$(flix[py],h)~
+ " " + sNum$(flix[vx],1) + " " + sNum$(flix[vy],1)

! store current flix if we dont get an update
Array.copy flix[], yourflix[]
GoSub HandleTCP
GoSub HandleBluetooth
GoSub SmoothFlix
GOTO render

ONERROR:
PRINT GETERROR$()
END

LoadKeys:
BUNDLE.GET _,"gn", gn
BUNDLE.GET _,"px", px
BUNDLE.GET _,"py", py
BUNDLE.GET _,"vx", vx
BUNDLE.GET _,"vy", vy
BUNDLE.GET _,"rad", rad
RETURN

LoadAccel:
BUNDLE.GET _,"ax", ax 
BUNDLE.GET _,"ay", ay
RETURN

ParseMessage:
youx    = VAL(WORD$(rmsg$, 1))
youy    = VAL(WORD$(rmsg$, 2))
youvx   = VAL(WORD$(rmsg$, 3))
youvy   = VAL(WORD$(rmsg$, 4))
uflixx  = VAL(WORD$(rmsg$, 5))
uflixy  = VAL(WORD$(rmsg$, 6))
uflixvx = VAL(WORD$(rmsg$, 7))
uflixvy = VAL(WORD$(rmsg$, 8))
you[px] = youx/dataRes*w
you[py] = youy/dataRes*h
!you[vx] = youvx/dataRes
!you[vy] = youvy/dataRes
yourflix[px]=uflixx/dataRes*w
yourflix[py]=uflixy/dataRes*h
yourflix[vx]=uflixvx/dataRes
yourflix[vy]=uflixvy/dataRes
RETURN

LerpYou:
 you[px] = (you[px]+uOldx1+uOldx2)/3
 you[py] = (you[py]+uOldy1+uOldy2)/3
 uOldx2=uOldx1
 uOldx1=you[px]
 uOldy2=uOldy1
 uOldy1=you[py]
return

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
return

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
return

SmoothFlix:
flix[px] = (flix[px] + yourflix[px])/2
flix[py] = (flix[py] + yourflix[py])/2
if abs(flix[vx]) < abs(yourflix[vx])
 flix[vx] = yourflix[vx]
endif
if abs(flix[vy]) < abs(yourflix[vy])
 flix[vy] = yourflix[vy]
endif
return

