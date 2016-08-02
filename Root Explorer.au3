#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Description=Root Explorer
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Copyright © 2015 Kyaw Swar Thwin
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListViewConstants.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>
#include <GuiImageList.au3>
#include "PureAutoItADB.au3"

Global $aFileList

RunWait("adb start-server", "", @SW_HIDE)

$hGUI = GUICreate("Root Explorer", 600, 400, -1, -1)
$idInput = GUICtrlCreateInput("/", 10, 13, 495, 21)
$idButton = GUICtrlCreateButton("Refresh", 515, 10, 75, 25)
$g_hListView = GUICtrlCreateListView("Name|Date Modified|Permission|Size", 10, 45, 580, 345)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 0, 200)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 1, 100)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 2, 100)
GUICtrlSendMsg(-1, $LVM_SETCOLUMNWIDTH, 3, 100)
Dim $hGUI_AccelTable[1][2] = [["{Enter}", $idButton]]
GUISetAccelerators($hGUI_AccelTable)
GUISetState(@SW_SHOW)
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

_Explorer()

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $idButton
			_Explorer()
	EndSwitch
WEnd

Func _Explorer()
	_GUICtrlListView_DeleteAllItems($g_hListView)
	Global $iSocket = _Android_Connect()
	_Android_Send($iSocket, "host:transport-any")
	$aFileList = _Android_FileListToArray($iSocket, GUICtrlRead($idInput))
	If GUICtrlRead($idInput) = "/" Then
		For $i = 3 To $aFileList[0]
			$aItem = StringSplit($aFileList[$i], "|")
			$iItem = GUICtrlCreateListViewItem($aFileList[$i], $g_hListView)
			If BitAND($aItem[3], BitShift(1, -14)) = BitShift(1, -14) Then
				GUICtrlSetImage($iItem, "shell32.dll", 4)
			Else
				GUICtrlSetImage($iItem, "shell32.dll", 1)
			EndIf
		Next
	Else
		For $i = 2 To $aFileList[0]
			$aItem = StringSplit($aFileList[$i], "|")
			$iItem = GUICtrlCreateListViewItem($aFileList[$i], $g_hListView)
			If BitAND($aItem[3], BitShift(1, -14)) = BitShift(1, -14) Then
				GUICtrlSetImage($iItem, "shell32.dll", 4)
			Else
				GUICtrlSetImage($iItem, "shell32.dll", 1)
			EndIf
		Next
	EndIf
	_Android_Shutdown($iSocket)
EndFunc   ;==>_Explorer

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hWndListView, $tInfo
	; Local $tBuffer
	$hWndListView = $g_hListView
	If Not IsHWnd($g_hListView) Then $hWndListView = GUICtrlGetHandle($g_hListView)

	$tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $hWndListView
			Switch $iCode
				Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
					$tInfo = DllStructCreate($tagNMITEMACTIVATE, $lParam)

					$iIndex = DllStructGetData($tInfo, "Index")

					If $iIndex <> -1 Then
						$aItem = StringSplit(_GUICtrlListView_GetItemTextString($g_hListView, $iIndex), "|")
						If BitAND($aItem[3], BitShift(1, -14)) = BitShift(1, -14) Then
							If GUICtrlRead($idInput) = "/" Then
								GUICtrlSetData($idInput, GUICtrlRead($idInput) & $aItem[1])
							Else
								If $aItem[1] = ".." Then
									Dim $sFilePath = StringLeft(GUICtrlRead($idInput), StringInStr(GUICtrlRead($idInput), "/", 0, -1))
									If StringLen($sFilePath) = 1 Then
										GUICtrlSetData($idInput, $sFilePath)
									Else
										GUICtrlSetData($idInput, StringLeft($sFilePath, StringLen($sFilePath) - 1))
									EndIf
								Else
									GUICtrlSetData($idInput, GUICtrlRead($idInput) & "/" & $aItem[1])
								EndIf
							EndIf
							_Explorer()
						EndIf
					EndIf
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY
