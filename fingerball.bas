DEBUG.ON      % enables all debug calls
DEBUG.ECHO.ON  % only actually enabled if debug.on
!TODO flip game so current user is always on bottom of screen
!XXXXXXXXXXXX MENU UI XXXXXXXXXXXXXXXXXXXXXXXXX
GW_COLOR$ = "#000000"
GW_SILENT_LOAD = 1
INCLUDE "GW.bas"
GW_LOAD_THEME ("native-droid-dark-red")
GW_DEFAULT_TRANSITIONS("page=fade, panel=overlay, dialog_message=fade")
page = GW_NEW_PAGE()
GW_START_CENTER(page)
titlebar = GW_ADD_TITLEBAR (page, GW_ADD_BAR_TITLE$("FINGERBALL"))
GW_CENTER_PAGE_VER(page)
GW_ADD_TEXT (page, "Ready your fingers... Ready your balls...")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_TEXT (page, "")
GW_ADD_BUTTON (page, "Host the server", "wifihost")
GW_ADD_BUTTON (page, "Connect to host", "wificlient")
GW_ADD_BUTTON (page, "Freeplay", "freeplay")
GW_STOP_CENTER(page)
ARRAY.LOAD dlgb$[], "ABORT>BACK"
dialog = GW_ADD_DIALOG_MESSAGE (page,"Hosting server @ IP", "",dlgb$[])
GW_RENDER(page)
WaitAction:
IsServer=0
IsClient=0
IsFreePlay=0
r$ = GW_WAIT_ACTION$()
IF r$="wifihost"
 IsServer = 1
ENDIF
IF r$="wificlient"
 IsClient = 1
ENDIF 
IF r$="freeplay"
 IsFreeplay = 1
ENDIF
IF r$="BACK"
 END
ENDIF

IF IsClient
 INPUT "Enter Host IP:", hostip$
 SOCKET.CLIENT.CONNECT hostip$, 12345
ENDIF

IF IsServer
 SOCKET.MYIP myip$
 SOCKET.SERVER.CREATE 12345
 GW_MODIFY (dialog, "text", myip$)
 GW_SHOW_dialog(dialog)
 SOCKET.SERVER.CONNECT 0
 DO
  SOCKET.SERVER.STATUS st
  IF GW_ACTION$() = "BACK"
   SOCKET.SERVER.CLOSE
   GW_close_dialog(dialog)
   GOTO WaitAction
  ENDIF
 UNTIL st=3
 SOCKET.SERVER.CLIENT.IP youip$
ENDIF

GOSUB FnInit %declares all our util functions

!XXXXXXXXXXXXXXXX Start Game Engine Vars XXXXXXXXXX
GR.OPEN 255, 0, 0, 0,0,1
GR.SCREEN w, h
GR.SET.ANTIALIAS 1
whalf = w/2
hhalf = h/2
h20 = h/20 
w20 = w/20
w40 = w/40
di_height = 2560
di_width = 1440 
GR.SCALE w/di_width, h/di_height
GR.SET.STROKE w40/2
!todo scale touch? scale stroke?

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
ARRAY.LOAD ball[], -1, whalf,mystart,0,0,w20,ballfrict, ballfrict
ARRAY.LOAD you[] , -1, whalf,ustart,0,0,w20,ballfrict, ballfrict
ARRAY.LOAD flix[], -1, whalf,hhalf,0,0,w40,flixfrict, flixfrict
ARRAY.LOAD touch[],-1,0,0
ARRAY.LOAD goals[],0,0
ARRAY.LOAD walls[],0,0,0,0
ARRAY.LOAD ttext[],0,w/2,h/4  %gfn, x, y
ARRAY.LOAD btext[],0,w/2,h-h/17
GR.TEXT.ALIGN 2
GR.TEXT.BOLD 1
GR.TEXT.SIZE h/4

HTML.CLOSE %Close GW Stuff as late as possible

RENDER:  %XXXXXXXXXX MAIN RENDER LOOP XXXXXXXXXXXXXXXXXXXXX
GR.CLS
GOSUB SceneDraw
GR.RENDER
GOSUB CheckTouch

UpdatePhysics(ball[])
CheckWalls(ball[], walls[], w, h)
UpdatePhysics(you[])
CheckWalls(you[], walls[], w, h)
CheckBalls(ball[], you[])
UpdatePhysics(flix[])
CheckWalls(flix[], walls[], w, h)
CheckBalls(ball[], flix[])
CheckBalls(flix[], you[])

!XXXXXXXXXXXXXX TRANSMIT GAME DATA XXXXXXXXXXXX
GoSub BuildSendString
! store current flix in case we dont get an update
ARRAY.COPY flix[], yourflix[]
GOSUB HandleTCP

! did someone score? only server checks
IF IsServer | IsFreeplay
 IF GR_COLLISION(flix[gn], goals[1])
  bscore += 1
  bscored = 0
  tscored = 1
  GOSUB GoalRender
  GOSUB ResetFlix
 ENDIF
 IF GR_COLLISION(flix[gn], goals[2])
  tscore += 1
  bscored = 1
  tscored = 0
  GOSUB goalRender
  GOSUB ResetFlix
 ENDIF
ENDIF

GOTO render
!XXXXXXXXXXXXXXX END MAIN LOOP XXXXXXXXXXXXXXXXXXXXXXXXXX

SceneDraw:
GOSUB blue
GR.CIRCLE ball[gn], ball[px], ball[py], ball[rad]
GOSUB red
GR.CIRCLE you[gn], you[px], you[py], you[rad]
GR.COLOR 255,255,255,255,1
GR.CIRCLE flix[gn], flix[px], flix[py], flix[rad]
GR.COLOR 255,255,255,255,1
! l t r b, bounce vector
!WallWidth = 10 %Made in KEYS for now, TODO fix globals?
GR.RECT walls[1], 0, 0, w, WallWidth
GR.RECT walls[2], w-WallWidth, 0, w, h
GR.RECT walls[3], 0,h-WallWidth, w, h
GR.RECT walls[4], 0,0,WallWidth,h
GOSUB red
GR.RECT goals[1], whalf-w20, 0, whalf+w20, w40
GOSUB blue
GR.RECT goals[2], whalf-w20, h-w40, whalf+w20, h
tstr$=FORMAT$("%",tscore)
bstr$=FORMAT$("%",bscore)
GR.GET.TEXTBOUNDS tstr$,tl,tt,tr,tb
GR.GET.TEXTBOUNDS bstr$,bl,bt,br,bb
temp = alpha
alpha = 35
gosub redalpha
GR.TEXT.DRAW ttext[gn],ttext[px]-tl/2,ttext[py],tstr$
gosub bluealpha
GR.TEXT.DRAW btext[gn],btext[px]-bl/2,btext[py],bstr$
alpha = temp
RETURN

GoalRender:
rlayer=0
pnum=20*4 
LIST.CREATE N, plist
FOR pindex=1 TO pnum
 LIST.ADD plist, whalf
 LIST.ADD plist, 0
 LIST.ADD plist, (RND()-0.5)*100
 LIST.ADD plist, (RND()-0.5)*5+30
NEXT pindex
FOR alpha = 255 TO 0 STEP -10
 GOSUB whitealpha
 FOR pindex=1 TO pnum STEP 4
  LIST.GET plist, pindex, plx
  LIST.GET plist, pindex+1, ply
  LIST.GET plist, pindex+2, plvx
  LIST.GET plist, pindex+3, plvy
  plx+= plvx+(RND()-0.5)*30
  ply+= plvy
  LIST.REPLACE plist, pindex, plx
  LIST.REPLACE plist, pindex+1, ply
  GR.CIRCLE trash, plx, ply, w20
  !GR.POINT garbage, plx, ply
 NEXT pindex
 temp = alpha
 alpha = 10
 GOSUB redalpha
 rlayer+=h/40
 ! l t r b, bounce vector
 GR.RECT walls[1], 0, 0, w, rlayer
 alpha = temp
 GOSUB SceneDraw
 GR.RENDER
NEXT alpha
LIST.CLEAR plist
PAUSE 1000
RETURN

MakeKeys:
gn = 1
px = 2
py = 3
vx = 4
vy = 5
rad= 6
ax = 7
ay = 8
WallWidth = 10
RETURN

CheckTouch: %TODO circular speed limit
GR.TOUCH flag, touch[px], touch[py]
IF flag
 !TODO better controls, powerup shot
 ball[vx] = (touch[px]-ball[px])/w*200
 ball[vy] = (touch[py]-ball[py])/h*200
 totalv = ABS(ball[vx])+ABS(ball[vy])+0.00001
 xpercent = ABS(ball[vx]/totalv)
 ypercent = ABS(ball[vy]/totalv)
 IF totalv > ballspeedlimit
  ball[vx] = SGN(ball[vx])*ballspeedlimit*xpercent
  ball[vy] = SGN(ball[vy])*ballspeedlimit*ypercent
 ENDIF
ENDIF
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

white:
GR.COLOR 255,255,255,255,1
RETURN
red:
GR.COLOR 255,255,85,255,1
RETURN
blue:
GR.COLOR 255,85,255,255,1
RETURN
whitealpha:
GR.COLOR alpha,255,255,255,1
RETURN
redalpha:
GR.COLOR alpha,255,85,255,1
RETURN
bluealpha:
GR.COLOR alpha,85,255,255,1
RETURN

BuildSendString:
SENDSTR$ = sNum$(ball[px],w) + " " + sNum$(ball[py],h)~
+ " " + sNum$(ball[vx],1) + " " + sNum$(ball[vy],1)~
+ " " + sNum$(flix[px],w) + " " + sNum$(flix[py],h)~
+ " " + sNum$(flix[vx],1) + " " + sNum$(flix[vy],1)~
+ " " + STR$(tscore) + " " + STR$(bscore)
RETURN

HandleTCP:
IF IsClient
 SOCKET.CLIENT.WRITE.LINE sendstr$
 SOCKET.CLIENT.READ.READY readyflag
 WHILE readyflag
  SOCKET.CLIENT.READ.LINE rmsg$
  GOSUB ParseMessage
  SOCKET.CLIENT.READ.READY readyflag
 REPEAT 
ENDIF
IF IsServer
 SOCKET.SERVER.WRITE.LINE sendstr$
 SOCKET.SERVER.READ.READY readyflag
 WHILE readyflag
  SOCKET.SERVER.READ.LINE rmsg$
  GOSUB ParseMessage
  SOCKET.SERVER.READ.READY readyflag
 REPEAT
ENDIF
RETURN

!XXXXXXXXXXXX START FUNCTION DEFS XXXXXXXXXXXXXXXXXXXX
FnInit:
FN.DEF UpdatePhysics (b[])
 GOSUB MakeKeys %makes keys to treat arrays like a class
 b[vx] = b[vx]+b[vx]*b[ax]
 b[vy] = b[vy]+b[vy]*b[ay]
 b[px] = b[px] + b[vx]
 b[py] = b[py] + b[vy]
FN.END

!TODO nudge ball positions to prevent overlap/passthru??
FN.DEF CheckBalls (b1[], b2[])
 GOSUB MakeKeys
 difx = b1[px]-b2[px]
 dify = b1[py]-b2[py]
 dist = POW(difx,2)+POW(dify,2)
 dist = SQR(dist)
 IF dist < b1[rad]+b2[rad] %balls hit
  ARRAY.LOAD vib[],1,3
  VIBRATE vib[], -1
  !TODO better energy transfer
  b2[vx] = b2[vx]*difx/5
  b2[vy] = b2[vy]*dify/5
  b1[vx] = b1[vx]+difx/5
  b1[vy] = b1[vy]+dify/5
 ENDIF
FN.END

FN.DEF CheckWalls (ball[], walls[], w, h)
 GOSUB MakeKeys
 FOR x=1 TO 4
  IF GR_COLLISION(ball[gn], walls[x])
   ARRAY.LOAD vib[],1,3
   VIBRATE vib[], -1
   SW.BEGIN x
    SW.CASE 1 %top wall
     ball[vy] = ABS(ball[vy])
	 ball[py] = ball[rad]+WallWidth+1
     SW.BREAK
    SW.CASE 2 %right wall
     ball[vx] = -ABS(ball[vx])
	 ball[px] = w - ball[rad]-WallWidth-1
     SW.BREAK
    SW.CASE 3 %bottom wall
     ball[vy] = -ABS(ball[vy])
	 ball[py] = h - ball[rad]-WallWidth-1
     SW.BREAK
    SW.CASE 4 %left wall
     ball[vx] = ABS(ball[vx])
	 ball[px] = ball[rad]+WallWidth+1
     SW.BREAK
   SW.END
  ENDIF
 NEXT x
FN.END

FN.DEF sNum$(num, scale)
 dataRes=2000
 FN.RTN STR$(INT(num/scale*dataRes))
FN.END
RETURN

ONERROR:
PRINT GETERROR$()
END
