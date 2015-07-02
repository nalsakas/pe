# NASM PE MACROS

Author: Seyhmus AKASLAN  
Contact: nalsakas@gmail.com  
License: GPL v2

## <a name="TABLE OF CONTENTS"></a>TABLE OF CONTENTS

1. [INRODUCTION](#INRODUCTION)
2. [VA()/RVA() MACROS](#VA()/RVA() MACROS)
3. [IMPORT MACROS](#IMPORT MACROS)
4. [EXPORT MACROS](#EXPORT MACROS)
5. [RESOURCE MACROS](#RESOURCE MACROS)
6. [MENU MACROS](#MENU MACROS)
7. [DIALOG MACROS](#DIALOG MACROS)
8. [STRINGTABLE MACROS](#STRINGTABLE MACROS)
9. [ACCELERATORTABLE MACROS](#ACCELERATORTABLE MACROS)
10. [BITMAP MACRO](#BITMAP MACRO)

## [:top:](#TABLE OF CONTENTS)<a name="INTRODUCTION"></a>INTRODUCTION

For a long time I wanted to output *PE32, DLL32, PE64* and *DLL64* formats directly from nasm assembler. Nasm doesn't have support of direct output to executable files or dll files but instead it has support of raw binary output and has advanced macro support. My aim in this project is to use nasm's macro capability to directly output executables. In order to make that happen I need to invent pretty a lot new macros. Some of them are PE header structures, section tables, data directories, resource macros, etc.

Why I created these macro sets? Answer is simple. Because I have a passion about inner workings of executables. Apart from that Ihave learned a lot while working with nasm macros and pe file format.

With these macro sets you can do amazing executables by yourself. You don't need any object linker or resource compiler whatsoever. You can import any function you want just by typing its name; you can export any local function you want; you can include any resource you want; you can experiment and get a deeper insight of pe file format, etc.

Although there are a lot of macros under the hood, end user only need to know a few of them. Actually only 3 of them suffice for a very basic PE.

```
%include 'pe.inc'  
PE32  
START  
  ret  
END
```

Example above is a valid pe file. All it does is to return as soon as loaded. As you can see there are only 3 macros you need to remember. *PE32, START* and *END*.

Now, look at the below example.

Example PE32 file:

```
%include "pe.inc"  

; For 32-bit executable use PE32
; For 32-bit dll use DLL32
; PE64 and DLL64 aren''t ready yet
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
; This structure is also know as resource tree.  
RESOURCE  
  TYPE type_id  
  	ID resource_id  
  		LANG  
  			LEAF RVA(resource_label), SIZEOF(resource_size)  
  		ENDLANG  
  	ENDID  
  ENDTYPE  
ENDRESOURCE  

; Setup Menu if defined in resource tree  
MENU menu_label  
	MENUITEM 'name', item_id  
	POPUP 'name'  
		MENUITEM 'name', item_id  
	ENDPOPUP  
ENDMENU  

; Setup Dialog if defined in resource tree  
DIALOG dialog_label, x, y, cx, cy  
  STYLE dialog styles      ;Optional  
  EXSTYLE extended styles  ;Optional  
  FONT size, 'face'        ;Optional  
  CAPTION 'Caption Text'   ;Optional  
  FONT size, 'font face'   ;Optional  
  
  ; Controls  
  ; Style and exstyle member of child controls are optional  
  CONTROL 'name', id, class_id, x, y, cx, cy, sytles, exstyles  
  
  ; Below controls are based on CONTROL macro.  
  ; Doesn't need class_id, because they are already declared inside.  
  PUSHBUTTON 'text', id, x, y, cx, cy, optional style, optional exstyle  
  ...  
ENDDIALOG  

; Setup String Table if defined in resource tree  
STRINGTABLE label  
  STRING 'First String'  
  STRING 'Second String'  
  STRING 'Third String'  
  ...  
  STRING '16th string'  
ENDSTRINGTABLE  

END  
; End of executable  
```

You can find detailed analysis of user space macros below. Have fun.

## [:top:](#TABLE OF CONTENTS)<a name="VA()/RVA() MACROS"></a>VA()/RVA() MACROS

Labels in assembly are offset based. They don't actually contain virtual addresses. *VA()* together with *RVA()* macros are invented to convert offset based labels into virtual addresses.

Examples:

|Before|After|Description|
|------|-------|-----|
|push dword [label]|push dword [VA(label)]| |  
|mov eax, dword [label]|mov eax, [VA(label)]| | 
|call [label]|call [VA(label)]| |  
|call label|call label|this line doesn't require VA()|

Beware there are two types of call instructions. One uses relative displacement whose form is `"call label"`. This form doesn't require *VA()* macro. But the other form which needs absolute virtual address has `"call [label]"` form. This form as you expect requires *VA()* macro.  

## [:top:](#TABLE OF CONTENTS)<a name="IMPORT MACROS"></a>IMPORT MACROS

If you want to use external functions from other libraries in your code use *IMPORT* macro. Import macro has following form.  

```
IMPORT  
	LIB Libname / user32.dll  
		FUNC Functionname / MessageBoxA  
	ENDLIB  
	LIB kernel32.dll  
		FUNC ExitProcess  
	ENDLIB  
ENIMPORT  
```

There can be more than one *LIB/ENDLIB* as well as more than one FUNC. Usage is very simple. All this macro does is to put import table where it is declared. Notice that libname and function names are in token form. They are not in string
form. This macro turns function names into labels. That labels behaves like addresses of IAT entry of that particular function. If you need to access imported function inside assembly use `"call [VA(function_name)]"`.

## [:top:](#TABLE OF CONTENTS)<a name="EXPORT MACROS"></a>EXPORT MACROS

If you want to export local functions of your executable use this macro. According to PE documantation both EXE files and DLL's can have exported functions. Sample usage is given below. Function_name is one of local function. Each export directory needs a module name which is its file name. Usually in this form libname.dll.

```
EXPORT module_name  
	FUNC function_name  
	...  
ENDEXPORT  
```

## [:top:](#TABLE OF CONTENTS)<a name="RESOURCE MACROS"></a>RESOURCE MACROS

Resources have tree like structures. According to documantation there can be only 3-level. First level is TYPE level. You declare type of resource here. RT_MENU, RT_DATA, RT_DIALOG etc. Second level is ID level. You define IDs of resources here.
ID_ICON, ID_MENU etc. Third level is language level. You define language and sublanguage IDs here. Last level is known as leaf level. You can use leafs as pointers to actual resources. Many resources require additional structures. User defined resources and raw resources doesn't require any special format.

Example:  

```
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

; Second define actual resources. They generally have special formats. Raw and 
; user defined types of resources doesn't have any special format.  
```

## [:top:](#TABLE OF CONTENTS)<a name="MENU MACROS"></a>MENU MACROS

In order to use menu resources first include one resource with RT_MENU type into resource tree. Than use following *MENU* macro to define your menu.

```
; Menu macro generates special format required by MENU resources.  
MENU menu_label  
	; First parameter is name, second is id and optional third parameter is flags  
	MENUITEM 'name', menu_item_id  
	 
	; First parameter is name and optional second parameter is flags  
	POPUP 'name'  
       MENUITEM 'name', menu_item_id  
    ENDPOPUP	
ENDMENU  
```

*MENU* macros helps tou create menu resources. There are only 2 type of child macros declared inside. One is *MENUITEM* and other is *POPUP/ENDPOPUP*.

## [:top:](#TABLE OF CONTENTS)<a name="DIALOG MACROS"></a>DIALOG MACROS

In order to use dialog resources first include one resource with RT_DIALOG type into resource tree. Than use following *DIALOG* macro to define your dialog.
```
DIALOG label, x, y, cx, cy  
  STYLE xxx                ; Optional  
  EXSTYLE xxx              ; Optional  
  CAPTION 'text'           ; Optional  
  MENU resource_id         ; Optional  
  FONT size, 'font face'   ; Optional
  
  ; Declare controls  
  CONTROL 'text', id, class_id, x, y, cx, cy, optional stye, optional exstyle  

  ; Predefined controls doesn't need class id  
  PUSHBUTTON 'text', id, x, y, cx, cy, optional style, optional exstyle  
  EDITTEXT id, x, y, cx, cy, style, exstyle  
  ...  
ENDDIALOG  
```

You don't need to put *STYLE*, *EXSTYLE*, *FONT* and *CAPTION* macros beneath *DIALOG* macro. They are optional. If you need a dialog menu then put MENU beneath *DIALOG* macro. If you need a caption for your dialog then put a CAPTION macro beneath *DIALOG* macro. If you need additional styles put *STYLE* and *EXSTYLE* beneath *DIALOG* macro. If you don't put a *STYLE*, dialog uses default styles which are;

`WS_POPUP | WS_BORDER | WS_SYSMENU | WS_VISIBLE | DS_SETFONT | WS_CAPTION | DS_NOFAILCREATE`

There are total 15 kinds of predefined child controls. All of them based on CONTROL macro. These child controls are *DEFPUSHBUTTON, PUSHBUTTON, GROUPBOX, RADIOBUTTON, AUTOCHECKBOX, AUTO3STATE, AUTORADIOBUTTON, PUSHBOX, STATE3, COMBOBOX, LTEXT, RTEXT, CTEXT, CHECKBOX, EDITTEXT, LISTBOX* and *SCROLLBAR*.

## [:top:](#TABLE OF CONTENTS)<a name="STRINGTABLE MACROS"></a>STRINGTABLE MACROS

One string table can hold up to 16 strings. If you have more than 16 strings you need to open another table. Each table referenced by one resource ID in resource tree. Normal resource compilers needs you put string ID's in the table. We don't use this method here. Instead we put strings in table without ID but with implied index. First string has index 1, second is 2 and so on. When you need to reference a string in a table use SID() macro which stands for string ID. This macro excpects
2 parameters. First one is resource ID of table defined in resource tree and second one is index of string. SID() macro returns calculated ID of each string in a table.

```
push buffer_size  
push VA(buffer)  
push SID(ID_TABLE, 1)        ; loads first string  
push dword [VA(hInstance)]  
call [VA(LoadStringA)]   
```

Strings  in tables are stored as 16-bit unicode strings. That means when you create a buffer you need twice size of a char. In asm that equals size of a word.

```
STRINGTABLE label  
  STRING 'First String'  
  STRING 'Second String'  
  STRING 'Third String'  
  ...  
  STRING '16th string'  
ENDSTRINGTABLE  
```

## [:top:](#TABLE OF CONTENTS)<a name="ACCELERATORTABLE MACROS"></a>ACCELERATORTABLE MACROS

With ACCELERATORTABLE macros you can include accelerators into your resources. Then you can use them inside asm with the help of LoadAccelerator API. To start with accelerators first you need to include a resource of accelerator type into resource tree. Than add following table.

```
ACCELERATORTABLE accelerator
   ; %1 = ascii key or virtual key,  %2 = ID of key,  %3 = flags
   ACCELERATOR 'A', ID_ACTION_SHIFT_A, FSHIFT
   ACCELERATOR VK_F5, ID_ACTION_CONTROL_F5, FCONTROL | FVIRTKEY
   ACCELERATOR VK_RETURN, ID_ACTION_ALT_ENTER, FALT | FVIRTKEY
   
   ; default flag is shift key
   ACCELERATOR 'H', IDM_FILE_HELP
ENDACCELERATORTABLE
```

## [:top:](#TABLE OF CONTENTS)<a name="BITMAP MACRO"></a>BITMAP MACRO

With BITMAP macro you can include bitmaps into your resources. Then you can use them inside asm code with LoadBitmap API. To start with bitmaps first include an resource of type RT_BITMAP into resource tree. Than add file with BITMAP macro. Sample application is given in samples directory.

```
; %1 = label
; %2 = Bitmap file in string form

BITMAP bitmap1, 'bitmap.bmp'
```