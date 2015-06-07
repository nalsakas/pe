For a long time I wanted to directly produce PE32, DLL32, PE64 and DLL64 files from the output of nasm assembler. Nasm doesn't have a direct output executable file but instead it has raw binary output and has advanced macro support. My aim in this project is to use nasm's macro capability and bin output together to directly produce executables. In order to make that happen I need to invent pretty a lot new macros. Some of them are PE header structures, section tables, data directories, etc.
Why I created this macro sets? Answer is simple. Because I have a passion about inner workings of executables. Apart from because of this project I also have learned a lot while writing nasm macros and writing about pe file format.
With these macro sets you can do amazing executables by yourself. You don't need any linker whatsoever. You can include any function you want to import by typing its library and name; you can export any local function; you can prepare resources of your application by your hand in the same source; you can experiment and get a deeper insight of pe format; etc. 
Although there will be a lot of macros beneath, end user only need to know a few user space macros. An example usage is given below. As you notice names and usage is pretty easy.

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
EXPORT
   ; write down local functions to export
   FUNC LocalFunction
   ...
ENDEXPORT

; Setup Resource Directory if you need to
RESOURCE
  ; I am working on details
ENDRESOURCE

END
; End of executable

You can find detailed analysis of user space macros below. Have fun.