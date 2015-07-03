;##############################################################################
; Author : Seyhmus AKASLAN
; Contact: nalsakas@gmail.com
;
; NASM PE Macros Examples
; Shows example usage of PE macros
; Copyright (C) 2015  Seyhmus AKASLAN
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
; MA  02110-1301, USA.
;##############################################################################
%include "../pe.inc"
%include "../windows.inc"

; Resource ID's
%define ID_BITMAP_1 1

; Create 32-bit Windows Executable
PE32

; Data Declarations
WNDCLASSEX:
	DWORD	.cbSize, SIZEOF(WNDCLASSEX)
	DWORD	.style, CS_HREDRAW|CS_VREDRAW
	DWORD	.lpfnWndProc, VA(WinProc)
	DWORD	.cbClsExtra
	DWORD	.cbWndExtra
	DWORD	.hInstance
	DWORD	.hIcon
	DWORD	.hCursor
	DWORD	.hbrBackground, COLOR_WINDOW
	DWORD	.lpszMenuName
	DWORD	.lpszClassName, VA(wndClass)
	DWORD	.hIconSm
WNDCLASSEX_end:

MSG:
	DWORD	hwnd
	DWORD	message
	WORD	wParam
	WORD	lParam
	DWORD	time
	DWORD	pt
MSG_end:

PAINTSTRUCTURE:
	DWORD  hdc;
	BYTE fErase;
	DWORD rcPaint[4];
	BYTE fRestore;
	BYTE fIncUpdate;
	BYTE rgbReserved[32];
PAINTSTRUCTURE_end:


BYTE wndClass, "WindowClass",0
BYTE wndTitle, 	"NASM PE MACROS",0
DWORD hIns
DWORD hWnd
DWORD LastError
DWORD hDC
DWORD hBitmap
DWORD MemoryDC
BYTE buffer[100]

; Entry Point
START

WinMain:
	push ebp
	mov ebp, esp
	
	; Get module handle
	push NULL
	call [VA(GetModuleHandleA)]
	mov [VA(WNDCLASSEX.hInstance)], eax
	mov [VA(hIns)], eax
	
	; Load Cursor
	push IDC_ARROW
	push NULL
	call [VA(LoadCursorA)]
	mov [VA(WNDCLASSEX.hCursor)], eax
	
	; Load Icon
	push IDI_APPLICATION
	push NULL
	call [VA(LoadIconA)]
	mov [VA(WNDCLASSEX.hIcon)], eax	
	
	; Register Class
	push VA(WNDCLASSEX)
	call [VA(RegisterClassExA)]
	
	cmp eax, 0
	je	.show_error
	
	; Create Window
	push NULL
	push dword [VA(hIns)]
	push NULL
	push NULL
	push 300
	push 300
	push 200
	push 200
	push WS_OVERLAPPEDWINDOW|WS_VISIBLE
	push VA(wndTitle)
	push VA(wndClass)
	push NULL	
	call [VA(CreateWindowExA)]
	mov [VA(hWnd)], eax
	
	cmp eax, 0
	je .show_error
	
	; Show Window
	push dword [ebp + 20]
	push dword [VA(hWnd)]
	call [VA(ShowWindow)]

.msg_loop:
	push NULL
	push NULL
	push NULL
	push VA(MSG)
	call [VA(GetMessageA)]
	
	cmp eax, 0
	je .msg_loop_end
	
	push VA(MSG)
	call [VA(TranslateMessage)]
	
	push VA(MSG)
	call [VA(DispatchMessageA)]
	jmp .msg_loop
.msg_loop_end:

.return:
	mov esp, ebp
	pop ebp
	ret 16
	
; Show Error Message and Exit
.show_error:
	call [VA(GetLastError)]
	mov [VA(LastError)], eax
	
	push NULL
	push 200h
	push VA(buffer)
	push NULL
	push eax
	push NULL
	push FORMAT_MESSAGE_FROM_SYSTEM
	call [VA(FormatMessageA)]
	
	push MB_ICONERROR
	push VA(wndTitle)
	push VA(buffer)
	push NULL
	call [VA(MessageBoxA)]
	jmp .return

; Window Precedure
; [ebp + 20] = lParam
; [ebp + 16] = wParam
; [ebp + 12] = Msg
; [ebp + 8] = hWnd
WinProc:
	push ebp
	mov ebp, esp
	
	; switch msg 
	cmp dword [ebp + 12], WM_DESTROY
	je .destroy
	cmp dword [ebp + 12], WM_PAINT
	je .paint

.defproc:
	push dword [ebp + 20]
	push dword [ebp + 16]
	push dword [ebp + 12]
	push dword [ebp + 8]
	call [VA(DefWindowProcA)]

.return:
	mov esp, ebp
	pop ebp
	ret 16
	
.destroy:
	push NULL
	call [VA(PostQuitMessage)]
	xor eax, eax
	jmp .return

.paint:
	; BeginPaint
	push VA(PAINTSTRUCTURE)
	push dword [ebp + 8]
	call [VA(BeginPaint)]
	mov [VA(hDC)], eax
	
	; LoadBitmap
	push ID_BITMAP_1
	push dword [VA(hIns)]
	call [VA(LoadBitmapA)]
	mov [VA(hBitmap)], eax
	
	; CreateCompatibleDC
	push dword [VA(hDC)]
	call [VA(CreateCompatibleDC)]
	mov [VA(MemoryDC)], eax
	
	; SelectObject
	push dword [VA(hBitmap)]
	push dword [VA(MemoryDC)]
	call [VA(SelectObject)]
	
	; BitBlit
	push SRCCOPY
	push 0
	push 0
	push dword [VA(MemoryDC)]
	push 300
	push 300
	push 10
	push 10
	push dword [VA(hDC)]
	call [VA(BitBlt)]

	; DeleteDC
	push dword [VA(MemoryDC)]
	call [VA(DeleteDC)]
	
	; DeleteObject
	push dword [VA(hBitmap)]
	call [VA(DeleteObject)]
	
	; EndPaint
	push VA(PAINTSTRUCTURE)
	push dword [ebp + 8]
	call [VA(EndPaint)]
	
	xor eax, eax
	jmp .return
	

; Data Directories
RESOURCE
	TYPE RT_BITMAP
		ID ID_BITMAP_1
			LANG
				LEAF RVA(bitmap1), SIZEOF(bitmap1)
			ENDLANG
		ENDID
	ENDTYPE
ENDRESOURCE

BITMAP bitmap1, 'bitmap.bmp'

IMPORT
	LIB kernel32.dll
		FUNC ExitProcess
		FUNC GetModuleHandleA
		FUNC GetLastError
		FUNC FormatMessageA
	ENDLIB
	
	LIB user32.dll
		FUNC MessageBoxA
		FUNC LoadCursorA
		FUNC LoadIconA
		FUNC LoadMenuA
		FUNC RegisterClassExA
		FUNC CreateWindowExA
		FUNC ShowWindow
		FUNC GetMessageA
		FUNC TranslateMessage
		FUNC DispatchMessageA
		FUNC DefWindowProcA
		FUNC PostQuitMessage
		FUNC DestroyWindow
		FUNC BeginPaint
		FUNC EndPaint
		FUNC LoadBitmapA
	ENDLIB
	
	LIB gdi32.dll
		FUNC CreateCompatibleDC
		FUNC BitBlt
		FUNC DeleteDC
		FUNC DeleteObject
		FUNC SelectObject
	ENDLIB
ENDIMPORT

END

; Compile
; nasm -f bin -o window_menu.exe