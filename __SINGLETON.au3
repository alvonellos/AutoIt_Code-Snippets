#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	This is a wrapper for Singleton().

 Changelog:
	06/13/12 - Created and working as of 06/13/12
	08/18/12 - Added a function to call a legacy function
			   that doesn't conform to convention.
#ce ----------------------------------------------------------------------------

#include <Misc.au3>
#include-once

; My version of singleton. To use it, include
; the header

; This is really bad, but when I wrote this,
; I didn't use the __ convention after the
; "namespace" name, I only used a single
; underscore. So, TODO....
; TODO:
;  Fix this and all scripts that include this
; This should work for now.
Func __SINGLETON__SINGLETON()
	__SINGLETON__SINGLETON()
EndFunc

Func __SINGLETON_SINGLETON()
	If (_Singleton(@ScriptName, 0) = 0) Then ; Another script exists
		ConsoleWrite("Another script: " & @ScriptName & @LF)
		Exit
	Else
		Return
	EndIf
EndFunc   ;==>__SINGLETON_SINGLETON
