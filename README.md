For a long time I wanted to directly produce PE32, DLL32, PE64 and DLL64 files from the 
output of nasm assembler. Nasm doesn't have support of direct output to executable file
but instead it has support of raw binary output and has advanced macro support. My aim in
this project is to use nasm's macro capability to directly output executables. In order to
make that happen I need to invent pretty a lot new macros. Some of them are PE header
structures, section tables, data directories, etc.

Why I created this macro sets? Answer is simple. Because I have a passion about inner workings
of executables. Apart from because of this project I also have learned a lot while writing
nasm macros and writing about pe file format.

With these macro sets you can do amazing executables by yourself. You don't need any obj linker or
resource compiler whatsoever. You can include any function you want to import by typing its library and name;
you can export any local function; you can prepare resources of your application by your hand in the same source;
you can experiment and get a deeper insight of pe format; etc.

Although there will be a lot of macros beneath, end user only need to know a few user space macros.
An example usage is given below. As you notice names and usage is pretty easy.

Example PE32 file:

%include "pe.inc"

; For 32-bit executable use PE32
; For 32-bit dll use DLL32
; 64-bit PE and DLL's are not ready yet
PE32

; Data declarations
Title db 'Title of MessageBox',0

; enty point of executable
START
; machine intructions
  ...
  push VA(Title)
  push 0
  call [VA(MessageBoxA)]

  LocalFunction:
     ...
     ret
     
; Setup import directory if you need to
IMPORT
  ; write down imported dll's
  LIB user32.dll
    ; write down imported functions
    FUNC MessageBoxA
  ENDIMPORT
  LIB kernel32.dll
    FUNC ExitProcess
    ...
  ENDLIB
ENDIMPORT

; Setup Export Directory if you need to
EXPORT module_name
   ; write down local functions to export
   FUNC LocalFunction
   ...
ENDEXPORT

; Setup Resource Directory if you need to
RESOURCE
  TYPE type_id
  	ID resource_id
  		LEAF RVA(resource_label), SIZEOF(resource)
  	ENDID
  ENDTYPE
ENDRESOURCE

; Menu resource
MENU resource_label
	MENUITEM 'name', item_id
	POPUP 'name'
		MENUITEM 'name', item_id
	ENDPOPUP
ENDMENU

END
; End of executable

You can find detailed analysis of user space macros below. Have fun.

1) VA() / RVA() MACROS:
Labels in an normal assembly source code are offset based. They don't actually contain virtual addresses.
VA() togetger with RVA() macros are invented in order to convert offset based addresses into virtual ones.

Examples:
push dword [label] --> push dword [VA(label)]
mov eax, dword [label] --> mov eax, [VA(label)]
call [label] --> call [VA(label)]
call label --> call label --> this line doesn't require VA()

Beware there are two types of call instruction. One uses relative displacement which is in this form "call label". 
This form doesn't require VA() macro. But the other form which has absolute address form, call [label], requires
VA() macro.

2) IMPORT MACROS:
If you want to use external functions from libraries use this macro. Import macro has following form.

IMPORT
	LIB Libname / user32.dll
		FUNC Functionname / MessageBoxA
	ENDLIB
	LIB kernel32.dll
		FUNC ExitProcess
	ENDLIB
ENIMPORT

There may be more than one LIB/ENDLIB as well as more than one FUNC. Usage is very simple. All this macro does is put import
table where it is declared. Notice libname and function names are in token form. They are not in string form. This macro turns
function names into labels. That labels behaves like address of IAT entry of that particular function. If you need to
access imported function inside assembly use "call [VA(function_name)]".

3) EXPORT MACROS:
If you want to export local functions of your executable use this macro. According to PE documantation both executables namely
PEs and dynamic libraries, DLLs, can have exported functions. Sample usage is given below. Function_name is one local function
label declared inside assemlby source code. Each export directory needs a module name which is dll's name. 

EXPORT module_name
	FUNC function_name
	...
ENDEXPORT


4) RESOURCE MACROS:
Resources have tree like structure. And according to documantation there is only 3-levels of them. First level is TYPE level.
You declare type of resource here. RT_MENU, RT_DATA, RT_DIALOG etc. Second level is ID level. You define IDs of resources here.
ID_ICON, ID_MENU etc. Third level is language level. You define language and sublanguage IDs here. Last level is known as leafs.
You use leaf as pointers to actual resources. Many resources require additional structures but user defined and raw resources
doesn't require any special format.

Example:

RESOURCE
	TYPE type_id / RT_MENU
		ID resource_id
			LANG lang_id, sublang_id / default is 0,0 for language neutral
				LEAF RVA(menu_label), SIZEOF(menu)
			ENDLANG
		ENDID
		ID resource_id2
			...
		ENDID
	ENDTYPE
	
	TYPE RT_DATA
		ID resource_id2
			LANG
				LEAF RVA(raw_data), SIZEOF(raw_data)
			ENDLANG
		ENDID
	ENDTYPE
ENDRESOURCE

MENU menu_label
	MENUITEM 'name', item_id
ENDMENU

As you can see there  can be more than one TYPE, ID and LANG entries. But each menu entry must comply this 3-level definition.
LEAF entries points to actual resouces by their labels.