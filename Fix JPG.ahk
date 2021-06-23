
IfExist, % A_ScriptDir . "\ToFix"
{
    Loop, Files, % A_ScriptDir . "\ToFix\*.jpg", F
    {
        data := ""
        BinRead(A_LoopFileFullPath, data, 1, 0x22)
        if (data == "45"){
            BinWrite(A_LoopFileFullPath, "58", 1, 0x22)
        }
    }
    MsgBox, Program Complete!
}Else{
    FileCreateDir, % A_ScriptDir . "\ToFix"
    MsgBox, % "Put all JPG file in " . A_ScriptDir . "\ToFix folder and run this program again"
}
ExitApp

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

BinRead(file, ByRef data, n=0, offset=0){
    h := DllCall("CreateFile", "Str", file, "Uint", 0x80000000, "Uint", 3, "UInt", 0,"UInt", 3, "Uint", 0, "UInt", 0)
    IfEqual h, -1, SetEnv, ErrorLevel, -1
    IfNotEqual ErrorLevel, 0, Return, 0
    m := 0
    IfLess offset, 0, SetEnv, m, 2
    r := DllCall("SetFilePointerEx", "Uint", h, "Int64", offset, "UInt *", p, "Int", m)
    IfEqual r, 0, SetEnv, ErrorLevel, -3
    IfNotEqual ErrorLevel,0, {
        t := ErrorLevel
        DllCall("CloseHandle", "Uint", h)
        ErrorLevel := t
        Return 0
    }
    TotalRead := 0
    data := ""
    IfEqual n, 0, SetEnv n, 0xffffffff
    format := A_FormatInteger
    SetFormat Integer, Hex
    Loop % n
    {
        result := DllCall("ReadFile", "UInt", h, "UChar *", c, "UInt", 1, "UInt *", Read, "UInt", 0)
        if (!result or Read < 1 or ErrorLevel)
        Break
        TotalRead += Read
        c += 0
        StringTrimLeft c, c, 2
        c := "0" . c
        StringRight c, c, 2
        data := data . c
    }

    IfNotEqual ErrorLevel,0, SetEnv,t,%ErrorLevel%
    h := DllCall("CloseHandle", "Uint", h)
    IfEqual h,-1, SetEnv, ErrorLevel, -2
    IfNotEqual t,,SetEnv, ErrorLevel, %t%
    SetFormat Integer, %format%
    TotalRead += 0
    Return TotalRead
}