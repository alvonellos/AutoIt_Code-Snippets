#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	File function header to do stuff.

 Changelog:
	Created on 06/25/2012
#ce ----------------------------------------------------------------------------

#include-once
#include <Misc.au3>
#include <File.au3>
#include <Crypt.au3>
#include <Array.au3>
#include "..\Include\__STACK.au3"
AutoItSetOption("MustDeclareVars", 1)

; Defines the default logging function to be used for
; logging purposes. This function must have one and
; only one parameter that takes a string and returns
; nothing.
Global $__FILE__DEFAULT_LOGGING_FUNCTION = "__FILE__CERR"

__FILE__MAIN()
Func __FILE__MAIN()
	Local $bFileInitReturnVal = __FILE__INITIALIZE()
EndFunc

; Just a wrapper for _Crypt_Startup() for now
; Returns true if successful and false, if not.
Func __FILE__INITIALIZE()
	Local $bCryptStartupReturnVal = _Crypt_Startup()
	If( $bCryptStartupReturnVal = True ) Then ; There wasn't an error
		Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__INITIALIZE, _Crypt_Startup() initialization successful")
	Else ; There was an error and $cryptStartupReturnVal will be false
		Select
			case @error = 1
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__INITIALIZE, failed to open Advapi32.dll. @error = " & @error)
			case @error = 2
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__INITIALIZE, failed to acquire crypt context. @error = " & @error)
			case Else
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__INITIALIZE, bad magic. @error = " & @error)
		EndSelect
	EndIf
	Return $bCryptStartupReturnVal
EndFunc

; If successful, returns a hash of the given file
; Otherwise, it returns -1.
Func __FILE__HASH($szFileName)
	Local $szFileHashData = _Crypt_HashFile($szFileName, $CALG_MD5)
	If( @error = 0 ) Then ; There wasn't a problem
		Return $szFileHashData
	Else
		Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "Error for file: " & $szFileName)
		Select
			case @error = 1
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__HASH, failed to open file. @error = " & @error)
			case @error = 2
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__HASH, failed to hash final piece. @error = " & @error)
			case @error = 3
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__HASH, failed to hash piece. @error = " & @error)
			case Else
				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__HASH, bad magic. @error = " & @error)
		EndSelect
		Return -1
	EndIf
EndFunc

; This function returns the last modified time of the
; given file path.
; On error:
;	Returns 01/01/70@00:00
;   Sets @error to 1
; No error:
;   Returns the last modified time of the given file
;   in the form specified:
;   If $bCentury is True:
;     returns four digit year
;   Else:
;     returns two digit year
;
; Ex. mm/dd/[yy]yy@hh:mm
Func __FILE__LASTMODIFIED($szFilePath, $bCentury = True)
	Local $aszSourceFileTime = FileGetTime($szFilePath)
	Local $szSourceFileTime  = ""
	If( @error = 1) Then ; There was a problem
		$szSourceFileTime = "01/01/" & _
			_Iif($bCentury = True, "19", "") & _
			"70@00:00"
		SetError(1)
	Else
		$szSourceFileTime = $aszSourceFileTime[1] & "/" & _ ; month
						    $aszSourceFileTime[2] & "/"  ; day
							If($bCentury = True) Then
								$szSourceFileTime &= $aszSourceFileTime[0] & "@" ; year yyyy
							Else
								$szSourceFileTime &= StringTrimLeft($aszSourceFileTime[0], 2) & "@" ; year yy
							EndIf
							$szSourceFileTime &= $aszSourceFileTime[3] & ":" & _ ; hh 00-24
							$aszSourceFileTime[4] ; mm 00-59
	EndIf
	Return $szSourceFileTime
EndFunc

; This one is a bit of a biggie. I know a reader other
; than me would tell me that this is COMPLETELY reinventing
; the wheel and is more than necessary... it is, BUT it's
; completely necessary. Work for <deleted> a little longer
; and see how crap randomly blindsides you.
;
; I plan on replacing this in the future. But, just in case,
; here is how it works...
;
; This script performs a DFS (Depth First Traversal) iteratively
; on a directory tree given the full path of the root directory to
; start with. So, when you pass the directory to the function, make
; sure that it gets the full path or else everything is going to
; be really funky.
;
; If it's successful, it'll return an array (That's not 0 indexed) so
; the count of the function will be stored in $aArray[0]. Iterate from
; 1 to that and you'll get everything you need out of it.
;
; If it's not successful, the only unsuccessful event that I've taken
; account for is the possibility that the directory you passed it doesn't
; exist.
;
; Returns:
; -1 :: Failure
; Success :: String array with stuff in it.
;
; @error:
; -1 :: Base Path doesn't exist.
; -2 :: Only one file in base path
; -3 :: No files in base path
; -4 :: Problem listing dirs in root dir
; TODO: Cleanup this code. Holy <expletive>.
; Fix a bug where the program doesn't handle only having one file in dir
; ^I think I fixed that already, but it's 6 am and I'm not sure.
Func __FILE__LIST($szListDirectoryBasePath)
	__STACK__DEALLOC() ; Delete w/e is in the stack
	Local $szDirRoot = $szListDirectoryBasePath
	If( FileExists($szListDirectoryBasePath) = 0 ) Then ; Directory doesn't exist
		; Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__LIST(), base path """ & $szListDirectoryBasePath & """ doesn't exist")
		SetError(-1)
		Return -1
	Else
		Local $aszVisitedDirs = $szListDirectoryBasePath & ","
		Local $aszDirList = _FileListToArray($szListDirectoryBasePath, "*", 2)
		Local $aszFileList = _FileListToArray($szListDirectoryBasePath, "*", 1)
		If( $aszDirList = 0 And $aszFileList = 0 ) Then ; No dirs or files in dir
			Return -1
		Else
			If ( $aszFileList[0] = 1 ) Then
				; Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__LIST(), there's only one file in " & $szListDirectoryBasePath)
				SetError(-2)
				Dim $errRetVal[1]
				$errRetVal[0] = $aszFileList[1]
				Return $errRetVal
				; ConsoleWrite("Is array: " & IsArray($errRetVal) & @LF)
			EndIf
		EndIf

		Local $szFileList = ""
		If( $aszFileList = 0 ) Then ; There was a problem, no files.
			; Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE_LIST(), there was a problem listing files in root dir. @error = " & @error)
			SetError(-3)
			StringTrimRight($aszFileList, 1) ; Remove the 0
		Else ; Good to go.
			; This is the file listing part.
			If( $aszDirList = 0 ) Then ; There was a problem
				; Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__LIST(), there was a problem listing dirs in root dir. @error = " & @error)
				SetError(-4)
				StringTrimRight($aszDirList, 1) ; Remove the 0
			Else
				; Grab the files in that directory and concatenate them to a
				; listiing
				$aszFileList = _FileListToArray($szListDirectoryBasePath, "*", 1)
				Local $i = 0
				For $i = 1 To $aszFileList[0] Step 1
					$szFileList &= $szDirRoot & "\" & $aszFileList[$i] & ","
				Next
			EndIf
			If( $aszDirList <> 0 ) Then ; There are dirs in the dir.
				Local $i = 0
				; Push all vertices adjacent to v onto S
				For $i = 1 To $aszDirList[0]
					__STACK__PUSH($szDirRoot & "\" & $aszDirList[$i])
				Next
			EndIf

		EndIf
		; Iterate through the rest of the directories
		; ConsoleWrite(" STACK : " & __STACK__SIZE() & @LF)
		While( True )
			Local $szCurrDir = __STACK__POP()
			If( $szCurrDir = -1 ) Then ; Break
				ExitLoop
			EndIf
			Local $aszSubDirs = _FileListToArray($szCurrDir, "*", 2)
			Local $aszSubFiles = _FileListToArray($szCurrDir, "*", 1)
			; _ArrayDisplay($aszSubDirs, "Subdirs in while loop")
			; _ArrayDisplay($aszSubFiles, "Subfiles in while loop")
			$aszVisitedDirs &= $szCurrDir & ","
			If( $aszSubFiles <> 0 ) Then
				Local $i = 0
				For $i = 1 To $aszSubFiles[0] Step 1
					$szFileList &= $szCurrDir & "\" & $aszSubFiles[$i] & ","
				Next
			EndIf
			If( $aszSubDirs <> 0 ) Then
				Local $i = 0
				For $i = 1 To $aszSubDirs[0] Step 1
					; ConsoleWrite($aszSubDirs[$i] & @LF)
					__STACK__PUSH($szCurrDir & "\" & $aszSubDirs[$i])
					If( StringInStr($aszVisitedDirs, $szCurrDir & "\" & $aszSubDirs[$i]) <> 0 ) Then ; Not found
						 $aszVisitedDirs &= $szCurrDir & "\" & $aszSubDirs[$i] & ","
						$aszSubFiles = _FileListToArray($szCurrDir & "\" & $aszSubDirs[$i], "*", 2)
						If( $aszSubFiles <> 0 ) Then
							Local $j = 0
							For $j = 1 To $aszSubFiles[0] Step 1
								$szFileList &= $szCurrDir & "\" & $aszSubFiles[$j] & ","
							Next
						Else
							; ConsoleWrite("Alternate clause error: " & $aszSubFiles & " :: " & @error & @LF)
							ExitLoop
						EndIf
					EndIf
				Next
			Else
				If( StringInStr($aszVisitedDirs, $szCurrDir & "\" & $szCurrDir <> 0 )) Then ; Not found
					$aszVisitedDirs &= $szCurrDir & ","
					; ConsoleWrite("Left off here --> alternate clause" & " " & $szCurrDir)
					$aszSubFiles = _FileListToArray($szCurrDir, "*", 2)
					If( $aszSubFiles <> 0 ) Then
						Local $j = 0
						For $j = 1 To $aszSubFiles[0] Step 1
							$szFileList &= $szCurrDir & "\" & $aszSubFiles[$j] & ","
						Next
					Else
						; ConsoleWrite("Alternate clause error: " & $aszSubFiles & " :: " & @error & @LF)
					EndIf
				EndIf

			EndIf
		WEnd
		Local $aszRetval = StringSplit($szFileList, ",")
		_ArrayDelete($aszRetval, $aszRetval[0])
		; _ArrayDisplay($aszRetval, "Return from func")
		__STACK__DEALLOC()
		Return $aszRetval
	EndIf
EndFunc

; This function performed a verified copy given a
; source and destination file. Here are a couple of
; things that make it better than FileCopy()
; 1. This function performs verification on the
;    source and destination files, before and
;    after copying; therefore, when the function
;    goes to copy a file, it makes sure that the
;    file that is copied is the one that's ACTUALLY
;    there.
; 2. It's efficient. It copies files that have met
;    the following conditions
;    1) The file must not exist in the destination
;       directory. If the file exists, then it
;       performs a checksum on the destination file
;       to make sure that what it has as the source
;       is the same as what's in the dest. If the
;       source matches the destination, then it
;       will not copy the file.
;    2) It will create the destination path, if that
;       is necessary
;    3) It will not copy if the source file doesn't
;       exist.
; 3. It's better because I wrote it.
; Here are the return values
; -1 : There was an error
; 0  : File copied successfully
; 1  : File copied successfully, but it didn't need to
;      copy the file.
; Codes in @error
; @error = -1 :: Problem generating source hash
; @error = -2 :: Problem generating destination hash
; @error = -3 :: Problem copying file
; @error = -4 :: Checksums don't match after copying
;
;  ----> PLEASE NOTE THE FOLLOWING <-------
;   If you're going to parse the output of
;   __FILE__COPY and have verbose set to
;  true, then make sure you're comparing
;  strings when you parse the output,
;  not <insert type here>. I'm putting this
;  here because I have made this mistake
;  myself.
;
; If $bVerbose is true, then when the function returns (successfully) then the
; program will store verbose results in the ByRef parameter you supplied in a
; string delimited by the pipe character in the following format.
; Source Full Path | Source Checksum | Source Modification time | Source Size (B)_
; Destination Full Path | Destination Checksum | Destination Modification Time | Dest Size (B)
; True or false depending on whether or not the file matches.
;
; I don't really want to return an array. I may change my mind later.
; know how to do optional ByRef parameters in AutoIt, so for now it's not optional.

FUNC __FILE__COPY($szSourcePath, $szDestinationPath, $bVerbose, ByRef $szFileData )
	Local $szSourceChecksum       = __FILE__HASH($szSourcePath)
	Local $szDestinationChecksum  = "" ; Don't hash it yet.
	If( $szSourceChecksum = -1 ) Then ; There was a problem
	;	Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__COPY, there was a problem generating the hash for " & $szSourcePath)
		SetError(-1)
		Return -1
	Else ; We got the hash, lets see if dest has same checksum
		Local $bShouldICopyTheFile = False
		If( FileExists($szDestinationPath) = 1 ) Then ; File exists
			$szDestinationChecksum = __FILE__HASH($szDestinationPath)
			; Handle condition if the destination file exists
			If( $szDestinationChecksum = -1 ) Then ; There was a problem
	;			Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE__COPY, there was a problem generating destination hash. @error = " & @error)
				SetError(-2)
				Return -1
			Else
				; There's not a problem
				; Check to see if we should copy the file
				; by comparing the source checksum and the
				; destination checksum, using mode two,
				; which means to compare without case
				; sensitivity. (Faster)
				Local $iCompareResult = StringCompare($szSourceChecksum, $szDestinationChecksum, 2)
				; ConsoleWrite("DEBUG:: "  & $iCompareResult & " : " & $szSourceChecksum & " : " & $szDestinationChecksum & @LF)
				If( $iCompareResult <> 0 ) Then ; The checksums are't equal
					; We should copy the file
					$bShouldICopyTheFile = True
				Else ; Checksums are equal
					; ConsoleWrite("DEBUG:: " & @LF)
					; This means that the checksums are equal and there is no need to
					; copy the file over
					; Return 1
					; Don't do anything. Or uncomment that return statement. Confusing
					; control flow.
				EndIf
			EndIf
		Else ; If the destination file doesn't exist
			; ConsoleWrite("Dest doesn't exist: " & $szSourcePath & " : " & $szDestinationPath & @LF)
			$bShouldICopyTheFile = True
		EndIf

		; Now for the business end.
		; We'll return -1 if there was a problem,
		; 0 if there wasn't a problem and we did
		; copy the file, and 1 if we didn't need
		; to copy the file
		If( $bShouldICopyTheFile = True ) Then
			; I want to copy the file and overwrite it, create the directory
			; structure if it exists.
			Local $iCopyResult = FileCopy($szSourcePath, $szDestinationPath, 9)
			If( $iCopyResult = 0 ) Then ; There was a problem.
	;			Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE_COPY(), there was a problem copying the file " & $szSourcePath  & " to " & $szDestinationPath)
				SetError(-3)
				Return -1
			Else
				$szDestinationChecksum = __FILE__HASH($szDestinationPath)
				; Compare the two checksums (case insensitive for speed)
				If( StringCompare($szSourceChecksum, $szDestinationChecksum, 2) <> 0 ) Then
	;				Call($__FILE__DEFAULT_LOGGING_FUNCTION,  "In __FILE_COPY(), checksums don't match after copying the file " & _
	;					  $szSourcePath  & " to " & $szDestinationPath)
					; If the checksums aren't equal, return -1
					SetError(-4)
					Return -1
				Else
					; Good to go
					; IF YOU CHANGE <expletive> HERE, change it down on the other end of the clause as well.
					If( $bVerbose = True ) Then
						Local $szSourceFileTime      = __FILE__LASTMODIFIED($szSourcePath)
						Local $szDestinationFileTime = __FILE__LASTMODIFIED($szDestinationPath)
						Local $szSourceFileSize      = FileGetSize($szSourcePath)
						Local $szDestinationFileSize = FileGetSize($szDestinationPath)
						; If there's an error, I don't really give a <expletive>. It doesn't matter.
						Local $szFileDataPrep = $szSourcePath      & "|" & _
												$szSourceChecksum      & "|" & _
												$szSourceFileTime      & "|" & _
												$szSourceFileSize      & "|" & _
												$szDestinationPath     & "|" & _
												$szDestinationChecksum & "|" & _
												$szDestinationFileTime & "|" & _
												$szDestinationFileSize & "|" & _
												_IIf(StringCompare($szSourceChecksum, _
												$szDestinationChecksum, 2) = 0, True, False)
												; If the checksums don't match, then I
												; want to put a true or false value in
												; the returned array. True for okay,
												; and false for not okay.
						; Split the string and store it in the ByRef var.
						; $aszFileData = StringSplit($szFileData, "|")
						; Nevermind, <expletive> that.
						$szFileData = $szFileDataPrep
					EndIf
					Return 0
				EndIf
			EndIf
		Else
			; This clause gets called if the file in the source
			; directory and in the destination directory are the
			; same file -- we don't need to copy them.
			;
			; If you change <expletive> here, change it up there ^ too. This whole
			; if clause needs to be EXACTLY the same for both cases.
			;
			; I hate to grossly duplicate code like this, but here's the
			; bottom line, you have to do the same thing twice and it
			; doesn't merit making another function for it, and because
			; autoit doesn't allow procedures in procedures, we can't do
			; stuff that way... meh.
			If( $bVerbose = True ) Then
				Local $szSourceFileTime      = __FILE__LASTMODIFIED($szSourcePath)
				Local $szDestinationFileTime = __FILE__LASTMODIFIED($szDestinationPath)
				Local $szSourceFileSize      = FileGetSize($szSourcePath)
				Local $szDestinationFileSize = FileGetSize($szDestinationPath)
				; If there's an error, I don't really give a <expletive>. It doesn't matter.
				Local $szFileDataPrep = $szSourcePath      & "|" & _
										$szSourceChecksum      & "|" & _
										$szSourceFileTime      & "|" & _
										$szSourceFileSize      & "|" & _
										$szDestinationPath     & "|" & _
										$szDestinationChecksum & "|" & _
										$szDestinationFileTime & "|" & _
										$szDestinationFileSize & "|" & _
										_IIf(StringCompare($szSourceChecksum, _
										$szDestinationChecksum, 2) = 0, True, False)
										; If the checksums don't match, then I
										; want to put a true or false value in
										; the returned array. True for okay,
										; and false for not okay.
					; Split the string and store it in the ByRef var.
					; $aszFileData = StringSplit($szFileData, "|")
					; Nevermind, <expletive> that.
				$szFileData = $szFileDataPrep
			EndIf
			Return 1
		EndIf
	EndIf ; End if there wasn't a problem
EndFunc

; Returns:
; -1 :: Failure
;
; @error:
; -1 :: Source doesn't exist.
; -2 :: Problem with __FILE__LIST() See logs.
; -3 :: Problem with __FILE__COPY() See logs.
Func dumb($sz, $sz2 = "")
	Return $sz
EndFunc

; This function returns the floating point value of part/whole
; and looks for round-off errors (so you can use it in a GUI
; control like a progress bar . . . or something like that).
; Input:
; 		$iPartNumber: (part value): A whole number >= 0
; 		$iWholeNumber: (total value): A wholeNumber > 0
; Output:
;       Returns part/whole where part != whole, if part = whole,
;       then it returns 1.
Func __FILE__PERCENTAGE_VALUE($iPartNumber, $iWholeNumber)
	; Since AutoIt treats datatypes the way that it does,
	; we don't have to worry too much about what type the
	; underlying value in $iPartNumber and $iWholeNumber is
	; ... as far as I know anyway. At time of this writing,
	; I tested it with strings, integers, and floating point
	; numbers.
	Local $fReturnValue = $iPartNumber / $iWholeNumber
	; Round off error that occurs with say,  2999 out of 2999
	; that's going to give you a nasty number you don't want.
	If( $iPartNumber = $iWholeNumber ) Then
		Return 1
	Else
		Return $fReturnValue
	EndIf
EndFunc


; This function performs a recursive copy given the following parameters
; $szSourceDirectoryRootPath: The full path to copy from
; $szDestinationDirectoryRootPath: The destination directory root path
; And, optionally, using the following parameters:
; $szFuncLogfCallBack:  A user provided function taking one string paramter to capture log information
;
; $szFuncItemFormatter: A user provided function taking one string parameter that handles item information
; 						The information will be provided in the following format:
;						Item # | Source Full Path | Source Checksum | Source Modification time | Source Size (B)_
;						Destination Full Path | Destination Checksum | Destination Modification Time | Dest Size (B)
;						True or false depending on whether or not the file matches |
;						True or false depending on whether or not the file was skipped (True if skipped, false otherwise) |
;						Total #
;			Note:
;				The data supplied to $szFuncItemFormatter will all be in a string. If you're dealing with the output
;				of this function, make sure you're comparing strings, and not comparing raw boolean datatypes. The
;				reason that I'm writing this is because I made that mistake myself. I figured it'd be a good idea to
;				just write that down here.
; $szFuncStatusCallBack: A user provided function taking one string parameter to handle status updates
; $szFuncItemCallBack:   A user provided function that handles the output of $szFuncItemFormatter and is used to update
;						 the GUI this is associated with (if any)
; $szFuncProgressBarCallBack: A user provided function that takes one floating point parameter and does something with it.
;							  This function will give percentage values as to the number of files copied over the number of
; 							  files not copied.
; Returns:
;	On failure:
; 		-1 :: Failure
;		Sets @error to one of the following values:
;			-1 :: Source Directory doesn't exist
;			-2 :: Error calling __FILE__LISTING(). (See log output for more details)
;			-3 :: Error calling __FILE__COPY(). (See log output for more details)
;	On success:
;		Returns an array containing the following information:
;		$aArray[0] = number of elements
;		$aArray[1] = Copied files
;		$aArray[2] = Skipped files
;
; TODO:
;	1) Implement counting number of bytes (or kilobytes) copied
; 	2) Time elapsed
; 	3) Checking of functions in parameters (make sure they exist)
;	4) Option to continue copying on error
;	5) Option to retry file copy on error
Func __FILE__RECURSIVE_COPY($szSourceDirectoryRootPath, $szDestinationDirectoryRootPath, _
							$szFuncLogfCallBack   = "dumb", $szFuncItemFormatter   = "dumb", _
							$szFuncStatusCallBack = "dumb", $szFuncItemCallBack    = "dumb", _
							$szFuncProgressBarCallBack = "dumb")

		; First, check if the source directory exists
		__STACK__DEALLOC()
		Local $iTotalFiles   = 0
		Local $iCopiedFiles  = 0
		Local $iSkippedFiles = 0
		Local $iFileCopiedKB = 0
		Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() INITIALIZING...")
		If( FileExists($szSourceDirectoryRootPath) = 0 ) Then ; The file doesn't exist
			Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() failed. SourceDir doesn't exist.")
			Call($szFuncStatusCallBack, "Failed.")
			; At this point, I'm not responsible for errors from call. So... If there is an error.
			; Then, SetError to be -1
			SetError(-1)
			Call($szFuncProgressBarCallBack, 0)
			Return -1
		EndIf

		Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() is getting the file listing.")
		Call($szFuncStatusCallBack, "Please wait, retrieving file listing")

		; Get file listing and interpret errors.
		Local $aszFileListing = __FILE__LIST($szSourceDirectoryRootPath)
		If( $aszFileListing = -1 ) Then ; There was a problem.
			; This may not be entirely accurate. $$$$
			Select
				Case @error = -1
					Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() failed. Base path doesn't exist. BAD MAGIC")
					Call($szFuncStatusCallBack, "Failed")
				Case @error = -2
					Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() failed. Only one file in base path. BAD MAGIC")
					Call($szFuncStatusCallBack, "Failed")
				Case @error = -3
					Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() failed. No files in base path.")
					Call($szFuncStatusCallBack, "Failed")
				Case @error = -4
					Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() failed. Problem listing dirs in root dir. BAD MAGIC")
					Call($szFuncStatusCallBack, "Failed")
				Case Else
					Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() failed. BAD MAGIC")
					Call($szFuncStatusCallBack, "Failed (BAD MAGIC)")
			EndSelect
			SetError(-2)
			Call($szFuncProgressBarCallBack, 0)
			Return -1
		Else ; We can progress with copying the file.
			; Dealloc and initialize the stack
			__STACK__DEALLOC()
			$iTotalFiles = $aszFileListing[0] - 1
			Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() source file listing succesful. # files = " & ($iTotalFiles))
			Call($szFuncStatusCallBack, "Found " & ($iTotalFiles) & " in source directory. Please wait...")
			; Make sure the path passed in has trailing backslash when we go to do
			; the string replacements. This just makes the whole algorithm much
			; easier...
			Local $szSourceDirectoryRootPathCopy      = $szSourceDirectoryRootPath
			Local $szDestinationDirectoryRootPathCopy = $szDestinationDirectoryRootPath
			If( StringRight($szSourceDirectoryRootPathCopy, 1)  <> "\" ) Then
				; Append the trailing slash
				$szSourceDirectoryRootPathCopy &= "\"
			EndIf

			If( StringRight($szDestinationDirectoryRootPathCopy, 1) <> "\" ) Then
				; Append the trailing slash
				$szDestinationDirectoryRootPathCopy &= "\"
			EndIf

			; Walk through the array and change all the source root paths
			; to an array of source and destination root paths.
			Local $szPushStrBuf = ""
			Local $szFileListingBuf = ""
			Local $i = 0
			__STACK__DEALLOC()
			For $i = 1 To $aszFileListing[0]-1 Step 1
				$szFileListingBuf = StringReplace($aszFileListing[$i], $szSourceDirectoryRootPathCopy, _
												   $szDestinationDirectoryRootPathCopy)
				; Now that that is done, we can know that whatever is in
				; $aszFileListing[$i] is the file full path as it was from
				; the source. The destination path is in $szFileListingBuf.
				$szPushStrBuf = $aszFileListing[$i] & "," & _
								$szFileListingBuf
				__STACK__PUSH($szPushStrBuf)
			Next
			Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() finished preparing destination list.")
			Call($szFuncStatusCallBack, "Finished destination list. Preparing to copy files...")
			 Local $aszFileListingArray = __STACK__ARRAY(1) ; Remove extra space from the stack.
			; _ArrayDisplay($aszFileListingArray)
			__STACK__DEALLOC() ; Free memory

			Local $aszSourceDestinationFileBuf = ""
			Local $iCopyResult = ""
			Local $szFileCopyDataStoreBuf = ""
			Call($szFuncStatusCallBack, "Copying files please wait...")
			$i = 0
			; MsgBox(0, "", UBound($aszFileListingArray))
			For $i = 0 To UBound($aszFileListingArray)-1 Step 1
				$aszSourceDestinationFileBuf = StringSplit($aszFileListingArray[$i], ",")
				; Here are the return values for __FILE__COPY()
				; -1 : There was an error
				; 0  : File copied successfully
				; 1  : File copied successfully, but it didn't need to
				;      copy the file.
				; Codes in @error
				; @error = -1 :: Problem generating source hash
				; @error = -2 :: Problem generating destination hash
				; @error = -3 :: Problem copying file
				; @error = -4 :: Checksums don't match after copying
				$szFileCopyDataStoreBuf = "" ; Zero it out, just in case
				$iCopyResult = __FILE__COPY($aszSourceDestinationFileBuf[1], $aszSourceDestinationFileBuf[2], _
											True, $szFileCopyDataStoreBuf)
				; Add the file number to the beginning of the string if there wasn't an error
				If( $iCopyResult = -1 ) Then ; There was an error
					Call($szFuncStatusCallBack, "Failed.")
					Select
						Case @error = -1
							Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() Problem generating source hash.")
						Case @error = -2
							Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() Problem generating destination hash.")
						Case @error = -3
							Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() Problem copying file. BAD MAGIC.")
						Case @error = -4
							Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() Checksums don't match")
							; I can actually do something about this. But I'm not going to.
						Case Else
							Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() BAD MAGIC. " & @ScriptLineNumber)
					EndSelect
					SetError(-3)
					Call($szFuncProgressBarCallBack, 0)
					Return -1 ; <--- should I return here or not?
				; Item # | Source Full Path | Source Checksum | Source Modification time | Source Size (B)_
				; Destination Full Path | Destination Checksum | Destination Modification Time | Dest Size (B)
				; True or false depending on whether or not the file matches |
				; True or false depending on whether or not the file was skipped (True if skipped, false otherwise) |
				; Total #
				; This is really unnecessary...
				ElseIf ( $iCopyResult = 0 ) Then ; Actually copied a file
					$iCopiedFiles = $iCopiedFiles + 1
					Local $fPercentDone = __FILE__PERCENTAGE_VALUE($iSkippedFiles + $iCopiedFiles, $iTotalFiles)
					Call($szFuncProgressBarCallBack, ($fPercentDone*100))
					Call($szFuncStatusCallBack, "Copied " & ($iSkippedFiles + $iCopiedFiles) & " of " & $iTotalFiles)

					; Call the user defined function to get the format of the stuff
					Local $oFormat = Call($szFuncItemFormatter, ($i+1) & "|" & $szFileCopyDataStoreBuf & "|" & "False" & "|" & $iTotalFiles)
					Call($szFuncItemCallBack, $oFormat)
				ElseIf ( $iCopyResult = 1 ) Then ; Skipped file
					; We skipped the file
					$iSkippedFiles += 1
					Local $fPercentDone = __FILE__PERCENTAGE_VALUE($iSkippedFiles + $iCopiedFiles, $iTotalFiles)
					Call($szFuncProgressBarCallBack, ($fPercentDone*100))
					Call($szFuncStatusCallBack, "Copied " & ($iSkippedFiles + $iCopiedFiles) & " of " & $iTotalFiles)

					; Call the user defined function to get the format of the stuffs
					Local $oFormat = Call($szFuncItemFormatter, ($i+1) & "|" & $szFileCopyDataStoreBuf & "|" & "True" & "|" & $iTotalFiles)
					Call($szFuncItemCallBack, $oFormat)
				Else

					Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() BAD MAGIC. ")
				EndIf
			Next
			; If we've gotten here, there shouldn't be any problemss
			Call($szFuncLogfCallBack, "__FILE__RECURSIVE_COPY() finished.")
			Call($szFuncStatusCallBack, "Finished copying " & ($iSkippedFiles + $iCopiedFiles) & " of " & $iTotalFiles)
			; No problems, so we'll return an array of values
			; $aiReturnValues[0] = Bounds of the array
			; $aiReturnValues[1] = Copied Files
			; $aiReturnValues[2] = Skipped Files
			Local $aiReturnValues[3]
			$aiReturnValues[0] = UBound($aiReturnValues)
			$aiReturnValues[1] = $iCopiedFiles
			$aiReturnValues[2] = $iSkippedFiles
			__STACK__DEALLOC()
			Return $aiReturnValues
		EndIf
EndFunc
FUNC __FILE__TEST_DUMMYLOGGER($sz)
	ConsoleWrite("__FILE__TEST_DUMMYLOGGER:> " & $sz & @LF)
EndFunc

Func __FILE__TEST_DUMMYFORMATTER($sz)
	;ConsoleWrite("__FILE__TEST_DUMMYFORMATTER:> " & $sz & @LF)
	Return $sz
EndFunc

Func __FILE__TEST_DUMMYSTATUS($sz)
	ConsoleWrite("__FILE__TEST_DUMMYSTATUS():> " & $sz & @LF)
EndFunc

Func __FILE__TEST_DUMMYITEMADDS($sz)
	ConsoleWrite("__FILE__TEST_DUMMYITEMADDS():> " & $sz & @LF)
EndFunc

Func __FILE__TEST_DUMMYPROGRESS($sz)
	ConsoleWrite("__FILE__TEST_DUMMYPROGRESS():> " & $sz & @LF)
EndFunc

; A formatting function that trims a path
; $szFullPath: the full path
; Returns:
;   The short path.
Func __FILE__TRIMPATH($szFullPath, $bShowPathDepth = False)
	Local $iPathLength = StringLen($szFullPath)
	Local $szRetVal = ""

	#cs -- Debugging
	Local $aszSplitTest = StringSplit($szFullPath, "\")
	Local $i = 0
	ConsoleWrite("__FILE__TRIMPATH(): " & @LF & _
				 @TAB & $szFullPath & ":-" & @LF)
	For $i = 0 To $aszSplitTest[0] Step 1
		ConsoleWrite(@TAB & "$aszSplitTest[" & $i & "] = " & $aszSplitTest[$i] & @LF)
	Next
	#ce Debugging

	Local $aszSplitPath = StringSplit($szFullPath, "\")
	If( $aszSplitPath[0] < 2 ) Then
		; Bad magic
		; This isn't supposed to happen
		$szRetVal = "-1"
	Else
		If( $aszSplitPath[0] = 2 ) Then
			; If there are "two" elements
			; in a 1 based array index,
			; then it means that there is
			; only the drive name and the
			; file name. So... just return
			; it after reassembling it.
			$szRetVal = $aszSplitPath[1] & "\" & _
					    $aszSplitPath[2]
		Else
			; If it doesn't fit any of the
			; above cases then we're pretty
			; we pretty much have to just
			; put "..."'s where the subdirs
			; used to be.

		  If( $bShowPathDepth = True ) Then
			$szRetVal = $aszSplitPath[1] & "\"
			; Walk from 2 because we don't want to
			; include the drive letter. We'll just
			; add it before the loop.
			Local $i = 0
			For $i = 2 To $aszSplitPath[0] - 1 Step 1
				$szRetVal &= "...\"
			Next
		  Else
			$szRetVal = $aszSplitPath[1] & "\...\"
		  EndIf
			; Now add the file name
			$szRetVal &= $aszSplitPath[$aszSplitPath[0]]
		EndIf
	EndIf

	Return $szRetVal
EndFunc

FUNC __FILE__TEST()
	__STACK__DEALLOC()
	Local $list = __FILE__LIST(@ScriptDir)
	Local $i = 0
	For $i = 1 To $list[0]-1 Step 1
		ConsoleWrite($i & ". " & $list[$i] & " " &__FILE__HASH($list[$i]) & @LF)
	Next
	;_ArrayDisplay($list)
	Local $result = ""
	ConsoleWrite("File Copy Test: " & __FILE__COPY(@ScriptFullPath, @ScriptFullPath & "2", True, $result ) & " " & $result & @LF)
	ConsoleWrite("File Copy Test2: " & __FILE__COPY(@ScriptFullPath, @ScriptDir & "\t\" & @ScriptName & "2", True, $result) & " " & $result & @LF)
	ConsoleWrite(@LF & @LF& @LF)
	Local $oRecursiveCopyValue =  __FILE__RECURSIVE_COPY(@ScriptDir,  "C:\scriptest\", _
						   "__FILE__TEST_DUMMYLOGGER", "__FILE__TEST_DUMMYFORMATTER", _
						   "__FILE__TEST_DUMMYSTATUS", "__FILE__TEST_DUMMYITEMADDS", _
							"__FILE__TEST_DUMMYPROGRESS")
	ConsoleWrite(@LF& @LF & @LF)

	If($oRecursiveCopyValue = -1) Then
		ConsoleWrite("File Recursive Copy Status: failure" & @LF)
	Else
		ConsoleWrite("File Recursive Copy Status: success" & @LF & _
					 @TAB & "Total files: " & ($oRecursiveCopyValue[1] + $oRecursiveCopyValue[2]) & @LF & _
					@TAB & @TAB & "Copied: " & $oRecursiveCopyValue[1] & @LF & _
					@TAB & @TAB & "Skipped: " & $oRecursiveCopyValue[2] & @LF)
	EndIf

	ConsoleWrite(@LF & @LF)
	ConsoleWrite("Testing __FILE__TRIMPATH(" & @ScriptFullPath & ")" & @LF)
	ConsoleWrite(__FILE__TRIMPATH(@ScriptFullPath) & @LF)
	ConsoleWrite("Testing __FILE__TRIMPATH(" & "C:\asd.txt" & ")" & @LF)
	ConsoleWrite(__FILE__TRIMPATH("C:\asd.txt") & @LF)
	ConsoleWrite("Testing __FILE__TRIMPATH(" & "C:\asd\asd.txt" & ")" & @LF)
	ConsoleWrite(__FILE__TRIMPATH("C:\asd\asd.txt") & @LF)
	;	$szSourceDirectoryRootPath, $szDestinationDirectoryRootPath, _
	;						$szFuncLogfCallBack   = "cerr", $szFuncItemFormatter      = "dumb", _
	;						$szFuncStatusCallBack = "dumb", $szFuncItemCallBack       = "dumb")

	ConsoleWrite(@LF & @LF)
	ConsoleWrite("Testing __FILE__PERCENTAGE_VALUE($i, 1000): (*0<=$i<1000)" & @LF)
	Local $i = 0
	For $i = 0 To 1000 Step 1
		ConsoleWrite(@TAB & @TAB & $i & "::" & __FILE__PERCENTAGE_VALUE(String($i),String(1000)) & @LF)
	Next
EndFunc


; Private logging function.
Func __FILE__CERR($message)
	Local $hFile = FileOpen(@ScriptDir & "\" &  @ComputerName & ".txt", 1) ; Append
	_FileWriteLog($hFile, @ComputerName & " :: " & $message)
	FileFlush($hFile)
	FileClose($hfile)
EndFunc