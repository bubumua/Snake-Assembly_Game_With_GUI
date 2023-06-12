# 编译/链接/运行

你可以直接运行`.exe`文件来看看这程序的效果

或者，在你编写完源程序后，运行`nmake`。前提是你已经安装了MASM32SDK，并且将必要的编译器、链接器、make工具等加入到了系统`PATH`，且在目录下有`makefile`文件。如果你更改了文件名，或者需要编译、链接其他文件，记得修改`makefile`文件哦。

关于MASM32SDK和其他工具的下载，可以翻翻我的[ASSEMBLY库](https://github.com/bubumua/ASSEMBLY)

# MASM32汇编

编译器：MASM32 SDK v11r

我没有使用VS或VC这种IDE，我只是下载/安装了MASM32SDK以及nmake工具，在编辑完源文件后使用`ml`、`rc`、`link`等命令进行编译、链接，关于这些命令，你可以在`makefile`文件里看到

如果你学习过DOS，那么win32的汇编大同小异，只需灵活invoke就行。下面是我在学习过程中的一些笔记，仅供参考。

## 参考与引用

https://www.bilibili.com/video/BV1os411c7Sh

https://www.jj2007.eu/Masm32_Tips_Tricks_and_Traps.htm

http://winprog.org/tutorial/references.html

## 窗口模板

这个模板来自于一个教学网站，但我找不到了。。。

```asm
.386
.model flat,stdcall
option casemap:none
include \masm32\include\windows.inc
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib            ; calls to functions in user32.lib and kernel32.lib
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.DATA                                                     ; initialized data
        ClassName db          "SimpleWinClass",0          ; the name of our window class
        AppName   db          "Our First Window",0        ; the name of our window

.DATA?                                                    ; Uninitialized data
                  hInstance   HINSTANCE ?                 ; Instance handle of our program
                  CommandLine LPSTR ?
.CODE                                                                             ; Here begins our code
        start:  
                invoke GetModuleHandle, NULL                                      ; get the instance handle of our program.
        ; Under Win32, hmodule==hinstance mov hInstance,eax
                mov    hInstance,eax
                invoke GetCommandLine                                             ; get the command line. You don't have to call this function IF
        ; your program doesn't process the command line.
                mov    CommandLine,eax
                invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; call the main function
                invoke ExitProcess, eax                                           ; quit our program. The exit code is returned in eax from WinMain.

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
                LOCAL  wc:WNDCLASSEX                                              ; create local variables on stack
                LOCAL  msg:MSG
                LOCAL  hwnd:HWND

                mov    wc.cbSize,SIZEOF WNDCLASSEX                                ; fill values in members of wc
                mov    wc.style, CS_HREDRAW or CS_VREDRAW
                mov    wc.lpfnWndProc, OFFSET WndProc
                mov    wc.cbClsExtra,NULL
                mov    wc.cbWndExtra,NULL
                push   hInstance
                pop    wc.hInstance
                mov    wc.hbrBackground,COLOR_WINDOW+1
                mov    wc.lpszMenuName,NULL
                mov    wc.lpszClassName,OFFSET ClassName
                invoke LoadIcon,NULL,IDI_APPLICATION
                mov    wc.hIcon,eax
                mov    wc.hIconSm,eax
                invoke LoadCursor,NULL,IDC_ARROW
                mov    wc.hCursor,eax
                invoke RegisterClassEx, addr wc                                   ; register our window class
                invoke CreateWindowEx,NULL,\
                ADDR   ClassName,\
                ADDR   AppName,\
                        WS_OVERLAPPEDWINDOW,\
                        CW_USEDEFAULT,\
                        CW_USEDEFAULT,\
                        CW_USEDEFAULT,\
                        CW_USEDEFAULT,\
                        NULL,\
                        NULL,\
                        hInst,\
                NULL
                mov    hwnd,eax
                invoke ShowWindow, hwnd,CmdShow                                   ; display our window on desktop
                invoke UpdateWindow, hwnd                                         ; refresh the client area

.WHILE TRUE                                                                       ; Enter message loop
                invoke GetMessage, ADDR msg,NULL,0,0
.BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
.ENDW
                mov    eax,msg.wParam              ; return exit code in eax
                ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
.IF uMsg==WM_DESTROY                               ; if the user closes our window
                invoke PostQuitMessage,NULL        ; quit our application
.ELSE
             invoke DefWindowProc,hWnd,uMsg,wParam,lParam        ; Default message processing
             ret
.ENDIF
                xor eax,eax
                ret
WndProc endp

end start 
```

### 分析

```asm
 invoke GetModuleHandle, NULL  
```

这句调用函数，获取本程序的实例句柄。实例句柄可以看作是本程序的ID，用作程序必须调用的几个 API 函数的参数。实际上在win32下，实例句柄是你的程序在内存中的线性地址。

调用的 Win32 函数几乎总是保留段寄存器和 ebx、edi、esi 和 ebp 寄存器。eax、ecx、edx 的值通常会“挥发”。

```asm
invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT  
```

WinMain 调用。  这里它接收四个参数：

1. 我们程序的实例句柄，
2. 我们程序的前一个实例的实例句柄，第一次出现时的命令行和窗口状态。  在  Win32 下，没有以前的实例。  每个程序在其地址空间中都是单独的，因此 hPrevInst 的值始终为 0。这是 Win16  时代的遗留问题，当时一个程序的所有实例都在同一地址空间中运行，并且一个实例想知道它是否是第一个实例.   在win16下，如果hPrevInst为NULL，那么这个实例就是第一个。
3. 未知
4. 未知

```asm
LOCAL  wc:WNDCLASSEX                                            
LOCAL  msg:MSG
LOCAL  hwnd:HWND
```

LOCAL 指令从堆栈中为函数中使用的局部变量分配内存。  一堆 LOCAL 指令必须紧接在 PROC 指令之下。  LOCAL  指令后面紧跟<局部变量的名称>:<变量类型>。  所以 LOCAL wc:WNDCLASSEX 告诉 MASM  从堆栈中为名为 wc 的变量分配 WNDCLASSEX 结构大小的内存。  我们可以在我们的代码中引用 wc 而不会涉及堆栈操作的任何困难。

不能自动初始化局部变量，因为它们只是在进入函数时动态分配的堆栈内存。您必须在 LOCAL 指令之后手动为它们分配所需的值。

WNDCLASSEX 中最重要的成员是 lpfnWndProc。  lpfn 代表指向函数的长指针。  在 Win32  下，没有“近”或“远”指针，只有指针，因为新的 FLAT 内存模型。  但这又是 Win16 时代的遗留问题。   每个窗口类都必须与一个称为窗口过程的函数相关联。  窗口过程负责处理从相关窗口类创建的所有窗口的消息。  Windows  将向窗口过程发送消息，通知它有关它所负责的窗口的重要事件，例如用户键盘或鼠标输入。  由窗口过程智能地响应它接收到的每个窗口消息。   您将花费大部分时间在窗口过程中编写事件处理程序。

WNDCLASSEX结构体如下：

```
WNDCLASSEX STRUCT DWORD
  cbSize            DWORD      ?
  style             DWORD      ?
  lpfnWndProc       DWORD      ?
  cbClsExtra        DWORD      ?
  cbWndExtra        DWORD      ?
  hInstance         DWORD      ?
  hIcon             DWORD      ?
  hCursor           DWORD      ?
  hbrBackground     DWORD      ?
  lpszMenuName      DWORD      ?
  lpszClassName     DWORD      ?
  hIconSm           DWORD      ?
WNDCLASSEX ENDS 
```

- cbSize：WNDCLASSEX 结构的字节大小。  我们可以使用 SIZEOF 运算符来获取值。  
- style：从这个类创建的窗口的风格。  您可以使用“或”运算符将多种样式组合在一起。  
- lpfnWndProc：负责从此类创建的窗口的窗口过程的地址。  
- cbClsExtra：指定要在窗口类结构之后分配的额外字节数。  操作系统将字节初始化为零。  您可以在此处存储特定于窗口类的数据。  
- cbWndExtra：指定要在窗口实例之后分配的额外字节数。  操作系统将字节初始化为零。  如果应用程序使用 WNDCLASS 结构在资源文件中注册使用 CLASS 指令创建的对话框，则必须将此成员设置为 DLGWINDOWEXTRA。  
- hInstance：模块的实例句柄。  
- hIcon：图标句柄。  从 LoadIcon 调用中获取它。  
- hCursor：光标句柄。  从 LoadCursor 调用中获取它。  
- hbrBackground：从该类创建的窗口的背景颜色。  
- lpszMenuName：从该类创建的窗口的默认菜单句柄。  
- lpszClassName：这个窗口类的名称。  
- hIconSm：与窗口类关联的小图标的句柄。  如果该成员为NULL，则系统在hIcon成员指定的图标资源中搜索合适大小的图标作为小图标。

```
mov    wc.cbSize,SIZEOF WNDCLASSEX                                ; fill values in members of wc
mov    wc.style, CS_HREDRAW or CS_VREDRAW
mov    wc.lpfnWndProc, OFFSET WndProc
mov    wc.cbClsExtra,NULL
mov    wc.cbWndExtra,NULL
push   hInstance
pop    wc.hInstance
mov    wc.hbrBackground,COLOR_WINDOW+1
mov    wc.lpszMenuName,NULL
mov    wc.lpszClassName,OFFSET ClassName
invoke LoadIcon,NULL,IDI_APPLICATION
mov    wc.hIcon,eax
mov    wc.hIconSm,eax
invoke LoadCursor,NULL,IDC_ARROW
mov    wc.hCursor,eax
```

填充wc变量的内容

```asm
invoke RegisterClassEx, addr wc                                   ; register our window class
invoke CreateWindowEx,NULL,\
                        ADDR ClassName,\
                        ADDR AppName,\
                        WS_OVERLAPPEDWINDOW,\
                        CW_USEDEFAULT,\
                        CW_USEDEFAULT,\
                        CW_USEDEFAULT,\
                        CW_USEDEFAULT,\
                        NULL,\
                        NULL,\
                        hInst,\
                        NULL
```

注册并完善我们的自定义窗口，关于CreateWindowEx这个函数，有12参数，如下：

```asm
CreateWindowExA proto dwExStyle:DWORD,\
                       lpClassName:DWORD,\
                       lpWindowName:DWORD,\
                       dwStyle:DWORD,\
                       X:DWORD,\
                       Y:DWORD,\
                       nWidth:DWORD,\
                       nHeight:DWORD,\
                       hWndParent:DWORD ,\
                       hMenu:DWORD,\
                       hInstance:DWORD,\
                       lpParam:DWORD 
```

- dwExStyle：额外的窗口样式。  这是添加到旧 CreateWindow 的新参数。  您可以在此处放置 Windows 95 和 NT  的新窗口样式。您可以在 dwStyle 中指定您的普通窗口样式，但如果您想要一些特殊样式，例如最顶层窗口，您必须在此处指定它们。   如果您不想要额外的窗口样式，可以使用 NULL。  
- lpClassName：（必需）。  包含要用作此窗口模板的窗口类名称的 ASCIIZ 字符串的地址。   该类可以是您自己注册的类或预定义的窗口类。  如上所述，您创建的每个窗口都必须基于一个窗口类。  
- lpWindowName：包含窗口名称的 ASCIIZ 字符串的地址。  它将显示在窗口的标题栏上。  如果此参数为  NULL，则窗口的标题栏将为空白。  
- dwStyle：窗口的样式。  您可以在此处指定窗口的外观。  传递 NULL  是可以的，但是窗口将没有系统菜单框，没有最小化-最大化按钮，也没有关闭窗口按钮。  窗户根本没有多大用处。  您需要按 Alt+F4 将其关闭。  最常见的窗口样式是 WS_OVERLAPPEDWINDOW。  一个窗口样式只是一个位标志。   因此，您可以通过“或”运算符组合多个窗口样式以获得所需的窗口外观。  
- WS_OVERLAPPEDWINDOW  样式实际上是通过这种方法组合了最常见的窗口样式。  
- X,Y：窗口左上角的坐标。  通常这个值应该是 CW_USEDEFAULT，也就是说，你希望 Windows  为你决定将窗口放在桌面上的什么位置。  
- nWidth、nHeight：窗口的宽度和高度（以像素为单位）。  您还可以使用 CW_USEDEFAULT 让 Windows  为您选择合适的宽度和高度。  
- hWndParent：窗口的父窗口（如果存在）的句柄。  此参数告诉 Windows  此窗口是否是某个其他窗口的子（从属）窗口，如果是，则哪个窗口是父窗口。  请注意，这不是多文档界面 (MDI) 的父子关系。   子窗口不绑定到父窗口的客户区。  此关系专门供 Windows 内部使用。  如果父窗口被销毁，所有的子窗口都会自动销毁。  真的就这么简单。  由于在我们的示例中只有一个窗口，因此我们将此参数指定为 NULL。  
- hMenu：窗口菜单的句柄。  如果要使用类菜单，则为 NULL。   
- lpszMenuName 指定窗口类的*默认*菜单。  默认情况下，从此窗口类创建的每个窗口都将具有相同的菜单。  除非您通过其 hMenu  参数为特定窗口指定一个 *overriding* 菜单。  
- hMenu实际上是一个两用参数。   如果您要创建的窗口是预定义的窗口类型（即控件），则此类控件不能拥有菜单。  hMenu 被用作该控件的 ID。  Windows 可以通过查看  lpClassName 参数来确定 hMenu 是否真的是菜单句柄或控件 ID。  如果它是预定义窗口类的名称，则 hMenu 是控件 ID。  如果不是，则它是窗口菜单的句柄。  
- hInstance：创建窗口的程序模块的实例句柄。  
- lpParam：指向传递给窗口的数据结构的可选指针。  MDI 窗口使用它来传递 CLIENTCREATESTRUCT 数据。   通常，此值设置为 NULL，表示没有数据通过 CreateWindow() 传递。  窗口可以通过调用 GetWindowLong  函数来获取这个参数的值。

```asm
    mov   hwnd,eax
    invoke ShowWindow, hwnd,CmdShow
    invoke UpdateWindow, hwnd 
```

根据创建窗口的结果，展示窗口（或不展示？）。下面一行是刷新窗口，用以更新内容

```asm
.WHILE TRUE                                           ; Enter message loop
    invoke GetMessage, ADDR msg,NULL,0,0
    .BREAK .IF (!eax)
    invoke TranslateMessage, ADDR msg
    invoke DispatchMessage, ADDR msg
.ENDW
```

现在，窗口已经在屏幕上了，但是只是个窗口，没有互动。因此需要不停地接收消息（或者说倾听窗口的消息）。如果GetMessage接收到了“关闭”的消息，即`WM_QUIT`，那么就停止循环，并退出；如果不是“关闭”的信息，那么还会给窗口发送一些消息。

这个循环不会一直占用CPU，空闲的时间可以交给其他任务。这就是Win16/32平台多任务协同方案的形成。

TranslateMessage 是一个实用程序函数，它接受原始键盘输入并生成放置在消息队列中的新消息 (WM_CHAR)。  带有  WM_CHAR 的消息包含按下键的 ASCII 值，这比原始键盘扫描码更容易处理。  如果您的程序不处理击键，您可以省略此调用。

DispatchMessage 将消息数据发送到负责消息所针对的特定窗口的窗口过程。

```asm
mov    eax,msg.wParam              ; return exit code in eax
ret
```

退出代码存储在 MSG 结构的 wParam 成员中。  您可以将此退出代码存储到 eax 中以将其返回给 Windows。  目前，Windows 不使用返回值，但为了安全起见还是按规则行事比较好。

```asm
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        .IF uMsg==WM_DESTROY                               ; if the user closes our window
                invoke PostQuitMessage,NULL        ; quit our application
        .ELSE
             invoke DefWindowProc,hWnd,uMsg,wParam,lParam        ; Default message processing
             ret
        .ENDIF
        xor eax,eax
        ret
WndProc endp
```

这段将是自定义窗口的重头戏：定义窗口接收到不同消息后的处理方法。`WM_DESTROY`是唯一一个必须要处理的消息，一般出现在关闭窗口的时候。此时必须调用`PostQuitMessage`函数，将`WM_QUIT`这个消息发送给windows那个不停转的循环。`WM_QUIT`将会使`GetMessage`返回FALSE，

## 加个笔刷

```
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
                local  hdc:dword
                local  brush:dword
                local  ps:PAINTSTRUCT
        
.IF uMsg==WM_DESTROY                                                ; if the user closes our window
                invoke PostQuitMessage,NULL                         ; quit our application
.elseif uMsg == WM_PAINT
                invoke CreateSolidBrush, 0ffh                       ;create red brush
                mov    brush, eax
                invoke BeginPaint, hWnd, addr ps
                mov    hdc, eax

                invoke FillRect, hdc, addr ps.rcPaint, brush
                
                invoke EndPaint, hWnd, addr ps
                invoke DeleteObject, brush
.ELSE
             invoke DefWindowProc,hWnd,uMsg,wParam,lParam        ; Default message processing
             ret
.ENDIF
                xor eax,eax
                ret
WndProc endp
```

在窗口过程函数中加点东西，其实就是笔刷相关的东西，然后把整个窗口涂成红色

## 处理点击消息

我们需要添加一个WM_LBUTTONDOWN的处理部分（对于右键与中间键，分別是WM_RBUTTONDOWN与WM_MBUTTONDOWN）．

```
.elseif uMsg == WM_LBUTTONDOWN
	invoke MessageBox,hWnd,addr ClassName,0,MB_OK or MB_ICONINFORMATION
```

每个windows消息可能拥有至多两个参数，wParam和lParam．最初wParam是16bit，lParam是32bit，但在Win32平台下两者都是32bit.不是每个消息使用了这些参数，而且每个消息以不同的方式来使用．比如，WM_CLOSE不使用它们任一个，所以你应该忽略它们．WM_COMMAND消息两个都使用，wParam有两个部分，HIWORD(wParam)中含有提示消息（如果有的话），LOWORD（wParam）含有发送消息的控件或菜单的标识号．lParam含有发送消息的控件的HWND（窗口的句柄）或者为NULL，当消息不是由控件发送．

## 结构体

masm32中有类似C语言的结构体

```
GPostn struct
    row     byte ?
    col     byte ?
GPostn ends

```

要访问结构体的属性，用`.`访问即可，例如`pos.row`

同时，也有类似数组下标访问的语法

```
.data
GPostn struct
    row     byte ?
    col     byte ?
GPostn ends

GBlock struct
    movein      GPostn  <>
    moveout     GPostn  <>
    occupancy   byte    ?
GBlock ends

gameMap         GBlock           <>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>,<>

.code 
mov gameMap[eax].movein.row,0
```



## 菜单与加速键（快捷键）

菜单的制作涉及到资源文件的运用。对于界面菜单的编写，使用ResEdit这个工具进行可视化编辑。

```
// .rc file
#include "res.h"

IDI_ICON1               ICON                    "green.ico"
IDI_ICON2               ICON                    "blue.ico"
IDI_ICON3               ICON                    "orange.ico"

//
// Menu resources
//
// LANGUAGE 0, SUBLANG_NEUTRAL
IDM_MENU1 MENU
{
    POPUP "��Ϸ����(&Q)"
    {
        MENUITEM "��ʼ��Ϸ\tC", IDM_START
        MENUITEM "��ͣ��Ϸ\tX", IDM_STOP
        MENUITEM SEPARATOR
        MENUITEM "�˳���Ϸ\tZ", IDM_QUIT
    }
    POPUP "����(&H)", HELP
    {
        MENUITEM "��Ϸ����", IDM_CTRL
        MENUITEM SEPARATOR
        MENUITEM "����", IDM_ABOUT
    }
}

//
// Accelerator resources
//
// LANGUAGE 0, SUBLANG_NEUTRAL
IDA_ACCELERATOR1 ACCELERATORS
{
    "c",IDM_START, ASCII,  ALT, NOINVERT
    "x",IDM_STOP, ASCII,  ALT, NOINVERT
    "z",IDM_QUIT, ASCII,  ALT, NOINVERT
}

```

```
// All resource identified by 3-digit number 
// icon 1XX
#define IDI_ICON1 101
#define IDI_ICON2 102
#define IDI_ICON3 103

// menu 2XX
#define IDM_MENU1 200
#define IDM_START 201
#define IDM_STOP 202
#define IDM_QUIT 203
#define IDM_CTRL 204
#define IDM_ABOUT 205

// accelerator 3XX
#define IDA_ACCELERATOR1 300
```

当用户点击菜单，或使用加速键使用菜单项时，都会向主窗口发送WM_COMMAND消息，消息有两个参数：

- wParam
    - 高位=wNotifyCode通知码。点击菜单发送的通知码为0，通过加速键发送的通知码为1
    - 低位=wID命令ID
- lParam=hwndCtl；发送WM_COMMAND的子窗口的句柄
    - 对于菜单项发送的WM_COMMAND，其lParam的值为0



