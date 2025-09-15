{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit basscode;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType, {$IFDEF MSWINDOWS}Windows,{$ENDIF} WinVersion, Graphics,
 Classes, basslight, SysUtils, Languages;

type
 PEncoderOptions = ^TEncoderOptions;

 TEncoderOptions = record
   Enc: TBASSEnc;

   //Flag for options editor to show Tags as just flags (not text)
   GroupOperation: boolean;

   FileName: string; //target for encoder

   //Tags using flags (if corresponding Tag is not empty)
   //If True then can be auto filled before calling encoder
   UseAuthor, UseTitle, UseComment, UseDate: boolean;

   TagAuthor, TagTitle, TagComment: string;

   //MP3:1..9999
   //OPUS:Y/YY/YYY/YYYY/YYYY-MM/YYYY-MM-DD or valid date for region
   //other values are ignored for MP3,OPUS
   //OGG,FLAC:any string
   TagDate: string;

   //MP3,OGG,OPUS: negative for average, positive for fixed, zero for no/default
   //MP3:positive - min if VBR
   //MP3:32 40 48 56 64 80 96 112 128 160 192 224 256 320 (min/max depends of sample rate)
   //OGG:no restrictions, ignored if quality was pointed
   //FLAC:ignored
   //OPUS:6-256 per channel
   BitRate,

   //MP3:0..9 (0 best)
   //OGG:0..110 (-1.0..10.0, 10 best, used instead of bitrate)
   //FLAC:0..8 (8 best)
   //OPUS:0..10 (10 best)
   //negative for no/default
   Quality,

   //MP3:0..9999 (0.000..9.999, 0 best, needs Ops.BitRate>0),
   //OPUS:>=0:CVBR;negative for usual VBR if BitRate=0 (i.e. using default mode)
   //FLAC,OGG:ignored
   //negative for no/default
   VBR: integer;

   CustomKeys: string;
 end;

const
 EncoderOptionsHints: array[Succ(Low(TBASSEnc))..High(TBASSEnc)] of string = (
   //MP3
   'LAME style options: -b, -B, -v, -V, -q, -m, --abr, --preset, ' +
   '--alt-preset, -Y, --resample, -p, -t, --tt, --ta, --tl, --ty, --tc, --tn, ' +
   '--tg, --ti, --tv, --add-id3v2, --id3v1-only, --id3v2-only, --pad-id3v2, ' +
   '--pad-id3v2-size, --noreplaygain',
   //OGG
   'OGGENC style options: -b / --bitrate, -m / --min-bitrate, -M / --max-bitrate, ' +
   '-q / --quality, -s / --serial, -t / --title, -a / --artist, -G / --genre, ' +
   '-d / --date, -l / --album, -N / --tracknum, -c / --comment',
   //FLAC
   'FLAC encoder style options: --ogg, --serial-number, --until, -S / --seekpoint, ' +
   '--no-seektable, -T / --tag, --picture, -P / --padding, --no-padding, ' +
   '-b / --blocksize, -V / --verify, --limit-min-bitrate, --fast, --best, ' +
   '-0 / --compression-level-0 and the other compression level options',
   //OPUS
   'OPUSENC style options: --bitrate, --vbr, --cvbr, --hard-cbr, ' +
   '--comp / --complexity, --framesize, --expect-loss, --max-delay, ' +
   '--comment, --artist, --title, --album, --tracknumber, --date, --genre, ' +
   '--picture, --padding, --serial, --set-ctl-int'
   );

 EncoderDateHints: array[Succ(Low(TBASSEnc))..High(TBASSEnc)] of string =
   (Mes_MP3DateHint, Mes_AnyString, Mes_AnyString, Mes_OPUSDateHint);

 EncoderQualityHints: array[Succ(Low(TBASSEnc))..High(TBASSEnc)] of string =
   (Mes_MP3QualityHint, Mes_OGGQualityHint, Mes_FLACQualityHint, Mes_OPUSQualityHint);

 EncoderBitrateHints: array[Succ(Low(TBASSEnc))..High(TBASSEnc)] of string =
   (Mes_MP3BitrateHint, Mes_OGGBitrateHint, '', Mes_OPUSBitrateHint);

var
 BASSFFTType: DWORD;
 BASSFFTNoWin: DWORD;
 BASSFFTRemDC: DWORD;
 BASSAmpMin: real;
 BASSNetUseProxy: boolean;
 BASSNetAgent, BASSNetProxy: string;
 BASSInitialized: boolean = False; //True => BASS_Init was called successfully
 BASSPaused: boolean;       //pause flag, used by SwitchPause
 BASSDevice: integer;

 //handle to stream or module,
 //0 => no music loaded
 MusicHandle: DWORD = 0;

 MusicIsStream: boolean;    //True => Music is stream, otherwise module
 EncoderHandle: HENCODE = 0;  //handle to encoder

 {
 Next procedures and functions checks some flags and handles
 and if all OK calls BASS functions. During calling
 some errors can be ocurred, all of them are translated
 into DELPHI's exceptions with error messages
 }

//calls BASS_Init if BASS was not initialized
procedure InitBASS(device: integer; freq, flags: DWORD; win: HWND);

//create stream for emulation (used with bassenc or UseBassForEmu)
//Decode for just decoding (not playing)
procedure InitEmuBASS(Decode: boolean);

function GetEncOptions(const Ops: TEncoderOptions): string;
procedure EncInitBASS(const Ops: TEncoderOptions);
function EncodeBASS(buf: pointer; bufsz: integer): boolean;
procedure EncDoneBASS;


//Tries start playing file: Stream = True - as stream,
//                          Stream = False - as module.
//StartTime and TimeLenMs only for stream
//(StartTime<0 for usual entire stream,
//StartTime>=0 for CUE pointed piece of stream)
//If successed then set sync for end of music by
//WM_PLAYNEXTITEM message
procedure PlayBASS(FileName: PChar; Stream: boolean; StartTime, TimeLenMs: integer);

procedure FreeAndUnloadBASS;

//returns max position for using with BASS_ChannelGetPosition.
function GetLengthBASS: QWORD;

procedure SetSync;    //Set SYNC_END and POS message
procedure SetMetaSync;//Set SYNC_META message
procedure RemoveSync; //Remove SYNC_END, POS and META message

//procedure SetVolumeBASS(v:single); //if BASS loaded set global volume

procedure GetNetConfig;
procedure StartBASS;

procedure PlayFreeBASS; //if PlayBASS was OK, stops playing and removes sync

function BASS_StreamCreateFile2(f: Pointer; flags: DWORD): HSTREAM;

procedure SwitchPause; //during playing pauses/resumes playback

procedure BASSVisualisation;
procedure BASS_SetLoop;

implementation

uses
 MainWin, Players, Mixer, FileTypes, settings;

var
 CallbackWindow: HWND;

 //sync handler, used for end of music message (WM_PLAYNEXTITEM)
 hsEND: HSYNC = 0; //if <> 0 then sync is set

 hsPOS: HSYNC = 0; //end of stream piece (CUE)

 hsMETA: HSYNC = 0; //meta data received (i.e. TAG)

 SyncTime, SyncRestart: QWORD; //CUE piece of stream end/begin

{$IFDEF UseBassForEmu}
 StreamIsUser:boolean; //True => Stream is user filled, otherwise file-stream
 {$ENDIF UseBassForEmu}

 // BASSVolume:single = 1; //global volume 0..1

procedure FreeBASS;
begin
 if BASSInitialized then
  begin
   BASSInitialized := False;
   BASS_Free;
  end;
end;

procedure InitBASS(device: integer; freq, flags: DWORD; win: HWND);
begin
 if BASSInitialized and (BASSDevice = device) then exit;
 FreeBASS;
 BASSDevice := device;
 CallbackWindow := win;
 BASSInitialized := BASS_Init(device, freq, flags,
   {$IFDEF MSWINDOWS}
   win
   {$ELSE}
   nil
   {$ENDIF}
   , nil);
 if not BASSInitialized then RaiseLastBASSError;
end;

procedure FreeAndUnloadBASS;
begin
 FreeBASS;
 UnloadBASS;
end;

procedure SyncEndProc(handle: HSYNC; channel, Data: DWORD; user: Pointer);
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
var
 RealEnd: boolean;
begin
 RealEnd := (SyncTime = QWORD(-1)) or not Do_Loop; //stream with no loop or any music
 if not RealEnd then
   //try loop stream
  begin
   RealEnd := not BASS_ChannelSetPosition(MusicHandle, SyncRestart, BASS_POS_BYTE);
   if not RealEnd and (BASS_ChannelIsActive(MusicHandle) <> BASS_ACTIVE_PLAYING) then
     //new position applyed, ensure the stream was not stopped
     RealEnd := not BASS_ChannelPlay(MusicHandle, False);
  end;
 if RealEnd then
  begin
   RemoveSync; //one proc for BASS_SYNC_END and BASS_SYNC_POS, remove all to avoid double playnext
   PostMessage(CallbackWindow, WM_PLAYNEXTITEM, 0, 0);
  end;
end;

procedure SyncMetaProc(handle: HSYNC; channel, Data: DWORD; user: Pointer);
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
begin
 PostMessage(CallbackWindow, WM_BASSMETADATA, 0, 0);
end;

//{$IFDEF UseBassForEmu}
function StreamProcEmu(handle: HSTREAM; buffer: Pointer; length: DWORD;
 user: Pointer): DWORD; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
var
 bl: integer;
begin
 Result := 0;
 if handle = MusicHandle then
  begin
   bl := BufferLength;
   BufferLength := DivMul(length, 8, int64(NumberOfChannels) * int64(SampleBit));
   MakeBuffer(buffer);
   BufferLength := bl;
   Result := BuffLen * NumberOfChannels * SampleBit div 8;
   if Real_End_All then
     Result := Result or BASS_STREAMPROC_END;
  end;
end;
//{$ENDIF UseBassForEmu}

procedure InitEmuBASS(Decode: boolean);
var
 fl: DWORD;
begin
 if Decode then
   fl := BASS_STREAM_DECODE
 else
   fl := 0;
 if SampleBit = 8 then
   fl := fl or BASS_SAMPLE_8BITS;
 MusicHandle := BASS_StreamCreate(SampleRate, NumberOfChannels, fl, @StreamProcEmu, nil);
end;

procedure PlayBASS(FileName: PChar; Stream: boolean; StartTime, TimeLenMs: integer);
var
 fl: DWORD;
 Restart: boolean;
begin
 if MusicHandle <> 0 then
   Exit;
 MusicIsStream := Stream;
 {$IFDEF UseBassForEmu}
StreamIsUser := FileName = '';
 {$ENDIF UseBassForEmu}
 fl := 0;
 if Stream then
  begin
   {$IFDEF UseBassForEmu}
  if FileName <> nil then
   {$ENDIF UseBassForEmu}
    begin
     if StreamPrescan then
       //slow, but need for VBR MP3 and chained OGG
       fl := BASS_STREAM_PRESCAN;
     if Do_Loop and (StartTime < 0) then
       //looped single file (no CUE)
       fl := fl or BASS_SAMPLE_LOOP;
     MusicHandle := BASS_StreamCreateFile2(FileName, fl);
    end;
   {$IFDEF UseBassForEmu}
  else
   InitEmuBASS(False)
   {$ENDIF UseBassForEmu}
  end
 else
  begin
   if Do_Loop then
     fl := BASS_SAMPLE_LOOP;
   MusicHandle := BASS_MusicLoad(False, FileName, 0, 0, BASS_MUSIC_STOPBACK or
     BASS_MUSIC_PRESCAN {or BASS_MUSIC_POSRESETEX} or fl, 0);
  end;
 if MusicHandle = 0 then
   RaiseLastBASSError;
 BASSPaused := False;
 Restart := True;
 SyncTime := QWORD(-1);
 if Stream and (StartTime >= 0) then
   //stream divided to subtunes via CUE
  begin
   SyncRestart := BASS_ChannelSeconds2Bytes(MusicHandle, StartTime / 1000);
   if not BASS_ChannelSetPosition(MusicHandle, SyncRestart, BASS_POS_BYTE) then
     RaiseLastBASSError
   else
    begin
     Restart := False; //CUE
     //if SyncTime will not fire (for example due rounding), must fire SyncEnd
     SyncTime := BASS_ChannelSeconds2Bytes(MusicHandle, (StartTime + TimeLenMs) / 1000);
     SetSync;
    end;
  end;
 if Restart and not Do_Loop then
   SetSync;
 if Stream
 {$IFDEF UseBassForEmu}
and not StreamIsUser
 {$ENDIF UseBassForEmu}
 then
   SetMetaSync;
 //BASS_ChannelSetAttribute(MusicHandle,BASS_ATTRIB_VOL,BASSVolume);
 if not BASS_ChannelPlay(MusicHandle, Restart) then
   RaiseLastBASSError;
end;

procedure SetSync;
begin
 hsEND := BASS_ChannelSetSync(MusicHandle, BASS_SYNC_END, 0, @SyncEndProc, nil);
 if SyncTime <> QWORD(-1) then
   hsPOS := BASS_ChannelSetSync(MusicHandle, BASS_SYNC_POS, SyncTime, @SyncEndProc, nil);
end;

procedure SetMetaSync;
begin
 hsMETA := BASS_ChannelSetSync(MusicHandle, BASS_SYNC_META, 0, @SyncMetaProc, nil);
end;

procedure RemoveSync;
begin
 if hsEND <> 0 then
  begin
   if not BASS_ChannelRemoveSync(MusicHandle, hsEND) then RaiseLastBASSError;
   hsEND := 0;
  end;
 if hsPOS <> 0 then
  begin
   if not BASS_ChannelRemoveSync(MusicHandle, hsPOS) then RaiseLastBASSError;
   hsPOS := 0;
  end;
 if hsMETA <> 0 then
  begin
   if not BASS_ChannelRemoveSync(MusicHandle, hsMETA) then RaiseLastBASSError;
   hsMETA := 0;
  end;
end;

function GetLengthBASS: QWORD;
begin
 if MusicHandle = 0 then
   Exit(0);
 Result := BASS_ChannelGetLength(MusicHandle, BASS_POS_BYTE);
 if int64(Result) = -1 then
   RaiseLastBASSError;
end;

{procedure SetVolumeBASS(v:single);
begin
BASSVolume := v;
if MusicHandle = 0 then exit;
BASS_ChannelSetAttribute(MusicHandle,BASS_ATTRIB_VOL,v);
end;}

procedure PlayFreeBASS;
begin
 if MusicHandle = 0 then
   Exit;
  try
   RemoveSync;
   BASS_ChannelStop(MusicHandle);
  finally
   if MusicIsStream then
     BASS_StreamFree(MusicHandle)
   else
     BASS_MusicFree(MusicHandle);
   MusicHandle := 0;
  end;
end;

(*var
 aFile:THandle=0;

procedure MyDownloadProc(buffer:pointer;length:DWORD;user:pointer);{$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
const
 CrLf = #13#10;
begin
if aFile = 0 then aFile := FileCreate(ParamStr(0)+'.download.mp3',fmOpenWrite);
if buffer = nil then
 begin
  FileClose(aFile);
  aFile := 0;
 end
else
 if length <> 0 then
  FileWrite(aFile,buffer^,length)
 else
  begin
   FileWrite(aFile,PChar(buffer)^,StrLen(PChar(buffer)));
   FileWrite(aFile,CrLf,2);
  end;
end;*)

function BASS_StreamCreateFile2(f: Pointer; flags: DWORD): HSTREAM;
var
 IsUrl: boolean;
begin
 IsUrl := FileIsURL(PChar(f));
 {$IFDEF Windows}
 flags := flags or BASS_UNICODE;
 f := pwidechar(UTF8Decode(PChar(f)));
 {$ENDIF Windows}
 if IsUrl then
  begin
   BASS_SetConfigPtr(BASS_CONFIG_NET_AGENT, PChar(BASSNetAgent));
   if not BASSNetUseProxy then
     BASS_SetConfigPtr(BASS_CONFIG_NET_PROXY, nil)
   else
     BASS_SetConfigPtr(BASS_CONFIG_NET_PROXY, PChar(BASSNetProxy));
   Result := BASS_StreamCreateURL(f, 0, flags(* or $800000{BASS_STREAM_STATUS}*),
     nil{@MyDownloadProc}, nil);
  end
 else
   Result := BASS_StreamCreateFile(False, f, 0, 0, flags);
end;

procedure SwitchPause;
begin
 if MusicHandle = 0 then
   Exit;
 if not BASSPaused then
  begin
   BASSPaused := BASS_ChannelPause(MusicHandle);
   if not BASSPaused then RaiseLastBASSError;
  end
 else
  begin
   BASSPaused := not BASS_ChannelPlay(MusicHandle, False);
   if BASSPaused then RaiseLastBASSError;
  end;
end;

procedure BASSVisualisation;
var
 i, l, r, k: DWORD;
 q: QWORD;
 fft: array of single;
 spa: array[0..spa_num - 1] of single;
 k1, l1: real;
 sr: integer;
 srf: single;
begin
 if (MusicHandle = 0) or Paused or (EncoderHandle <> 0) then
   Exit;
 q := BASS_ChannelGetPosition(MusicHandle, BASS_POS_BYTE);
 if q = QWORD(-1) then
   Exit;
 {$IFDEF UseBassForEmu}
if StreamIsUser then
 AYVisualisation(DivMul(q,8,Int64(NumberOfChannels) * Int64(SampleBit)))
else
 {$ENDIF UseBassForEmu}
  begin
   k1 := BASS_ChannelBytes2Seconds(MusicHandle, q);
   if k1 < 0 then
     Exit;
   CurrTime_Rasch := trunc(k1 * 1000);
   if IsStreamFileType(CurFileType) and (StreamPlayFrom > 0) then
     Dec(CurrTime_Rasch, StreamPlayFrom);
   VProgrPos := CurrTime_Rasch;
   if IndicatorChecked then
    begin
     l := BASS_ChannelGetLevel(MusicHandle);
     if l <> $FFFFFFFF then
      begin
       r := l shr 16;
       if r <= BASSAmpMin * 128 then
         r := 0
       else
         r := trunc(32768 / ln(1 / BASSAmpMin) * ln(r / BASSAmpMin / 32768) + 0.5);
       l := l and $FFFF;
       if l <= BASSAmpMin * 128 then
         l := 0
       else
         l := trunc(32768 / ln(1 / BASSAmpMin) * ln(l / BASSAmpMin / 32768) + 0.5);
       RedrawVisChannels(l, 0, r, 32768);
      end;
    end;
   if SpectrumChecked then
    begin
     case BASSFFTType of
       BASS_DATA_FFT256: k := 256;
       BASS_DATA_FFT512: k := 512;
       BASS_DATA_FFT1024: k := 1024;
       BASS_DATA_FFT2048: k := 2048;
       BASS_DATA_FFT4096: k := 4096;
       BASS_DATA_FFT8192: k := 8192;
       BASS_DATA_FFT16384: k := 16384;
     else
       k := 32768;
      end;
     SetLength(fft, k div 2);
     k1 := spa_num / ln(20000 / 20);
     l := BASS_ChannelGetData(MusicHandle, @fft[0], BASSFFTType or
       BASSFFTNoWin or BASSFFTRemDC);
     if l = $FFFFFFFF then
       Exit;
     BMP_Vis.Canvas.CopyMode := cmSrcCopy;
     BMP_Vis.Canvas.CopyRect(Rect(0, 0, spa_width, spa_height), BMP_Sources.Canvas,
       Bounds(spa_src, 0, spa_width, spa_height));
     if BASS_ChannelGetAttribute(MusicHandle, BASS_ATTRIB_FREQ, srf) then
       sr := trunc(srf)
     else
       sr := SampleRate;
     FillChar(spa, spa_num * sizeof(single), 0);
     for i := 1 to k div 2 - 1 do
      begin
       r := trunc(k1 * ln(i / k / 20 * sr) + 0.5);
       if r < spa_num then
         spa[r] := spa[r] + fft[i] * fft[i];
      end;
     fft := nil;

     for r := 0 to spa_num - 1 do
      begin
       l1 := sqrt(spa[r]);
       if l1 > BASSAmpMin then
        begin
         l1 := spa_height - spa_height / ln(1 / BASSAmpMin) * ln(l1 / BASSAmpMin);
         if l1 >= 0 then
          begin
           BMP_Vis.Canvas.MoveTo(r, spa_height);
           BMP_Vis.Canvas.LineTo(r, trunc(l1 + 0.5) + 1);
          end;
        end;
      end;

     //todo передавать Canvas через параметры
     FrmMain.Canvas.CopyMode := cmSrcCopy;
     FrmMain.Canvas.CopyRect(Bounds(spa_x*Scale, spa_y*Scale, spa_width*Scale, spa_height*Scale),
       BMP_Vis.Canvas, Rect(0, 0, spa_width, spa_height));
    end;
   ShowProgress(VProgrPos);
  end;
end;

procedure GetNetConfig;
var
 p: pointer;
begin
 if BASSNetAgent = '' then
  begin
   BASSNetAgent := PChar(BASS_GetConfigPtr(BASS_CONFIG_NET_AGENT));
   //todo не использовать FrmMixer, через параметры?
   FrmMixer.CBNetAgent.Text := BASSNetAgent;
   p := BASS_GetConfigPtr(BASS_CONFIG_NET_PROXY);
   BASSNetUseProxy := p <> nil;
   FrmMixer.EProxy.Enabled := BASSNetUseProxy;
   FrmMixer.CBProxy.Checked := BASSNetUseProxy;
   if BASSNetUseProxy then
    begin
     BASSNetProxy := PChar(p);
     FrmMixer.EProxy.Text := BASSNetProxy;
    end;
  end;
end;

procedure StartBASS;
begin
 if IsPlaying then
   Exit;
 PlayFreeBASS;
 LoadBASS;
 GetNetConfig;
 //todo передавать Handle через параметры
 InitBASS({BASS_FIRSTSOUNDDEVICE}BASS_DEFAULTDEVICE, SampleRate, 0, FrmMain.Handle);

 IsPlaying := True;
 Paused := False;

 {$IFDEF UseBassForEmu}
 if CurFileType in [BASSFileMin..BASSFileMax] then
  begin
 {$ENDIF UseBassForEmu}
 PlayBASS(PChar(CurItem.FileName), IsStreamFileType(CurFileType),
   StreamPlayFrom, Time_ms);
 if FileIsURL(CurItem.FileName) then
   PostMessage(FrmMain.Handle, WM_BASSMETADATA, 0, 0);
 {$IFDEF UseBassForEmu}
  end
 else if CurFileType in [MinAYChipFile..MaxAYChipFile] then
  PlayBASS(nil,True,DLL,-1,Time_ms);
 {$ENDIF Windows}
end;

procedure BASS_SetLoop;
var
 info: BASS_CHANNELINFO;
begin
 if MusicHandle = 0 then
   Exit;
 if IsStreamFileType(CurFileType) and (StreamPlayFrom >= 0) then
   Exit;
 BASS_ChannelGetInfo(MusicHandle, info);
 if Do_Loop then
  begin
   RemoveSync;
   info.flags := info.flags or BASS_SAMPLE_LOOP;
  end
 else
  begin
   if (Time_ms >= 0) and (CurrTime_Rasch >= Time_ms) then
    begin        //todo передавать Handle через параметры или сделать в инит WndHandleforBASS := Handle
     PostMessage(FrmMain.Handle, WM_PLAYNEXTITEM, 0, 0);
     Exit;
    end;
   SetSync;
   info.flags := info.flags and (BASS_SAMPLE_LOOP xor DWORD(-1));
  end;
 BASS_ChannelFlags(MusicHandle, info.flags, info.flags);
end;

function GetEncOptions(const Ops: TEncoderOptions): string;

 function Q(const s: string; AddQ: boolean): string;
 begin
   //todo остальные символы, linux, плохая идея передавать таги в ком. строке
   Result := StringReplace(s, '\', '\\', [rfReplaceAll]);
   Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
   if AddQ then
     Result := '"' + Result + '"';
 end;

var
 options: string;

 procedure AddTag(Use: boolean; const Tag, Key: string;
 const Prefix: string = ''; AddQ: boolean = True);
 begin
   if Use and (Tag <> '') then
     options += ' ' + Key + Prefix + Q(Tag, AddQ);
 end;

 function GetDateValue(const s: string; vmax: integer; out v: word): boolean;
 var
   vi: integer;
 begin
   Result := TryStrToInt(s, vi) and (vi > 0) and (vi <= vmax);
   if Result then
     v := vi;
 end;

 function ExtractDate: string;
 var
   Dt: TDate;
   d, m, y: word;
 begin
   Result := '';
   if not Ops.UseDate then
     Exit;
   if GetDateValue(Ops.TagDate, 9999, y) then
     //number 1..9999
     Exit(Format('%.4D', [y]));
   if Ops.Enc = tbeMP3 then
     Exit;
   //check for 'YYYY-MM' and 'YYYY-MM-DD'
   if (Length(Ops.TagDate) >= 7) and (Ops.TagDate[5] = '-') and
     GetDateValue(Copy(Ops.TagDate, 1, 4), 9999, y) and
     GetDateValue(Copy(Ops.TagDate, 6, 2), 12, m) then
    begin
     Result := Format('%.4D-%.2D', [y, m]);
     if (Length(Ops.TagDate) = 10) and (Ops.TagDate[8] = '-') and
       GetDateValue(Copy(Ops.TagDate, 9, 2), 31, d) and TryEncodeDate(y, m, d, Dt) then
       Result += Format('-%.2D', [d]);
     Exit;
    end;
   if TryStrToDate(Ops.TagDate, Dt) then
     //usual date
    begin
     DecodeDate(Dt, y, m, d);
     Exit(Format('%.4D-%.2D-%.2D', [y, m, d]));
    end;
 end;

var
 FS: TFormatSettings;
begin
 FS.DecimalSeparator := '.';

 options := Ops.CustomKeys;

 case Ops.Enc of
   tbeMP3:
    begin
     AddTag(Ops.UseAuthor, Ops.TagAuthor, '--ta ');
     AddTag(Ops.UseTitle, Ops.TagTitle, '--tt ');
     AddTag(Ops.UseComment, Ops.TagComment, '--tc ');
     AddTag(Ops.UseDate, ExtractDate, '--ty ', '', False);
     if Ops.VBR >= 0 then
       //Variable BR
      begin
       options += Format(' -V %.3F', [Ops.VBR / 1000], FS);
       if Ops.BitRate <> 0 then
         options += ' -b ' + IntToStr(Abs(Ops.BitRate));
      end
     else if Ops.BitRate < 0 then
       //Average BR
       options += ' --abr ' + IntToStr(-Ops.BitRate)
     else if Ops.BitRate > 0 then
       //Fixed BR
       options += ' -b ' + IntToStr(Ops.BitRate);
     if Ops.Quality >= 0 then
       options += ' -q ' + IntToStr(Ops.Quality);
    end;
   tbeOGG:
    begin
     AddTag(Ops.UseAuthor, Ops.TagAuthor, '-a ');
     AddTag(Ops.UseTitle, Ops.TagTitle, '-t ');
     AddTag(Ops.UseComment, Ops.TagComment, '-c ', 'comment=');
     AddTag(Ops.UseDate, Ops.TagDate, '-d ');
     if Ops.Quality >= 0 then
       //Quality rather than bitrate
       options += Format(' -q %.1F', [Ops.Quality / 10 - 1], FS)
     else if Ops.BitRate < 0 then
       //Average BR
       options += ' -b ' + IntToStr(-Ops.BitRate)
     else if Ops.BitRate > 0 then
       //Fixed BR
       options += '--managed -b ' + IntToStr(Ops.BitRate);
    end;
   tbeFLAC:
    begin
     AddTag(Ops.UseAuthor, Ops.TagAuthor, '-T ', 'ARTIST=');
     AddTag(Ops.UseTitle, Ops.TagTitle, '-T ', 'TITLE=');
     AddTag(Ops.UseComment, Ops.TagComment, '-T ', 'COMMENT=');
     AddTag(Ops.UseDate, Ops.TagDate, '-T ', 'DATE=');
     if Ops.Quality >= 0 then
       //compression level
       options += ' -' + IntToStr(Ops.Quality);
    end;
   tbeOPUS:
    begin
     AddTag(Ops.UseAuthor, Ops.TagAuthor, '--artist ');
     AddTag(Ops.UseTitle, Ops.TagTitle, '--title ');
     AddTag(Ops.UseComment, Ops.TagComment, '--comment ', 'comment=');
     AddTag(Ops.UseDate, ExtractDate, '--date ');
     if Ops.VBR >= 0 then
      begin
       //Constrained variable BR
       options += ' --cvbr';
       if Ops.BitRate > 0 then
         options += ' --bitrate ' + IntToStr(Ops.BitRate);
      end
     else if Ops.BitRate > 0 then
       //Fixed BR
       options += ' --hard-cbr --bitrate ' + IntToStr(Ops.BitRate)
     else if Ops.BitRate < 0 then
       //Average BR
       options += ' --vbr --bitrate ' + IntToStr(-Ops.BitRate);
{   else
    //Usual VBR
    options += ' --vbr'; //its default, no need to point?}
     if Ops.Quality >= 0 then
       //encoding quality
       options += ' --comp ' + IntToStr(Ops.Quality);
    end;
  end;

 Result := options;
end;

procedure EncInitBASS(const Ops: TEncoderOptions);
var
 flags: DWORD;
 options: string;
 f, o: Pointer;
begin
 InitBASS(BASS_NOSOUNDDEVICE, SampleRate, 0, 0);
 InitEmuBASS(True);
 if MusicHandle = 0 then
   RaiseLastBASSError;

 options := GetEncOptions(Ops);

 {$IFDEF Windows}
 flags := BASS_UNICODE;
 f := pwidechar(UTF8Decode(PChar(Ops.FileName)));
 o := pwidechar(UTF8Decode(PChar(options)));
 {$ELSE}
 flags := 0;
 f := PChar(Ops.FileName);
 o := PChar(options);
 {$ENDIF Windows}

 case Ops.Enc of
   tbeMP3: EncoderHandle := BASS_Encode_MP3_StartFile(MusicHandle, o, flags, f);
   tbeOGG: EncoderHandle := BASS_Encode_OGG_StartFile(MusicHandle, o, flags, f);
   tbeFLAC: EncoderHandle := BASS_Encode_FLAC_StartFile(MusicHandle, o, flags, f);
   tbeOPUS: EncoderHandle := BASS_Encode_OPUS_StartFile(MusicHandle, o, flags, f);
 else
   EncoderHandle := 0;
  end;
 if EncoderHandle = 0 then
   RaiseLastBASSError;
end;

function EncodeBASS(buf: pointer; bufsz: integer): boolean;
begin
 if BASS_Encode_IsActive(EncoderHandle) <> BASS_ACTIVE_PLAYING then
  begin
   EncDoneBASS;
   RaiseBASSError(DWORD(-1), 'Encoder became frozen');
  end;
 Result := BASS_ChannelGetData(MusicHandle, buf, bufsz) <> DWORD(-1);
 if not Result then
   if BASS_ErrorGetCode() <> BASS_ERROR_ENDED then
    begin
     EncDoneBASS;
     RaiseLastBASSError;
    end;
end;

procedure EncDoneBASS;
begin
 if EncoderHandle = 0 then
   Exit;

 BASS_Encode_Stop(EncoderHandle);
 EncoderHandle := 0;

 if MusicHandle = 0 then
   Exit;

 BASS_StreamFree(MusicHandle);
 MusicHandle := 0;

 FreeBASS;
end;

end.
