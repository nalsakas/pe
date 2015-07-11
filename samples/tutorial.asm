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

PE32

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
	call [VA(GetModuleHandleA)]
	mov [VA(hIns)], eax

	; DialogBox
	push 0
	push VA(DlgProc)
	push 0
	push ID_DIALOG
	push dword [VA(hIns)]
	call [VA(DialogBoxParamA)]

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
	call [VA(GetDlgItem)]
	mov [VA(hStatic)], eax
	
	; LoadBitmap
	push ID_BITMAP
	push dword [VA(hIns)]
	call [VA(LoadBitmapA)]
	mov [VA(hBitmap)], eax
	
	; GetObject
	push VA(SBITMAP)
	push SIZEOF(SBITMAP)
	push dword [VA(hBitmap)]
	call [VA(GetObjectA)]
	
	mov eax, 1	
	jmp .return

.paint:
	; DC Static
	push dword [VA(hStatic)]
	call [VA(GetDC)]
	mov [VA(hDCStatic)], eax
	
	push VA(SRECT)
	push dword [VA(hStatic)]
	call [VA(GetClientRect)]
	
	; First MemDC
	push dword [VA(hDCStatic)]
	call [VA(CreateCompatibleDC)]
	mov [VA(hDCMem1)], eax
	
	push dword [VA(hBitmap)]
	push dword [VA(hDCMem1)]
	call [VA(SelectObject)]

	; Second MemDC
	push dword [VA(hDCStatic)]
	call [VA(CreateCompatibleDC)]
	mov [VA(hDCMem2)], eax	
	
	push dword [VA(SRECT.bottom)]
	push dword [VA(SRECT.right)]
	push dword [VA(hDCStatic)]
	call [VA(CreateCompatibleBitmap)]
	mov [VA(hBitmapMem)], eax
	
	push dword [VA(hBitmapMem)]
	push dword [VA(hDCMem2)]
	call [VA(SelectObject)]
	
	; StretchBlit
	push SRCCOPY
	push dword [VA(SBITMAP.bmHeight)]
	push dword [VA(SBITMAP.bmWidth)]
	push 0
	push 0
	push dword [VA(hDCMem1)]
	push dword [VA(SRECT.bottom)]
	push dword [VA(SRECT.right)]
	push 0
	push 0
	push dword [VA(hDCMem2)]
	call [VA(StretchBlt)]
	
	; BitBlit
	push SRCCOPY
	push 0
	push 0
	push dword [VA(hDCMem2)]
	push dword [VA(SRECT.bottom)]
	push dword [VA(SRECT.right)]
	push 0
	push 0
	push dword [VA(hDCStatic)]
	call [VA(BitBlt)]
	
	; Cleanup
	push dword [VA(hBitmapMem)]
	call [VA(DeleteObject)]
	
	push dword [VA(hDCMem2)]
	call [VA(DeleteDC)]
	
	push dword [VA(hDCMem1)]
	call [VA(DeleteDC)]

	push dword [VA(hDCStatic)]
	push dword [VA(hStatic)]
	call [VA(ReleaseDC)]
	
	mov eax, 1
	jmp .return

.close:
	; Free Resources
	push dword [VA(hBitmap)]
	call [VA(DeleteObject)]
	
	; EndDialog
	push 1
	push dword [ebp + 8]
	call [VA(EndDialog)]

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
