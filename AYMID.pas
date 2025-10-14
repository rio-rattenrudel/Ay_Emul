{
AYMID.pas - midi sysex sendout thread
-----------------------------------------------------

Based on MSVC++ source code of TMIDI by Tom Grandgent
Based on Midi.pas source code of Sergey Bulba
Author Sergey Vladimirovich Bulba
(c)1999-2022 S.V.Bulba

AYMID is inspired by ASID interpretation by Jouni Paulus
and Vice ASID implementation by aTc

(c)2025 by rio rattenrudel
}

unit AYMID;

{$mode objfpc}{$H+}

interface

uses
  LCLIntf,Windows,MMSystem,Sysutils,StdCtrls,Classes;

var
  regs: array [0..15] of BYTE = ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, 0, 0);

  running: Boolean = false;

procedure AYMIDEnumDevices(cb:TComboBox);
procedure aymidthread_start;
procedure aymidthread_stop;
function aymidthread_active:boolean;

var
  AYMIDDevice:longword = MIDI_MAPPER;

implementation

uses
  MainWin, settings, sometypes, AY, AYMIDconsole;

const
  FALL_ASLEEP_COUNT = 10;

type
  TThread1 = class(TThread)
    private
      data: array [0..20] of BYTE;
      captured: record  // capture for aymid console
        mask: uint16;
        msb:  uint16;
        len:  byte;
      end;
      procedure ASyncConsoleOutput(mask, msb: uint16; len: byte);
      procedure PushConsole;
    protected
      procedure Execute; override;
    end;

var
  // Timing variable
  PeriodMin:longword = 1;

  AYMIDOUTH:HMIDIOUT = 0;
  aymid_thread:TThread1 = nil;
  aymidcall_csection:TCriticalSection;

  keepAwakeCC: BYTE = FALL_ASLEEP_COUNT;

procedure AYMIDEnumDevices(cb:TComboBox);
var
  outcaps: MIDIOUTCAPS;
  i: integer;

begin
  for i := 0 to integer(midiOutGetNumDevs) - 1 do
    if midiOutGetDevCaps(i, @outcaps, sizeof(outcaps)) = MMSYSERR_NOERROR then
      cb.Items.Add({AnsiTo}UTF8Encode(WideString(outcaps.szPname)))
    else
      cb.Items.Add('Unknown MIDI device');
end;

procedure output_sysex_data(init:byte;data:PArray0OfByte;length:integer);
var
  mh: MIDIHDR;
  tmp: byte;

begin
  if AYMIDOUTH = 0 then exit;

  if init = 0 then begin
    dec(PByte(data));
    tmp := data[0];
    data[0] := $F0; // Sysex begin command
    inc(length);
  end;

  // Prepare the MIDI out header
  FillChar(mh, sizeof(mh), 0);
  mh.lpData := pointer(data);
  mh.dwBufferLength := length;
  mh.dwBytesRecorded := length;
  // Prepare the sysex buffer for output
  midiOutPrepareHeader(AYMIDOUTH, @mh, sizeof(mh));

  // Send the sysex buffer!
  if midiOutLongMsg(AYMIDOUTH, @mh, sizeof(mh)) <> MIDIERR_NOTREADY then ;//break;

  // Unprepare the sysex buffer
  midiOutUnprepareHeader(AYMIDOUTH, @mh, sizeof(mh));

  if init = 0 then data[0] := tmp;
end;

procedure Sendstop;
var
  i: BYTE;
  stop: array [0..2] of BYTE = ($2E, $4D, $F7); // ident, stop cmd

begin
  output_sysex_data(0,@stop,3);
  running := false;
end;

procedure Sendout;
var
  i: BYTE;
  reg: byte;
  isModified: Boolean = false;
  dcc: byte = 0;
  mask: uint16 = 0;
  msb: uint16 = 0;
  play: array [0..2] of BYTE = ($2E, $4C, $F7); // ident, start cmd
  stop: array [0..2] of BYTE = ($2E, $4D, $F7); // ident, stop cmd

begin
  aymid_thread.data[0]:=$2E; // ident
  aymid_thread.data[1]:=$4E; // update cmd

  // init data
  if not running then begin
    for i := 0 to 13 do regs[i] := $FF;
  end;

  for i := 0 to 13 do begin
    reg := SoundChip[0].RegisterAY.Index[i];

    if reg <> regs[i] then begin  // diff reg
      regs[i] := reg;             // copy reg

      if reg > $7f then           // diff msb
        msb := msb or (1 shl i);  // set msb
      mask := mask or (1 shl i);  // set mask

      aymid_thread.data[dcc+6] := reg and $7f; // fill data

      isModified := true;
      Inc(dcc);
    end;
  end;

  if not running then begin
    running := true;
    output_sysex_data(0,@play,3);
  end;

  if isModified then begin
    aymid_thread.data[2] := mask and $7f;
    aymid_thread.data[3] := (mask shr 7) and $7f;
    aymid_thread.data[4] := msb and $7f;
    aymid_thread.data[5] := (msb shr 7) and $7f;

    if UseAYMIDConsole then begin
      // instead of raw output:
      // OutputAYMID(mask, msb, @aymid_thread.data, dcc);

      // try queue the data to main:
      aymid_thread.ASyncConsoleOutput(mask, msb, dcc);
    end;

    aymid_thread.data[dcc+6] := $F7; // end byte
    Inc(dcc);

    output_sysex_data(0,@aymid_thread.data,dcc+6);

    keepAwakeCC := FALL_ASLEEP_COUNT;
  end else if keepAwakeCC > 0 then dec(keepAwakeCC);
end;

procedure init_midi_out;
begin
  if AYMIDOUTH <> 0 then begin
    midiOutClose(AYMIDOUTH);
    AYMIDOUTH := 0;
  end;
  if midiOutOpen(@AYMIDOUTH, AYMIDDevice, 0, 0, 0) <> MMSYSERR_NOERROR then begin
    AYMIDOUTH := 0;
    raise EMultiMediaError.Create('Unable to open MIDI-out device');
  end;
end;

procedure close_midi_out;
var
  i: integer;

begin
  if AYMIDOUTH <> 0 then begin
    Sendstop;
    i := 0;
    while (midiOutClose(AYMIDOUTH) <> MMSYSERR_NOERROR) and (i < 10) do begin
      inc(i);
      Sleep(200);
    end;
    AYMIDOUTH := 0;
    if i = 10 then
      raise EMultiMediaError.Create('Unable to close MIDI-out device');
  end;
end;

procedure TThread1.Execute;
begin

  // Init MIDI-out device
  try
    init_midi_out;
  except
    ShowException(ExceptObject,ExceptAddr);
  end;
  if AYMIDOUTH = 0 then exit; //todo next play ?

  //Set max MMTimers precision
  timeBeginPeriod(PeriodMin);


  // main loop
  repeat

    // goto sleep, reduce cpu load
    if keepAwakeCC = 0 then Sleep(1);

    if not IntFlag then continue;
    Sendout;

    if Terminated then break;
  until Terminated;


  // PLAYBACK HAS STOPPED
  //Restore default MMTimers precision
  timeEndPeriod(PeriodMin);

  Sleep(50);
  try
    close_midi_out;
  except
    ShowException(ExceptObject,ExceptAddr);
  end;
end;

procedure TThread1.ASyncConsoleOutput(mask, msb: uint16; len: byte);
begin
  // capture data to queue
  captured.len  := len;
  captured.mask := mask;
  captured.msb  := msb;

  Queue(@PushConsole);
end;

procedure TThread1.PushConsole;
begin
  OutputAYMID(captured.mask, 
              captured.msb, 
              @data, // raw, no copy, minor priority
              captured.len);
end;

function aymidthread_active:boolean;
begin
  Result := aymid_thread <> nil;
end;

procedure aymidthread_free;
begin
  aymid_thread.Terminate;
  aymid_thread.WaitFor;
  aymid_thread.Free;
  aymid_thread := nil;
end;

procedure aymidthread_stop;
begin
  if aymidthread_active then begin
    aymidthread_free;
  end;
end;

procedure aymidthread_start;
begin
  if aymidthread_active then exit;

  running := false;

  aymid_thread := TThread1.Create(False);
  aymid_thread.Priority := tpTimeCritical; // let's make it time critical, midi isn't a heavy job
end;

var
  tc:TIMECAPS;

initialization

InitializeCriticalSection(aymidcall_csection);

if timeGetDevCaps(@tc, sizeof(TIMECAPS)) = TIMERR_NOERROR then begin
  if PeriodMin < tc.wPeriodMin then PeriodMin := tc.wPeriodMin;
  if PeriodMin > tc.wPeriodMax then PeriodMin := tc.wPeriodMax;
end;

finalization

DeleteCriticalSection(aymidcall_csection);

end.
