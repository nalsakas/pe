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

DLL64

; Data declarations here
BYTE Title, "NASM PE MACROS",0
BYTE Text, "64-bit exports works!",0

START
	mov rax, 1
	ret
	
MyExport:
; instructions

	push rbp
	mov rbp, rsp

	; Fastcall callling convention
	mov r9, 0
	mov r8, VA(Title)
	mov rdx, VA(Text)
	mov rcx, 0
	call [VA(MessageBoxA)]		

	mov rsp, rbp
	pop rbp
	ret

; data directories here
IMPORT
	LIB user32.dll
		FUNC MessageBoxA
	ENDLIB
ENDIMPORT

EXPORT 64_exporter.dll
	FUNC MyExport
ENDEXPORT

END
