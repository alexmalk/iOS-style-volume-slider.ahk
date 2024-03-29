; iOS-style Volume Slider
; Author: rmalkiew@gmail.com
; Requirements: Windows 10 – dependency on Segoe MDL2 Asstes (rendering icons)

; Hotkeys

    ; Volume Up (PgUp)
        PgUp::
            Volume := GetVolume() 
            If ( A_PriorHotkey <> "PgUp" or A_TimeSincePriorHotkey >= 250 )
                SoundSet, +2
            If ( A_PriorHotkey = "PgUp" and A_TimeSincePriorHotkey < 250 )
                SoundSet, +8
            If !WinExist("ahk_class AutoHotkeyGUI") {
                Notify(GetVolumeIcon(),-1,GetVolume())
                SetTimer, AnimateDissolveOut, 750
            } Else {
                Icon := GetVolumeIcon()
                Loop { ; Smooth progress bar movement
                    Volume += 2
                    GuiControl,, NotifyIcon, % Icon
                    GuiControl,, NotifyProgress, % Volume ; Sandwiched to minimize icon flickering
                    GuiControl,, NotifyIcon, % Icon
                } Until ( Volume = GetVolume() or Volume = 100 )
                SetTimer, AnimateDissolveOut, 1000
            }
        Return

    ; Volume Down (PgDn)
        PgDn::
            Volume := GetVolume()
            If ( A_PriorHotkey <> "PgDn" or A_TimeSincePriorHotkey >= 250 )
                SoundSet, -2
            If ( A_PriorHotkey = "PgDn" and A_TimeSincePriorHotkey < 250 )
                SoundSet, -8
            If !WinExist("ahk_class AutoHotkeyGUI") {
                Notify(GetVolumeIcon(),-1,GetVolume())
                SetTimer, AnimateDissolveOut, 750
            } Else {
                Icon := GetVolumeIcon()
                Loop { ; Smooth progress bar movement
                    Volume -= 2
                    GuiControl,, NotifyIcon, % Icon
                    GuiControl,, NotifyProgress, % Volume ; Sandwiched to minimize icon flickering
                    GuiControl,, NotifyIcon, % Icon
                } Until ( Volume = GetVolume() or Volume = 0 )
                SetTimer, AnimateDissolveOut, 1000
            }
        Return

    ; Mute System Toggle (Ctrl+PgDn)
        <^PgDn::
            SoundGet, MuteSystem, , Mute
            If ( MuteSystem = "Off" ) {
                SoundSet, +1, , Mute
                Notify("",,GetVolume())
            } Else {
                SoundSet, +1, , Mute
                If ( Fullscreen() = False )
                    SoundPlay, %A_WinDir%\Media\Windows Background.wav
                Notify(GetVolumeIcon(),,GetVolume())          
            }
        Return

; Functions

    ; Detect Fullscreen App
        Fullscreen() {
            WinGetClass, Class, A
            WinGetPos, X, Y, Width, Height, A
            Return Width = A_ScreenWidth and Height = A_ScreenHeight and Class <> "Windows.UI.Core.CoreWindow" and Class <> "WorkerW"
        }

    ; Animate Dissolve In
        AnimateDissolveIn() {
            Alpha := 0
            If ( Fullscreen() = False ) {
                Loop { ; Darker when out of fullscreen
                    Alpha += 56
                    Sleep 1
                    WinSet, Transparent, %Alpha%, %A_ScriptName%
                } Until ( Alpha >= 224 )
            } Else {
                Loop { ; Lighter when in fullscreen
                    Alpha += 52
                    Sleep 1
                    WinSet, Transparent, %Alpha%, %A_ScriptName%
                } Until ( Alpha >= 208 )
            }
        }

    ; Animate Dissolve Out
        AnimateDissolveOut() {
            If ( Fullscreen() = False ) {
                Alpha := 224
                Loop { ; Darker when out of fullscreen
                    Alpha -= 28
                    Sleep 1
                    WinSet, Transparent, %Alpha%, %A_ScriptName%
                } Until ( Alpha <= 0 )
            } Else {
                Alpha := 208
                Loop { ; Lighter when in fullscreen
                    Alpha -= 26
                    Sleep 1
                    WinSet, Transparent, %Alpha%, %A_ScriptName%
                } Until ( Alpha <= 0 )
            }
        }

    ; Animate Dissolve Out (Timer for Volume Notify)
        AnimateDissolveOut:
            If ( Fullscreen() = False and A_PriorHotkey ~= "Pg" ) ; Avoid playing sound in fullscreen, audio assumed active
                SoundPlay, %A_WinDir%\Media\Windows Background.wav
            SetTimer, AnimateDissolveOut, Off
            AnimateDissolveOut()
            Gui, Destroy
        Return

    ; Get Volume
        GetVolume() {
            SoundGet, Volume
            Volume := Round(Volume)
            Return %Volume%
        }

    ; Get Volume Icon (Segoe MDL2 Assets)
        GetVolumeIcon() {
            SoundGet, MuteSystem, , Mute
            If ( MuteSystem = "Off") {
                SoundGet, Volume
                If ( Volume = 0 )
                    Return ""
                If ( Volume > 0 and Volume < 33 )
                    Return ""
                If ( Volume >= 33 and Volume < 66 )
                    Return ""
                If ( Volume >= 66 and Volume <= 100 )
                    Return ""
            } Else {
                Return ""
            }
        }


    ; Notify GUI
        Notify(Icon:="", Time:=750, Progress:="") {

            Global ; Make variables accessible to other files
            GuiEnter:
            If !WinExist("ahk_class AutoHotkeyGUI") { ; Avoid re-rendering existing GUI
                
                Gui, +HwndHGui +LastFound +ToolWindow +AlwaysOnTop -Caption -Disabled ; GUI options
                DllCall("SetClassLong","UInt",HGui,"Int",-26,"Int",DllCall("GetClassLong","UInt",HGui,"Int",-26)|0x20000) ; Drop Shadow
                Gui, Color, 090909, 090909 ; Background Color

                If ( Fullscreen() = False ) { ; Large, centered UI
                    ; Icon + Progress Bar
                    Gui, Add, Progress, vNotifyProgress x-1 y-1 w322 h98 cE9E9E9 Background090909, %Progress%
                    Gui, Font, s48 c666666, Segoe MDL2 Assets
                    Gui, Add, Text, BackgroundTrans vNotifyIcon x24 y16 , %Icon%
                    Gui, Margin, 0, 0
                    Gui := [48, "Center"]

                } Else { ; Small, top-aligned UI
                    ; Icon + Progress Bar
                    Gui, Add, Progress, vNotifyProgress x-1 y-1 w192 h50 cE9E9E9 Background090909, %Progress%
                    Gui, Font, s24 c666666, Segoe MDL2 Assets
                    Gui, Add, Text, vNotifyIcon x16 y8 BackgroundTrans, %Icon%
                    Gui, Margin, 0, 0
                    Gui := [24, 80]
                }

                DetectHiddenWindows, On
                Gui, Show, Hide ; Pre-render GUI
                WinSet, Transparent, 0, %A_ScriptName% ; Apply 0% transparency
                WinGetPos, X, Y, Width, Height, %A_ScriptName% ; Get GUI info
                X := (A_ScreenWidth/2)-(Width/2) ; Calculate true screen center
                Gui, Show, % "x" X " y" Gui[2] " NA"
                WinSet, Region, % "0-0 w" Width " h" Height " r" Gui[1] "-" Gui[1] ; Apply rounded corners
                AnimateDissolveIn()

            } Else {
                AnimateDissolveOut()
                Gui, Destroy
                Gosub, GuiEnter
            }
            If ( Time >= 0 ) {
                Sleep %Time% ; Time to display Notify
                AnimateDissolveOut()
                Gui, Destroy
            }
            Return
        }
