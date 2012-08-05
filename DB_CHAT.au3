#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	A chat client over DB

#ce ----------------------------------------------------------------------------

#include "..\Include\__DROPBOX.au3"
HotKeySet("^s", "input")
HotKeySet("{ESC}", "abort")
main()
Func abort()
	__DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir)
	Exit
EndFunc

Func main()
	__DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir, "dumb")
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "DGparser", "dumb")
	While True
		Sleep(10)
	WEnd
EndFunc

Func dumb($msg)

EndFunc
Func DGparser($hFile)
	Local $szDatum = FileRead($hFile, -1)
	Local $aszSplitDG = StringSplit($szDatum, @LF)
	; _ArrayDisplay($aszSplitDG)
	Local $display = $aszSplitDG[2] & "@" & $aszSplitDG[1] & ": "
	If( $aszSplitDG[0] > 4 ) Then
		For $i = 4 To $aszSplitDG[0]-1 Step 1
			ConsoleWrite($display & $aszSplitDG[$i] & @LF)
		Next
	Else
		ConsoleWrite($display & $aszSplitDG[4] & @LF)
	EndIf
EndFunc

Func input()
		Local $input = InputBox("", "enter message", "none", "", 100, 100)
		__DROPBOX__COMM__WRITE("comm", @ScriptDir, $input, "dumb")
EndFunc