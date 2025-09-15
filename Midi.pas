{
MIDI files decoding and playing code for Win32
----------------------------------------------

Based on MSVC++ source code of TMIDI by Tom Grandgent

XMIDI file format interpretation based on source code
of The System Shock Random Generator By Cless

Rewritten on Object Pascal for Delphi 7 and
additionally bugfixed during Delphi->Free Pascal migration
by Sergey Bulba

(c)2006,2008,2016 S.V.Bulba
http://bulba.untergrund.net/
svbulba@gmail.com

This is Ay_Emul edition of rewriting and removing extra code
from original TMIDI. Only playing, seeking and visualisation
code is used. Must play all MIDI files of types from 0 to 2
(.MID and .RMI, type 2 not tested). Uses the lowest level of
Win32 Multimedia System.

Some bugs of TMIDI was fixed here also.

Can play all tracks in file (.MID (.RMI) type 0 and 1) or
selected tracks only (type 2 or .XMI)
}

unit Midi;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf,Windows,MMSystem,Sysutils,StdCtrls,Classes,sometypes;

const
 MThd = $6468544D;
 MTrk = $6B72544D;
 RIFF = $46464952;
 RMID = $44494D52;
 RIFFdata = $61746164;
 XMIFORM = $4D524F46;
 XMID = $44494D58;
 XDIR = $52494458;
 XMIINFO = $4F464E49;
 XMICAT = $20544143;
 XMIEVNT = $544E5645;
 MIDI_STANDARD_NONE =  1;
 MIDI_STANDARD_GM   =  2;
 MIDI_STANDARD_GS   =  4;
 MIDI_STANDARD_XG   =  8;
 MIDI_STANDARD_MT32 = 16;
 MAX_MIDI_WAIT   = 100.0; // Max # of milliseconds to sleep in main playback loop
 MAX_MIDI_TRACKS = 65535; // Max # of tracks Midi.pas will read from a MIDI file
 MAX_PITCH_BEND  = $2000; // Max value for pitch bends (this is a MIDI constant, do not change!)
 MAX_XMIDILOOPS = 128;    // Max number of XMIDI FOR_LOOP statements Midi.pas allows

type
 channel_state_t = record
  // State values
  changed_pitch_bend:integer;
  normal_program:integer; // Normal program used by this channel
  notes:packed array[0..127] of byte; // Current velocity for each possible note (0 is off)
  note_count:integer;     // Number of notes currently on
  note_counta:integer;    // Same, including zero volume
  xmioff:array[0..127] of double; // XMI note off time
  volume,pan:byte;        // Last volume and pan
  // Historical values
  last_bank:shortint;     // Last bank set
  last_pitch_bend:integer;// Last pitch bend set
 end;

 track_header_t = record
  length:longword;        // Length of track chunk in bytes
  data:PArray0OfByte;      // Pointer to beginning of track chunk
//  dataptr:PByteArray;     // Pointer to current location in track chunk
  current:longword;       // dataptr --> current
  track_length:longword;  // Length of track in milliseconds
  trigger:double;         // Ending time of current event
  enabled:boolean;        // Is this track enabled?
  lastcmd:byte;           // Last command byte (used in running mode)
  fstcopyrtxt,            // Possibly track author string
  fstseqtrkname,          // Possibly track sequence name
  alltexts:string;        // all meta-event's texts in track
 end;

 PMIDIParams = ^TMIDIParams;
 TMIDIParams = record
  //Load params
  file_format:smallint;   // MIDI file type (0, 1, or 2 and -1 for XMI)
  num_tracks:word;        // Number of tracks in MIDI file
  num_ticks:word;         // Number of ticks per quarter note (used to calc tempo)
  track_from,
  track_to:word;          // Tracks to play
  song_length:longword;   // Length of song in milliseconds
  midi_standard:integer;  // MIDI standard used by this MIDI file (as sysex indicates)
  found_note_on:boolean;  // Has there been a Note On event yet?
  first_note_on:double;   // Time when the first Note On event was found

  //Vars
  tempo:longword;         // Current tempo
  tick_length:double;     // Current tick length in milliseconds
  analyzing:boolean;      // Is this song currently being analyzed?
  seeking:boolean;        // Is this song currently seeking?
  seek_to:double;         // Place to seek to (in milliseconds)
  stop_requested:boolean; // Has there been a request to stop the playback thread?
  playing:boolean;        // Is the playback thread playing?
  paused:boolean;         // Is the playback thread paused?
  started:boolean;
  loop_count:integer;     // Number of times left to loop the playback
  starttime:longword;     // Starting playback time
  curtime:double;         // Current playback time
  elapsedtime:longword;
  channels:array[0..15] of channel_state_t; // Channel state structs
  loops:array [0..MAX_XMIDILOOPS-1] of record //XMIDI loop "controllers"
   count:integer;
//   dataptr:PArray0OfByte;
   current:longword;
  end;
  loop_num:integer;       //Current XMIDI loop (-1 - no loop point defined)
  th:array of track_header_t; // Track state structs
 end;

procedure MIDIEnumDevices(cb:TComboBox);
procedure load_midi(var mp:PMIDIParams;prescan_tracks:PWord;filename:string);
procedure unload_midi(mp:PMIDIParams);
procedure midithread_start;
procedure midithread_stop;
function midithread_active:boolean;
procedure MIDIVisualisation;
procedure MIDI_SetLoop;

var

 MIDIParams:PMIDIParams;

 MIDISeekToFirstNote:boolean = True;

 MIDIDevice:longword = MIDI_MAPPER;

implementation

uses
 MainWin, UniReader, settings;

type
 TThread1 = class(TThread)
     protected
       procedure Execute; override;
     end;

var
 // Timing variable
 PeriodMin:longword = 1;

 MIDIOUTH:HMIDIOUT = 0;
 midi_thread:TThread1 = nil;

procedure MIDIEnumDevices(cb:TComboBox);
var
 outcaps:MIDIOUTCAPS;
 i:integer;
begin
for i := 0 to integer(midiOutGetNumDevs) - 1 do
 if midiOutGetDevCaps(i, @outcaps, sizeof(outcaps)) = MMSYSERR_NOERROR then
  cb.Items.Add({AnsiTo}UTF8Encode(WideString(outcaps.szPname)))
 else
  cb.Items.Add('Unknown MIDI device');
end;

procedure init_midi_out;
begin
if MIDIOUTH <> 0 then
 begin
  midiOutClose(MIDIOUTH);
  MIDIOUTH := 0;
 end;
if midiOutOpen(@MIDIOUTH, MIDIDevice, 0, 0, 0) <> MMSYSERR_NOERROR then
 begin
  MIDIOUTH := 0;
  raise EMultiMediaError.Create('Unable to open MIDI-out device');
 end;
end;

procedure close_midi_out;
var
 i:integer;
begin
if MIDIOUTH <> 0 then
 begin
  midiOutReset(MIDIOUTH);
  i := 0;
  while (midiOutClose(MIDIOUTH) <> MMSYSERR_NOERROR) and (i < 10) do
   begin
    inc(i);
    Sleep(200);
   end;
  MIDIOUTH := 0;
  if i = 10 then
   raise EMultiMediaError.Create('Unable to close MIDI-out device');
 end;
end;

procedure set_tempo(mp:PMIDIParams;new_tempo:longword);
var
 old_tick_length:double;
 i,j:integer;
begin
if new_tempo = 0 then
 raise EMultiMediaError.Create('Set Tempo=0');

if new_tempo = mp^.tempo then exit;

if mp^.file_format = -1 then
 if mp^.tempo = 0 then
  mp^.num_ticks := new_tempo * 3 div 25000
 else
  exit;

mp^.tempo := new_tempo;

// Calculate new tick length
old_tick_length := mp^.tick_length;
mp^.tick_length := new_tempo / 1000 / mp^.num_ticks;

if not mp^.analyzing and (mp^.file_format = -1) then
 for i := 0 to 15 do
  if mp^.channels[i].note_counta <> 0 then
   for j := 0 to 127 do
    if mp^.channels[i].xmioff[j] >= 0 then
      mp^.channels[i].xmioff[j] := mp^.curtime + (mp^.channels[i].xmioff[j] - mp^.curtime) / old_tick_length * mp^.tick_length;

// Correct outstanding track triggers on each track
for i := mp^.track_from to mp^.track_to do
 begin
  if not mp^.th[i].enabled then continue;
  mp^.th[i].trigger := mp^.curtime + (mp^.th[i].trigger - mp^.curtime) / old_tick_length * mp^.tick_length;
 end;
end;

// Turns all notes off on a specific channel
procedure all_notes_off_channel(mp:PMIDIParams;channel:integer);
var
 j:integer;
begin
// Clear saved note velocities for this channel
FillChar(mp^.channels[channel].notes,128,0);
mp^.channels[channel].note_count := 0;
mp^.channels[channel].note_counta := 0;
// Reset XMI note off times
if mp^.file_format = -1 then
 for j := 0 to 127 do
  mp^.channels[channel].xmioff[j] := -1;
// Turn off notes on the MIDI-out device
if MIDIOUTH <> 0 then
 begin
  midiOutShortMsg(MIDIOUTH, $78B0 or channel);
  // midiOutShortMsg(MIDIOUTH, $79B0 or channel);
  // midiOutShortMsg(MIDIOUTH, $7BB0 or channel);
 end;
end;

// Turns all notes off on all channels
procedure all_notes_off(mp:PMIDIParams);
var
 c:integer;
begin
for c := 0 to 15 do
 all_notes_off_channel(mp,c);
end;

// Updates the volume for a given note on a given channel
procedure update_note_volume(mp:PMIDIParams;channel,note,volume:byte);
begin
if volume <> 0 then
 begin
  // Note on
  if mp^.channels[channel].notes[note] = 0 then
   inc(mp^.channels[channel].note_count);
 end
else
 begin
  // Note off
  if mp^.channels[channel].notes[note] <> 0 then
   dec(mp^.channels[channel].note_count);
 end;
// Store the value
mp^.channels[channel].notes[note] := volume;
end;

procedure note_on(mp:PMIDIParams;on_:boolean;note,velocity,chan:byte);
var
 dwParam1:DWORD;
 channel:byte;
begin
channel := chan;

//  if velocity > 128 then
  // MessageBox(0,PChar('velocity range error: ' + IntToStr(velocity)),'Error-warning',MB_ICONERROR);

// Update display/historic values
if on_ then
 begin
  update_note_volume(mp,channel, note and 127, velocity and 127);
  inc(mp^.channels[channel].note_counta);
 end
else
 begin
  update_note_volume(mp,channel, note and 127, 0);
  dec(mp^.channels[channel].note_counta);
  mp^.channels[channel].xmioff[note] := -1;
 end;

if MIDIOUTH <> 0  then
 begin
  // If the bank for this channel is 127, treat it as a percussive channel! (XG)
  // This needs to be an option, in case someone actually has a real XG synth.
  if (mp^.midi_standard = MIDI_STANDARD_XG) and (mp^.channels[channel].last_bank = 127) then
   channel := 9;

  dwParam1 := velocity shl 16 or (note shl 8) or $80 or channel;
  if on_ then dwParam1 := dwParam1 or $10;
  midiOutShortMsg(MIDIOUTH, dwParam1);
 end;
end;

procedure set_channel_program(mp:PMIDIParams;channel,prog:byte);
begin
//  if prog >= 128 then
  // MessageBox(hwndApp,PChar('set_channel_program range error: ' + IntToStr(prog)),'Error-warning',MB_ICONERROR);

mp^.channels[channel].normal_program := prog;

if not mp^.analyzing and (MIDIOUTH <> 0) then
  midiOutShortMsg(MIDIOUTH, prog shl 8 or $C0 or channel);
end;

procedure set_channel_pitch(mp:PMIDIParams;channel:byte;intd:integer);
var
 d1,d2:byte;
begin
mp^.channels[channel].changed_pitch_bend := intd;
if not mp^.analyzing then
 begin
  d2 := intd; d1 := intd shr 8;
  mp^.channels[channel].last_pitch_bend := d2 shl 7 or d1 - MAX_PITCH_BEND;
  if MIDIOUTH <> 0 then
   midiOutShortMsg(MIDIOUTH, d2 shl 16 or (d1 shl 8) or $E0 or channel);
 end;
end;

procedure output_sysex_data(init:byte;data:PArray0OfByte;length:integer);
var
 mh:MIDIHDR;
 i:integer;
 tmp:byte;
begin
if MIDIOUTH = 0 then exit;

if init = 0 then
 begin
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
midiOutPrepareHeader(MIDIOUTH, @mh, sizeof(mh));

for i := 0 to 1 do
 begin
  // Send the sysex buffer!
  if midiOutLongMsg(MIDIOUTH, @mh, sizeof(mh)) <> MIDIERR_NOTREADY then break;
  sleep(10);
 end;

// Unprepare the sysex buffer
midiOutUnprepareHeader(MIDIOUTH, @mh, sizeof(mh));

if init = 0 then data[0] := tmp;
end;

// Adds a new node to the list of MIDI text events
procedure new_midi_text(mp:PMIDIParams; var th:track_header_t; midi_text:string; text_type:integer);

 procedure AddStr(s:string);
 var
  t:string;
 begin
  t := Trim(s); if t = '' then exit;
  th.alltexts := th.alltexts + IntToStr(text_type) + ': ' + TrimRight(s) + #13#10;
  //Copyright text
  if (text_type = 2) and (th.fstcopyrtxt = '') then
   th.fstcopyrtxt := t;
  //Sequence or track name
  if (text_type = 3) and (th.fstseqtrkname = '') then
   th.fstseqtrkname := t;
 end;

var
 ch:integer;
begin

if midi_text <> '' then
 begin
  // Sneaky trick to detect MT-32 MIDI files!
  if (mp^.midi_standard = MIDI_STANDARD_NONE) and (pos('MT-32',midi_text) <> 0) then
   mp^.midi_standard := MIDI_STANDARD_MT32;

  // Cool trick to break up lines with CR/LF pairs
  // Search for a CR or LF
  ch := Pos(#13,midi_text);
  if ch = 0 then ch := Pos(#10,midi_text);
  // Found one?  Good.. let's break up the line into multiple text entries!
  if ch <> 0 then
   begin
    // Terminate the string at this character and move to the next character
    midi_text[ch] := #0;
    AddStr(PChar(midi_text)); inc(ch);
    if ch > Length(midi_text) then exit;
    // See if there's another CR/LF to seek past
    if midi_text[ch] in [#13,#10] then inc(ch);
    if ch > Length(midi_text) then exit;
    // Make a new text entry with what we just seeked past
    new_midi_text(mp,th,PChar(@midi_text[ch]),text_type);
   end
  else
   AddStr(midi_text);
 end;
end;

procedure check_midi_standard(var ms:integer;data:PArray0OfByte;len:integer);
begin
if len = 0 then exit;
case data[0] of // Manufacturer ID
$41: // Roland
 begin
  if len < 3 then exit;
  case data[2] of
  $16: // MT-32
   ms := MIDI_STANDARD_MT32;
  $42: // GS Message
   ms := MIDI_STANDARD_GS;
  end;
 end;
$43: // Yamaha
 begin
  if len < 3 then exit;
  case data[2] of
  $4C: // XG Message
   ms := MIDI_STANDARD_XG;
  end;
 end;
$7E, // General MIDI
$7F:
 ms := MIDI_STANDARD_GM;
end;
end;

function read_bytes_mem(var th:track_header_t; buf:PChar; num:longword):longword;
begin
if th.current + num > th.length then
 raise EMultiMediaError.Create('RdBts: file damaged');
Move(th.data[th.current],buf^,num);
inc(th.current,num);
Result := num;
end;

function read_byte_mem(var th:track_header_t):byte;
begin
if th.current >= th.length then
 raise EMultiMediaError.Create('RdBt: file damaged');
Result := th.data[th.current];
inc(th.current);
end;

function read_int_mem(var th:track_header_t):longword;
begin
if th.current + 4 > th.length then
 raise EMultiMediaError.Create('RdInt: file damaged');
Result := SwapEndian(PLongWord(@th.data[th.current])^);
inc(th.current,4);
end;

function read_short_mem(var th:track_header_t):word;
begin
if th.current + 2 > th.length then
 raise EMultiMediaError.Create('RdShrt: file damaged');
Result := SwapEndian(PWord(@th.data[th.current])^);
inc(th.current,2);
end;

function read_vlq_mem(var th:track_header_t):longword;
var
 value:longword;
 c:shortint;
 i:integer;
begin
i := 4;
value := 0;
repeat
 if th.current >= th.length then
  raise EMultiMediaError.Create('RdVLQ: file damaged');
 c := th.data[th.current];
 value := (value shl 7) or longword(c and $7F);
 inc(th.current);
 dec(i);
until (c >= 0) or (i = 0);
if c < 0 then //Error !!!
 raise EMultiMediaError.Create('RdVLQ: file damaged');
Result := value;
end;

// XMIDI Delta Variable Length Quantity
function read_vlq2_mem(var th:track_header_t):longword;
var
 value:byte;
begin
Result := 0;
while True do
 begin
  if th.current >= th.length then exit;
  value := th.data[th.current];
  if shortint(value) < 0 then exit;
  inc(th.current);
  inc(Result,value);
 end;
end;

procedure process_midi_event(mp:PMIDIParams;var th:track_header_t);
var
 text:PChar;
 id:longword;
 i:integer;
 len:longword;
 cmd,d1,d2:byte;
 intd:longword;
 channel:longword;
 sysexptr:PArray0OfByte; // Pointer to beginning of sysex data
begin
// Read the MIDI event command
cmd := read_byte_mem(th);

// Handle running mode
if cmd < 128 then
 begin
  dec(th.current);
  cmd := th.lastcmd;
  if cmd < 128 then
   raise EMultiMediaError.Create('Broken File (cmd < 128)');
 end
//some Meta-events can be inside of other running mode command
else if cmd <> 255 then
 th.lastcmd := cmd;

if cmd = $FF then // Meta-event
 begin
  cmd := read_byte_mem(th);
  len := read_vlq_mem(th);
  if len > th.length - th.current then
   raise EMultiMediaError.Create('Meta-event length error');
  case cmd of
  $01, // Text
  $02, // Copyright info
  $03, // Sequence or track name
  $04, // Track instrument name
  $05, // Lyric
  $06, // Marker
  $07: // Cue point
   if (mp^.analyzing and not mp^.seeking) then
    begin
     // Read the text
     GetMem(text,len + 1);
     try
      read_bytes_mem(th,text,len);
      text[len] := #0;
      // Save the text
      new_midi_text(mp,th,text,cmd);
     finally
      FreeMem(text);
     end;
    end
   else
    inc(th.current,len);
  $2F: // End of track
   begin
    th.enabled := False;
    inc(th.current,len);
   end;
  $51: // Set tempo
   begin
    if Len >= 3 then
     begin
      read_bytes_mem(th, @id, 3);
      intd := SwapEndian(id shl 8);
      set_tempo(mp,intd);
      inc(th.current,len-3);
     end
    else
     inc(th.current,len);
   end;
  else // Unknown or not need for me
   inc(th.current,len);
  end;
 end
else
 begin
  channel := cmd and 15;
  // *** cool symmetric part follows: ***
  case cmd shr 4 of // Normal event
  $08: // Note off
   begin
    d1 := read_byte_mem(th);
    d2 := read_byte_mem(th);
    if not mp^.analyzing then
     note_on(mp,FALSE,d1,d2,channel);
   end;
  $09: // Note on
   begin
    d1 := read_byte_mem(th);
    d2 := read_byte_mem(th);
    if mp^.file_format = -1 then
    intd := read_vlq_mem(th);
    if not mp^.analyzing then
     begin
      if mp^.file_format = -1 then
       begin
        //This check for old soft MIDI devices (VSC and SYXG50 for Windows)
        if mp^.channels[channel].xmioff[d1 and $7F] >= 0 then //Was on?
         note_on(mp,FALSE,d1,0,channel); //then off it
        mp^.channels[channel].xmioff[d1 and $7F] := mp^.curtime + intd * mp^.tick_length;
       end;
      note_on(mp,TRUE,d1,d2,channel);
     end
    else if not mp^.found_note_on then
     begin
      mp^.found_note_on := True;
      mp^.first_note_on := th.trigger;
     end;
   end;
  $0A: // Key after-touch
   begin
    d1 := read_byte_mem(th);
    d2 := read_byte_mem(th);
    if not mp^.analyzing and (MIDIOUTH <> 0) then
     midiOutShortMsg(MIDIOUTH, d2 shl 16 or (d1 shl 8) or cmd);
   end;
  $0B: // Control Change
   begin
    d1 := read_byte_mem(th);
    d2 := read_byte_mem(th);
    if mp^.file_format = -1 then
     case d1 of
     116: //XMIDI_FOR_LOOP
      begin
       inc(mp^.loop_num);
       if mp^.loop_num = MAX_XMIDILOOPS then
        raise EMultiMediaError.Create('Number of XMIDI loops too big (>128)');
       mp^.loops[mp^.loop_num].count := d2;
       mp^.loops[mp^.loop_num].current := th.current;
       exit;
      end;
     117: //XMIDI_NEXT_BREAK
      begin
       if mp^.loop_num >= 0 then
        if d2 < 64 then
         dec(mp^.loop_num);
       if (mp^.loop_num < 0) or (mp^.loops[mp^.loop_num].count = 0) then
        th.enabled := False
       else
        begin
         th.current := mp^.loops[mp^.loop_num].current;
         dec(mp^.loops[mp^.loop_num].count);
         if mp^.loops[mp^.loop_num].count = 0 then
          dec(mp^.loop_num);
        end;
       exit;
      end;
     end;
    if not mp^.analyzing or mp^.seeking then
     begin
      case d1 of
      0: mp^.channels[channel].last_bank := d2;
      7: mp^.channels[channel].volume := 127 - (d2 and 127);
      10:mp^.channels[channel].pan := d2 and 127;
      end;
      if MIDIOUTH <> 0 then
       for i := 0 to 1 do
        begin
         if midiOutShortMsg(MIDIOUTH, d2 shl 16 or (d1 shl 8) or $B0 or channel) <> MIDIERR_NOTREADY then break;
         sleep(10);
        end;
     end;
   end;
  $0C: // Program Change
   set_channel_program(mp,channel,read_byte_mem(th));
  $0D: // Channel after-touch
   begin
    d1 := read_byte_mem(th);
    if not mp^.analyzing then
     midiOutShortMsg(MIDIOUTH, d1 shl 8 or cmd);
   end;
  $0E: // Pitch wheel
   begin
    intd := read_short_mem(th);
    set_channel_pitch(mp,channel,intd);
   end;
  $0F: // System message
   case channel of
   $01: //MTC Quarter Frame Message
    read_byte_mem(th);
   $02: //Song position
    begin
     read_byte_mem(th);
     read_byte_mem(th);
    end;
   $03: //Song select
    read_byte_mem(th);
   $00,
   $07: // SYSEX data
    begin
     len := read_vlq_mem(th);
     if len > th.length - th.current then
      raise EMultiMediaError.Create('Sysex len error');
     sysexptr := @th.data[th.current];
     inc(th.current,len);
     if mp^.analyzing and not mp^.seeking and (channel = 0) then
      check_midi_standard(mp^.midi_standard,sysexptr,len);
     if not mp^.analyzing or mp^.seeking then
      // Don't send sysex when seeking on the MT-32
      if not ((mp^.midi_standard = MIDI_STANDARD_MT32) and mp^.seeking) then
       output_sysex_data(channel,sysexptr,len);
    end;
   end;
  end;
 end;
end;

procedure analyze_midi(mp:PMIDIParams);
var
 i:integer;
 vlq,starttime:longword;
 curtime,nexttrigger:double;
 first_pass:boolean;
begin

// Initialize playback parameters
mp^.midi_standard := MIDI_STANDARD_NONE;
mp^.stop_requested := False;

mp^.tick_length := 500000 / 1000 / mp^.num_ticks;
mp^.tempo := 500000; //120 BPM
if mp^.file_format = -1 then //Prepare to accept only first set_tempo for XMI
 mp^.tempo := 0;
mp^.analyzing := True;
mp^.seeking := False;
mp^.loop_num := -1; //No XMIDI loops for the moment

// Initialize track parameters
for i := mp^.track_from to mp^.track_to do
 begin
  mp^.th[i].track_length := 0;
  mp^.th[i].lastcmd := 0;
  mp^.th[i].enabled := True;
  mp^.th[i].trigger := 0.0;
  mp^.th[i].current := 0;
 end;

// Record starting time
starttime := 0;
nexttrigger := 0.0;
mp^.starttime := starttime;

mp^.found_note_on := False;
mp^.first_note_on := 0.0;

// Loop until we've been asked to stop
first_pass := True;
while not mp^.stop_requested do
 begin
  curtime := nexttrigger;
  // Schedule the next "wakeup time" MAX_MIDI_WAIT milliseconds into the future
  nexttrigger := curtime + MAX_MIDI_WAIT;

  // See if any tracks have pending data
  mp^.stop_requested := True;
  for i := mp^.track_from to mp^.track_to do
   begin
    // Continue on to the next track if this track is disabled
    if not mp^.th[i].enabled then
     continue
    else
     mp^.stop_requested := False;

    // Read the next event's delta time
    if first_pass then
     begin
      if mp^.file_format = -1 then
       vlq := read_vlq2_mem(mp^.th[i])
      else
       vlq := read_vlq_mem(mp^.th[i]);
      mp^.th[i].trigger := curtime + vlq * mp^.tick_length;
     end;

    // Process MIDI events until one is scheduled for a time in the future
    while curtime >= mp^.th[i].trigger do
     begin

      // Process the event for this track
      mp^.curtime := curtime;
      process_midi_event(mp,mp^.th[i]);

      // Check for end of track
      if not mp^.th[i].enabled then
       begin
        mp^.th[i].track_length := round(curtime);
        break;
       end;

      if mp^.th[i].current >= mp^.th[i].length then
       begin
        mp^.th[i].track_length := round(curtime);
        mp^.th[i].enabled := False;
        break;
       end;

      // Read the next event's delta time
      if mp^.file_format = -1 then
       vlq := read_vlq2_mem(mp^.th[i])
      else
       vlq := read_vlq_mem(mp^.th[i]);
      mp^.th[i].trigger := mp^.th[i].trigger + vlq * mp^.tick_length;
     end;
    // Check for end of track
    if not mp^.th[i].enabled then continue;

    // See if this track's trigger is the more recent than the next scheduled trigger
    // If so, make it the next trigger
    if mp^.th[i].trigger < nexttrigger then
     nexttrigger := mp^.th[i].trigger;
   end;
  first_pass := False;
 end;
// Analysis complete

// Store song length
mp^.song_length := round(curtime);

end;

procedure load_midi(var mp:PMIDIParams;prescan_tracks:PWord;filename:string);

var
 URHandle:integer;

 function read_short:word;
 var
  v:word;
 begin
 UniRead(URHandle,@v,2);
 Result := SwapEndian(v)
 end;

 function read_int:longword;
 var
  v:longword;
 begin
 UniRead(URHandle,@v,4);
 Result := SwapEndian(v)
 end;

var
 id:longword;
 buf:array[0..1023] of byte;
 track:longword;
 i:integer;
 cur,len,start,chunk_len:Int64;
begin

if prescan_tracks = nil then new(mp);

try

 UniReadInit(URHandle,URFile,filename,nil,-1);

 try

  // Read the MIDI file header
  UniRead(URHandle,@id,4);

  // Could be XMIDI
  if id = XMIFORM then
   begin
    // Read length of
    len := read_int;

    start := UniReadersData[URHandle]^.UniFilePos;

    // Read 4 bytes of type
    UniRead(URHandle,@id,4);

    // XDIRless XMIDI, we can handle them here.
    if id = XMID then
     track := 1
    // Not an XMIDI that we recognise
    else if id <> XDIR then
     raise EMultiMediaError.Create('Not a recognised XMID')
    // Seems Valid
    else
     begin
      track := 0;

      cur := 4;
      while cur < len do
       begin

        // Read 4 bytes of type
        UniRead(URHandle,@id,4);

        // Read length of chunk
        chunk_len := read_int;

        if id <> XMIINFO then
         begin
          // Must allign
          inc(cur,8 + ((chunk_len + 1) and $FFFFFFFFFFFFFFFE));
          UniFileSeek(URHandle,start + cur);
          continue;
         end;

        // Must be at least 2 bytes long
        if chunk_len < 2 then break;

        UniRead(URHandle,@track,2);
        break;
       end;

      // Didn't get to fill the header
      if track = 0 then
       raise EMultiMediaError.Create('Not a valid XMID');

      // Ok now to start part 2
      // Goto the right place
      UniFileSeek(URHandle,start + ((len + 1) and $FFFFFFFFFFFFFFFE));

      // Read 4 bytes of type
      UniRead(URHandle,@id,4);

      // Not an XMID
      if id <> XMICAT then
       raise EMultiMediaError.Create('Not a recognised XMID (no "CAT ")');

      // Skip length of this track
      UniFileSeek(URHandle,UniReadersData[URHandle]^.UniFilePos + 4);

      // Read 4 bytes of type
      UniRead(URHandle,@id,4);

      // Not an XMID
      if id <> XMID then
       raise EMultiMediaError.Create('Not a recognised XMID ("XMID" not found)');

     end;

    if prescan_tracks <> nil then
     begin
      prescan_tracks^ := track;
      exit;
     end;

    // Ok it's an XMID
    mp^.num_tracks := track;
    mp^.file_format := -1;
    mp^.num_ticks := 500000 * 3 div 25000;
    SetLength(mp^.th,track);
    for i := 0 to track - 1 do
     FillChar(mp^.th[i],sizeof(track_header_t),0);

    track := 0; 

    while (UniReadersData[URHandle]^.UniFilePos < UniReadersData[URHandle]^.UniFileSize)
          and (track < mp^.num_tracks) do
     begin
      // Read first 4 bytes of name
      UniRead(URHandle,@id,4);
      len := read_int;

      // Skip the FORM entries
      if id = XMIFORM then
       begin
        UniFileSeek(URHandle,UniReadersData[URHandle]^.UniFilePos + 4);
        UniRead(URHandle,@id,4);
        len := read_int;
       end;

      if id <> XMIEVNT then
       begin
        UniFileSeek(URHandle,UniReadersData[URHandle]^.UniFilePos + ((len + 1) and $FFFFFFFFFFFFFFFE));
        continue;
       end;

      start := UniReadersData[URHandle]^.UniFilePos;

      mp^.th[track].length := len;

      // Read the track data into memory
      GetMem(mp^.th[track].data,mp^.th[track].length);
      try
       UniRead(URHandle,mp^.th[track].data,mp^.th[track].length)
      except
       FreeMem(mp^.th[track].data);
       break;
      end;

      // Increment Counter
      inc(track);

      // go to start of next track
      UniFileSeek(URHandle,start + ((len + 1) and $FFFFFFFFFFFFFFFE));
     end;
   end
  // Check to see if the "MThd" ID is correct
  else
   begin
    if MThd <> id then
     begin
      // No?  Check for a RIFF header (RMID format)
      if RIFF = id then
       begin
        // Yes!  Read len

        UniRead(URHandle,@i,4);
        len := i;

        start := UniReadersData[URHandle]^.UniFilePos;

        // Read 4 bytes of type
        UniRead(URHandle,@id,4);

        if id <> RMID then
         raise EMultiMediaError.Create('Invalid RMID');

        // Is a RMID
        cur := 4;
        while cur < len do
         begin

          // Read 4 bytes of type
          UniRead(URHandle,@id,4);

          UniRead(URHandle,@i,4);
          chunk_len := i;

          if id = RIFFdata then break;

          // Must allign
          inc(cur,8 + ((chunk_len + 1) and $FFFFFFFFFFFFFFFE));
          UniFileSeek(URHandle,start + cur);
         end;

        // Now read the MIDI file header
        UniRead(URHandle,@id,4);
        // Now look for MThd
        if MThd <> id then
         raise EMultiMediaError.Create('Not a MIDI file because it does not begin with "MThd"')
       end
      else
       begin
        // STILL no MThd?  Search through the beginning of the file for MThd
        UniFileSeek(URHandle,0);
        len := UniReadersData[URHandle]^.UniFileSize;
        if len > 1024 then len := 1024;
        UniRead(URHandle,@buf,len);
        cur := 0;
        if len > 4 then
         begin
          while cur < len - 4 do
           begin
            if MThd = PLongWord(@buf[cur])^ then break;
            inc(cur);
           end;
         end;
        if (len <= 4) or (cur >= len - 4) then
         raise EMultiMediaError.Create('Not a MIDI file because it does not begin with "MThd"');
        UniFileSeek(URHandle,cur + 4);
       end;
     end;
    // Read the header size
    len := read_int;
    if len <> 6 then
     raise EMultiMediaError.Create('Unexpected MIDI file header length: ' + IntToStr(len));

    // Identify the file format
    i := read_short;
    if not (i in [0..2]) then
     raise EMultiMediaError.Create('Unknown MIDI file type: ' + IntToStr(i));

    if (prescan_tracks <> nil) and (i <> 2) then
     begin
      prescan_tracks^ := 1;
      exit;
     end; 

    // Output other information present in the header
    track := read_short;

    if prescan_tracks <> nil then
     begin
      if track = 0 then //header says 'no tracks'
       track := 1; //try to extract tracks anyway later
      prescan_tracks^ := track;
      exit;
     end; 

    mp^.file_format := i;
    mp^.num_tracks := track;

    SetLength(mp^.th,track);
    for i := 0 to integer(track) - 1 do
     FillChar(mp^.th[i],sizeof(track_header_t),0);
    mp^.num_ticks := read_short;
    if smallint(mp^.num_ticks) <= 0 then
     raise EMultiMediaError.Create('PPQN <= 0 (not supported yet)');

    track := 0;

    // Read tracks
    while UniReadersData[URHandle]^.UniFilePos < UniReadersData[URHandle]^.UniFileSize do
     begin

      if (track >= MAX_MIDI_TRACKS) then break;

      // Read the track header
      try
       UniRead(URHandle,@id,4);
      except
       break;
      end;
      // Check to see if the "MTrk" ID is correct
      if MTrk <> id then break;
      if track >= mp^.num_tracks then
       begin
        SetLength(mp^.th,track + 1);
        mp^.num_tracks := track + 1;
        FillChar(mp^.th[track],sizeof(track_header_t),0);
       end;

      // Read track length in bytes
      try
       mp^.th[track].length := read_int;
      except
       break;
      end;

      // Read the track data into memory
      GetMem(mp^.th[track].data,mp^.th[track].length);
      try
       UniRead(URHandle,mp^.th[track].data,mp^.th[track].length);
      except
       FreeMem(mp^.th[track].data);
       break;
      end;
      inc(track);
     end;
   end;

  if track < mp^.num_tracks then
   begin
    SetLength(mp^.th,track);
    mp^.num_tracks := track;
   end;
  if track = 0 then
   raise EMultiMediaError.Create('No tracks in MIDI file');

 finally
  UniReadClose(URHandle);
 end;

 if (mp^.file_format = -1) or (mp^.file_format = 2) then
  begin
   for i := 0 to mp^.num_tracks - 1 do
    begin
     mp^.track_to := i;
     mp^.track_from := i;
     analyze_midi(mp);
    end;
  end
 else
  begin
   mp^.track_to := mp^.num_tracks - 1;
   mp^.track_from := 0;
   analyze_midi(mp);
  end

except
 if prescan_tracks = nil then
  begin
   unload_midi(mp);
   raise;
  end
 else
  prescan_tracks^ := 0;
end;

end;

procedure unload_midi(mp:PMIDIParams);
var
 i:integer;
begin
// Unload any previously-loaded MIDI data
if mp^.num_tracks <> 0 then
 for i := 0 to mp^.num_tracks - 1 do
  if mp^.th[i].data <> nil then
   FreeMem(mp^.th[i].data);
Dispose(mp);
end;

procedure TThread1.Execute; //todo нужна ревизия кода, много спорных моментов
var
 i,j:integer;
 vlq,starttime:longword;
 curtime:double;
 nexttrigger:double;
 first_pass:boolean;
 tracks_active:boolean;
 seeking:boolean;
 mp:PMIDIParams;
label
 BeginPlayback;
begin

mp := MIDIParams;

// Initialize seeking states
if MIDISeekToFirstNote and (mp^.first_note_on > 500.0) then
 //Skip start silence if it > 0.5 sec
 begin
  seeking := True;
  mp^.seek_to := mp^.first_note_on - 100.0; //100 ms before first note
 end
else
 begin
  seeking := False;
  mp^.seek_to := 0.0;
 end;

mp^.seeking := seeking;

// Init MIDI-out device
try
 init_midi_out;
except
// ShowException(ExceptObject,ExceptAddr);
// exit; //todo next play ?
end;
if MIDIOUTH = 0 then exit; //todo next play ?

// Set playback thread priority
//Priority:=tpHighest; вынесено за нитку

// Initialize loop count
mp^.loop_count := 1;

mp^.loop_num := -1; //No XMIDI loops for the moment

//Set max MMTimers precision
timeBeginPeriod(PeriodMin);

while mp^.loop_count > 0 do
 begin
  dec(mp^.loop_count);
  if (mp^.file_format <> -1) or (mp^.loop_num < 0) then //Don't init if looping to XMIDI-looppoint
   begin
BeginPlayback:
    // Initialize tempo
    mp^.tick_length := 500000 / 1000 / mp^.num_ticks;
    mp^.tempo := 500000; //120 BPM
    if mp^.file_format = -1 then //Prepare to accept only first set_tempo for XMI
     mp^.tempo := 0;

    // Initialize playback parameters
    mp^.analyzing := mp^.seeking;
    mp^.playing := True;
    IsPlaying := True;
    mp^.paused := False;
    Paused := False;
//    mp^.stop_requested := False; //todo похоже из-за этого висло, пока не было проверки Terminated

    // Reset channel states
    for i := 0 to 15 do
     begin
      // Reset # of notes currently being played on this channel
      mp^.channels[i].note_count := 0;
      mp^.channels[i].note_counta := 0;

      mp^.channels[i].volume := 0;
      mp^.channels[i].pan := 64;

      mp^.channels[i].last_bank := -1;

      mp^.channels[i].changed_pitch_bend := -1;
      // Reset program values
      mp^.channels[i].normal_program := -1;
      // Reset note values
      FillChar(mp^.channels[i].notes,sizeof(mp^.channels[i].notes),0);
      // Reset historical values
      mp^.channels[i].last_pitch_bend := 0;
      // Reset XMI note off times
      if mp^.file_format = -1 then
       for j := 0 to 127 do
        mp^.channels[i].xmioff[j] := -1;
     end;

    // Initialize track parameters
    for i := mp^.track_from to mp^.track_to do
     begin
      mp^.th[i].lastcmd := 0;
      mp^.th[i].enabled := True;
      mp^.th[i].trigger := 0.0;
      mp^.th[i].current := 0;
     end;

    // Record starting time
    starttime := timeGetTime;
    mp^.starttime := starttime;
    curtime := 0.0;
    nexttrigger := curtime;
    mp^.elapsedtime := 0;

    first_pass := True;
    tracks_active := True;
    mp^.started := True;
   end;

  // Loop until we've been asked to stop
  while not mp^.stop_requested and not Terminated do
   begin
    // Get current time
    if not seeking then
     begin
      curtime := longword(timeGetTime - starttime);
      mp^.elapsedtime := trunc(curtime); //round ?
     end
    else
     begin
      if tracks_active then curtime := nexttrigger;
      // See if the seek is done or forced to stop seeking
      if not tracks_active or (curtime >= mp^.seek_to) then
       begin
        // Seek is done - correct timing values
        starttime := round(timeGetTime - curtime);
        mp^.starttime := starttime;
        mp^.elapsedtime := trunc(curtime); //round ?
        // Reset seek state flags
        mp^.analyzing := False;
        mp^.seeking := False;
        seeking := False;

        // Set channel values
        for i := 0 to 15 do
         begin
          if (mp^.channels[i].changed_pitch_bend >= 0) then
           set_channel_pitch(mp,i,mp^.channels[i].changed_pitch_bend);
          // Set program changes
          if (mp^.channels[i].normal_program >= 0) then
           set_channel_program(mp,i,mp^.channels[i].normal_program);
         end;
       end;
     end;

    // See if we've been asked to seek and we're not already doing it
    if mp^.seeking and not seeking then
     begin
      seeking := True;
      // Turn all notes off
      all_notes_off(mp);
      if mp^.seek_to >= mp^.elapsedtime then
       mp^.analyzing := True
      else
       goto BeginPlayback; // Aaaah!  A goto!! (not my ;) )
     end;

    // Schedule the next "wakeup time" MAX_MIDI_WAIT milliseconds into the future
    nexttrigger := curtime + MAX_MIDI_WAIT;

    mp^.curtime := curtime;

    //Check note off time for XMI
    if not seeking and (mp^.file_format = -1) then
     for i := 0 to 15 do
      if mp^.channels[i].note_counta <> 0 then
       for j := 0 to 127 do
        if mp^.channels[i].xmioff[j] >= 0 then
         if curtime >= mp^.channels[i].xmioff[j] then
          note_on(mp,FALSE,j,0,i)
         else if mp^.channels[i].xmioff[j] < nexttrigger then
          nexttrigger := mp^.channels[i].xmioff[j];

    // See if any tracks have pending data
    tracks_active := False;
    for i := mp^.track_from to mp^.track_to do
     begin
      // Continue on to the next track if this track is disabled
      if not mp^.th[i].enabled then continue;

      // Read the first event's delta time
      if first_pass then
       begin
        if mp^.file_format = -1 then
         vlq := read_vlq2_mem(mp^.th[i])
        else
         vlq := read_vlq_mem(mp^.th[i]);
        mp^.th[i].trigger := curtime + vlq * mp^.tick_length;
       end;

      // Process MIDI events until one is scheduled for a time in the future
      while curtime >= mp^.th[i].trigger do
       begin
        // Process the event for this track
        try
         process_midi_event(mp,mp^.th[i])
        except
         mp^.stop_requested := True; //todo вообще-то эту переменную безопасно только читать из thread'а
         break;
        end;

        // Disable this track if its data pointer has reached or exceeded the track length
        if mp^.th[i].current >= mp^.th[i].length then
         begin
          mp^.th[i].enabled := False;
          break;
         end;

        // Check for end of track
        if not mp^.th[i].enabled then break;

        // Read the next event's delta time
        if mp^.file_format = -1 then
         vlq := read_vlq2_mem(mp^.th[i])
        else
         vlq := read_vlq_mem(mp^.th[i]);
        mp^.th[i].trigger := mp^.th[i].trigger + vlq * mp^.tick_length;
       end;
      // Check for end of track
      if not mp^.th[i].enabled then continue;
      tracks_active := True;

      // See if this track's trigger is the more recent than the next scheduled trigger
      if mp^.th[i].trigger < nexttrigger then
       nexttrigger := mp^.th[i].trigger;
     end;
    first_pass := False;


    // Check to see if a pause has been requested
    if mp^.paused then
     begin
      // Turn off the notes being played
      all_notes_off(mp);
      // Wait until we're unpaused or not playing anymore
      while mp^.paused and mp^.playing and not mp^.stop_requested and not Terminated do
       Sleep(100);
      // If we've been asked to stop.. break from the main playback loop
      if not mp^.playing or mp^.stop_requested or Terminated then
       break;
      // We need to resume.  Correct the start time to be up-to-date!
      starttime := round(timeGetTime - curtime);
     end;

    // Wait until the next trigger time
    if not mp^.stop_requested and not seeking and not Terminated then
     begin
      if not tracks_active then break;
      i := trunc(nexttrigger - longword(timeGetTime - starttime));
      if i >= 0 then Sleep(i);
     end;
   end;

  // Break out of looping if a stop was requested
  if mp^.stop_requested or Terminated  then break;

  // If the looping checkbox is checked, loop another time
  if Do_Loop then
   begin
    inc(mp^.loop_count);

    if (mp^.file_format = -1) and (mp^.loop_num >= 0) then //XMIDI loop point
     begin
      mp^.th[mp^.track_from].enabled := True;
      mp^.th[mp^.track_from].current := mp^.loops[mp^.loop_num].current;
      mp^.th[mp^.track_from].trigger := mp^.th[mp^.track_from].trigger +
        read_vlq2_mem(mp^.th[mp^.track_from]) * mp^.tick_length;
     end;
   end;
 end;
// PLAYBACK HAS STOPPED
//Restore default MMTimers precision
timeEndPeriod(PeriodMin);
// Turn off all the notes, reset the MIDI-out device, and close it
all_notes_off(mp);
Sleep(50);
try
 close_midi_out;
except
 ShowException(ExceptObject,ExceptAddr);
end;

mp^.playing := False;

if not mp^.stop_requested then //todo как в digsoundcode
             //todo передавать Handle через параметры
 PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0);

end;

procedure MIDIVisualisation;
const
 lpq = 180;
 pr = 14;
var
 c:^channel_state_t;
 i,j,vol,x,lq,mq,rq:integer;
begin
if not midithread_active or MIDIParams^.paused or
   not MIDIParams^.started or MIDIParams^.seeking then
 Exit;
VProgrPos := MIDIParams^.elapsedtime;
CurrTime_Rasch := VProgrPos;
if SpectrumChecked or IndicatorChecked then
 begin
  lq := 0; mq := 0; rq := 0;
  if SpectrumChecked then
   FillChar(PSpa_prev^,SizeOf(TSpa),0);
  // Loop through the MIDI channels
  for i := 0 to 15 do
   begin
    c := @MIDIParams^.channels[i];
    // Distinguish between channels with active notes versus silent channels
    if c^.note_count <> 0 then
     begin
      // This channel has at least one note playing.

      // Loop through the notes on this channel
      for j := 0 to 127 do
       begin
        // Get the volume for this note (0 means the note is not being played)
        vol := c^.notes[j] - c^.volume; //must be logarithmic
        if SpectrumChecked and (j > 15) and (vol > 0) then
         begin
          // This note is being played.

          //0 - 8.1757 Hz
          //12 - 16.3516 Hz
          //16 - 20.6017 Hz
          //100 - 2637.0205 Hz
          //127 - 12543.8540 Hz
          if c^.last_pitch_bend = 0 then
           x := round((j - 16) * (spa_num - 1) / (127 - 16))
          else
           //Due http://www.elvenminstrel.com/music/tuning/reference/pitchbends.shtml
           //one unit of MIDI pitch bend is 2/8192 of semitones
           x := round((j - 16 + c^.last_pitch_bend * (2 / 8192)) * (spa_num - 1) / (127 - 16));
          if x in [0..spa_num-1] then
           if vol > PSpa_prev^[x] then PSpa_prev^[x] := vol;
         end;
        if IndicatorChecked and (vol > 0) then
         begin
          x := vol*vol;
          case c^.pan of
          0..64-pr:  inc(lq,x);
          64+pr..127:inc(rq,x);
          else       inc(mq,x);
          end;
         end;
       end;
     end;
   end;
  if IndicatorChecked then
   begin
    lq := round(sqrt(lq));
    if lq > lpq then lq := lpq;
    mq := round(sqrt(mq));
    if mq > lpq then mq := lpq;
    rq := round(sqrt(rq));
    if rq > lpq then rq := lpq;
    RedrawVisChannels(lq,mq,rq,lpq)
   end;
  if SpectrumChecked then
   RedrawVisSpectrum(nil,127);
 end;
ShowProgress(VProgrPos);
end;

procedure MIDI_SetLoop;
begin
if Do_Loop or not midithread_active or (MIDIParams^.file_format <> -1) or
   (MIDIParams^.loop_num < 0) or MIDIParams^.paused or not MIDIParams^.started or
   MIDIParams^.seeking then exit;
//Looped XMIDI
if CurrTime_Rasch >= Time_ms then
 PostMessage(FrmMain.Handle,WM_PLAYNEXTITEM,0,0);
end;

function midithread_active:boolean;
begin
Result := midi_thread <> nil;
end;

procedure midithread_free;
begin
midi_thread.Terminate;
midi_thread.WaitFor;
midi_thread.Free;
midi_thread := nil;
end;

procedure midithread_stop;
begin
if midithread_active then
 begin
  MIDIParams^.stop_requested := True;
  midithread_free;
 end;
end;

procedure midithread_start;
begin
if midithread_active then exit;
MIDIParams^.started := False;
MIDIParams^.stop_requested := False;
if (MIDIParams^.file_format = -1) or (MIDIParams^.file_format = 2) then
 if MIDIParams^.track_to >= MIDIParams^.num_tracks then
  raise EMultiMediaError.Create('Track out of range');
midi_thread := TThread1.Create(False);
midi_thread.Priority := tpHighest;
end;

var
 tc:TIMECAPS;

initialization

if timeGetDevCaps(@tc, sizeof(TIMECAPS)) = TIMERR_NOERROR then
 begin
  if PeriodMin < tc.wPeriodMin then PeriodMin := tc.wPeriodMin;
  if PeriodMin > tc.wPeriodMax then PeriodMin := tc.wPeriodMax;
 end;

end.
