Attribute VB_Name = "modDatabase"

' Copyright (c) 2007-2008 Elysium Source. All rights reserved.
' This code is licensed under the Elysium General License.

Option Explicit
Public Const MAX_PATH As Long = 260
Private Const ERROR_NO_MORE_FILES = 18
Private Const FILE_ATTRIBUTE_DIRECTORY = &H10
Private Const FILE_ATTRIBUTE_NORMAL = &H80
Private Const FILE_ATTRIBUTE_HIDDEN = &H2
Private Const FILE_ATTRIBUTE_SYSTEM = &H4
Private Const FILE_ATTRIBUTE_TEMPORARY = &H100

Private Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type
Private Type WIN32_FIND_DATA
    dwFileAttributes As Long
    ftCreationTime As FILETIME
    ftLastAccessTime As FILETIME
    ftLastWriteTime As FILETIME
    nFileSizeHigh As Long
    nFileSizeLow As Long
    dwReserved0 As Long
    dwReserved1 As Long
    cFileName As String * MAX_PATH
    cAlternate As String * 14
End Type

Private Declare Function FindFirstFile Lib "kernel32" Alias "FindFirstFileA" (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function FindClose Lib "kernel32" (ByVal hFindFile As Long) As Long
Private Declare Function FindNextFile Lib "kernel32" Alias "FindNextFileA" (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long

Public Declare Function WritePrivateProfileString& Lib "kernel32" Alias "WritePrivateProfileStringA" (ByVal AppName$, ByVal KeyName$, ByVal keydefault$, ByVal Filename$)
Public Declare Function GetPrivateProfileString& Lib "kernel32" Alias "GetPrivateProfileStringA" (ByVal AppName$, ByVal KeyName$, ByVal keydefault$, ByVal ReturnedString$, ByVal RSSize&, ByVal Filename$)

Public SOffsetX As Integer
Public SOffsetY As Integer

Function GetVar(File As String, Header As String, Var As String) As String
Dim sSpaces As String   ' Max string length
Dim szReturn As String  ' Return default value if not found
  
    szReturn = vbNullString
  
    sSpaces = Space(5000)
  
    Call GetPrivateProfileString(Header, Var, szReturn, sSpaces, Len(sSpaces), File)
  
    GetVar = RTrim$(sSpaces)
    GetVar = Left(GetVar, Len(GetVar) - 1)
End Function

Public Function ExistVar(File As String, Header As String, Var As String) As Boolean

    ExistVar = (GetVar(File, Header, Var) <> "")

End Function

Sub PutVar(File As String, Header As String, Var As String, Value As String)
    If Trim$(Value) = "0" Or Trim$(Value) = vbNullString Then
        If ExistVar(File, Header, Var) Then
            Call DelVar(File, Header, Var)
        End If
    Else
        Call WritePrivateProfileString(Header, Var, Value, File)
    End If
End Sub

Public Sub DelVar(sFileName As String, sSection As String, sKey As String)

   If Len(Trim$(sKey)) <> 0 Then
      WritePrivateProfileString sSection, sKey, _
         vbNullString, sFileName
   Else
      WritePrivateProfileString _
         sSection, sKey, vbNullString, sFileName
   End If
End Sub

Function StripTerminator(ByVal strString As String) As String
    Dim intZeroPos As Integer
    intZeroPos = InStr(strString, Chr$(0))
    If intZeroPos > 0 Then
        StripTerminator = Left$(strString, intZeroPos - 1)
    Else
        StripTerminator = strString
    End If
End Function

Function FileExist(ByVal Filename As String) As Boolean
    If Dir(App.Path & "\" & Filename) = vbNullString Then
        FileExist = False
    Else
        FileExist = True
    End If
End Function

Function ScreenFileExist(ByVal Filename As String) As Boolean
    If Dir(App.Path & "\Screenshots\" & Filename) = "" Then
        ScreenFileExist = False
    Else
        ScreenFileExist = True
    End If
End Function

Sub AddLog(ByVal Text As String)
Dim Filename As String
Dim f As Long

    'If Trim$(Command) = "-debug" Then
    If GoDebug = YES Then
        If frmDebug.Visible = False Then
            frmDebug.Visible = True
        End If
        
        Filename = App.Path & "\debug.txt"
    
        If Not FileExist("debug.txt") Then
            f = FreeFile
            Open Filename For Output As #f
            Close #f
        End If
    
        f = FreeFile
        Open Filename For Append As #f
            Print #f, Time & ": " & Text
        Close #f
    End If
End Sub

Sub SaveLocalMap(ByVal MapNum As Long)
Dim Filename As String
Dim f As Long

    Filename = App.Path & "\maps\map" & MapNum & ".dat"
                            
    f = FreeFile
    Open Filename For Binary As #f
        Put #f, , Map(MapNum)
    Close #f
End Sub

Sub LoadMap(ByVal MapNum As Long)
Dim Filename As String
Dim f As Long

    Filename = App.Path & "\maps\map" & MapNum & ".dat"
        
    If FileExist("maps\map" & MapNum & ".dat") = False Then Exit Sub
    f = FreeFile
    Open Filename For Binary As #f
        Get #f, , Map(MapNum)
    Close #f

End Sub

Function GetMapRevision(ByVal MapNum As Long) As Long
    GetMapRevision = Map(MapNum).Revision
End Function

Function ListMusic(ByVal sStartDir As String)
    Dim lpFindFileData As WIN32_FIND_DATA, lFileHdl  As Long
    Dim sTemp As String, sTemp2 As String, lRet As Long, iLastIndex  As Integer
    Dim strPath As String
    
    On Error Resume Next
    
    If Right$(sStartDir, 1) <> "\" Then sStartDir = sStartDir & "\"
    frmMapProperties.lstMusic.Clear
    
    frmMapProperties.lstMusic.AddItem "None", 0
    
    sStartDir = sStartDir & "*.*"
    
    lFileHdl = FindFirstFile(sStartDir, lpFindFileData)
    
    If lFileHdl <> -1 Then
        Do Until lRet = ERROR_NO_MORE_FILES
                strPath = Left$(sStartDir, Len(sStartDir) - 4) & "\"
                    If (lpFindFileData.dwFileAttributes And FILE_ATTRIBUTE_NORMAL) = vbNormal Then
                        sTemp = StrConv(StripTerminator(lpFindFileData.cFileName), vbProperCase)
                        If Right$(sTemp, 4) = ".mid" Then
                            frmMapProperties.lstMusic.AddItem sTemp
                        End If
                    End If
                lRet = FindNextFile(lFileHdl, lpFindFileData)
            If lRet = 0 Then Exit Do
        Loop
    End If
    lRet = FindClose(lFileHdl)
End Function

Function ListSounds(ByVal sStartDir As String, ByVal Form As Long)
    Dim lpFindFileData As WIN32_FIND_DATA, lFileHdl  As Long
    Dim sTemp As String, sTemp2 As String, lRet As Long, iLastIndex  As Integer
    Dim strPath As String
    
    On Error Resume Next
    
    If Right$(sStartDir, 1) <> "\" Then sStartDir = sStartDir & "\"
    If Form = 1 Then
        frmSound.lstSound.Clear
    ElseIf Form = 2 Then
        frmNotice.lstSound.Clear
    ElseIf Form = 3 Then
        frmEmoticonEditor.lstSound.Clear
    End If
    
    sStartDir = sStartDir & "*.*"
    
    lFileHdl = FindFirstFile(sStartDir, lpFindFileData)
    
    If lFileHdl <> -1 Then
        Do Until lRet = ERROR_NO_MORE_FILES
            strPath = Left$(sStartDir, Len(sStartDir) - 4) & "\"
                If (lpFindFileData.dwFileAttributes And FILE_ATTRIBUTE_NORMAL) = vbNormal Then
                    sTemp = StrConv(StripTerminator(lpFindFileData.cFileName), vbProperCase)
                    If Right$(sTemp, 4) = ".wav" Then
                        If Form = 1 Then
                            frmSound.lstSound.AddItem sTemp
                        ElseIf Form = 2 Then
                            frmNotice.lstSound.AddItem sTemp
                        ElseIf Form = 3 Then
                            frmEmoticonEditor.lstSound.AddItem sTemp
                        End If
                    End If
                End If
                lRet = FindNextFile(lFileHdl, lpFindFileData)
            If lRet = 0 Then Exit Do
        Loop
    End If
    lRet = FindClose(lFileHdl)
End Function

Sub MovePicture(PB As PictureBox, Button As Integer, Shift As Integer, x As Single, y As Single)
    If Button = 1 Then
        PB.Left = PB.Left + x - SOffsetX
        PB.Top = PB.Top + y - SOffsetY
    End If
End Sub
