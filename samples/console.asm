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

; override GUI
; subsystem console
%define SUBSYSTEM 3

PE32
    DWORD std_out
    DWORD std_in
    DWORD i
    DWORD mode
    
    BYTE message, "Hello World!",0
    message_size equ $ - message
    
    BYTE message2, 0xA,"Press any key to continue...",0
    message2_size equ $ - message2
    
    BYTE buffer
    
START
	; GetStdHandle OUTPUT
	push	STD_OUTPUT_HANDLE
    call	[VA(GetStdHandle)]
    mov		[VA(std_out)], eax
    
    ; GetStdHandle INPUT
	push	STD_INPUT_HANDLE
	call	[VA(GetStdHandle)]
    mov		[VA(std_in)], eax

	; WriteConsoleA
	push 	NULL
	push	VA(i)
	push	message_size
	push	VA(message)
	push	dword [VA(std_out)]
	call	[VA(WriteConsoleA)]
	
	; WriteConsoleA
	push 	NULL
	push	VA(i)
	push	message2_size
	push	VA(message2)
	push	dword [VA(std_out)]
	call	[VA(WriteConsoleA)]

	; Update console mode
	; GetConsoleMode
	push	VA(mode)
	push	dword [VA(std_in)]
	call	[VA(GetConsoleMode)]
	
	; Disable line input
	; No need to press enter key after input
	mov		eax, ENABLE_LINE_INPUT
	not		eax
	and		[VA(mode)], eax
	
	; SetConsoleMode
	push	dword [VA(mode)]
	push	dword [VA(std_in)]
	call	[VA(SetConsoleMode)]
	
	; ReadConsoleA
	; get pressed key
	push 	NULL
	push	VA(i)
	push	1
	push	VA(buffer)
	push	dword [VA(std_in)]
	call	[VA(ReadConsoleA)]	
	
    ret

IMPORT
	LIB kernel32.dll
		FUNC GetStdHandle
		FUNC AllocConsole
		FUNC WriteConsoleA
		FUNC ReadConsoleA
		FUNC SetConsoleMode
		FUNC GetConsoleMode
	ENDLIB
ENDIMPORT

END

; Assemble
; nasm -f bin -o console.exe console.asm