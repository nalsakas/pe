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
%define IDM_MAINMENU 1
%define IDM_FILE_EXIT 11
%define IDM_FILE_HELP 12

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
	DWORD	.lpszMenuName, IDM_MAINMENU
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

BYTE wndClass, "WindowClass",0
BYTE wndTitle, 	"NASM PE MACROS",0
DWORD hWnd
DWORD hIns
DWORD LastError

; MessageBox texts
BYTE error_title, "Error",0
BYTE help_title, "Help",0
BYTE help_text,\
	`Demo Applicaton\n\n`,\
	`Shows Capabilities of NASM PE MACROS`,0

; Alternative of "times 100h db 0"
BYTE buffer[100h]

; Entry Point
START
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
	ret
	

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
	cmp dword [ebp + 12], WM_COMMAND
	je .command

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
	
.command:
	mov eax, dword [ebp + 16]
	
	cmp ax, IDM_FILE_EXIT
	je .command_exit
	cmp ax, IDM_FILE_HELP
	je .command_help
	jmp .return
	
.command_exit:	
	push dword [VA(hWnd)]
	call [VA(DestroyWindow)]
	xor eax, eax
	jmp .return

.command_help:	
	push MB_OK | MB_ICONINFORMATION
	push VA(help_title)
	push VA(help_text)
	push dword [VA(hWnd)]
	call [VA(MessageBoxA)]
	xor eax, eax
	jmp .return


; Data Directories
RESOURCE
	TYPE RT_MENU
		ID IDM_MAINMENU
			LANG
				LEAF RVA(mainmenu), SIZEOF(mainmenu)
			ENDLANG
		ENDID
	ENDTYPE
ENDRESOURCE

MENU mainmenu
	POPUP 'File'
		MENUITEM 'Exit', IDM_FILE_EXIT
		MENUITEM 'Help', IDM_FILE_HELP
	ENDPOPUP
ENDMENU

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
	ENDLIB	
ENDIMPORT

END

; Assemble
; nasm -f bin -o window_menu.exe window_menu.asm
