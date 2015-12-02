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

; Subsystem Console
%define SUBSYSTEM 3

PE32

BYTE message, "NASM PE MACROS",0Ah,0
BYTE message2, "Press Enter key to continue...",0

BYTE format, "%c",0
BYTE char

START	
	; printf
	push VA(message)
	call [VA(printf)]
	add esp, 4

	; printf
	push VA(message2)
	call [VA(printf)]
	add esp, 4
	
	; scanf
	push VA(char)
	push VA(format)
	call [VA(scanf)]
	add esp, 8
	
	ret

IMPORT
    LIB msvcrt.dll
    	FUNC scanf
        FUNC printf
    ENDLIB
ENDIMPORT

END

; Assemble
; nasm -f bin -o console_printf.exe console_printf.asm