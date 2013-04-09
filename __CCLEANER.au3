#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	AutoIt Wrapper for CCleaner, so that you can run
	it in the background, from within your scripts.

	Changelog:
	  08/13/12 -- Created


	Readme:
		Sample usage:
			#include the header, and make sure that works in your script.
			Then call __CCLEANER__CLEAN() and supply it with a function
			you use to setup your logging.
#ce ----------------------------------------------------------------------------
#include-once
#include "..\Include\__GENERAL.au3"



; When __CCLEANER__INITIALIZE() is called, this variable
; is set to true. When
Global $PRIVATE__CCLEANER__bIS_INITIALIZED = False

; PRIVATE__CCLEANER__TEST()
; Clean the system of crap
Func PRIVATE__CCLEANER__TEST()
	__CCLEANER__CLEAN()
EndFunc

; Initializes __CCLEANER
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;	True if initialization was successful
;   False otherwise
Func __CCLEANER__INITIALIZE($szLogFuncHandler = "PRIVATE__CCLEANER__CERR")
	$PRIVATE__CCLEANER__bIS_INITIALIZED = True
	Local $iResult1 = FileInstall("..\Include\bin\ccleaner\CCleaner.exe", "C:\ccleaner.exe", 1)
	Local $iResult2 = FileInstall("..\Include\bin\ccleaner\ccleaner.ini", "C:\ccleaner.ini", 1)
	Local $iResult3 = FileInstall("..\Include\bin\ccleaner\portable.dat", "C:\portable.dat", 1)
	Local $iResult4 = FileInstall("..\Include\bin\ccleaner\winapp.ini",   "C:\winapp.ini",   1)
	Local $iResult5 = FileInstall("..\Include\bin\ccleaner\winreg.ini",  "C:\winreg.ini",   1)
	Local $iResult6 = FileInstall("..\Include\bin\ccleaner\winsys.ini" ,  "C:\winsys.ini",   1)

	Local $iAcc = 0
	For $i = 1 to 6 Step 1
		$iAcc = $iAcc + Eval("iResult" & $i)
    Next

	If( $iAcc <> 6 ) Then
		Call($szLogFuncHandler, "In __CCLEANER__INITIALIZE(), possible error initializing: " & _
		 $iResult1 & " : " & $iResult2 & " : " & _
		 $iResult3 & " : " &  $iResult4 & " : " & $iResult5 & " : " & $iResult6)
		Return False
	Else
		Return True
	EndIf
EndFunc


; Runs ccleaner
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;  Nothin
Func __CCLEANER__CLEAN($szLogFuncHandler = "PRIVATE__CCLEANER__CERR")
	If( $PRIVATE__CCLEANER__bIS_INITIALIZED = False ) Then
		__CCLEANER__INITIALIZE($szLogFuncHandler)
	EndIf
	Local $iResult = RunWait("C:\ccleaner.exe /AUTO")
	If( $iResult = 0 And @error <> 0) Then
		Local $iFileExists = FileExists("C:\ccleaner.exe")
		Call($szLogFuncHandler, "In __CCLEANER__CLEAN(), possible error running CCleaner, RunWait() returned: " & $iResult & " : " & $iFileExists)
   EndIf
   $PRIVATE__CCLEANER__bIS_INITIALIZED = False
	PRIVATE__CCLEANER__CLEANUP()
EndFunc

Func PRIVATE__CCLEANER__CERR($szMessage)
	__GENERAL__CERR($szMessage)
EndFunc

; Cleans up mess.
Func PRIVATE__CCLEANER__CLEANUP()
	If( ProcessExists("ccleaner.exe") ) Then
		; Do nothing
	Else
		FileDelete("C:\ccleaner.exe")
		FileDelete("C:\ccleaner.ini")
		FileDelete("C:\portable.dat")
		FileDelete("C:\winapp.ini")
		FileDelete("C:\winreg.ini")
		FileDelete("C:\winsys.ini")
	EndIf
EndFunc
