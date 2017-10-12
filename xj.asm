.386 
.model FLAT,stdcall 
option casemap:none  
;__UNICODE__ equ


include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

include xj.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

GameInit PROTO hwnd:HWND
GamePaint PROTO hwnd:HWND

.code ;代码区  r/e  api
WinMain proc
  LOCAL  @wc: WNDCLASS
  LOCAL  @hInstance : HINSTANCE
  LOCAL  @hWnd:HWND 
  local  @msg:MSG

  ;获取模块基址
  invoke GetModuleHandle, NULL
  mov @hInstance, eax
  .if eax == 0
    mov eax, 0
    ret
  .endif 

  mov @wc.style, CS_VREDRAW or CS_HREDRAW; ;默认,垂直和水平拉伸窗口,窗口内容重新布局和绘制
  mov @wc.lpfnWndProc, CR26WindowProc;
  mov @wc.cbClsExtra, 0;  //额外内存大小
  mov @wc.cbWndExtra, 0; 
  mov eax, @hInstance
  mov @wc.hInstance, eax;//实例句柄
  mov @wc.hIcon, NULL; //图标
  mov @wc.hCursor, NULL;//光标
  mov @wc.hbrBackground, COLOR_ACTIVEBORDER;//背景画刷
  mov @wc.lpszMenuName, NULL; //菜单名
  mov @wc.lpszClassName, offset g_szClassName;//窗口类名
  invoke RegisterClass, addr @wc
  .if eax == 0
    mov eax, 0
    ret
  .endif

  invoke CreateWindowEx, 0, offset g_szClassName,  offset g_szWndName,
    WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, 
    CW_USEDEFAULT,
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    NULL, 
    NULL, 
    @hInstance, 
    NULL
  .if eax == 0
    invoke GetLastError
    mov eax, 0
    ret
  .endif
  mov @hWnd, eax

  invoke ShowWindow, @hWnd, SW_SHOW;
  invoke UpdateWindow, @hWnd;
  
  invoke GameInit, @hWnd

  ;消息循环
  .while  TRUE
   invoke PeekMessage, addr @msg, NULL, 0, 0, PM_REMOVE
   .if  eax == 1
	 invoke TranslateMessage, addr @msg 
     invoke DispatchMessage, addr @msg 
   .else
     invoke GetTickCount
	 sub eax, g_tPre
	 .if eax >= 50
	   invoke GamePaint, @hWnd
	 .endif
   .endif

    
  .endw

  mov eax, TRUE
  ret
WinMain endp

CR26WindowProc proc hwnd:HWND,  uMsg:UINT, wParam:WPARAM, lParam:LPARAM

  
  .if uMsg == WM_KEYDOWN
    ;invoke MessageBox, hwnd, offset g_szKeyDown, offset g_szTitle, MB_OK
	.if wParam == VK_UP
	  mov g_nDirection, 0
	  sub g_nY, 10
	  .if g_nY <= 10
	    mov g_nY, 10
	  .endif
	.elseif wParam == VK_DOWN
	  mov g_nDirection, 1
	  add g_nY, 10
	  .if g_nY > 460
	    mov g_nY, 460
	  .endif
	.elseif wParam == VK_LEFT
	  mov g_nDirection, 2
	  sub g_nX, 10
	  .if g_nX <= 10
	    mov g_nX, 10
	  .endif
	.elseif wParam == VK_RIGHT
	  mov g_nDirection, 3
	  add g_nX, 10
	  .if g_nX >= 725
	    mov g_nX, 725
	  .endif
	.endif
  .elseif uMsg == WM_CLOSE
    invoke DestroyWindow, hwnd
  .elseif uMsg == WM_DESTROY
    invoke PostQuitMessage, 0
  .endif

  invoke DefWindowProc, hwnd, uMsg, wParam, lParam;
  ret
CR26WindowProc endp

GameInit proc hwnd:HWND
  local @bmp: HBITMAP
  
  invoke GetDC, hwnd
  mov g_hdc, eax

  invoke CreateCompatibleDC, g_hdc
  mov g_mdc, eax
  
  invoke CreateCompatibleDC, g_hdc
  mov g_bufdc, eax
  
  invoke CreateCompatibleBitmap, g_hdc, WINDOW_WIDTH, WINDOW_HEIGHT
  mov @bmp, eax
  
  ;设定人物位置和方向
  mov g_nX, 150
  mov g_nY, 350
  mov g_nDirection, 3
  mov g_nNum, 0
  
  invoke SelectObject, g_mdc, @bmp
  
  ;加载图片
  invoke LoadImage, NULL, offset g_szGo1, IMAGE_BITMAP, 480, 216, LR_LOADFROMFILE
  mov g_hSpriteUp, eax
  invoke LoadImage, NULL, offset g_szGo2, IMAGE_BITMAP, 480, 216, LR_LOADFROMFILE
  mov g_hSpriteDown, eax
  invoke LoadImage, NULL, offset g_szGo3, IMAGE_BITMAP, 480, 216, LR_LOADFROMFILE
  mov g_hSpriteLeft, eax
  invoke LoadImage, NULL, offset g_szGo4, IMAGE_BITMAP, 480, 216, LR_LOADFROMFILE
  mov g_hSpriteRight, eax
  invoke LoadImage, NULL, offset g_szBg, IMAGE_BITMAP, WINDOW_WIDTH, WINDOW_HEIGHT, LR_LOADFROMFILE
  mov g_hBackGround, eax
  
  invoke GamePaint, hwnd
  
  ret
GameInit endp

GamePaint proc hwnd:HWND
  local @framecount:DWORD
  local @framecoord:DWORD

  invoke SelectObject, g_bufdc, g_hBackGround
  invoke BitBlt, g_mdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_bufdc, 0, 0, SRCCOPY
  
  .if g_nDirection == 0
    invoke SelectObject, g_bufdc, g_hSpriteUp
  .endif
  
  .if g_nDirection == 1
    invoke SelectObject, g_bufdc, g_hSpriteDown
  .endif
  
  .if g_nDirection == 2
    invoke SelectObject, g_bufdc, g_hSpriteLeft
  .endif
  
  .if g_nDirection == 3
    invoke SelectObject, g_bufdc, g_hSpriteRight
  .endif
  
  mov eax, g_nNum
  mov @framecount, eax
  mov @framecoord, 0
  
  .while @framecount > 0
	sub @framecount, 1
	add @framecoord, 60
  .endw
  
  invoke BitBlt, g_mdc, g_nX, g_nY, 60, 108, g_bufdc, @framecoord, 108, SRCAND
  invoke BitBlt, g_mdc, g_nX, g_nY, 60, 108, g_bufdc, @framecoord, 0, SRCPAINT
  
  invoke BitBlt, g_hdc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, g_mdc, 0, 0, SRCCOPY
  
  invoke GetTickCount
  mov g_tPre, eax
  
  add g_nNum, 1
  
  .if g_nNum >= 8
    mov g_nNum, 0
  .endif
  

  ret
GamePaint endp

end WinMain
