#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	Test Singleton

 Changelog:
	06/13/12 - Created and working as of 06/13/12

#ce ----------------------------------------------------------------------------

#include <Misc.au3>
#include-once

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
