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
%include '../windows.inc'

; Resource IDs
%define ID_STRTABLE 10h

PE32

; Data declarations	
WORD buffer[100]
BYTE title, "NASM PE MACROS",0

START
	
	push 0
	call [VA(GetModuleHandleA)]
	
	
	; Load string from string table index 2,
	; which is the second string of table
	
	push 100 
	push VA(buffer)
	push SID(ID_STRTABLE, 1)
	;push SID(ID_STRTABLE, 2)
	push eax
	call [VA(LoadStringA)]
	
	push MB_OK | MB_ICONINFORMATION
	push VA(title)
	push VA(buffer)
	push NULL
	call [VA(MessageBoxA)]
	
	ret

IMPORT
	LIB user32.dll
		FUNC LoadStringA
		FUNC MessageBoxA
	ENDLIB
	LIB kernel32.dll
		FUNC GetModuleHandleA
	ENDLIB
ENDIMPORT

RESOURCE
	TYPE RT_STRING
		ID ID_STRTABLE
			LANG
				LEAF RVA(strtable), SIZEOF(strtable)
			ENDLANG
		ENDID
	ENDTYPE
ENDRESOURCE

STRINGTABLE strtable
	STRING `String Table\n\nHello Word 1`
	STRING `String Table\n\nHello World 2`
ENDSTRINGTABLE

END

; Compile
; nasm -f bin -o string_table_ascii.exe 
