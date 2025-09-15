{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit atari;

{$mode objfpc}{$H+}

{ $define debug_savewav}

interface

uses
 Classes, SysUtils, ay, sometypes;

type
 TAtariErrorHandler = procedure(const ErrMes:string);

procedure Atari_Emulate;
procedure Atari_Emulate_One_VBL;
procedure Atari_CheckOuts;
procedure Atari_PrepEmu(AtariSTe:boolean);
procedure Atari_SetDefault;
function Atari_SeekTo(TargetTick:integer):boolean;
procedure Atari_StopEmu;
procedure Atari_Free;
procedure Atari_MixDMASnd(var LevL,LevR:integer);
procedure SynthesizerSNDH;

const
 Atari_MainClockFreqDef = {$ifdef MicroST}32084988{$else}32000000{$endif};

var
 AtariErrorHandler:TAtariErrorHandler = nil;
 SNDHBuffer:TArrayOfByte;
 CurrentSong:integer;
 IntAddr:DWORD = 8;
 Atari_ExecutionError:boolean;
 AyFreq:real; //todo move from ay (microst)
 MainClockFreq,MC68000Freq,MFPFreq,VBLFreq,MCbyMFP:real;
 FrqAyByFrqMC68000:int64;
 VBLPeriod:integer;

implementation

uses
 {$ifdef Dbg}Main,{$endif}
 mc68000, settings{$ifndef MicroST}, Players{$endif};

type
 POuts = ^TOuts;
 TOuts = record
  Reg,Data:byte;
  Odometer:integer;
  Next:POuts;
 end;

var
 STe:boolean;
 AYOuts:POuts = nil;
 MemSize:integer;
 bank0:array of byte;
 DMASnd_PRate:byte;
 DMASnd_Play:boolean = False;
 DMASnd_PLoop,DMASnd_PMono:boolean;
 DMASnd_PStart,DMASnd_PEnd:dword;
 DMASnd_PPos:integer;
 DMASnd_PBase,DMASnd_PCurr:double;
 IntDMASnd:boolean; //todo move from ay (microst)
 {$ifndef MicroST}
 TickCount:integer absolute PlConsts[0].Global_Tick_Counter;
 TickCountMax:integer absolute PlConsts[0].Global_Tick_Max;
 {$endif}
 Seeking:boolean; //todo move from ay (microst)

procedure ShowError(const s:string);
begin
if AtariErrorHandler <> nil then AtariErrorHandler(s);
end;

function IntelDWord(DWrd:dword):dword; inline;
begin
Result := SwapEndian(DWrd);
end;

const
  MinMemSize = $80000; //512 is not enough for several tunes, used 1024 for STe mode
  MaxMemSizeDouble = 3;
  MFPKoefs:array[0..7] of integer = (0,4,10,16,50,64,100,200);

type
 LWPtr = ^longword;
 WPtr = ^word;
 S4 = array[0..3] of char;
 S4Ptr = ^S4;

 PSTMem = ^TSTMem;
 TSTMem = record
  Size:integer;
  Free:boolean;
  Next:PSTMem;
 end;

var
 STMemBeg:integer;
 STMem:TSTMem = (Size:0;Free:False;Next:nil);
 MFP_Registers:record
  case Boolean of
  True:
   (Index:array[0..23] of byte);
  False:
   (MFP_PDR,
    MFP_AER,
    MFP_DIR,
    MFP_IEA,
    MFP_IEB,
    MFP_IPA,
    MFP_IPB,
    MFP_ISA,
    MFP_ISB,
    MFP_IMA,
    MFP_IMB,
    MFP_VCR,
    MFP_TAC,
    MFP_TBC,
    MFP_TDC,
    MFP_TAD,
    MFP_TBD,
    MFP_TCD,
    MFP_TDD,
    MFP_SYC,
    MFP_UCR,
    MFP_RES,
    MFP_TRS,
    MFP_UAD:byte);
 end;

type
 TMFP_DelayTimer = record
  IE,IM:boolean;
  V,DM:byte;
  DR,Cnt,
  Base,Delay,ICnt:integer;
  TxD:PByte; //^TAD|TBD|TCD|TDD
  IPx:PByte; //^IPA|IPB
  ISx:PByte; //^ISA|ISB
  IPSb:byte; //IPR/ISR bit number
 end;

var
 BaseVBL:integer;
 MFP_DTA,MFP_DTB,MFP_DTC,MFP_DTD:TMFP_DelayTimer;
 DMASnd_Ctrl,DMASnd_Mode:byte;
 DMASnd_Start,DMASnd_End:dword;
 MicrowireMask,MicrowireData:word;
 MicrowireShift:integer;

procedure FreeSTMem;
var
 p,p1:PSTMem;
begin
p := STMem.Next;
while p <> nil do
 begin
  p1 := p^.Next;
  Dispose(p);
  p := p1;
 end;
FillChar(STMem,SizeOf(STMem),0);
end;

procedure InitSTMem(MBeg,MEnd:integer);
begin
FreeSTMem;
if MBeg and 1 <> 0 then inc(MBeg);
if MEnd and 1 <> 0 then inc(MEnd);
if MBeg >= MEnd then exit;
STMemBeg := MBeg;
STMem.Size:=MEnd - MBeg;
STMem.Free:=True;
end;

function GetSTMemMax:integer;
var
 p:PSTMem;
begin
p := @STMem;
Result := 0;
repeat
 if p^.Free and (p^.Size > Result) then
  Result := p^.Size;
 p := p^.Next;
until p = nil;
end;

function GetSTMem(MSiz:integer):integer;
var
 p,p1:PSTMem;
begin
if MSiz and 1 <> 0 then inc(MSiz);
Result := STMemBeg;
p := @STMem;
repeat
  if p^.Free and (p^.Size >= MSiz) then
   begin
    p^.Free:=False;
    if p^.Size > MSiz then
     begin
      New(p1);
      p1^.Size:=p^.Size-MSiz;
      p1^.Free:=True;
      p1^.Next:=p^.Next;
      p^.Next:=p1;
      p^.Size:=MSiz;
     end;
    exit;
   end;
  inc(Result,p^.Size);
  p := p^.Next;
until p = nil;
Result := 0;
end;

function FreeSTMem(MAddr:integer):integer;
var
 p,p1:PSTMem;
begin
if MAddr and 1 <> 0 then inc(MAddr);
Result := STMemBeg;
p := @STMem;
p1 := nil;
repeat
 if not p^.Free and (Result = MAddr) then
  begin
   p^.Free:=True;
   if (p1 <> nil) and (p1^.Free) then
    begin
     inc(p1^.Size,p^.Size);
     p1^.Next:=p^.Next;
     Dispose(p);
     p := p1;
    end;
   p1 := p^.Next;
   if (p1 <> nil) and p1^.Free then
    begin
     inc(p^.Size,p1^.Size);
     p^.Next:=p1^.Next;
     Dispose(p1);
    end;
   Result := 0;
   exit;
  end;
 p1 := p;
 inc(Result,p^.Size);
 p := p^.Next;
until p = nil;
Result := -1;
end;

procedure tripOdometer;
var
 Number_Of_Takts:integer;
begin
Number_Of_Takts := s68000readOdometer;
dec(BaseVBL,Number_Of_Takts);
if MFP_DTA.Delay > 0 then
 dec(MFP_DTA.Base,Number_Of_Takts);
if MFP_DTB.Delay > 0 then
 dec(MFP_DTB.Base,Number_Of_Takts);
if MFP_DTC.Delay > 0 then
 dec(MFP_DTC.Base,Number_Of_Takts);
if MFP_DTD.Delay > 0 then
 dec(MFP_DTD.Base,Number_Of_Takts);
if DMASnd_Play then
 begin
  DMASnd_PBase := DMASnd_PBase - Number_Of_Takts;
  DMASnd_PCurr := DMASnd_PCurr - Number_Of_Takts;
 end;
s68000tripOdometer;
end;

procedure Ctrl_DMASnd;
{$ifdef debug_savewav}
var
 f:file;
 i:dword;
{$endif}
begin
DMASnd_PLoop := DMASnd_Ctrl and 2 <> 0;
if (DMASnd_Ctrl and 1 <> 0) and DMASnd_Play then exit;
DMASnd_Play := DMASnd_Ctrl and 1 <> 0;
if DMASnd_Play then
 begin
  DMASnd_PRate := DMASnd_Mode and 3;
  DMASnd_PMono := DMASnd_Mode and 128 <> 0;
  DMASnd_PStart := DMASnd_Start;
  DMASnd_PPos := -1;
  DMASnd_PEnd := DMASnd_End;
  {$ifdef debug_savewav}
  AssignFile(f,ExtractFilePath(ParamStr(0))+'_debugdma_'+IntToHex(DMASnd_PStart,6)+'-'+IntToHex(DMASnd_PEnd,6)+'.wavnoh');
  Rewrite(f,1);
  for i := DMASnd_PStart to DMASnd_PEnd-1 do
   begin
    if i and 1 <> 0 then continue;
    BlockWrite(f,Swap(WPtr(@bank0[i])^),2);
   end;
  CloseFile(f);
  {$endif}
 end;
end;

//call tripOdometer before calling DMASndSkipMC68000Takts !!!
procedure DMASndSkipMC68000Takts;
var
 k:longword;
begin
while DMASnd_Play and (DMASnd_PCurr < 0) do
 begin
  if DMASnd_PMono then
   begin
    k := DMASnd_PStart + trunc((50066 / 8) * (1 shl DMASnd_PRate) * (DMASnd_PCurr - DMASnd_PBase) / MC68000Freq);
    if k >= DMASnd_PEnd then
     begin
      DMASnd_Play := False;
      if DMASnd_PLoop then
       begin
        Ctrl_DMASnd;
//        k := DMASnd_PStart;
        DMASnd_PBase := DMASnd_PCurr;
       end;
     end;
   end
  else
   begin
    k := DMASnd_PStart + (trunc((50066 / 8) * (1 shl DMASnd_PRate) * (DMASnd_PCurr - DMASnd_PBase) / MC68000Freq)) * 2;
    if k >= DMASnd_PEnd then
     begin
      DMASnd_Play := False;
      if DMASnd_PLoop then
       begin
        Ctrl_DMASnd;
//        k := DMASnd_PStart;
        DMASnd_PBase := DMASnd_PCurr;
       end
     end;
   end;
  if DMASnd_Play then
   DMASnd_PCurr := DMASnd_PCurr + 1;
 end;
end;

function ExpandTimerDR(DR:byte):integer; inline;
begin
if DR <> 0 then Result := DR else Result := 256;
end;

function GetMFPDelay(c:byte;d:integer):integer; inline;
begin
Result := trunc(d * MFPKoefs[c] * MCbyMFP);
end;

function CalcTimerCnt(var MFP_DT:TMFP_DelayTimer):byte;
begin
if MFP_DT.DM <> 0 then
 MFP_DT.Cnt := MFP_DT.DR - trunc((integer(s68000readOdometer) - MFP_DT.Base)
                      /(MFPKoefs[MFP_DT.DM]*MCbyMFP)) mod MFP_DT.DR;
Result := MFP_DT.Cnt;
end;

procedure SetTimerDataRegister(var MFP_DT:TMFP_DelayTimer;TDRNew:byte);
begin
MFP_DT.TxD^ := TDRNew;
if MFP_DT.DM = 0 then
 begin
  MFP_DT.DR := ExpandTimerDR(TDRNew);
  MFP_DT.Cnt := MFP_DT.DR;
 end;
end;

procedure SetTimerDelayMode(var MFP_DT:TMFP_DelayTimer;TDMNew:byte);
var
 od:integer;
begin
if TDMNew = 0 then
 begin
  CalcTimerCnt(MFP_DT);
  MFP_DT.Delay := 0;
  MFP_DT.DM := 0;
 end
else if TDMNew <> MFP_DT.DM then
 begin
  od := s68000readOdometer;
  MFP_DT.Delay := GetMFPDelay(TDMNew,MFP_DT.DR);
  if MFP_DT.DM <> 0 then
   MFP_DT.Base := od - trunc((od - MFP_DT.Base) * (MFPKoefs[TDMNew]/MFPKoefs[MFP_DT.DM]))
  else
   MFP_DT.Base := od - GetMFPDelay(TDMNew,MFP_DT.DR - MFP_DT.Cnt);
  MFP_DT.DM := TDMNew;
 end;
end;

procedure SetMFPRegister(Num:integer;Value:byte);
begin
case Num of
0..2,19..23:
  MFP_Registers.Index[Num] := Value;
3:begin
   MFP_DTA.IE := Value and 32 <> 0;
   MFP_DTB.IE := Value and 1 <> 0;
   MFP_Registers.MFP_IEA := Value;
   s68000releaseTimeslice;
  end;
4:begin
   MFP_DTC.IE := Value and 32 <> 0;
   MFP_DTD.IE := Value and 16 <> 0;
   MFP_Registers.MFP_IEB := Value;
   s68000releaseTimeslice;
  end;
5,6:
  MFP_Registers.Index[Num] := MFP_Registers.Index[Num] and Value;
7,8:
  if MFP_Registers.MFP_VCR and 8 <> 0 then
   MFP_Registers.Index[Num] := MFP_Registers.Index[Num] and Value;
9:begin
   MFP_DTA.IM := Value and 32 <> 0;
   MFP_DTB.IM := Value and 1 <> 0;
   MFP_Registers.MFP_IMA := Value;
   s68000releaseTimeslice;
  end;
10:
  begin
   MFP_DTC.IM := Value and 32 <> 0;
   MFP_DTD.IM := Value and 16 <> 0;
   MFP_Registers.MFP_IMB := Value;
   s68000releaseTimeslice;
  end;
11:
  begin
   MFP_Registers.MFP_VCR := Value and $F8;
   if Value and 8 = 0 then
    begin
     MFP_Registers.MFP_ISA := 0;
     MFP_Registers.MFP_ISB := 0;
    end;
  end;
12:
  begin
   SetTimerDelayMode(MFP_DTA,Value and 7);
   MFP_Registers.MFP_TAC := Value;
   s68000releaseTimeslice;
  end;
13:
  begin
   SetTimerDelayMode(MFP_DTB,Value and 7);
   MFP_Registers.MFP_TBC := Value;
   s68000releaseTimeslice;
  end;
14:
  begin
   SetTimerDelayMode(MFP_DTC,Value shr 4 and 7);
   SetTimerDelayMode(MFP_DTD,Value and 7);
   MFP_Registers.MFP_TDC := Value;
   s68000releaseTimeslice;
  end;
15:
  begin
   SetTimerDataRegister(MFP_DTA,Value);
   s68000releaseTimeslice;
  end;
16:
  begin
   SetTimerDataRegister(MFP_DTB,Value);
   s68000releaseTimeslice;
  end;
17:
  begin
   SetTimerDataRegister(MFP_DTC,Value);
   s68000releaseTimeslice;
  end;
18:
  begin
   SetTimerDataRegister(MFP_DTD,Value);
   s68000releaseTimeslice;
  end;
end;
end;

procedure AddOut(Reg,Data:byte);
var
 p:POuts;
 p1:pointer;
begin
p1 := @AYOuts;
p := AYOuts;
while p <> nil do
 begin
  p1 := @p^.Next;
  p := p^.Next;
 end;
new(POuts(p1^));
p := POuts(p1^);
p^.Reg := Reg;
p^.Data := Data;
p^.Odometer:=s68000readOdometer;
p^.Next := nil;
end;

procedure ClearOuts(var p:POuts);
begin
if p = nil then exit;
ClearOuts(p^.Next);
Dispose(p);
p := nil;
end;

function soundchip_readbyte(address:longword):longword;
begin
{$ifndef MicroST}with SoundChip[0] do{$endif}
 if (address and 3 = 0) and (Current_RegisterAY < 16) then
  exit(RegisterAY.Index[Current_RegisterAY]);
Result := 0;
end;

function soundchip_readword(address:longword):longword;
begin
Result := soundchip_readbyte(address) shl 8;
end;

procedure soundchip_writebyte(address,data:longword);
begin
{$ifndef MicroST}with SoundChip[0] do{$endif}
 case address and 3 of
 0:Current_RegisterAY := data and 255;
 2:begin
    if Current_RegisterAY < 14 then
     begin
      if BuffLen >= BufferLength then //s68000releaseTimeslice не прерывает команды с серией выводов
       AddOut(Current_RegisterAY,data)
      else
       begin
        SynthesizerSNDH;
        if BuffLen >= BufferLength then
         s68000releaseTimeslice;
        if not IntFlag then
         SetAYRegister(Current_RegisterAY,data)
        else
         AddOut(Current_RegisterAY,data);
       end;
     end
    else
     SetAYRegister(Current_RegisterAY,data);
   end;
 end;
end;

procedure soundchip_writeword(address,data:longword);
begin
soundchip_writebyte(address,data shr 8);
end;

(*
    ===========#==#=======#===============================================#=====
    $FFFF8900.W|RW|SND_DMA|Sound-DMA-Control           %____RPRP F_EL__EL |F,STE
               |  |       | Timer A after Record/Play-------++|| | ||  || |F
               |  |       | MFP I/O 7 after Record/Play-------++ | ||  || |F
               |  |       | Frame Registers 0:play,1:record------+ ||  || |F
               |  |       | DMA record Enable/Loop-----------------++  || |F
               |  |       | DMA play Enable/Loop-----------------------++ |F,STE
    $FFFF8903.B|RW|SND_FSH|Frame Start Hi                                 |F,STE
    $FFFF8905.B|RW|SND_FSM|Frame Start Mi                                 |F,STE
    $FFFF8907.B|RW|SND_FSL|Frame Start Lo                                 |F,STE
    $FFFF8909.B|RW|SND_FCH|Frame Count Hi                                 |F,STE
    $FFFF890B.B|RW|SND_FCM|Frame Count Mi                                 |F,STE
    $FFFF890D.B|RW|SND_FCL|Frame Count Lo                                 |F,STE
    $FFFF890F.B|RW|SND_FEH|Frame End Hi                                   |F,STE
    $FFFF8911.B|RW|SND_FEM|Frame End Mi                                   |F,STE
    $FFFF8913.B|RW|SND_FEL|Frame End Lo                                   |F,STE
    $FFFF8920.W|RW|SND_SMC|Sound Mode Control          %__SS__PP MB____FF |F,STE
               |  |       | DAC to track %SS--------------++  || ||    || |F
               |  |       | Play %PP+1 tracks-----------------++ ||    || |F
               |  |       | 0:Stereo,0:Mono----------------------+|    || |F
               |  |       | 0:8bit,1:16bit------------------------+    || |F
               |  |       | Falcon:nute------STE: 6258 Hz--------------00 |F,STE
               |  |       | Falcon:12292 Hz--STE:12517 Hz--------------01 |F,STE
               |  |       | Falcon:19668 Hz--STE:25033 Hz--------------10 |F,STE
               |  |       | Falcon:49170 Hz--STE:50066 Hz--------------11 |F,STE
*)

(*
##############DMA Sound System                                     ###########
-------+-----+-----------------------------------------------------+----------
$FF8900|byte |Buffer interrupts                         BIT 3 2 1 0|R/W (F030)
       |     |TimerA-Int at end of record buffer -----------' | | ||
       |     |TimerA-Int at end of replay buffer -------------' | ||
       |     |MFP-15-Int (I7) at end of record buffer ----------' ||
       |     |MFP-15-Int (I7) at end of replay buffer ------------'|
-------+-----+-----------------------------------------------------+----------
$FF8901|byte |DMA Control Register              BIT 7 . 5 4 . . 1 0|R/W
       |     |1 - select record register -----------+   | |     | ||    (F030)
       |     |0 - select replay register -----------'   | |     | ||    (F030)
       |     |Loop record buffer -----------------------' |     | ||    (F030)
       |     |DMA Record on ------------------------------'     | ||    (F030)
       |     |Loop replay buffer -------------------------------' ||     (STe)
       |     |DMA Replay on --------------------------------------'|     (STe)
-------+-----+-----------------------------------------------------+----------
$FF8903|byte |Frame start address (high byte)                      |R/W  (STe)
$FF8905|byte |Frame start address (mid byte)                       |R/W  (STe)
$FF8907|byte |Frame start address (low byte)                       |R/W  (STe)
$FF8909|byte |Frame address counter (high byte)                    |R    (STe)
$FF890B|byte |Frame address counter (mid byte)                     |R    (STe)
$FF890D|byte |Frame address counter (low byte)                     |R    (STe)
$FF890F|byte |Frame end address (high byte)                        |R/W  (STe)
$FF8911|byte |Frame end address (mid byte)                         |R/W  (STe)
$FF8913|byte |Frame end address (low byte)                         |R/W  (STe)
-------+-----+-----------------------------------------------------+----------
$FF8920|byte |DMA Track Control                     BIT 5 4 . . 1 0|R/W (F030)
       |     |00 - Set DAC to Track 0 ------------------+-+     | ||
       |     |01 - Set DAC to Track 1 ------------------+-+     | ||
       |     |10 - Set DAC to Track 2 ------------------+-+     | ||
       |     |11 - Set DAC to Track 3 ------------------+-'     | ||
       |     |00 - Play 1 Track --------------------------------+-+|
       |     |01 - Play 2 Tracks -------------------------------+-+|
       |     |10 - Play 3 Tracks -------------------------------+-+|
       |     |11 - Play 4 Tracks -------------------------------+-'|
-------+-----+-----------------------------------------------------+----------
$FF8921|byte |Sound mode control                BIT 7 6 . . . . 1 0|R/W  (STe)
       |     |0 - Stereo, 1 - Mono -----------------' |         | ||
       |     |0 - 8bit -------------------------------+         | ||
       |     |1 - 16bit (F030 only) ------------------'         | ||    (F030)
       |     |Frequency control bits                            | ||
       |     |00 - Off (F030 only) -----------------------------+-+|    (F030)
       |     |00 - 6258hz frequency (STe only) -----------------+-+|
       |     |01 - 12517hz frequency ---------------------------+-+|
       |     |10 - 25033hz frequency ---------------------------+-+|
       |     |11 - 50066hz frequency ---------------------------+-'|
       |     |Samples are always signed. In stereo mode, data is   |
       |     |arranged in pairs with high pair the left channel,low|
       |     |pair right channel. Sample length MUST be even in    |
       |     |either mono or stereo mode.                          |
       |     |Example: 8 bit Stereo : LRLRLRLRLRLRLRLR             |
       |     |        16 bit Stereo : LLRRLLRRLLRRLLRR (F030)      |
       |     |2 track 16 bit stereo : LLRRllrrLLRRllrr (F030)      |
-------+-----+-----------------------------------------------------+----------
##############STe Microwire Controller (STe/TT only!)              ###########
-------+-----+-----------------------------------------------------+----------
$FF8922|byte |Microwire data register                              |R/W  (Mwr)
$FF8924|byte |Microwire mask register                              |R/W  (Mwr)
       |     +-----------------------------------------------------+
       |     |!! ATTENTION !! Microwire is now obsolete! It is not |
       |     |present in the Falcon030 and is unlikely to be in any|
       |     |future machines. You have been warned.               |
       |     +-----------------------------------------------------+
       |     |Volume/tone controller commands         (Address %10)|
       |     |Master Volume                           10 011 DDDDDD|
       |     |Left Volume                             10 101 .DDDDD|
       |     |Right Volume                            10 100 .DDDDD|
       |     |Treble                                  10 010 ..DDDD|
       |     |Bass                                    10 001 ..DDDD|
       |     |Mixer                                   10 000 ....DD|
       |     +-----------------------------------------------------+
       |     |Volume/tone controller values                        |
       |     |Master Volume     : 0-40   (0 -80dB, 40=0dB)         |
       |     |Left/Right Volume : 0-20    (0 80dB, 20=0dB)         |
       |     |Treble/bass       : 0-12 (0 -12dB, 12 +12dB)         |
       |     |Mixer             : 0-3 (0 -12dB, 1 mix PSG)         |
       |     |                    (2 don't mix,3 reserved)         |
       |     +-----------------------------------------------------+
       |     |Procedure: Set mask register to $7ff. Read data      |
       |     |register and save original value.Write data register.|
       |     |Compare data register with original value, repeat    |
       |     |until data register returns to original value to     |
       |     |ensure data has been sent over the interface.        |
       |     +-----------------------------------------------------+
       |     |Interrupts: Timer A can be set to interrupt at the   |
       |     |end of a frame. Alternatively, the GPI7 (MFP mono    |
       |     |detect) can be used to generate interrupts thereby   |
       |     |freeing up Timer A. In this case, the active edge    |
       |     |$FFFA03 must be set by or-ing the active edge of     |
       |     |$FFFA03 with the contents of $FF8260:                |
       |     |$FF8260 - 2 (mono)     or.b  #$80 with edge          |
       |     |$FF8260 - 0,1 (colour) and.b #$7F with edge          |
       |     |This will generate an interrupt at the START of a    |
       |     |frame, instead of at the end as with Timer A. To     |
       |     |generate an interrupt at the END of a frame, simply  |
       |     |reverse the edge values.                             |
*)

//simulate Microwire serial shifting
procedure MicrowireDummyShift;
begin
if MicrowireShift > 0 then
 begin
  dec(MicrowireShift);
  MicrowireData := (MicrowireData shl 1) or (MicrowireData shr 15);
  MicrowireMask := (MicrowireMask shl 1) or (MicrowireMask shr 15);
 end;
end;

function CalcDmaSndCounter:longword;
var
 k:longword;
begin
 if DMASnd_Play then
  begin
   if DMASnd_PMono then
    k := DMASnd_PEnd
   else
    k := DMASnd_PStart + (DMASnd_PEnd - DMASnd_PStart) div 2;
   Result := trunc((50066 / 8) * (1 shl DMASnd_PRate) * (s68000readOdometer - DMASnd_PBase) / MC68000Freq);
   if DMASnd_PStart + Result < k then
    begin
     if DMASnd_PMono then
      Result := (Result and $FFFFFFFE) + DMASnd_PStart //only even?
     else
      Result := Result*2 + DMASnd_PStart;
    end
   else if not DMASnd_PLoop then
    Result := DMASnd_PEnd
   else if k > DMASnd_PStart then
    begin
     Result := Result mod (k - DMASnd_PStart);;
     if DMASnd_PMono then
      Result := (Result and $FFFFFFFE) + DMASnd_PStart //only even?
     else
      Result := Result*2 + DMASnd_PStart;
    end
   else
    Result := DMASnd_PStart;
  end
 else
  Result := DMASnd_PStart; //todo saving position after stopping dma sound
end;

function stedac_readbyte(address:longword):longword;
var
 s:string;
begin
Result := 0;
s := 'read STE DAC ' + IntToHex(address,6);
if address = $FF8901 then
 Result := DMASnd_Ctrl
else if address = $FF8921 then
 Result := DMASnd_Mode
else if address = $FF8903 then
 Result := DMASnd_Start shr 16
else if address = $FF8905 then
 Result := (DMASnd_Start shr 8) and 255
else if address = $FF8907 then
 Result := DMASnd_Start and 255
else if address = $FF8909 then
 Result := CalcDmaSndCounter shr 16
else if address = $FF890B then
 Result := (CalcDmaSndCounter shr 8) and 255
else if address = $FF890D then
 Result := CalcDmaSndCounter and 255
else if address = $FF890F then
 Result := DMASnd_End shr 16
else if address = $FF8911 then
 Result := (DMASnd_End shr 8) and 255
else if address = $FF8913 then
 Result := DMASnd_End and 255
else if address = $FF8922 then
 begin
  MicrowireDummyShift;
  Result := MicrowireData shr 8;
 end
else if address = $FF8923 then
 Result := MicrowireData and 255
else if address = $FF8924 then
 begin
  MicrowireDummyShift;
  Result := MicrowireMask shr 8;
 end
else if address = $FF8925 then
 Result := MicrowireMask and 255;
 ShowError(s);
end;

function stedac_readword(address:longword):longword;
begin
if address = $FF8922 then
 begin
  MicrowireDummyShift;
  Result := MicrowireData;
  ShowError('Read Microwire Data Register');
 end
else if address = $FF8924 then
 begin
  MicrowireDummyShift;
  Result := MicrowireMask;
  ShowError('Read Microwire Mask Register');
 end
else
 Result := stedac_readbyte(address + 1);
end;

function GetDMAStrs:string;
begin
Result := ' (C:'+IntToHex(DMASnd_Ctrl,2)+',M:'+IntToHex(DMASnd_Mode,2)+
',S:'+IntToHex(DMASnd_Start,6)+',E:'+IntToHex(DMASnd_End,6)+')';
end;

procedure stedac_writebyte(address,data:longword);
var
 s:string;
begin
s := 'write to STE DAC';
if address = $FF8901 then
 begin
  //if DMA playing just store new value
  DMASnd_Ctrl := data and 3; //STe only

  if DMASnd_Play or (data and 1 <> 0) then
   begin
    if BuffLen < BufferLength then
     SynthesizerSNDH;
    if BuffLen >= BufferLength then
     s68000releaseTimeslice;
    if IntFlag then
     begin
      IntDMASnd := True;
      exit;
     end;
   end;

  if data and 1 <> 0 then
   if not DMASnd_Play then
    begin
     DMASnd_PBase := s68000readOdometer;
     DMASnd_PCurr := DMASnd_PBase;
     s68000releaseTimeslice;
    end;
  Ctrl_DMASnd;
 end
else if address = $FF8921 then
 DMASnd_Mode := data and $83 //STe
else if address = $FF8903 then
 DMASnd_Start := (DMASnd_Start and 65535) or (data shl 16)
 //or reset like DMASnd_Start := data shl 16; ? from FAQ:
 //? I set all the registers, but there is no sound at all.
 //! The DMA-Soundsystem expects you to write the high-byte of the Start- and Endaddress first. Even though this serves no purpose at all, writing the highbyte clears the others. Hence it must be written first.
else if address = $FF8905 then
 DMASnd_Start := (DMASnd_Start and $ff00ff) or (data shl 8)
else if address = $FF8907 then
 DMASnd_Start := (DMASnd_Start and $ffff00) or (data and 254) //even
else if address = $FF890F then
 DMASnd_End := (DMASnd_End and 65535) or (data shl 16)
else if address = $FF8911 then
 DMASnd_End := (DMASnd_End and $ff00ff) or (data shl 8)
else if address = $FF8913 then
 DMASnd_End := (DMASnd_End and $ffff00) or (data and 254) //even
else if address = $FF8922 then
 MicrowireData := (MicrowireData and 255) or (data shl 8)
else if address = $FF8923 then
 begin
  MicrowireShift := 16;
  MicrowireData := (MicrowireData and $FF00) or (data and 255);
 end
else if address = $FF8924 then
 MicrowireMask := (MicrowireMask and 255) or (data shl 8)
else if address = $FF8925 then
 MicrowireMask := (MicrowireMask and $FF00) or (data and 255)
{$IFDEF Dbg}
else
 s := 'Unkn DMA write '+IntToHex(address,6)+','+IntToHex(data,2)
{$ENDIF Dbg}
;
ShowError(s + GetDMAStrs);
end;

procedure stedac_writeword(address,data:longword);
begin
if address = $FF8922 then
 begin
  MicrowireShift := 16;
  MicrowireData := data;
  ShowError('Write Microwire Data Register');
 end
else if address = $FF8924 then
 begin
  MicrowireMask := data;
  ShowError('Write Microwire Mask Register');
 end
else
 stedac_writebyte(address + 1,data and 255);
end;

function mfp_readbyte(address:longword):longword;
var
 i:integer;
begin
Result := 0;
if address and 1 = 0 then exit;
i := (address - $FFFA01) div 2;
case i of
15:
  Result := CalcTimerCnt(MFP_DTA);
16:
  Result := CalcTimerCnt(MFP_DTB);
17:
  Result := CalcTimerCnt(MFP_DTC);
18:
  Result := CalcTimerCnt(MFP_DTD);
else
 Result := MFP_Registers.Index[i];
end;
end;

function mfp_readword(address:longword):longword;
begin
Result := mfp_readbyte(address + 1);
end;

procedure mfp_writebyte(address,data:longword);
begin
if address and 1 = 0 then exit;
SetMFPRegister((address - $FFFA01) div 2,data);
end;

procedure mfp_writeword(address,data:longword);
begin
mfp_writebyte(address + 1,data and 255);
end;

procedure trap_writebyte(address,data:longword);
var
 sp,p:longword;
 n:word;
 Mes:string;
begin
sp := Swap(LWPtr(@bank0[$11FC])^);
if (sp = 0) then exit;
Mes := 'trap #'+IntToStr(byte(data))+' was raised';
try
  if byte(data) <> 1 then exit;
  if sp > longword(MemSize) - 12 then exit;
  n := WPtr(@bank0[sp+6])^; p := Swap(LWPtr(@bank0[sp+8])^);
  Mes := Mes + ', n=$' + IntToHex(n,4) + ', p=$' + IntToHex(p,8);
  if (n = $48) or (n = $44) then //GEMDOS Malloc (48) and Mxalloc (44, dummy but works, todo better ;) )
   begin
    if p = $FFFFFFFF then
     p := GetSTMemMax
    else
     p := GetSTMem(p);
    LWPtr(@bank0[$11FC])^ := Swap(p);
   end
  else if n = $49 then //GEMDOS Mfree
   begin
    p := FreeSTMem(p);
    LWPtr(@bank0[$11FC])^ := Swap(p);
   end
  else if n = $30 then //GEMDOS Sversion
   begin
    p := $1300; //todo: since 0.19 can be Mxalloc
    LWPtr(@bank0[$11FC])^ := Swap(p);
   end;
finally
  ShowError(Mes);
end;
end;

const
  pretend_programfetch:array[0..1] of TSTARSCREAM_PROGRAMREGION  =
   ((lowaddr:$000000;highaddr:0{MemSize-1};offset:nil{@bank0}),
    (lowaddr:longword(-1);highaddr:longword(-1);offset:nil));
var
 pretend_readbyte,pretend_readword,
 pretend_writebyte,pretend_writeword:array of TSTARSCREAM_DATAREGION;
(*  MaxRgn = 4;
  pretend_readbyte:array[0..MaxRgn] of TSTARSCREAM_DATAREGION =
   ((lowaddr:$000000;highaddr:0{MemSize-1};memorycall:nil;userdata:nil{@bank0}),
    (lowaddr:$FF8800;highaddr:$FF88FF;memorycall:@soundchip_readbyte;userdata:nil),
    (lowaddr:$FFFA00;highaddr:$FFFA2F;memorycall:@mfp_readbyte;userdata:nil),
    (lowaddr:$FF8900;highaddr:$FF8921{FF};memorycall:@stedac_readbyte;userdata:nil),
    (lowaddr:longword(-1);highaddr:longword(-1);memorycall:nil;userdata:nil));
  pretend_readword:array[0..MaxRgn] of TSTARSCREAM_DATAREGION =
   ((lowaddr:$000000;highaddr:0{MemSize-1};memorycall:nil;userdata:nil{@bank0}),
    (lowaddr:$FF8800;highaddr:$FF88FF;memorycall:@soundchip_readword;userdata:nil),
    (lowaddr:$FFFA00;highaddr:$FFFA2F;memorycall:@mfp_readword;userdata:nil),
    (lowaddr:$FF8900;highaddr:$FF89FF;memorycall:@stedac_readword;userdata:nil),
    (lowaddr:longword(-1);highaddr:longword(-1);memorycall:nil;userdata:nil));
  pretend_writebyte:array[0..MaxRgn+1] of TSTARSCREAM_DATAREGION =
   ((lowaddr:$000000;highaddr:0{MemSize-1};memorycall:nil;userdata:nil{@bank0}),
    (lowaddr:$FF8800;highaddr:$FF88FF;memorycall:@soundchip_writebyte;userdata:nil),
    (lowaddr:$FFFA00;highaddr:$FFFA2F;memorycall:@mfp_writebyte;userdata:nil),
    (lowaddr:$FF8900;highaddr:$FF89FF;memorycall:@stedac_writebyte;userdata:nil),
    (lowaddr:$FFFF00;highaddr:$FFFF01;memorycall:@trap_writebyte;userdata:nil), //dummy area for emulating some trap functions
    (lowaddr:longword(-1);highaddr:longword(-1);memorycall:nil;userdata:nil));
  pretend_writeword:array[0..MaxRgn] of TSTARSCREAM_DATAREGION =
   ((lowaddr:$000000;highaddr:0{MemSize-1};memorycall:nil;userdata:nil{@bank0}),
    (lowaddr:$FF8800;highaddr:$FF88FF;memorycall:@soundchip_writeword;userdata:nil),
    (lowaddr:$FFFA00;highaddr:$FFFA2F;memorycall:@mfp_writeword;userdata:nil),
    (lowaddr:$FF8900;highaddr:$FF89FF;memorycall:@stedac_writeword;userdata:nil),
    (lowaddr:longword(-1);highaddr:longword(-1);memorycall:nil;userdata:nil));*)

procedure IntelizeMemory;
var
 i:integer;
begin
i := 0;
while i < MemSize do
 begin
  PWord(@bank0[i])^ := Swap(PWord(@bank0[i])^);
  inc(i,2);
 end;
end;

procedure Init68000Context;

 procedure SetDataRegion(var SSDR:TSTARSCREAM_DATAREGION;lowaddr,highaddr:longword;memorycall,userdata:pointer);
 begin
  SSDR.lowaddr:=lowaddr;
  SSDR.highaddr:=highaddr;
  SSDR.memorycall:=memorycall;
  SSDR.userdata:=userdata;
 end;

var
 Rgn:integer;
begin
FillChar(s68000context,s68000GetContextSize,0);

pretend_programfetch[0].highaddr:=MemSize-1;
pretend_programfetch[0].offset:=@bank0[0];
s68000context.s_fetch := @pretend_programfetch;
s68000context.u_fetch := @pretend_programfetch;

if STe then Rgn := 5 else Rgn := 4;

SetLength(pretend_readbyte,Rgn);
SetDataRegion(pretend_readbyte[Rgn-1],longword(-1),longword(-1),nil,nil);
if STe then SetDataRegion(pretend_readbyte[Rgn-2],$FF8900,$FF89FF,@stedac_readbyte,nil);
SetDataRegion(pretend_readbyte[2],$FFFA00,$FFFA2F,@mfp_readbyte,nil);
SetDataRegion(pretend_readbyte[1],$FF8800,$FF88FF,@soundchip_readbyte,nil);
SetDataRegion(pretend_readbyte[0],0,MemSize-1,nil,@bank0[0]);
s68000context.s_readbyte := @pretend_readbyte[0];
s68000context.u_readbyte := @pretend_readbyte[0];

SetLength(pretend_readword,Rgn);
SetDataRegion(pretend_readword[Rgn-1],longword(-1),longword(-1),nil,nil);
if STe then SetDataRegion(pretend_readword[Rgn-2],$FF8900,$FF89FF,@stedac_readword,nil);
SetDataRegion(pretend_readword[2],$FFFA00,$FFFA2F,@mfp_readword,nil);
SetDataRegion(pretend_readword[1],$FF8800,$FF88FF,@soundchip_readword,nil);
SetDataRegion(pretend_readword[0],0,MemSize-1,nil,@bank0[0]);
s68000context.s_readword := @pretend_readword[0];
s68000context.u_readword := @pretend_readword[0];

SetLength(pretend_writebyte,Rgn+1);
SetDataRegion(pretend_writebyte[Rgn],longword(-1),longword(-1),nil,nil);
SetDataRegion(pretend_writebyte[Rgn-1],$FFFF00,$FFFF01,@trap_writebyte,nil); //dummy area for emulating some trap functions
if STe then SetDataRegion(pretend_writebyte[Rgn-2],$FF8900,$FF89FF,@stedac_writebyte,nil);
SetDataRegion(pretend_writebyte[2],$FFFA00,$FFFA2F,@mfp_writebyte,nil);
SetDataRegion(pretend_writebyte[1],$FF8800,$FF88FF,@soundchip_writebyte,nil);
SetDataRegion(pretend_writebyte[0],0,MemSize-1,nil,@bank0[0]);
s68000context.s_writebyte := @pretend_writebyte[0];
s68000context.u_writebyte := @pretend_writebyte[0];

SetLength(pretend_writeword,Rgn);
SetDataRegion(pretend_writeword[Rgn-1],longword(-1),longword(-1),nil,nil);
if STe then SetDataRegion(pretend_writeword[Rgn-2],$FF8900,$FF89FF,@stedac_writeword,nil);
SetDataRegion(pretend_writeword[2],$FFFA00,$FFFA2F,@mfp_writeword,nil);
SetDataRegion(pretend_writeword[1],$FF8800,$FF88FF,@soundchip_writeword,nil);
SetDataRegion(pretend_writeword[0],0,MemSize-1,nil,@bank0[0]);
s68000context.s_writeword := @pretend_writeword[0];
s68000context.u_writeword := @pretend_writeword[0];
end;

procedure Atari_PrepMem;
const
 RTE = $1076; //address of RTE instruction
 PrgStart = $2000; //start address
var
 l:integer;
 {$IFDEF Dbg}
 f:file;
 {$ENDIF Dbg}
begin
MemSize := MinMemSize; l := MaxMemSizeDouble;
if STe then
 begin
  MemSize := MemSize shl 1;
  dec(l);
 end;
for l := 1 to l do
 begin
  if MemSize >= PrgStart+$3000+Length(SNDHBuffer) then break;
  MemSize := MemSize shl 1;
 end;
SetLength(bank0,MemSize);
Init68000Context;
FillChar(bank0[0],MemSize,0);
for l := 0 to $380 div 4 do
 LWPtr(@bank0[l*4])^ := IntelDWord(RTE); //todo: "normal" vector table

LWPtr(@bank0[0])^ := IntelDWord(MemSize); //Stack
LWPtr(@bank0[4])^ := IntelDWord(PrgStart); //PC

LWPtr(@bank0[$070])^ := IntelDWord(RTE); //VBL Handler(!Vxx)
LWPtr(@bank0[$084])^ := IntelDWord($1200); //TRAP #1 emulation
LWPtr(@bank0[$110])^ := IntelDWord(RTE); //MFP Timer D
LWPtr(@bank0[$114])^ := IntelDWord(RTE); //MFP Timer C
LWPtr(@bank0[$120])^ := IntelDWord(RTE); //MFP Timer B
LWPtr(@bank0[$134])^ := IntelDWord(RTE); //MFP Timer A
WPtr(@bank0[$448])^ := $0100; //<>0 => PAL (50 Hz)
WPtr(@bank0[$452])^ := $0100; //Disable execution of VBL routines
WPtr(@bank0[$454])^ := $0800; //Number of VBL routines
LWPtr(@bank0[$456])^ := IntelDWord($04CE); //Pointer to list of VBL routines
{//"FillChared"
LWPtr(@bank0[$4CE])^ := 0; //1st VBL routine
LWPtr(@bank0[$4D2])^ := 0; //2nd VBL routine
LWPtr(@bank0[$4D6])^ := 0; //3rd VBL routine
LWPtr(@bank0[$4DA])^ := 0; //4th VBL routine
LWPtr(@bank0[$4DE])^ := 0; //5th VBL routine
LWPtr(@bank0[$4E2])^ := 0; //6th VBL routine
LWPtr(@bank0[$4E6])^ := 0; //7th VBL routine
LWPtr(@bank0[$4EA])^ := 0; //8th VBL routine
}
//LPtr(@bank0[$7150])^ := 0; //Timer routine disabled

LWPtr(@bank0[$0FF6])^ := IntelDWord(IntAddr+PrgStart+$1000);

{case PlayGen of
GenVBL:}
 begin
  VBLFreq := {$ifndef MicroST}Interrupt_Freq/1000{$else}PlayFreq{$endif};
  VBLPeriod := round (MC68000Freq / VBLFreq);
  LWPtr(@bank0[$070])^ := IntelDWord($1000); //VBL Handler(!Vxx)
  if VBLFreq <> 50 then WPtr(@bank0[$448])^ := 0;
  WPtr(@bank0[$452])^ := 0; //Enable execution of VBL routines
 end;
{GenTC:
 begin
  LPtr(@bank0[$114])^ := IntelDWord($1100); //MFP Timer C Handle (TCxx)
  l := round(MFPFreq / PlayFreq);
  i := 7;
  repeat
   j := l div MFPKoefs[i];
   if (j - 1) in [0..255] then break;
   dec(i)
  until i = 0;
  j := j and 255;
  TimerC_Delay := GetMFPDelay(i,j);
  MFP_Registers.MFP_TCD := j;
  MFP_Registers.MFP_TDC := i shl 4;
  TimerC_IE := True;
  MFP_Registers.MFP_IEB := 32;
  TimerC_IM := True;
  MFP_Registers.MFP_IMB := 32;
 end;
end;}

//VBL interrupt handler
//Sorry for my bad MC68000 assembler :(
LWPtr(@bank0[$1000])^ := IntelDWord($48E7FFFE); {MOVEM.L D0-A6,-(A7)}
LWPtr(@bank0[$1004])^ := IntelDWord($207C0000); {MOVE.L #$000452,A0}
WPtr(@bank0[$1008])^ := $5204;
LWPtr(@bank0[$100A])^ := IntelDWord($0C500000); {CMPI.W 0,(A0)}
LWPtr(@bank0[$100E])^ := IntelDWord($66000062); {BNE.W VBL_EXEC_DISABLED}
LWPtr(@bank0[$1012])^ := IntelDWord($207C0000); {MOVE.L #$000454,A0}
WPtr(@bank0[$1016])^ := $5404;
LWPtr(@bank0[$1018])^ := IntelDWord($4C900001); {MOVEM.W (A0),D0}
LWPtr(@bank0[$101C])^ := IntelDWord($207C0000); {MOVE.L #$000FFE,A0}
WPtr(@bank0[$1020])^ := $FE0F;
LWPtr(@bank0[$1022])^ := IntelDWord($48900001); {MOVEM.W D0,(A0)}
LWPtr(@bank0[$1026])^ := IntelDWord($207C0000); {MOVE.L #$000456,A0}
WPtr(@bank0[$102A])^ := $5604;
LWPtr(@bank0[$102C])^ := IntelDWord($4CD00001); {MOVEM.L (A0),D0}
LWPtr(@bank0[$1030])^ := IntelDWord($207C0000); {MOVE.L #$000FFA,A0}
WPtr(@bank0[$1034])^ := $FA0F;
LWPtr(@bank0[$1036])^ := IntelDWord($48D00001); {MOVEM.L D0,(A0)}
{VBLoop:}
LWPtr(@bank0[$103A])^ := IntelDWord($207C0000); {MOVE.L #$000ffe,A0}
WPtr(@bank0[$103E])^ := $FE0F;
LWPtr(@bank0[$1040])^ := IntelDWord($0C500000); {CMPI.W 0,(A0)}
LWPtr(@bank0[$1044])^ := IntelDWord($6700002C); {BEQ.W VBL_EXEC_DISABLED}
LWPtr(@bank0[$1048])^ := IntelDWord($04500001); {SUBI.W 1,(A0)}
LWPtr(@bank0[$104C])^ := IntelDWord($207C0000); {MOVE.L #$000FFA,A0}
WPtr(@bank0[$1050])^ := $FA0F;
LWPtr(@bank0[$1052])^ := IntelDWord($4CD00001); {MOVEM.L (A0),D0}
LWPtr(@bank0[$1056])^ := IntelDWord($06900000); {ADDI.L 4,(A0)}
WPtr(@bank0[$105A])^ := $0400;
WPtr(@bank0[$105C])^ := $4020;                  {MOVEA.L D0,A0}
LWPtr(@bank0[$105E])^ := IntelDWord($0C900000); {CMPI.L 0,(A0)}
WPtr(@bank0[$1062])^ := $0000;
LWPtr(@bank0[$1064])^ := IntelDWord($6700FFD4); {BEQ.W VBLoop}
LWPtr(@bank0[$1068])^ := IntelDWord($4CD00100); {MOVEM.L (A0),A0}
WPtr(@bank0[$106C])^ := $904E;                  {JSR (A0)}
LWPtr(@bank0[$106E])^ := IntelDWord($6000FFCA); {BRA.W VBLoop}
{VBL_EXEC_DISABLED:}
LWPtr(@bank0[$1072])^ := IntelDWord($4CDF7FFF); {MOVEM.L (A7)+,D0-A6}
WPtr(@bank0[$1076])^ := $734E;                  {RTE}

(*//Timer interrupt handler
LWPtr(@bank0[$1100])^ := IntelDWord($48E7FFFE); {MOVEM.L D0-A6,-(A7)}
LWPtr(@bank0[$1104])^ := IntelDWord($207C0000); {MOVE.L #$007150,A0}
WPtr(@bank0[$1108])^ := $5071;
LWPtr(@bank0[$110A])^ := IntelDWord($0C900000); {CMPI.L 0,(A0)}
WPtr(@bank0[$110E])^ := $0000;
LWPtr(@bank0[$1110])^ := IntelDWord($67000008); {BEQ.W TIMER_EXEC_DISABLED}
LWPtr(@bank0[$1114])^ := IntelDWord($4CD00100); {MOVEM.L (A0),A0}
WPtr(@bank0[$1118])^ := $904E;                  {JSR (A0)}
{TIMER_EXEC_DISABLED:}
LWPtr(@bank0[$111A])^ := IntelDWord($4CDF7FFF); {MOVEM.L (A7)+,D0-A6}
WPtr(@bank0[$111E])^ := $734E;                  {RTE}*)

//TRAP #1 emulation
//LWPtr(@bank0[$11FC])^ := 0; //"fillchared"
LWPtr(@bank0[$1200])^ := IntelDWord($21CF11FC); {move.l a7,($11fc)}
LWPtr(@bank0[$1204])^ := IntelDWord($13FC0001); {MOVE.B #1,($FFFF00)}
LWPtr(@bank0[$1208])^ := IntelDWord($00FFFF00);
LWPtr(@bank0[$120C])^ := IntelDWord($203811FC); {move.l ($11fc),d0}
LWPtr(@bank0[$1210])^ := IntelDWord($21FC0000); {move.l #0,($11fc)}
LWPtr(@bank0[$1214])^ := IntelDWord($000011fc);
WPtr(@bank0[$1218])^ := $734E;                  {RTE}


LWPtr(@bank0[$5A0])^ := IntelDWord($1500); //pointer to Cookie Jar
S4Ptr(@bank0[$1500])^ := '_CPU';
//FillChared //0 - MC68000
S4Ptr(@bank0[$1508])^ := '_SND';
if STe then
 l := 3 //YM+DMASound
else
 l := 1; //YM
LWPtr(@bank0[$150C])^ := IntelDWord(l);
S4Ptr(@bank0[$1510])^ := '_MCH';
if STe then
 l := $10000 //Atari STe
else
 l := 0; //Atari ST
LWPtr(@bank0[$1514])^ := IntelDWord(l);
//0 FillChared

(*
4e2f0e //move.l a6,-(sp)
13fc000100ffffff //move.b #1,($ffffff)
11fc00011000 //move.b #1,($1000)
23cf00ffffff //move.l sp,($ffffff)
23cf00ffffff //move.l a7,($ffffff)
21cf1000 //move.l sp,($1000)
21cf1000 //move.l a7,($1000)
21c01000 //move.l d0,($1000)
23c000ffffff //move.l d0,($ffffff)
20381000 //move.l ($1000),d0
203900ffffff //move.l ($ffffff),d0
23fc0000000000ffffff // move.l #0,($ffffff)
21fc000000001000 // move.l #0,($1000)
*)

//Start point
LWPtr(@bank0[PrgStart])^ := IntelDWord($61000FFE); {BSR.W SND + 0}
LWPtr(@bank0[PrgStart+4])^ := IntelDWord($207C0000); {MOVE.L #$000FF6,A0}
WPtr(@bank0[PrgStart+8])^ := $F60F;
LWPtr(@bank0[PrgStart+$A])^ := IntelDWord($4CD00001); {MOVEM.L (A0),D0}
LWPtr(@bank0[PrgStart+$E])^ := IntelDWord($207C0000); {MOVE.L #$00xxxx,A0}
{case PlayGen of
GenVBL: //xxxx = 04CE}
 WPtr(@bank0[PrgStart+$12])^ := $CE04;
{GenTA..GenTD: //xxxx = 7150
 WPtr(@bank0[PrgStart+$12])^ := $5071;
end;}
LWPtr(@bank0[PrgStart+$14])^ := IntelDWord($48D00001); {MOVEM.L D0,(A0)}
{Loop:}
//LWPtr(@bank0[PrgStart+$18])^ := IntelDWord($4E722300); {STOP #2300}
LWPtr(@bank0[PrgStart+$18])^ := IntelDWord($4E722000); {STOP #2000}
LWPtr(@bank0[PrgStart+$1C])^ := IntelDWord($6000FFFA); {BRA.W Loop}

l := Length(SNDHBuffer);
if l > MemSize - PrgStart - $3000 then
 begin
  {$IFDEF Dbg}
  DbgStr(#9'Too big UnpackedSize size: ' + IntToStr(l));
  {$ENDIF Dbg}
  l := MemSize - PrgStart - $3000;
 end;
Move(SNDHBuffer[0],bank0[PrgStart+$1000],l);

InitSTMem(PrgStart+l+$2000,MemSize - $1000);

{$IFDEF Dbg}
AssignFile(f,ExtractFilePath(ParamStr(0))+'_allmem.bin');
Rewrite(f,1);
BlockWrite(f,bank0[0],MemSize);
CloseFile(f);
{$ENDIF Dbg}

IntelizeMemory;

end;

procedure Atari_InitEmu;
begin

TickCount := 0;
Real_End_All := False;

ClearOuts(AYOuts);

FillChar(MFP_DTA,SizeOf(MFP_DTA),0);
FillChar(MFP_DTB,SizeOf(MFP_DTB),0);
FillChar(MFP_DTC,SizeOf(MFP_DTC),0);
FillChar(MFP_DTD,SizeOf(MFP_DTD),0);

MFP_DTA.DR := 256;
MFP_DTB.DR := 256;
MFP_DTC.DR := 256;
MFP_DTD.DR := 256;

MFP_DTA.Cnt := 256;
MFP_DTB.Cnt := 256;
MFP_DTC.Cnt := 256;
MFP_DTD.Cnt := 256;

MFP_DTA.V := 13;
MFP_DTB.V := 8;
MFP_DTC.V := 5;
MFP_DTD.V := 4;

MFP_DTA.TxD := @MFP_Registers.MFP_TAD;
MFP_DTB.TxD := @MFP_Registers.MFP_TBD;
MFP_DTC.TxD := @MFP_Registers.MFP_TCD;
MFP_DTD.TxD := @MFP_Registers.MFP_TDD;

MFP_DTA.IPx := @MFP_Registers.MFP_IPA;
MFP_DTB.IPx := @MFP_Registers.MFP_IPA;
MFP_DTC.IPx := @MFP_Registers.MFP_IPB;
MFP_DTD.IPx := @MFP_Registers.MFP_IPB;

MFP_DTA.ISx := @MFP_Registers.MFP_ISA;
MFP_DTB.ISx := @MFP_Registers.MFP_ISA;
MFP_DTC.ISx := @MFP_Registers.MFP_ISB;
MFP_DTD.ISx := @MFP_Registers.MFP_ISB;

MFP_DTA.IPSb := 32;
MFP_DTB.IPSb := 1;
MFP_DTC.IPSb := 32;
MFP_DTD.IPSb := 16;

FillChar(MFP_Registers,SizeOf(MFP_Registers),0);
MFP_Registers.MFP_VCR := $40;

DMASnd_Ctrl := 0;
DMASnd_Mode := 0;
DMASnd_Start := 0;
DMASnd_End := 0;
DMASnd_Play := False;
MicrowireMask := 0;
MicrowireData := 0;
MicrowireShift := 0;

if s68000reset <> 0 then
 begin
  ShowError('Reset fault/MC68KEmuLib');
  exit;
 end;

Atari_ExecutionError := False;
BaseVBL := 0;
DMASnd_PBase := 0;
DMASnd_PCurr := 0;
IntDMASnd := False;
end;

procedure Atari_PrepEmu(AtariSTe:boolean);
begin
STe := AtariSTe;
Atari_PrepMem;
Atari_InitEmu;
s68000context.dreg[0] := CurrentSong;
//s68000context.dreg[1] := $1000;
{$ifdef MicroST}
InitAYEmu;
{$else}
ResetAYChipEmulation(0,True); //в InitForAllTypes есть, но в Atari_SeekTo нет
{$endif}
Seeking := False;
end;

function EmulateTimer(od:integer;var MFP_DT:TMFP_DelayTimer):integer;
begin
Result := -1;
if MFP_DT.ICnt > 0 then
 begin
  if not MFP_DT.IE or not MFP_DT.IM then
   MFP_DT.ICnt := 0
  else if s68000interrupt(6,MFP_Registers.MFP_VCR and $F0 or MFP_DT.V) = 0 then
   begin
    dec(MFP_DT.ICnt);
    if (MFP_DT.ICnt = 0) and (MFP_Registers.MFP_VCR and 8 = 0) then
     begin
      MFP_DT.IPx^ := MFP_DT.IPx^ and not MFP_DT.IPSb;
      MFP_DT.ISx^ := MFP_DT.ISx^ and not MFP_DT.IPSb;
     end;
   end;
 end;
if MFP_DT.Delay > 0 then
 begin
  if od - MFP_DT.Base >= MFP_DT.Delay then
   begin
    if MFP_DT.IE then
     begin
      MFP_DT.IPx^ := MFP_DT.IPx^ or MFP_DT.IPSb;
      if MFP_DT.IM then
       begin
        if MFP_Registers.MFP_VCR and 8 <> 0 then //software end-of-interrupt mode
         MFP_DT.ISx^ := MFP_DT.ISx^ or MFP_DT.IPSb;
        if s68000interrupt(6,MFP_Registers.MFP_VCR and $F0 or MFP_DT.V) = 0 then
         begin
          if MFP_Registers.MFP_VCR and 8 = 0 then //automatic end-of-interrupt mode
           begin
            MFP_DT.IPx^ := MFP_DT.IPx^ and not MFP_DT.IPSb;
            MFP_DT.ISx^ := MFP_DT.ISx^ and not MFP_DT.IPSb;
           end;
         end
        else
         inc(MFP_DT.ICnt);
       end;
     end;
    inc(MFP_DT.Base,MFP_DT.Delay);
    MFP_DT.DR := ExpandTimerDR(MFP_DT.TxD^);
    MFP_DT.Delay := GetMFPDelay(MFP_DT.DM,MFP_DT.DR);
   end;
  Result := MFP_DT.Base + MFP_DT.Delay - od;
  if Result <= 0 then Result := 1;
 end;

end;

//var
// cnt:int64=0;

procedure Atari_Emulate;
var
 min,od,i:integer;
 dma:boolean;
// f:double;
begin
try
  od := s68000readOdometer;
  if (od - BaseVBL >= VBLPeriod) and ((s68000interrupt(4,-1) = 0) or
     (od - BaseVBL >= VBLPeriod + VBLPeriod div 10)) then //todo разобраться, что делать с пропущенными прерываниями
   begin
    inc(BaseVBL,VBLPeriod);
    inc(TickCount);
    if not Do_Loop then
     if TickCount >= TickCountMax then
      Real_End_All := True;
   end;
  min := BaseVBL + VBLPeriod - od;
  if min <= 0 then
   min := 1;
  i := EmulateTimer(od,MFP_DTA);
  if (i > 0) and (min > i) then
   min := i;
  i := EmulateTimer(od,MFP_DTB);
  if (i > 0) and (min > i) then
   min := i;
  i := EmulateTimer(od,MFP_DTC);
  if (i > 0) and (min > i) then
   min := i;
  i := EmulateTimer(od,MFP_DTD);
  if (i > 0) and (min > i) then
   min := i;
  dma := False;
  if DMASnd_Play then //todo do faster during seeking
   begin
//    DMASnd_PCurr
    i := trunc(MC68000Freq/((50066 / 8) * (1 shl DMASnd_PRate)));// - (od - DMASnd_PBase));
(*    f := AYFreq/8/((50066 / 8) * (1 shl DMASnd_PRate)){ + 1};
    i := trunc(f)+ord(frac(f)<>0);
    i := trunc(i*MC68000Freq*8/AYFreq - (od - DMASnd_PBase));
    if i <= 0 then
     i := 1;*)
    if min > i then
     min := i;
    dma := true;
   end;

//    while s68000readPC <> $53de do
 //    s68000exec(1);
(*        repeat
         od := s68000readOdometer;
         if {(s68000readPC = $53ee) or} (s68000readPC = $553e) then
          begin
           //breakpoint ;)
           ShowMessage('Open Console to work in interactive MC68000 debugger (Ctrl+Alt+O in Lazarus) or restart from Console.'+#13+
            'In Console type ? to help or q to quit.');
           while cpudebug_interactive(1,nil,nil,nil,nil) <> -1 do ;
          end;
         i := s68000exec(1);
         if longword(i) <> $80000000 then break;
         dec(min,s68000readOdometer-od);
        until min <=0;
*)
{    repeat
     od := s68000readOdometer;
     inc(cnt); if cnt = 27828 then
      cnt := 27828; //breakpoint ;)
     i := s68000exec(1);
     if longword(i) <> $80000000 then break;
     dec(min,s68000readOdometer-od);
    until min <=0;}

    i := s68000exec(min);
    if longword(i) <> $80000000 then
     begin
      Atari_ExecutionError := True;
      ShowError('Exec fault, error #' + IntToHex(i,8) + '/MC68KEmuLib');
     end;

    if (BuffLen < BufferLength) and dma then //todo и вообще может подумать, чтобы все проверки проходили на входе в SynthesizerSNDH
                                            //ведь на стыке буферов может dma исказиться
     SynthesizerSNDH;

except
  Atari_ExecutionError := True;
  ShowError('MC68KLibEmu exception PC='+IntToHex(s68000readPC,8){+' Cnt='+IntToStr(cnt)});
end;
end;

procedure Atari_Emulate_One_VBL;
var
 i:integer;
begin
//todo пока сделано лишь бы работало
BuffLen := 0;
Seeking := True;
IntFlag := False;
Atari_CheckOuts;
while not Real_End_All do
 begin
  i := PlConsts[0].Global_Tick_Counter;
  Atari_Emulate;
  s68000readOdometer;
  if i <> PlConsts[0].Global_Tick_Counter then
   break;
  if Atari_ExecutionError then
   begin
    //todo
    break;
   end;
  if (s68000readOdometer >= 150000) or Real_End_All then
   SynthesizerSNDH;
 end;
Seeking := False;
end;

procedure Atari_CheckOuts;
var
 p:POuts;
begin
  p := AYOuts;
  while p <> nil do
   begin
    {$ifndef MicroST}SoundChip[0].{$endif}SetAYRegister(p^.Reg,p^.Data);
    p := p^.Next;
   end;
  ClearOuts(AYOuts);
  if IntDMASnd then
   begin
    IntDMASnd := False;
    if DMASnd_Ctrl and 1 <> 0 then
     if not DMASnd_Play then
      begin
       DMASnd_PBase := s68000readOdometer;
       DMASnd_PCurr := DMASnd_PBase;
      end;
    Ctrl_DMASnd;
   end;
end;

procedure Atari_SetDefault;
begin
MainClockFreq := Atari_MainClockFreqDef;
AyFreq := Atari_MainClockFreqDef / 16;
MC68000Freq := Atari_MainClockFreqDef / 4;
MFPFreq := Atari_MainClockFreqDef / 13;
VBLFreq := 50.052;
VBLPeriod := round (MC68000Freq / VBLFreq);
FrqAyByFrqMC68000 := round(AyFreq/MC68000Freq/8*4294967296);
Delay_In_Tiks := round(8192/SampleRate*AyFreq);
MCbyMFP := MC68000Freq/MFPFreq;
end;

function Atari_SeekTo(TargetTick:integer):boolean;
begin
if TargetTick < TickCount then
 Atari_PrepEmu(STe)
else
 Atari_CheckOuts;
IntFlag := False;
BuffLen := 0; //todo внутри эмуляции есть проверки BuffLen < и т.п. - подумать
Seeking := True;
while not Atari_ExecutionError and (TickCount < TargetTick) and
      not Real_End_All do
 begin
  Atari_Emulate;
  if Atari_ExecutionError then
   exit(False);
  tripOdometer;
  DMASndSkipMC68000Takts;
 end;
Seeking := False;
Number_Of_Tiks.re := 0;
Result := True;
end;

procedure Atari_StopEmu;
begin
ClearOuts(AYOuts);
FreeSTMem;
DMASnd_Play := False;
end;

procedure Atari_Free;
begin
Atari_StopEmu;
SNDHBuffer := nil;
bank0 := nil;
MemSize := 0;
end;

var
 prevl,prevr:integer;

procedure Atari_MixDMASnd(var LevL,LevR:integer);
var
 k:integer;
begin
if DMASnd_Play then
 begin
  if DMASnd_PMono then
   begin
    k := DMASnd_PStart + trunc((50066 / 8) * (1 shl DMASnd_PRate) * (DMASnd_PCurr - DMASnd_PBase) / MC68000Freq);
    if k <> DMASnd_PPos then
     begin
      DMASnd_PPos := k;
      if longword(k) >= DMASnd_PEnd then
       begin
        DMASnd_Play := False;
        if DMASnd_PLoop then
         begin
          Ctrl_DMASnd;
          k := DMASnd_PStart;
          DMASnd_PBase := DMASnd_PCurr;
         end;
       end;
      if DMASnd_Play then
       begin
        k := k xor 1; //emulated memory is word swapped
        if k < MemSize then
         prevl := shortint(bank0[k])* Atari_DMALevel div 128;
       end;
     end;
    inc(LevL,prevl);
    inc(LevR,prevl);
   end
  else
   begin
    k := DMASnd_PStart + (trunc((50066 / 8) * (1 shl DMASnd_PRate) * (DMASnd_PCurr - DMASnd_PBase) / MC68000Freq)) * 2;
    if k <> DMASnd_PPos then
     begin
      DMASnd_PPos := k;
      if longword(k) >= DMASnd_PEnd then
       begin
        DMASnd_Play := False;
        if DMASnd_PLoop then
         begin
          Ctrl_DMASnd;
          k := DMASnd_PStart;
          DMASnd_PBase := DMASnd_PCurr;
         end
       end;
      if DMASnd_Play then
       begin
        //emulated memory is word swapped
        if k + 1 < MemSize then
         prevl := shortint(bank0[k + 1]) * Atari_DMALevel div 128;
        if k < MemSize then
         prevr := shortint(bank0[k]) * Atari_DMALevel div 128;
       end;
     end;
    inc(LevL,prevl);
    inc(LevR,prevr);
   end;
  if DMASnd_Play then
   DMASnd_PCurr := DMASnd_PCurr + MC68000Freq*8/AYFreq;
 end;
end;

procedure SynthesizerSNDH;
var
 N_Of_Tiks:packed record
     case boolean of
      False:(lo:longword;
             hi:longword);
      True: (re:int64);
     end;
 Number_Of_Takts:integer;
begin
if not IntFlag then
 begin
  Number_Of_Takts := s68000readOdometer;
  N_Of_Tiks.Re := Number_Of_Tiks.Re + Number_Of_Takts * FrqAyByFrqMC68000;
  if N_Of_Tiks.hi = 0 then exit;
  tripOdometer;
  Number_Of_Tiks.Re := N_Of_Tiks.Re;
  if Seeking then
   begin
    DMASndSkipMC68000Takts;
    Number_Of_Tiks.hi := 0;
    exit;
   end;
 end
else
 IntFlag := False;
{$ifdef MicroST}
Synthesizer_Stereo16;
{$else}
Synthesizer(BufP);
{$endif}
end;

end.

