#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:        Alexander Alvonellos

 Script Function:
	A set of utility functions for manipulating things to do with the
	display

#ce ----------------------------------------------------------------------------
#include-once

__SCREEN__TEST()

Func __SCREEN__GET_MAX_X()
   Return @DesktopWidth
EndFunc

Func __SCREEN__GET_MAX_Y()
   Return @DesktopHeight
EndFunc

Func __SCREEN__GET_MAX_XY()
   Local $szRetBuf = ""
   $szRetBuf &= __SCREEN__GET_MAX_X() & "," & __SCREEN__GET_MAX_Y()
   Return StringSplit($szRetBuf, ",", 2)
EndFunc

Func __SCREEN__CALCULATE_CHANGE_RATIO_X($previousResolution_X)
   Local $value = __SCREEN__GET_MAX_X()/$previousResolution_X
   Local $ret = Round($value, 2) 
   Return $ret
EndFunc

Func __SCREEN__CALCULATE_CHANGE_RATIO_Y($previousResolution_Y)
   Local $value = __SCREEN__GET_MAX_Y()/$previousResolution_Y
   Local $ret = Round($value, 2) 
   Return $ret
EndFunc

Func __SCREEN__CALCULATE_CHANGE_RATIO_XY($previousResolution_X, $previousResolution_Y)
   Local $szRetBuf = ""
   $szRetBuf &= __SCREEN__CALCULATE_CHANGE_RATIO_X($previousResolution_X) & _
			    "," & _
			    __SCREEN__CALCULATE_CHANGE_RATIO_Y($previousResolution_Y)
   Return StringSplit($szRetBuf, ",", 2)
EndFunc

Func __SCREEN__TEST()
   ConsoleWrite("Resolution: " & __SCREEN__GET_MAX_X() & " :: " & __SCREEN__GET_MAX_Y() & @LF)
   Local $adBuf = __SCREEN__GET_MAX_XY()
   ConsoleWrite("Resolution (x,y): " & $adBuf[0] & " :: " & $adBuf[1] & @LF)
   
   ConsoleWrite("Ratio_X: " & __SCREEN__CALCULATE_CHANGE_RATIO_X(1024) & @LF)
   ConsoleWrite("Ratio_Y: " & __SCREEN__CALCULATE_CHANGE_RATIO_Y(768)  & @LF)
   $adBuf = __SCREEN__CALCULATE_CHANGE_RATIO_XY(1024, 768)
   ConsoleWrite("Ratio (x,y): " & $adBuf[0] & " :: " & $adBuf[1] & @LF)
   Local $defX = 994
   Local $defY = 7
   Local $ratX = __SCREEN__CALCULATE_CHANGE_RATIO_X(1024)
   Local $ratY = __SCREEN__CALCULATE_CHANGE_RATIO_Y(768)
   Local $newX = $ratX * $defX
   Local $newY = $ratX * $defY
   $newX = Ceiling($newX)
   $newY = Ceiling($newY) 
   ConsoleWrite("New (x, y): "  & $newX & " :: " & $newY & @LF)
   MouseMove($newX, $newY)
  Sleep(10000)
EndFunc