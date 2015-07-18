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
%define ID_BUTTON 11
%define ID_EDIT 20

PE64 FLAT

; Data declerations
BYTE title, "NASM PE MACROS",0
QWORD hIns
BYTE buffer[256]

START

	push rbp
	mov rbp, rsp
	
	; shadow stack area
	sub rsp, 40
	
	; Get module handle
	mov rcx, 0
	call [GetModuleHandleA]
	mov [hIns], rax
	
	; DialogBox
	mov r9, DlgProc
	mov r8, 0
	mov rdx, ID_DIALOG
	mov rcx, [hIns]
	call [DialogBoxParamA]
	
.return:
	mov rsp, rbp
	pop rbp
	ret

; Dialog Procedure
; [r9] = lParam
; [r8] = wParam
; [rdx] = uMsg
; [rcx] = hDlg
DlgProc:
	; save parameters on shadow
	mov qword [rsp + 8], rcx
	mov qword [rsp + 16], rdx
	mov qword [rsp + 24], r8
	mov qword [rsp + 32], r9

	push rbp
	mov rbp, rsp
	
	; shadow stack area
	sub rsp, 40
	
	; switch msg
	cmp qword [rbp + 24], WM_CLOSE
	je .close
	cmp qword [rbp + 24], WM_COMMAND
	je .command
	cmp qword [rbp + 24], WM_INITDIALOG
	je .initdialog

.default:
	xor rax, rax
	
.return:
	mov rsp, rbp
	pop rbp
	ret

.initdialog:
	mov eax, 1
	jmp .return

.close:
	mov rdx, 1
	mov rcx, [rbp + 16]
	call [EndDialog]
	
	mov rax, 1
	jmp .return

.command:
	mov rax, [rbp + 32]
	cmp ax, ID_BUTTON
	je .command_button
	jmp .default

.command_button:
	; GetDlgItemText
	mov r9, 255
	mov r8, buffer
	mov rdx, ID_EDIT
	mov rcx, [rbp + 16]
	call [GetDlgItemTextA]
	
	; MessageBox
	mov r9, 0
	mov r8, title
	mov rdx, buffer
	mov rcx, 0
	call [MessageBoxA]	

	mov rax, 1
	jmp .return


; Data Directories
IMPORT
	LIB user32.dll
		FUNC MessageBoxA
		FUNC DialogBoxParamA
		FUNC EndDialog
		FUNC SendMessageA
		FUNC GetDlgItemTextA
	ENDLIB
	LIB kernel32.dll
		FUNC GetModuleHandleA
		FUNC LoadLibraryA
		FUNC FreeLibrary
	ENDLIB
ENDIMPORT

RESOURCE
	TYPE RT_DIALOG
		ID ID_DIALOG
			LANG
				LEAF RVA(dialog), SIZEOF(dialog)
			ENDLANG
		ENDID
	ENDTYPE
ENDRESOURCE

DIALOG dialog, 0, 0, 210, 142
	STYLE DS_CENTER
	CAPTION "NASM PE MACROS"

	DEFPUSHBUTTON "OK", ID_BUTTON, 2, 122, 208, 18
	EDITTEXT ID_EDIT, 2, 2, 208, 120, ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL
ENDDIALOG

END

; Assemble
; nasm -f bin -o 64_dialogbox.exe 64_dialogbox.asm
