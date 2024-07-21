
; AHK v1.1.37.01

; Initialize
TargetedFiles := []
ProgramTitle := "Fix JPG"
FilesWriteFailed := []
JPGExts := ["jpg", "jpeg"]

; Drag and Drop
Gui, Margin, 5, 5
Gui, Add, Text, w650 h20 Center, % "Drag and drop your JPG files and folders here"
Gui, Add, ListView, w650 h200 vListView, Path
LV_ModifyCol(1,635)
Gui, Add, Button, x275 y235 w100 h20, Scan
Gui, Show, , % ProgramTitle
Menu PopRow, Add, Remove folder, PopRow
Return

; Start read
ButtonScan:
Path := LV_GetArray()
Gui, Destroy
TotalFiles := GetTotalJPG(Path)
Gui, New,, % ProgramTitle . " - Scanning"
Gui, Margin, 10, 10
Gui, Add, Text, w500 vCurrentProcess
Gui, Add, Progress, % "w500 h20 vProgress Range0-" . TotalFiles, 0
Gui, Show

CheckFile(file_path){
    FileRead, data, *c %file_path%
    Loop, 1000 ; set max read bytes to save performance if fails to find 'ICC_PROFILE'
    {
        if (StrGet(&data + int2hex(A_Index), 11, "UTF-8") == "ICC_PROFILE"){
            return [file_path, A_Index+10]
        }
    }
    return ""
}

for i,c in Path
{
    if (InStr(FileExist(c), "D")){
        Loop, Files, % c . "\*.*", FR
        {
            if (GetExt(A_LoopFileFullPath) in JPGExts){
                GuiControl, Text, CurrentProcess, % "Reading - " . GetFilename(A_LoopFileFullPath)
                GuiControl, , Progress, +1
    
                fileFound := CheckFile(A_LoopFileFullPath)
                (fileFound != "") ? TargetedFiles.Push(fileFound) : ""
            }
        }
    }Else{
        if (GetExt(c) in JPGExts){
            GuiControl, Text, CurrentProcess, % "Reading - " . GetFilename(c)
            GuiControl, , Progress, +1

            fileFound := CheckFile(c)
            (fileFound != "") ? TargetedFiles.Push(fileFound) : ""
        }
    }
}
; check list conformation
Gui, Destroy
Gui, New, +HwndgHWND, % ProgramTitle
Gui, Margin, 5, 5
Gui, Add, Text, w650 h20 Center, Select which file you want to convert:
Gui, Add, ListView, w650 h200 Checked vListView, Path|Address
Gui, Add, Checkbox, x10 y235 w225 h20 vCheckAll gCheckAll, Check All
Gui, Add, Button, x275 y235 w100 h20, Start
for i,c in TargetedFiles
    LV_Add("+Check", c[1], int2hex(c[2]))
LV_ModifyCol()
LV_ModifyCol(2, 120)
Gui, Show
WinActive := True
Loop
{
    if (LV_GetChecked("ahk_id " gHWND).Length() == TargetedFiles.Length())
        GuiControl, , CheckAll, 1
    Else
        GuiControl, , CheckAll, 0
    Sleep % LinearInterpolation(250,1000,TargetedFiles.Length()/500)
    (!WinActive)?Break
}
Return
; Start write
ButtonStart:
WinActive := False
TargetedFiles := RemoveUnchecked(TargetedFiles, "ahk_id" . gHWND,,TotalFileSkip)
Gui, Destroy
Gui, New,, % ProgramTitle . " - Working"
Gui, Margin, 10, 10
Gui, Add, Text, w500 vCurrentProcess
Gui, Add, Progress, % "w500 h20 vProgress Range0-" . TargetedFiles.Length(), 0
Gui, Add, Text, w500 vCredit cAAAAAA, program by ZIGATRONZ
Gui, Show
for i,c in TargetedFiles
{
    GuiControl, Text, CurrentProcess, % c[1]
    GuiControl, , Progress, +1
    Write := BinWrite(c[1], "58", 1, c[2])
    if (Write != 1)
        FilesWriteFailed.Push(c)
}
; Result
GuiControl, Text, CurrentProcess, % "Complete!"
MsgBox, 64, % ProgramTitle . " - Result", % "Program Complete!`n`nTotal JPG Converted: " . TargetedFiles.Length() . "`nTotal JPG Skipped: " . TotalFileSkip . "`nTotal JPG Ignored: " . (TotalFiles - TargetedFiles.Length() - TotalFileSkip) . "`nTotal Failed: " . FilesWriteFailed.Length()
Gui, Destroy
if (FilesWriteFailed.Length() > 0)
    FileAppend, % ArrayToList(FilesWriteFailed, "Unable to write: ", " at index :"), %ProgramTitle% - Convert Error.log

GuiEscape:
GuiClose:
ExitApp

;Drag and drop
GuiDropFiles:
    Loop, Parse, A_GuiEvent, `n
    {
        if (InStr(FileExist(A_LoopField), "D")){
            LV_Add(, A_LoopField)
        }Else{
            LV_Add(, A_LoopField)
        }
    }
Return

GuiContextMenu:
if (A_GuiControl != "ListView")
    Return
SelectedRow := A_EventInfo
Menu, PopRow, Show, %A_GuiX%, %A_GuiY%
Return

PopRow:
    Loop
    {
        if (Pos:=LV_GetNext(0))
            LV_Delete(Pos)
        Else
            Break
    }
Return

;functions

RemoveUnchecked(FileList, WinTitle, ClassNN:="SysListView321", ByRef TotalSkip:=0){
    local Pos:=1, out:=[], breakOnNoJob:=0
    ControlGet, LV_Items, List,, % ClassNN, % WinTitle
    While Pos
    {
        Pos := RegExMatch(LV_Items, "`am)(^.*?$)", Line, Pos + StrLen(Line))
        SendMessage, 0x102c, A_Index-1, 0x2000, % ClassNN, % WinTitle
        ErrorLevel?out.Push([SubStr(Line, 1, InStr(Line, A_Tab)-1), FileList[A_Index][2]])
        (Pos == 1)?breakOnNoJob ++
        (breakOnNoJob>=10)?Pos:=0
    }
    TotalSkip := FileList.Length() - out.Length()
    Return out
}

LV_GetChecked(WinTitle, ClassNN:="SysListView321"){
    local Pos:=1, Item:=[]
    ControlGet, LV_Items, List,, % ClassNN, % WinTitle
    While Pos
    {
        Pos := RegExMatch(LV_Items, "`am)(^.*?$)", Line, Pos + StrLen(Line))
        SendMessage, 0x102c, A_Index-1, 0x2000, % ClassNN, % WinTitle
        ErrorLevel?Item.Push(SubStr(Line, 1, InStr(Line, A_Tab)-1))
    }
    Return Item
}

LV_GetArray(){
    out := []
    Loop
    {
        if (LV_GetText(Text, A_Index, 1)){
            out.Push(Text)
        }Else{
            Break
        }
    }
    Return out
}

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

LinearInterpolation(a,b,t){
    Return a+(b-a)*t
}

CheckAll:
    GuiControlGet, CheckBoxAll, , CheckAll
    if (CheckBoxAll)
        Loop, % LV_GetCount()
            LV_Modify(A_Index, "+Check")
    Else
        Loop, % LV_GetCount()
            LV_Modify(A_Index, "-Check")
Return

GetFilename(path){
    SplitPath, path, out
    Return out
}

GetExt(path){
    SplitPath, path, , , out
    StringLower, out, out
    Return out
}

GetTotalJPG(Arr){
    global JPGExts
    count := 0
    for i,c in Arr
    {
        if (InStr(FileExist(c), "D")){
            Loop, Files, % c . "\*.*", FR
            {
                if (GetExt(A_LoopFileFullPath) in JPGExts){
                    count ++
                }
            }
        }Else{
            if (GetExt(c) in JPGExts){
                count ++
            }
        }
    }
    Return count
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
