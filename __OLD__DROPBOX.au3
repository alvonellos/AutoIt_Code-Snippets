#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:


#ce ----------------------------------------------------------------------------
;; Configuration Options
Global $__DROPBOX__iPROCESSWAIT_INTERVAL = 1
Global $__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD = 2000
Global $__DROPBOX__iDEFAULT_MAX_REGISTERED_SUBSCRIBERS = 1
;; End configutation options.

;; Globals
Global $__DROPBOX__REGISTERED_SUBSCRIBERS = 0
;; End globals
#include-once
#include <Process.au3>
#include <Misc.au3>
#include <Date.au3>
#include <Array.au3>
#include <File.au3>

 __DROPBOX__TEST()

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
	__DROPBOX__COMM__READ("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	Sleep(10000)
	;; __DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	__DROPBOX__COMM__SUBSCRIBE("comm", @ScriptDir, "__DROPBOX__COMM__READ__DEMO_READER")
	__DROPBOX__COMM__REMOVE_CHANNEL("comm", @ScriptDir, "__DROPBOX__CERR")
	ConsoleWrite("Hit bottom" & @LF)
	While True
		Sleep(10)
	WEnd
	Return
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
				Call($szLogFuncHandler, "In __DROPBOX__COMM__CREATE_CHANNEL(), channel " & $szChannelName & "created successfully.")
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
;   TODO.
Func __DROPBOX__COMM__REMOVE_CHANNEL($szChannelName, $szChannelPath, $szLogFuncHandler = "__DROPBOX__CERR")
	If( FileExists($szChannelPath & "\" & $szChannelName) = 1 ) Then ; Channel exists
		Call($szLogFuncHandler, "In __DROPBOX__COMM__REMOVE_CHANNEL(), file exists")
		; Remove all the datagrams & channel directory.
		$bReturnValue = __DROPBOX__COMM__UNSUBSCRIBE($szChannelName, $szChannelPath)
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
	 ConsoleWrite("DEBUG: " & "Called" & @LF)
	For $i = 0 To $__DROPBOX__REGISTERED_SUBSCRIBERS Step 1
		Local $chan = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szChannelName_" & _
								$__DROPBOX__REGISTERED_SUBSCRIBERS)
		ConsoleWrite("DEBUG: " & $chan & @LF)
		Local $path = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szChannelPath_" & _
								$__DROPBOX__REGISTERED_SUBSCRIBERS)
		ConsoleWrite("DEBUG: " & $path & @LF)
		Local $hand = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szFuncDataHandler_" & _
								$__DROPBOX__REGISTERED_SUBSCRIBERS)
		ConsoleWrite("DEBUG: " & $hand & @LF)
		Local $logf = Eval("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szLogFuncHandler_" & _
								$__DROPBOX__REGISTERED_SUBSCRIBERS)
		ConsoleWrite("DEBUG: " & $logf & @LF)
		__DROPBOX__COMM__READ($chan, $path, $hand, $logf)
	Next
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
				$szChannelName & ".ini" , $szChannelName & "-Listening", @ComputerName, _
				__DROPBOX__COMM__EPOCH())

		$__DROPBOX__REGISTERED_SUBSCRIBERS = $__DROPBOX__REGISTERED_SUBSCRIBERS + 1
		Call($szLogFuncHandler, "In __DROPBOX__COMM__SUBSCRIBE(), adding subscriber " & "#" & _
		     $__DROPBOX__REGISTERED_SUBSCRIBERS &" : " & $szFuncDataHandler & "().")
		Local $j1 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szChannelName_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, $szChannelName, 2)
		Local $j2 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szChannelPath_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, $szChannelPath, 2)
		Local $j3 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szFuncDataHandler_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, $szFuncDataHandler, 2)
		Local $j4 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szLogFuncHandler_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, $szLogFuncHandler, 2)
		;ConsoleWrite($j1 & " :: " & $j2 & " :: " & $j3 & " :: " & $j4 & @LF)

		If( ($j1 + $j2 + $j3 + $j4) = 4) Then
			AdlibRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS", _
						  $__DROPBOX__iDEFAULT_CHANNEL_POLLING_PERIOD)
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



; This function unsubscribes a previously assigned
; function from the specified channel residing in
; the specified path. The function specified is
; removed from being called using AdLibUnRegister.
;
; Parameters:
;    $szChannelName: The channel name to use
;    $szChannelPath: The path the channel resides in
;   [$szLogFuncHandler]: A function to handle log information
;                        supplied by the parameter.
; Returns:
;   True: If successful, @error is possibly set.
;   False: If not successful, and sets @error
; @error:
;    0: No problems.
;   -1: No subscribers are registered.
;   -2: Problem assigning data to vars.
;
; Remarks:
;   At this point, I've only coded this library to handle
;   only one subscriber at a time. It wouldn't be too hard
;   to add it, but I'm working on it...
Func __DROPBOX__COMM__UNSUBSCRIBE($szChannelName, $szChannelPath, $szLogFuncHandler = "__DROPBOX__CERR")
	If( $__DROPBOX__REGISTERED_SUBSCRIBERS = 1 ) Then
		Local $oChannelIniListDResult = IniWrite($szChannelPath & "\" & $szChannelName & "\" & _
						$szChannelName & ".ini" , $szChannelName & "-Listening", @ComputerName, -1)
		Local $j1 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szChannelName_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, "", 2)
		Local $j2 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szChannelPath_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, "", 2)
		Local $j3 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szFuncDataHandler_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, "", 2)
		Local $j4 = Assign("__PRIVATE__DROPBOX__COMM__SUBSCRIBE_szLogFuncHandler_" & _
					$__DROPBOX__REGISTERED_SUBSCRIBERS, "", 2)

		If( ($j1 + $j2 + $j3 + $j4) = 4) Then
			; AdlibUnRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS")
			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE(), successfully removed subscriber info.")
			SetError(0)
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

			Call($szLogFuncHandler, "In __DROPBOX__COMM__UNSUBSCRIBE(), there was a problem calling Assign()." & _
									$szLogErrMessageForAssign)
			SetError(-2)
		EndIf

		; This is the major difference between the behavior of __SUBSCRIBE and
		; __UNSUBSCRIBE. No matter what happens, __UNSUBSCRIBE makes a best-effort
		; attempt to unregister the callback function from being called.
		; AdlibUnRegister("PRIVATE__DROPBOX__COMM__PARSE_SUBSCRIBERS")
		; Now, the really smart thing to do would be to do this:
		AdLibUnRegister()
		; Because, this way, it unregisters the last registered AdLib function

		$__DROPBOX__REGISTERED_SUBSCRIBERS = $__DROPBOX__REGISTERED_SUBSCRIBERS - 1
		Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), removed callback function.")
		Return True
	Else
		Call($szLogFuncHandler, "In __DROPBOX__COMM_UNSUBSCRIBE(), attempted to unsubscribe when there are no subscribers.")
		SetError(-1)
		Return False
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
				IniWrite($szChannelComb & "\" & $szChannelName & ".ini", _
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
	Local $iDateTimeFilter = IniRead($szChannelComb & "\" & $szChannelName & ".ini", _
							$szChannelName & "-LastRx", @ComputerName, -1)
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
		IniWrite($szChannelComb & "\" & $szChannelName & ".ini", _
			$szChannelName & "-LastRx", @ComputerName, $iMostRecentDateTime)
	EndIf
EndFunc

Func __DROPBOX__COMM__EPOCH()
	Return _DateDiff('s', "1970/01/01 00:00:00", _NowCalc())
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
