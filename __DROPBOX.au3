#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
		Misc collection of functions to be
	used with dropbox.

	This version is the Beta version that's currently in development,
	not to say that the regular dropbox.au3 file is finished, but it
	at least works (somewhat) correctly in the __COMM part of the
	function

	We've got a few bugs laying around here. Read through the code
	completely and understand how it works before using it. I
	wouldn't recommend using it as-is right now. 

#ce ----------------------------------------------------------------------------
#include-once
#include <Process.au3>
#include <Misc.au3>
#include <Date.au3>
#include <Array.au3>
#include <File.au3>

;; Configuration Options
Global $__DROPBOX__iPROCESSWAIT_INTERVAL = 1
Global $__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD = 500
Global $__DROPBOX__iDEFAULT_MAX_REGISTERED_SUBSCRIBERS = 1024
;; End configutation options.

;; Globals
Global $__DROPBOX__REGISTERED_SUBSCRIBERS = 0

; Contains a pipe delimited string containing
; function names to call. (Used in __PARSE_SUBSCRIBERS
; and __SUBSCRIBE and UNSUBSCRIBE)
Global $__DROPBOX__szREGISTERED_FUNCTIONS = ""
;; End globals
 ;;__DROPBOX__TEST()

; This function demonstrates is used to test
; the UDF while in development and serves as
; a reference on how to use it.
Func __DROPBOX__TEST()
	;ConsoleWrite("__DROPBOX__CHECK_EXIST:> " & __DROPBOX__CHECK_EXIST() & @LF)
	;ConsoleWrite("__DROPBOX__INITIALIZE():> " & __DROPBOX__INITIALIZE() & @LF)
	;ConsoleWrite("__DROPBOX__TERMINATE():> " & __DROPBOX__TERMINATE() & @LF)
	;ConsoleWrite("__DROPBOX__INITIALIZE():> " & __DROPBOX__INITIALIZE() & @LF)
	 __DROPBOX__COMM__CREATE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	;__DROPBOX__COMM__REMOVE_CHANNEL(@ScriptDir, "__DROPBOX__CERR")
	Local $strBuf = ""
	$strBuf = "They Call Me Data"

	__DROPBOX__COMM__WRITE("comm", @ScriptDir, $strBuf)
	Sleep(10000)
	;__DROPBOX__COMM__READ("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	Sleep(10000)
	;; __DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	; __DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER_2")
	Sleep(5000)
	__DROPBOX__COMM__WRITE("comm", @ScriptDir, $strBuf)
	Sleep(5000)
	__DROPBOX__COMM__UNSUBSCRIBE_FUNCTION("__DROPBOX__COMM__READ__DEMO_READER_2")
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	Sleep(10000)
	__DROPBOX__COMM__WRITE("comm", @ScriptDir, $strBuf)

	;__DROPBOX__COMM__PURGE("comm", @ScriptDir)
	; __DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	ConsoleWrite("Hit bottom" & @LF)
	Sleep(10000)
	__DROPBOX__COMM__PURGE("comm", @ScriptDir)
	Sleep(10000)
	While True
		Sleep(10000)
		;__DROPBOX__COMM__WRITE("comm", @ScriptDir, $strBuf)
	WEnd
	Return
EndFunc

Func __DROPBOX__COMM__READ__DEMO_READER_2($hFile)
	Local $szDatum = FileRead($hFile, -1) ; Read to end
	ConsoleWrite("-----------------__DROPBOX__COMM__READ__DEMO_READER_2---------------------------" & @LF)
	ConsoleWrite($szDatum & @LF)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
EndFunc

; Checks if Dropbox is an active
; process on the system.
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;    True if active
;    False if not.
Func __DROPBOX__CHECK_EXIST($szLogFuncHandler = "__DROPBOX__CERR")
	Local $iProcessResult = ProcessWait("Dropbox.exe", $__DROPBOX__iPROCESSWAIT_INTERVAL)
	If(  $iProcessResult <> 0 ) Then
		; Dropbox exists
		Call($szLogFuncHandler, "In __DROPBOX_CHECK_EXIST(), dropbox appears to be running.")
		Return True
	Else
		; Dropbox doesn't exist
		Call($szLogFuncHandler, "In __DROPBOX_CHECK_EXIST(), dropbox does not appear to be running.")
		Return False
	EndIf
EndFunc

; Terminates the dropbox
; process on the system
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;   True: successful
;   False: otherwise
; @error:
;  -2: Last ditch effort to terminate dropbox failed
;  -1: Unknown error terminating dropbox
;   0: Successfully terminated dropbox
;   1: OpenProcess failed
;   2: AdjustTokenPrivileges failed
;   3: TerminateProcess failed
;   4: Cannot verify if process exists
;   5: Unknown error. Bad magic
; Remarks:
;  If dropbox isn't running on
;  the system, then this func
;  will return true anyways.
Func __DROPBOX__TERMINATE($szLogFuncHandler = "__DROPBOX__CERR")
	Local $bReturnValue = False
	Call($szLogFuncHandler, "In __DROPBOX__TERMINATE()")
	If(ProcessExists("Dropbox.exe")) Then
	   Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), dropbox exists, killing")

	   Local $result = ProcessClose("Dropbox.exe")
	   If( $result = 1 ) Then ; Terminated Dropbox, exiting
		  Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), successfully terminated dropbox")
		  SetError(0)
		  $bReturnValue = True
	   Else
		 Select
		 Case @error = 1
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), OpenProcess failed")
			SetError(1)
		 Case @error = 2
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), AdjustTokenPrivileges failed")
			SetError(2)
		 Case @error = 3
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), TerminateProcess failed")
			SetError(3)
		 Case @error = 4
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), Cannot verify if process exists")
			SetError(4)
		 Case Else
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), there was an error and I don't know what caused it.")
			SetError(-1)
		 EndSelect
		 ; Fall back and do everything to kill DropBox
		 If(ProcessExists("Dropbox.exe")) Then
			Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), we've done almost everything to terminate dropBox(), making a last ditch effort.")
			$result = _RunDos("taskkill /f /im Dropbox.exe")
			If( @error <> 0 ) Then
			   Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), last ditch effort to kill Dropbox failed. We're going to bomb now.")
			   SetError(-2)
			   $bReturnValue = False
			Else
			   Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), last ditch effort succeeded!")
			   $bReturnValue = True
			EndIf
		 EndIf
	  EndIf
   Else
	  Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), dropbox isn't running")
	  $bReturnValue = True
   EndIf
	Call($szLogFuncHandler, "In __DROPBOX__TERMINATE(), exiting")
	Return $bReturnValue
EndFunc

; Initializes (starts)
; dropbox on the host
; system.
;
; Parameters:
; [$szLogFuncHandler]
;   A string function that takes
;   a single parameter and is
;   used to write log info.
; Returns:
;  If successful:
;    Returns True
;  Otherwise:
;     Returns False and sets @error
;    @error:
; 	   -1: If dropbox dir not found
;      -2: Other problem.
Func __DROPBOX__INITIALIZE($szLogFuncHandler = "__DROPBOX__CERR")
	Local $szDropBoxDir = @AppDataDir & "\Dropbox\bin"
	If( FileExists($szDropBoxDir) = 0 ) Then
		Call($szLogFuncHandler, "In __DROPBOX__INITIALIZE(), cannot find dropbox directory")
		; Dropbox directory doesn't exist
		SetError(-1)
		Return False
	Else
		; Dropbox directory exists
		Local $iResult = Run($szDropBoxDir & "\Dropbox.exe", "", @SW_HIDE)
		Call($szLogFuncHandler, "In __DROPBOX__INITIALIZE(), " & _
			_Iif($iResult <> 0, "successfully started dropbox.", _
			"unsuccessfully started dropbox.") & _
			" PID: " & $iResult)
		If($iResult <> 0 ) Then
			Return True
		Else
			Call($szLogFuncHandler, "In __DROPBOX__INITIALIZE(), failed to start dropbox.")
			SetError(-2)
			Return False
		EndIf
	EndIf
EndFunc

; This function creates a channel in the specified directory
; for communications to go through.
;
; Parameters:
;    $szChannelName: A string describing the channel
;    $szChannelPath: The path to create the channel in.
;    $szLogFuncHandler: A string containing a function name
;                       to call with log information.
; Returns:
;   True: If the channel was created successfully.
;   False: If the channel was not created successfully
;          (see @error)
; @error:
;    -1: General error creating channel directory.
;    -2: Error creating configuration file in channel.
;    -3: Channel already exists.
; Remarks:
;   TODO.
Func __DROPBOX__COMM__CREATE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler = "__DROPBOX__CERR")
	If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
		; The channel doesn't exist, create it.
		Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), Creating channel: " & $szChannelPath & "\" & $szChannelName)
		Local $oChannelCreationResult = DirCreate($szChannelPath & "\" & $szChannelName)
		If( $oChannelCreationResult = 0 ) Then ; There was a problem
			Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), there was an error creating the channel.")
			SetError(-1)
			Return False
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), Channel created, result: " & $oChannelCreationResult)
			Local $oChannelIniCreationResult = IniWrite($szChannelPath & "\" & $szChannelName & "\" & $szChannelName & _
												".ini" , $szChannelName & "-Creator", @ComputerName, __DROPBOX__COMM__EPOCH())
			Local $oChannelIniCreationResult2 = IniWrite($szChannelPath & "\" & $szChannelName & "\" & @ComputerName & _
												".ini" , $szChannelName & "-Creator", @ComputerName, __DROPBOX__COMM__EPOCH())
			If( $oChannelCreationResult = 0) Then ; There was a problem
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), there was an error creating INI file for the channel")
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), cleaning up...")
				$bCleanupResult = __DROPBOX__COMM__REMOVE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler)
				; TODO: Add error handling code here (for __DROPBOX__COMM__REMOVE_CHANNEL())
				SetError(-2)
				Return False
			Else
				SetError(0)
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), creating channel configuration file. Result: " & $oChannelIniCreationResult)
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), channel " & $szChannelName & " created successfully.")
				Return True
			EndIf
		EndIf
	Else
		; Channel exists
		Call($szLogFuncHandler, "In __DROPBOX__COMM_CREATE_CHANNEL(), channel already exists.")
		SetError(-3)
		Return False
	EndIf
EndFunc

; TODO!!!!
; This function removes a channel in the specified directory
; for communications to go through.
;
; Parameters:
;    $szChannelName: A string describing the channel
;    $szChannelPath: The path to create the channel in.
;    $szLogFuncHandler: A string containing a function name
;                       to call with log information.
; Returns:
;   True: If the channel was removed successfully
;         (see @error)
;   False: If the channel was not removed successfully
;          (see @error)
; @error:
;    -1: General error unsubscribing from channel. (See @extended)
;    -2: Error unsubscribing from channel,
;         --> See @extended
;    -3: Channel doesn't exist.
; @extended:
;    Set to the return value of unsubscribe on error..
;
; Remarks:
;   TODO: Finish fixing this (so that it can remove a channel without removing all
;         subscribers from all channels.
;   Looks like there is a bug in UNSUBSCRIBE_FUNCTION
Func __DROPBOX__COMM__REMOVE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler = "__DROPBOX__CERR")
	If( FileExists($szChannelPath & "\" & $szChannelName) = 1 ) Then ; Channel exists
		Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), file exists")
		; Remove all the datagrams & channel directory.
		$bReturnValue = __DROPBOX__COMM__UNSUBSCRIBE("-1", $szLogFuncHandler)
		#cs
		;	-- This is a bugfix that fixes an issue where calling this function
		;   -- While there is more than one channel subscribed will unsubscribe all
		;	-- functions from all channels.
		Local $bReturnValue = False
		Local $i = 0
		Local $aszFuncListing = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
		For $i = 1 To $aszFuncListing[0]-1 Step 1
			Local $chan = ""
			Local $path = ""
			Local $name = ""
			Local $logf = ""
			Local $bGetDataResult = __DROPBOX__COMM__GET_FUNCTION_DATA($aszFuncListing[$i], $chan, $path, $name, $logf, $szLogFuncHandler)
			If( $bGetDataResult = False ) Then
				; There was a problem
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), there was an error retrieving data for function " & $aszFuncListing[$i] & ".")
				$bReturnValue = False
			Else
				Local $szChannelCombParam = $szChannelPath & "\" & $szChannelName
				Local $szChannelCombDatum = $chan & "\" & $path
				If( StringCompare($szChannelCombParam, $szChannelCombDatum, 2) = 0 ) Then
					; Both are equal, so remove it.
					ConsoleWrite("In __DROPBOX__COMM__REMOVE_CHANNEL(), removing " & $aszFuncListing[$i] & " from " & $szChannelName & "." & @lF)
					__DROPBOX__COMM__UNSUBSCRIBE($aszFuncListing[$i], $szLogFuncHandler)
				Else
					; Not a match, for now
					ConsoleWrite("In __DROPBOX__COMM__REMOVE_CHANNEL(), did not remove " & $aszFuncListing[$i] & " from " & $szChannelName & "." & @lF)
					ConsoleWrite("---> Mismatch: " & $chan & " " & $path & " " & $name & " " & $logf & @LF)
				EndIf
		#ce
		If($bReturnValue = False) Then
			; __DROPBOX__COMM__UNSUBSCRIBE() throws errors if there was an error deallocating memory, or if
			; there was no subscriber attached to the thread. Both of these threads are non-fatal -- so
			; what we can do here is just continue... but first, let's retrieve the value stored in @error and
			; in @extended before we call the log-handler (because call can reset both of those to be 0xDEADBEEF
			; and I don't want that.
			Local $tmpaterror = @error
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), error unsubscribing from channel. @error: " & @error)
			SetError(-2)
			SetExtended($tmpaterror)
		EndIf

		Local $oChannelDeletionResult = DirRemove($szChannelPath & "\" & $szChannelName, 1)
		If( $oChannelDeletionResult = 0 ) Then ; There was a problem.
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), error removing channel dir.")
			If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
				; Dir doesn't exist, but, prior to entering this section of the massive IF statment
				; (the one in the beginning), the directory must have existed for us to get to this
				; point, and for the control flow to get here at this point means that we're at a
				; logical contradiction... and therefore there's a bug in the logic.
				;
				; Code can't just magically change it's mind, that's why I call it bad magic.
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel dir doesn't exist. BAD MAGIC")
				SetError(-3)
				Return True
			Else
				Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel exists, but cannot be deleted.")
				SetError(-4)
				Return False
			EndIf
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), successfully removed channel.")
			Return True
		EndIf
	Else
		Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), channel dir doesn't exist.")
		SetError(-3)
		Return True
	EndIf
	Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), BAD MAGIC ON: " & @ScriptLineNumber)
	; I just had a feeling.
EndFunc

; Not intended to be called from the outside,
; but this function execs the stuff that was
; assigned in __SUBSCRIBE().
Func PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS()
	Local $i = 0
	 ;ConsoleWrite("DEBUG: " & "Called" & @LF)
	 ; Left off here.
	 ; Gotta write some code to parse through
	 ; __DROPBOX__list subscribers bla bla bla
	 ; and then figure out how to iterate
     ;	 through
	 ; that mess in this function.
	 Local $aszListing = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
	 ; _ArrayDisplay($aszListing, "Stuff")
	For $i = 1 To $aszListing[0]-1 Step 1
		; ConsoleWrite("DEBUG: " & $aszListing[$i])
		;__PRIVATE__DROPBOX__COMM__SUBSCRIBE_
		Local $chan = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szChannelName")
		;ConsoleWrite("DEBUG: " & $chan & @LF)
		Local $path = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szChannelPath")
		;ConsoleWrite("DEBUG: " & $path & @LF)
		Local $hand = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szFuncDataHandler")
		; ConsoleWrite("DEBUG: " & Eval($hand) & @LF)
		Local $logf = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$aszListing[$i] & "_szLogFuncHandler")
		;ConsoleWrite("DEBUG: " & $logf & @LF)
		__DROPBOX__COMM__READ($chan, $path, $hand, $logf)
	Next
EndFunc

; This function takes a single parameter, $szFunctionName,
; that denotes the name of the subscribed function, as would
; be used as a parameter to Call() and gets the data associated
; , internally, with that function, such as the channel name,
; channel path, and log functions and such associated with
; that function.
;
; Parameters:
;    $szFunctionName: The name of the function, as would be used
;                     as a parameter to Call()
;    $_szChannelName: A variable to store the channel name in
;    $_szChannelPath: A variable to store the channel path in
;    $_szFuncDataHandler: A variable to store the name of the
;                        function used to parse input data.
;                        In this case, this parameter is
;                        redundant and will be assigned
;                        the same data as what was supplied
;                        in $szFunctionName.
;	$_szLogFuncHandler:  A variable to store the name of the
;                       function called for logging purposes.
;    $szLogFuncHandler: The name of the function to call with
;						logging information.
; Returns:
;	If successful:
;		1. Returns True
;		2. Sets @error to 0
;       3. Assigns the appropriate
;		   data to the supplied ByRef
;          variables
;   If not successful:
;		1. Returns False
;		2. Sets @error as appropriate
;		3. Assigns "" to all the provided
;		   variables.
; @error:
;    0: No problems.
;   -1: Problem reading data from global variables.
;
; Remarks:
;   None.

Func __DROPBOX__COMM__GET_FUNCTION_DATA($szFunctionName, _
									    ByRef $_szChannelName, ByRef $_szChannelPath, _
										ByRef $_szFuncDataHandler, ByRef $_szLogFuncHandler, _
										$szLogFuncHandler = "__DROPBOX__CERR")

		Local $j1 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szChannelName")
		;ConsoleWrite("DEBUG: " & $chan & @LF)
		Local $j2 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szChannelPath")
		;ConsoleWrite("DEBUG: " & $path & @LF)
		Local $j3 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szFuncDataHandler")
		; ConsoleWrite("DEBUG: " & Eval($hand) & @LF)
		Local $j4 = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFunctionName & "_szLogFuncHandler")

		If( ($j1 & $j2 & $j3 & $j4) <> "") Then
			; No problems.
			SetError(0)
			Call($szLogFuncHandler, "In __DROPBOX__COMM__GET_FUNCTION_DATA(), successfully retrieved function data")
			Return True
		Else
			Local $szLogErrMessageForAssign = "Failed to retrieve the following data for the function " & $szFunctionName & ": "
			If( $j1 = 0 ) Then
				$szLogErrMessageForAssign &= "[Channel Name] "
			EndIf

			If( $j2 = 0 ) Then
				$szLogErrMessageForAssign &= "[Channel Path] "
			EndIf

			If( $j3 = 0 ) Then
				$szLogErrMessageForAssign &= "[Data Handler] "
			EndIf

			If( $j4 = 0 ) Then
				$szLogErrMessageForAssign &= "[Channel Error Log Handler]."
			EndIf

			Call($szLogFuncHandler, "In __DROPBOX__COMM__GET_FUNCTION_DATA(), " & $szLogErrMessageForAssign)
			SetError(-1)
			Return False
		EndIf
EndFunc

; This function subscribes a function specified by
; a parameter to changes made in the specified channel
; name. The function specified is called using AdLibRegister.
;
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;    $szFuncDataHandler: A string describing a function
;                        to be called when changes are
;                        made in the channel
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful
;   False: If not successful, and sets @error
; @error:
;    0: Channel doesn't exist.
;   -1: Max number of subscribers reached
;   -2: Problem assigning data to vars.
;
; Remarks:
;   At this point, I've only coded this library to handle
;   only one subscriber at a time. It wouldn't be too hard
;   to add it, but I'm working on it...
Func __DROPBOX__COMM__SUBSCRIBE($szChannelName, $szChannelPath, $szFuncDataHandler, $szLogFuncHandler = "__DROPBOX__CERR")
	If( FileExists($szChannelPath & "\" & $szChannelName) = 0 ) Then
		SetError(0)
		Return False
	EndIf

	If( _
		$__DROPBOX__REGISTERED_SUBSCRIBERS = 0 _
		OR _
		$__DROPBOX__REGISTERED_SUBSCRIBERS < $__DROPBOX__iDEFAULT_MAX_REGISTERED_SUBSCRIBERS _
	   ) Then

		Local $oChannelIniCreationResult = IniWrite($szChannelPath & "\" & $szChannelName & "\" & _
				@ComputerName & ".ini" , $szChannelName & "-Listening", $szFuncDataHandler, _
				__DROPBOX__COMM__EPOCH())

		$__DROPBOX__REGISTERED_SUBSCRIBERS = $__DROPBOX__REGISTERED_SUBSCRIBERS + 1
		$__DROPBOX__szREGISTERED_FUNCTIONS &= $szFuncDataHandler & "|"
		Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), adding subscriber " & "#" & _
		     $__DROPBOX__REGISTERED_SUBSCRIBERS &" : " & $szFuncDataHandler & "().")
		Local $j1 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFuncDataHandler & "_szChannelName", $szChannelName, 2)
		Local $j2 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFuncDataHandler & "_szChannelPath", $szChannelPath, 2)
		Local $j3 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szFuncDataHandler & "_szFuncDataHandler", $szFuncDataHandler, 2)
		Local $j4 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
					$szLogFuncHandler & "_szLogFuncHandler", $szLogFuncHandler, 2)
		;ConsoleWrite($j1 & " :: " & $j2 & " :: " & $j3 & " :: " & $j4 & @LF)

		If( ($j1 + $j2 + $j3 + $j4) = 4) Then
			If( $__DROPBOX__REGISTERED_SUBSCRIBERS <= 1 ) Then
				AdlibRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS", _
							$__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD)
			EndIf
			Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), successfully added subscriber.")
			Return True
		Else
			Local $szLogErrMessageForAssign = "The following assignments have failed: "
			If( $j1 = 0 ) Then
				$szLogErrMessageForAssign &= "$j1, "
			EndIf

			If( $j2 = 0 ) Then
				$szLogErrMessageForAssign &= "$j2, "
			EndIf

			If( $j3 = 0 ) Then
				$szLogErrMessageForAssign &= "$j3, "
			EndIf

			If( $j4 = 0 ) Then
				$szLogErrMessageForAssign &= "$j4."
			EndIf

			Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), there was a problem calling Assign()." & _
									$szLogErrMessageForAssign)
			SetError(-2)
			Return False
		EndIf
	Else
		Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), attempted to subscribe handler when limit reached")
		SetError(-1)
		Return False
	EndIf
EndFunc


; The following function is used by __UNSUBSCRIBE()
; to alert the user if a deadlock error happens where,
; __UNSUBSCRIBE() doesn't correctly unsubscribe a function
; from being called.
Func PRIVATE__DROPBOX__COMM__UNSUBSCRIBED_FUNC_TRIGGER($msg)
	Call("__DROPBOX__CERR", "In PRIVATE__DROPBOX__COMM__UNSUBSCRIBED_FUNC_TRIGGER(), " & _
					"A FUNCTION THAT HAS BEEN REMOVED FROM THE NOTIFY LIST " & _
					"HAS CALLED THIS FUNCTION, HERE IS THE DATA IT GAVE ME: " & _
					$msg)
EndFunc

; This function unsubscribes a previously assigned
; function from the specified channel residing in
; the specified path. The function specified is
; removed from being called using AdLibUnRegister.
;
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;    [$szFuncName = "-1"]: The function to unregister from
;                          the call. The default for this is
;                          "-1", which basically means unsub
;                          -scribe everything.
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful, @error is possibly set.
;   False: If not successful, and sets @error
;   -->    See Remarks
; @error:
;    0: No problems.
;   -1: No subscribers are registered.
;   -2: General failure
;
; Remarks:
; This function will always return true. Check @error for results.
Func __DROPBOX__COMM__UNSUBSCRIBE($szFuncDataHandler = "-1", $szLogFuncHandler = "__DROPBOX__CERR")
	If( $__DROPBOX__REGISTERED_SUBSCRIBERS < 1 ) Then
		Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), attempted to unsubscribe when there are no subscribers.")
		SetError(-1)
		Return False
	EndIf

	; This is where it gets hairy. If
	; the function is not -1, that means
	; we have to unsubscribe from an
	; individual function.
	If( $szFuncDataHandler <> "-1" ) Then
		Local $bResult = __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION($szFuncDataHandler, $szLogFuncHandler)
		If( $bResult = False ) Then
			Local $iErrorCode = @error
			Local $szErrorMsg = "In __DROPBOX__COMM_UNSUBSCRIBE(), error unsubscribing function " & $szFuncDataHandler & "."
			$szErrorMsg &= " Code: "

			Select
				Case $iErrorCode = 0
					$szErrorMsg &= " 0, meaning no problems. BAD MAGIC."
				Case $iErrorCode = -1
					$szErrorMsg &= " -1, meaning no subscribers are registered."
				Case $iErrorCode = -2
					$szErrorMsg &= " -2, meaning problem assigning data to function list."
				Case Else
					$szErrorMsg &= " BAD MAGIC."
			EndSelect
			SetError(-2)
			Call($szLogFuncHandler, $szErrorMsg)
		Else
			SetError(0)
			Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), removed callback function " & $szFuncDataHandler)
		EndIf
	Else
		; This clause means that we have to remove all the subscribed functions.
		Local $aszFuncListing = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
		Local $i = 0;
		For $i = 1 To $aszFuncListing[0]-1 Step 1
			Local $bResult = __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION($szFuncDataHandler, $szLogFuncHandler)
			If( $bResult = False ) Then
				Local $iErrorCode = @error
				Local $szErrorMsg = "In __DROPBOX__COMM_UNSUBSCRIBE(), error unsubscribing function " & $szFuncDataHandler & "."
				$szErrorMsg &= " Code: "
				Select
					Case $iErrorCode = 0
						$szErrorMsg &= " 0, meaning no problems. BAD MAGIC."
					Case $iErrorCode = -1
						$szErrorMsg &= " -1, meaning no subscribers are registered."
					Case $iErrorCode = -2
						$szErrorMsg &= " -2, meaning problem assigning data to function list."
					Case Else
						$szErrorMsg &= " BAD MAGIC."
				EndSelect
				SetError(-2)
				Call($szLogFuncHandler, $szErrorMsg)
			Else
				SetError(0)
				$__DROPBOX__REGISTERED_SUBSCRIBERS = $__DROPBOX__REGISTERED_SUBSCRIBERS - 1
				Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), removed callback function " & $szFuncDataHandler)
			EndIf
		Next

		; This is the major difference between the behavior of __SUBSCRIBE and
		; __UNSUBSCRIBE. No matter what happens, __UNSUBSCRIBE makes a best-effort
		; attempt to unregister the callback function from being called.
		; AdlibUnRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS")
		; Now, the really smart thing to do would be to do this:
		AdLibUnRegister()
		; Because, this way, it unregisters the last registered AdLib function

		$__DROPBOX__REGISTERED_SUBSCRIBERS = 0
		Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), removed callback function.")
	EndIf
	Return True
EndFunc

; This function unsubscribes a specified function
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;    [$szFuncName = "-1"]: The function to unregister from
;                          the call. The default for this is
;                          "-1", which basically means unsub
;                          -scribe everything.
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful, @error is possibly set.
;   False: If not successful, and sets @error
; @error:
;    0: No problems.
;   -1: Function not registered.
;   -2: Problem assigning data to vars.
; Remarks:
;   If you look in the source code and see the variables $f and
;   $f2, it's hard to understand why they're there.
;
;   $f is an alias of the function provided in $szFuncName
;   $f2 is a function used for debugging purposes to locate
;   functions that, are transparent to the program, but may
;   still be called by the program while it is reading info
;   from a channel.
;
;   It's a bit to wrap your head around, but if you've gotten
;   this far, you know what I mean.
Func __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION($szFuncName, $szLogFuncHandler = "__DROPBOX__CERR")
	If( $__DROPBOX__REGISTERED_SUBSCRIBERS < 1 ) Then
		Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), attempted to unsubscribe when there are no subscribers.")
		SetError(-1)
		Return False
	EndIf

	; $f is an alias for that damn long function name.
	Local $f2 = "PRIVATE__DROPBOX__COMM__UNSUBSCRIBED_FUNC_TRIGGER"
	Local $f = $szFuncName

	Local $chan = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & $f & "_szChannelName")
	Local $path = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & $f & "_szChannelPath")

	Local $j1 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szChannelName", "", 2)
	Local $j2 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szChannelPath", "", 2)
	Local $j3 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szFuncDataHandler", $f, 2)
	Local $j4 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_" & _
				$f & "_szLogFuncHandler", $f2, 2)
	Local $oChannelIniListDResult = IniWrite($path & "\" & $chan & "\" & _
				@ComputerName & ".ini" , $chan & "-Listening", $szFuncName, -1)

	If( ($j1 + $j2 + $j3 + $j4) = 4) Then
		Local $aszFuncListing = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
		Local $szNewRegisteredFunctionsList = ""
		; Perform a linear search on the function
		; list and locate the index of the unsubscribed
		; function and remove it
		Local $i = 0
		Local $iFoundIndex = -1
		For $i = 1 To $aszFuncListing[0]-1 Step 1
			Local $cmpr = StringCompare($szFuncName, $aszFuncListing[$i], 1) ; Case sensitive
			If( $cmpr = 0 ) Then
				; Found it
				$iFoundIndex = $i
			Else
				; Add the function to the new list
				$szNewRegisteredFunctionsList &= $aszFuncListing & "|"
			EndIf
		Next
		If( $iFoundIndex = -1 ) Then
			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), removal was successful. Function not found. BAD MAGIC.")
			SetError(-1)
		Else
			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), successfully removed subscriber info.")
			SetError(0)
		EndIf

	Else
		Local $szLogErrMessageForAssign = "The following assignments have failed: "
		If( $j1 = 0 ) Then
			$szLogErrMessageForAssign &= "$j1, "
		EndIf

		If( $j2 = 0 ) Then
			$szLogErrMessageForAssign &= "$j2, "
		EndIf

		If( $j3 = 0 ) Then
			$szLogErrMessageForAssign &= "$j3, "
		EndIf

		If( $j4 = 0 ) Then
			$szLogErrMessageForAssign &= "$j4."
		EndIf

		Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE_FUNCTION(), there was a problem calling Assign()." & _
								$szLogErrMessageForAssign)
		SetError(-2)
	EndIf
EndFunc


; This function writes the specified data
; to the specified channel residing in the
; specified path.
;
; Parameters:
;    $szChannelName: The channel name
;    $szChannelPath; The path the channel resides in
;    $szData: The data to transmit
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;    True: If successful
;    False: If not successful, and sets @error
; @error:
;    -1: Error opening up tmp datagram file for
;        writing.
;    -2: Error writing datagram information to
;        the file
;    -3: Error moving (renaming) file to .dg
;        extension. (See remarks)
;
; Remarks:
;  This function creates a file in the channel
;  with a name containing the current unix_epoch
;  time. Then it writes the following data to the
;  file:
;    Line 1) Unix epoch time of transmission
;    Line 2) Source
;    Line 3) Number of characters in transmission
;    Line 4) Actual transmission data (specified
;            in $szData)
;  After the data is written to the file, it is
;  saved in the dropbox and then renamed to have
;  a ".dg" extension, which stands for datagram.
;
;  The reasoning behind this is that it solves the
;  file locking problem that can sometimes happen
;  when a client is listening while another is
;  writing the information. (See __READ())
Func __DROPBOX__COMM__WRITE($szChannelName, $szChannelPath, $szData, $szLogFuncHandler = "__DROPBOX__CERR")
	Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), transmitting information...")
	Local $DatumBuff = ""
	Local $TxTime = __DROPBOX__COMM__EPOCH()
	$DatumBuff &= $TxTime & @LF
	$DatumBuff &= @ComputerName & @LF
	$DatumBuff &= StringLen($szData) & @LF
	$DatumBuff &= $szData
	$szFileName = $szChannelPath & "\" & $szChannelName & "\" & $TxTime
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	Local $hFileOpenHandle = FileOpen($szFileName, 10)
	If( $hFileOpenHandle = -1 ) Then ; There was an error
		Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), there was an error opening file for writing.")
		SetError(-1)
		Return False
	Else
		Local $iFileWriteResults = FileWrite($hFileOpenHandle, $DatumBuff)
		If( $iFileWriteResults = 0 ) Then ; There was an error
			Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), there was an error writing to the file.")
			SetError(-2)
			Return False
		Else
			FileFlush($hFileOpenHandle)
			FileClose($hFileOpenHandle)
			Local $iFileMoveResults = FileMove($szFileName, $szFileName & ".dg", 1)
			If( $iFileMoveResults = 0 ) Then ; There was an error
				Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), there was an error moving file to .dg ext.")
				SetError(-3)
				Return False
			Else
				IniWrite($szChannelComb & "\" & @ComputerName & ".ini", _
				$szChannelName & "-LastTx", @ComputerName, $TxTime)
				Call($szLogFuncHandler, "In __DROPBOX__COMM__WRITE(), successfully transmitted datagram.")
				SetError(0)
				Return True
			EndIf
		EndIf
	EndIf
EndFunc

Func __DROPBOX__COMM__READ__DEMO_READER($hFile)
	$szDatum = FileRead($hFile, -1) ; Read to end
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
	ConsoleWrite($szDatum & @LF)
	ConsoleWrite("--------------------------------------------------------------------------------" & @LF)
EndFunc

; This function is used to read new datagrams
; from the specified channel residing in the
; specified path using the specified function.
;
; Parameters:
;    $szChannelName: The channel name
;    $szChannelPath; The path the channel resides in
;    $szFuncReader: A string containing the name of
;                   a function that takes a filehandle
;                   as a parameter and is used to parse
;                   information recieved from new data
;                   -grams.
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;    True: If successful
;    False: If not successful, and sets @error
; @error:
;    -1: Error opening up tmp datagram file for
;        writing.
;    -2: Error writing datagram information to
;        the file
;    -3: Error moving (renaming) file to .dg
;        extension. (See remarks)
;
; Remarks:
;   The way this function works is a bit quirky,
;   and the best way to do it is to use the
;   __SUBSCRIBE() function, which calls this and
;  will automatically notify your calling program of
;  any new datagrams recieved on this end.
;
;  If you're calling this directly, the function
;  you supply in $szFuncReader will be called for
;  each new file found in $szChannelName.
;
;  It automatically writes (and reads) to an Ini
;  file to determine if you've read information from
;  this channel before, and will automatically update
;  it right before this function returns.
;
;  So, what this means is that when you call this for
;  the first time. If you're in a channel containing a
;  lot of files you have not read... it may not be nice
;  to you.
Func __DROPBOX__COMM__READ($szChannelName, $szChannelPath, $szFuncReader, $szLogFuncHandler = "__DROPBOX__CERR")
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	Local $iDateTimeFilter = IniRead($szChannelComb & "\" & @ComputerName & ".ini", _
							$szChannelName & "-LastRx", $szFuncReader, -1)
	Local $aszListing = _FileListToArray($szChannelComb, "*.dg", 1)
	;_ArrayDisplay($aszListing)
	Local $i = 0
	Local $hFileToRead
	Local $iMostRecentDateTime = 0
	For $i = 1 To UBound($aszListing)-1 Step 1
		If( StringLeft($aszListing[$i], 10) > $iMostRecentDateTime ) Then
					$iMostRecentDateTime = StringLeft($aszListing[$i], 10)
				If(StringLeft($aszListing[$i], 10) > $iDateTimeFilter) Then
					$hFileToRead = FileOpen($szChannelComb & "\" & $aszListing[$i]) ; Read only
					Call($szFuncReader, $hFileToRead)
					FileClose($hFileToRead)
				EndIf
		Else
			; Do nothing.
		EndIf
	Next

	; To prevent too much traffic on the dropbox.
	If( $iMostRecentDateTime > $iDateTimeFilter ) Then
		IniWrite($szChannelComb & "\" & @ComputerName & ".ini", _
			$szChannelName & "-LastRx", $szFuncReader, $iMostRecentDateTime)
	EndIf
EndFunc

; This function returns the current
; epoch time.
Func __DROPBOX__COMM__EPOCH()
	Return _DateDiff('s', "1970/01/01 00:00:00", _NowCalc())
EndFunc

; This function is used to purge old datagrams
; from the specified channel residing in the
; specified path.
;
; Parameters:
;    $szChannelName: The channel name (no trailing \)
;    $szChannelPath: The path the channel resides in (no trailing \)
;    [$iMaxFileAge = 0]:   If the age of the file is greater than the value
;                    specified in this parameter, then the file will
;                    be deleted. If 0, then all files will be purged.
;                    (See remarks)
;
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;    True:  If successful
;    False: If not successful, and sets @error
; @error:
;    -1: Error opening up datagram file for
;        deletion
;    -2: Error writing information to
;        the channel ini file.
;    -3: Error removing datagram file.
;
; Remarks:
;   Age is calculated as the difference now and the file name:
;     $iDifference =  (__DROPBOX__COMM__EPOCH() - $szCurrFile)
;   So, when you specify $iMaxFileAge, you're specifying the
;   maximum difference between the current time and the file
;   time.
;
;
Func __DROPBOX__COMM__PURGE($szChannelName, $szChannelPath, $iMaxFileAge = 0, $szLogFuncHandler = "__DROPBOX__CERR")
	Call($szLogFuncHandler, "In __DROPBOX__COMM__PURGE(), purging datagrams from channel")
	Local $szChannelComb = $szChannelPath & "\" & $szChannelName
	Local $iCurrentEpoch = __DROPBOX__COMM__EPOCH()
	Local $aszFileListing = _FileListToArray($szChannelComb, "*.dg")
	Local $i = 0
	For $i = 1 To UBound($aszFileListing)-1 Step 1
		Local $iLoopFileName = StringTrimLeft($aszFileListing[$i], 10)
		Local $iDifference   = $iCurrentEpoch - $iLoopFileName
		If( $iDifference >= $iMaxFileAge ) Then
			Local $iDelResult = FileDelete( $szChannelComb & "\" & $aszFileListing[$i] )
			If( $iDelResult <> 1 ) Then ; There was an error
				Call($szLogFuncHandler, "In __DROPBOX__COMM__PURGE(), error deleting file " & $aszFileListing[$i])
				Return False
			EndIf
		EndIf
	Next
	Return True
EndFunc

; This function is used to retrieve the list of functions
; using this library to subscribe to a channel.
;
; Parameters:
;   [$szLogFuncHandler]: A function to handle log
;                        information.
; Returns:
;   If successful:
;    An array of strings containing function names.
;   If unsuccessful:
;    An array of three "-1"'s and sets @error
; @error:
;	-1: No subscribed functions
;
; Remarks:
;
;
Func __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST($szLogFuncHandler = "__DROPBOX__CERR")
	Local $aszSubscribedFunctionList = $__DROPBOX__szREGISTERED_FUNCTIONS
	Local $aszRetVal = StringSplit("-1|-1|-1", "|")
	If( $__DROPBOX__REGISTERED_SUBSCRIBERS = 0 ) Then
		; There are no functions subscribed.
		Call($szLogFuncHandler, "In __DROPBOX__COMM__GET_SUBSCRIBED_FUNCTION_LIST(), was " & _
			 "called when there are no registered subscribers.")
		SetError(-1)
	Else
		; One thing to note: potential bug here. If the list of registered
		; functions has not been truncated properly, and has a pipe charact
		; -er on the end, for example:
		;   Bad:
		;     _functions = "func1|func2|func3|"
		; ... Then a condition may occur where the last element in the array
		; $aszRetVal is blank.
		;
		; So, as a simple fix, we have an if clause to check for it.
		; Will this blow up? Probably.
		; TODO: LEFT OFF HERE 072212
		If( StringRight($__DROPBOX__szREGISTERED_FUNCTIONS, 1) <> "|" ) Then
			$aszRetVal = StringSplit($__DROPBOX__szREGISTERED_FUNCTIONS, "|")
		Else
			$aszRetVal = StringSplit _
						 ( _
							StringTrimRight _
							( _
							  $__DROPBOX__szREGISTERED_FUNCTIONS, 1 _
							) _
						  , "|" _
						  )
		EndIf
	EndIf
	Return $aszRetVal
EndFunc

; This function places a lock for the pipe (for use as a semaphore)
; given a particular file. I don't know if I'm going to use this or not.
Func __DROPBOX__COMM__LOCK($szFileFullPath, $szLogFuncHandler = "__DROPBOX__CERR")
EndFunc

; I don't know if I'm going to use this or not.
Func __DROPBOX__COMM__RELEASE($szFileFullPath, $szLogFuncHandler = "__DROPBOX__CERR")
EndFunc


;;; END Communications through dropbox section.

Func __DROPBOX__CERR($szMsg)
	ConsoleWrite($szMsg & @LF)
EndFunc
