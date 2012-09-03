#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_Add_Constants=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.8.1
 Author:         Alexander Alvonellos

 Script Function:
	This is a cleaner script to be called by CSC.

#ce ----------------------------------------------------------------------------
#include "../Include/__DEFRAGGLER.au3"
#include "../Include/__CCLEANER.au3"
#include "../Include/__SINGLETON.au3"
#include "../Include/__GENERAL.au3"

;__SINGLETON__SINGLETON()

Func main()
   	__GENERAL__CERR("In CLEAN, performing cleanup...")
	__CCLEANER__CLEAN()
    __DEFRAGGLER__DEFRAG()
EndFunc

main()