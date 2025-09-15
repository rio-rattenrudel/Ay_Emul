{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit mixerctl;

{$mode objfpc} {$H+}

interface

uses
  Classes, SysUtils,
  {$ifdef Windows}MMSystem, Windows,{$else}asoundlib, BaseUnix,{$endif}
  LCLIntf, LCLType;

type
  Tmixerctl_list = array of record
   Name:string;
   SubDevice:array of record
    Name:string;
    SubDevice:array of string;
    end;
   end;

function mixerctl_enumerate(var List:Tmixerctl_list):integer;
function mixerctl_open(const Path1,Path2,Path3:string;CallBackWindowHandle:HWND;CallBackMessage:Cardinal):integer;
function mixerctl_close:integer;
function mixerctl_title(var Title:string):integer;

//v in range 0..1, result is number of updated channels
function mixerctl_setvolume(v:single):integer;

//if result=0 then v was set (in range 0..1)
function mixerctl_getvolume(out v:single;UpdateBalans:boolean):integer;

var
 mixerctl_Path1:string = '';
 mixerctl_Path2:string = '';
 mixerctl_Path3:string = '';

implementation

{$ifdef Windows}
const
  MixIDNo = UINT(-1);
{$endif}

type
{$ifdef Windows}
  TSysMixers = array of record
   ID:UINT;
   Caps:TMIXERCAPSW;
   Dests:array of record
    Line:TMIXERLINEW;
    LCtrls:TMIXERLINECONTROLSW;
    Ctrls:array of TMIXERCONTROLW;
   end;
  end;
{$else}
  TMIXERCONTROLDETAILS_UNSIGNED = record
    dwValue:clong;//DWORD in Windows;
  end;
  TThread1 = class(TThread)
     protected
       procedure Execute; override;
     end;
{$endif}

var
  mparams:record
   Opened:boolean;
   Chans:integer;
   CallBackWindowHandle:HWND;
   {$ifdef Windows}
   CallBackMessage:UINT;
   Pos,Max,Min:DWORD;
   PrevWndProc:WNDPROC;
   MixerID:UINT;
   ControlID:DWORD;
   MixerHandle:HMIXER;
   {$else}
   CallBackMessage:Cardinal;
   Pos,Max,Min:clong;
   mixerHandle:Psnd_mixer_t;
   mixElem:Psnd_mixer_elem_t;
   monitor_thread:TThread1;
   mixercall_csection:TCriticalSection;
   ChanIDs:array of snd_mixer_selem_channel_id_t;
   {$endif}
   Balans,Vals:array of TMIXERCONTROLDETAILS_UNSIGNED;
  end;

procedure FillParams(const Path1,Path2,Path3:string;Max,Min:int64;Chans:integer);
var
 ind:integer;
 v:single;
begin
mparams.Opened := True;
mixerctl_Path1 := Path1;
mixerctl_Path2 := Path2;
mixerctl_Path3 := Path3;
mparams.Max := Max;
mparams.Min := Min;
mparams.Chans := Chans;
SetLength(mparams.Vals,Chans);
SetLength(mparams.Balans,Chans);
for ind := 0 to Chans - 1 do
 begin
  mparams.Vals[ind].dwValue := mparams.Max;
  mparams.Balans[ind].dwValue := mparams.Max;
 end;
mparams.Pos := mparams.Max;
mixerctl_getvolume(v,True);
end;

{$ifdef Windows}
procedure GetSystemMixers(var Mixers:TSysMixers);
var
 n,i:UINT;
 j:DWORD;
begin
n := mixerGetNumDevs;
SetLength(Mixers,n);
if n <> 0 then
 for i := 0 to n - 1 do
  begin
   if mixerGetID(i,Mixers[i].ID,MIXER_OBJECTF_MIXER) <> MMSYSERR_NOERROR then
    Mixers[i].ID := MixIDNo
   else if mixerGetDevCapsW(Mixers[i].ID,@Mixers[i].Caps,sizeof(TMIXERCAPSW)) = MMSYSERR_NOERROR then
    begin
     SetLength(Mixers[i].Dests,Mixers[i].Caps.cDestinations);
     if Mixers[i].Caps.cDestinations <> 0 then
      for j := 0 to Mixers[i].Caps.cDestinations - 1 do
        begin
         FillChar(Mixers[i].Dests[j],sizeof(TMIXERLINEW),0);
         Mixers[i].Dests[j].Line.cbStruct := sizeof(TMIXERLINEW);
         Mixers[i].Dests[j].Line.dwDestination := j;
         if mixerGetLineInfoW(Mixers[i].ID,@Mixers[i].Dests[j].Line,MIXER_GETLINEINFOF_DESTINATION or
                                         MIXER_OBJECTF_MIXER) <> MMSYSERR_NOERROR then
          Mixers[i].Dests[j].Line.cChannels := 0
         else if Mixers[i].Dests[j].Line.cControls > 0 then
          begin
           SetLength(Mixers[i].Dests[j].Ctrls,Mixers[i].Dests[j].Line.cControls);
           FillChar(Mixers[i].Dests[j].LCtrls,sizeof(TMIXERLINECONTROLSW),0);
           Mixers[i].Dests[j].LCtrls.cbStruct := sizeof(TMIXERLINECONTROLSW);
           Mixers[i].Dests[j].LCtrls.dwLineID := Mixers[i].Dests[j].Line.dwLineID;
           Mixers[i].Dests[j].LCtrls.cControls := Mixers[i].Dests[j].Line.cControls;
           Mixers[i].Dests[j].LCtrls.cbmxctrl := sizeof(TMIXERCONTROLW);
           Mixers[i].Dests[j].LCtrls.pamxctrl := @Mixers[i].Dests[j].Ctrls[0];
           if mixerGetLineControlsW(Mixers[i].ID,@Mixers[i].Dests[j].LCtrls,
                            MIXER_GETLINECONTROLSF_ALL or
                            MIXER_OBJECTF_MIXER) <> MMSYSERR_NOERROR then
            Mixers[i].Dests[j].Line.cControls := 0;
          end;
        end;
    end
   else
    Mixers[i].ID := MixIDNo;
  end;
end;

function WndCallback(Ahwnd: HWND; uMsg: UINT; wParam: WParam; lParam: LParam):LRESULT; stdcall;
begin
if (uMsg = MM_MIXM_CONTROL_CHANGE) and (Ahwnd = mparams.CallBackWindowHandle) then
 if (HMIXER(WParam) = mparams.MixerHandle) and
    (DWORD(LParam) = mparams.ControlID) then
  uMsg := mparams.CallBackMessage;
Result:=CallWindowProc(mparams.PrevWndProc,Ahwnd, uMsg, WParam, LParam);
end;

function SelectMixerControl(var Mixers:TSysMixers;i,j,k:integer):boolean;
begin
Result := False;
if (i < 0) or (j < 0) or (k < 0) then exit;
if (i < Length(Mixers)) and
   (j < Length(Mixers[i].Dests)) and
   (k < Length(Mixers[i].Dests[j].Ctrls)) then
 begin
  if (Mixers[i].ID = MixIDNo) or
     (Mixers[i].Dests[j].Ctrls[k].Bounds.dwMaximum =
      Mixers[i].Dests[j].Ctrls[k].Bounds.dwMinimum) then
   exit;
  mixerctl_close;
  if mixerOpen(@mparams.MixerHandle,
          Mixers[i].ID,mparams.CallBackWindowHandle,0,CALLBACK_WINDOW) <> MMSYSERR_NOERROR then
   exit;
  FillParams(//Path1,Path2,Path3,Max,Min,Chans
     UTF8Encode(WideString(Mixers[i].Caps.szPname)),
     UTF8Encode(WideString(Mixers[i].Dests[j].Line.szName)),
     UTF8Encode(WideString(Mixers[i].Dests[j].Ctrls[k].szName)),
     Mixers[i].Dests[j].Ctrls[k].Bounds.dwMaximum,
     Mixers[i].Dests[j].Ctrls[k].Bounds.dwMinimum,
     Mixers[i].Dests[j].Line.cChannels);
  mparams.MixerID := Mixers[i].ID;
  mparams.ControlID := Mixers[i].Dests[j].Ctrls[k].dwControlID;
  mparams.PrevWndProc:={%H-}WNDPROC(SetWindowLongPtr(mparams.CallBackWindowHandle,GWL_WNDPROC,{%H-}PtrInt(@WndCallback)));
  Result := True;
 end;
end;

function SelectMixerControl2(var Mixers:TSysMixers;const Path1,Path2,Path3:string):boolean;
var
 ind:integer;
 i,j,k:integer;
 ws:widestring;
begin
Result := False;
i := -1;
ws := UTF8Decode(Path1);
for ind := 0 to Length(Mixers) - 1 do
 if Mixers[ind].Caps.szPname = ws then
  begin
   i := ind;
   break;
  end;
if i < 0 then
 Exit;
j := -1;
ws := UTF8Decode(Path2);
for ind := 0 to Length(Mixers[i].Dests) - 1 do
 if Mixers[i].Dests[ind].Line.szName = ws then
  begin
   j := ind;
   Break;
  end;
if j < 0 then
 Exit;
k := -1;
ws := UTF8Decode(Path3);
for ind := 0 to Length(Mixers[i].Dests[j].Ctrls) - 1 do
 if Mixers[i].Dests[j].Ctrls[ind].szName = ws then
  begin
   k := ind;
   Break;
  end;
if k < 0 then
 Exit;
Result := SelectMixerControl(Mixers,i,j,k);
end;

function DetectMixerControl(var Mixers:TSysMixers):boolean;

 function VSearch(CompType:DWORD):boolean;
 var
  i,j,k:integer;
 begin
 Result := False;
 for i := 0 to Length(Mixers) - 1 do
 if Mixers[i].ID <> MixIDNo then
  for j := 0 to Mixers[i].Caps.cDestinations - 1 do
   if (Mixers[i].Dests[j].Line.cChannels > 0) and
      (Mixers[i].Dests[j].Line.dwComponentType = CompType) then
    for k := 0 to Mixers[i].Dests[j].Line.cControls - 1 do
     if Mixers[i].Dests[j].Ctrls[k].dwControlType =
                            MIXERCONTROL_CONTROLTYPE_VOLUME then
      begin
       Result := True;
       SelectMixerControl(Mixers,i,j,k);
       exit;
      end;
 end;

begin
Result := VSearch(MIXERLINE_COMPONENTTYPE_DST_SPEAKERS);
if Result then exit;
Result := VSearch(MIXERLINE_COMPONENTTYPE_DST_HEADPHONES);
if Result then exit;
Result := VSearch(MIXERLINE_COMPONENTTYPE_DST_LINE);
if Result then exit;
Result := VSearch(MIXERLINE_COMPONENTTYPE_DST_DIGITAL);
if Result then exit;
Result := VSearch(MIXERLINE_COMPONENTTYPE_DST_MONITOR);
if Result then exit;
Result := VSearch(MIXERLINE_COMPONENTTYPE_DST_TELEPHONE);
end;
{$else}

procedure TThread1.Execute;
var
  pfds:Ppollfd;
  nfds,rnfds,ret:cint;
  revents:cushort;
begin
repeat
EnterCriticalSection(mparams.mixercall_csection);
try
  nfds := snd_mixer_poll_descriptors_count(mparams.mixerHandle);
  if (nfds <= 0) then exit;

  pfds := GetMem(sizeof(pollfd) * nfds);
  if (pfds = nil) then exit;
  rnfds := snd_mixer_poll_descriptors(mparams.mixerHandle, pfds, nfds);

  if (rnfds < 0) or (rnfds > nfds) then exit;
//            snd_strerror (rnfds)));

finally
  LeaveCriticalSection(mparams.mixercall_csection);
end;

//use timeout cause of no events set on snd_mixer_free, snd_mixer_detach
//and snd_mixer_close in some linuxes
ret := fppoll(pfds, rnfds, 100);
if (ret < 0) or Terminated then exit;
if ret = 0 then continue; //timeout

EnterCriticalSection(mparams.mixercall_csection);
try
  ret := snd_mixer_poll_descriptors_revents(mparams.mixerHandle, pfds, nfds, @revents);
  if (ret < 0) then exit;
//            snd_strerror (ret)));
  if (revents and (POLLIN or POLLPRI)) <> 0 then
   snd_mixer_handle_events (mparams.mixerHandle)
  else if (revents and (POLLERR or POLLNVAL or POLLHUP)) <> 0 then
   exit;
finally
  LeaveCriticalSection(mparams.mixercall_csection);
end;
until Terminated;
end;

function snd_mixer_elem_callback(elem:Psnd_mixer_elem_t;mask:cuint):cint;cdecl;
begin
Result := 0;
if (mask and SND_CTL_EVENT_MASK_REMOVE) = SND_CTL_EVENT_MASK_REMOVE then exit;
if (mask and SND_CTL_EVENT_MASK_VALUE) <> 0 then
 PostMessage(mparams.CallBackWindowHandle,mparams.CallBackMessage,0,0);
end;

{function snd_mixer_callback(ctl:Psnd_mixer_t;mask:cuint;elem:Psnd_mixer_elem_t):cint;cdecl;
begin
Result := 0;
end;}

{function snd_mixer_event(class_:Psnd_mixer_class_t;mask:cuint;
      		       helem:Psnd_hctl_elem_t;melem:Psnd_mixer_elem_t):cint;cdecl;
begin
Result := 0;
end;}

function SelectMixerControl2(const Path1,Path3:string):boolean;
var
 mixerHandle:Psnd_mixer_t;
 mixElem:Psnd_mixer_elem_t;
 count:cuint;
 i,j,chans:integer;
 min,max:clong;

// mclass:Psnd_mixer_class_t;

begin
Result := False;
EnterCriticalSection(mparams.mixercall_csection);
try
  if snd_mixer_open(@mixerHandle, 0) <> 0 then
   Exit;
  try
    if snd_mixer_attach(mixerHandle,PChar(Path1)) <> 0 then
     Exit;
    if snd_mixer_selem_register(mixerHandle, nil, {@mclass}nil) <> 0 then
     Exit;

    if snd_mixer_load(mixerHandle) <> 0 then
     Exit;

    {if snd_mixer_class_set_event(mclass,@snd_mixer_event) <> 0 then
     Exit;}

    mixElem := snd_mixer_first_elem(mixerHandle);
    count := snd_mixer_get_count(mixerHandle);
    if count <> 0 then
     for i := 0 to count - 1 do
      begin
       if (mixElem = nil) then
        Break;
       if snd_mixer_selem_get_name(mixElem) <> Path3 then
        Continue;
       min := 0;
       max := 0;
       if (snd_mixer_selem_has_playback_volume(mixElem) <> 0) then
        begin
         snd_mixer_selem_get_playback_volume_range(mixElem, @min, @max);
         if max > min then
          Exit(True);
        end;
       mixElem := snd_mixer_elem_next(mixElem);
      end;
  finally
    if not Result then
     begin
      snd_mixer_free(mixerHandle);
      snd_mixer_detach(mixerHandle,PChar(Path1));
      snd_mixer_close(mixerHandle);
     end;
  end;
finally
  LeaveCriticalSection(mparams.mixercall_csection);
  if Result then
   begin
    mixerctl_close;
    mparams.mixerHandle:=mixerHandle;
    mparams.mixElem:=mixElem;
    chans := 0;
    SetLength(mparams.ChanIDs,Ord(High(snd_mixer_selem_channel_id_t))-Ord(Low(snd_mixer_selem_channel_id_t))+1);
    for j := Ord(Low(snd_mixer_selem_channel_id_t)) to Ord(High(snd_mixer_selem_channel_id_t)) do
     if snd_mixer_selem_has_playback_channel(mixElem,snd_mixer_selem_channel_id_t(j)) = 1 then
      begin
       mparams.ChanIDs[chans] := snd_mixer_selem_channel_id_t(j);
       Inc(chans);
      end;
    SetLength(mparams.ChanIDs,chans);
    FillParams(Path1,'Playback Volume',Path3,max,min,chans);
    snd_mixer_elem_set_callback(mixElem,@snd_mixer_elem_callback);
//    snd_mixer_set_callback(mixerHandle,@snd_mixer_callback);
    mparams.monitor_thread := TThread1.Create(False);
   end;
end;

end;

function DetectMixerControl:boolean;
var
  List:Tmixerctl_list;
  i,j:integer;
begin
//todo real detect (ctls->Master, PCM, etc) like in gstalsamixer.c
Result := False;
if mixerctl_enumerate(List) <> 0 then exit;
for i := 0 to Length(List)-1 do
 for j := 0 to Length(List[i].SubDevice[0].SubDevice)-1 do
  if SelectMixerControl2(List[i].Name,List[i].SubDevice[0].SubDevice[j]) then
   begin
    Result := True;
    exit;
   end;
end;

{$endif}

function mixerctl_enumerate(var List:Tmixerctl_list):integer;
var
{$ifdef Windows}
 i,j,k,n,o,p:integer;
 Mixers:TSysMixers;
{$else}
 mixerHandle:Psnd_mixer_t;
 tS:string;
 mixElem:Psnd_mixer_elem_t;
 count:cuint;
 i,j:integer;
 min,max:clong;
{$endif}
begin
Result := 0;
{$ifdef Windows}
GetSystemMixers(Mixers);
if Length(Mixers) = 0 then
 begin
//  ShowMessage('No any system mixer found');
  Result := 1; //todo
  exit;
 end;
SetLength(List,Length(Mixers));
n := 0;
for i := 0 to Length(Mixers) - 1 do
 if Mixers[i].ID <> MixIDNo then
  begin
   List[n].Name := UTF8Encode(WideString(Mixers[i].Caps.szPname));
   SetLength(List[n].SubDevice,Mixers[i].Caps.cDestinations);
   o := 0;
   for j := 0 to Mixers[i].Caps.cDestinations - 1 do
    if (Mixers[i].Dests[j].Line.cChannels > 0) and
       (Mixers[i].Dests[j].Line.dwComponentType in
            [MIXERLINE_COMPONENTTYPE_DST_DIGITAL,
             MIXERLINE_COMPONENTTYPE_DST_LINE,
             MIXERLINE_COMPONENTTYPE_DST_MONITOR,
             MIXERLINE_COMPONENTTYPE_DST_SPEAKERS,
             MIXERLINE_COMPONENTTYPE_DST_HEADPHONES,
             MIXERLINE_COMPONENTTYPE_DST_TELEPHONE]) then
     begin
      List[n].SubDevice[o].Name := UTF8Encode(WideString(Mixers[i].Dests[j].Line.szName));
      SetLength(List[n].SubDevice[o].SubDevice,Mixers[i].Dests[j].Line.cControls);
      p := 0;
      for k := 0 to Mixers[i].Dests[j].Line.cControls - 1 do
       if Mixers[i].Dests[j].Ctrls[k].dwControlType =
          MIXERCONTROL_CONTROLTYPE_VOLUME then
        begin
         List[n].SubDevice[o].SubDevice[p] := UTF8Encode(WideString(Mixers[i].Dests[j].Ctrls[k].szName));
         inc(p);
        end;
      SetLength(List[n].SubDevice[o].SubDevice,p);
      inc(o);
     end;
   SetLength(List[n].SubDevice,o);
   inc(n);
  end;
SetLength(List,n);
if n = 0 then
 begin
//  ShowMessage('No valid system mixer');
  Result := 1; //todo
  exit;
 end;
{$else}
SetLength(List,1);
List[0].Name:='default'; //todo other devices
EnterCriticalSection(mparams.mixercall_csection);
try
  snd_mixer_open(@mixerHandle, 0);
  snd_mixer_attach(mixerHandle,'default');
  snd_mixer_selem_register(mixerHandle, nil, nil);
  snd_mixer_load(mixerHandle);

  mixElem := snd_mixer_first_elem(mixerHandle);
  count := snd_mixer_get_count(mixerHandle);
  SetLength(List[0].SubDevice,1);
  List[0].SubDevice[0].Name:='Playback Volume';
  SetLength(List[0].SubDevice[0].SubDevice,count);
  j := 0; if count <> 0 then
  for i := 0 to count - 1 do
   begin
    if (mixElem = nil) then
     break;
    tS := snd_mixer_selem_get_name(mixElem);
    min := 0;
    max := 0;
    if (snd_mixer_selem_has_playback_volume(mixElem) <> 0) then
     begin
      snd_mixer_selem_get_playback_volume_range(mixElem, @min, @max);
      if max > min then
       begin
        List[0].SubDevice[0].SubDevice[j]:=tS;
        inc(j);
       end;
     end;
    mixElem := snd_mixer_elem_next(mixElem);
   end;
  SetLength(List[0].SubDevice[0].SubDevice,j);
  snd_mixer_free(mixerHandle);
  snd_mixer_detach(mixerHandle,'default');
  snd_mixer_close(mixerHandle);
finally
  LeaveCriticalSection(mparams.mixercall_csection);
end;
{$endif}
end;

function mixerctl_open(const Path1,Path2,Path3:string;CallBackWindowHandle:HWND;CallBackMessage:Cardinal):integer;
{$ifdef Windows}
var
 Mixers:TSysMixers;
{$endif}
begin
Result := 0;
mparams.CallBackWindowHandle := CallBackWindowHandle;
mparams.CallBackMessage := CallBackMessage;
{$ifdef Windows}
GetSystemMixers(Mixers);
{$endif}
if (Path1 = '') or not SelectMixerControl2({$ifdef Windows}Mixers,{$endif}
                            Path1,{$ifdef Windows}Path2,{$endif}Path3) then
 if not DetectMixerControl{$ifdef Windows}(Mixers){$endif} then
  Result := 1; //todo retcodes
end;

function mixerctl_close:integer;
begin
Result := 0;
if mparams.Opened then
 begin
  {$ifdef Windows}
  SetWindowLongPtr(mparams.CallBackWindowHandle,GWL_WNDPROC,{%H-}PtrInt(mparams.PrevWndProc));
  mixerClose(mparams.MixerHandle);
  {$else}
  mparams.monitor_thread.Terminate;
  EnterCriticalSection(mparams.mixercall_csection);
  try
   snd_mixer_free(mparams.mixerHandle);
   snd_mixer_detach(mparams.mixerHandle,PChar(mixerctl_Path1));
   snd_mixer_close(mparams.mixerHandle);
  finally
   LeaveCriticalSection(mparams.mixercall_csection);
  end;
  mparams.monitor_thread.WaitFor;
  {$endif}
  mparams.Opened := False;
  mixerctl_Path1 := '';
  mixerctl_Path2 := '';
  mixerctl_Path3 := '';
 end;
end;

function mixerctl_title(var Title:string):integer;
begin
Result := 0;
Title := mixerctl_Path1;
if mixerctl_Path2 <> '' then
 begin
  Title := Title + '->' + mixerctl_Path2;
  if mixerctl_Path3 <> '' then
   Title := Title + '->' + mixerctl_Path3;
 end;
end;

function mixerctl_setvolume(v:single):integer;
var
{$ifdef Windows}
 MCD:TMIXERCONTROLDETAILS;
 ps:DWORD;
{$else}
 ps:clong;
{$endif}
 i:integer;
begin
Result := 0;
if not mparams.Opened or (mparams.Chans = 0) then
 Exit;
{$ifdef Windows}
if mparams.MixerID = MixIDNo then
 Exit;
{$endif}
ps := mparams.Min;
for i := 0 to mparams.Chans - 1 do
 if ps < mparams.Balans[i].dwValue then
  ps := mparams.Balans[i].dwValue;
mparams.Pos := mparams.Min +
                Trunc(v * (mparams.Max - mparams.Min) + 0.5);
for i := 0 to mparams.Chans - 1 do
 if ps > mparams.Min then
  mparams.Vals[i].dwValue := mparams.Min +
   Trunc((mparams.Pos - mparams.Min)/(ps - mparams.Min)*
             (mparams.Balans[i].dwValue - mparams.Min) + 0.5)
 else
  mparams.Vals[i].dwValue := mparams.Pos;
{$ifdef Windows}
FillChar(MCD,sizeof(TMIXERCONTROLDETAILS),0);
MCD.cbStruct := sizeof(TMIXERCONTROLDETAILS);
MCD.dwControlID := mparams.ControlID;
MCD.cChannels := mparams.Chans;
MCD.cbDetails := sizeof(TMIXERCONTROLDETAILS_UNSIGNED);
MCD.paDetails := @mparams.Vals[0];
mixerSetControlDetails(mparams.MixerID,@MCD,
                                        MIXER_SETCONTROLDETAILSF_VALUE or
                                        MIXER_OBJECTF_MIXER);
Result := mparams.Chans;
{$else}
EnterCriticalSection(mparams.mixercall_csection);
try
  for i := 0 to mparams.Chans - 1 do
   if snd_mixer_selem_set_playback_volume(mparams.mixElem, mparams.ChanIDs[i], mparams.Vals[i].dwValue) = 0 then
    Inc(Result)
   else
    Exit;
finally
  LeaveCriticalSection(mparams.mixercall_csection);
end;
{$endif}
end;

function mixerctl_getvolume(out v:single;UpdateBalans:boolean):integer;
var
{$ifdef Windows}
 MCD:TMIXERCONTROLDETAILS;
{$endif}
 MDU:array of TMIXERCONTROLDETAILS_UNSIGNED;
 i,ps:integer;
begin
Result := 1; //todo errorcodes?
if not mparams.Opened or (mparams.Chans = 0) then
 Exit;
{$ifdef Windows}
if mparams.MixerID = MixIDNo then
 Exit;
{$endif}
SetLength(MDU,mparams.Chans);
{$ifdef Windows}
FillChar(MCD,sizeof(TMIXERCONTROLDETAILS),0);
MCD.cbStruct := sizeof(TMIXERCONTROLDETAILS);
MCD.dwControlID := mparams.ControlID;
MCD.cChannels := mparams.Chans;
MCD.cbDetails := sizeof(TMIXERCONTROLDETAILS_UNSIGNED);
MCD.paDetails := @MDU[0];
if mixerGetControlDetails(mparams.MixerID,@MCD,
                               MIXER_GETCONTROLDETAILSF_VALUE or
                               MIXER_OBJECTF_MIXER) = MMSYSERR_NOERROR then
{$else}
ps := 0;
EnterCriticalSection(mparams.mixercall_csection);
try
  for i := 0 to mparams.Chans - 1 do
   if snd_mixer_selem_get_playback_volume(mparams.mixElem,mparams.ChanIDs[i],@MDU[i].dwValue) <> 0 then
    begin
     ps := 1;
     break;
    end;
finally
  LeaveCriticalSection(mparams.mixercall_csection);
end;
if ps = 0 then
{$endif}
 begin
  ps := 0;
  for i := 0 to mparams.Chans - 1 do
   if mparams.Vals[i].dwValue <> MDU[i].dwValue then
    begin
     ps := 1;
     Break;
    end;
  if ps <> 0 then
   begin
    mparams.Pos := mparams.Min;
    for i := 0 to mparams.Chans - 1 do
     begin
      if mparams.Pos < MDU[i].dwValue then
       mparams.Pos := MDU[i].dwValue;
      mparams.Vals[i].dwValue := MDU[i].dwValue;
      if UpdateBalans then
       mparams.Balans[i].dwValue := MDU[i].dwValue;
     end;
   end;
 end
else
 mparams.Pos := mparams.Max;
v := (mparams.Pos - mparams.Min) /
                    (mparams.Max - mparams.Min);
Result := 0;
end;

initialization

mparams.Opened := False;
{$ifdef Windows}
mparams.MixerID := MixIDNo;
{$else}
InitializeCriticalSection(mparams.mixercall_csection);
{$endif}

finalization

{$ifndef Windows}
DeleteCriticalSection(mparams.mixercall_csection);
{$endif}

end.

