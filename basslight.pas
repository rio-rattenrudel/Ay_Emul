{
basslight
---------
(c)2003,2021,2024 S.V.Bulba
http://ay.strangled.net/
svbulba@gmail.com

Description:
------------
Dinamycally loads/unloads BASS.DLL (BASSWMA.DLL, BASSAPE.DLL, BASSFLAC.DLL,
BASSWV.DLL, BASS_AC3.DLL, etc) and BASSENC.DLL (BASSENC_MP3.DLL, etc)
Uses minimal set of constants, types and declarations from
original BASS.PAS, BASSWMA.PAS, BASSAPE.PAS, BASSFLAC.PAS, BASSWV.PAS,
BASS_AC3.PAS, BASSENC.PAS, BASSENC_MP3.PAS, etc

Linux version is supported too

Written for using with BASS version 2.4
}

unit basslight;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType{$IFDEF MSWINDOWS}, Windows{$ELSE},dl{$ENDIF}
 {$IFDEF dbgmode},Dialogs{$ENDIF}, SysUtils;

type
 EBASSError = class(Exception);

 TBASSEnc = (tbeMain, tbeMP3, tbeOGG, tbeFLAC, tbeOPUS);
 TBASSEncSet = set of TBASSEnc;

 HMUSIC = DWORD;
 HSAMPLE = DWORD;
 HSTREAM = DWORD;
 HSYNC = DWORD;
 HPLUGIN = DWORD;
 HENCODE = DWORD;

 STREAMPROC = function(handle: HSTREAM; buffer: Pointer; length: DWORD;
   user: Pointer): DWORD; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 DOWNLOADPROC = procedure(buffer: Pointer; length: DWORD; user: Pointer);
   {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 SYNCPROC = procedure(handle: HSYNC; channel, Data: DWORD; user: Pointer);
   {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};

 BASS_CHANNELINFO = record
   freq: DWORD;        // default playback rate
   chans: DWORD;       // channels
   flags: DWORD;       // BASS_SAMPLE/STREAM/MUSIC/SPEAKER flags
   ctype: DWORD;       // type of channel
   origres: DWORD;     // original resolution
   plugin: HPLUGIN;    // plugin
   sample: HSAMPLE;    // sample
   {$IFDEF CPUX64}
    padding: DWORD;
   {$ENDIF}
   filename: PChar;    // filename
 end;

procedure RaiseBASSError(Code: DWORD; const Mes: string);
procedure RaiseLastBASSError;

//if BASS is not loaded then loads BASS and plug-ins
//checks version and gets some procs addresses
procedure LoadBASS(Enc: TBASSEncSet = []);

procedure UnloadBASS;   //Unload BASS if it was loaded

const
 BASS_DEFAULTDEVICE = -1;
 BASS_NOSOUNDDEVICE = 0;
 BASS_FIRSTSOUNDDEVICE = 1;

 //Some consts from BASS*.PAS
 BASS_CONFIG_NET_AGENT = 16;
 BASS_CONFIG_NET_PROXY = 17;

 BASS_TAG_ID3 = 0;
 BASS_TAG_ID3V2 = 1;
 BASS_TAG_OGG = 2;
 BASS_TAG_HTTP = 3;
 BASS_TAG_ICY = 4;
 BASS_TAG_META = 5;
 BASS_TAG_APE = 6;
 BASS_TAG_WMA = 8;

 BASS_TAG_RIFF_INFO = $100;
 BASS_TAG_MUSIC_NAME = $10000;
 BASS_TAG_MUSIC_MESSAGE = $10001;
 BASS_TAG_MUSIC_INST = $10100;
 BASS_TAG_MUSIC_SAMPLE = $10300;

 BASS_STREAM_PRESCAN = $20000;
 BASS_STREAM_DECODE = $200000;

 BASS_UNICODE = $80000000;

 BASS_SAMPLE_LOOP = 4;

 BASS_MUSIC_STOPBACK = $80000;
 BASS_MUSIC_PRESCAN = BASS_STREAM_PRESCAN;
 BASS_MUSIC_CALCLEN = BASS_MUSIC_PRESCAN;
 BASS_MUSIC_NOSAMPLE = $100000;

 BASS_POS_BYTE = 0;

 BASS_DATA_FFT256 = $80000000;
 BASS_DATA_FFT512 = $80000001;
 BASS_DATA_FFT1024 = $80000002;
 BASS_DATA_FFT2048 = $80000003;
 BASS_DATA_FFT4096 = $80000004;
 BASS_DATA_FFT8192 = $80000005;
 BASS_DATA_FFT16384 = $80000006;
 BASS_DATA_FFT32768 = $80000007;
 BASS_DATA_FFT_NOWINDOW = $20;
 BASS_DATA_FFT_REMOVEDC = $40;

 BASS_SYNC_POS = 0;
 BASS_SYNC_END = 2;
 BASS_SYNC_META = 4;
 // {$IFDEF UseBassForEmu}
 BASS_STREAMPROC_END = $80000000;
 BASS_SAMPLE_8BITS = 1;
 // {$ENDIF UseBassForEmu}

 BASS_ACTIVE_PLAYING = 1;

 BASS_ATTRIB_FREQ = 1;
 // BASS_ATTRIB_VOL         = 2;

 // BASS_MP3_SETPOS         = BASS_STREAM_PRESCAN;

 BASS_CTYPE_SAMPLE = 1;
 BASS_CTYPE_RECORD = 2;
 BASS_CTYPE_STREAM = $10000;
 BASS_CTYPE_STREAM_VORBIS = $10002;
 BASS_CTYPE_STREAM_OGG = $10002;
 BASS_CTYPE_STREAM_MP1 = $10003;
 BASS_CTYPE_STREAM_MP2 = $10004;
 BASS_CTYPE_STREAM_MP3 = $10005;
 BASS_CTYPE_STREAM_AIFF = $10006;
 BASS_CTYPE_STREAM_CA = $10007;
 BASS_CTYPE_STREAM_MF = $10008;
 BASS_CTYPE_STREAM_AM = $10009;
 BASS_CTYPE_STREAM_SAMPLE = $1000a;
 BASS_CTYPE_STREAM_DUMMY = $18000;
 BASS_CTYPE_STREAM_DEVICE = $18001;
 BASS_CTYPE_STREAM_AAC = $10b00;
 BASS_CTYPE_STREAM_MP4 = $10b01;
 BASS_CTYPE_STREAM_AC3 = $11000;
 BASS_CTYPE_STREAM_ALAC = $10e00;
 BASS_CTYPE_STREAM_APE = $10700;
 BASS_CTYPE_STREAM_DSD = $11700;
 BASS_CTYPE_STREAM_FLAC = $10900;
 BASS_CTYPE_STREAM_FLAC_OGG = $10901;
 BASS_CTYPE_STREAM_OPUS = $11200;
 BASS_CTYPE_STREAM_WMA = $10300;
 BASS_CTYPE_STREAM_WMA_MP3 = $10301;
 BASS_CTYPE_STREAM_WV = $10500;
 BASS_CTYPE_STREAM_WAV = $40000; // WAVE flag (LOWORD=codec)
 BASS_CTYPE_STREAM_WAV_PCM = $50001;
 BASS_CTYPE_STREAM_WAV_FLOAT = $50003;
 BASS_CTYPE_MUSIC_MOD = $20000;
 BASS_CTYPE_MUSIC_MTM = $20001;
 BASS_CTYPE_MUSIC_S3M = $20002;
 BASS_CTYPE_MUSIC_XM = $20003;
 BASS_CTYPE_MUSIC_IT = $20004;
 BASS_CTYPE_MUSIC_MO3 = $00100; // MO3 flag


 BASS_ERROR_VERSION = 43;
 BASS_ERROR_ENDED = 45;

var
 BASSErrorString: string;
 BASSErCode: DWORD;

 //Some BASS.DLL function addresses (see description in original BASS.PAS)
type
 TBASSGetVersionProc = function: DWORD; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};

var
 BASS_GetVersion: function: DWORD; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ErrorGetCode: function: integer; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_PluginLoad: function(filename: PChar; flags: DWORD): HPLUGIN;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_GetConfigPtr: function(option: DWORD): Pointer;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_SetConfigPtr: function(option: DWORD; Value: Pointer): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 {$IFDEF MSWINDOWS}
 BASS_Init: function(device: integer; freq, flags: DWORD; win: HWND;
 clsid: PGUID): BOOL; stdcall;
 {$ELSE}
 BASS_Init:function (device: Integer; freq, flags: DWORD; win: Pointer; clsid: Pointer): BOOL; cdecl;
 {$ENDIF}
 BASS_Free: function: BOOL; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_StreamCreateFile: function(mem: BOOL; f: Pointer; offset, length: QWORD;
 flags: DWORD): HSTREAM; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_StreamCreateURL: function(url: PChar; offset: DWORD; flags: DWORD;
 proc: DOWNLOADPROC; user: Pointer): HSTREAM;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_StreamCreate: function(freq, chans, flags: DWORD; proc: STREAMPROC;
 user: Pointer): HSTREAM; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_StreamFree: function(handle: HSTREAM): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelIsActive: function(handle: DWORD): DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelPlay: function(handle: DWORD; restart: BOOL): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelSetSync: function(handle: DWORD; type_: DWORD; param: QWORD;
 proc: SYNCPROC; user: Pointer): HSYNC; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelRemoveSync: function(handle: DWORD; sync: HSYNC): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelPause: function(handle: DWORD): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelStop: function(handle: DWORD): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetLength: function(handle, mode: DWORD): QWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetPosition: function(handle, mode: DWORD): QWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelSetPosition: function(handle: DWORD; pos: QWORD; mode: DWORD): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetLevel: function(handle: DWORD): DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetData: function(handle: DWORD; buffer: Pointer; length: DWORD): DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetAttribute: function(handle, attrib: DWORD; var Value: single): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelBytes2Seconds: function(handle: DWORD; pos: QWORD): double;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelSeconds2Bytes: function(handle: DWORD; pos: double): QWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelFlags: function(handle, flags, mask: DWORD): DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetInfo: function(handle: DWORD; var info: BASS_CHANNELINFO): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_ChannelGetTags: function(handle: HSTREAM; tags: DWORD): pansichar;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_MusicLoad: function(mem: BOOL; f: Pointer; offset: QWORD;
 length, flags, freq: DWORD): HMUSIC; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_MusicFree: function(handle: HMUSIC): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};

 BASS_Encode_GetVersion: function: DWORD; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_IsActive: function(handle: DWORD): DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_Stop: function(handle: DWORD): BOOL;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_MP3_GetVersion: function: DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_MP3_StartFile: function(handle: DWORD; options: PChar;
 flags: DWORD; filename: PChar): HENCODE; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_OGG_GetVersion: function: DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_OGG_StartFile: function(handle: DWORD; options: PChar;
 flags: DWORD; filename: PChar): HENCODE; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_FLAC_GetVersion: function: DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_FLAC_StartFile: function(handle: DWORD; options: PChar;
 flags: DWORD; filename: PChar): HENCODE; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_OPUS_GetVersion: function: DWORD;
 {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};
 BASS_Encode_OPUS_StartFile: function(handle: DWORD; options: PChar;
 flags: DWORD; filename: PChar): HENCODE; {$IFDEF MSWINDOWS} stdcall{$ELSE}cdecl{$ENDIF};

implementation

var
 Hnd:{$IFDEF MSWINDOWS}HINST{$ELSE}PtrInt{$ENDIF} = 0;
 HndEnc: array[TBASSEnc] of
 {$IFDEF MSWINDOWS}HINST{$ELSE}PtrInt{$ENDIF} = (0, 0, 0, 0, 0);

const
 Libs = 9;
 LibNames: array[0..Libs] of string =
   ({$IFDEF MSWINDOWS}'bass.dll'{$ELSE}'libbass.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'basswma.dll'{$ELSE}'libbasswma.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassape.dll'{$ELSE}'libbassape.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassflac.dll'{$ELSE}'libbassflac.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'basswv.dll'{$ELSE}'libbasswv.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bass_ac3.dll'{$ELSE}'libbass_ac3.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bass_aac.dll'{$ELSE}'libbass_aac.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassalac.dll'{$ELSE}'libbassalac.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassdsd.dll'{$ELSE}'libbassdsd.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassopus.dll'{$ELSE}'libbassopus.so'{$ENDIF}
   );

const
 LibEncNames: array[TBASSEnc] of string =
   ({$IFDEF MSWINDOWS}'bassenc.dll'{$ELSE}'libbassenc.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassenc_mp3.dll'{$ELSE}'libbassenc_mp3.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassenc_ogg.dll'{$ELSE}'libbassenc_ogg.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassenc_flac.dll'{$ELSE}'libbassenc_flac.so'{$ENDIF},
   {$IFDEF MSWINDOWS}'bassenc_opus.dll'{$ELSE}'libbassenc_opus.so'{$ENDIF}
   );


resourcestring

 BASSE_OK = 'All is OK';
 BASSE_Mem = 'Memory error';
 BASSE_CantOpenFile = 'Can''t open the file';
 BASSE_CantFindSndDrv = 'Can''t find a free sound driver';
 BASSE_SampleBufLost = 'The sample buffer was lost';
 BASSE_InvalidHnd = 'Invalid handle';
 BASSE_UnsupSmpFormat = 'Unsupported sample format';
 BASSE_InvalidPos = 'Invalid position';
 BASSE_NoInit = 'BASS_Init has not been successfully called';
 BASSE_NoStart = 'BASS_Start has not been successfully called';
 BASSE_SSL = 'SSL/HTTPS support isn''t available';
 BASSE_Reinit = 'Device needs to be reinitialized';
 BASSE_Unknown = 'Unknown error';
 BASSE_Already = 'Already initialized/paused/whatever';
 BASSE_NotAudio = 'File does not contain audio';
 BASSE_CantGetChan = 'Can''t get a free channel';
 BASSE_IllegalType = 'An illegal type was specified';
 BASSE_IllegalParam = 'An illegal parameter was specified';
 BASSE_No3D = 'No 3D support';
 BASSE_NoEAX = 'No EAX support';
 BASSE_IllegalDevice = 'Illegal device number';
 BASSE_NotPlaying = 'Not playing';
 BASSE_IllegalSampleRate = 'Illegal sample rate';
 BASSE_NotFileStream = 'The stream is not a file stream';
 BASSE_NoHardVoices = 'No hardware voices available';
 BASSE_Empty = 'The file has no sample data';
 BASSE_NoInternet = 'No internet connection could be opened';
 BASSE_CantCrateFile = 'Couldn''t create the file';
 BASSE_EffectsNotEnabled = 'Effects are not enabled';
 BASSE_NotAvail = 'Requested data/action is not available';
 BASSE_DecodChan = 'The channel is/isn''t a "decoding channel"';
 BASSE_DirectXVer = 'A sufficient DirectX version is not installed';
 BASSE_ConnectionTimedout = 'Connection timedout';
 BASSE_UnsupFileFormat = 'Unsupported file format';
 BASSE_UnavailSpeaker = 'Unavailable speaker';
 BASSE_Version = 'Invalid BASS version';
 BASSE_Codec = 'Codec is not available/supported';
 BASSE_ChanFileEnd = 'The channel/file has ended';
 BASSE_DeviceBusy = 'The device is busy';
 BASSE_Unstreamable = 'Unstreamable file';
 BASSE_Protocol = 'Unsupported protocol';
 BASSE_Denied = 'The device is busy';

procedure RaiseBASSError(Code: DWORD; const Mes: string);
begin
 BASSErrorString := Mes;
 BASSErCode := Code;
 raise EBASSError.Create('Error #' + IntToStr(Code) + ': ' + Mes);
end;

procedure RaiseLastBASSError;
const
 MaxDescribedError = 49;
 UnknownErrorIndex = 12;
 BASSErCodes: array[0..MaxDescribedError] of string =
   (BASSE_OK,
   BASSE_Mem,
   BASSE_CantOpenFile,
   BASSE_CantFindSndDrv,
   BASSE_SampleBufLost,
   BASSE_InvalidHnd,
   BASSE_UnsupSmpFormat,
   BASSE_InvalidPos,
   BASSE_NoInit,
   BASSE_NoStart,
   BASSE_SSL,
   BASSE_Reinit,
   BASSE_Unknown,
   BASSE_Unknown,
   BASSE_Already,
   BASSE_Unknown,
   BASSE_Unknown,
   BASSE_NotAudio,
   BASSE_CantGetChan,
   BASSE_IllegalType,
   BASSE_IllegalParam,
   BASSE_No3D,
   BASSE_NoEAX,
   BASSE_IllegalDevice,
   BASSE_NotPlaying,
   BASSE_IllegalSampleRate,
   BASSE_Unknown,
   BASSE_NotFileStream,
   BASSE_Unknown,
   BASSE_NoHardVoices,
   BASSE_Unknown,
   BASSE_Empty,
   BASSE_NoInternet,
   BASSE_CantCrateFile,
   BASSE_EffectsNotEnabled,
   BASSE_Unknown,
   BASSE_Unknown,
   BASSE_NotAvail,
   BASSE_DecodChan,
   BASSE_DirectXVer,
   BASSE_ConnectionTimedout,
   BASSE_UnsupFileFormat,
   BASSE_UnavailSpeaker,
   BASSE_Version,
   BASSE_Codec,
   BASSE_ChanFileEnd,
   BASSE_DeviceBusy,
   BASSE_Unstreamable,
   BASSE_Protocol,
   BASSE_Denied);
var
 ErCode: DWORD;
begin
 BASSErCode := BASS_ErrorGetCode();
 if BASSErCode > MaxDescribedError then //DWORD(Integer)>=0
   ErCode := UnknownErrorIndex
 else
   ErCode := BASSErCode;
 RaiseBASSError(BASSErCode, BASSErCodes[ErCode]);
end;

function TryGet(const p: pointer): pointer;
begin
 Result := p;
 if p = nil then
  begin
   BASSErrorString := '';
   BASSErCode := 0;
   RaiseLastOSError;
  end;
end;

procedure CheckVersion(Version: DWORD; const LibName: string);
begin
 if Version and $FFFF0000 <> $02040000 then
   RaiseBASSError(BASS_ERROR_VERSION, 'Sorry, ' + LibName + ' version 2.4 required');
end;

procedure LoadBASS(Enc: TBASSEncSet = []);
var
 ExeDir: string;

 function TryGetProcAddress(const prcname: string; LibHnd:
   {$IFDEF MSWINDOWS}
   HINST
   {$ELSE}
PtrInt
   {$ENDIF}
   ): pointer;
 begin
   {$IFDEF MSWINDOWS}
   Result := TryGet(GetProcAddress(LibHnd, PChar(prcname)));
   {$ELSE}
   Result := TryGet(dlsym(LibHnd,pchar(prcname)));
   {$ENDIF}
 end;

 function TryGetProcAddress(const prcname: string): pointer;
 begin
   Result := TryGetProcAddress(prcname, Hnd);
 end;

 function LoadLib(const libname, onerrmes, getversionprocname: string;
   out GetVersionProc: TBASSGetVersionProc; var LibHnd:
   {$IFDEF MSWINDOWS}
   HINST
   {$ELSE}
PtrInt
   {$ENDIF}
   ): boolean;
 begin
   if LibHnd <> 0 then
     Exit(False);
   {$IFDEF MSWINDOWS}
   LibHnd := LoadLibraryW(pwidechar(UTF8Decode(ExeDir + libname)));
   {$ELSE}
   LibHnd := {%H-}PtrInt(dlopen(PChar(ExeDir+libname),RTLD_LAZY or RTLD_GLOBAL));
   {$ENDIF}
   if LibHnd = 0 then
     RaiseBASSError(BASS_ERROR_VERSION, libname + onerrmes);
    try
     pointer(GetVersionProc) := TryGetProcAddress(getversionprocname, LibHnd);
     CheckVersion(GetVersionProc(), libname);
    except
     UnloadBASS;
     raise;
    end;
   Result := True;
 end;

var
 i: integer;

 {$IFDEF dbgmode}
 Tst:HPLUGIN;
 {$ENDIF dbgmode}
begin
 ExeDir := IncludeTrailingBackslash(ExtractFileDir(ParamStr(0)));
 if LoadLib(LibNames[0], ' 2.4 by Ian Luck required for playing extra file types',
   'BASS_GetVersion', BASS_GetVersion, Hnd) then
  try
   pointer(BASS_ErrorGetCode) := TryGetProcAddress('BASS_ErrorGetCode');
   pointer(BASS_PluginLoad) := TryGetProcAddress('BASS_PluginLoad');
   pointer(BASS_GetConfigPtr) := TryGetProcAddress('BASS_GetConfigPtr');
   pointer(BASS_SetConfigPtr) := TryGetProcAddress('BASS_SetConfigPtr');
   pointer(BASS_Init) := TryGetProcAddress('BASS_Init');
   pointer(BASS_Free) := TryGetProcAddress('BASS_Free');
   pointer(BASS_StreamCreateFile) := TryGetProcAddress('BASS_StreamCreateFile');
   pointer(BASS_StreamCreateURL) := TryGetProcAddress('BASS_StreamCreateURL');
   pointer(BASS_StreamCreate) := TryGetProcAddress('BASS_StreamCreate');
   pointer(BASS_StreamFree) := TryGetProcAddress('BASS_StreamFree');
   pointer(BASS_ChannelIsActive) := TryGetProcAddress('BASS_ChannelIsActive');
   pointer(BASS_ChannelPlay) := TryGetProcAddress('BASS_ChannelPlay');
   pointer(BASS_ChannelSetSync) := TryGetProcAddress('BASS_ChannelSetSync');
   pointer(BASS_ChannelRemoveSync) := TryGetProcAddress('BASS_ChannelRemoveSync');
   pointer(BASS_ChannelPause) := TryGetProcAddress('BASS_ChannelPause');
   pointer(BASS_ChannelStop) := TryGetProcAddress('BASS_ChannelStop');
   pointer(BASS_ChannelGetLength) := TryGetProcAddress('BASS_ChannelGetLength');
   pointer(BASS_ChannelGetPosition) := TryGetProcAddress('BASS_ChannelGetPosition');
   pointer(BASS_ChannelSetPosition) := TryGetProcAddress('BASS_ChannelSetPosition');
   pointer(BASS_ChannelGetLevel) := TryGetProcAddress('BASS_ChannelGetLevel');
   pointer(BASS_ChannelGetData) := TryGetProcAddress('BASS_ChannelGetData');
   pointer(BASS_ChannelGetAttribute) := TryGetProcAddress('BASS_ChannelGetAttribute');
   pointer(BASS_ChannelBytes2Seconds) := TryGetProcAddress('BASS_ChannelBytes2Seconds');
   pointer(BASS_ChannelSeconds2Bytes) := TryGetProcAddress('BASS_ChannelSeconds2Bytes');
   pointer(BASS_ChannelFlags) := TryGetProcAddress('BASS_ChannelFlags');
   pointer(BASS_ChannelGetInfo) := TryGetProcAddress('BASS_ChannelGetInfo');
   pointer(BASS_ChannelGetTags) := TryGetProcAddress('BASS_ChannelGetTags');
   pointer(BASS_MusicLoad) := TryGetProcAddress('BASS_MusicLoad');
   pointer(BASS_MusicFree) := TryGetProcAddress('BASS_MusicFree');

   for i := 1 to Libs do
     {$IFDEF dbgmode}
   begin tst :=
     {$endif dbgmode}
     BASS_PluginLoad(PChar(
       {$IFDEF MSWINDOWS}
       UTF8Decode(
       {$ENDIF}
       ExeDir + LibNames[i])
       {$IFDEF MSWINDOWS}
       )
       {$ENDIF}
       ,
       {$IFDEF MSWINDOWS}
       BASS_UNICODE
       {$ELSE}
0
       {$ENDIF}
       );
   {$IFDEF dbgmode}
   if tst = 0 then
    try
     RaiseLastBASSError;
    except
     if BASSErCode <> 14{Already} then
      ShowMessage('BASSPlugInLoad Error ' + BASSErrorString + ' ('+ExeDir+LibNames[i]+')');
    end;
   end;
   {$ENDIF dbgmode}

  except
   UnloadBASS;
   raise;
  end;

 if (Enc <> []) and LoadLib(LibEncNames[tbeMain],
   ' 2.4 by Ian Luck required for encoding extra file types',
   'BASS_Encode_GetVersion', BASS_Encode_GetVersion, HndEnc[tbeMain]) then
  try
   pointer(BASS_Encode_IsActive) :=
     TryGetProcAddress('BASS_Encode_IsActive', HndEnc[tbeMain]);
   pointer(BASS_Encode_Stop) := TryGetProcAddress('BASS_Encode_Stop', HndEnc[tbeMain]);
   if (tbeMP3 in Enc) and LoadLib(LibEncNames[tbeMP3],
     ' 2.4 by Ian Luck required for encoding MP3', 'BASS_Encode_MP3_GetVersion',
     BASS_Encode_MP3_GetVersion, HndEnc[tbeMP3]) then
     pointer(BASS_Encode_MP3_StartFile) :=
       TryGetProcAddress('BASS_Encode_MP3_StartFile', HndEnc[tbeMP3]);
   if (tbeOGG in Enc) and LoadLib(LibEncNames[tbeOGG],
     ' 2.4 by Ian Luck required for encoding OGG', 'BASS_Encode_OGG_GetVersion',
     BASS_Encode_OGG_GetVersion, HndEnc[tbeOGG]) then
     pointer(BASS_Encode_OGG_StartFile) :=
       TryGetProcAddress('BASS_Encode_OGG_StartFile', HndEnc[tbeOGG]);
   if (tbeFLAC in Enc) and LoadLib(LibEncNames[tbeFLAC],
     ' 2.4 by Ian Luck required for encoding FLAC', 'BASS_Encode_FLAC_GetVersion',
     BASS_Encode_FLAC_GetVersion, HndEnc[tbeFLAC]) then
     pointer(BASS_Encode_FLAC_StartFile) :=
       TryGetProcAddress('BASS_Encode_FLAC_StartFile', HndEnc[tbeFLAC]);
   if (tbeOPUS in Enc) and LoadLib(LibEncNames[tbeOPUS],
     ' 2.4 by Ian Luck required for encoding OPUS', 'BASS_Encode_OPUS_GetVersion',
     BASS_Encode_OPUS_GetVersion, HndEnc[tbeOPUS]) then
     pointer(BASS_Encode_OPUS_StartFile) :=
       TryGetProcAddress('BASS_Encode_OPUS_StartFile', HndEnc[tbeOPUS]);
  except
   UnloadBASS;
   raise;
  end;

end;

procedure UnloadBASS;
var
 EncI: TBASSEnc;
begin
 for EncI := High(TBASSEnc) downto Low(TBASSEnc) do
   if HndEnc[EncI] <> 0 then
    begin
     {$IFDEF MSWINDOWS}
     FreeLibrary(HndEnc[EncI]);
     {$ELSE}
     dlClose(HndEnc[EncI]);
     {$ENDIF}
     HndEnc[EncI] := 0;
    end;
 if Hnd <> 0 then
  begin
   {$IFDEF MSWINDOWS}
   FreeLibrary(Hnd);
   {$ELSE}
   dlClose(Hnd);
   {$ENDIF}
   Hnd := 0;
  end;
end;

end.
