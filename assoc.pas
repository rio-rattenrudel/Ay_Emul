{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit assoc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, ShlObj;

procedure RegApp(PerUser:boolean;const AppExePath,Paths,DefaultIcon,FriendlyAppName:string;
   const SupportedTypes,Verbs:array of string);
function IsRegApp(const AppExePath:string):boolean;
procedure DelApp(PerUser:boolean;const AppExe:string);
procedure RegProgID(PerUser:boolean;ProgID:string;const Verbs:array of string);
function IsRegProgID(const ProgID:string):boolean;
procedure DelProgID(const ProgID:string);
procedure RegFileExts(PerUser:boolean;const FileExts:array of string);
function IsRegFileExt(const FileExt,ProgID:string):boolean;
procedure AssocChanged;

implementation

function SHDeleteKeyW(key:HKEY;SubKey:PWideChar):integer;stdcall;external 'shlwapi.dll';

const
  HKEY_NO = HKEY(-1);
  RootKeys:array[Boolean] of HKEY = (HKEY_LOCAL_MACHINE,HKEY_CURRENT_USER);
  ClassesPath = 'Software\Classes\';
  AppPaths = 'Software\Microsoft\Windows\CurrentVersion\App Paths\';

var
  RegRootKey:HKEY = HKEY_CURRENT_USER;
  RegOpenedKey:HKEY = HKEY_NO;

type
 ERegistryError = class(Exception);

procedure RegRaiseError(Res:integer);
var
 Strg:PWideChar;
begin
if Res <> ERROR_SUCCESS then
 begin
  FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER,
                nil,Res,0,@Strg,0,nil);
  try
   raise ERegistryError.Create(UTF8Encode(WideString(Strg)));
  finally
   LocalFree({%H-}HLOCAL(Strg));
  end;
 end;
end;

procedure RegClose;
begin
if RegOpenedKey = HKEY_NO then exit;
RegCloseKey(RegOpenedKey);
RegOpenedKey := HKEY_NO;
end;

procedure RegOpenKey(const SubKeyName:string;ReadOnly:boolean = False);
begin
RegClose;
if ReadOnly then
 RegRaiseError(RegOpenKeyExW(RegRootKey,PWideChar(UTF8Decode(SubKeyName)),
                REG_OPTION_NON_VOLATILE,KEY_READ,RegOpenedKey))
else
 RegRaiseError(RegCreateKeyExW(RegRootKey,PWideChar(UTF8Decode(SubKeyName)),0,nil,
                REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,nil,RegOpenedKey,nil));
end;

procedure RegWriteString(const ValueName,Value:string;SType:DWORD=REG_SZ);
var
 wV:PWideChar;
begin
if RegOpenedKey = HKEY_NO then exit;
wV := PWideChar(UTF8Decode(Value));
RegRaiseError(RegSetValueExW(RegOpenedKey,PWideChar(UTF8Decode(ValueName)),0,
                SType,wV,Length(wV)*SizeOf(widechar)));
end;

procedure RegWriteExpandString(const ValueName,Value:string);
begin
RegWriteString(ValueName,Value,REG_EXPAND_SZ);
end;

procedure RegReadString(const ValueName:string;var Value:string);
var
 l:DWORD;
 RStr:PChar;
 wV:PWideChar;
begin
Value := '';
if RegOpenedKey = HKEY_NO then exit;
wV := PWideChar(UTF8Decode(ValueName));
if RegQueryValueExW(RegOpenedKey,wV,nil,nil,nil,@l)
    <> ERROR_SUCCESS then exit;
GetMem(RStr,l+2); RStr[l] := #0; RStr[l+1] := #0;
try
  RegRaiseError(RegQueryValueExW(RegOpenedKey,wV,nil,nil,PByte(RStr),@l));
  Value := UTF8Encode(WideString(PWideChar(RStr)));
finally
  FreeMem(RStr);
end;
end;

procedure NextStr(var sout,sin:string);
var
  l:integer;
begin
 l := Pos(#0,sin);
 if l = 0 then
  begin
   sout := sin;
   sin := '';
  end
 else
  begin
   sout := Copy(sin,1,l-1);
   sin := Copy(sin,l+1,Length(sin)-l);
  end;
end;

procedure SaveVerbs(Root:string;const Verbs:array of string);
var
  Verb,s,v:string;
  i:integer;
begin
Root := Root+'\shell\';
for i := 0 to Length(Verbs) - 1 do
 begin
   s := Verbs[i];
   NextStr(Verb,s);
   NextStr(v,s);
   if v <> '' then
    begin
     RegOpenKey(Root+Verb);
     RegWriteString('',v);
    end;
   NextStr(v,s);
   RegOpenKey(Root+Verb+'\command');
   RegWriteString('',v);
   NextStr(v,s);
   if v <> '' then
     begin
      RegOpenKey(Root+Verb+'\ddeexec');
      RegWriteString('',v);
      NextStr(v,s);
      RegOpenKey(Root+Verb+'\ddeexec\Application');
      RegWriteString('',v);
     end;
 end;
end;

procedure RegApp(PerUser:boolean;const AppExePath,Paths,DefaultIcon,FriendlyAppName:string;
   const SupportedTypes,Verbs:array of string);
var
  AppExe,CurPath:string;
  i,l:integer;
begin
AppExe := ExtractFileName(AppExePath);
if AppExe = '' then exit;
RegRootKey := RootKeys[PerUser];
RegOpenKey(AppPaths+AppExe);
try
  RegWriteString('',AppExePath);
  if Paths <> '' then
   RegWriteString('Path',Paths); //from Win7 can be expand string
  CurPath := 'Software\Classes\Applications\'+AppExe;
  RegOpenKey(CurPath);
  if FriendlyAppName <> '' then
   RegWriteString('FriendlyAppName',FriendlyAppName);
  if DefaultIcon <> '' then
   begin
    RegOpenKey(CurPath+'\DefaultIcon');
    RegWriteExpandString('',DefaultIcon);
   end;
  l := Length(SupportedTypes);
  if l <> 0 then
   begin
    RegOpenKey(CurPath+'\SupportedTypes');
    for i := 0 to l - 1 do
     RegWriteString(LowerCase(SupportedTypes[i]),'');
   end;
  SaveVerbs(CurPath,Verbs);
finally
  RegClose;
end;
end;

function IsRegApp(const AppExePath:string):boolean;
var
  AppExe:string;
begin
AppExe := ExtractFileName(AppExePath);
Result := AppExe <> ''; if not Result then exit;
RegRootKey := HKEY_CURRENT_USER;
try
  RegOpenKey(AppPaths+AppExe,True);
except
  Result := False;
end;
if not Result then
 begin
  Result := True;
  RegRootKey := HKEY_LOCAL_MACHINE;
  try
    RegOpenKey(AppPaths+AppExe,True);
  except
    Result := False;
  end;
 end;
if not Result then exit;
try
  Result := False;
  RegReadString('',AppExe);
  Result := AppExe = AppExePath;
finally
  RegClose;
end;
end;

procedure DelApp(PerUser:boolean;const AppExe:string);
var
  Res1,Res2,Res3:integer;
begin
if AppExe = '' then exit;
Res1 := SHDeleteKeyW(HKEY_CLASSES_ROOT,PWideChar(UTF8Decode('Applications\'+AppExe))); //Current User
if Res1 = ERROR_SUCCESS then
 Res1 := SHDeleteKeyW(HKEY_CLASSES_ROOT,PWideChar(UTF8Decode('Applications\'+AppExe))); //All Users
Res2 := SHDeleteKeyW(HKEY_CURRENT_USER,PWideChar(UTF8Decode(AppPaths+AppExe))); //Current User
Res3 := SHDeleteKeyW(HKEY_LOCAL_MACHINE,PWideChar(UTF8Decode(AppPaths+AppExe))); //All Users
if not (Res1 in [ERROR_SUCCESS,ERROR_FILE_NOT_FOUND]) then
 RegRaiseError(Res1);
if not (Res2 in [ERROR_SUCCESS,ERROR_FILE_NOT_FOUND]) then
 RegRaiseError(Res2);
if not (Res3 in [ERROR_SUCCESS,ERROR_FILE_NOT_FOUND]) then
 RegRaiseError(Res3);
end;

procedure RegProgID(PerUser:boolean;ProgID:string;const Verbs:array of string);
var
  ProgIDn,v:string;
begin
RegRootKey := RootKeys[PerUser];
NextStr(ProgIDn,ProgID);
RegOpenKey(ClassesPath+ProgIDn);
try
  NextStr(v,ProgID);
  if v <> '' then
   RegWriteString('',v);
  NextStr(v,ProgID);
  if v <> '' then
   begin
    RegOpenKey(ClassesPath+ProgIDn+'\DefaultIcon');
    RegWriteExpandString('',v);
   end;
  SaveVerbs(ClassesPath+ProgIDn,Verbs);
finally
  RegClose;
end;
end;

function IsRegProgID(const ProgID:string):boolean;
begin
Result := True;
RegRootKey := HKEY_CLASSES_ROOT;
try
  RegOpenKey(ProgID,True);
except
  Result := False;
end;
RegClose;
end;

procedure DelProgID(const ProgID:string);
var
  Res:integer;
begin
if ProgID = '' then exit;
Res := SHDeleteKeyW(HKEY_CLASSES_ROOT,PWideChar(UTF8Decode(ProgID))); //Current User
if Res = ERROR_FILE_NOT_FOUND then exit;
RegRaiseError(Res);
Res := SHDeleteKeyW(HKEY_CLASSES_ROOT,PWideChar(UTF8Decode(ProgID))); //All Users
if Res in [ERROR_SUCCESS,ERROR_FILE_NOT_FOUND] then exit;
RegRaiseError(Res);
end;

procedure RegFileExts(PerUser:boolean;const FileExts:array of string);
var
  i:integer;
  v,s,prev,prevglb:string;
  dodefault:boolean;
begin
try
  for i := 0 to Length(FileExts)-1 do
   begin
    s := FileExts[i];
    NextStr(v,s); dodefault := v = '1';
    NextStr(v,s); v := LowerCase(v);

    prevglb := '';
    if PerUser then //read also global assoc
     begin
      RegRootKey := HKEY_LOCAL_MACHINE;
      try
       RegOpenKey(ClassesPath+v,True);
       RegReadString('',prevglb);
      except
       prevglb := '';
      end;
     end;

    RegRootKey := RootKeys[PerUser];
    RegOpenKey(ClassesPath+v);
    if s = '' then continue;
    RegReadString('',prev);
    if dodefault and (prev <> s) then
     RegWriteString('',s);
    RegOpenKey(ClassesPath+v+'\OpenWithProgIds');
    if (prev <> '') and (prev <> s) then
     RegWriteString(prev,'');
    if (prevglb <> '') and (prevglb <> s) and (prevglb <> prev) then
     RegWriteString(prevglb,'');
    RegWriteString(s,'');
   end;
finally
  RegClose;
end;
end;

function IfWin8orGreater:boolean;
var
  vmaj,vmin:DWORD;
begin
vmaj := GetVersion;
vmin := HIBYTE(LOWORD(vmaj));
vmaj := LOBYTE(LOWORD(vmaj));
Result := ((vmaj = 6) and (vmin >= 2)) or (vmaj > 6);
end;

function IsRegFileExt(const FileExt,ProgID:string):boolean;
var
  v:string;
begin
Result := (FileExt <> '') and (ProgID <> '');
if not Result then exit;
RegRootKey := HKEY_CLASSES_ROOT;
try
  RegOpenKey(LowerCase(FileExt),True);
  RegReadString('',v);
  Result := v = ProgID;
  if not Result and IfWin8orGreater then
   begin
    Result := True;
    RegOpenKey(LowerCase(FileExt)+'\OpenWithProgIds',True);
    RegReadString(ProgID,v);
   end;
except
  Result := False;
end;
RegClose;
end;

procedure AssocChanged;
begin
SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
end;

end.

