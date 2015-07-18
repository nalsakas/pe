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

; Resource constanst
%define ID_BITMAP 1
%define ID_STATIC 2
%define ID_DIALOG 3

; windows.h constants
%define STM_SETIMAGE  0x0172
%define SS_BITMAP  0x0000000E

PE32 FLAT

; Data declarations
DWORD hIns
DWORD hStatic
DWORD hDCMem1
DWORD hDCMem2
DWORD hDCStatic
DWORD hBitmap
DWORD hBitmapMem

; Windows Structures
SRECT:
	DWORD .left
	DWORD .top
	DWORD .right
	DWORD .bottom
SRECT_end:

SBITMAP:
	DWORD .bmType;
	DWORD .bmWidth;
	DWORD .bmHeight;
	DWORD .bmWidthBytes;
	WORD .bmPlanes;
	WORD .bmBitsPixel;
	DWORD .bmBits;
SBITMAP_end:

START
	push ebp
	mov ebp, esp

	; Get module handle
	push NULL
	call [GetModuleHandleA]
	mov [hIns], eax

	; DialogBox
	push 0
	push DlgProc
	push 0
	push ID_DIALOG
	push dword [hIns]
	call [DialogBoxParamA]

	; return
	mov esp, ebp
	pop ebp
	ret

; Dialog Procedure
; [ebp + 20] = lParam
; [ebp + 16] = wParam
; [ebp + 12] = uMsg
; [ebp + 8] = hDlg
DlgProc:
	push ebp
	mov ebp, esp

	; switch msg
	cmp dword [ebp + 12], WM_PAINT
	je .paint
	cmp dword [ebp + 12], WM_INITDIALOG
	je .init
	cmp dword [ebp + 12], WM_CLOSE
	je .close
	
	; default
	xor eax, eax

.return:
	mov esp, ebp
	pop ebp	
	ret 16

.init:
	; Child window handle
	push ID_STATIC
	push dword [ebp + 8]
	call [GetDlgItem]
	mov [hStatic], eax
	
	; LoadBitmap
	push ID_BITMAP
	push dword [hIns]
	call [LoadBitmapA]
	mov [hBitmap], eax
	
	; GetObject
	push SBITMAP
	push SIZEOF(SBITMAP)
	push dword [hBitmap]
	call [GetObjectA]
	
	mov eax, 1	
	jmp .return

.paint:
	; DC Static
	push dword [hStatic]
	call [GetDC]
	mov [hDCStatic], eax
	
	push SRECT
	push dword [hStatic]
	call [GetClientRect]
	
	; First MemDC
	push dword [hDCStatic]
	call [CreateCompatibleDC]
	mov [hDCMem1], eax
	
	push dword [hBitmap]
	push dword [hDCMem1]
	call [SelectObject]

	; Second MemDC
	push dword [hDCStatic]
	call [CreateCompatibleDC]
	mov [hDCMem2], eax	
	
	push dword [SRECT.bottom]
	push dword [SRECT.right]
	push dword [hDCStatic]
	call [CreateCompatibleBitmap]
	mov [hBitmapMem], eax
	
	push dword [hBitmapMem]
	push dword [hDCMem2]
	call [SelectObject]
	
	; StretchBlit
	push SRCCOPY
	push dword [SBITMAP.bmHeight]
	push dword [SBITMAP.bmWidth]
	push 0
	push 0
	push dword [hDCMem1]
	push dword [SRECT.bottom]
	push dword [SRECT.right]
	push 0
	push 0
	push dword [hDCMem2]
	call [StretchBlt]
	
	; BitBlit
	push SRCCOPY
	push 0
	push 0
	push dword [hDCMem2]
	push dword [SRECT.bottom]
	push dword [SRECT.right]
	push 0
	push 0
	push dword [hDCStatic]
	call [BitBlt]
	
	; Cleanup
	push dword [hBitmapMem]
	call [DeleteObject]
	
	push dword [hDCMem2]
	call [DeleteDC]
	
	push dword [hDCMem1]
	call [DeleteDC]

	push dword [hDCStatic]
	push dword [hStatic]
	call [ReleaseDC]
	
	mov eax, 1
	jmp .return

.close:
	; Free Resources
	push dword [hBitmap]
	call [DeleteObject]
	
	; EndDialog
	push 1
	push dword [ebp + 8]
	call [EndDialog]

	mov eax, 1
	jmp .return
	

; Import data directory
IMPORT
	LIB user32.dll
		FUNC DialogBoxParamA
		FUNC EndDialog
		FUNC SendDlgItemMessageA
		FUNC LoadBitmapA
		FUNC GetDlgItem
		FUNC GetDC
		FUNC ReleaseDC
		FUNC GetClientRect
	ENDLIB
	LIB kernel32.dll
		FUNC GetModuleHandleA
	ENDLIB
	LIB gdi32.dll
		FUNC DeleteObject
		FUNC SelectObject
		FUNC GetObjectA
		FUNC CreateCompatibleDC
		FUNC CreateCompatibleBitmap
		FUNC StretchBlt
		FUNC BitBlt
		FUNC DeleteDC
	ENDLIB	
ENDIMPORT

; Resource data directory
RESOURCE
	TYPE RT_BITMAP
		ID ID_BITMAP
			LANG
				LEAF RVA(bitmap), SIZEOF(bitmap)	
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

; Resources
BITMAP bitmap, 'bitmap.bmp'

DIALOG dialog, 10, 10, 200, 200
	STYLE DS_CENTER
	CAPTION 'NASM PE MACROS'
	FONT 8, "Tahoma"
	
	CONTROL '', ID_STATIC, 'STATIC', 0, 0, 200, 200, SS_BITMAP
ENDDIALOG

; End of Application
END

; Assemble
; nasm -f bin -o tutorial.exe tutorial.asm