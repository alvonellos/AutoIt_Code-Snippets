#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	A simple stack data structure for strings


#ce ----------------------------------------------------------------------------

#include <Array.au3>
#include <Misc.au3>
#include <File.au3>
#include-once

AutoItSetOption("MustDeclareVars", 1)
Global $__STACK__szDEALLOC_MAGIC_WORD = "0xDEADBEEF"
Global $__STACK__aszCurrentStackData[2]
Global $__STACK__iCurrentStackDataUsedCount = 0

 ; __STACK__TEST()
 ; __STACK__STRESSTEST()

; This function inserts some data onto the
; stack.
;
; Parameters:
;	$szData: some data to push onto the stack
;
; Returns:
;	If successful:
;		Returns 0
;	Otherwise:
;		Returns -1
;
; @error:
;	Doesn't set @error
; Remarks:
;	See main remarks.
Func __STACK__PUSH($szData)
	; ConsoleWrite("---> PUSHED: " & $szData & @LF)
	Local $iStackSize = (UBound($__STACK__aszCurrentStackData))
	Local $iStackUtilization = $__STACK__iCurrentStackDataUsedCount
	If($iStackUtilization < $iStackSize) Then
		$__STACK__aszCurrentStackData[$__STACK__iCurrentStackDataUsedCount] = $szData
	ElseIf ($iStackSize >= $iStackUtilization) Then
		ReDim $__STACK__aszCurrentStackData[(2*UBound($__STACK__aszCurrentStackData))]
		$__STACK__aszCurrentStackData[$__STACK__iCurrentStackDataUsedCount] = $szData
	Else
		Return -1
	EndIf
	$__STACK__iCurrentStackDataUsedCount = $__STACK__iCurrentStackDataUsedCount + 1
	Return 0
EndFunc

; This function pops some data off of the
; stack.
;
; Parameters:
;	None
;
; Returns:
;	If successful:
;		Returns some data
;	Otherwise:
;		Returns -1
;
; @error:
;	Doesn't set @error
; Remarks:
;	See main remarks.
;
; TODO:
;   Add a failure constant, because -1 could be,
;   conveniently, an acceptable return value to
;   the calling function
Func __STACK__POP()
	Local $szReturnValue = -1
	Local $iStackSize = (UBound($__STACK__aszCurrentStackData) - 1)
	Local $iStackUtilization = $__STACK__iCurrentStackDataUsedCount
	If ($__STACK__iCurrentStackDataUsedCount > 0 ) Then
		Local $szReturnValue = $__STACK__aszCurrentStackData[$__STACK__iCurrentStackDataUsedCount - 1]
		$__STACK__aszCurrentStackData[$__STACK__iCurrentStackDataUsedCount - 1] = _
									 $__STACK__szDEALLOC_MAGIC_WORD
		$__STACK__iCurrentStackDataUsedCount = $__STACK__iCurrentStackDataUsedCount - 1
	Else
		$szReturnValue = -1
	EndIf
	; ConsoleWrite("---> POPPED : " & $szReturnValue & @LF)
	Return $szReturnValue
EndFunc

; Deletes all data from the stack
;
; Parameters:
;	None
;
; Returns:
;	Nothing
;
; @error:
;	Doesn't set @error
; Remarks:
;	See main remarks.
Func __STACK__DEALLOC()
	; If( $__STACK__iCurrentStackDataUsedCount > 0 ) Then
	;	Local $i = $__STACK__iCurrentStackDataUsedCount - 1
	;	For $i = $i To UBound($__STACK__aszCurrentStackData) Step 1
	;		; _ArrayDelete($__STACK__aszCurrentStackData, $i)
	;	Next
	; EndIf
	$__STACK__aszCurrentStackData = ""
	Dim $__STACK__aszCurrentStackData[2]
	$__STACK__iCurrentStackDataUsedCount = 0
EndFunc

; This function saves the stack to a file
;
; Parameters:
;	$szFilePath: A string containing the path to
;				 save the file into.
;	$iMode:		See remarks.
;
; Returns:
;	Nothing
; @error:
;	Nothing
;
; Remarks:
; If iMode = 0, then the stack is saved AS IS
; If iMode = 1, then the magic variables are
;  trimmed from the array. The side effect of
;  this is that after more variables are added
;  to the stack and it resizes, it will resize
;  in orders of magnitude other than powers of 2
Func __STACK__SAVE($szFilePath, $iMode = 0)
	Local $copyArray = __STACK__ARRAY($iMode)
	; _ArrayDisplay($copyArray, "PENIS")
	Local $hFileHandle = FileOpen($szFilePath, 2) ; Overwrite
	_FileWriteFromArray($hFileHandle, $copyArray)
	FileFlush($hFileHandle)
	FileClose($hFileHandle)
EndFunc

; This function loads data from a file onto
; the stack
;
; Parameters:
;	$szFilePath: The path containing the stack's
;				 data.
;
; Returns:
;	Nothing
;
; @error:
;	Doesn't set @error
; Remarks:
;	See main remarks.
Func __STACK__LOAD($szFilePath)
	_FileReadToArray($szFilePath, $__STACK__aszCurrentStackData)
	; _ArrayDisplay($__STACK__aszCurrentStackData, "LOADED")
	; We delete element zero because when _FileReadToArray reads
	; the information from the file into the array, it stores the
	; number of items in $__STACK__aszCurrentStackData[0] and that
	; isn't what we want for this library.
	_ArrayDelete($__STACK__aszCurrentStackData, 0)
	; _ArrayDisplay($__STACK__aszCurrentStackData, "LOADED")
	$__STACK__iCurrentStackDataUsedCount = UBound($__STACK__aszCurrentStackData)
	; If we have less than or equal to three elements in the array,
	; then we should return to prevent a subscript error.
	If( $__STACK__iCurrentStackDataUsedCount <= 3 ) Then
		Return
	Else
		While($__STACK__aszCurrentStackData[$__STACK__iCurrentStackDataUsedCount-1] = "")
			$__STACK__iCurrentStackDataUsedCount = $__STACK__iCurrentStackDataUsedCount - 1
		WEnd
	EndIf
	; ConsoleWrite($__STACK__iCurrentStackDataUsedCount)
EndFunc

; Returns the stack as an array
; and trims the extra space from
; the array.
; If iMode = 0, then the stack is saved AS IS
; If iMode = 1, then the magic variables are
;  trimmed from the array. The side effect of
;  this is that after more variables are added
;  to the stack and it resizes, it will resize
;  in orders of magnitude other than powers of 2
Func __STACK__ARRAY($iMode = 0)
	Local $copy = ""
	Local $i = 0
	If( $iMode = 0 ) Then
			Return $__STACK__aszCurrentStackData
	Else
		For $i = 0 To ($__STACK__iCurrentStackDataUsedCount - 1) Step 1
			If( $__STACK__aszCurrentStackData[$i] <> $__STACK__szDEALLOC_MAGIC_WORD ) Then ; We can copy it
				$copy &= $__STACK__aszCurrentStackData[$i]
				If( ($i+1) < ($__STACK__iCurrentStackDataUsedCount) ) Then ; We're not at the last element
					$copy &= Chr(0)
				EndIf ; Otherwise, we don't want to add that last delim character.
			Else
				; ConsoleWrite("--> Debug on line 73")
			EndIf
		Next
		Return StringSplit($copy, Chr(0), 3) ; Each character in string is req for delim.
		; And returns the array as a 0 indexed array, so you have to use ubound to get the dim.
	EndIf
EndFunc

; Return the size of the stack.
Func __STACK__SIZE()
	Return $__STACK__iCurrentStackDataUsedCount
EndFunc
Func __STACK__STRESSTEST()
	__STACK__DEALLOC()
	Local $i = 0
	For $i = 0 To 1000000 Step 1
		__STACK__PUSH($i)
		;ConsoleWrite($i & " : " & __STACK__PUSH($i) & " ::: " & UBound($__STACK__aszCurrentStackData) & " :- " & _
		;			$__STACK__iCurrentStackDataUsedCount & @LF)
	Next
	__STACK__SAVE(@ScriptDir & "\" & "STACK.dat")
	MsgBox(0, "", "")
	__STACK__DEALLOC()
	MsgBox(0, "", "")
EndFunc

; Debugging...
FUNC __STACK__TEST()
	_ArrayDisplay($__STACK__aszCurrentStackData)
	Local $i = 0
	For $i = 0 To 10 Step 1
		ConsoleWrite($i & " : " & __STACK__PUSH($i) & " ::: " & UBound($__STACK__aszCurrentStackData) & " :- " & _
					 $__STACK__iCurrentStackDataUsedCount & @LF)
	Next
	_ArrayDisplay($__STACK__aszCurrentStackData, "Directly from stack data")
	Local $arrCopy = __STACK__ARRAY()
	_ArrayDisplay($arrCopy, "From __STACK__ARRAY()")
	__STACK__SAVE(@ScriptDir & "\" & "STACK.dat")

	For $i = 0 To 10 Step 1
		__STACK__POP()
	Next
	_ArrayDisplay($__STACK__aszCurrentStackData, "Directly from stack data after deletion")
	$arrCopy = __STACK__ARRAY()
	_ArrayDisplay($arrCopy, "From __STACK__ARRAY() after deletion")
	__STACK__DEALLOC()

	__STACK__LOAD(@ScriptDir & "\" & "STACK.dat")
	_ArrayDisplay($__STACK__aszCurrentStackData, "Data loaded from saved file")
	For $i = 0 To 10 Step 1
		ConsoleWrite($i & " : " & __STACK__PUSH($i) & " ::: " & UBound($__STACK__aszCurrentStackData) & " :- " & _
					 $__STACK__iCurrentStackDataUsedCount & @LF)
	Next
	_ArrayDisplay($__STACK__aszCurrentStackData, "After adding ten elements to data loaded from saved file")
	__STACK__DEALLOC()

	MsgBox(0, "", "")
EndFunc