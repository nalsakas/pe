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

PE64

START
	
	;Align stack to 16 bytes
	push rbp
	
	; Call exported function of library
	; Function doesn't take any parameters.
	call [VA(MyExport)]
	
	pop rbp
	ret

IMPORT
	LIB 64_exporter.dll
		FUNC MyExport
	ENDLIB
ENDIMPORT

END

; Assemble
; nasm -f bin -o 64_importer.exe 64_importer.asm