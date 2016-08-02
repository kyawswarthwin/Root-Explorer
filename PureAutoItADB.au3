#include-once
#include <WinAPIMisc.au3>

;References:
;https://android.googlesource.com/platform/system/core/+/master/adb/OVERVIEW.TXT
;https://android.googlesource.com/platform/system/core/+/master/adb/SERVICES.TXT
;https://android.googlesource.com/platform/system/core/+/master/adb/SYNC.TXT
;UDF Version: 0.1 Beta
;UDF Coded By: Kyaw Swar Thwin

TCPStartup()

OnAutoItExitRegister("__Android_OnExit")

Func _Android_Connect()
	Local $iSocket = TCPConnect("127.0.0.1", 5037)
	Return SetError(@error, 0, $iSocket)
EndFunc   ;==>_Android_Connect

Func _Android_Shutdown($iSocket)
	TCPCloseSocket($iSocket)
EndFunc   ;==>_Android_Shutdown

Func _Android_Send($iSocket, $sCommand)
	Local $vData = __Send($iSocket, Hex(StringLen($sCommand), 4) & $sCommand)
	Return SetError(@error, 0, $vData)
EndFunc   ;==>_Android_Send

Func _Android_Sync($iSocket, $sCommand, $sData)
	Local $vData = _Android_Send($iSocket, "sync:")
	If @error Then Return SetError(@error, 0, $vData)
	If StringLeft($vData, 4) = "FAIL" Then Return $vData
	__Send($iSocket, $sCommand)
	__Send($iSocket, "0x" & Hex(_WinAPI_SwapDWord(StringLen($sData)), 8))
	$vData = __Send($iSocket, $sData)
	Return SetError(@error, 0, $vData)
EndFunc   ;==>_Android_Sync

Func _Android_FileListToArray($iSocket, $sFilePath)
	Local $sDelimiter = ":", $sFileList = "", $iFileMode, $iFileSize, $iLastModifiedTime, $iFileNameLength, $sFileName
	Local $vData = _Android_Sync($iSocket, "LIST", $sFilePath)
	If @error Then Return SetError(@error, 0, $vData)
	Local $i = 1
	While BinaryToString(BinaryMid($vData, $i, 4)) <> "DONE"
		$iFileMode = Int(BinaryMid($vData, $i + 4, 4))
		$iFileSize = Int(BinaryMid($vData, $i + 8, 4))
		$iLastModifiedTime = Int(BinaryMid($vData, $i + 12, 4))
		$iFileNameLength = Int(BinaryMid($vData, $i + 16, 4))
		$sFileName = BinaryToString(BinaryMid($vData, $i + 20, $iFileNameLength))
		$sFileList &= $sDelimiter & $sFileName & "|" & $iLastModifiedTime & "|" & $iFileMode & "|" & $iFileSize
		$i += $iFileNameLength + 20
	WEnd
	Return StringSplit(StringTrimLeft($sFileList, 1), $sDelimiter)
EndFunc   ;==>_Android_FileListToArray

Func __Android_OnExit()
	TCPShutdown()
EndFunc   ;==>__Android_OnExit

Func __Send($iSocket, $sCommand)
	TCPSend($iSocket, $sCommand)
	If @error Then SetError(1, 0, "")
	Sleep(500)
	Local $vData = TCPRecv($iSocket, 1024 * 64)
	If @error Then SetError(2, 0, "")
	Return $vData
EndFunc   ;==>__Send
