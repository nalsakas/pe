; NASM PE MACROS Header
%include '../pe.inc'

; Optional windows.h for Windows constants
%include '../windows.inc'

;  Resource constansts and define's here

; Application type
; PE64, PE32, DLL64, DLL32
PE32

; Data declarations here
; dd, db etc.


; Entry point
START

; instructions


; data directories here
; IMPORT/EXPORT/RESOURCE/MENU/DIALOG/BITMAP etc.


; End of application
END

; Assemble
; nasm -f bin -o filename.exe filename.asm
