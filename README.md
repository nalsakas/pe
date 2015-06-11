For a long time I wanted to output PE32, DLL32, PE64 and DLL64 formats 
directly from nasm assembler. Nasm doesn't have support of direct output to executable files or dll files
but instead it has support of raw binary output and has advanced macro support. My aim in
this project is to use nasm's macro capability to directly output executables. In order to
make that happen I need to invent pretty a lot new macros. Some of them are PE header
structures, section tables, data directories, resource macros, etc.

Why I created these macro sets? Answer is simple. Because I have a passion about inner workings
of executables. Apart from that Ihave learned a lot while working with nasm macros and pe file format.

With these macro sets you can do amazing executables by yourself. You don't need any object linker or
resource compiler whatsoever. You can import any function you want just by typing its name;
you can export any local function you want; you can include any resource you want;
you can experiment and get a deeper insight of pe file format, etc.

Although there are a lot of macros under the hood, end user only need to know a few of them.
An example usage is given below. As you notice usage is pretty easy.

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
  		LANG
  			LEAF RVA(resource_label), SIZEOF(resource)
  		ENDLANG
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
Labels in assembly are offset based. They don't actually contain virtual addresses.
VA() together with RVA() macros are invented to convert offset based labels into virtual addresses.

Examples: 
push dword [label] --> push dword [VA(label)]
mov eax, dword [label] --> mov eax, [VA(label)]
call [label] --> call [VA(label)]
call label --> call label --> this line doesn't require VA()

Beware there are two types of call instructions. One uses relative displacement whose form is "call label". 
This form doesn't require VA() macro. But the other form which needs absolute virtual address has "call [label]" form.
This form as you expect requires VA() macro.
VA() macro.

2) IMPORT MACROS:
If you want to use external functions from other libraries in your code use IMPORT macro. Import macro has following form.

IMPORT
	LIB Libname / user32.dll
		FUNC Functionname / MessageBoxA
	ENDLIB
	LIB kernel32.dll
		FUNC ExitProcess
	ENDLIB
ENIMPORT

There can be more than one LIB/ENDLIB as well as more than one FUNC. Usage is very simple. All this macro does is to put import
table where it is declared. Notice that libname and function names are in token form. They are not in string form. This macro turns
function names into labels. That labels behaves like addresses of IAT entry of that particular function. If you need to
access imported function inside assembly use "call [VA(function_name)]".

3) EXPORT MACROS:
If you want to export local functions of your executable use this macro. According to PE documantation both EXE files and DLL's
can have exported functions. Sample usage is given below. Function_name is one of local function.
Each export directory needs a module name which is its file name. Usually in this form "libname.dll". 

EXPORT module_name
	FUNC function_name
	...
ENDEXPORT


4) RESOURCE MACROS:
Resources have tree like structures. According to documantation there can be only 3-level. First level is TYPE level.
You declare type of resource here. RT_MENU, RT_DATA, RT_DIALOG etc. Second level is ID level. You define IDs of resources here.
ID_ICON, ID_MENU etc. Third level is language level. You define language and sublanguage IDs here.
Last level is known as leaf level. You can use leafs as pointers to actual resources. Many resources require additional
structures. User defined resources and raw resources doesn't require any special format.

Example:

; First define resource tree, which has type, id, lang and pointer to actual resources.
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

; Second define actual resources. They generally have special formats. Raw and user defined types of resources doesn't have
; any special format.

; Menu macro generates special format of MENU resources.
MENU menu_label
	MENUITEM 'name', item_id
ENDMENU

As you can see there can be more than one TYPE, ID and LANG entries in resource tree. But each entry must comply 3-level
hierarcy. LEAF entries points to actual resouces.