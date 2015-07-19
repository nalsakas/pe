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

PE64

; Data declerations
BYTE title, "NASM PE MACROS",0
QWORD hIns
BYTE buffer[256]

START
	push rbp
	mov rbp, rsp
		
	; shadow stack area
	sub rsp, 48
	
	; Get module handle
	mov rcx, 0
	call [VA(GetModuleHandleA)]
	mov [VA(hIns)], rax
	
	; DialogBox
	xor rax, rax
	mov qword [rsp + 32], rax
	mov r9, VA(DlgProc)
	mov r8, 0
	mov rdx, ID_DIALOG
	mov rcx, [VA(hIns)]
	call [VA(DialogBoxParamA)]
	
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
	mov [rsp + 8], rcx
	mov [rsp + 16], rdx
	mov [rsp + 24], r8
	mov [rsp + 32], r9

	push rbp
	mov rbp, rsp
	
	; shadow stack area
	sub rsp, 32
	
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
	call [VA(EndDialog)]
	
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
	mov r8, VA(buffer)
	mov rdx, ID_EDIT
	mov rcx, [rbp + 16]
	call [VA(GetDlgItemTextA)]
	
	; MessageBox
	mov r9, 0
	mov r8, VA(title)
	mov rdx, VA(buffer)
	mov rcx, 0
	call [VA(MessageBoxA)]	

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

	DEFPUSHBUTTON "OK", ID_BUTTON, 1, 122, 208, 19
	EDITTEXT ID_EDIT, 1, 1, 208, 120, ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL
ENDDIALOG

END

; Assemble
; nasm -f bin -o 64_dialogbox.exe 64_dialogbox.asm
