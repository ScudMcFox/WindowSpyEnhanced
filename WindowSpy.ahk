/* Window Spy
  
  - add ahk_pid to first edit field
  
*/

#InstallKeybdHook

#NoEnv
#SingleInstance Force

if (!A_IsAdmin)
{ run *runas "%A_ScriptFullPath%"
  ExitApp
}

SetWorkingDir, %A_ScriptDir%
SetBatchLines, 100
CoordMode, Pixel, Screen

global suspendswitch := false

; Routines Automatic Script Reload
  global reloadCheckTimer := 0
  global startScriptTimeStamp := 0
  global nowScriptTimeStamp := 0
  global scriptReloaded := false
  global FileChecked := false
Rscriptautoreload()
  { if (reloadCheckTimer < A_TickCount && FileExist(A_ScriptFullPath)) ; ReloadCheck for NewScriptState
    { file := A_ScriptFullPath ; get full filename
      FileGetTime, nowScriptTimeStamp, %file%
    
      if (FileChecked)
      { if (nowScriptTimeStamp != startScriptTimeStamp)
        { if (!scriptReloaded)
          MsgBox,, AutoReloadScript, Change Detected Reload Script ...`n%startScriptTimeStamp%`n%nowScriptTimeStamp%`n%file%, 0.5
          scriptReloaded := true
          ; logEvent("ScriptChangeDetected, Script Reloaded")
          OnExit,
          Reload
        }
      }
      else
      { startScriptTimeStamp := nowScriptTimeStamp
        FileChecked := true
      }
      reloadCheckTimer := A_TickCount + ( 5 *1000)
    }
  }  

  R_DumpArray(Dump_Array, Dump_Wait := true, Dump_Title := "") ; Notepad-Edition
    { DumpArrayFile := A_Temp "\TMP_DAF_" A_Scriptname
      FileDelete, % DumpArrayFile
      dumpstring := ""
      if (Dump_Array.MaxIndex() > 0)
      { dumpstring .= "Dump_Array-Export: (" A_ScriptName ") " Dump_Title "`n`nArraySize: " Dump_Array.MaxIndex() " entries`n`n"
        for lib_key,lib_val in Dump_Array
        { if (lib_val != "")
          { lib_val := StrReplace(lib_val, "`n", "/n")
            lib_val := StrReplace(lib_val, "`r", "/r")
            dumpstring .= lib_key ": >" lib_val "<`n"
          }
           else
           {  skipped++
              skippedList .= lib_key ","
           }
        }
        StringTrimRight, skippedList, skippedList, 1
        dumpstring .= "`n" skipped " entries with no value (" skippedList ")`n"
        FileAppend, % dumpstring, % DumpArrayFile, UTF-16
            
        if (Dump_Wait)
          runWait, % "notepad.exe " DumpArrayFile
         else
          run    , % "notepad.exe " DumpArrayFile
      }
      else
        MsgBox % "DumpedArray is empty or not an array."
    }

; GUI

  txtNotFrozen  := "(Hold Ctrl to suspend / Press Ins to stop updates)"
  txtFrozen     := "(Updates suspended, Press Ins or Release Ctrl)"
  txtMouseCtrl  := "Control Under Mouse Position"
  txtFocusCtrl  := "Focused Control"
  colProgress   := ""

Gui, New, hwndhGui Resize MinSize +AlwaysOnTop
Gui, Add, Text,, Window Title, Class and Process:
Gui, Add, Checkbox, yp xp+200 w120 Right Checked vCtrl_FollowMouse, Follow Mouse
Gui, Add, Edit, xm w320 r3 ReadOnly -Wrap vCtrl_Title
Gui, Add, Text, w80, Mouse Position:
; Gui, Add, Button, x+20 w40 h15 g_BTNCopyColor, % "cColor"
Gui, Add, Edit, x10 w320 r5 ReadOnly vCtrl_MousePos
Gui, Add, Text, w160 vCtrl_CtrlLabel, % txtFocusCtrl ":"
Gui, Add, Edit, w320 r4 ReadOnly vCtrl_Ctrl
Gui, Add, Progress, x180 y171 w150 h22 Disabled c000000 vcolProgress, 100
Gui, Add, Text, x180 y171 w150 h22 g_BTNCopyColor BackgroundTrans, % ""
Gui, Add, Text, xm , Active Window Position:
Gui, Add, Edit, w320 r2 ReadOnly vCtrl_Pos
Gui, Add, Text,, Status Bar Text:
Gui, Add, Edit, w320 r4 ReadOnly vCtrl_SBText
Gui, Add, Checkbox, vCtrl_IsSlow, Slow TitleMatchMode
Gui, Add, Text,, Visible Text:
Gui, Add, Edit, w320 r5 ReadOnly vCtrl_VisText
Gui, Add, Text,, All Text:
Gui, Add, Edit, w320 r5 ReadOnly vCtrl_AllText
Gui, Font,, % "s12 q4"
Gui, Add, Text, w320 r1 vCtrl_Freeze, % txtNotFrozen

if (A_ComputerName == "SCUDMCFOX")
  Gui, Show, x2560 y540 NoActivate, Window Spy
if (A_ComputerName == "TV")
  Gui, Show, % "x" A_ScreenWidth-1024 " y" A_ScreenHeight*2-700 " NoActivate", Window Spy
else
  Gui, Show, % "NoActivate", Window Spy
OnMessage(0x201, "WM_LBUTTONDOWN") ; Move Window  

GetClientSize(hGui, temp)
horzMargin := temp*96//A_ScreenDPI - 320

; Loop
  SetTimer, Update, 250
  return

; Routines

  WM_LBUTTONDOWN() ; make guis mouse movable with : OnMessage(0x201, "WM_LBUTTONDOWN")
    { PostMessage, 0xA1, 2
    }

GuiSize:
  Gui %hGui%:Default
  if !horzMargin
    return
  SetTimer, Update, % A_EventInfo=1 ? "Off" : "On" ; Suspend on minimize
  ctrlW := A_GuiWidth - horzMargin
  list = Title,MousePos,MouseCur,Pos,SBText,VisText,AllText,Freeze
  Loop, Parse, list, `,
    GuiControl, Move, Ctrl_%A_LoopField%, w%ctrlW%
  return

Update:
  Gui %hGui%:Default
  GuiControlGet, Ctrl_FollowMouse
  CoordMode, Mouse, Screen
  MouseGetPos, msX, msY, msWin, msCtrl
  actWin := WinExist("A")
  if Ctrl_FollowMouse
  { curWin := msWin
    curCtrl := msCtrl
    WinExist("ahk_id " curWin)
  }
  else
  { curWin := actWin
    ControlGetFocus, curCtrl
  }
  WinGetTitle, t1
  WinGetClass, t2
  if (curWin = hGui || t2 = "MultitaskingViewFrame") ; Our Gui || Alt-tab ; prevent stuttering on moving
  ; if (t2 = "MultitaskingViewFrame") ; Our Gui || Alt-tab
  { GuiControl,, Ctrl_Freeze, % txtFrozen
    return
  }
  GuiControl,, Ctrl_Freeze, % txtNotFrozen
  WinGet, t3, ProcessName
  GuiControl,, Ctrl_Title, % t1 "`nahk_class " t2 "`nahk_exe " t3
  CoordMode, Mouse, Relative
  MouseGetPos, mrX, mrY
  CoordMode, Mouse, Client
  MouseGetPos, mcX, mcY
  PixelGetColor, mClr, %msX%, %msY%, RGB
  mClr := SubStr(mClr, 3)
  PixelGetColor, mClrS, %msX%, %msY%, RGB Slow
  mClrS := SubStr(mClrS, 3)
  GuiControl, +c%mClrS%, colProgress
  GuiControl,, Ctrl_MousePos, % "Screen:`t" msX ", " msY " (less often used)`nWindow:`t" mrX ", " mrY " (default)`nClient:`t" mcX ", " mcY " (recommended)"
    . "`nColorN:`t" mClr " (Red=" SubStr(mClr, 1, 2) " Green=" SubStr(mClr, 3, 2) " Blue=" SubStr(mClr, 5) ")"
    . "`nColorS:`t" mClrS " (Red=" SubStr(mClrS, 1, 2) " Green=" SubStr(mClrS, 3, 2) " Blue=" SubStr(mClrS, 5) ")`n"
  GuiControl,, Ctrl_CtrlLabel, % (Ctrl_FollowMouse ? txtMouseCtrl : txtFocusCtrl) ":"
  if (curCtrl)
  { ControlGetText, ctrlTxt, %curCtrl%
    cText := "ClassNN:`t" curCtrl "`nText:`t" textMangle(ctrlTxt)
      ControlGetPos cX, cY, cW, cH, %curCtrl%
      cText .= "`n`tx: " cX "`ty: " cY "`tw: " cW "`th: " cH
      WinToClient(curWin, cX, cY)
    ControlGet, curCtrlHwnd, Hwnd,, % curCtrl
      GetClientSize(curCtrlHwnd, cW, cH)
      cText .= "`nClient:`tx: " cX "`ty: " cY "`tw: " cW "`th: " cH
  }
  else
    cText := ""
    
  GuiControl,, Ctrl_Ctrl, % cText
  WinGetPos, wX, wY, wW, wH
  GetClientSize(curWin, wcW, wcH)
  GuiControl,, Ctrl_Pos, % "`tx: " wX "`ty: " wY "`tw: " wW "`th: " wH "`nClient:`t`t`tw: " wcW "`th: " wcH
  sbTxt := ""
  Loop
  { StatusBarGetText, ovi, %A_Index%
    if ovi =
      break
    sbTxt .= "(" A_Index "):`t" textMangle(ovi) "`n"
    Rscriptautoreload()
  }
  StringTrimRight, sbTxt, sbTxt, 1
  GuiControl,, Ctrl_SBText, % sbTxt
  GuiControlGet, bSlow,, Ctrl_IsSlow
  if bSlow
  { DetectHiddenText, Off
    WinGetText, ovVisText
    DetectHiddenText, On
    WinGetText, ovAllText
  }
  else
  { ovVisText := WinGetTextFast(false)
    ovAllText := WinGetTextFast(true)
  }
  GuiControl,, Ctrl_VisText, % ovVisText
  GuiControl,, Ctrl_AllText, % ovAllText
  return

GuiClose:
  ExitApp

WinGetTextFast(detect_hidden)
  { ; WinGetText ALWAYS uses the "fast" mode - TitleMatchMode only affects
    ; WinText/ExcludeText parameters.  In Slow mode, GetWindowText() is used
    ; to retrieve the text of each control.
    WinGet controls, ControlListHwnd
    static WINDOW_TEXT_SIZE := 32767 ; Defined in AutoHotkey source.
    VarSetCapacity(buf, WINDOW_TEXT_SIZE * (A_IsUnicode ? 2 : 1))
    text := ""
    Loop Parse, controls, `n
    { if !detect_hidden && !DllCall("IsWindowVisible", "ptr", A_LoopField)
        continue
      if !DllCall("GetWindowText", "ptr", A_LoopField, "str", buf, "int", WINDOW_TEXT_SIZE)
        continue
      text .= buf "`r`n"
    }
    return text
  }

GetClientSize(hWnd, ByRef w := "", ByRef h := "")
  { VarSetCapacity(rect, 16)
    DllCall("GetClientRect", "ptr", hWnd, "ptr", &rect)
    w := NumGet(rect, 8, "int")
    h := NumGet(rect, 12, "int")
  }

WinToClient(hWnd, ByRef x, ByRef y)
  { WinGetPos wX, wY,,, ahk_id %hWnd%
    x += wX, y += wY
    VarSetCapacity(pt, 8), NumPut(y, NumPut(x, pt, "int"), "int")
    if !DllCall("ScreenToClient", "ptr", hWnd, "ptr", &pt)
      return false
    x := NumGet(pt, 0, "int"), y := NumGet(pt, 4, "int")
      return true
  }

textMangle(x)
  { if pos := InStr(x, "`n")
      x := SubStr(x, 1, pos-1), elli := true
    if StrLen(x) > 40
    { StringLeft, x, x, 40
      elli := true
    }
    if elli
      x .= " (...)"
    return x
  }

; Buttons

_BTNCopyColor:
  SoundBeep, 250,70
  clipboard := mClrS
  return

; Hotkeys MouseMovement with ALT and ARROW keys

!up::
  MouseMove, 0,-1, 0,R
  return
!down::
  MouseMove, 0,1, 0,R
  return
!left::
  MouseMove, -1,0, 0,R
  return
!right::
  MouseMove, 1,0, 0,R
  return

; Hotkeys

~*Ctrl::
  if (!suspendswitch)
  { SetTimer, Update, Off
    GuiControl, %hGui%:, Ctrl_Freeze, % txtFrozen
  }
  return

~*Ctrl up::
  if (!suspendswitch)
    SetTimer, Update, On
  return
  
^.:: ; ctrl + dot = copy color data to clipboard
  clipboard :=  msX "," msY ",""" mClrS """"
  return
  
*Insert::
  suspendswitch := !suspendswitch
  if (suspendswitch)
  { SetTimer, Update, Off
    GuiControl, %hGui%:, Ctrl_Freeze, % txtFrozen
    clipboard :=  msX "," msY ",""" mClrS """"
  }
   else
  { SetTimer, Update, On
  }
  return
  
sc01B:: ; plus near enter // shows a list of all controls that window has to offer
  WinGetTitle, wTitle, A
  WinGet, myList, ControlList, % wTitle
  myList := StrSplit(myList,"`n")
  R_DumpArray(myList, true, wTitle) ; R_DumpArray(Dump_Array, Dump_Wait := true, Dump_Title := "") ; Notepad-Edition
  return
  
  