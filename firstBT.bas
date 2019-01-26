!DEBUG.ON
!DEBUG.ECHO.ON

!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!bt.close
BT.OPEN
ARRAY.LOAD type$[], "Connect to host", "Be the host"
title$ = "Select operation mode"
SELECT type, type$[], title$

IF type = 1
 BT.CONNECT
ENDIF

ln = 0
DO
 BT.STATUS s
 IF s = 1
  ln = ln + 1
  PRINT "Listening"; ln; "seconds..."
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

! *** Read/Write Loop ****
!RW_Loop:
! IF menu = 2 THEN BT.DISCONNECT
! Read status to insure
! that we remain connected.
! If disconnected, program
! reverts to listen mode.
! In that case, ask user
! what to do.
! BT.STATUS s
! IF s<> 3
!  PRINT "Connection lost"
!  GOTO new_connection
! ENDIF
! Read messages until
! the message queue is
! empty

!onConsoleTouch:
!xdoMenu = 1
!ConsoleTouch.Resume
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


GR.OPEN 255, 0, 0, 0
GR.ORIENTATION 1 %Force portrait
GR.SCREEN w, h
whalf = w/2
hhalf = h/2
w20 = w/20
w40 = w/40

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

ARRAY.LOAD ball[], -1, whalf,hhalf+hhalf/2,0,0,w20
ARRAY.LOAD you[] , -1, whalf,hhalf-hhalf/2,0,0,w20

ARRAY.LOAD flix[], -1, whalf,hhalf,        0,0,w40

ARRAY.LOAD touch[],-1,0,0
ARRAY.LOAD touch2[],-1,0,0

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
  flix[vx] = flix[vx]-difx/5
  flix[vy] = flix[vy]-dify/5
  ball[vx] = ball[vx]+difx/4
  ball[vy] = ball[vy]+dify/4
  !DoSmash(ball[], flix[], _)
  FN.RTN 80
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


RENDER:
GR.CLS
a = 255
fill = 1
!r = 255
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
IF flag2
 r = 0
ELSE
 r = 255
ENDIF

UpdatePhysics(ball[], _)
CheckWalls(ball[], walls[], _)

UpdatePhysics(you[], _)
CheckWalls(you[], walls[], _)

UpdatePhysics(flix[], _)

g = CheckBalls(ball[], flix[], _)
GR.COLOR a,r,g,b,fill
GR.CIRCLE flix[gn], flix[px], flix[py], flix[rad]
CheckWalls(flix[], walls[], _)

GR.RENDER

SENDSTR$ = STR$(INT(ball[px]/w*1000)) + " " + STR$(INT(ball[py]/h*1000))
BT.WRITE SENDSTR$

DO
 BT.READ.READY rr
 IF rr
  BT.READ.BYTES rmsg$
  youx = VAL(WORD$(rmsg$, 1))
  youy = VAL(WORD$(rmsg$, 2))
  you[px] = youx/1000*h
  you[py] = youy/1000*h
  !print rmsg$
 ENDIF
UNTIL rr = 0

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
