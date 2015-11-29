%include "../pe.inc"

%define SUBSYSTEM 3

PE32

BYTE message, "NASM PE MACROS",0
BYTE format, "%c",0
BYTE char

START	
	; printf
	push VA(message)
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