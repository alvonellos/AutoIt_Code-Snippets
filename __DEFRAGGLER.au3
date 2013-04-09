#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	AutoIt Wrapper for Defraggler, so that you can run
	it in the background, from within your scripts.

	Changelog:
	  08/13/12 -- Created


	Readme:
		Sample usage:
			#include the header, and make sure that works in your script.
			Then call __DEFRAGGLER__CLEAN() and supply it with a function
			you use to setup your logging.
#ce ----------------------------------------------------------------------------
#include-once
#include "..\Include\__GENERAL.au3"



; When __DEFRAGGLER__INITIALIZE() is called, this variable
; is set to true. When
Global $PRIVATE__DEFRAGGLER__bIS_INITIALIZED = False
Global $__DEFRAGGLER__szPARAMS = "C: /QD"
; PRIVATE__DEFRAGGLER__TEST()
; Clean the system of crap
Func PRIVATE__DEFRAGGLER__TEST()
	__DEFRAGGLER__DEFRAG()
EndFunc

; Initializes __DEFRAGGLER
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;	True if initialization was successful
;   False otherwise
Func __DEFRAGGLER__INITIALIZE($szLogFuncHandler = "PRIVATE__DEFRAGGLER__CERR")
	$PRIVATE__DEFRAGGLER__bIS_INITIALIZED = True
	Local $iResult1 = FileInstall("..\Include\bin\defraggler\df.exe", "C:\df.exe", 1)
	Local $iAcc = $iResult1

	If( $iAcc <> 1 ) Then
		Call($szLogFuncHandler, $iAcc & "In __DEFRAGGLER__INITIALIZE(), possible error initializing: " & _
		 $iResult1 )
		Return False
	Else
		Return True
	EndIf
EndFunc


; Runs defraggler
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;  Nothin
Func __DEFRAGGLER__DEFRAG($szLogFuncHandler = "PRIVATE__DEFRAGGLER__CERR")
	If(ProcessExists("df.exe")) Then
		Call($szLogFuncHandler, "In __DEFRAGGLER__DEFRAG(), __DEFRAG() was called while df.exe is still running.")
		Return
	EndIf

	If( $PRIVATE__DEFRAGGLER__bIS_INITIALIZED = False ) Then
		__DEFRAGGLER__INITIALIZE($szLogFuncHandler)
	EndIf
	Local $iResult = RunWait("C:\df.exe" & " " & $__DEFRAGGLER__szPARAMS, @WorkingDir, @SW_HIDE)
	; Call($szLogFuncHandler, "In __DEFRAGFGLER__DEFRAG(), using disabled version")
	Call($szLogFuncHandler, "In __DEFRAGGLER__DEFRAG(), working")
	If( $iResult = 0 And @error <> 0) Then
		Local $iFileExists = FileExists("C:\df.exe")
		Call($szLogFuncHandler, "In __DEFRAGGLER__DEFRAG(), possible error" & _
		"running defraggler, RunWait() returned: " & $iResult & " : " & $iFileExists)
   EndIf
   $PRIVATE__DEFRAGGLER__bIS_INITIALIZED = False
	PRIVATE__DEFRAGGLER__CLEANUP()
EndFunc

Func PRIVATE__DEFRAGGLER__CERR($szMessage)
	__GENERAL__CERR($szMessage)
EndFunc

; Cleans up mess.
Func PRIVATE__DEFRAGGLER__CLEANUP()
	If( ProcessExists("df.exe") ) Then
		; Do nothing
	Else
		FileDelete("C:\df.exe")
	EndIf
EndFunc
