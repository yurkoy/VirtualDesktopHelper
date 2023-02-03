; AutoHotkey v2 script

#SingleInstance Force
#WinActivateForce
#UseHook
A_HotkeyInterval := 20
A_MaxHotkeysPerInterval := 20000
; A_MenuMaskKey := "vk07"

SetWorkingDir(A_ScriptDir)

; Get hwnd of AutoHotkey window, for listener
DetectHiddenWindows True
ahkWindowHwnd := WinExist("ahk_pid " . DllCall("GetCurrentProcessId", "Uint"))
ahkWindowHwnd += 0x1000 << 32

; Path to the DLL, relative to the script
VDA_PATH := "e:\work\code\VirtualDesktopAccessor\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
PinWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "PinWindow", "Ptr")
UnPinWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnPinWindow", "Ptr")
IsPinnedAppProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedApp", "Ptr")
PinAppProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "PinApp", "Ptr")
UnPinAppProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnPinApp", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")

GetDesktopCount() {
    global GetDesktopCountProc
    count := DllCall(GetDesktopCountProc, "UInt")
    return count
}

MoveCurrentWindowToDesktop(number) {
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
    activeHwnd := WinGetID("A")
    DllCall(MoveWindowToDesktopNumberProc, "UInt", activeHwnd, "UInt", number)
    ; DllCall(GoToDesktopNumberProc, "UInt", number)
}

MoveCurrentWindowToDesktopAndSwitch(number) {
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
    activeHwnd := WinGetID("A")
    DllCall(MoveWindowToDesktopNumberProc, "UInt", activeHwnd, "UInt", number)
    DllCall(GoToDesktopNumberProc, "UInt", number)
}

GoToPrevDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "UInt")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is 0, go to last desktop
    if (current = 0) {
        MoveOrGotoDesktopNumber(last_desktop)
    } else {
        MoveOrGotoDesktopNumber(current - 1)
    }
    return
}

GoToNextDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "UInt")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is last, go to first desktop
    if (current = last_desktop) {
        MoveOrGotoDesktopNumber(0)
    } else {
        MoveOrGotoDesktopNumber(current + 1)
    }
    return
}

GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    ; AllowSetForegroundWindow(ASFW_ANY)
    DllCall("User32\AllowSetForegroundWindow", "Int", -1)
    DllCall(GoToDesktopNumberProc, "Int", num)
    return
}
MoveOrGotoDesktopNumber(num) {
    ; If user is holding down Mouse left button, move the current window also
    if (GetKeyState("LButton")) {
        MoveCurrentWindowToDesktop(num)
    } else {
        GoToDesktopNumber(num)
    }
    return
}
GetDesktopName(num) {
    global GetDesktopNameProc
    utf8_buffer := Buffer(1024, 0)
    ran := DllCall(GetDesktopNameProc, "UInt", num, "Ptr", utf8_buffer, "UInt", utf8_buffer.Size)
    name := StrGet(utf8_buffer, 1024, "UTF-8")
    return name
}
SetDesktopName(num, name) {
    global SetDesktopNameProc
    OutputDebug(name)
    name_utf8 := Buffer(1024, 0)
    StrPut(name, name_utf8, "UTF-8")
    ran := DllCall(SetDesktopNameProc, "UInt", num, "Ptr", name_utf8)
    return ran
}
CreateDesktop() {
    global CreateDesktopProc
    ran := DllCall(CreateDesktopProc)
    return ran
}
RemoveDesktop(remove_desktop_number, fallback_desktop_number) {
    global RemoveDesktopProc
    ran := DllCall(RemoveDesktopProc, "UInt", remove_desktop_number, "UInt", fallback_desktop_number)
    return ran
}
ToggleWindowToAllDesktopsPin() {
    global IsPinnedWindowProc, PinWindowProc, UnPinWindowProc
    activeHwnd := WinGetID("A")

    pinned := DllCall(IsPinnedWindowProc, "UInt", activeHwnd)
    if (pinned) {
        return DllCall(UnPinWindowProc, "UInt", activeHwnd)
    }
    else {
        return DllCall(PinWindowProc, "UInt", activeHwnd)
    }
}

ChangeAppearance(desktopIndex) {
    A_IconTip := GetDesktopName(desktopIndex)
    iconFile := "./icons/" . desktopIndex . ".ico"
    if (!FileExist(iconFile)) {
        iconFile := "./icons/+.ico"
    }
    TraySetIcon(iconFile)
}

; SetDesktopName(0, "It works! 🐱")
current := DllCall(GetCurrentDesktopNumberProc, "UInt") + 1
ChangeAppearance(current)

DllCall(RegisterPostMessageHookProc, "Int", ahkWindowHwnd, "Int", 0x1400 + 30)
OnMessage(0x1400 + 30, OnChangeDesktop)
OnChangeDesktop(wParam, lParam, msg, hwnd) {
    Critical(1)
    OldDesktop := wParam + 1
    NewDesktop := lParam + 1
    ChangeAppearance(NewDesktop)
    ; Name := GetDesktopName(NewDesktop - 1)
    ; OutputDebug("Desktop changed to " Name " from " OldDesktop " to " NewDesktop)
    ; TraySetIcon(".\Icons\icon" NewDesktop ".ico")
}

#1::MoveOrGotoDesktopNumber(0)
#2::MoveOrGotoDesktopNumber(1)
#3::MoveOrGotoDesktopNumber(2)
#4::MoveOrGotoDesktopNumber(3)
#5::MoveOrGotoDesktopNumber(4)
#6::MoveOrGotoDesktopNumber(5)
#7::MoveOrGotoDesktopNumber(6)
#8::MoveOrGotoDesktopNumber(7)
#9::MoveOrGotoDesktopNumber(8)
#0::MoveOrGotoDesktopNumber(9)

#^1::MoveCurrentWindowToDesktop(0)
#^2::MoveCurrentWindowToDesktop(1)
#^3::MoveCurrentWindowToDesktop(2)
#^4::MoveCurrentWindowToDesktop(3)
#^5::MoveCurrentWindowToDesktop(4)
#^6::MoveCurrentWindowToDesktop(5)
#^7::MoveCurrentWindowToDesktop(6)
#^8::MoveCurrentWindowToDesktop(7)
#^9::MoveCurrentWindowToDesktop(8)
#^0::MoveCurrentWindowToDesktop(9)

#+1::MoveCurrentWindowToDesktopAndSwitch(0)
#+2::MoveCurrentWindowToDesktopAndSwitch(1)
#+3::MoveCurrentWindowToDesktopAndSwitch(2)
#+4::MoveCurrentWindowToDesktopAndSwitch(3)
#+5::MoveCurrentWindowToDesktopAndSwitch(4)
#+6::MoveCurrentWindowToDesktopAndSwitch(5)
#+7::MoveCurrentWindowToDesktopAndSwitch(6)
#+8::MoveCurrentWindowToDesktopAndSwitch(7)
#+9::MoveCurrentWindowToDesktopAndSwitch(8)
#+0::MoveCurrentWindowToDesktopAndSwitch(9)

#^+q::ToggleWindowToAllDesktopsPin()
