.586
.model flat,stdcall
option casemap:none

include \masm32\include\masm32rt.inc
include \masm32\include\winmm.inc

includelib \masm32\lib\winmm.lib

; porcedure pre-statement
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
InitMap proto

; global initialized data
.DATA                                                         
        ; the name of window class
        ClassName        db           "SimpleWinClass",0   
        ; the title of window      
        AppName          db           "Gluttonous Snake",0    
        ; for DEBUG       
        IconErr          db           "Icon Error",0
        fmt              db           "%d,%d,%d,%d", 0
        SnM              db           "snakeMsg",0
        snakeMsg         db           "%d,%d,%d,%d", 0
        SnCrM            db           "snakeCrashMsg",0
        snakeCrashMsg    db           "edi=%d,esi=%d,edioc=%d,esioc=%d", 0
        ; GAME text
        GameOverTitle    db           "Game Over",0
        SnakeAchievement db           "Snake Length: %d, Your Score: %d",0
        SnakeLength      db           "Snake Length: %d ",0
        SnakeScore       db           "Score: %d ",0
        TitleAbout       db           "About",0
        TextAbout        db           "You are right. However, Snake is a classic game that was developed in 1976 at Bell Labs and has become a popular casual game.",0
        TitleControl     db           "HOW TO PLAY",0
        TextControl      db           "Press the SPACE to start/pause the game and use WASD to control the snake's movement.",0

        ; output buffer
        szBuffer         db           256 dup(0)
        ; define window size
        WND_WIDTH        equ          800
        WND_HEIGHT       equ          750
        ; define block size 
        ICON_WIDTH       equ          32
        ICON_HEIGHT      equ          32
        ; define timer interval
        TIMER            equ          500
        ; define resource id, conforming to .rc (header) file
        IDI_ICON1        equ          101
        IDI_ICON2        equ          102
        IDI_ICON3        equ          103
        IDI_HR           equ          104
        IDI_HD           equ          105
        IDI_HL           equ          106
        IDI_HU           equ          107
        IDM_MENU1        equ          200
        IDM_START        equ          211
        IDM_STOP         equ          212
        IDM_QUIT         equ          213
        IDM_CTRL         equ          221
        IDM_ABOUT        equ          222
        IDA_ACCELERATOR1 equ          300
        ; define music about
        Mp3DeviceID      dd           0
        PlayFlag         dd           0
        Mp3Device        db           "MPEGVideo",0     ; play .mp3, so use MPEGVideo
        MUSIC_TOUSHIGE   db           "toushige.mp3",0
        
        ; orientation meaning:
        ; 0:no orientation
        ; 1:right
        ; 2:up
        ; 4:down
        ; 3:left
        RIGHT equ 1
        UP    equ 2
        LEFT  equ 3
        DOWN  equ 4

        ; define position in map
        SnakeInfo struct
                y               byte    5
                x               byte    4
                orientation     byte    RIGHT
                satisfied       byte    0
                len          dword   4
                score           dword   0
        SnakeInfo ends
        mySnake SnakeInfo <?>    
        
        ; occupancy meaning:
        ; 0:empty
        ; 2:food
        ; 3:snake
        ; 6/7:wall
        EMPTY           equ     0
        FOOD            equ     2
        SNAKE_HEAD      equ     3
        SNAKE           equ     4
        WALL            equ     6
        FOODVALUE       equ     10

        ;define game area size 
        MAXROW   equ     20
        MAXCOL   equ     20
        MAPSIZE  equ     400
        mapInY   db      400 dup(0)     
        mapInX   db      400 dup(0)     
        mapOutY  db      400 dup(0)     
        mapOutX  db      400 dup(0)     
        mapOcpy  db      400 dup(0) 
        ; dynamic game data
        gameIsRunning   db      0
        snakeCanSwerve  db      1
        foodExist       db      0
        randSeed        DWORD   0
                
        ; define block in map, a pity that i don't know how to use struct :C
        ; GBlock struct
        ;         mvInX      byte  0
        ;         mvInY   byte    0
        ;         mvOutX  byte    0
        ;         mvOutY  byte    0
        ;         occupancy   byte    EMPTY
        ; GBlock ends

; global data, but Uninitialized
.DATA?       
        ; Instance handle of our program
        hInstance    HINSTANCE  ?
        hWindow      HINSTANCE  ?
        CommandLine  LPSTR      ?
        ; menu handle
        hMenu        HMENU      ?
        ; accelerator handle
        hAccelerator HACCEL     ?
        ; icon handle
        hIcon_green  HICON      ?
        hIcon_blue   HICON      ?
        hIcon_orange HICON      ?
        hIcon_down   HICON      ?
        hIcon_right  HICON      ?
        hIcon_left   HICON      ?
        hIcon_up     HICON      ?
                  
.CODE
start:  
; get the instance handle of our program.
        invoke GetModuleHandle, NULL
        mov    hInstance,eax
; get the command line handle. command line is command from menu .etc
        invoke GetCommandLine
        mov    CommandLine,eax
; Load resources
        ; Load icon
        invoke LoadIcon, hInstance, IDI_ICON1
        mov    hIcon_green, eax
        invoke LoadIcon, hInstance, IDI_ICON2
        mov    hIcon_blue, eax
        invoke LoadIcon, hInstance, IDI_ICON3
        mov    hIcon_orange, eax
        invoke LoadIcon, hInstance, IDI_HD
        mov    hIcon_down, eax
        invoke LoadIcon, hInstance, IDI_HL
        mov    hIcon_left, eax
        invoke LoadIcon, hInstance, IDI_HR
        mov    hIcon_right, eax
        invoke LoadIcon, hInstance, IDI_HU
        mov    hIcon_up, eax
        ; Load menu
        invoke LoadMenu, hInstance, IDM_MENU1
        mov    hMenu, eax
        ; Load acceleratormsg
        invoke LoadAccelerators, hInstance, IDA_ACCELERATOR1
        mov    hAccelerator, eax
; Initialize game map
        invoke InitMap
; call the main function
        invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
; quit program. The exit code is returned in eax from WinMain.
        invoke ExitProcess, eax

; play music
PlayMp3File proc hWin:DWORD,NameOfFile:DWORD
      LOCAL mciOpenParms:MCI_OPEN_PARMS
      LOCAL mciPlayParms:MCI_PLAY_PARMS

            mov eax,hWin        
            mov mciPlayParms.dwCallback,eax

            mov eax, OFFSET Mp3Device
            mov mciOpenParms.lpstrDeviceType,eax

            mov eax,NameOfFile
            mov mciOpenParms.lpstrElementName,eax

            invoke mciSendCommand,0,MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,ADDR mciOpenParms
            mov eax,mciOpenParms.wDeviceID
            mov Mp3DeviceID,eax

            invoke mciSendCommand,Mp3DeviceID,MCI_PLAY,MCI_NOTIFY,ADDR mciPlayParms
            ret  
PlayMp3File endp

; With Row and Col, return linear index in gameMap
GetIndex proc uses edi row:byte, col:byte
; calculate block offset in ebx
        movzx edi,row
        mov eax,MAXCOL
        mul edi
        mov edi,eax
        movzx eax,col
        add eax,edi
        ret
GetIndex endp

; Initialize birth of snake
InitSnake proc
        local @birthX:byte
        local @birthY:byte
        local @birthLen:byte
        mov @birthX,1
        mov @birthY,5
        mov @birthLen,4
        movzx ecx,@birthLen
        createSnake:
                invoke GetIndex,@birthY,@birthX
                mov edi,eax
                ; set ocpy
                mov mapOcpy[edi],SNAKE
                ; set movein and moveout
                mov al,@birthY
                mov mapOutY[edi],al
                mov mapInY[edi],al
                mov al,@birthX
                push ax
                inc al
                mov mapOutX[edi],al
                pop ax
                dec al
                mov mapInX[edi],al
                inc @birthX
                loop createSnake

        mov mySnake.x,4
        mov mySnake.y,5
        mov mySnake.orientation,RIGHT
        mov mySnake.len,4
        mov mySnake.score,0
        invoke GetIndex,5,4
        mov edi,eax
        mov mapOcpy[edi],SNAKE_HEAD
        ret
InitSnake endp

; untested random number generator
xorshift128plus PROC s:DWORD
        mov     eax, dword ptr [s]                      ; 0000 _ 48: 8B. 05, 00000000(rel)
        mov     edx, dword ptr [s+8H]                   ; 0007 _ 48: 8B. 15, 00000008(rel)
        mov     dword ptr [s], edx                      ; 000E _ 48: 89. 15, 00000000(rel)
        mov     ecx, eax                                ; 0015 _ 48: 89. C1
        shl     ecx, 23                                 ; 0018 _ 48: C1. E1, 17
        xor     eax, ecx                                ; 001C _ 48: 31. C8
        mov     ecx, eax                                ; 001F _ 48: 89. C1
        xor     ecx, edx                                ; 0022 _ 48: 31. D1
        shr     eax, 17                                 ; 0025 _ 48: C1. E8, 11
        xor     ecx, eax                                ; 0029 _ 48: 31. C1
        mov     eax, edx                                ; 002C _ 48: 89. D0
        shr     eax, 26                                 ; 002F _ 48: C1. E8, 1A
        xor     ecx, eax                                ; 0033 _ 48: 31. C1
        mov     dword ptr [s+8H], ecx                   ; 0036 _ 48: 89. 0D, 00000008(rel)
        mov     eax, dword ptr [s+8H]                   ; 003D _ 48: 8B. 05, 00000008(rel)
        add     eax, edx                                ; 0044 _ 48: 01. D0
        
        ret                                             ; 0047 _ C3
xorshift128plus ENDP

; generate random number
generate_random_number PROC range:DWORD
        ; Get the system time as random number seed
        invoke GetTickCount
        mov randSeed, eax
        invoke nseed, randSeed
        invoke nrandom, range
        mov ebx, range
        xor edx, edx
        div ebx
        mov eax,edx
        ret
generate_random_number ENDP

;init food
CreateFood PROC uses eax edx
generateRandom:
        ; invoke myRandom,MAPSIZE
        invoke generate_random_number,MAPSIZE
        mov dl,mapOcpy[eax]
        cmp dl,EMPTY
        jnz generateRandom
        ; jnz nofoodhere
createFood:
        mov mapOcpy[eax],FOOD
        mov foodExist,1
nofoodhere:
        ret
CreateFood ENDP

; Initialize the map (draw walls), and the birth of snake
InitMap proc 
        local @x:byte
        local @y:byte
        local @block:dword
        ; Initialize local variable
        mov @x,0
        mov @y,0

        for_row:
                cmp @y,MAXROW
                jz snakeBirth
                mov @x,0
        for_col:
                cmp @x,MAXCOL
                jz nextRow
        setBlock:
                invoke GetIndex,@y,@x
                mov edi,eax
        ; Initialize current block 
                ; set Wall
                .if(@y==0||@x==0||@y==MAXROW-1||@x==MAXCOL-1)
                        mov mapOcpy[edi],WALL
                .else
                        mov mapOcpy[edi],EMPTY
                .endif
                ;set movein and moveout
                mov al,@y
                mov mapInY,al
                mov mapOutY,al
                mov al,@x
                mov mapInX,al
                mov mapOutX,al
        nextCol:
                inc @x
                jmp for_col
        nextRow:
                inc @y
                jmp for_row
        snakeBirth:
                push ecx
                invoke InitSnake
                pop ecx
                invoke CreateFood
                ret
InitMap endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
                LOCAL  @wc:WNDCLASSEX
                LOCAL  @msg:MSG
                LOCAL  @hWnd:HWND
        ; define my custom window. fill values in members of @wc
                mov    @wc.cbSize,SIZEOF WNDCLASSEX
                mov    @wc.style, CS_HREDRAW or CS_VREDRAW
                mov    @wc.lpfnWndProc, OFFSET WndProc
                mov    @wc.cbClsExtra,NULL
                mov    @wc.cbWndExtra,NULL
                push   hInstance
                pop    @wc.hInstance
                mov    @wc.hbrBackground,COLOR_WINDOW+1
                mov    @wc.lpszMenuName,IDM_MENU1
                mov    @wc.lpszClassName,OFFSET ClassName
                invoke LoadIcon,NULL,IDI_APPLICATION
                mov    @wc.hIcon,eax
                mov    @wc.hIconSm,eax
                invoke LoadCursor,NULL,IDC_ARROW
                mov    @wc.hCursor,eax
        ; register custom window
                invoke RegisterClassEx, addr @wc
        ; create custom window with 12 param
                invoke CreateWindowEx,NULL,\
ADDR   ClassName,\
ADDR   AppName,\
WS_OVERLAPPEDWINDOW,\
CW_USEDEFAULT,\
CW_USEDEFAULT,\
WND_WIDTH,\
WND_HEIGHT,\
NULL,\
NULL,\
hInst,\
NULL
        ; get window handle
                mov    @hWnd,eax
        ; display window on desktop
                invoke ShowWindow, @hWnd, CmdShow
        ; refresh the client area, (send PAINT message). just a demonstration, actually unnecessary
                invoke UpdateWindow, @hWnd
        ; set TIMER to send timing signal
                invoke SetTimer, @hWnd, NULL, TIMER, NULL
        ; Enter message loop
        .WHILE TRUE
                invoke GetMessage, ADDR @msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateAccelerator, @hWnd, hAccelerator, addr @msg
                .if (eax==0)
                        invoke TranslateMessage, ADDR @msg
                        invoke DispatchMessage, ADDR @msg
                .endif
        .ENDW
        ; if receive WM_destory, end this programme
                mov           eax,@msg.wParam
                ret
WinMain endp

; paint game area
DrawMap proc hdc:DWORD,hWnd:HWND
; Define the dimensions of the matrix
        LOCAL         @curRow:dword
        LOCAL         @curCol:dword
        LOCAL         @xp:DWORD
        LOCAL         @yp:DWORD
        LOCAL         @temp:byte
; Initialize variables
        mov           @curRow, 0
        mov           @curCol, 0
        mov           @xp, 0
        mov           @yp, 0
        mov           ecx, 0
        drawrow:
                mov eax,MAXROW
                cmp @curRow,eax
                jz endDrawMap
                mov @curCol,0
        drawcol:
                mov eax,MAXCOL
                cmp @curCol,MAXCOL
                jz nextRow
        drawBlock:
        ; calculate xp and yp
                mov ebx,ICON_HEIGHT
                mov eax,@curRow
                mul ebx
                mov @yp,eax
                mov ebx,ICON_WIDTH
                mov eax,@curCol
                mul ebx
                mov @xp,eax
        ; get block index 
                invoke GetIndex,byte ptr @curRow,byte ptr @curCol
                mov edi,eax
        ; according to occupancy, draw blocks
                mov al,mapOcpy[edi]
                .if (al==WALL)
                        invoke DrawIcon, hdc, @xp, @yp, hIcon_blue
                .elseif (al==SNAKE)
                        invoke DrawIcon, hdc, @xp, @yp, hIcon_green
                .elseif (al==SNAKE_HEAD)
                        .if mySnake.orientation==RIGHT
                                invoke DrawIcon, hdc, @xp, @yp, hIcon_right
                        .elseif mySnake.orientation==UP
                                invoke DrawIcon, hdc, @xp, @yp,  hIcon_up
                        .elseif mySnake.orientation==LEFT
                                invoke DrawIcon, hdc, @xp, @yp, hIcon_left
                        .else
                                invoke DrawIcon, hdc, @xp, @yp, hIcon_down
                        .endif
                .elseif (al==FOOD)
                        invoke DrawIcon, hdc, @xp, @yp, hIcon_orange
                .else
                .endif
        nextCol:
                inc @curCol
                jmp drawcol
        nextRow:
                inc @curRow
                jmp drawrow
        endDrawMap:
                ret
DrawMap endp

UpdateMapData proc hWnd:HWND
        local @curY:byte
        local @curX:byte
        local @nextY:byte
        local @nextX:byte
        local @HY:byte
        local @HX:byte
; if game stop, skip all 
        cmp gameIsRunning,0
        jz endUpdateMapDate
        mov snakeCanSwerve,0
; get head coordinate
        mov ah, mySnake.y
        mov @curY, ah
        mov al, mySnake.x
        mov @curX, al
getCurIndex:
        ; get head current block
        invoke GetIndex,@curY,@curX
        mov edi,eax
        ; if current block movein equal to itself coordinate, end update
        mov ah,mapInY[edi]
        mov al,mapInX[edi]
; Determine whether the block is snakehead or WALL or EMPTY or FOOD, if yes, skip to avoid infinite loop
        .if(ah==mySnake.y && al==mySnake.x)
                jmp createFoodOrNot
        .endif
        mov al,mapOcpy[edi]
        cmp al,EMPTY
        jz createFoodOrNot
        cmp al,WALL
        jz createFoodOrNot
        cmp al,FOOD
        jz createFoodOrNot
; get next block coordinate
        mov ah,mapOutY[edi]
        mov @nextY,ah
        mov al,mapOutX[edi]
        mov @nextX,al
; get next block index
        invoke GetIndex, @nextY, @nextX
        mov esi,eax
; compare ocpy, if crash, game over
        mov dl,mapOcpy[edi]
        mov al,mapOcpy[esi]
        cmp dl,al
        jb crash
; if food, gain score and become "satisfied" (growing up)
        cmp al,FOOD
        jnz snakeMove
        mov eax,mySnake.score
        add eax, FOODVALUE
        mov mySnake.score,eax
        mov eax,mySnake.len
        inc eax
        mov mySnake.len,eax
        mov foodExist,0
        mov mySnake.satisfied,1
snakeMove:
        ; if snake head, set movein and moveout of next block
        mov dl,mapOcpy[edi]
        cmp dl,SNAKE_HEAD
        jne notHead
        ; set next block movein equal to current block coordinate
        mov ah,@curY
        mov al,@curX
        mov mapInY[esi],ah
        mov mapInX[esi],al
        ; set next block occupy, if satisfied, grow up
        mov mapOcpy[esi],SNAKE_HEAD
        cmp mySnake.satisfied,0
        jz unsatisfied
        mov mapOcpy[edi],SNAKE
        jmp updateMySnakePosition
unsatisfied:
        mov mapOcpy[edi],0
updateMySnakePosition:
        mov ah,@nextY
        mov mySnake.y,ah
        mov al,@nextX
        mov mySnake.x,al
; set next block moveout according to head orientation
        .if (mySnake.orientation==RIGHT)
                mov ah,mySnake.y
                mov mapOutY[esi],ah
                mov al,mySnake.x
                inc al
                mov mapOutX[esi],al
        .elseif (mySnake.orientation==UP)
                mov ah,mySnake.y
                dec ah
                mov mapOutY[esi],ah
                mov al,mySnake.x
                mov mapOutX[esi],al
        .elseif (mySnake.orientation==LEFT)
                mov ah,mySnake.y
                mov mapOutY[esi],ah
                mov al,mySnake.x
                dec al
                mov mapOutX[esi],al
        .elseif (mySnake.orientation==DOWN)
                mov ah,mySnake.y
                inc ah
                mov mapOutY[esi],ah
                mov al,mySnake.x
                mov mapOutX[esi],al
        .endif
        ; if satisfied, become hungry back and skip body movement
        cmp mySnake.satisfied,0
        jz keepHungry
        mov mySnake.satisfied,0
        jmp createFoodOrNot
keepHungry:
        jmp nextBody 
notHead:
        ; set next block ocpy
        mov al,mapOcpy[edi]
        mov mapOcpy[esi],al
        mov mapOcpy[edi],0
nextBody:
        ; move point towards snake tail
        mov ah,mapInY[edi]
        mov @curY,ah
        mov al,mapInX[edi]
        mov @curX,al
        jmp getCurIndex
; snake crashes
crash:
        mov gameIsRunning,0
        push eax
        movzx ebx,ah
        movzx eax,al
        invoke wsprintf, Addr szBuffer, Addr SnakeAchievement, mySnake.len, mySnake.score
        invoke MessageBox, hWnd, addr szBuffer, addr GameOverTitle, MB_OK
        pop eax
        invoke InitMap
        jmp endUpdateMapDate
createFoodOrNot:
        cmp foodExist,1
        jz endUpdateMapDate
        invoke CreateFood
endUpdateMapDate:
        mov snakeCanSwerve,1
        ret
UpdateMapData endp

; deal with key down
HandleKeydown proc uses edi hWnd:HWND, msg:UINT, wParam:WPARAM, lParam:LPARAM, hdc:DWORD
        LOCAL   @xp:DWORD
        LOCAL   @yp:DWORD

        mov eax, wParam
        .if eax == VK_SPACE
                cmp gameIsRunning,0
                jz setRunning
                mov gameIsRunning,0
                ; stop music
                invoke mciSendCommand,Mp3DeviceID,MCI_CLOSE,0,0
                jmp zeroSet
        setRunning:
                mov gameIsRunning,1
                ; play music
                invoke PlayMp3File, hWnd, addr MUSIC_TOUSHIGE
                zeroSet:
        ; key W
        .elseif (eax == 87 || eax == VK_UP)
                cmp snakeCanSwerve,0
                jz endHandleKeydown
                cmp gameIsRunning,0
                jz endHandleKeydown
        ; you can not go back
                invoke GetIndex,mySnake.y,mySnake.x
                mov edi,eax
                mov ah,mapInY[edi]
                mov al,mySnake.y
                dec al
                cmp ah,al
                jz endHandleKeydown
        ; change out direction
                mov mapOutY[edi],al
                mov al,mySnake.x
                mov mapOutX[edi],al
        ; draw snake head
                mov mySnake.orientation,UP
                invoke InvalidateRect, hWnd, NULL, TRUE
        ; key A
        .elseif (eax == 65 || eax == VK_LEFT)
                cmp snakeCanSwerve,0
                jz endHandleKeydown
                cmp gameIsRunning,0
                jz endHandleKeydown
        ; you can not go back
                invoke GetIndex,mySnake.y,mySnake.x
                mov edi,eax
                mov ah,mapInX[edi]
                mov al,mySnake.x
                dec al
                cmp ah,al
                jz endHandleKeydown
        ; change out direction
                mov mapOutX[edi],al
                mov al,mySnake.y
                mov mapOutY[edi],al
        ; draw snake head
                mov mySnake.orientation,LEFT
                invoke InvalidateRect, hWnd, NULL, TRUE
        ; key S
        .elseif (eax == 83 || eax == VK_DOWN)
                cmp snakeCanSwerve,0
                jz endHandleKeydown
                cmp gameIsRunning,0
                jz endHandleKeydown
        ; you can not go back
                invoke GetIndex,mySnake.y,mySnake.x
                mov edi,eax
                mov ah,mapInY[edi]
                mov al,mySnake.y
                inc al
                cmp ah,al
                jz endHandleKeydown
        ; change out direction
                mov mapOutY[edi],al
                mov al,mySnake.x
                mov mapOutX[edi],al
        ; draw snake head
                mov mySnake.orientation,DOWN
                invoke InvalidateRect, hWnd, NULL, TRUE
        ; key D
        .elseif (eax == 68 || eax == VK_RIGHT)
                cmp snakeCanSwerve,0
                jz endHandleKeydown
                cmp gameIsRunning,0
                jz endHandleKeydown
        ; you can not go back
                invoke GetIndex,mySnake.y,mySnake.x
                mov edi,eax
                mov ah,mapInX[edi]
                mov al,mySnake.x
                inc al
                cmp ah,al
                jz endHandleKeydown
        ; change out direction
                mov mapOutX[edi],al
                mov al,mySnake.y
                mov mapOutY[edi],al
        ; draw snake head
                mov mySnake.orientation,RIGHT
                invoke InvalidateRect, hWnd, NULL, TRUE
        ; key C
        .elseif eax == 67
                mov gameIsRunning,1
        ; key X
        .elseif eax == 88
                mov gameIsRunning,0
        ; key Z
        .elseif eax == 90
                invoke PostQuitMessage,NULL
        .else 
        .endif
        endHandleKeydown:
                ret
HandleKeydown endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        local @hdc:dword
        local @brush:dword
        local @ps:PAINTSTRUCT
        local rect:RECT
        local rect1:RECT

        .IF uMsg == WM_COMMAND
                mov eax, wParam
                .if ax==IDM_ABOUT
                        mov gameIsRunning,0
                        invoke MessageBox,hWnd,addr TextAbout,addr TitleAbout,MB_OK or MB_ICONINFORMATION
                .elseif ax==IDM_CTRL
                        mov gameIsRunning,0
                        invoke MessageBox,hWnd,addr TextControl,addr TitleControl,MB_OK or MB_ICONINFORMATION
                .elseif ax==IDM_START
                        mov gameIsRunning,1
                        ; play music
                        invoke PlayMp3File, hWnd, addr MUSIC_TOUSHIGE
                .elseif ax==IDM_STOP
                        mov gameIsRunning,0
                        ; stop music
                        invoke mciSendCommand,Mp3DeviceID,MCI_CLOSE,0,0
                .elseif ax==IDM_QUIT
                        invoke PostQuitMessage,NULL
                .endif
                

        .elseif uMsg == WM_PAINT
                invoke BeginPaint, hWnd, addr @ps
                mov           @hdc, eax
        
                ;draw red background
                ; invoke CreateSolidBrush, 0ffh
                ; mov    @brush, eax
                ; invoke FillRect, @hdc, addr @ps.rcPaint, @brush
                ; invoke DeleteObject, @brush

        ; draw text
                invoke GetClientRect, hWnd, addr rect
        ; Calculate the client area of ​​the window
                ; invoke AdjustWindowRect, addr rect, WS_OVERLAPPEDWINDOW, FALSE
                invoke wsprintf, Addr szBuffer, Addr SnakeScore, mySnake.score
                invoke DrawText, @hdc, addr szBuffer, -1, addr rect, DT_SINGLELINE OR DT_RIGHT OR DT_VCENTER
                mov eax,rect.top
                add eax,30
                mov rect.top,eax
                invoke wsprintf, Addr szBuffer, Addr SnakeLength, mySnake.len
                invoke DrawText, @hdc, addr szBuffer, -1, addr rect, DT_SINGLELINE OR DT_RIGHT OR DT_VCENTER
                mov eax,rect.top
                sub eax,30
                mov rect.top,eax
        ; repaint game area
                invoke DrawMap, @hdc, hWnd
        ; end paint
                invoke EndPaint, hWnd, addr @ps
        .elseif uMsg == WM_TIMER
                invoke UpdateMapData, hWnd
                invoke InvalidateRect, hWnd, NULL, TRUE
        .elseif uMsg == WM_KEYDOWN
                invoke HandleKeydown, hWnd, uMsg, wParam, lParam, @hdc
        .elseif uMsg == MM_MCINOTIFY
                invoke PlayMp3File, hWnd, addr MUSIC_TOUSHIGE
        .elseif uMsg == WM_LBUTTONDOWN
                ; invoke        MessageBox,hWnd,addr ClassName,0,MB_OK or MB_ICONINFORMATION
        .elseif uMsg==WM_DESTROY
                invoke        PostQuitMessage,NULL
        .ELSE 
                ; Default message processing                                                           
                invoke DefWindowProc,hWnd,uMsg,wParam,lParam
                ret
        .ENDIF
        xor eax,eax
        ret
WndProc endp



end start 
; DEBUG
; push eax
; movzx ebx,mapOcpy[esi]
; movzx eax,mapOcpy[edi]
; Invoke wsprintf, Addr szBuffer, Addr snakeMsg, edi,esi,ebx,eax
; invoke MessageBox, hWnd, addr szBuffer, addr SnM, MB_OK
; pop eax