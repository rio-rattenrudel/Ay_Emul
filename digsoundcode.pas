{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit digsoundcode;

{$mode objfpc}{$H+}

interface

uses
  Classes, LCLIntf, LCLType, digsound, SysUtils, Forms;

const
 digsoundDeviceDef = 0;

var
 digsoundDevice:integer;
procedure digsoundthread_start;
procedure digsoundthread_stop;
procedure digsoundthread_free;
function digsoundthread_active:boolean;
procedure digsoundloop_catch;
procedure digsoundloop_release;
procedure digsound_pauseswitch;
procedure digsoundVisualisation;

implementation

uses
  MainWin, Players, AY, settings;

type
 TThread1 = class(TThread)
     protected
       procedure Execute; override;
     end;

var
 digsound_thread:TThread1 = nil;
 digsoundloop_break:integer;
 digsoundloop_csection:TCriticalSection;
 digsoundcall_csection:TCriticalSection;

procedure DSCheck(Res:integer);
var
 ErrMsg:string;
begin
if Res > 0 then
 begin
  EnterCriticalSection(digsoundcall_csection);
  try
   ErrMsg := digsound_geterrortext(Res);
  finally
   LeaveCriticalSection(digsoundcall_csection);
  end;
  raise EMultiMediaError.Create(ErrMsg);
 end;
end;

procedure digsoundVisualisation;
var
 Res:integer;
 s:int64;
begin
if not digsoundthread_active or Paused then
 Exit;
EnterCriticalSection(digsoundcall_csection);
try
 Res := digsound_getposition(s);
finally
 LeaveCriticalSection(digsoundcall_csection);
end;
if Res = 0 then
  AYVisualisation(s);
end;

procedure digsoundthread_stop;
begin
if digsoundthread_active then
 begin
  IsPlaying := False;
  EnterCriticalSection(digsoundcall_csection);
  try
   digsound_setevent;
  finally
   LeaveCriticalSection(digsoundcall_csection);
  end;
  digsoundthread_free;
 end;
end;

function FillBuffers:boolean;
var
 i,Res:integer;
 PBuffer:pointer;
begin
Result := False;
for i := 0 to NumberOfBuffers - 1 do
 begin
  if not IsPlaying or Paused then exit;
  if digsoundloop_break > 0 then exit;
  EnterCriticalSection(digsoundcall_csection);
  try
   Res := digsound_getbuffer(PBuffer,BufferLength);
  finally
   LeaveCriticalSection(digsoundcall_csection);
  end;
  if Res = Ord(digsound_rc_no_buffer) then exit;
  if Res = 0 then
   begin
    MakeBuffer(PBuffer);
    if not IsPlaying or Paused then exit;
    if BuffLen = 0 then
     break //todo StopPlaying
    else
     begin
      EnterCriticalSection(digsoundcall_csection);
      try
       Res := digsound_push(BuffLen);
      finally
       LeaveCriticalSection(digsoundcall_csection);
      end;
      DSCheck(Res);
     end;
    Result := True;
    if Real_End_All then exit;
   end
  else
   DSCheck(Res);
 end;
end;

procedure TThread1.Execute;
begin
try
 repeat
  EnterCriticalSection(digsoundloop_csection);
  try
   if Real_End_All and (digsoundloop_break = 0) then
    begin
     EnterCriticalSection(digsoundcall_csection);
     try
      if digsound_check = Ord(digsound_rc_done) then
       break;
     finally
      LeaveCriticalSection(digsoundcall_csection);
     end;
    end
   else
    FillBuffers;
  finally
   LeaveCriticalSection(digsoundloop_csection);
  end;
  if Terminated or not IsPlaying then break;
  digsound_waitforevent;
 until Terminated or not IsPlaying;
finally
 if IsPlaying then
              //todo передавать Handle через init?
  PostMessage(FrmMain.Handle,WM_FINALIZEWO,0,0);
end;
end;

procedure digsoundthread_start;
begin
if digsoundthread_active then exit;
DSCheck(digsound_open(digsoundDevice,NumberOfChannels,SampleRate,SampleBit,NumberOfBuffers,BufLen_ms,True));
//todo может загнать всё это в thread?
try
 try
  IsPlaying := True;
  digsoundloop_break := 0;
  Paused := False;
  if FillBuffers then
   begin
    digsound_thread := TThread1.Create(False);
    digsound_thread.Priority := tpHigher;
   end
  else
   IsPlaying := False;
 except
  IsPlaying := False;
  raise;
 end;
finally
 if not IsPlaying then
  DSCheck(digsound_close);
end;
end;

procedure digsoundthread_free;
begin
digsound_thread.Terminate;
digsound_thread.WaitFor;
digsound_thread.Free;
digsound_thread := nil;
//todo не закрывать без нужды
DSCheck(digsound_close);
IsPlaying := False;
end;

function digsoundthread_active:boolean;
begin
Result := digsound_thread <> nil;
end;

procedure digsoundloop_catch;
begin
if not IsPlaying then exit;
inc(digsoundloop_break);
if digsoundloop_break > 1 then exit;
EnterCriticalSection(digsoundloop_csection);
end;

procedure digsoundloop_release;
begin
if not IsPlaying then exit;
dec(digsoundloop_break);
if digsoundloop_break = 0 then
 LeaveCriticalSection(digsoundloop_csection);
end;

procedure digsound_pauseswitch;
var
 Res:integer;
begin
if not IsPlaying then exit;
EnterCriticalSection(digsoundcall_csection);
try
if Paused then
 begin
  Res := digsound_continue;
  if Res <= 0 then
   Paused := False;
 end
else
 begin
  Res := digsound_pause;
  if Res <= 0 then
   Paused := True;
 end;
finally
 LeaveCriticalSection(digsoundcall_csection);
end;
DSCheck(Res);
end;

initialization

InitializeCriticalSection(digsoundcall_csection);
InitializeCriticalSection(digsoundloop_csection);

finalization

DeleteCriticalSection(digsoundloop_csection);
DeleteCriticalSection(digsoundcall_csection);

end.
