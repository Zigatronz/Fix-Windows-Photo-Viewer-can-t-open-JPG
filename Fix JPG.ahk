
; Initialize
TotalFiles := 0
TargetedFiles := []
ProgramTitle := "Fix JPG"
FilesWriteFailed := []
IfNotExist, % A_ScriptDir . "\ToFix"
{
    FileCreateDir, % A_ScriptDir . "\ToFix"
    MsgBox, 1, % ProgramTitle, % "Put all JPG file that you wish to fix in 'ToFix' folder.`n`nPress OK when you done.`nPress Cancel to exit."
    IfMsgBox, Cancel
    {
        FileRemoveDir, % A_ScriptDir . "\ToFix", 0
        ExitApp
    }
}
; Start read
Loop, Files, % A_ScriptDir . "\ToFix\*.jpg", FR
    TotalFiles ++
Gui, New,, % ProgramTitle . " - Scanning"
Gui, Margin, 10, 10
Gui, Add, Text, w500 vCurrentProcess
Gui, Add, Progress, % "w500 h20 vProgress Range0-" . TotalFiles, 0
Gui, Show
Loop, Files, % A_ScriptDir . "\ToFix\*.jpg", FR
{
    GuiControl, Text, CurrentProcess, % SubStr(A_LoopFileFullPath, StrLen(A_ScriptDir . "\ToFix\")+1)
    GuiControl, , Progress, +1
    FileRead, data, *c %A_LoopFileFullPath%
    Loop, 1000 ; set max read bytes to save performance if fails to find 'ICC_PROFILE'
    {
        if (StrGet(&data + int2hex(A_Index), 11, "UTF-8") == "ICC_PROFILE"){
            TargetedFiles.Push([A_LoopFileFullPath, A_Index+10])
            Break
        }
    }
}
; Gui conformation
Gui, New,, % ProgramTitle
Gui, Margin, 10, 10
Gui, Add, ListBox, w600 h200, % ArrayToList(TargetedFiles)
Gui, Add, Button, x250 w100 h20, Start
Gui, Show
Return
; Start write
ButtonStart:
Gui, Destroy
Gui, New,, % ProgramTitle . " - Working"
Gui, Margin, 10, 10
Gui, Add, Text, w500 vCurrentProcess
Gui, Add, Progress, % "w500 h20 vProgress Range0-" . TargetedFiles.Length(), 0
Gui, Show
for i,c in TargetedFiles
{
    GuiControl, Text, CurrentProcess, % c[1]
    GuiControl, , Progress, +1
    Write := BinWrite(c[1], "58", 1, c[2])
    if (Write != 1)
        FilesWriteFailed.Push(c)
}
; Report
GuiControl, Text, CurrentProcess, % "Complete!"
MsgBox, % "Program Complete!`n`nTotal JPG converted: " . TargetedFiles.Length() . "`nTotal Ignore: " . (TotalFiles - TargetedFiles.Length()) . "`nTotal Failed: " . FilesWriteFailed.Length()
Gui, Destroy
if (FilesWriteFailed.Length() > 0)
    FileAppend, % ArrayToList(FilesWriteFailed, "Unable to write: ", " at index :"), %ProgramTitle% - Convert Error.log

GuiEscape:
GuiClose:
ExitApp

ArrayToList(array, sStr:="", mStr:="", eStr:=""){
    local list
    for i,c in array
    {
        if (sStr)
            list .= "|" . sStr . SubStr(c[1], StrLen(A_ScriptDir . "\ToFix\")+1) . mStr . c[2] . eStr
        Else
            list .= "|" . SubStr(c[1], StrLen(A_ScriptDir . "\ToFix\")+1)
    }
    Return SubStr(list, 2)
}

BinWrite(file, data, n=0, offset=0){
    h := DllCall("CreateFile", "str", file, "Uint", 0x40000000, "Uint", 0, "UInt", 0, "UInt", 4, "Uint", 0, "UInt", 0)
    IfEqual h, -1, SetEnv, ErrorLevel, -1
    IfNotEqual ErrorLevel, 0, Return, 0
    m := 0
    IfLess offset, 0, SetEnv, m, 2
    r := DllCall("SetFilePointerEx", "Uint", h, "Int64", offset, "UInt *", p, "Int", m)
    IfEqual r, 0, SetEnv, ErrorLevel, -3
    IfNotEqual ErrorLevel, 0, {
        t := ErrorLevel
        DllCall("CloseHandle", "Uint", h)
        ErrorLevel := t
        Return 0
    }
    TotalWritten := 0
    m := Ceil(StrLen(data)/2)
    If (n <= 0 or n > m)
        n := m
    Loop % n
    {
        StringLeft c, data, 2
        StringTrimLeft data, data, 2
        c := "0x" . c
        Result := DllCall("WriteFile", "UInt", h, "UChar *", c, "UInt", 1, "UInt *", Written, "UInt", 0)
        TotalWritten += Written
        if (!Result or Written < 1 or ErrorLevel)
        Break
    }
    IfNotEqual ErrorLevel, 0, SetEnv, t, % ErrorLevel
    h := DllCall("CloseHandle", "Uint", h)
    IfEqual h,-1, SetEnv, ErrorLevel, -2
    IfNotEqual t,,SetEnv, ErrorLevel, % t
    Return TotalWritten
}

; Credit: jNizM
int2hex(int){
    HEX_INT := 8
    while (HEX_INT--)
    {
        n := (int >> (HEX_INT * 4)) & 0xf
        h .= n > 9 ? chr(0x37 + n) : n
        if (HEX_INT == 0 && HEX_INT//2 == 0)
            h .= " "
    }
    return "0x" h
}
