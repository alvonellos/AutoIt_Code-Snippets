#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------
#include-once
#include <File.au3>
#include <Date.au3>



; AutoItSetOption("MustDeclareVars", 1)
Func __GENERAL__CERR($message)
	Local $hFile = FileOpen(@ScriptDir & "\" &  @ComputerName & ".txt", 1) ; Append
	_FileWriteLog($hFile, @ComputerName & " :: " & $message)
	FileFlush($hFile)
	FileClose($hfile)
EndFunc

Func __GENERAL__TIMESTAMP($cDateDelimiter = "-", $cDateTimeDelimiter = "@", _
						  $cTimeDelimiter = ":", $cMSecDelimiter = ".")
	Local $comb = ""
   $comb &= $cDateDelimiter & @MON
   $comb &= $cDateDelimiter & @MDAY
   $comb &= $cDateTimeDelimiter & @HOUR
   $comb &= $cTimeDelimiter & @MIN
   $comb &= $cTimeDelimiter & @SEC
   $comb &= $cMSecDelimiter & @MSEC
   Return $comb
EndFunc

; This function returns the current
; epoch time.
Func __GENERAL__EPOCH()
	Return _DateDiff('s', "1970/01/01 00:00:00", _NowCalc())
EndFunc
   ;; Left off here 071612
;; http://www.phy.mtu.edu/~suits/notefreqs.html
Func __GENERAL__PLAY_NOTE_A($iDurationMillisec = 200)
	Beep(440,$iDurationMillisec)
EndFunc

Func __GENERAL__PLAY_NOTE_B($iDurationMillisec = 200)
	Beep(495,$iDurationMillisec)
EndFunc

Func __GENERAL__PLAY_NOTE_C($iDurationMillisec = 200)
	Beep(528,$iDurationMillisec)
EndFunc

Func __GENERAL__PLAY_NOTE_D($iDurationMillisec = 200)
	Beep(594,$iDurationMillisec)
EndFunc

Func __GENERAL__PLAY_NOTE_E($iDurationMillisec = 200)
	Beep(660,$iDurationMillisec)
EndFunc

Func __GENERAL__PLAY_NOTE_F($iDurationMillisec = 200)
	Beep(704,$iDurationMillisec)
EndFunc

Func __GENERAL__PLAY_NOTE_G($iDurationMillisec = 200)
	Beep(783,$iDurationMillisec)
EndFunc