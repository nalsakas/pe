;##############################################################################
; Author : Seyhmus AKASLAN
; Contact: nalsakas@gmail.com
;
; NASM PE Macro Sets
; Used for direct output to executable file using only assembler.  
; Copyright (C) 2015  Seyhmus AKASLAN

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

;##############################################################################
; Utility Functions and Global Definitions
; ROUNDVS(x,y) rounds size to the multiple of Section Alignment
; ROUNDFS(x,y) rounds size to the multiple of File Alignment
;##############################################################################
; Section Alignment is above or equal to the File Alignment
%define SALIGN 1000h

; File Alignment, Can't be smaller than 200h
%define FALIGN 200h 

; Image Base
%define IMAGEBASE 400000h

; Section Name
; max 8 chars
%define SECTIONNAME 'nasmrocks'

; Subsystem
; GUI = 1, CONSOLE = 2, NATIVE = 3
%define SUBSYSTEM 1

; Round Functions
%define ROUNDVS(x,y) ((x - y)/SALIGN + 1)*SALIGN
%define ROUNDFS(x,y) ((x - y)/FALIGN + 1)*FALIGN

; VA (Virtual Address) function
%define VA(x)	x - %$SECTION_START_1 + ROUNDVS(%$IMAGE_SECTION_HEADER_END, %$IMAGE_DOS_HEADER) + IMAGEBASE

; RVA (Relative Virtual Address) function
%define RVA(x) VA(x) - IMAGEBASE 

; SIZEOF()
%define SIZEOF(x) x%+_end  - x 

; LOWORD macro, useful for resources
;%define LOWORD(x)  (x & 0x0000FFFF)

; HIWORD macro, useful for resources
;%define HIWORD(x)  (x & 0xFFFF0000) >> 16

; MAKEINTRESOURCE, useful for resources
;%define MAKEINTRESOURCE(x) LOWORD(x)

;##############################################################################
; DEBUG Macros
; 
; Used internally to testing purposes
; To test variable value inside pe.inc use bug() function to output its value
;##############################################################################
%macro DEBUG 0
	%define %$DEBUG 1
%endmacro

%macro dbgmsg 1+
	%ifdef %$DEBUG
		%warning %1
	%endif
%endmacro

; Debug Messages
%define bug(x) dbgmsg x
;##############################################################################
; PE MACROS
;
; Sample Usage:
; PE32 or DLL32 or PE64 or DLL64
;
; Data definitions
; label: db 'xxx'
;
; START
;   instructions
;   etc.
;
; Data Directories Definitions
; IMPORT / ENDIMPORT
; EXPORT / ENDEXPORT
; RESOURCE / ENDRESOURCE
; END
;
;##############################################################################
%macro PE32 0
	BITS 32
	%push pe32
	
	IMAGE_DOS_HEADER
	IMAGE_NT_SIGNATURE
	IMAGE_FILE_HEADER
	IMAGE_OPTIONAL_HEADER
	IMAGE_DATA_DIRECTORY
	IMAGE_SECTION_HEADER
%endmacro

%macro DLL32 0
	BITS 32
	%push dll32
	
	; Override Global Image Base
	%define IMAGEBASE 10000000h
	
	IMAGE_DOS_HEADER
	IMAGE_NT_SIGNATURE
	IMAGE_FILE_HEADER
	IMAGE_OPTIONAL_HEADER
	IMAGE_DATA_DIRECTORY
	IMAGE_SECTION_HEADER
%endmacro

%macro START 0
	%$ENTRY_POINT:
%endmacro

%macro END 0
	%ifndef %$IMPORT
		%$IMAGE_IMPORT_DESCRIPTOR_START:
		%$IMAGE_IMPORT_DESCRIPTOR_END:
	%endif

	%ifndef %$EXPORT
		%$IMAGE_EXPORT_DIRECTORY_START:
		%$IMAGE_EXPORT_DIRECTORY_END:
	%endif
	
	%ifndef %$RESOURCE
		%$IMAGE_RESOURCE_DIRECTORY_START:
		%$IMAGE_RESOURCE_DIRECTORY_END:
	%endif
	
	;ALIGN
	times (FALIGN - (($ - %$SECTION_START_1) % FALIGN)) db 0
	
	%$SECTION_END_1:
	%$IMAGE_END:
	%pop
 	;pe32, dll32, etc.
%endmacro

;##############################################################################
; IMPORT TABLE Macros
; IMPORT/ENDIMPORT
; USAGE
; IMPORT
;   LIB user32.dll
;     FUNC FunctionName
;   ENDLIB
;
;   LIB kernel32.dll
;     FUNC FunctionName
;   ENDLIB
; ENDIMPORT
;##############################################################################
%macro IMPORT 0
	;ALIGN DWORD
	;times (4 - (($ - %$IMAGE_DOS_HEADER) % 4)) db 0
	
	%assign %$IMPORT 1
%endmacro

%macro LIB 1
	; Count number of LIBs
	%ifnum %$LIBRARY_COUNT
		%assign %$LIBRARY_COUNT %$LIBRARY_COUNT + 1
	%else
		%assign %$LIBRARY_COUNT 1
	%endif
	
	; Get name of LIB
	%define %$LIBRARY_NAME_%[%$LIBRARY_COUNT] %1
%endmacro

%macro ENDLIB 0
	%ifnum %$FUNCTION_COUNT
		%xdefine %$FUNCTION_COUNT_%[%$LIBRARY_COUNT] %$FUNCTION_COUNT
		bug( %?? '%$FUNCTION_COUNT_%[%$LIBRARY_COUNT]' %$FUNCTION_COUNT_%[%$LIBRARY_COUNT] )
		
		%assign %$FUNCTION_COUNT 0
		bug( %?? '%$FUNCTION_COUNT_%[%$LIBRARY_COUNT]' %$FUNCTION_COUNT_%[%$LIBRARY_COUNT] )
	%endif
%endmacro

%macro FUNC 1
	%ifdef %$IMPORT
		%if %$IMPORT == 1
			; Count number of functions for each lib	
			%ifnum %$FUNCTION_COUNT
				%assign %$FUNCTION_COUNT %$FUNCTION_COUNT + 1
			%else
				%assign %$FUNCTION_COUNT 1
			%endif

			%define %$FUNCTION_NAME_%[%$LIBRARY_COUNT]%[%$FUNCTION_COUNT] %1

			bug( %?? '%$FUNCTION_NAME_%[%$LIBRARY_COUNT]%[%$FUNCTION_COUNT]' %[%$LIBRARY_COUNT]%[%$FUNCTION_COUNT] %$FUNCTION_NAME_%[%$LIBRARY_COUNT]%[%$FUNCTION_COUNT] )
		%endif
	%endif
	
	%ifdef %$EXPORT
		%if %$EXPORT == 1 
			%ifnum %$EXPORT_COUNT
				%assign %$EXPORT_COUNT %$EXPORT_COUNT + 1
			%else
				%assign %$EXPORT_COUNT 1
			%endif

			%define %$EXPORT_NAME_%[%$EXPORT_COUNT] %1

			bug( %?? '%$EXPORT_NAME_%[%$EXPORT_COUNT]' %$EXPORT_COUNT %$EXPORT_NAME_%[%$EXPORT_COUNT] )
		%endif
	%endif
%endmacro

%macro ENDIMPORT 0
	; Prepare IMAGE_IMPORT_BY_NAMEs
	; For each imported library
	%ifnum %$LIBRARY_COUNT
		
		%assign %%i 0
		%rep %$LIBRARY_COUNT
			%assign %%i %%i + 1
			
			%ifnum %$FUNCTION_COUNT_%[%%i]
			
				%assign %%j 0
				%rep %$FUNCTION_COUNT_%[%%i]
					%assign %%j %%j + 1
					%define %%FNAME_%[%%i]%[%%j] %$FUNCTION_NAME_%[%%i]%[%%j]
					%defstr %%FSNAME_%[%%i]%[%%j] %%FNAME_%[%%i]%[%%j]
					
					%%FN_%[%%i]%[%%j]:
					dw 0
					db %%FSNAME_%[%%i]%[%%j], 0
					
					bug( %?? '%%FSNAME_%[%%i]%[%%j]' %[%%i]%[%%j] %%FSNAME_%[%%i]%[%%j] )
				%endrep
			%endif
		%endrep
	%endif
	
	; Prepare Original First Thunk
	; For each imported library
	%ifnum %$LIBRARY_COUNT
		%assign %%i 0
		%rep %$LIBRARY_COUNT
			%assign %%i %%i + 1
			
			%%OFTHUNK_%[%%i]:
			
			%ifnum %$FUNCTION_COUNT_%[%%i]
				%assign %%j 0
				%rep %$FUNCTION_COUNT_%[%%i]
					%assign %%j %%j + 1
					
					dd RVA(%%FN_%[%%i]%[%%j])
				%endrep
			%endif
			
			; Zero padding
			dd 0
		%endrep
	%endif
	
	; First Thunk, IAT
	; For each imported library
	%ifnum %$LIBRARY_COUNT
			%assign %%i 0
			%rep %$LIBRARY_COUNT
				%assign %%i %%i + 1
				
				%%FTHUNK_%[%%i]:
				
				%ifnum %$FUNCTION_COUNT_%[%%i]
					
					%assign %%j 0
					%rep %$FUNCTION_COUNT_%[%%i]
						%assign %%j %%j + 1
						
						%$FUNCTION_NAME_%[%%i]%[%%j]:
						dd RVA(%%FN_%[%%i]%[%%j])
						
						bug( %?? '%$FUNCTION_NAME_%[%%i]%[%%j]' %[%%i]%[%%j] %$FUNCTION_NAME_%[%%i]%[%%j] )
					%endrep
				%endif
				
				; Zero padding
				dd 0
			%endrep
	%endif

	; LIBs names
	; For each imported library
	%ifnum %$LIBRARY_COUNT
		%assign %%i 0
		%rep %$LIBRARY_COUNT
			%assign %%i %%i + 1
			
			%defstr %%LIBNAME_%[%%i] %$LIBRARY_NAME_%[%%i] 
			
			%%LNAME_%[%%i]:
			db 	%%LIBNAME_%[%%i], 0
			
			bug( %?? '%%LIBNAME_%[%%i]' %%i %%LIBNAME_%[%%i] )
		%endrep
	%endif
	
	; Fill in IMAGE_IMPORT_DESCRIPTOR structure
	; For each imported library
	%$IMAGE_IMPORT_DESCRIPTOR_START:
	%ifnum %$LIBRARY_COUNT
		%assign %%i 0
		%rep %$LIBRARY_COUNT
			%assign %%i %%i + 1
			
			DWORD %%OriginalFirstThunk_%[%%i], RVA(%%OFTHUNK_%[%%i])
			DWORD %%TimeDateStamp_%[%%i]
			DWORD %%ForwarderChain_%[%%i]
			DWORD %%Name_%[%%i], RVA(%%LNAME_%[%%i])
			DWORD %%FirstThunk_%[%%i], RVA(%%FTHUNK_%[%%i])	
		%endrep
	%endif
	
	%assign %$IMPORT 0
	; zero termination
	times 5 dd 0
	%$IMAGE_IMPORT_DESCRIPTOR_END:
%endmacro

;##############################################################################
; EXPORT TABLE Macros
; EXPORT/ENDEXPORT
; USAGE
; EXPORT
;   FUNC FunctionName
; ENDEXPORT
;##############################################################################
; %1 = Module name
%macro EXPORT 1
	;ALIGN DWORD
	;times (4 - (($ - %$IMAGE_DOS_HEADER) % 4)) db 0
	
	%assign %$EXPORT 1
	%ifnempty %1
		%define %$EXPORT_MODULE_NAME %1
	%else
		%warning EXPORT expects module name as input
	%endif
%endmacro

%macro ENDEXPORT 0
	; Get module name from parameter
	%ifdef %$EXPORT_MODULE_NAME
		%ifnstr %$EXPORT_MODULE_NAME
			%defstr %%substr %$EXPORT_MODULE_NAME
			BYTE %%Module_Name, %%substr, 0
		%else
			BYTE %%Module_Name, %$EXPORT_MODULE_NAME,0
		%endif
	%endif
	bug( %?? ExportModuleName '%%Module_Name' %%Module_Name )
	
	
	%%FUNCTIONS_ADDRESS:
	%ifnum %$EXPORT_COUNT
		%assign %%i 0
		
		%rep %$EXPORT_COUNT
			%assign %%i %%i + 1
		
			%define %%ENAME_%[%%i] %$EXPORT_NAME_%[%%i]
			dd RVA(%%ENAME_%[%%i])
			
			bug( %?? FunctionsAddress '%%ENAME_%[%%i]' %%i %%ENAME_%[%%i] )
		%endrep
	%endif
	
	; Names of Exported Functions
	%ifnum %$EXPORT_COUNT
		%assign %%i 0
		%rep %$EXPORT_COUNT
			%assign %%i %%i + 1
			
			%define %%FNAME_%[%%i] %$EXPORT_NAME_%[%%i]
			%defstr %%FNNAME_%[%%i] %%FNAME_%[%%i]
			
			%%FN_%[%%i]:
			db %%FNNAME_%[%%i],0
			
			bug( %?? Names '%%FNNAME_%[%%i]' %%i %%FNNAME_%[%%i] )
		%endrep
	%endif
	
	; Names Array
	%%NAMES_ADDRESS:
	%ifnum %$EXPORT_COUNT
		%assign %%i 0
		%rep %$EXPORT_COUNT
			%assign %%i %%i + 1
			dd RVA(%%FN_%[%%i])
			
			bug( %?? NamesAddress '%%FN_%[%%i]' %%i %%FN_%[%%i] )
		%endrep
	%endif	
	
	; Ordinals Array
	%%ORDINALS_ADDRESS:
	%ifnum %$EXPORT_COUNT
		%assign %%i 0 
		%rep %$EXPORT_COUNT
			dw %%i
			%assign %%i %%i + 1
			bug( %?? Ordinals '%%i' %%i )
		%endrep
	%endif
	
	
	; Export Table
	%$IMAGE_EXPORT_DIRECTORY_START:
	
	DWORD %%Characteristics
	DWORD %%TimeDateStamp
	WORD %%MajorVersion
	WORD %%MinorVersion
	DWORD %%Name, RVA(%%Module_Name)
	DWORD %%Base
	DWORD %%NumberOfFunctions, %$EXPORT_COUNT 
	DWORD %%NumberOfNames, %$EXPORT_COUNT
	DWORD %%AddressOfFunctions, RVA(%%FUNCTIONS_ADDRESS)
	DWORD %%AddressOfNames, RVA(%%NAMES_ADDRESS)
	DWORD %%AddressOfNameOrdinals, RVA(%%ORDINALS_ADDRESS)	
	
	%assign %$EXPORT 0
	%$IMAGE_EXPORT_DIRECTORY_END:
%endmacro

;##############################################################################
; RESOURCE Macros
; RESOURCE/ENDRESOURCE
; ID/ENDID, TYPE/ENDTYPE, LANG/ENDLANG, etc.
;##############################################################################
%macro RESOURCE 0
	;ALIGN DWORD
	;times (4 - (($ - %$IMAGE_DOS_HEADER) % 4)) db 0
	
	%assign %$RESOURCE 1
	%assign %$RESOURCE_TYPECOUNT 0
	%assign %$RESOURCE_IDCOUNT 0
	%assign %$RESOURCE_LANGCOUNT 0
%endmacro

%macro ENDRESOURCE 0
	%$IMAGE_RESOURCE_DIRECTORY_START:
	
	; TYPE Directory
	DWORD %%Characteristics
	DWORD %%TimeDateStamp
	WORD %%MajorVersion
	WORD %%MinorVersion
	WORD %%NumberOfNamedEntries
	WORD %%NumberOfIdEntries, %$RESOURCE_TYPECOUNT
	
	; TYPE Entries
	%assign %%i 0
	%rep %$RESOURCE_TYPECOUNT
		%assign %%i %%i + 1
		DWORD %%Name%[%%i], %$RESOURCE_TYPEID_%[%%i]
		DWORD %%OffsetToData%[%%i], (1<<31)|(%%ID_DIRECTORY%[%%i] - %$IMAGE_RESOURCE_DIRECTORY_START)
	%endrep
	
	; ID Directories   
	%assign %%i 0
	%rep %$RESOURCE_TYPECOUNT
		%assign %%i %%i + 1
		
		%%ID_DIRECTORY%[%%i]:
		DWORD %%Characteristics%[%%i]
		DWORD %%TimeDateStamp%[%%i]
		WORD %%MajorVersion%[%%i]
		WORD %%MinorVersion%[%%i]
		WORD %%NumberOfNamedEntries%[%%i]
		WORD %%NumberOfIdEntries%[%%i], %$RESOURCE_IDCOUNT_OF_%[%%i]
	
		;ID Entries
		%assign %%j 0
		%rep %$RESOURCE_IDCOUNT_OF_%[%%i]
			%assign %%j %%j + 1
			DWORD %%Name%[%%i]%[%%j], %$RESOURCE_ID_%[%%i]%[%%j]
			DWORD %%OffsetToData%[%%i]%[%%j], (1<<31)|(%%LANG_DIRECTORY%[%%i]%[%%j] - %$IMAGE_RESOURCE_DIRECTORY_START)
		%endrep
		
		; LANG directories
		%assign %%j 0
		%rep %$RESOURCE_IDCOUNT_OF_%[%%i]
			%assign %%j %%j + 1

			%%LANG_DIRECTORY%[%%i]%[%%j]:
			DWORD %%Characteristics%[%%i]%[%%j]
			DWORD %%TimeDateStamp%[%%i]%[%%j]
			WORD %%MajorVersion%[%%i]%[%%j]
			WORD %%MinorVersion%[%%i]%[%%j]
			WORD %%NumberOfNamedEntries%[%%i]%[%%j]
			WORD %%NumberOfIdEntries%[%%i]%[%%j], %$RESOURCE_LANGCOUNT_OF_%[%%i]%[%%j]
		
			;LANG Entries
			%assign %%k 0
			%rep %$RESOURCE_LANGCOUNT_OF_%[%%i]%[%%j]
				%assign %%k %%k + 1
				DWORD %%Name%[%%i]%[%%j]%[%%k], %$RESOURCE_LANGID_%[%%i]%[%%j]%[%%k]
				DWORD %%OffsetToData%[%%i]%[%%j]%[%%k], (%%LEAF_DIRECTORY_%[%%i]%[%%j]%[%%k] - %$IMAGE_RESOURCE_DIRECTORY_START)
			%endrep
			
			; Leaf Directories
			;LANG Entries
			%assign %%k 0
			%rep %$RESOURCE_LANGCOUNT_OF_%[%%i]%[%%j]
				%assign %%k %%k + 1
				
				%%LEAF_DIRECTORY_%[%%i]%[%%j]%[%%k]:
				
				DWORD %%DataOffset%[%%i]%[%%j]%[%%k], %$RESOURCE_LEAF_DATA_%[%%i]%[%%j]%[%%k]
				DWORD %%Size%[%%i]%[%%j]%[%%k], %$RESOURCE_LEAF_SIZE_%[%%i]%[%%j]%[%%k]
				DWORD %%CodePage%[%%i]%[%%j]%[%%k], %$RESOURCE_LEAF_CODEPAGE_%[%%i]%[%%j]%[%%k]
    			DWORD %%Reserved%[%%i]%[%%j]%[%%k]
			%endrep
		%endrep
	%endrep	
	
	
	%assign %$RESOURCE_TYPECOUNT 0
	%$IMAGE_RESOURCE_DIRECTORY_END:
%endmacro

%macro TYPE 1
	%ifnnum %1
		%error %1 is not a number. %?? macro expects number parameter.
	%endif

	%assign %$RESOURCE_TYPECOUNT %$RESOURCE_TYPECOUNT + 1

	%xdefine %$RESOURCE_TYPEID_%[%$RESOURCE_TYPECOUNT] %1
	
	; Debug
	bug( '%$RESOURCE_TYPECOUNT' %$RESOURCE_TYPECOUNT )
	bug( '%$RESOURCE_TYPEID_%[%$RESOURCE_TYPECOUNT]' %$RESOURCE_TYPEID_%[%$RESOURCE_TYPECOUNT] )
%endmacro

%macro ENDTYPE 0
	%xdefine %$RESOURCE_IDCOUNT_OF_%$RESOURCE_TYPECOUNT %$RESOURCE_IDCOUNT
	
	;Debug
	bug( %?? '%$RESOURCE_TYPECOUNT' %$RESOURCE_TYPECOUNT '%$RESOURCE_IDCOUNT' %$RESOURCE_IDCOUNT )
	
	%assign %$RESOURCE_IDCOUNT 0
%endmacro

%macro ID 1
	%ifnnum %1
		%error %1 is not a number. %?? macro expects number parameter.
	%endif

	%assign %$RESOURCE_IDCOUNT %$RESOURCE_IDCOUNT + 1

	%xdefine %$RESOURCE_ID_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT] %1
	
	; Debug
	bug( '%$RESOURCE_IDCOUNT' %$RESOURCE_IDCOUNT )
	bug( '%$RESOURCE_ID_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]' %$RESOURCE_ID_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT] )	
%endmacro

%macro ENDID 0
	%xdefine %$RESOURCE_LANGCOUNT_OF_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT] %$RESOURCE_LANGCOUNT
	
	;Debug
	bug( %?? '%$RESOURCE_IDCOUNT' %$RESOURCE_IDCOUNT '%$RESOURCE_LANGCOUNT' %$RESOURCE_LANGCOUNT )
	
	%assign %$RESOURCE_LANGCOUNT 0
%endmacro

; %1 Primary Language id
; %2 Sublanguage id
%macro LANG 0-2 0,0
	%ifnnum %1
		%error %1 is not a number. %?? macro expects number parameter.
	%endif
	
	%assign %$RESOURCE_LANGCOUNT %$RESOURCE_LANGCOUNT + 1
	
	%assign %%language_id (%2 << 10) | %1
	%xdefine %$RESOURCE_LANGID_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]%[%$RESOURCE_LANGCOUNT] %%language_id
	
	; Debug
	bug( '%$RESOURCE_LANGCOUNT' %$RESOURCE_LANGCOUNT )
	bug( '%$RESOURCE_LANGID_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]%[%$RESOURCE_LANGCOUNT]' %$RESOURCE_LANGID_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]%[%$RESOURCE_LANGCOUNT]	)
%endmacro

%macro ENDLANG 0
%endmacro

%macro LEAF 1-3 0,0
	%define %$RESOURCE_LEAF_DATA_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]%[%$RESOURCE_LANGCOUNT] %1
	%define %$RESOURCE_LEAF_SIZE_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]%[%$RESOURCE_LANGCOUNT] %2
	%define %$RESOURCE_LEAF_CODEPAGE_%[%$RESOURCE_TYPECOUNT]%[%$RESOURCE_IDCOUNT]%[%$RESOURCE_LANGCOUNT] %3
%endmacro

; Resource Type: RT_RCDATA, raw data
%macro FILE 1
	%1:
	%defstr %%filename %1
	incbin %%filename
	%1_end:
%endmacro
;##############################################################################
; MENU Macros
; MENU name/ENDMENU
; POPUP/ENDPOPUP, MENUITEM, etc.
;
; USAGE:
; MENU name
;   MENUITEM 'name', id
;   POPUP 'name'
;     MENUITEM 'name', id
;   ENDPOPUP
;   MENUITEM 'name'
; ENDMENU
;;##############################################################################

; %1 = name
%macro MENU 1
	;ALIGN DWORD
	times (4 - (($ - %$IMAGE_DOS_HEADER) % 4)) db 0
	
	%1:
	; Menu Header
	WORD   %%wVersion
	WORD   %%cbHeaderSize
	
	%define %$MENU_NAME %1	
	%assign %$MENU_ITEM_NUMBER 0
%endmacro

; %1 = name
; %2 = flags
%macro POPUP 1-2 0
	%assign %$MENU_ITEM_NUMBER %$MENU_ITEM_NUMBER + 1
	
	%ifnstr %1
		%error %?? String expected as first parameter
	%endif
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_TYPE 1
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_NAME %1
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_FLAGS %2
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_ID 0
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_LAST 0
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_POPUP 10h
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_INPOPUP 0
%endmacro

%macro ENDPOPUP 0
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_LAST 80h
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_INPOPUP 1
%endmacro

; %1 = name
; %2 = menuID
; %3 = flags
%macro MENUITEM 2-3 0
	%assign %$MENU_ITEM_NUMBER  %$MENU_ITEM_NUMBER + 1
	
	%ifnstr %1
		%error %?? String expected as first parameter
	%endif
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_TYPE 2
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_ID %2
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_NAME %1
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_FLAGS %3
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_POPUP 0
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_LAST 0
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_INPOPUP 0
%endmacro

%macro ENDMENU 0
	%xdefine %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_LAST 80h
	
	; Correct last popup menu problem
	%if %[%$MENU_NAME]_%[%$MENU_ITEM_NUMBER]_INPOPUP == 1
		%assign %%j %$MENU_ITEM_NUMBER
		%rep %$MENU_ITEM_NUMBER
			%assign %%j %%j - 1
			%if %[%$MENU_NAME]_%[%%j]_TYPE == 1
				%xdefine %[%$MENU_NAME]_%[%%j]_LAST 80h
				%exitrep
			%endif
		%endrep
	%endif
	
	%assign %%i 0
	%rep %$MENU_ITEM_NUMBER
		%assign %%i %%i + 1
		
		%if %[%$MENU_NAME]_%[%%i]_TYPE == 1
			WORD %%fItemFlags_%[%%i], %[%$MENU_NAME]_%[%%i]_FLAGS | %[%$MENU_NAME]_%[%%i]_LAST | %[%$MENU_NAME]_%[%%i]_POPUP
			WORD %%szItemText_%[%%i], __utf16__(%[%$MENU_NAME]_%[%%i]_NAME),0
			;bug(%?? '%[%%i]' %[%%i] %[%$MENU_NAME]_%[%%i]_NAME)
		%else
			WORD %%fItemFlags_%[%%i], %[%$MENU_NAME]_%[%%i]_FLAGS | %[%$MENU_NAME]_%[%%i]_LAST | %[%$MENU_NAME]_%[%%i]_POPUP
			WORD %%wMenuID_%[%%i], %[%$MENU_NAME]_%[%%i]_ID
			WORD %%szItemText_%[%%i], __utf16__(%[%$MENU_NAME]_%[%%i]_NAME),0
			;bug(%?? '%[%%i]' %[%%i] %[%$MENU_NAME]_%[%%i]_NAME)
		%endif
	%endrep
	
	; Clean up
	%assign %$MENU_ITEM_NUMBER 0
	%[%$MENU_NAME]_end:
%endmacro
;##############################################################################
; PE HEADER Macros
; End user shouldn't use these macros explicitly
; These structures are found on any windows.h include file
; Converting C language structures into nasm is easy
; Thanks to DWORD, WORD and BYTE macros declared earlier
;##############################################################################
%macro IMAGE_DOS_HEADER 0
	%$IMAGE_DOS_HEADER:
	WORD %%e_magic, 5A4Dh
	WORD %%e_cblp
	WORD %%e_cp
	WORD %%e_crlc
	WORD %%e_cparhdr
	WORD %%e_minalloc
	WORD %%e_maxalloc
	WORD %%e_ss
	WORD %%e_sp
	WORD %%e_csum
	WORD %%e_ip
	WORD %%e_cs
	WORD %%e_lfarcl
	WORD %%e_ovno
	WORD %%e_res[4]
	WORD %%e_oemid
	WORD %%e_oeminfo
	WORD %%e_res2[10]
	DWORD %%e_lfanew, %$PE_SIGNATURE
%endmacro

%macro IMAGE_NT_SIGNATURE 0
	%$IMAGE_NT_SIGNATURE:

	%assign %%IMAGE_DOS_SIGNATURE             0x5A4D      ;MZ
	%assign %%IMAGE_OS2_SIGNATURE             0x454E      ;NE
	%assign %%IMAGE_OS2_SIGNATURE_LE          0x454C      ;LE
	%assign %%IMAGE_NT_SIGNATURE              0x00004550  ;PE00
	%define %%SIGNATURE %%IMAGE_NT_SIGNATURE
	
	DWORD %$PE_SIGNATURE, %%SIGNATURE 
%endmacro

%macro IMAGE_FILE_HEADER 0
	%$IMAGE_FILE_HEADER:
	
	; Machine
	%assign %%IMAGE_FILE_MACHINE_I386 0x014c
	%assign %%IMAGE_FILE_MACHINE_IA64 0x0200
	%assign %%IMAGE_FILE_MACHINE_AMD64 0x8664
	
	%ifctx pe32
		%define %%Mac %%IMAGE_FILE_MACHINE_I386
	%elifctx dll32
		%define %%Mac %%IMAGE_FILE_MACHINE_I386
	;%elifctx pe64
	;	%define %%Mac %%IMAGE_FILE_MACHINE_IA64
	;%elifctx dll64
	;	%define %%Mac %%IMAGE_FILE_MACHINE_IA64
	%endif 
	
	; Characteristics
	%assign %%IMAGE_FILE_DLL 0x2000
	%assign %%IMAGE_FILE_32BIT_MACHINE 0x0100
	%assign %%IMAGE_FILE_EXECUTABLE_IMAGE 0x0002
	
	%ifctx pe32
		%define %%Character %%IMAGE_FILE_32BIT_MACHINE|%%IMAGE_FILE_EXECUTABLE_IMAGE
	%elifctx dll32
		%define %%Character %%IMAGE_FILE_32BIT_MACHINE|%%IMAGE_FILE_DLL|%%IMAGE_FILE_EXECUTABLE_IMAGE
	;%elifctx pe64
	;	%define %%Character
	;%elifctx dll64
	;	%define %%Character
	%endif
	
	; File Header
	WORD    %%Machine, %%Mac	
	WORD    %%NumberOfSections, 1
	DWORD   %%TimeDateStamp, __POSIX_TIME__
	DWORD   %%PointerToSymbolTable
	DWORD   %%NumberOfSymbols
	WORD    %%SizeOfOptionalHeader, %$IMAGE_SECTION_HEADER - %$IMAGE_OPTIONAL_HEADER
	WORD    %%Characteristics, %%Character
%endmacro

%macro IMAGE_OPTIONAL_HEADER 0
	%$IMAGE_OPTIONAL_HEADER:
	
	;Magic
	%assign %%IMAGE_NT_OPTIONAL_HDR32_MAGIC 0x10b
	%assign %%IMAGE_NT_OPTIONAL_HDR64_MAGIC 0x20b
	%ifctx pe32
		%define %%Magik %%IMAGE_NT_OPTIONAL_HDR32_MAGIC
	%elifctx dll32
		%define %%Magik %%IMAGE_NT_OPTIONAL_HDR32_MAGIC
	%elifctx pe64
		%define %%Magik %%IMAGE_NT_OPTIONAL_HDR64_MAGIC
	%elifctx dll64
		%define %%Magik %%IMAGE_NT_OPTIONAL_HDR64_MAGIC
	%endif
	
	;Subsystem
	%assign %%IMAGE_SUBSYSTEM_NATIVE 1
	%assign %%IMAGE_SUBSYSTEM_WINDOWS_GUI 2
	%assign %%IMAGE_SUBSYSTEM_WINDOWS_CUI 3
	%if SUBSYSTEM == 1
		%define %%Subsys %%IMAGE_SUBSYSTEM_WINDOWS_GUI
	%elif SUBSYSTEM == 2
		%define %%Subsys %%IMAGE_SUBSYSTEM_WINDOWS_CUI
	%elif SUBSYSTEM == 3
		%define %%Subsys %%IMAGE_SUBSYSTEM_NATIVE
	%endif
	
	; Image Size
	%define %%IMAGE_SIZE  ROUNDVS(%$IMAGE_END, %$IMAGE_SECTION_HEADER_END) + ROUNDVS(%$IMAGE_SECTION_HEADER_END, %$IMAGE_DOS_HEADER)
	
	; Headers Size
	%define %%HEADERS_SIZE %$IMAGE_SECTION_HEADER_END - %$IMAGE_DOS_HEADER
	
	; Section Table
	WORD    %%Magic, %%Magik
	BYTE    %%MajorLinkerVersion
	BYTE    %%MinorLinkerVersion
	DWORD   %%SizeOfCode
	DWORD   %%SizeOfInitializedData
	DWORD   %%SizeOfUninitializedData
	DWORD   %%AddressOfEntryPoint, RVA(%$ENTRY_POINT)
	DWORD   %%BaseOfCode
	DWORD   %%BaseOfData
	DWORD   %%ImageBase, IMAGEBASE
	DWORD   %%SectionAlignment, SALIGN
	DWORD   %%FileAlignment, FALIGN
	WORD    %%MajorOperatingSystemVersion, 4
	WORD    %%MinorOperatingSystemVersion, 0
	WORD    %%MajorImageVersion
	WORD    %%MinorImageVersion
	WORD    %%MajorSubsystemVersion, 4
	WORD    %%MinorSubsystemVersion, 0
	DWORD   %%Win32VersionValue
	DWORD   %%SizeOfImage, %%IMAGE_SIZE
	DWORD   %%SizeOfHeaders, %%HEADERS_SIZE
	DWORD   %%CheckSum
	WORD    %%Subsystem, %%Subsys
	WORD    %%DllCharacteristics
	DWORD   %%SizeOfStackReserve
	DWORD   %%SizeOfStackCommit
	DWORD   %%SizeOfHeapReserve
	DWORD   %%SizeOfHeapCommit
	DWORD   %%LoaderFlags
	DWORD   %%NumberOfRvaAndSizes,10h
%endmacro

%macro IMAGE_DATA_DIRECTORY 0
	%$IMAGE_DATA_DIRECTORY:
	
	; Import Table
	%define %%ImportTable_VA RVA(%$IMAGE_IMPORT_DESCRIPTOR_START)
	%define %%ImportTable_SZ %$IMAGE_IMPORT_DESCRIPTOR_END - %$IMAGE_IMPORT_DESCRIPTOR_START
	
	; Export Table
	%define %%ExportTable_VA RVA(%$IMAGE_EXPORT_DIRECTORY_START)
	%define %%ExportTable_SZ %$IMAGE_EXPORT_DIRECTORY_END - %$IMAGE_EXPORT_DIRECTORY_START
	
	; Resource Table
	%define %%ResourceTable_VA RVA(%$IMAGE_RESOURCE_DIRECTORY_START)
	%define %%ResourceTable_SZ %$IMAGE_RESOURCE_DIRECTORY_END - %$IMAGE_RESOURCE_DIRECTORY_START
	
	DWORD   %%ExportTableVirtualAddress, %%ExportTable_VA
	DWORD   %%ExportTableSize, %%ExportTable_SZ
	
	DWORD   %%ImportTableVirtualAddress, %%ImportTable_VA
	DWORD   %%ImportTableSize, %%ImportTable_SZ
	
	DWORD   %%ResourceTableVirtualAddress, %%ResourceTable_VA
	DWORD   %%ResourceTableSize, %%ResourceTable_SZ
	
	DWORD   %%ExceptionTableVirtualAddress
	DWORD   %%ExceptionTableSize
	
	DWORD   %%CertificateTableVirtualAddress
	DWORD   %%CertificateTableSize
	
	DWORD   %%BaseRelocationTableVirtualAddress
	DWORD   %%BaseRelocationTableSize
	
	DWORD   %%DebuggingInformationVirtualAddress
	DWORD   %%DebuggingInformationSize
	
	DWORD   %%ArchitectureSpecificDataVirtualAddress
	DWORD   %%ArchitectureSpecificDataSize
	
	DWORD   %%GlobalPointerRegisterVirtualAddress
	DWORD   %%GlobalPointerRegisterSize
	
	DWORD   %%ThreadLocalStorageTLSVirtualAddress
	DWORD   %%ThreadLocalStorageTLSSize
	
	DWORD   %%LoadConfigurationTableVirtualAddress
	DWORD   %%LoadConfigurationTableSize
	
	DWORD   %%BoundImportTableVirtualAddress
	DWORD   %%BoundImportTableSize
	
	DWORD   %%ImportAddressTableVirtualAddress
	DWORD   %%ImportAddressTableSize
	
	DWORD   %%DelayImportDescriptorVirtualAddress
	DWORD   %%DelayImportDescriptorSize
	
	DWORD   %%TheCLRHeaderVirtualAddress
	DWORD   %%TheCLRHeaderSize
	
	DWORD   %%ReservedVirtualAddress
	DWORD   %%ReservedSize
%endmacro

%macro IMAGE_SECTION_HEADER 0
	%$IMAGE_SECTION_HEADER:
	
	; Virtual Address
	%define %$SECTION_VA_1 ROUNDVS(%$IMAGE_SECTION_HEADER_END, %$IMAGE_DOS_HEADER)
	
	; Virtual Size
	%define %$SECTION_VS_1 ROUNDVS(%$SECTION_END_1, %$SECTION_START_1)

	; Virtual Size
	%define %$SECTION_VS_1 ROUNDVS(%$SECTION_END_1, %$SECTION_START_1)

	; File Address
	%define %$SECTION_FA_1 %$SECTION_START_1

	; File Size
	%define %$SECTION_FS_1 (%$SECTION_END_1 - %$SECTION_START_1)

	;Characteristics
	%define IMAGE_SCN_CNT_CODE 0x00000020
	%define IMAGE_SCN_CNT_INITIALIZED_DATA 0x00000040
	%define IMAGE_SCN_CNT_UNINITIALIZED_DATA 0x00000080
	%assign %%IMAGE_SCN_MEM_EXECUTE 0x20000000
	%assign %%IMAGE_SCN_MEM_READ 0x40000000
	%assign %%IMAGE_SCN_MEM_WRITE 0x80000000
	%assign %%IMAGE_SCN_MEM_SHARED 0x10000000		
	%define %$SECTION_CHARACTERISTICS_1 %%IMAGE_SCN_MEM_EXECUTE|%%IMAGE_SCN_MEM_READ|%%IMAGE_SCN_MEM_WRITE

	;Section Name
	%define %%str SECTIONNAME
	%ifstr %%str
		%strlen %%len %%str
		
		%if %%len == 8
			; keep %%str as it is
		%elif %%len < 8
			%rep (8 - %%len)
				%strcat %%str %%str, `\0`
			%endrep
		%elif %%len > 8
			%substr %%str %%str 1, 8
		%endif
		
		%define %%SECTION_NAME_1  %%str
	%else
		%error "String expected " %%str
	%endif
	bug(%?? 'SECTIONNAME' SECTIONNAME '%%len' %%len '%%SECTION_NAME_1' %%SECTION_NAME_1 )
	
	; Section Table
	BYTE    %%Name, %%SECTION_NAME_1
	DWORD   %%VirtualSize, %$SECTION_VS_1 
	DWORD   %%VirtualAddress, %$SECTION_VA_1
	DWORD   %%SizeOfRawData, %$SECTION_FS_1 
	DWORD   %%PointerToRawData, %$SECTION_FA_1
	DWORD   %%PointerToRelocations
	DWORD   %%PointerToLinenumbers
	WORD    %%NumberOfRelocations
	WORD    %%NumberOfLinenumbers
	DWORD   %%Characteristics, %$SECTION_CHARACTERISTICS_1

	;ALIGN
	times (FALIGN - (($ - %$IMAGE_DOS_HEADER) % FALIGN)) db 0
	
	%$IMAGE_SECTION_HEADER_END:
	%$SECTION_START_1:
%endmacro

;##############################################################################
; General Purpose TYPE Macros
; DWORD, WORD, BYTE
; DWORD var[], WORD var[], BYTE var[]
; Very Handy When Building PE Header structures
;##############################################################################
%macro DWORD 1-2+ 0h
	%defstr %%label %1
	%strlen %%len %%label

	%assign %%i 1
	%rep %%len 
		%substr %%c %%label %%i

		%if %%c == '['
			%define %%array
			%assign %%start %%i + 1
		%endif

		%if %%c == ']'
			%assign %%end %%i
		%endif

		%assign %%i %%i + 1
	%endrep

	%ifdef %%array
	    %substr %%sublabel %%label 1,%%start-2
	    %deftok toklabel %%sublabel 
	    toklabel:
	%else
	    %deftok toklabel %%label 
	    toklabel:
	%endif

	%ifdef  %%array
		%assign %%lenght %%end - %%start
		%substr %%number %%label %%start, %%lenght
		%deftok %%number %%number
		
		times %%number dd %2
	%else
		dd %2
	%endif
%endmacro

%macro WORD 1-2+ 0h
	%defstr %%label %1
	%strlen %%len %%label

	%assign %%i 1
	%rep %%len 
		%substr %%c %%label %%i

		%if %%c == '['
			%define %%array
			%assign %%start %%i + 1
		%endif

		%if %%c == ']'
			%assign %%end %%i
		%endif

		%assign %%i %%i + 1
	%endrep
	
	%ifdef %%array
	    %substr %%sublabel %%label 1,%%start-2
	    %deftok toklabel %%sublabel 
	    toklabel:
	%else
	    %deftok toklabel %%label 
	    toklabel:
	%endif
	
	%ifdef  %%array
		%assign %%lenght %%end - %%start
		%substr %%number %%label %%start, %%lenght
		%deftok %%number %%number
		
		times %%number dw %2
	%else
		dw %2
	%endif
%endmacro

%macro BYTE 1-2+ 0h
	%defstr %%label %1
	%strlen %%len %%label

	%assign %%i 1
	%rep %%len 
		%substr %%c %%label %%i

		%if %%c == '['
			%define %%array
			%assign %%start %%i + 1
		%endif

		%if %%c == ']'
			%assign %%end %%i
		%endif

		%assign %%i %%i + 1
	%endrep
	
	%ifdef %%array
	    %substr %%sublabel %%label 1,%%start-2
	    %deftok toklabel %%sublabel 
	    toklabel:
	%else
	    %deftok toklabel %%label 
	    toklabel:
	%endif
	
	%ifdef  %%array
		%assign %%lenght %%end - %%start
		%substr %%number %%label %%start, %%lenght
		%deftok %%number %%number
		
		times %%number db %2
	%else
		db %2
	%endif
%endmacro
