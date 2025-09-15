{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit Convs;

{$mode objfpc}{$H+}

interface

uses
 basscode, basslight;

//DestDir need for silent mode (no asking user for file name and destination folder)
//Result = False if user or error aborted conversion proccess
function WAV_Converter(Silent: boolean; const DestDir: string): boolean;

//If Silent=True, init EncoderOptions[Enc] before calling (at least .Enc and .GroupOperation)
//If Silent=True, don't asking user for file name and don't calling tag editor
//If Silent=True and .GroupOperation=False, tag editor will be called, then
//.GroupOperation is became True to don't call Tag Editor next time
function BASS_Converter(Silent: boolean; const DestDir: string; Enc: TBASSEnc): boolean;

function PSG_Converter(Silent: boolean; const DestDir: string): boolean;
function VTX_Converter(Silent: boolean; const DestDir: string): boolean;
function YM6_Converter(Silent: boolean; const DestDir: string): boolean;
function ZXAY_Converter(Silent: boolean; const DestDir: string): boolean;
function CPToUTF8(const s: string): string;
function UTF8ToCP(const s: string): string;
function GarbageDecoder(const s: string): string;
function ASCII(const s: string): boolean;
{$IFDEF Windows}
function IfAnsiToUTF8(const s: string): string;
{$ENDIF  Windows}

var
 //initial default and last encoding user selected options to reuse next time
 EncoderOptions: array[Succ(Low(TBASSEnc))..High(TBASSEnc)] of
 TEncoderOptions = ((Enc: tbeMP3; GroupOperation: False; FileName: '';
   UseAuthor: False; UseTitle: False; UseComment: False; UseDate: False;
   TagAuthor: ''; TagTitle: ''; TagComment: ''; TagDate: '';
   BitRate: 0; Quality: -1; VBR: -1; CustomKeys: '--id3v2-only'), (Enc: tbeOGG;
   GroupOperation: False; FileName: '';
   UseAuthor: False; UseTitle: False; UseComment: False; UseDate: False;
   TagAuthor: ''; TagTitle: ''; TagComment: ''; TagDate: '';
   BitRate: 0; Quality: -1; VBR: -1; CustomKeys: ''), (Enc: tbeFLAC;
   GroupOperation: False; FileName: '';
   UseAuthor: False; UseTitle: False; UseComment: False; UseDate: False;
   TagAuthor: ''; TagTitle: ''; TagComment: ''; TagDate: '';
   BitRate: 0; Quality: -1; VBR: -1; CustomKeys: ''), (Enc: tbeOPUS;
   GroupOperation: False; FileName: '';
   UseAuthor: False; UseTitle: False; UseComment: False; UseDate: False;
   TagAuthor: ''; TagTitle: ''; TagComment: ''; TagDate: '';
   BitRate: 0; Quality: -1; VBR: -1; CustomKeys: ''));

implementation

uses
 LCLIntf, LazUtf8, UniReader, MainWin, AY, Z80, PlayList, SysUtils,
 Lh5, HeadEdit, Controls, StdCtrls, Forms, Players, LConvEncoding, winversion,
 FileTypes, settings, sometypes, EncOptsEdit;

const
 WriteBufferLen = 32768;

type
 PWriteBuffer = ^TWriteBuffer;
 TWriteBuffer = packed array[0..WriteBufferLen - 1] of byte;

const

 //Comment for VTX and YM6-files creating
 YMCommentLen = 52;

type
 NTString52 = array[0..YMCommentLen] of char;

const
 YMComment: NTString52 = 'Created by Sergey Bulba''s AY-3-8910/12 Emulator v' +
   VersionString + #0;

var
 //Wave-file header
 WaveFileHeader: record
   rId: array[0..3] of char;
   rLen: longint;
   wId: array[0..3] of char;
   fId: array[0..3] of char;
   fLen: longint;
   wFormatTag: word;
   nChannels: word;
   nSamplesPerSec: longint;
   nAvgBytesPerSec: longint;
   nBlockAlign: word;
   FormatSpecific: word;
   dId: array[0..3] of char;
   dLen: longint;
   end
 = (rId: 'RIFF'; rLen: 0; wId: 'WAVE'; fId: 'fmt '; fLen: 16; wFormatTag: 1;
 nChannels: 2; nSamplesPerSec: 44100; nAvgBytesPerSec: 176400;
 nBlockAlign: 4; FormatSpecific: 16; dId: 'data'; dlen: 0);

 //note: for PT3.7 TS-format we are forced to play both "submodules" concurrently
 //so we need all twice (buffer, output files, vars, etc)
 //so, two buffers to save TurboSound AY-registers streams to separate files
 WBuf: array[0..1] of PWriteBuffer;
 WPos: array[0..1] of integer;
 WFile: array[0..1] of file;
 WCnt: integer; //number of alocated buffers

procedure WriteBufferInit(const FN: string; n: integer);
begin
 New(WBuf[n]);
 AssignFile(WFile[n], FN);
 Rewrite(WFile[n], 1);
 WPos[n] := 0;
 Inc(WCnt);
end;

procedure WriteBufferInit(const FN: string; const FN2: string = '');
begin
 WCnt := 0;
 WriteBufferInit(FN, 0);
 if FN2 <> '' then WriteBufferInit(FN2, 1);
end;

procedure WriteBufferFlush(n: integer);
begin
 if WPos[n] <> 0 then
  begin
   BlockWrite(WFile[n], WBuf[n]^, WPos[n]);
   WPos[n] := 0;
  end;
end;

procedure WriteBufferDW(l: DWORD; n: integer = 0);
begin
 if WPos[n] > WriteBufferLen - 4 then
   WriteBufferFlush(n);
 PDWord(@WBuf[n]^[WPos[n]])^ := l;
 Inc(WPos[n], 4);
end;

procedure WriteBufferB(b: byte; n: integer = 0);
begin
 if WPos[n] >= WriteBufferLen - 1 then
   WriteBufferFlush(n);
 WBuf[n]^[WPos[n]] := b;
 Inc(WPos[n]);
end;

procedure WriteBufferBuf(p: pointer; sz: integer; n: integer = 0);
begin
 if WPos[n] >= WriteBufferLen - sz then
  begin
   WriteBufferFlush(n);
   BlockWrite(WFile[n], p^, sz);
  end
 else
  begin
   Move(p^, WBuf[n]^[WPos[n]], sz);
   Inc(WPos[n], sz);
  end;
end;

procedure WriteBufferClose;
begin
 WriteBufferFlush(0);
 CloseFile(WFile[0]);
 Dispose(WBuf[0]);
 if WCnt > 1 then
  begin
   WriteBufferFlush(1);
   CloseFile(WFile[1]);
   Dispose(WBuf[1]);
  end;
end;

procedure VTX_Header_Editor(var Hdr: TVTXFileHeader;
 var Title, Author, Programm, Tracker: string);
begin
 with THeaderEditor.Create(FrmMain) do
  begin
   FrAy := Hdr.ChipFrq;
   FrInt := Hdr.InterFrq;
   ChipChk[0] := (Hdr.Id = $7961);
   ChipChk[1] := not ChipChk[0];
   LoopPos := Hdr.Loop;
   NumOfPos := Hdr.UnpackSize div 14;
   SongName := Title;
   SongAuthor := Author;
   SongProgram := Programm;
   SongTracker := Tracker;
   ChanMode := 1;
   Year := Hdr.Year;
   SetParams;
    try
     ShowModal;
     if ModalResult = mrOk then
      begin
       GetParams;
       Hdr.ChipFrq := FrAy;
       Hdr.InterFrq := FrInt;
       if ChipChk[0] then
         Hdr.Id := $7961
       else
         Hdr.Id := $6d79;
       Hdr.Loop := LoopPos;
       Hdr.Mode := ChanMode;
       Hdr.Year := Year;
       Title := SongName;
       Author := SongAuthor;
       Programm := SongProgram;
       Tracker := SongTracker;
      end;
    finally
     Free;
    end;
  end;
end;

procedure YM6_Header_Editor(var Hdr: TYM5FileHeader; var Title, Author: string);
begin
 with THeaderEditor.Create(FrmMain) do
  begin
   FrAy := Hdr.ChipFrq;
   FrInt := Hdr.InterFrq;
   ChipChk[0] := False;
   ChipChk[1] := True;
   LoopPos := Hdr.Loop;
   NumOfPos := Hdr.Num_of_tiks;
   SongName := Title;
   SongAuthor := Author;
   SongProgram := '';
   SongTracker := '';
   cbChanAlloc.Enabled := False;
   ChTypeBox.Enabled := False;
   ChanMode := 0;
   Year := 0;
   Edit11.Enabled := False;
   Edit12.Enabled := False;
   Edit13.Enabled := False;
   SetParams;
    try
     ShowModal;
     if ModalResult = mrOk then
      begin
       GetParams;
       Hdr.ChipFrq := FrAy;
       Hdr.InterFrq := FrInt;
       Hdr.Loop := LoopPos;
       Title := SongName;
       Author := SongAuthor;
      end;
    finally
     Free;
    end;
  end;
end;

procedure BASS_Encoder_Options_Editor(var Ops: TEncoderOptions);
begin
 with TFrmEncOptsEditor.Create(FrmMain) do
  begin
    try
     OpsInitial := @Ops;
     ShowModal;
     if ModalResult = mrOk then
       Ops := OpsFilled;
    finally
     Free;
    end;
  end;
end;

function ZXAY_Converter(Silent: boolean; const DestDir: string): boolean;
var
 New_Takt: longword;

 procedure OUT2ZXAY;
 var
   Number_Of_Takts: smallint;
   ZX_Takt, ZX_Takt2: smallint;
   ZX_Port: word;
   ZX_Port_Data: byte;
 begin
   while not May_Quit and (UniReadersData[FileHandle]^.UniFilePos <=
       UniReadersData[FileHandle]^.UniFileSize - 5) do
    begin
     UniRead(FileHandle, @ZX_Takt, 2);
     UniRead(FileHandle, @ZX_Port, 2);
     UniRead(FileHandle, @ZX_Port_Data, 1);
     if ZX_Takt = -1 then
       ZX_Takt2 := 0
     else
       ZX_Takt2 := ZX_Takt;
     Number_Of_Takts := ZX_Takt2 - Previous_AY_Takt;
     Previous_AY_Takt := ZX_Takt2;
     if Number_Of_Takts <= 0 then Inc(Number_Of_Takts, 17472);
     Inc(New_Takt, Number_Of_Takts);
     if (ZX_Takt <> -1) and ((ZX_Port and PortMask) = ($BFFD and PortMask)) then
       case SoundChip[0].Current_RegisterAY of
         1, 3, 5, 13:
           ZX_Port_Data := ZX_Port_Data and 15;
         6, 8..10:
           ZX_Port_Data := ZX_Port_Data and 31;
         7:
           ZX_Port_Data := ZX_Port_Data and 63;
        end;
     if New_Takt >= $100000 then
      begin
       New_Takt := New_Takt and $0fffff;
       if (New_Takt <> 0) or ((New_Takt = 0) and (ZX_Takt >= 0) and
         ((ZX_Port and PortMask) <> ($BFFD and PortMask))) or
         ((New_Takt = 0) and (ZX_Takt >= 0) and
         ((ZX_Port and PortMask) = ($BFFD and PortMask)) and
         (SoundChip[0].Current_RegisterAY >= 14)) or
         ((New_Takt = 0) and (ZX_Takt = -1)) or
         ((New_Takt = 0) and (ZX_Takt >= 0) and
         ((ZX_Port and PortMask) = ($BFFD and PortMask)) and
         (SoundChip[0].Current_RegisterAY < 13) and
         (SoundChip[0].RegisterAY.Index[SoundChip[0].Current_RegisterAY] =
         ZX_Port_Data)) then
         WriteBufferDW($FFF00000);
      end;
     if (ZX_Takt >= 0) then
       if (ZX_Port and PortMask) = ($FFFD and PortMask) then
         SoundChip[0].Current_RegisterAY := ZX_Port_Data
       else if ((ZX_Port and PortMask) = ($BFFD and PortMask)) and
         (SoundChip[0].Current_RegisterAY < 14) and
         ((SoundChip[0].Current_RegisterAY = 13) or
         (SoundChip[0].RegisterAY.Index[SoundChip[0].Current_RegisterAY] <>
         ZX_Port_Data)) then
        begin
         SoundChip[0].RegisterAY.Index[SoundChip[0].Current_RegisterAY] := ZX_Port_Data;
         WriteBufferDW(New_Takt or (longword(SoundChip[0].Current_RegisterAY) shl 20) or
           (longword(ZX_Port_Data) shl 24));
        end;
     if UniReadersData[FileHandle]^.UniFilePos and $FFF = 0 then
      begin
       ShowProgress(UniReadersData[FileHandle]^.UniFilePos);
       Application.ProcessMessages;
      end;
    end;
 end;

 procedure EPSG2ZXAY;
 var
   Temp3: integer;
   EPSGRec: packed record
   case boolean of
     True: (Reg, Data: byte;
       TSt: integer);
     False: (All: int64);
    end;
 begin
   EPSGRec.All := 0;
   Temp3 := -1;
   while not May_Quit and (UniReadersData[FileHandle]^.UniFilePos <=
       UniReadersData[FileHandle]^.UniFileSize - 5) do
    begin
     UniRead(FileHandle, @EPSGRec, 5);
     with EPSGRec do
       if All = $FFFFFFFFFF then
        begin
         Inc(New_Takt, EPSG_TStateMax - Previous_AY_Takt);
         Previous_AY_Takt := 0;
         if New_Takt >= $100000 then
          begin
           New_Takt := New_Takt and $FFFFF;
           if New_Takt <> 0 then
            begin
             WriteBufferDW($FFF00000);
             Temp3 := 0;
            end;
          end;
        end
       else
        begin
         case Reg of
           1, 3, 5, 13:
             Data := Data and 15;
           6, 8..10:
             Data := Data and 31;
           7:
             Data := Data and 63
          end;
         Inc(New_Takt, TSt - Previous_AY_Takt);
         Previous_AY_Takt := TSt;
         if New_Takt >= $100000 then
          begin
           New_Takt := New_Takt and $FFFFF;
           if (New_Takt <> 0) or ((New_Takt = 0) and
             ((Reg > 13) or ((Reg < 13) and
             (SoundChip[0].RegisterAY.Index[Reg] = Data)))) then
            begin
             WriteBufferDW($FFF00000);
             Temp3 := 0;
            end;
          end;
         if (Reg = 13) or ((Reg < 13) and
           (SoundChip[0].RegisterAY.Index[Reg] <> Data)) then
          begin
           SoundChip[0].RegisterAY.Index[Reg] := Data;
           WriteBufferDW(New_Takt or (longword(Reg) shl 20) or
             (longword(Data) shl 24));
           Temp3 := New_Takt;
          end;
        end;
     if UniReadersData[FileHandle]^.UniFilePos and $FFF = 0 then
      begin
       ShowProgress(UniReadersData[FileHandle]^.UniFilePos);
       Application.ProcessMessages;
      end;
    end;
   if (Temp3 <> -1) and (longword(Temp3) <> New_Takt) then
     WriteBufferDW(New_Takt or (longword(SoundChip[0].RegisterAY.Index[0]) shl 24));
 end;

 procedure AY2ZXAY;
 var
   Temp3: integer;
 begin
   OutProc := @OutInitialConverter;
   repeat
     WasOuting := -1;
     Temp3 := CurrentTact;
     Z80_Step;
     Inc(New_Takt, CurrentTact - Temp3);
     if New_Takt >= $100000 then
      begin
       New_Takt := New_Takt and $0fffff;
       if (New_Takt <> 0) or (WasOuting < 0) then
         WriteBufferDW($FFF00000);
      end;
     if WasOuting >= 0 then
       WriteBufferDW(New_Takt or (longword(WasOuting) shl 20) or
         (longword(SoundChip[0].RegisterAY.Index[WasOuting]) shl 24));
     if CurrentTact >= MaxTStates then
      begin
       Dec(CurrentTact, MaxTStates);
       Inc(PlConsts[0].Global_Tick_Counter);
       if PlConsts[0].Global_Tick_Counter and 63 = 0 then
        begin
         ShowProgress(PlConsts[0].Global_Tick_Counter);
         Application.ProcessMessages;
        end;
      end;
   until (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) or May_Quit;
   if (New_Takt <> 0) and (WasOuting < 0) then
     WriteBufferDW(New_Takt or (longword(SoundChip[0].RegisterAY.Index[0]) shl 24));
 end;

var
 Dir, FN, Exten: string;
 DirType: TDirType;
begin
 Result := True; //user canceled or critical error flag

 //file types allowed to be converted to ZXAY
 if (CurFileType <> FT.OUT) and (CurFileType <> FT.EPSG) and
   (CurFileType <> FT.AY) and (CurFileType <> FT.AYM) then
   Exit;

 if not FrmPLst.GetVarsForSave(PlayingItem, FT.ZXAY, Silent, DestDir,
   Dir, DirType, FN, Exten) then
   //no room for file name or user canceled
   Exit(False);

 if FrmMain.CanSetFocus then
   FrmMain.SetFocus;
 WriteBufferInit(FN);
 InitForAllTypes(True);
 New_Takt := 0;
  try
   LongProcessPrepare;
   WriteBufferDW($5941585A);
   if IsZ80EmuFileType(CurFileType) then
     ProgrMax := PlConsts[0].Global_Tick_Max
   else
     ProgrMax := UniReadersData[FileHandle]^.UniFileSize;
   if CurFileType = FT.OUT then
     OUT2ZXAY
   else if CurFileType = FT.EPSG then
     EPSG2ZXAY
   else if IsZ80EmuFileType(CurFileType) then
     AY2ZXAY;
   Result := not May_Quit;
  finally
   LongProcessDone;
   WriteBufferClose;
  end;
 ShowProgress(ProgrMax);
end;

function WAV_Converter(Silent: boolean; const DestDir: string): boolean;
var
 DirType: TDirType;
 FileOut: file;
 Dir, FN, Exten: string;
 LoopTemp: boolean;
 WBuf: TWriteBuffer;
 BufLenTemp: integer;
begin
 Result := True; //user canceled or critical error flag

 if IsStreamOrModuleFileType(CurFileType) or IsCDFileType(CurFileType) or
   IsMIDIFileType(CurFileType) then
   Exit;

 if not FrmPLst.GetVarsForSave(PlayingItem, GetFileType('WAV'), Silent,
   DestDir, Dir, DirType, FN, Exten) then
   //no room for file name or user canceled
   Exit(False);

 LongProcessPrepare;

 AssignFile(FileOut, FN);
 Rewrite(FileOut, 1);
  try
   Seek(FileOut, SizeOf(WaveFileHeader));
   InitForAllTypes(True);
   with WaveFileHeader do
    begin
     nChannels := NumberOfChannels;
     nSamplesPerSec := SampleRate;
     nBlockAlign := (SampleBit div 8) * NumberOfChannels;
     nAvgBytesPerSec := SampleRate * nBlockAlign;
     FormatSpecific := SampleBit;
     BufLenTemp := BufferLength;
     BufferLength := WriteBufferLen div nBlockAlign;
    end;
   ProgrMax := Trunc(Time_ms / 1000 * SampleRate + 0.5);
   ShowProgress(VProgrPos);
   LoopTemp := Do_Loop;
   Do_Loop := False;
   repeat
     MakeBuffer(@WBuf);
     Inc(VProgrPos, BuffLen);
     BlockWrite(FileOut, WBuf, BuffLen * WaveFileHeader.nBlockAlign);
     ShowProgress(VProgrPos);
     Application.ProcessMessages;
   until May_Quit or Real_End_All;
   Result := Real_End_All and not May_Quit;
   Do_Loop := LoopTemp;
   BufferLength := BufLenTemp;
   Seek(FileOut, 0);
   WaveFileHeader.rlen := sizeof(WaveFileHeader) + VProgrPos *
     WaveFileHeader.nBlockAlign;
   WaveFileHeader.dlen := VProgrPos * WaveFileHeader.nBlockAlign;
   BlockWrite(FileOut, WaveFileHeader, sizeof(WaveFileHeader));
  finally
   LongProcessDone;
   CloseFile(FileOut);
  end;
 ShowProgress(ProgrMax);
end;

function BASS_Converter(Silent: boolean; const DestDir: string; Enc: TBASSEnc): boolean;

 procedure SetTags;
 begin
   with EncoderOptions[Enc] do
    begin
     TagAuthor := PlaylistItems[PlayingItem]^.Author;
     TagTitle := PlaylistItems[PlayingItem]^.Title;
     TagComment := PlaylistItems[PlayingItem]^.Comment;
     TagDate := PlaylistItems[PlayingItem]^.Date;
    end;
 end;

var
 DirType: TDirType;
 Dir, FN, Exten: string;
 LoopTemp: boolean;
 WBuf: TWriteBuffer;
 FT: integer;
 AllowTagEditor: boolean;
begin
 Result := True; //user canceled or critical error flag

 if Enc = tbeMain then //assert
   Exit;

 if IsStreamOrModuleFileType(CurFileType) or IsCDFileType(CurFileType) or
   IsMIDIFileType(CurFileType) then
   Exit;

 case Enc of
   tbeMP3: FT := GetFileType('MP3');
   tbeOGG: FT := GetFileType('OGG');
   tbeFLAC: FT := GetFileType('FLAC');
   tbeOPUS: FT := GetFileType('OPUS');
 else
   Exit(False);
  end;

 if not FrmPLst.GetVarsForSave(PlayingItem, FT, Silent, DestDir, Dir,
   DirType, FN, Exten) then
   //no room for file name or user canceled
   Exit(False);

 with EncoderOptions[Enc] do
  begin
   EncoderOptions[Enc].FileName := FN;
   if not Silent then
     //prepare tags for tags and options editor
     SetTags;
   AllowTagEditor := not Silent or not GroupOperation;
   GroupOperation := Silent;
   if AllowTagEditor then
     //if previously manually edited tags, set to use all (for tag editor)
    begin
     UseAuthor := True;
     UseTitle := True;
     UseComment := True;
     UseDate := True;
     if Silent then
       //example strings for options preview
      begin
       TagAuthor := '<auto>';
       TagTitle := '<auto>';
       TagComment := '<auto>';
       case Enc of
         tbeMP3: TagDate := '1';
         tbeOGG, tbeFLAC: TagDate := '<auto>';
         tbeOPUS: TagDate := '0001-01-01';
        end;
      end;
     BASS_Encoder_Options_Editor(EncoderOptions[Enc]);
    end;
   if Silent then
     //auto fill tags
     SetTags;
  end;


 LoadBASS([Enc]);

  try
   LongProcessPrepare;
   InitForAllTypes(True);
   ProgrMax := Trunc(Time_ms / 1000 * SampleRate + 0.5);
   ShowProgress(VProgrPos);
   LoopTemp := Do_Loop;
   Do_Loop := False;

   EncInitBASS(EncoderOptions[Enc]);
    try
     while not May_Quit and EncodeBASS(@WBuf, SizeOf(WBuf)) do
      begin
       Inc(VProgrPos, BuffLen);
       ShowProgress(VProgrPos);
       Application.ProcessMessages;
      end;
     Result := not May_Quit;
    finally
     EncDoneBASS;
    end;
   Do_Loop := LoopTemp;
  finally
   LongProcessDone;
   UnloadBASS; //todo external to call once for group ops
  end;
 ShowProgress(ProgrMax);
end;

function PSG_Converter(Silent: boolean; const DestDir: string): boolean;
var
 Prev_Regs: array[0..1, 0..13] of integer;
 FF_Counter: array[0..1] of integer;
 pos: longword;
const
 PSG: array[0..15] of byte =
   ($50, $53, $47, $1a, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

 procedure Psg_Save_Ostatok(n: integer = 0);
 var
   j: dword;
 begin
   if FF_Counter[n] > 0 then
    begin
     j := FF_Counter[n] div 4;
     if j > 0 then
      begin
       while j > 255 do
        begin
         Dec(j, 255);
         WriteBufferB($FE, n);
         WriteBufferB($FF, n);
        end;
       if j > 0 then
        begin
         WriteBufferB($FE, n);
         WriteBufferB(j, n);
        end;
      end;
     for j := 1 to FF_Counter[n] mod 4 do
       WriteBufferB($FF, n);
     FF_Counter[n] := 0;
    end;
 end;

 procedure PSG_Save_Registers(n: integer = 0);
 var
   i: word;
 begin
   Inc(FF_Counter[n]);
   for i := 0 to 13 do
     if Prev_Regs[n, i] <> SoundChip[n].RegisterAY.Index[i] then
      begin
       Psg_Save_Ostatok(n);
       Prev_Regs[n, i] := SoundChip[n].RegisterAY.Index[i];
       WriteBufferB(i, n);
       WriteBufferB(SoundChip[n].RegisterAY.Index[i], n);
      end;
   Prev_Regs[n, 13] := 255;
   SoundChip[n].RegisterAY.EnvType := 255;
 end;

 procedure OUT2PSG;
 begin
   OUTZXAYConv_TotalTime := IntOffset;
   ProgrMax := round((Time_ms / 1000) * (FrqZ80 / MaxTStates));
   pos := 0;
   repeat
     OUT_Get_Registers(0);
     if pos < ProgrMax then PSG_Save_Registers;
     Inc(pos);
     if (pos and 63) = 0 then
      begin
       ShowProgress(pos);
       Application.ProcessMessages;
      end
   until May_Quit or (pos >= ProgrMax);
   PSG_Save_Ostatok;
 end;

 procedure ZXAY2PSG;
 begin
   OUTZXAYConv_TotalTime := IntOffset;
   ProgrMax := round((Time_ms / 1000) * (FrqZ80 / MaxTStates));
   pos := 0;
   repeat
     ZXAY_Get_Registers(0);
     if pos < ProgrMax then PSG_Save_Registers;
     Inc(pos);
     if (pos and 63) = 0 then
      begin
       ShowProgress(pos);
       Application.ProcessMessages;
      end
   until May_Quit or (pos >= ProgrMax);
   PSG_Save_Ostatok;
 end;

 procedure EPSG2PSG;
 begin
   ProgrMax := round((Time_ms / 1000) * (FrqZ80 / EPSG_TStateMax));
   pos := 0;
   repeat
     EPSG_Get_Registers(0);
     if pos < ProgrMax then PSG_Save_Registers;
     Inc(pos);
     if (pos and 63) = 0 then
      begin
       ShowProgress(pos);
       Application.ProcessMessages;
      end
   until May_Quit or (pos >= ProgrMax);
   PSG_Save_Ostatok;
 end;

 procedure VBL2PSG;
 var
   nMax: integer;
 begin
   if TSMode and (PlConsts[1].Global_Tick_Max > PlConsts[0].Global_Tick_Max) then
     nMax := 1
   else
     nMax := 0;
   ProgrMax := PlConsts[nMax].Global_Tick_Max;
   repeat
     All_GetRegisters[0](0);
     if not Real_End[0] or Force_Loop then
       //if forced loop then continue save registers
       //(need for TS modules of different time length)
       PSG_Save_Registers;
     if TSMode then
      begin
       All_GetRegisters[1](1);
       if not Real_End[1] or Force_Loop then
         PSG_Save_Registers(1);
      end;
     if (PlConsts[nMax].Global_Tick_Counter and 63) = 0 then
      begin
       ShowProgress(PlConsts[nMax].Global_Tick_Counter);
       Application.ProcessMessages;
      end;
   until (PlConsts[nMax].Global_Tick_Counter >=
       PlConsts[nMax].Global_Tick_Max) or May_Quit;
   PSG_Save_Ostatok;
   if TSMode then
     PSG_Save_Ostatok(1);
 end;

var
 Loop_Save, FNIdent: boolean;
 Dir, FN, FN2, Exten: string;
 DirType: TDirType;
 c, i: integer;
begin
 Result := True; //user canceled or critical error flag

 //file types not allowed to be converted to PSG
 if IsStreamOrModuleFileType(CurFileType) or IsCDFileType(CurFileType) or
   IsMIDIFileType(CurFileType) or (CurFileType = FT.PSG) then
   Exit;

 if not FrmPLst.GetVarsForSave(PlayingItem, FT.PSG, Silent, DestDir,
   Dir, DirType, FN, Exten, TSMode) then
   //no room for file name or user canceled
   Exit(False);

 if TSMode then
  begin
   FN2 := GetTSFileName(FN, 2);
   FN := GetTSFileName(FN, 1);
  end
 else
   FN2 := '';

 Loop_Save := Do_Loop;
 Do_Loop := False;
 InitForAllTypes(True);
 for c := 0 to 1 do
  begin
   for i := 0 to 12 do
     Prev_Regs[c, i] := -1;
   Prev_Regs[c, 13] := 255;
   SoundChip[c].RegisterAY.EnvType := 255;
  end;
 OutProc := @OutInitialConverter;
 FNIdent :=
   {$ifdef Windows}
   //todo не учтено короткое/не короткое имя
   UTF8LowerCase(PlaylistItems[PlayingItem]^.FileName) = UTF8LowerCase(FN);
 {$else}
   PlaylistItems[PlayingItem]^.FileName = FN;
 {$endif}
 if (CurFileType = FT.EPSG) and FNIdent then
   WriteBufferInit('Temp8910.$$$')
 else
   WriteBufferInit(FN, FN2);
 FF_Counter[0] := 0;
 if TSMode then
   FF_Counter[1] := 0;
 LongProcessPrepare;
  try
   WriteBufferBuf(@PSG, 16);
   if TSMode then
     WriteBufferBuf(@PSG, 16, 1);
   if CurFileType = FT.OUT then
     OUT2PSG
   else if CurFileType = FT.ZXAY then
     ZXAY2PSG
   else if CurFileType = FT.EPSG then
     EPSG2PSG
   else
     VBL2PSG;
   Result := not May_Quit;
  finally
   LongProcessDone;
   WriteBufferClose;
  end;
 if (CurFileType = FT.EPSG) and FNIdent then
  begin
   UniReadClose(FileHandle);
   DeleteFile(FN);
   RenameFile('Temp8910.$$$', FN);
   UniReadInit(FileHandle, URFile, FN, nil, -1);
   CurFileType := FT.PSG;
   MakeBuffer := @MakeBufferPSG;
   All_GetRegisters[0] := @PSG_Get_Registers;
   PlaylistItems[PlayingItem]^.Time := pos;
   PlaylistItems[PlayingItem]^.FileType := CurFileType;
   RedrawItem(PlayingItem);
  end;
 Do_Loop := Loop_Save;
 ShowProgress(ProgrMax);
end;

function VTX_Converter(Silent: boolean; const DestDir: string): boolean;
var
 p: PArray0OfByte;
 bpos: dword;

 procedure VTX_Save_Registers;
 var
   i: word;
   k: dword;
 begin
   k := 0;
   for i := 0 to 13 do
    begin
     p[bpos + k] := SoundChip[0].RegisterAY.Index[i];
     Inc(k, ProgrMax);
    end;
   Inc(bpos);
   SoundChip[0].RegisterAY.EnvType := 255;
 end;

 procedure OUT2VTX;
 begin
   OUTZXAYConv_TotalTime := IntOffset;
   repeat
     OUT_Get_Registers(0);
     if bpos < ProgrMax then VTX_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end
   until May_Quit or (bpos >= ProgrMax);
 end;

 procedure ZXAY2VTX;
 begin
   OUTZXAYConv_TotalTime := IntOffset;
   repeat
     ZXAY_Get_Registers(0);
     if bpos < ProgrMax then VTX_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end
   until May_Quit or (bpos >= ProgrMax);
 end;

 procedure EPSG2VTX;
 begin
   repeat
     EPSG_Get_Registers(0);
     if bpos < ProgrMax then VTX_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end;
   until May_Quit or (bpos >= ProgrMax);
 end;

 procedure VBL2VTX;
 begin
   repeat
     All_GetRegisters[0](0);
     VTX_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end;
   until (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) or May_Quit;
 end;

var
 Loop_Save: boolean;
 Nam, Aut, Prg, Trk: string;
 VTX_Hdr: TVTXFileHeader;
 Dir, FN, Exten: string;
 DirType: TDirType;
begin
 Result := True; //user canceled or critical error flag

 //file types not allowed to be converted to VTX
 if IsStreamOrModuleFileType(CurFileType) or IsCDFileType(CurFileType) or
   IsMIDIFileType(CurFileType) or (CurFileType = FT.VTX) then
   Exit;

 if not FrmPLst.GetVarsForSave(PlayingItem, FT.VTX, Silent, DestDir,
   Dir, DirType, FN, Exten) then
   //no room for file name or user canceled
   Exit(False);

 Loop_Save := Do_Loop;
 Do_Loop := False;
 InitForAllTypes(True);
 SoundChip[0].RegisterAY.EnvType := 255;
 OutProc := @OutInitialConverter;
 AssignFile(LhaOutFile, FN);
 Rewrite(LhaOutFile, 1);
 if CurFileType = FT.EPSG then
   ProgrMax := round((Time_ms / 1000) * (FrqZ80 / EPSG_TStateMax))
 else if (CurFileType = FT.OUT) or (CurFileType = FT.ZXAY) then
   ProgrMax := round((Time_ms / 1000) * (FrqZ80 / MaxTStates))
 else
   ProgrMax := PlConsts[0].Global_Tick_Max;
 with VTX_Hdr do
  begin
   if ChType = YM_Chip then
     Id := $6d79
   else
     Id := $7961;
   Mode := 1;
   UnpackSize := ProgrMax * 14;
   if LoopVBL > 65535 then
     loop := 65535
   else
     loop := LoopVBL;
   Trk := GetEditorString(CurFileType);
   Year := 0;
   ChipFrq := AY_Freq;
   if Interrupt_Freq > 255000 then
     InterFrq := 255
   else
     InterFrq := round(Interrupt_Freq / 1000);
  end;
 Nam := CurItem.Title;
 Aut := CurItem.Author;
 Prg := CurItem.Programm;
 if not Silent then
   VTX_Header_Editor(VTX_Hdr, Nam, Aut, Prg, Trk);
 Nam := Trim(UTF8ToCP(Nam)) + #0;
 Aut := Trim(UTF8ToCP(Aut)) + #0;
 Prg := Trim(UTF8ToCP(Prg)) + #0;
 Trk := Trim(UTF8ToCP(Trk)) + #0;
 LongProcessPrepare;
  try
   BlockWrite(LhaOutFile, VTX_Hdr, sizeof(VTX_Hdr));
   BlockWrite(LhaOutFile, Nam[1], Length(Nam));
   BlockWrite(LhaOutFile, Aut[1], Length(Aut));
   BlockWrite(LhaOutFile, Prg[1], Length(Prg));
   BlockWrite(LhaOutFile, Trk[1], Length(Trk));
   BlockWrite(LhaOutFile, YMComment, YMCommentLen + 1);
   bpos := 0;
   GetMem(p, ProgrMax * 14);
    try
     if CurFileType = FT.OUT then
       OUT2VTX
     else if CurFileType = FT.ZXAY then
       ZXAY2VTX
     else if CurFileType = FT.EPSG then
       EPSG2VTX
     else
       VBL2VTX;
     Result := not May_Quit;
     Original_Size := VTX_Hdr.UnpackSize;
     Encode_Buffer_To_File(p);
    finally
     FreeMem(p);
    end;
  finally
   LongProcessDone;
   CloseFile(LhaOutFile);
  end;
 Do_Loop := Loop_Save;
 ShowProgress(ProgrMax);
end;

function YM6_Converter(Silent: boolean; const DestDir: string): boolean;
var
 p: PArray0OfByte;
 bpos: dword;
 bposadd: dword;

 procedure YM6_Save_Registers;
 var
   i: word;
   k: dword;
 begin
   k := bposadd;
   for i := 0 to 13 do
    begin
     p[bpos + k] := SoundChip[0].RegisterAY.Index[i];
     Inc(k, ProgrMax);
    end;
   p[bpos + k] := 0;
   p[bpos + k + ProgrMax] := 0;
   Inc(bpos);
   SoundChip[0].RegisterAY.EnvType := 255;
 end;

 procedure OUT2YM6;
 begin
   OUTZXAYConv_TotalTime := IntOffset;
   repeat
     OUT_Get_Registers(0);
     if bpos < ProgrMax then YM6_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end
   until May_Quit or (bpos >= ProgrMax);
 end;

 procedure ZXAY2YM6;
 begin
   OUTZXAYConv_TotalTime := IntOffset;
   repeat
     ZXAY_Get_Registers(0);
     if bpos < ProgrMax then YM6_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end
   until May_Quit or (bpos >= ProgrMax);
 end;

 procedure EPSG2YM6;
 begin
   repeat
     EPSG_Get_Registers(0);
     if bpos < ProgrMax then YM6_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end;
   until May_Quit or (bpos >= ProgrMax);
 end;

 procedure VBL2YM6;
 begin
   repeat
     All_GetRegisters[0](0);
     YM6_Save_Registers;
     if (bpos and 63) = 0 then
      begin
       ShowProgress(bpos);
       Application.ProcessMessages;
      end;
   until (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) or May_Quit;
 end;

 function Get_CRC(p: PArray0OfByte; sz: dword): word;
 var
   i, i2: dword;
 begin
   Result := 0;
   for i := 0 to pred(sz) do
    begin
     Result := (Result xor p[i]);
     for I2 := 1 to 8 do
       if ((Result and 1) <> 0) then
         Result := ((Result shr 1) xor $a001)
       else
         Result := (Result shr 1);
    end;
 end;

const
 SFileNameLen = 10;
 SFileName: string = 'Ay_Emul.ym';
 YMEnd: array[0..3] of char = 'End!';
var
 i: word;
 i2: byte;
 Loop_Save: boolean;
 Tit, Aut: string;
 YM5_Hdr: TYM5FileHeader;
 LZH_Hdr: TLZHFileHeader;
 Dir, FN, Exten: string;
 DirType: TDirType;
begin
 Result := True; //user canceled or critical error flag

 //file types not allowed to be converted to YM6
 if IsStreamOrModuleFileType(CurFileType) or IsCDFileType(CurFileType) or
   IsMIDIFileType(CurFileType) or (CurFileType = FT.YM5) or (CurFileType = FT.YM6) then
   Exit;

 if not FrmPLst.GetVarsForSave(PlayingItem, FT.YM, Silent, DestDir,
   Dir, DirType, FN, Exten) then
   //no room for file name or user canceled
   Exit(False);

 Loop_Save := Do_Loop;
 Do_Loop := False;
 InitForAllTypes(True);
 SoundChip[0].RegisterAY.EnvType := 255;
 OutProc := @OutInitialConverter;
 AssignFile(LhaOutFile, FN);
 Rewrite(LhaOutFile, 1);
  try
   Seek(LhaOutFile, sizeof(LZH_Hdr));
   BlockWrite(LhaOutFile, SFileName[1], SFileNameLen);
   LZH_Hdr.HSize := sizeof(LZH_Hdr) + SFileNameLen;
   LZH_Hdr.FileNameLen := SFileNameLen;
   Seek(LhaOutFile, int64(LZH_Hdr.HSize) + 2);
   if CurFileType = FT.EPSG then
     ProgrMax := round((Time_ms / 1000) * (FrqZ80 / EPSG_TStateMax))
   else if (CurFileType = FT.OUT) or (CurFileType = FT.ZXAY) then
     ProgrMax := round((Time_ms / 1000) * (FrqZ80 / MaxTStates))
   else
     ProgrMax := PlConsts[0].Global_Tick_Max;
   with YM5_Hdr do
    begin
     Id := $21364d59;
     Leo := 'LeOnArD!';
     Num_of_tiks := ProgrMax;
     Song_Attr := $01000000;
     Num_of_Dig := 0;
     Loop := LoopVBL;
     InterFrq := round(Interrupt_Freq / 1000);
     ChipFrq := AY_Freq;
     Add_Size := 0;
    end;
   Tit := CurItem.Title;
   Aut := CurItem.Author;
   if not Silent then
     YM6_Header_Editor(Ym5_Hdr, Tit, Aut);
   Tit := Trim(UTF8ToCP(Tit)) + #0;
   Aut := Trim(UTF8ToCP(Aut)) + #0;
   with YM5_Hdr do
    begin
     Num_of_tiks := SwapEndian(Num_of_tiks);
     ChipFrq := SwapEndian(ChipFrq);
     InterFrq := SwapEndian(InterFrq);
     Loop := SwapEndian(Loop);
    end;
   bposadd := sizeof(YM5_Hdr) + longword(Length(Aut) + Length(Tit)) +
     YMCommentLen + 1;
   bpos := 0;
   Original_Size := ProgrMax * 16 + 4 + bposadd;
   GetMem(p, Original_Size);
   LongProcessPrepare;
    try
     if CurFileType = FT.OUT then
       OUT2YM6
     else if CurFileType = FT.ZXAY then
       ZXAY2YM6
     else if CurFileType = FT.EPSG then
       EPSG2YM6
     else
       VBL2YM6;
     Result := not May_Quit;
     Move(YM5_Hdr, p^, sizeof(YM5_Hdr));
     Move(Tit[1], p[sizeof(YM5_Hdr)], Length(Tit));
     Move(Aut[1], p[sizeof(YM5_Hdr) + Length(Tit)], Length(Aut));
     Move(YMComment, p[sizeof(YM5_Hdr) + Length(Aut) + Length(Tit)], YMCommentLen + 1);
     Move(YMEnd, p[Original_Size - 4], 4);
     Encode_Buffer_To_File(p);
     Seek(LhaOutFile, 0);
     LZH_Hdr.UCompSize := Original_Size;
     LZH_Hdr.CompSize := Compressed_Size;
     LZH_Hdr.Method := '-lh5-';
     LZH_Hdr.Attr := $20;
     LZH_Hdr.Dos_DT := (CompilY - 1980) shl 25 or CompilM shl 21 or
       CompilD shl 16 or VersionMajor shl 11 or VersionMinor shl 5;
     BlockWrite(LhaOutFile, LZH_Hdr, sizeof(LZH_Hdr));
     Seek(LhaOutFile, lZH_hdr.HSize);
     i := Get_CRC(p, Original_Size);
     BlockWrite(LhaOutFile, i, 2);
     LZH_Hdr.ChkSum := 0;
     Seek(LhaOutFile, 2);
     for i := 0 to Pred(LZH_hdr.HSize) do
      begin
       System.BlockRead(LhaOutFile, i2, 1);
       Inc(LZH_Hdr.ChkSum, i2);
      end;
     Seek(LhaOutFile, 1);
     BlockWrite(LhaOutFile, LZH_Hdr.ChkSum, 1);
     Seek(LhaOutFile, System.FileSize(LhaOutFile));
     BlockWrite(LhaOutFile, Zero, 1);
    finally
     LongProcessDone;
     FreeMem(p);
    end;
  finally
   CloseFile(LhaOutFile);
  end;
 Do_Loop := Loop_Save;
 ShowProgress(ProgrMax);
end;

function CPToUTF8(const s: string): string;
begin
 Result := ConvertEncoding(s, CodePageDef, 'UTF8');
end;

function UTF8ToCP(const s: string): string;
begin
 Result := ConvertEncoding(s, 'UTF8', CodePageDef);
end;

function DecodeHTMLEntities(const s: string): string;
var
 i, len, code: integer;
 ss: string;
begin
 Result := '';
 len := Length(s);
 i := 0;
 while i < len do
  begin
   Inc(i);
   ss := s[i];
   if s[i] = '&' then
     if i < len then
      begin
       Inc(i);
       ss := ss + s[i];
       if s[i] = '#' then
        begin
         code := 0;
         while i < len do
          begin
           Inc(i);
           ss := ss + s[i];
           case s[i] of
             '0'..'9':
              begin
               code := code * 10 + Ord(s[i]) - Ord('0');
               if code > 65535 then break;
              end;
             ';':
              begin
               if Length(ss) = 3 then break;
               ss := UTF8Encode(WideString(widechar(code)));
               break;
              end
           else
             break;
            end;
          end;
        end;
      end;
   Result := Result + ss;
  end;
end;

function GarbageDecoder(const s: string): string;
var
 len: integer;
begin
 Result := s;
 len := Length(Result);
 if FindInvalidUTF8Codepoint(PChar(Result), len) >= 0 then
  begin
   if (len >= 4) and (len and 1 = 0) then
     if (Result[1] = #$FE) and (Result[2] = #$FF) then
       Exit(UCS2BEToUTF8(PChar(@Result[3])))
     else if (Result[1] = #$FF) and (Result[2] = #$FE) then
       Exit(UCS2LEToUTF8(PChar(@Result[3])));
   Result := CPToUTF8(Result);
  end
 else if len >= 3 then
   if (Result[1] = #$EF) and (Result[2] = #$BB) and (Result[3] = #$BF) then
     Result := Copy(Result, 4, Len - 3);
 Result := DecodeHTMLEntities(Result);
end;

function ASCII(const s: string): boolean;
var
 i: integer;
begin
 for i := 1 to Length(s) do
   if Ord(s[i]) > 127 then
     Exit(False);
 Result := True;
end;

{$IFDEF Windows}
function IfAnsiToUTF8(const s: string): string;
begin
 Result := s;
 if ASCII(Result) then
   Exit;
 if FindInvalidUTF8Codepoint(PChar(Result), Length(Result)) < 0 then
   Exit;
 Result := ConvertEncoding(Result, 'Ansi', 'UTF8');
end;
{$ENDIF  Windows}

end.
