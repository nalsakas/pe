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

%define ID_ACCELERATOR 20
%define ID_ACTION_SHIFT_A 21
%define ID_ACTION_CONTROL_F5 22
%define ID_ACTION_ALT_ENTER 23

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
	DWORD	.hwnd
	DWORD	.message
	WORD	.wParam
	WORD	.lParam
	DWORD	.time
	DWORD	.pt
MSG_end:

BYTE wndClass, "WindowClass",0
BYTE wndTitle, 	"NASM PE MACROS",0
DWORD hWnd
DWORD hIns
DWORD hAccel
DWORD LastError

; MessageBox texts
BYTE title, "NASM PE MACROS", 0
BYTE text, "HELP menu item pressed", 0
BYTE text_shift_a, "Shift + A keys pressed.", 0
BYTE text_control_f5, "Control + F5 keys pressed.", 0
BYTE text_alt_enter, "Alt + Enter keys pressed.", 0

; Alternative of "times 100h db 0"
BYTE buffer[100h]

; Entry Point
START

; [ebp + 20] = nShowCmd
; [ebp + 16] = lpCmdLine
; [ebp + 12] = hPrevInst
; [ebp + 8] = hInst
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

	; Load Accelerators
	push ID_ACCELERATOR
	push dword [VA(hIns)]
	call [VA(LoadAcceleratorsA)]
	test eax, eax
	je .show_error
	mov [VA(hAccel)], eax
	
.msg_loop:
	push NULL
	push NULL
	push NULL
	push VA(MSG)
	call [VA(GetMessageA)]
	
	cmp eax, 0
	je .msg_loop_end
	jl .show_error
	
	; Translate Accelerator Messages
	push VA(MSG)
	push dword [VA(hAccel)]
	push dword [VA(hWnd)]
	call [VA(TranslateAcceleratorA)]
	test eax, eax
	jne .next
	
	push VA(MSG)
	call [VA(TranslateMessage)]
	
	push VA(MSG)
	call [VA(DispatchMessageA)]
.next:
	jmp .msg_loop
.msg_loop_end:

.return:
	mov eax, dword [VA(MSG.wParam)]
	mov esp, ebp
	pop ebp
	ret
	
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
	push VA(title)
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
	
	; LOWORD (wParam)
	cmp ax, IDM_FILE_EXIT
	je .command_exit
	cmp ax, IDM_FILE_HELP
	je .command_help
	cmp ax, ID_ACTION_SHIFT_A
	je .command_shift_a
	cmp ax, ID_ACTION_CONTROL_F5
	je .command_control_f5	
	cmp ax, ID_ACTION_ALT_ENTER
	je .command_alt_enter
	jmp .return
	
.command_exit:	
	push dword [VA(hWnd)]
	call [VA(DestroyWindow)]
	xor eax, eax
	jmp .return

.command_help:	
	push MB_OK | MB_ICONINFORMATION
	push VA(title)
	push VA(text)
	push dword [VA(hWnd)]
	call [VA(MessageBoxA)]
	xor eax, eax
	jmp .return

.command_shift_a:
	push MB_OK | MB_ICONINFORMATION
	push VA(title)
	push VA(text_shift_a)
	push dword [VA(hWnd)]
	call [VA(MessageBoxA)]
	xor eax, eax
	jmp .return	
	
.command_control_f5:
	push MB_OK | MB_ICONINFORMATION
	push VA(title)
	push VA(text_control_f5)
	push dword [VA(hWnd)]
	call [VA(MessageBoxA)]
	xor eax, eax
	jmp .return

.command_alt_enter:
	push MB_OK | MB_ICONINFORMATION
	push VA(title)
	push VA(text_alt_enter)
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
	TYPE RT_ACCELERATOR
		ID ID_ACCELERATOR
			LANG
				LEAF RVA(accelerator), SIZEOF(accelerator)
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


ACCELERATORTABLE accelerator
	ACCELERATOR 'A', ID_ACTION_SHIFT_A, FSHIFT
	ACCELERATOR VK_F5, ID_ACTION_CONTROL_F5, FCONTROL | FVIRTKEY
	ACCELERATOR VK_RETURN, ID_ACTION_ALT_ENTER, FALT | FVIRTKEY
	; default key is shift, accelerator for menu item
	ACCELERATOR 'H', IDM_FILE_HELP
ENDACCELERATORTABLE

IMPORT
	LIB kernel32.dll
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
		FUNC LoadAcceleratorsA
		FUNC TranslateAcceleratorA
	ENDLIB	
ENDIMPORT

END

; Compile
; nasm -f bin -o accelerator.exe
