#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	I'm lazy. Really lazy. So lazy that I'd rather #include
	something than have to write it over and over and over
	again. I've found that _Singleton is something that I
	use a lot, so I put it in this file. 

	All you have to do is #include it. 

 Changelog:
	06/13/12 - Created and working as of 06/13/12

#ce ----------------------------------------------------------------------------

#include <Misc.au3>
#include-once
__SINGLETON_SINGLETON()
; My version of singleton. To use it, include
; the header
Func __SINGLETON_SINGLETON()
	If (_Singleton(@ScriptName, 0) = 0) Then ; Another script exists
		ConsoleWrite("Another script: " & @ScriptName & @LF)
		Exit
	Else
		Return
	EndIf
EndFunc   ;==>__SINGLETON_SINGLETON
