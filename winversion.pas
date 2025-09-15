{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit WinVersion;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Dialogs, LCLIntf, LCLType, lazutf8,
 {$IFDEF Windows}
 Windows,
 {$ENDIF Windows}
 Types, simpleipc, process;

const
 //Version related constants
 VersionString = '3.0';
 VersionMajor = 3;
 VersionMinor = 0;
 CompilYs = '2025';
 CompilY = 2025;
 CompilM = 02;
 CompilD = 28;
 {$ifdef beta}
 BetaNumber = 'beta 2';
 {$endif beta}
 IPCServerName = 'Ay_Emul ' + VersionString
   {$ifdef beta}+ ' ' + BetaNumber{$endif beta} + ' IPC';
 {$IFDEF Windows}
 DdeServiceName = 'Ay_Emul ' + VersionString
   {$ifdef beta}+ ' ' + BetaNumber{$endif beta} + ' DDE';
 {$ENDIF Windows}

var
 IPCServer: TSimpleIPCServer;

function GetCommandLine: string;
function FileIsURL(FileName: string): boolean;
function IPCSendParams: boolean;
procedure StartIPC;
procedure StopIPC;
{$IFDEF Windows}
procedure StartDDE;
procedure StopDDE;
procedure OpenInEditor;
{$ENDIF Windows}
procedure RemoveTaskbarButton;
procedure AddTaskbarButton;
procedure CheckStringFitting(handle: THandle; var s: string; w: integer);
function GetProcessFileName: string;
{$IFNDEF Windows}
  procedure NonWin;
{$ENDIF Windows}
procedure CmdExecute(const cmd: string; const pars: array of string);
{$IFDEF dbgmode}
procedure Log(const s:string);
{$ENDIF dbgmode}

implementation

uses
 MainWin,
 {$IFDEF Windows}
 PlayList;
 {$ELSE Windows}
 Languages;
 {$ENDIF Windows}

function IPCSendParams: boolean;
var
 s: string;
begin
 Result := False;
 with TSimpleIPCClient.Create(nil) do
  try
   ServerID := IPCServerName;
   if ServerRunning then
    begin
     Active := True;
     Result := True;
     s := '"' + GetCurrentDir + '" ' + GetCommandLine;
     if ParamCount = 0 then s := s + ' -vshow';
     SendStringMessage(s);
     Active := False;
    end;
  finally
   Free;
  end;
end;

type
 TMessageHook = class(TThread)
   procedure ApplyMessage;
 protected
   procedure Execute; override;
 end;

var
 MessageHook: TMessageHook;

procedure TMessageHook.ApplyMessage;
begin
 IPCServer.PeekMessage(0, True);
end;

procedure TMessageHook.Execute;
begin
 while not Terminated do
  begin
   if IPCServer.Active then
     Synchronize(@ApplyMessage);
   Sleep(3);
  end;
end;

procedure StartIPC;
begin
 IPCServer := TSimpleIPCServer.Create(nil);
 IPCServer.ServerID := IPCServerName;
 IPCServer.Global := True;
 IPCServer.StartServer;
 MessageHook := TMessageHook.Create(False);
end;

procedure StopIPC;
begin
 MessageHook.Terminate;
 MessageHook.WaitFor;
 MessageHook.Free;
 IPCServer.Free;
end;

{$IFDEF Windows}
var
 DdeInst: integer;

function hsz2Str(Ahsz: HSZ): string;
var
 L: integer;
begin
 Result := '';
 if Ahsz = 0 then exit;
 L := DdeQueryString(DdeInst, Ahsz, nil, 0, CP_WINANSI);
 if L <= 0 then exit;
 SetLength(Result, L);
 DdeQueryString(DdeInst, Ahsz, PChar(Result), L + 1, CP_WINANSI);
end;

function hDdeData2Str(AData: HDDEData): string;
var
 L: integer;
begin
 Result := '';
 if AData = 0 then exit;
 L := DdeGetData(AData, nil, 0, 0);
 if L <= 0 then exit;
 SetLength(Result, L);
 DdeGetData(AData, pbyte(PChar(Result)), L, 0);
 Result := UTF8Encode(WideString(pwidechar(Result)));
end;

function DdeFunc(CallType, Fmt: UINT; Conv: HConv; hsz1, hsz2: HSZ;
 Data: HDDEData; Data1, Data2: DWORD): HDDEData stdcall;
const
 SZDDESYS_TOPIC = 'System';
begin
 Result := 0;
 case CallType of
   XTYP_CONNECT: begin
     if SameText(hsz2Str(hsz1), SZDDESYS_TOPIC) and
       SameText(hsz2Str(hsz2), DdeServiceName) then
      begin
       Result := 1;
      end;
    end;
   XTYP_EXECUTE: begin
     if SameText(hsz2Str(hsz1), SZDDESYS_TOPIC) then
      begin
       SetCommandLine('"' + GetCurrentDir + '" Ay_Emul.exe ' + hDdeData2Str(Data));
       Result := DDE_FACK;
      end;
    end;
  end;
end;

procedure StartDDE;
const
 CBF_SKIP_ALLNOTIFICATIONS = $003c0000;
begin
 DdeInitializeW(@DdeInst, @DdeFunc, APPCLASS_STANDARD or CBF_SKIP_ALLNOTIFICATIONS, 0);
 DdeNameService(DdeInst, DdeCreateStringHandle(DdeInst, DdeServiceName, CP_WINANSI),
   0, DNS_REGISTER);
end;

procedure StopDDE;
begin
 DdeUninitialize(DdeInst);
end;

{$ENDIF Windows}

function FileIsURL(FileName: string): boolean;
const
 nprotos = 2;
 protos: array[0..nprotos] of string =
   ('http://', 'https://', 'ftp://');
var
 i: integer;
begin
 FileName := LowerCase(FileName);
 for i := 0 to nprotos do
   if (Pos(protos[i], FileName) = 1) then
    Exit(True);
 Result := False;
end;

function GetCommandLine: string;
 {$IFDEF Windows}
begin
 Result := UTF8Encode(WideString(GetCommandLineW));
 {$ELSE Windows}
var
 i:integer;
begin
Result := '"' + ParamStr(0) + '"';
for i := 1 to ParamCount do
 Result := Result + ' "' + ParamStr(i) + '"';
 {$ENDIF Windows}
end;

procedure CmdExecute(const cmd: string; const pars: array of string);
var
 i: integer;
begin
 with TProcess.Create(nil) do
  try
   Executable := cmd;
   for i := 0 to Length(pars) - 1 do
     Parameters.Add(pars[i]);
   Options := [poWaitonexit];
   Execute;
  finally
   Free;
  end;
end;

{$IFDEF Windows}

procedure OpenInEditor;
var
 SI: STARTUPINFOW;
 PI: PROCESS_INFORMATION;
 FN: array of string;
 s: string;
 i, n, z: integer;

 procedure ClearSaved;
 var
   j: integer;
 begin
   for j := n - 1 downto 0 do
     if (FN[j] <> '') and FileExists(FN[j]) then
       SysUtils.DeleteFile(FN[j]);
 end;

begin
 n := 0;
 z := 0;
 s := '';
 for i := 0 to Length(PlaylistItems) - 1 do
   if PlayListItems[i]^.Selected then
    begin
     Inc(n);
     SetLength(FN, n);
     if not FrmPLst.SaveFile(i, True, FN[n - 1]) then
      begin
       ClearSaved;
       Exit;
      end;
     if FN[n - 1] <> '' then
      begin
       Inc(z);
       s += ' "' + FN[n - 1] + '"';
      end;
    end;
 if z = 0 then
   Exit;
 FillChar(SI, sizeof(SI), 0);
 SI.cb := sizeof(SI);
 if not CreateProcessW(pwidechar(UTF8Decode(VTPath)), pwidechar(UTF8Decode(VTPath + s)),
   nil, nil, False, 0, nil, pwidechar(UTF8Decode(ExtractFileDir(VTPath))), SI, PI) then
  begin //todo: удалять временные файлы по завершению процесса?
    try
     RaiseLastOSError;
    finally
     ClearSaved;
    end;
  end;
end;

{$ENDIF Windows}

procedure CheckStringFitting(handle: THandle; var s: string; w: integer);
var
 sz: TSize;
 len, nch: integer;
begin
 len := Length(s); //в байтах - вроде фича LCL, а не баг
 if not LCLIntf.GetTextExtentExPoint(handle, PChar(s), len, w, @nch, nil, Sz) then
  Exit;
 len := UTF8Length(s);
 if nch < len then s := UTF8Copy(s, 1, nch - 3) + '...';
end;

function GetProcessFileName: string;
begin
 Result := ParamStr(0);
end;

{$IFDEF Windows}
procedure Set_WS_EXSTYLE(h: THandle; WS: DWORD);
begin
 ShowWindow(h, SW_HIDE);
 SetWindowLong(h, GWL_EXSTYLE, WS);
 ShowWindow(h, SW_SHOWNA);
end;
{$ENDIF Windows}

procedure RemoveTaskbarButton;
{$IFDEF Windows}
var
 h: THandle;
 {$ENDIF Windows}
begin
 {$IFDEF Windows}
 h := GetParent(FrmMain.Handle);
 Set_WS_EXSTYLE(h, GetWindowLong(h, GWL_EXSTYLE) and not WS_EX_APPWINDOW or
   WS_EX_TOOLWINDOW);
 {$ENDIF Windows}
 //no need in Linux cause of tray icon can be either simplier behaviour,
 //or not shown at all
end;

procedure AddTaskbarButton;
{$IFDEF Windows}
var
 h: THandle;
 {$ENDIF Windows}
begin
 {$IFDEF Windows}
 h := GetParent(FrmMain.Handle);
 Set_WS_EXSTYLE(h, GetWindowLong(h, GWL_EXSTYLE) and not WS_EX_TOOLWINDOW or
   WS_EX_APPWINDOW);
 {$ENDIF Windows}
 //no need in Linux cause of tray icon can be either simplier behaviour,
 //or not shown at all
end;

{$IFNDEF Windows}
procedure NonWin;
begin
 MessageDlg(Mes_WinVersion,mtInformation,[mbOk],0);
end;
{$ENDIF Windows}

{$IFDEF dbgmode}
procedure Log(const s:string);
var
 f:Text;
begin
 Assign(f,ParamStr(0)+'.log');
 if FileExists(ParamStr(0)+'.log') then
  Append(f)
 else
  Rewrite(f);
 Writeln(f,DateTimeToStr(Now,True) + ' ' + s);
 Close(f);
end;
{$ENDIF}

end.
