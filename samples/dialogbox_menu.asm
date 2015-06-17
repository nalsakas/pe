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
%include '../pe.inc'
%include '../windows.inc'

; Resource IDs
%define ID_DIALOG 10 
%define ID_BUTTON_OK 11
%define ID_BUTTON_CANCEL 12
%define ID_MENU 20
%define ID_MENU_EXIT 21
%define ID_STATIC 30
%define ID_EDIT 40
PE32

; Data declerations
BYTE title, "SAMPLE",0
DWORD hIns
DWORD LastError
BYTE buffer[100h]

BYTE ok_title, "WM_COMMAND",0
BYTE ok_text, "OK button pressed :-)",0

START

WinMain:
	push ebp
	mov ebp, esp
	
	; Get module handle
	push NULL
	call [VA(GetModuleHandleA)]
	mov [VA(hIns)], eax
	
	; Load Menu
	push ID_MENU
	push dword [VA(hIns)]
	call [VA(LoadMenuA)]
	;test eax, eax
	;je .show_error
	
	; DialogBox
	push VA(DlgProc)
	push 0
	push ID_DIALOG
	push dword [VA(hIns)]
	call [VA(DialogBoxParamA)]
	
	test eax, eax
	jle .show_error
	jmp .return
	
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
	push VA(title)
	push VA(buffer)
	push NULL
	call [VA(MessageBoxA)]	
	jmp .return

; Dialog Procedure
; [ebp + 20] = lParam
; [ebp + 16] = wParam
; [ebp + 12] = uMsg
; [ebp + 8] = hDlg
DlgProc:
	push ebp
	mov ebp, esp
	
	; switch msg
	cmp dword [ebp + 12], WM_INITDIALOG
	je .init
	cmp dword [ebp + 12], WM_CLOSE
	je .close
	cmp dword [ebp + 12], WM_DESTROY
	je .destroy
	cmp dword [ebp + 12], WM_COMMAND
	je .command	
	jmp .default
	
.return:
	mov esp, ebp
	pop ebp	
	ret 16

.default:
	xor eax, eax
	jmp .return

.init:
	mov eax, 1
	jmp .return

.close:
	push 0
	push 0
	push WM_DESTROY
	push dword [ebp + 8]
	call [VA(SendMessageA)]	
	mov eax, 1
	jmp .return

.destroy:
	push 1
	push dword [ebp + 8]
	call [VA(EndDialog)]
	
	mov eax, 1
	jmp .return

.command:
	mov eax, dword [ebp + 16]
	
	; LOWORD(eax)
	cmp ax, ID_BUTTON_OK
	je .command_button_ok
	cmp ax, ID_BUTTON_CANCEL
	je .command_button_cancel
	cmp ax, ID_MENU_EXIT
	je .command_menu_exit
	jmp .default

.command_button_ok:
	push MB_ICONINFORMATION
	push VA(ok_title)
	push VA(ok_text)
	push NULL
	call [VA(MessageBoxA)]	

	mov eax, 1
	jmp .return

.command_button_cancel:
	jmp .destroy

.command_menu_exit:
	jmp .destroy


; Data Directories
IMPORT
	LIB user32.dll
		FUNC MessageBoxA
		FUNC DialogBoxParamA
		FUNC EndDialog
		FUNC SendMessageA
		FUNC LoadMenuA
	ENDLIB
	LIB kernel32.dll
		FUNC GetModuleHandleA
		FUNC GetLastError
		FUNC FormatMessageA
	ENDLIB
ENDIMPORT

RESOURCE
	TYPE RT_MENU
		ID ID_MENU
			LANG
				LEAF RVA(menu), SIZEOF(menu)
			ENDLANG
		ENDID
	ENDTYPE
	TYPE RT_DIALOG
		ID ID_DIALOG
			LANG
				LEAF RVA(dialog), SIZEOF(dialog)
			ENDLANG
		ENDID
	ENDTYPE
ENDRESOURCE

DIALOG dialog, 10, 10, 150, 100
	CAPTION 'My Dialog'
	MENU ID_MENU

	DEFPUSHBUTTON 'OK', ID_BUTTON_OK, 52, 72, 40, 16
	PUSHBUTTON 'CANCEL', ID_BUTTON_CANCEL, 96, 72, 44, 16
	EDITTEXT ID_EDIT, 36, 12, 104, 16
	CTEXT 'NAME', ID_STATIC, 4, 12, 32, 16
ENDDIALOG

MENU menu
	POPUP 'FILE'
		MENUITEM 'Exit', ID_MENU_EXIT
	ENDPOPUP
ENDMENU

END

; Compile
; nasm -f bin -o dialogbox_menu.exe
