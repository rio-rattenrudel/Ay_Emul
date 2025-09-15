{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit Players;

{$mode objfpc}{$H+}

interface

uses
 LCLIntf, LCLType, SysUtils, Controls, Forms, lazutf8,
 AY, FileTypes, WinVersion, sometypes;

type
 EFileStructureError = class(Exception);
 EAddFileError = class(Exception);
 ErrorCodes = (FileNoError, ErFileNotFound, ErReadingFile, ErLZHDataIsNotValid,
   ErFLSAddrNotDetected, ErBASSError, ErBadFileStructure);

resourcestring

 Er_ErFileNotFound = 'File not found';
 Er_ErReadingFile = 'Error reading file';
 Er_ErLZHDataIsNotValid = 'LZH data is not valid';
 Er_ErFLSAddrNotDetected = 'Address of compilation is not detected: not FLS-file';
 Er_ErBASSError = 'Error calling BASS library';
 Er_ErBadFileStructure = 'Bad file structure';

const
 ImageID = 'Disk Image: ';
 ImageIDLen = Length(ImageID);
 Errors: array[Succ(Low(ErrorCodes))..High(ErrorCodes)] of string =
   (Er_ErFileNotFound, Er_ErReadingFile, Er_ErLZHDataIsNotValid,
   Er_ErFLSAddrNotDetected, Er_ErBASSError, Er_ErBadFileStructure);

 //количество паттернов ST, которые могут влезть в память, уменьшено на 1
 ST1MaxPat = 64; //todo: 0..64 или 1..64 (см. ниже)?
 ST1MaxPatE = 31;
 //ограничение редактора ST, уменьшено на 1 (todo: уточнить, вроде 1..31 в редакторе ST 3.0, а у меня 0..31)
 FLSMaxPatE = ST1MaxPatE;
 //предполагаем, что на FLS действуют все ограничения редактора ST

 STF_PatSize = 9 * 64; //размер одного паттерна
 STF_PrePatsSize = $BF9; //размер области перед паттернами
 STF_MinSize = STF_PrePatsSize + STF_PatSize; //хотя бы один паттерн
 STF_MaxSize = STF_PrePatsSize + STF_PatSize * (31 + 1);
 //все паттерны (с запасом - так как пакер часто захватывает мусор за последним паттерном, а распаковать надо)
 STFPacked_MaxSize = $1000; //не более одной страницы в ZX128
 //символы, которые позволяет вбить в название редактор + прописные буквы
 STF_AllowedChars = [#$20..#$5A, #$5E..#$7A, #$AC, #$C3, #$C5..#$C9, #$CB..#$CD, #$E2];

type
 //Trackers structure

 TST1Smp = packed record
   Vl, Ns: array[0..31] of byte;
   Tn: array[0..31] of word;
   LPos, LLen: byte;
 end;

 TST1Pos = packed record
   PNum, PTrans: byte;
 end;
 TST1Orn = array[0..31] of shortint;
 TST11PatLn = array[0..2] of packed record
   Nt, ESNum, EONum: byte;
   end;
 TST1Pat = array[0..63] of TST11PatLn;

 TSTCPat = packed record
   Num: byte;
   Ofs: array[0..2] of word;
 end;

 TSTFSmp = packed record
   Vl, NTENs: array[0..31] of byte;
   Tn: array[0..31] of word;
   LpB, LpS: byte;
 end;

 TSTFPos = packed record
   Pat, Trn: byte;
 end;

 TSTFOrn = packed record
   LpB, LpE: byte;
   Vals: array[0..29] of shortint;
 end;
 TSTFPat = array[0..63, 0..2] of packed record
   Nt, SmCmd, Param: byte;
   end;

 TSTPPat = packed record
   Ofs: array[0..2] of word;
 end;
 PSTFPacked = ^TSTFPacked;
 TSTFPacked = packed array [0..Pred(STFPacked_MaxSize)] of byte;
 PSTFUnpacked = ^TSTFUnpacked;
 TSTFUnpacked = packed array[0..Pred(STF_MaxSize)] of byte;

type

 PModTypes = ^ModTypes;
 ModTypes = packed record
   case integer of
     0: (Index: array[0..65536] of byte);
     1: (ST_Delay: byte;
       ST_PositionsPointer, ST_OrnamentsPointer, ST_PatternsPointer: word;
       ST_Name: array[0..17] of char;
       ST_Size: word);
     2: (ASC1_Delay, ASC1_LoopingPosition: byte;
       ASC1_PatternsPointers, ASC1_SamplesPointers, ASC1_OrnamentsPointers: word;
       ASC1_Number_Of_Positions: byte;
       ASC1_Positions: array[0..65535 - 9] of byte);
     3: (ASC0_Delay: byte;
       ASC0_PatternsPointers, ASC0_SamplesPointers, ASC0_OrnamentsPointers: word;
       ASC0_Number_Of_Positions: byte;
       ASC0_Positions: array[0..65535 - 8] of byte);
     4: (STP_Delay: byte;
       STP_PositionsPointer, STP_PatternsPointer,
       STP_OrnamentsPointer, STP_SamplesPointer: word;
       STP_Init_Id: byte);
     5: (PT2_Delay: byte;
       PT2_NumberOfPositions: byte;
       PT2_LoopPosition: byte;
       PT2_SamplesPointers: array[0..31] of word;
       PT2_OrnamentsPointers: array[0..15] of word;
       PT2_PatternsPointer: word;
       PT2_MusicName: array[0..29] of char;
       PT2_PositionList: array[0..65535 - 131] of byte);
     6: (PT3_MusicName: array[0..$62] of char;
       PT3_TonTableId: byte;
       PT3_Delay: byte;
       PT3_NumberOfPositions: byte;
       PT3_LoopPosition: byte;
       PT3_PatternsPointer: word;
       PT3_SamplesPointers: array[0..31] of word;
       PT3_OrnamentsPointers: array[0..15] of word;
       PT3_PositionList: array[0..65535 - 201] of byte);
     7: (PSC_MusicName: array[0..68] of char;
       PSC_UnknownPointer: word;
       PSC_PatternsPointer: word;
       PSC_Delay: byte;
       PSC_OrnamentsPointer: word;
       PSC_SamplesPointers: array[0..31] of word);
     8: (FTC_MusicName: array[0..68] of char;
       FTC_Delay: byte;
       FTC_Loop_Position: byte;
       FTC_Slack: integer;
       FTC_PatternsPointer: word;
       FTC_Slack2: array[0..4] of byte;
       FTC_SamplesPointers: array[0..31] of word;
       FTC_OrnamentsPointers: array[0..32] of word;
       FTC_Positions: array[0..(65536 - $d4) div 2 - 1] of packed record
         Pattern: byte;
         Transposition: shortint;
         end);
     9: (PT1_Delay: byte;
       PT1_NumberOfPositions: byte;
       PT1_LoopPosition: byte;
       PT1_SamplesPointers: array[0..15] of word;
       PT1_OrnamentsPointers: array[0..15] of word;
       PT1_PatternsPointer: word;
       PT1_MusicName: array[0..29] of char;
       PT1_PositionList: array[0..65535 - 99] of byte);
     10: (FLS_PositionsPointer: word;
       FLS_OrnamentsPointer: word;
       FLS_SamplesPointer: word;
       FLS_PatternsPointers: array[1..(65536 - 6) div 6] of packed record
         PatternA, PatternB, PatternC: word;
         end);
     11: (SQT_Size, SQT_SamplesPointer, SQT_OrnamentsPointer, SQT_PatternsPointer,
       SQT_PositionsPointer, SQT_LoopPointer: word);
     12: (GTR_Delay: byte;
       GTR_ID: array[0..3] of char;
       GTR_Address: word;
       GTR_Name: array[0..31] of char;
       GTR_SamplesPointers: array[0..14] of word;
       GTR_OrnamentsPointers: array[0..15] of word;
       GTR_PatternsPointers: array[0..31] of packed record
         PatternA, PatternB, PatternC: word;
         end;
       GTR_NumberOfPositions: byte;
       GTR_LoopPosition: byte;
       GTR_Positions: array[0..65536 - 295 - 1] of byte);
     13: (PSM_PositionsPointer: word;
       PSM_SamplesPointer: word;
       PSM_OrnamentsPointer: word;
       PSM_PatternsPointer: word;
       PSM_Remark: array[0..65535 - 8] of byte);
     14: (ST1_Smp: array[1..15] of TST1Smp;
       ST1_Pos: array[0..255] of TST1Pos;
       ST1_PosLen: byte;
       ST1_Orn: array[0..16] of TST1Orn;
       ST1_Del, ST1_PatLen: byte;
       ST1_Pat: array[0..ST1MaxPat] of TST1Pat);
     15: (STF_Samples: array[1..15] of TSTFSmp;
       STF_Positions: array[0..255] of TSTFPos;
       STF_PosLen: byte;
       STF_Ornaments: array[0..16] of TSTFOrn;
       STF_Delay: byte;
       STF_PatLens: array[1..31] of byte;
       STF_LoopPos: byte;
       STF_Title: array[1..25] of char;
       STF_Patterns: array[1..31] of TSTFPat);
     16: (ST3_Delay: byte;
       ST3_PositionsPointer, ST3_SamplesPointer, ST3_OrnamentsPointer,
       ST3_PatternsPointer: word;
       ST3_Title: array[1..55] of char);
 end;

type

 //AY-file header and structures
 TAYFileHeader = packed record
   FileID, TypeID: longword;
   FileVersion, PlayerVersion: byte;
   PSpecialPlayer, PAuthor, PMisc: smallint;
   NumOfSongs, FirstSong: byte;
   PSongsStructure: smallint;
 end;

 TSongStructure = packed record
   PSongName, PSongData: smallint;
 end;

 TSongData = packed record
   ChanA, ChanB, ChanC, Noise: byte;
   SongLength: word;
   FadeLength: word;
   HiReg, LoReg: byte;
   PPoints, PAddresses: smallint;
 end;

 TPoints = packed record
   Stek, Init, Inter: word;
 end;

 //AYM-file header
 TAYMFileHeader = packed record
   AYM: array[0..2] of char;
   Rev: char;
   Name: array[0..27] of char;
   Author: array[0..15] of char;
   Init, Play: word;
   MusMin, MusMax, MusPos, RegPos: byte;
   AF, BC, DE, HL, IX, IY: word;
   Blocks: byte;
 end;

 TAYMBlock = packed record
   start, size: word;
 end;

 //VTX-file header
 TVTXFileHeader = packed record
   Id: word;
   Mode: byte;
   Loop: word;
   ChipFrq: dword;
   InterFrq: byte;
   Year: word;
   UnpackSize: dword;
 end;

 //YM5- and YM6-file header
 PYM5FileHeader = ^TYM5FileHeader;

 TYM5FileHeader = packed record
   Id: dword;
   Leo: array[0..7] of char;
   Num_of_tiks: dword;
   Song_Attr: dword;
   Num_of_Dig: word;
   ChipFrq: dword;
   InterFrq: word;
   Loop: dword;
   Add_Size: word;
 end;

 //LZH-file header
 TLZHFileHeader = packed record
   HSize: byte;
   ChkSum: byte;
   Method: array[1..5] of char;
   CompSize: longint;
   UCompSize: longint;
   Dos_DT: longint;
   Attr: word;
   FileNameLen: byte;
 end;

 FXM_Stek = packed array of word;

 TEPSGRec = packed record
   case boolean of
     True: (Reg, Data: byte;
       TSt: longword);
     False: (All: int64);
 end;

 PPT3_Channel_Parameters = ^PT3_Channel_Parameters;

 PT3_Channel_Parameters = record
   Address_In_Pattern,
   OrnamentPointer,
   SamplePointer,
   Ton: word;
   Loop_Ornament_Position,
   Ornament_Length,
   Position_In_Ornament,
   Loop_Sample_Position,
   Sample_Length,
   Position_In_Sample,
   Volume,
   Number_Of_Notes_To_Skip,
   Note,
   Slide_To_Note,
   Amplitude: byte;
   Envelope_Enabled,
   Enabled,
   SimpleGliss: boolean;
   Current_Amplitude_Sliding,
   Ton_Slide_Count,
   Current_OnOff,
   OnOff_Delay,
   OffOn_Delay,
   Ton_Slide_Delay,
   Current_Ton_Sliding,
   Ton_Accumulator,
   Ton_Slide_Step,
   Ton_Delta: smallint;
   Note_Skip_Counter: shortint;
   Current_Noise_Sliding,
   Current_Envelope_Sliding: byte;
 end;

 PPT3_Parameters = ^PT3_Parameters;

 PT3_Parameters = record
   Env_Base: packed record
     case boolean of
       True: (wrd: smallint);
       False: (lo: byte;
         hi: byte);
     end;
   Cur_Env_Slide,
   Env_Slide_Add: smallint;
   Cur_Env_Delay,
   Env_Delay: shortint;
   Noise_Base,
   Delay,
   AddToNoise,
   DelayCounter,
   CurrentPosition: byte;
 end;

 PPT2_Channel_Parameters = ^PT2_Channel_Parameters;

 PT2_Channel_Parameters = record
   Address_In_Pattern,
   OrnamentPointer,
   SamplePointer,
   Ton: word;
   Loop_Ornament_Position,
   Ornament_Length,
   Position_In_Ornament,
   Loop_Sample_Position,
   Sample_Length,
   Position_In_Sample,
   Volume,
   Number_Of_Notes_To_Skip,
   Note,
   Slide_To_Note,
   Amplitude: byte;
   Current_Ton_Sliding,
   Ton_Delta: smallint;
   GlissType: integer;
   Envelope_Enabled,
   Enabled: boolean;
   Glissade,
   Addition_To_Noise,
   Note_Skip_Counter: shortint
 end;
 PPT2_Parameters = ^PT2_Parameters;

 PT2_Parameters = record
   DelayCounter,
   Delay,
   CurrentPosition: byte;
 end;

 PSTC_Channel_Parameters = ^STC_Channel_Parameters;

 STC_Channel_Parameters = record
   Address_In_Pattern,
   SamplePointer,
   OrnamentPointer,
   Ton: word;
   Amplitude,
   Note,
   Position_In_Sample,
   Number_Of_Notes_To_Skip: byte;
   Sample_Tik_Counter,
   Note_Skip_Counter: shortint;
   Envelope_Enabled: boolean;
 end;
 PSTC_Parameters = ^STC_Parameters;

 STC_Parameters = record
   DelayCounter,
   Transposition,
   CurrentPosition: byte;
 end;

 PSTP_Channel_Parameters = ^STP_Channel_Parameters;

 STP_Channel_Parameters = record
   OrnamentPointer,
   SamplePointer,
   Address_In_Pattern,
   Ton: word;
   Position_In_Ornament,
   Loop_Ornament_Position,
   Ornament_Length,
   Position_In_Sample,
   Loop_Sample_Position,
   Sample_Length,
   Volume,
   Number_Of_Notes_To_Skip,
   Note,
   Amplitude: byte;
   Current_Ton_Sliding: smallint;
   Envelope_Enabled,
   Enabled: boolean;
   Glissade,
   Note_Skip_Counter: shortint
 end;
 PSTP_Parameters = ^STP_Parameters;

 STP_Parameters = record
   DelayCounter,
   CurrentPosition,
   Transposition: byte;
 end;

 PASC_Channel_Parameters = ^ASC_Channel_Parameters;

 ASC_Channel_Parameters = record
   Initial_Point_In_Sample,
   Point_In_Sample,
   Loop_Point_In_Sample,
   Initial_Point_In_Ornament,
   Point_In_Ornament,
   Loop_Point_In_Ornament,
   Address_In_Pattern,
   Ton,
   Ton_Deviation: word;
   Note,
   Addition_To_Note,
   Number_Of_Notes_To_Skip,
   Initial_Noise,
   Current_Noise,
   Volume,
   Ton_Sliding_Counter,
   Amplitude,
   Amplitude_Delay,
   Amplitude_Delay_Counter: byte;
   Current_Ton_Sliding,
   Substruction_for_Ton_Sliding: smallint;
   Note_Skip_Counter,
   Addition_To_Amplitude: shortint;
   Envelope_Enabled,
   Sound_Enabled,
   Sample_Finished,
   Break_Sample_Loop,
   Break_Ornament_Loop: boolean;
 end;
 PASC_Parameters = ^ASC_Parameters;

 ASC_Parameters = record
   Delay,
   DelayCounter,
   CurrentPosition: byte;
 end;

 PPSC_Channel_Parameters = ^PSC_Channel_Parameters;

 PSC_Channel_Parameters = record
   Address_In_Pattern,
   OrnamentPointer,
   SamplePointer,
   Ton: word;
   Current_Ton_Sliding,
   Ton_Accumulator,
   Addition_To_Ton: smallint;
   Initial_Volume,
   Note_Skip_Counter: shortint;
   Note,
   Volume,
   Amplitude,
   Volume_Counter,
   Volume_Counter1,
   Volume_Counter_Init,
   Noise_Accumulator,
   Position_In_Sample,
   Loop_Sample_Position,
   Position_In_Ornament,
   Loop_Ornament_Position: byte;
   Enabled,
   Ornament_Enabled,
   Envelope_Enabled,
   Gliss,
   Ton_Slide_Enabled,
   Break_Sample_Loop,
   Break_Ornament_Loop,
   Volume_Inc: boolean;
 end;

 PPSC_Parameters = ^PSC_Parameters;

 PSC_Parameters = record
   Delay,
   DelayCounter,
   Lines_Counter,
   Noise_Base,
   Positions_Pointer: word;
 end;

 PSQT_Channel_Parameters = ^SQT_Channel_Parameters;

 SQT_Channel_Parameters = record
   Address_In_Pattern,
   SamplePointer,
   Point_In_Sample,
   OrnamentPointer,
   Point_In_Ornament,
   Ton,
   ix27: word;
   Volume,
   Amplitude,
   Note,
   ix21: byte;
   Ton_Slide_Step,
   Current_Ton_Sliding: smallint;
   Sample_Tik_Counter,
   Ornament_Tik_Counter,
   Transposit: shortint;
   Enabled,
   Envelope_Enabled,
   Ornament_Enabled,
   Gliss,
   MixNoise,
   MixTon,
   b4ix0, b6ix0, b7ix0: boolean;
 end;

 PSQT_Parameters = ^SQT_Parameters;

 SQT_Parameters = record
   Delay,
   DelayCounter,
   Lines_Counter: byte;
   Positions_Pointer: word;
 end;

 PFTC_Channel_Parameters = ^FTC_Channel_Parameters;

 FTC_Channel_Parameters = record
   Address_In_Pattern,
   OrnamentPointer,
   SamplePointer,
   Envelope_Accumulator,
   Envelope,
   Ton: word;
   Ornament_Length,
   Loop_Ornament_Position,
   Position_In_Ornament,
   Sample_Length,
   Loop_Sample_Position,
   Position_In_Sample,
   Sample_Noise_Accumulator,
   Noise_Accumulator,
   Note_Accumulator,
   Ton_Slide_Direction,
   Volume,
   Noise,
   Amplitude,
   Previous_Note,
   Note: byte;
   Note_Skip_Counter,
   Volume_Slide: shortint;
   Addition_To_Ton,
   Ton_Slide_Step,
   Ton_Slide_Step1,
   Current_Ton_Sliding,
   Ton_Accumulator: smallint;
   Envelope_Enabled,
   Sample_Enabled: boolean;
 end;

 PFTC_Parameters = ^FTC_Parameters;

 FTC_Parameters = record
   Delay,
   DelayCounter,
   Transposition,
   CurrentPosition,
   EnvT, Retrig: byte;
 end;

 PPT1_Channel_Parameters = ^PT1_Channel_Parameters;

 PT1_Channel_Parameters = record
   Address_In_Pattern,
   OrnamentPointer,
   SamplePointer,
   Ton: word;
   Number_Of_Notes_To_Skip,
   Volume,
   Loop_Sample_Position,
   Position_In_Sample,
   Sample_Length,
   Amplitude,
   Note: byte;
   Note_Skip_Counter: shortint;
   Envelope_Enabled,
   Enabled: boolean;
 end;

 PPT1_Parameters = ^PT1_Parameters;

 PT1_Parameters = record
   Delay,
   DelayCounter,
   CurrentPosition: byte;
 end;

 PFLS_Channel_Parameters = ^FLS_Channel_Parameters;

 FLS_Channel_Parameters = record
   Address_In_Pattern,
   OrnamentPointer,
   SamplePointer,
   Ton: word;
   Sample_Length,
   Loop_Sample_Position,
   Position_In_Sample,
   Amplitude,
   Number_Of_Notes_To_Skip,
   Note: byte;
   Note_Skip_Counter,
   Sample_Tik_Counter: shortint;
   Envelope_Enabled,
   Ornament_Enabled: boolean;
 end;

 PFLS_Parameters = ^FLS_Parameters;

 FLS_Parameters = record
   Delay,
   DelayCounter,
   CurrentPosition: byte;
 end;

 PGTR_Channel_Parameters = ^GTR_Channel_Parameters;

 GTR_Channel_Parameters = record
   SamplePointer,
   OrnamentPointer,
   Address_In_Pattern,
   Ton: word;
   Position_In_Sample,
   Loop_Sample_Position,
   Sample_Length,
   Position_In_Ornament,
   Loop_Ornament_Position,
   Ornament_Length,
   Volume,
   Note,
   Amplitude: byte;
   Note_Skip_Counter: shortint;
   Envelope_Enabled,
   Enabled: boolean;
 end;

 PGTR_Parameters = ^GTR_Parameters;

 GTR_Parameters = record
   DelayCounter,
   CurrentPosition: byte;
 end;

 PFXM_Channel_Parameters = ^FXM_Channel_Parameters;

 FXM_Channel_Parameters = record
   Address_In_Pattern,
   Point_In_Sample,
   SamplePointer,
   Point_In_Ornament,
   OrnamentPointer,
   Ton: word;
   FXM_Mixer,
   Note,
   Volume,
   Amplitude: byte;
   Transposit,
   Note_Skip_Counter,
   Sample_Tik_Counter: shortint;
   b0e, b1e, b2e, b3e: boolean;
 end;

 PFXM_Parameters = ^FXM_Parameters;

 FXM_Parameters = record
   Noise_Base: byte;
 end;

 PPSM_Channel_Parameters = ^PSM_Channel_Parameters;

 PSM_Channel_Parameters = record
   Address_In_Pattern,
   RetAddress,
   DivShift, Ton: word;
   Number_Of_Notes_To_Skip, Note_Skip_Counter,
   Amplitude, RetCnt, Vol, VolCnt, LoopCnt, Orn, EnvType, EnvDiv, Samp: byte;
   OrnTick, SmpTick, Note: shortint;
 end;

 PPSM_Parameters = ^PSM_Parameters;

 PSM_Parameters = record
   Delay,
   DelayCounter: byte;
   CurrentPosition: byte;
   Transposition: shortint;
   Finished: boolean;
 end;

 TPlParams = record
   case integer of
     0: (PT3: PT3_Parameters;
       PT3_A, PT3_B, PT3_C: PT3_Channel_Parameters);
     1: (PT2: PT2_Parameters;
       PT2_A, PT2_B, PT2_C: PT2_Channel_Parameters);
     2: (PT1: PT1_Parameters;
       PT1_A, PT1_B, PT1_C: PT1_Channel_Parameters);
     3: (STC: STC_Parameters;
       STC_A, STC_B, STC_C: STC_Channel_Parameters);
     4: (STP: STP_Parameters;
       STP_A, STP_B, STP_C: STP_Channel_Parameters);
     5: (ASC: ASC_Parameters;
       ASC_A, ASC_B, ASC_C: ASC_Channel_Parameters);
     6: (PSC: PSC_Parameters;
       PSC_A, PSC_B, PSC_C: PSC_Channel_Parameters);
     7: (SQT: SQT_Parameters;
       SQT_A, SQT_B, SQT_C: SQT_Channel_Parameters);
     8: (FTC: FTC_Parameters;
       FTC_A, FTC_B, FTC_C: FTC_Channel_Parameters);
     9: (FLS: FLS_Parameters;
       FLS_A, FLS_B, FLS_C: FLS_Channel_Parameters);
     10: (GTR: GTR_Parameters;
       GTR_A, GTR_B, GTR_C: GTR_Channel_Parameters);
     11: (FXM: FXM_Parameters;
       FXM_A, FXM_B, FXM_C: FXM_Channel_Parameters);
     12: (PSM: PSM_Parameters;
       PSM_A, PSM_B, PSM_C: PSM_Channel_Parameters);
 end;

 TPlConsts = record
   RAM: PModTypes;
   Global_Tick_Counter, Global_Tick_Max: integer;
   TS: integer;
   case boolean of
     True: (Version: integer);
     False: (Address: word;
       amad_andsix: byte);
 end;

type
 PID3v1 = ^TID3v1;

 TID3v1 = packed record
   Tag: array[0..2] of char;
   Title, Author, Album: array[0..29] of char;
   Year: array[0..3] of char;
   Comment: array[0..29] of char;
   Genre: byte;
 end;
 PID3V2Header = ^TID3V2Header;

 TID3V2Header = packed record
   Tag: array[0..2] of char;
   VerMajor, VerMinor, Flags: byte;
   Size: DWORD;
 end;
 PID3V2ExtHeader = ^TID3V2ExtHeader;

 TID3V2ExtHeader = packed record
   Size: DWORD;
   Flags: word;
   PaddingSize: DWORD;
 end;
 PID3V2Frame = ^TID3V2Frame;

 TID3V2Frame = packed record
   Id, Size: DWORD;
   Flags: word;
 end;

var
 TSMode: boolean;
 ZRAM, RAM1: ModTypes;
 EPSG_TStateMax: integer;
 NumberOfVBLs, LoopVBL: integer;
 VTX_Offset, Position_In_VTX: integer;
 PVTXYMUnpackedData: PArray0OfByte;
 FinderWorksNow: boolean;
 FXM_StekA, FXM_StekB, FXM_StekC: FXM_Stek;
 PlParams: array[0..1] of TPlParams;
 PlConsts: array[0..1] of TPlConsts;
 All_GetRegisters: array[0..1] of procedure(CNum: integer);
 MakeBuffer: procedure(Buf: pointer);
 CurFileType, CurFileType1: Available_Types;
 AYSongData: TSongData;
 AYPoints: TPoints;
 AYBlocks: integer;
 AYMFileHeader: TAYMFileHeader;
 FileOpened: boolean = False;
 FileAvailable: boolean = False;
 FileLoaded: boolean = False;
 FileHandle: integer;
 YM6TiksOnInt: real;
 YM6SinusTable: array [0..15, 0..7] of byte;
 AtariTimerPeriod1, AtariTimerPeriod2: real;
 AtariTimerCounter1, AtariTimerCounter2: real;
 YM6CurTik: real;
 YM6Tiks: int64;
 CurItem: record
   PLStr, Title, Author, Programm, Comment, Tracker, FileName: string;
   end;
 CurCDNum, CurCDTrk, StreamPlayFrom: integer;

 //tunes finder options and defaults
 F_STF: boolean = True;
 F_ST1: boolean = True;
 F_STC: boolean = True;
 F_ST3: boolean = True;
 F_ASM0: boolean = True;
 F_ASM1: boolean = True;
 F_STP: boolean = True;
 F_PSC: boolean = True;
 F_FLS: boolean = True;
 F_SQT: boolean = True;
 F_PT1: boolean = True;
 F_PT2: boolean = True;
 F_PT3: boolean = True;
 F_FTC: boolean = True;
 F_GTR: boolean = True;
 IntegrityCheck: boolean = True;

function LoadTrackerModule(var Module: ModTypes; PPLItem: pointer;
 Index, MAddr, MLen: integer; Mem: pointer; FType: Available_Types): boolean;
procedure PrepareItem(Index: integer);
procedure InitForAllTypes(InitAll: boolean);
procedure InsertTitleASC(var Module: ModTypes; var Sz: integer; const TtlStr: string);
procedure InsertTitleSTP(var Module: ModTypes; var Sz: integer; const TtlStr: string);
procedure InsertTitleSTC(var Module: ModTypes; var Sz: integer; const TtlStr: string);
procedure FindModules;
{$IFDEF Windows}
procedure AddCDTrack(CDN, TN: integer; Inited: boolean);
{$ENDIF Windows}
procedure Add_Songs_From_File(File_Name: string; Detect: boolean);
procedure FreePlayingResourses;

procedure MakeBufferOUT(Buf: pointer);
procedure OUT_Get_Registers(CNum: integer);
procedure MakeBufferVTX(Buf: pointer);
procedure VTX_YM3_YM3b_Get_Registers(CNum: integer);
procedure MakeBufferYM2(Buf: pointer);
procedure YM2_Get_Registers(CNum: integer);
procedure MakeBufferYM5(Buf: pointer);
procedure YM5_Get_Registers(CNum: integer);
procedure YM5i_Get_Registers(CNum: integer);
procedure MakeBufferYM6(Buf: pointer);
procedure YM6_Get_Registers(CNum: integer);
procedure YM6i_Get_Registers(CNum: integer);
procedure YM6_Extra_GetRegisters(CNum: integer);
procedure MakeBufferEPSG(Buf: pointer);
procedure EPSG_Get_Registers(CNum: integer);
procedure MakeBufferPSG(Buf: pointer);
procedure PSG_Get_Registers(CNum: integer);
procedure MakeBufferZXAY(Buf: pointer);
procedure ZXAY_Get_Registers(CNum: integer);

procedure MakeBufferTracker(Buf: pointer);
procedure PT3_Get_Registers(CNum: integer);
procedure PT2_Get_Registers(CNum: integer);
procedure PT1_Get_Registers(CNum: integer);
procedure STC_Get_Registers(CNum: integer);
procedure STP_Get_Registers(CNum: integer);
procedure ASC_Get_Registers(CNum: integer);
procedure PSC_Get_Registers(CNum: integer);
procedure SQT_Get_Registers(CNum: integer);
procedure FTC_Get_Registers(CNum: integer);
procedure FLS_Get_Registers(CNum: integer);
procedure GTR_Get_Registers(CNum: integer);
procedure FXM_Get_Registers(CNum: integer);
procedure PSM_Get_Registers(CNum: integer);

procedure MakeBufferAY(Buf: pointer);
procedure AY_Get_Registers(CNum: integer);

procedure MakeBufferSNDH(Buf: pointer);
procedure SNDH_Get_Registers(CNum: integer);

procedure RerollMusic(newpos, maxpos: integer);

procedure GetTimeFXM(Module: PModTypes; Address: integer; var Tm, Lp: integer);
procedure GetTimeGTR(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimeSTC(Module: PModTypes; var Tm: integer);
procedure GetTimeASC(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimeSTP(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimePT2(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimePT3(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimePSC(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimeFTC(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimeSQT(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimePT1(Module: PModTypes; var Tm, Lp: integer);
procedure GetTimeFLS(Module: PModTypes; var Tm: integer);
procedure GetTimePSM(Module: PModTypes; var Tm, Lp: integer);
procedure GetTime(FileHandle: integer; PPLItem: pointer; Index: integer;
 AlreadyLoaded: pointer; var Lp: integer);

procedure YMizeSample(Buf: PArray0OfByte; Len: integer);

implementation

uses
 MainWin, UniReader, Lh5, Z80, Classes, PlayList, basscode, basstags, basslight,
 {$IFDEF Windows}
 CDviaMCI, Midi,
 {$ENDIF Windows}
 Mixer, ProgBox, Tools, digidrum, Convs, settings, sndh, atari, mc68000, Languages;

const

 StcId = 'SOUND TRACKER COMPILATION OF ';
 KsaId = 'KSA SOFTWARE COMPILATION OF ';
 AscId = 'ASM COMPILATION OF ';

 //Ton tables of different trackers
 {ASC Sound Master}
 ASM_Table: array[0..$55] of word =
   ($edc, $e07, $d3e, $c80, $bcc, $b22, $a82, $9ec, $95c, $8d6, $858,
   $7e0, $76e, $704, $69f,
   $640, $5e6, $591, $541, $4f6, $4ae, $46b, $42c, $3f0, $3b7, $382,
   $34f, $320, $2f3, $2c8,
   $2a1, $27b, $257, $236, $216, $1f8, $1dc, $1c1, $1a8, $190, $179,
   $164, $150, $13d, $12c,
   $11b, $10b, $fc, $ee, $e0, $d4, $c8, $bd, $b2, $a8, $9f, $96, $8d,
   $85, $7e, $77, $70, $6a,
   $64, $5e, $59, $54, $50, $4b, $47, $43, $3f, $3c, $38, $35, $32,
   $2f, $2d, $2a, $28, $26, $24,
   $22, $20, $1e, $1c);

 {Sound Tracker}
 ST_Table: array[0..95] of word =
   ($ef8, $e10, $d60, $c80, $bd8, $b28, $a88, $9f0, $960, $8e0, $858,
   $7e0, $77c, $708, $6b0,
   $640, $5ec, $594, $544, $4f8, $4b0, $470, $42c, $3f0, $3be, $384,
   $358, $320, $2f6, $2ca,
   $2a2, $27c, $258, $238, $216, $1f8, $1df, $1c2, $1ac, $190, $17b,
   $165, $151, $13e, $12c,
   $11c, $10b, $fc, $ef, $e1, $d6, $c8, $bd, $b2, $a8, $9f, $96, $8e,
   $85, $7e, $77, $70, $6b,
   $64, $5e, $59, $54, $4f, $4b, $47, $42, $3f, $3b, $38, $35, $32,
   $2f, $2c, $2a, $27, $25, $23,
   $21, $1f, $1d, $1c, $1a, $19, $17, $16, $15, $13, $12, $11, $10, $f);

 {SQ-Tracker}
 SQT_Table: array[0..$5f] of word =
   ($d5d, $c9c, $be7, $b3c, $a9b, $a02, $973, $8eb, $86b, $7f2, $780, $714, $6ae, $64e,
   $5f4, $59e, $54f, $501, $4b9, $475, $435, $3f9, $3c0, $38a, $357,
   $327, $2fa, $2cf, $2a7,
   $281, $25d, $23b, $21b, $1fc, $1e0, $1c5, $1ac, $194, $17d, $168,
   $153, $140, $12e, $11d,
   $10d, $fe, $f0, $e2, $d6, $ca, $be, $b4, $aa, $a0, $97, $8f, $87,
   $7f, $78, $71, $6b, $65, $5f,
   $5a, $55, $50, $4c, $47, $43, $40, $3c, $39, $35, $32, $30, $2d,
   $2a, $28, $26, $24, $22, $20,
   $1e, $1c, $1b, $19, $18, $16, $15, $14, $13, $12, $11, $10, $f, $e);

 {Fuxoft AY Language}
 FXM_Table: array[0..$53] of word =
   ($fbf, $edc, $e07, $d3d, $c7f, $bcc, $b22, $a82, $9eb, $95d, $8d6,
   $857, $7df, $76e, $703,
   $69f, $640, $5e6, $591, $541, $4f6, $4ae, $46b, $42c, $3f0, $3b7,
   $382, $34f, $320, $2f3,
   $2c8, $2a1, $27b, $257, $236, $216, $1f8, $1dc, $1c1, $1a8, $190,
   $179, $164, $150, $13d,
   $12c, $11b, $10b, $fc, $ee, $e0, $d4, $c8, $bd, $b2, $a8, $9f, $96,
   $8d, $85, $7e, $77, $70,
   $6a, $64, $5e, $59, $54, $4f, $4b, $47, $43, $3f, $3b, $38, $35,
   $32, $2f, $2d, $2a, $28, $25,
   $23, $21);

 {Pro Sound Maker}
 PSM_Table: array[0..95] of word =
   ($D3D, $C7F, $BCB, $B22, $A82, $9EB, $95D, $8D6, $857, $7DF, $76E, $703,
   $69F, $63F, $5E6, $591, $541, $4F6, $4AE, $46B, $42C, $3F0, $3B7, $382,
   $34F, $320, $2F3, $2C8, $2A1, $27B, $257, $236, $216, $1F8, $1DC, $1C1,
   $1A8, $190, $179, $164, $150, $13D, $12C, $11B, $10B, $0FC, $0EE, $0E0,
   $0D4, $0C8, $0BD, $0B2, $0A8, $09F, $096, $08D, $085, $07E, $077, $070,
   $06A, $064, $05E, $059, $054, $04F, $04B, $047, $043, $03F, $03B, $038,
   $035, $032, $02F, $02D, $02A, $028, $025, $023, $021, $01F, $01E, $01C,
   $01A, $019, $018, $016, $015, $014, $013, $012, $011, $010, $00F, $00E);

 {Table # 2 of Fast Tracker 1.07-1.08}
 FTCNoteTable2: array[0..95] of word =
   ($0D10, $0C58, $0BA0, $0B00, $0A60, $09C8, $0940, $08B8, $0840, $07C0, $0750, $06F0,
   $0688, $062C, $05D0, $0580, $0530, $04E4, $04A0, $045C, $0420, $03E0, $03A8, $0378,
   $0344, $0316, $02E8, $02C0, $0298, $0272, $0250, $022E, $0210, $01F0, $01D4, $01BC,
   $01A2, $018B, $0174, $0160, $014C, $0139, $0128, $0117, $0108, $00F8, $00EA, $00DE,
   $00D1, $00C5, $00BA, $00B0, $00A6, $009C, $0094, $008B, $0084, $007C, $0075, $006F,
   $0068, $0062, $005D, $0058, $0053, $004E, $004A, $0045, $0042, $003E, $003A, $0037,
   $0034, $0031, $002E, $002C, $0029, $0027, $0025, $0022, $0021, $001F, $001D, $001B,
   $001A, $0018, $0017, $0016, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D);

type
 PT3ToneTable = array[0..95] of word;
 PT3VolTable = array[0..15, 0..15] of byte;

const
 {Table #0 of Pro Tracker 3.3x - 3.4r}
 PT3NoteTable_PT_33_34r: PT3ToneTable = (
   $0C21, $0B73, $0ACE, $0A33, $09A0, $0916, $0893, $0818, $07A4, $0736, $06CE, $066D,
   $0610, $05B9, $0567, $0519, $04D0, $048B, $0449, $040C, $03D2, $039B, $0367, $0336,
   $0308, $02DC, $02B3, $028C, $0268, $0245, $0224, $0206, $01E9, $01CD, $01B3, $019B,
   $0184, $016E, $0159, $0146, $0134, $0122, $0112, $0103, $00F4, $00E6, $00D9, $00CD,
   $00C2, $00B7, $00AC, $00A3, $009A, $0091, $0089, $0081, $007A, $0073, $006C, $0066,
   $0061, $005B, $0056, $0051, $004D, $0048, $0044, $0040, $003D, $0039, $0036, $0033,
   $0030, $002D, $002B, $0028, $0026, $0024, $0022, $0020, $001E, $001C, $001B, $0019,
   $0018, $0016, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D, $000C);

 {Table #0 of Pro Tracker 3.4x - 3.5x}
 PT3NoteTable_PT_34_35: PT3ToneTable = (
   $0C22, $0B73, $0ACF, $0A33, $09A1, $0917, $0894, $0819, $07A4, $0737, $06CF, $066D,
   $0611, $05BA, $0567, $051A, $04D0, $048B, $044A, $040C, $03D2, $039B, $0367, $0337,
   $0308, $02DD, $02B4, $028D, $0268, $0246, $0225, $0206, $01E9, $01CE, $01B4, $019B,
   $0184, $016E, $015A, $0146, $0134, $0123, $0112, $0103, $00F5, $00E7, $00DA, $00CE,
   $00C2, $00B7, $00AD, $00A3, $009A, $0091, $0089, $0082, $007A, $0073, $006D, $0067,
   $0061, $005C, $0056, $0052, $004D, $0049, $0045, $0041, $003D, $003A, $0036, $0033,
   $0031, $002E, $002B, $0029, $0027, $0024, $0022, $0020, $001F, $001D, $001B, $001A,
   $0018, $0017, $0016, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D, $000C);

 {Table #1 of Pro Tracker 3.3x - 3.5x)}
 PT3NoteTable_ST: PT3ToneTable = (
   $0EF8, $0E10, $0D60, $0C80, $0BD8, $0B28, $0A88, $09F0, $0960, $08E0, $0858, $07E0,
   $077C, $0708, $06B0, $0640, $05EC, $0594, $0544, $04F8, $04B0, $0470, $042C, $03FD,
   $03BE, $0384, $0358, $0320, $02F6, $02CA, $02A2, $027C, $0258, $0238, $0216, $01F8,
   $01DF, $01C2, $01AC, $0190, $017B, $0165, $0151, $013E, $012C, $011C, $010A, $00FC,
   $00EF, $00E1, $00D6, $00C8, $00BD, $00B2, $00A8, $009F, $0096, $008E, $0085, $007E,
   $0077, $0070, $006B, $0064, $005E, $0059, $0054, $004F, $004B, $0047, $0042, $003F,
   $003B, $0038, $0035, $0032, $002F, $002C, $002A, $0027, $0025, $0023, $0021, $001F,
   $001D, $001C, $001A, $0019, $0017, $0016, $0015, $0013, $0012, $0011, $0010, $000F);

 {Table #2 of Pro Tracker 3.4r}
 PT3NoteTable_ASM_34r: PT3ToneTable = (
   $0D3E, $0C80, $0BCC, $0B22, $0A82, $09EC, $095C, $08D6, $0858, $07E0, $076E, $0704,
   $069F, $0640, $05E6, $0591, $0541, $04F6, $04AE, $046B, $042C, $03F0, $03B7, $0382,
   $034F, $0320, $02F3, $02C8, $02A1, $027B, $0257, $0236, $0216, $01F8, $01DC, $01C1,
   $01A8, $0190, $0179, $0164, $0150, $013D, $012C, $011B, $010B, $00FC, $00EE, $00E0,
   $00D4, $00C8, $00BD, $00B2, $00A8, $009F, $0096, $008D, $0085, $007E, $0077, $0070,
   $006A, $0064, $005E, $0059, $0054, $0050, $004B, $0047, $0043, $003F, $003C, $0038,
   $0035, $0032, $002F, $002D, $002A, $0028, $0026, $0024, $0022, $0020, $001E, $001D,
   $001B, $001A, $0019, $0018, $0015, $0014, $0013, $0012, $0011, $0010, $000F, $000E);

 {Table #2 of Pro Tracker 3.4x - 3.5x}
 PT3NoteTable_ASM_34_35: PT3ToneTable = (
   $0D10, $0C55, $0BA4, $0AFC, $0A5F, $09CA, $093D, $08B8, $083B, $07C5, $0755, $06EC,
   $0688, $062A, $05D2, $057E, $052F, $04E5, $049E, $045C, $041D, $03E2, $03AB, $0376,
   $0344, $0315, $02E9, $02BF, $0298, $0272, $024F, $022E, $020F, $01F1, $01D5, $01BB,
   $01A2, $018B, $0174, $0160, $014C, $0139, $0128, $0117, $0107, $00F9, $00EB, $00DD,
   $00D1, $00C5, $00BA, $00B0, $00A6, $009D, $0094, $008C, $0084, $007C, $0075, $006F,
   $0069, $0063, $005D, $0058, $0053, $004E, $004A, $0046, $0042, $003E, $003B, $0037,
   $0034, $0031, $002F, $002C, $0029, $0027, $0025, $0023, $0021, $001F, $001D, $001C,
   $001A, $0019, $0017, $0016, $0015, $0014, $0012, $0011, $0010, $000F, $000E, $000D);

 {Table #3 of Pro Tracker 3.4r}
 PT3NoteTable_REAL_34r: PT3ToneTable = (
   $0CDA, $0C22, $0B73, $0ACF, $0A33, $09A1, $0917, $0894, $0819, $07A4, $0737, $06CF,
   $066D, $0611, $05BA, $0567, $051A, $04D0, $048B, $044A, $040C, $03D2, $039B, $0367,
   $0337, $0308, $02DD, $02B4, $028D, $0268, $0246, $0225, $0206, $01E9, $01CE, $01B4,
   $019B, $0184, $016E, $015A, $0146, $0134, $0123, $0113, $0103, $00F5, $00E7, $00DA,
   $00CE, $00C2, $00B7, $00AD, $00A3, $009A, $0091, $0089, $0082, $007A, $0073, $006D,
   $0067, $0061, $005C, $0056, $0052, $004D, $0049, $0045, $0041, $003D, $003A, $0036,
   $0033, $0031, $002E, $002B, $0029, $0027, $0024, $0022, $0020, $001F, $001D, $001B,
   $001A, $0018, $0017, $0016, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D);

 {Table #3 of Pro Tracker 3.4x - 3.5x}
 PT3NoteTable_REAL_34_35: PT3ToneTable = (
   $0CDA, $0C22, $0B73, $0ACF, $0A33, $09A1, $0917, $0894, $0819, $07A4, $0737, $06CF,
   $066D, $0611, $05BA, $0567, $051A, $04D0, $048B, $044A, $040C, $03D2, $039B, $0367,
   $0337, $0308, $02DD, $02B4, $028D, $0268, $0246, $0225, $0206, $01E9, $01CE, $01B4,
   $019B, $0184, $016E, $015A, $0146, $0134, $0123, $0112, $0103, $00F5, $00E7, $00DA,
   $00CE, $00C2, $00B7, $00AD, $00A3, $009A, $0091, $0089, $0082, $007A, $0073, $006D,
   $0067, $0061, $005C, $0056, $0052, $004D, $0049, $0045, $0041, $003D, $003A, $0036,
   $0033, $0031, $002E, $002B, $0029, $0027, $0024, $0022, $0020, $001F, $001D, $001B,
   $001A, $0018, $0017, $0016, $0014, $0013, $0012, $0011, $0010, $000F, $000E, $000D);

 {Volume table of Pro Tracker 3.3x - 3.4x}
 PT3VolumeTable_33_34: PT3VolTable = (
   ($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00),
   ($00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01),
   ($00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02),
   ($00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03),
   ($00, $00, $00, $00, $01, $01, $01, $02, $02, $02, $03, $03, $03, $04, $04, $04),
   ($00, $00, $00, $01, $01, $01, $02, $02, $03, $03, $03, $04, $04, $04, $05, $05),
   ($00, $00, $00, $01, $01, $02, $02, $03, $03, $03, $04, $04, $05, $05, $06, $06),
   ($00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07),
   ($00, $00, $01, $01, $02, $02, $03, $03, $04, $05, $05, $06, $06, $07, $07, $08),
   ($00, $00, $01, $01, $02, $03, $03, $04, $05, $05, $06, $06, $07, $08, $08, $09),
   ($00, $00, $01, $02, $02, $03, $04, $04, $05, $06, $06, $07, $08, $08, $09, $0A),
   ($00, $00, $01, $02, $03, $03, $04, $05, $06, $06, $07, $08, $09, $09, $0A, $0B),
   ($00, $00, $01, $02, $03, $04, $04, $05, $06, $07, $08, $08, $09, $0A, $0B, $0C),
   ($00, $00, $01, $02, $03, $04, $05, $06, $07, $07, $08, $09, $0A, $0B, $0C, $0D),
   ($00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E),
   ($00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F));

 {Volume table of Pro Tracker 3.5x}
 PT3VolumeTable_35: PT3VolTable =
   ( //Amplitude := round((Volume * 17 + byte(Volume > 7)) * Sample_Amplitude / 256);
   ($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00),
   ($00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01),
   ($00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02),
   ($00, $00, $00, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $03, $03, $03),
   ($00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $04, $04),
   ($00, $00, $01, $01, $01, $02, $02, $02, $03, $03, $03, $04, $04, $04, $05, $05),
   ($00, $00, $01, $01, $02, $02, $02, $03, $03, $04, $04, $04, $05, $05, $06, $06),
   ($00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07),
   ($00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $08),
   ($00, $01, $01, $02, $02, $03, $04, $04, $05, $05, $06, $07, $07, $08, $08, $09),
   ($00, $01, $01, $02, $03, $03, $04, $05, $05, $06, $07, $07, $08, $09, $09, $0A),
   ($00, $01, $01, $02, $03, $04, $04, $05, $06, $07, $07, $08, $09, $0A, $0A, $0B),
   ($00, $01, $02, $02, $03, $04, $05, $06, $06, $07, $08, $09, $0A, $0A, $0B, $0C),
   ($00, $01, $02, $03, $03, $04, $05, $06, $07, $08, $09, $0A, $0A, $0B, $0C, $0D),
   ($00, $01, $02, $03, $04, $05, $06, $07, $07, $08, $09, $0A, $0B, $0C, $0D, $0E),
   ($00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F));

 st1nts: array[1..7] of integer =
   (9, 11, 0, 2, 4, 5, 7);

type
 //TAGs in players' code for modules finder
 TF_TagTypes = (F_Tag_No, F_Tag_ASC, F_Tag_STP, F_Tag_STC, F_Tag_ST3);

var
 F_Frame: PModTypes;
 Readen1, F_Length, F_Address: integer;
 F_PlayerTag: record
   Player_Offset: integer;
   TagType: TF_TagTypes;
   Value: string;
   end;
 DDrumSamples: array of record
   Length: integer;
   Buf: PArray0OfByte;
   end;
 AtariSE1Type, AtariSE2Type, AtariSE1Channel, AtariSE2Channel: byte;
 AtariV1, AtariV2: byte;
 AtariParam1, AtariParam2: byte;
 AtariSE1Pos, AtariSE2Pos: integer;
 AtariSE1TP, AtariSE2TP: byte;
 YM6SinusPos1, YM6SinusPos2: integer;

procedure RaiseBadFileStructure;
begin
 raise EFileStructureError.Create(Errors[ErBadFileStructure]);
end;

function STFDepackInit(psize: integer; out pos1, pos2: integer): boolean;
begin
 if psize < 2 then
   Exit(False);
 pos1 := 1;
 pos2 := 0;
 Result := True;
end;

function STFDepackBytes(var buf1: TSTFPacked; var buf2: TSTFUnpacked;
 var pos1, pos2: integer; const psize: integer;
 const dsize: integer = STF_MaxSize): boolean;

 function GetByte: integer;
 begin
   if pos1 >= psize then
     Result := -1
   else
    begin
     Result := buf1[pos1];
     Inc(pos1);
    end;
 end;

 //заполняем область из c повторяющихся байтов b
 function FillBufByte(c: integer; b: byte): boolean;
 begin
   if pos2 + c > STF_MaxSize then
     Exit(False);
   FillChar(buf2[pos2], c, b);
   Inc(pos2, c);
   Result := True;
 end;

 //дублируем подстроку байтов длиной c, смещение с конца Ofs=OfsH*256+buf1[pos1]
 function MoveBufBytes(c: integer; OfsH: byte): boolean;
 var
   from: integer;
 begin
   if (pos2 + c > STF_MaxSize) then
     Exit(False);
   from := pos2 - word(OfsH) shl 8 - GetByte;
   if from < 0 then
     Exit(False);
   while c > 0 do
     //Move работает не побайтово, потому не годится для имитации ldir
    begin
     buf2[pos2] := buf2[from];
     Inc(pos2);
     Inc(from);
     Dec(c);
    end;
   Result := True;
 end;

 //переносим подстроку байтов длиной c
 function MoveBuf1Bytes(c: integer): boolean;
 begin
   if (pos2 + c > STF_MaxSize) then
     Exit(False);
   if (pos1 + c > psize) then
     Exit(False);
   Move(buf1[pos1], buf2[pos2], c);
   Inc(pos2, c);
   Inc(pos1, c);
   Result := True;
 end;

var
 a, b: integer;
begin
 if pos2 < 0 then
   //распаковка окончена на предыдущем вызове
   Exit(False);
 while pos2 < dsize do
  begin
   a := GetByte;
   if a < 0 then
     Exit(False);
   if a and 1 <> 0 then
    begin
     if a and 2 <> 0 then
      begin
       if a and 4 <> 0 then //два одинаковых байта
        begin
         if not FillBufByte(2, a shr 3 - 1) then
           Exit(False);
        end
       else //первый байт оригинала -> последний распaкованного
        begin
         if not FillBufByte(1, buf1[0]) then
           Exit(False);
         pos2 := -pos2;
         //маркер того, что распаковка окончена
         break; //конец распаковки
        end;
      end
     else //длина и старший байт смещения закодированы в одном байте
     if not MoveBufBytes(a shr 5 + 3, (a shr 2) and 7) then
       Exit(False);
    end
   else
    begin
     if a and 2 <> 0 then
      begin
       if a and 4 <> 0 then
        begin
         if not MoveBuf1Bytes(a shr 3 + 1) then
           Exit(False);
        end
       else
        begin
         b := GetByte;
         if b < 0 then
           Exit(False);
         if not MoveBufBytes(b + 3, a shr 3) then
           Exit(False);
        end;
      end
     else
      begin
       b := GetByte;
       if b < 0 then
         Exit(False);
       if a and 4 <> 0 then
        begin
         if not FillBufByte(a shr 3 + 3, b) then
           Exit(False);
        end
       else
        begin
         a := (a and $F8) shl 5 + b + 3;
         b := GetByte;
         if b < 0 then
           Exit(False);
         if not FillBufByte(a, b) then
           Exit(False);
        end;
      end;
    end;
  end;
 Result := True;
end;

function STFDepack(var m: ModTypes; var msize: integer): boolean;
var
 pos1, pos2: integer;
 buf2: TSTFUnpacked;
begin
 if STFDepackInit(msize, pos1, pos2) then
   if (STFDepackBytes(PSTFPacked(@m)^, buf2, pos1, pos2, msize)) and (pos2 < 0) then
    begin
     msize := -pos2;
     Move(buf2, m, msize);
     Exit(True);
    end;
 Result := False;
end;

function STF2STP(var m: ModTypes; var msize: integer): boolean;
var
 Pats: array of string;

 function AddPat(const pat: string): integer;
 var
   l, i: integer;
 begin
   Result := 0;
   l := Length(Pats);
   for i := 0 to l - 1 do
     if Pats[i] <> pat then
       Inc(Result, Length(Pats[i]))
     else
       exit;
   SetLength(Pats, l + 1);
   Pats[l] := pat;
 end;

var
 pat: string;
 empty: integer;

 function CalcEmpty(i, j, c: integer): integer;
 var
   n, newempty: integer;
 begin
   newempty := 0;
   for n := j + 1 to m.STF_PatLens[i] - 1 do
    begin
     if (m.STF_Patterns[i][n, c].Nt and $F0 <> 0) or //note or R--
       (m.STF_Patterns[i][n, c].SmCmd and $F <> 0) or
       //slide (1-2), envt(8-E), orn (F) or undocumented 0 orn (3-7)
       (m.STF_Patterns[i][n, c].Param and $F0 <> 0) then //volume
       break;
     Inc(newempty);
    end;
   if newempty <> empty then
    begin
     empty := newempty;
     pat := pat + char($80 + empty);
    end;
   Result := empty;
 end;

var
 mc: ModTypes;
 PatsUsed: array[1..31] of boolean;

 function InsertUnusedPatterns: boolean;
 var
   i, pofs: integer;
   b: byte;
 begin
   FillChar(PatsUsed, SizeOf(PatsUsed), 0);
   pofs := msize - STF_PrePatsSize;
   for i := 0 to 255 do
    begin
     b := m.STF_Positions[i].Pat;
     if not (b in [1..31]) then
       Exit(False);
     if not PatsUsed[b] then
      begin
       PatsUsed[b] := True;
       Dec(pofs, STF_PatSize);
       if pofs < 0 then
         //заявлено паттернов больше, чем есть в наличии
         Exit(False);
      end;
    end;

   Move(m.Index[STF_PrePatsSize], mc, msize - STF_PrePatsSize);

   pofs := 0;
   msize := STF_PrePatsSize;
   for i := 1 to 31 do
    begin
     if PatsUsed[i] then
      begin
       Move(mc.Index[pofs], m.Index[msize], STF_PatSize);
       Inc(pofs, STF_PatSize);
      end;
     //   else
     //  FillChar(m.Index[pos2],STF_PatSize,0); //не обязательно, обращений к не используемому паттерну не будет
     Inc(msize, STF_PatSize);
    end;
   Result := True;
 end;

var
 PatsUsedMax: integer;
 CPats: array[1..31] of TSTPPat;
 SamsUsed: array[1..15] of boolean;
 OrnsUsed: array[0..15] of boolean;
 i, patn, chn, lin, Note, Octave, Diez, Sample, Ornament, Volume,
 SlideT, SlideD, EnvT, EnvP, sam, env, orn, sld, vol: integer;
 b: byte;
 s: shortint;
 w: smallint;

 patsofs, ornofs, samofs, curofs: integer;
const
 STP_id: string = 'KSA SOFTWARE COMPILATION OF ';
begin
 if msize < STF_MinSize then
   Exit(False);

 //unused patterns was removed before packing, so need to move some pats now
 if not InsertUnusedPatterns then
   Exit(False);

 FillChar(CPats, SizeOf(CPats), 0);
 FillChar(PatsUsed, SizeOf(PatsUsed), 0);
 FillChar(SamsUsed, SizeOf(SamsUsed), 0);
 FillChar(OrnsUsed, SizeOf(OrnsUsed), 0);
 OrnsUsed[0] := True;
 PatsUsedMax := 0;
 for i := 0 to m.STF_PosLen do
   //или to 255, если надо повторить глюк оригинального компилятора
  begin
   b := m.STF_Positions[i].Pat;
   //  if not (b in [1..31]) then //эта проверка уже сделана в InsertUnusedPatterns
   // exit(False);
   if not (m.STF_PatLens[b] in [1..64]) then
     Exit(False);
   if b > PatsUsedMax then
     PatsUsedMax := b;
   PatsUsed[b] := True;
  end;

 if msize < STF_MinSize + STF_PatSize * (PatsUsedMax - 1) then
   Exit(False);

 for patn := 1 to 31 do
   if PatsUsed[patn] then
     for chn := 0 to 2 do
      begin
       pat := '';
       empty := -1;
       sam := -1;
       env := 0;
       orn := -1;
       sld := 0;
       vol := -1;
       lin := 0;
       while lin < m.STF_PatLens[patn] do
        begin
         b := m.STF_Patterns[patn][lin, chn].SmCmd;
         Sample := b shr 4;
         Ornament := -1;
         SlideT := 0;
         EnvT := 0;
         Volume := 0;
         b := b and 15;
         case b of
           1: begin
             SlideT := 1;
             //KSA в stprhelp.txt пишет, что диапазон 0..7F, в реале 0..FF,
             //т.е. команда 0101=02FF и наоборот, 0201=01FF
             SlideD := m.STF_Patterns[patn][lin, chn].Param;
            end;
           2: begin
             SlideT := -1;
             SlideD := -m.STF_Patterns[patn][lin, chn].Param;
            end;
           8..14:
            begin
             EnvT := b;
             EnvP := m.STF_Patterns[patn][lin, chn].Param;
             env := 1;
            end;
         else
          begin
           Volume := m.STF_Patterns[patn][lin, chn].Param shr 4;
           //if Volume = 1 then Volume := 2; //имитация ошибки оригинального компилятора
           if b = 15 then
            begin
             Ornament := m.STF_Patterns[patn][lin, chn].Param and 15;
             OrnsUsed[Ornament] := True;
            end
           else if b <> 0 then //3..7
             Ornament := 0;
           //недокументированное KSA в stprhelp.txt поведение
           //и редактора, и оригинального компилятора
          end;
          end;

         b := m.STF_Patterns[patn][lin, chn].Nt;
         if b in [$F0..$F7] then
           //возможно R это просто флажок bit7, остальные биты - случайны
           Note := -2 //R--
         else
          begin
           Note := b shr 4;
           if Note = 0 then
             Note := -1 //no note
           else if Note in [1..7] then
            begin
             Diez := Ord(b and 8 <> 0);
             if (Note in [2, 5]) and (Diez <> 0) then
               Exit(False);
             Octave := b and 7;
             Note := st1nts[Note] + Octave * 12 + Diez;
             //0..95, проверка не требуется
            end
           else
             Exit(False);
          end;
         //sample в редакторе применяется только с нотой, но при применении с R--
         //оригинальный комилятор его не игнорирует, в результате после родной
         //компиляции звучит не так, как в редакторе
         if (Sample > 0) and (sam <> Sample) and (Note >= 0) then
          begin
           SamsUsed[Sample] := True;
           pat := pat + char($60 + Sample);
           sam := Sample;
          end;
         if (Ornament >= 0) and ((orn <> Ornament) or (sld <> 0) or
           //if slide was turned on before, don't skip orn set
           (env <> 0) //орнамент еще и огибающую отключает
           ) then
          begin
           pat := pat + char($70 + Ornament);
           orn := Ornament;
           sld := 0;
           env := 0;
          end;
         if EnvT > 0 then
           pat := pat + char($C0 + EnvT) + char(EnvP);
         if SlideT <> 0 then
          begin
           pat := pat + char($F0) + char(SlideD);
           sld := SlideT;
          end;
         if (Note >= 0) and (EnvT > 0) then
           //для нот с огибающей компилятором выставляется громкость F
           Volume := 15;
      {глюк оригинального компилятора - может проигнорить (но не всегда)
       установку громкости в ситуации:
       --- 00E0
       C-4 2E3F
       C-3 10E0 <--- вот эту
       C-4 2E3F
       почему иногда нормально, иногда нет, понять не удалось, хотя ради
       спортивного интереса хотелось повторить глюк}
         if (Volume > 0) and (vol <> Volume) then
          begin
           pat := pat + char($100 - Volume);
           vol := Volume;
          end;

         Inc(lin, CalcEmpty(patn, lin, chn) + 1);
         case Note of
           -2: pat := pat + char($D0);
           -1: pat := pat + char($E0);
         else
           pat := pat + char(Note + 1);
          end;
        end;
       CPats[patn].Ofs[chn] := AddPat(pat + #0);
      end;

 mc.STP_Delay := m.STF_Delay;
 curofs := 10;
 if Trim(m.STF_Title) <> '' then
  begin
   Move(STP_id[1], mc.Index[curofs], Length(STP_id));
   Inc(curofs, Length(STP_id));
   Move(m.STF_Title[1], mc.Index[curofs], 25);
   Inc(curofs, 25);
  end;

 patsofs := curofs;
 for i := 0 to Length(Pats) - 1 do
  begin
   if curofs + Length(Pats[i]) > 65536 then
     Exit(False);
   Move(Pats[i][1], mc.Index[curofs], Length(Pats[i]));
   Inc(curofs, Length(Pats[i]));
  end;

 //в оригинальном компиляторе компилируются даже неиспользуемые орнаменты
{for i := 0 to 15 do
 OrnsUsed[i] := True;}

 ornofs := curofs;
 for i := 0 to 15 do
   //в идеале 0-й орнамент - 32 нуля, но встречаются с LpE=29
   //(хотя в редакторе это не редактируется)
   if OrnsUsed[i] then
    begin
     if (m.STF_Ornaments[i].LpE > 29) or (m.STF_Ornaments[i].LpB >
       m.STF_Ornaments[i].LpE) or (curofs + m.STF_Ornaments[i].LpE > 65536 - 3) then
       Exit(False);
     mc.Index[curofs] := m.STF_Ornaments[i].LpB;
     Inc(curofs);
     mc.Index[curofs] := m.STF_Ornaments[i].LpE + 1;
     Inc(curofs);
     for lin := 0 to m.STF_Ornaments[i].LpE do
      begin
       s := m.STF_Ornaments[i].Vals[lin];
       if (s < -64) or (s > 63) then
         //ограничение внутри редактора
         Exit(False);
       mc.Index[curofs] := s;
       Inc(curofs);
      end;
    end;

 samofs := curofs;
 for i := 1 to 15 do
   if SamsUsed[i] then
    begin
     if m.STF_Samples[i].LpB = 0 then
       lin := 32
     else
      begin
       if m.STF_Samples[i].LpB > 32 then
         Exit(False);
       lin := m.STF_Samples[i].LpB + m.STF_Samples[i].LpS;
       if lin > 32 then
         Exit(False);
      end;
     if curofs + lin * $80 > 65536 - 2 then
       Exit(False);
     mc.Index[curofs] := m.STF_Samples[i].LpB - 1;
     Inc(curofs);
     mc.Index[curofs] := lin;
     Inc(curofs);
     for lin := 0 to lin - 1 do
      begin
       b := m.STF_Samples[i].Vl[lin];
       if b > 15 then
         Exit(False);
       if shortint(m.STF_Samples[i].NTENs[lin]) < 0 then //noise mask
         b := b or $80;
       if m.STF_Samples[i].NTENs[lin] and $40 <> 0 then //tone mask
         b := b or $10;
       mc.Index[curofs] := b;
       Inc(curofs);
       b := Ord(m.STF_Samples[i].NTENs[lin] and $20 <> 0) +
         m.STF_Samples[i].NTENs[lin] and $1f shl 1;
       mc.Index[curofs] := b;
       Inc(curofs);
       if m.STF_Samples[i].Tn[lin] and $E000 <> 0 then
         Exit(False);
       w := m.STF_Samples[i].Tn[lin] and $FFF;
       if m.STF_Samples[i].Tn[lin] and $1000 = 0 then
         w := -w;
       mc.Index[curofs] := Lo(w);
       Inc(curofs);
       mc.Index[curofs] := Hi(w);
       Inc(curofs);
      end;
    end;

 if curofs + 2 * (m.STF_PosLen + 2) > 65536 then
   Exit(False);
 mc.STP_PositionsPointer := curofs;
 mc.Index[curofs] := m.STF_PosLen + 1;
 Inc(curofs);
 mc.Index[curofs] := m.STF_LoopPos;
 Inc(curofs);
 for i := 0 to m.STF_PosLen do
  begin
   mc.Index[curofs] := (m.STF_Positions[i].Pat - 1) * 6;
   Inc(curofs);
   mc.Index[curofs] := m.STF_Positions[i].Trn;
   Inc(curofs);
  end;

 if curofs + SizeOf(TSTPPat) * PatsUsedMax > 65536 then
   Exit(False);
 mc.STP_PatternsPointer := curofs;
 //todo можно пересортировать паттерны, чтобы не было пустот
 for patn := 1 to PatsUsedMax do
  begin
   for chn := 0 to 2 do
     Inc(CPats[patn].Ofs[chn], patsofs);
   Move(CPats[patn], mc.Index[curofs], SizeOf(TSTPPat));
   Inc(curofs, SizeOf(TSTPPat));
  end;

 if curofs > 65536 - 2 * 16 then
   Exit(False);
 mc.STP_OrnamentsPointer := curofs;
 orn := ornofs;
 for i := 0 to 15 do
  begin
   Move(orn, mc.Index[curofs], 2);
   if OrnsUsed[i] then
     Inc(orn, 2 + m.STF_Ornaments[i].LpE + 1);
   Inc(curofs, 2);
  end;

 if curofs > 65536 - 2 * 15 then
   Exit(False);
 mc.STP_SamplesPointer := curofs;
 sam := samofs;
 for i := 1 to 15 do
  begin
   Move(sam, mc.Index[curofs], 2);
   if SamsUsed[i] then
    begin
     if m.STF_Samples[i].LpB = 0 then
       lin := 32
     else
       lin := m.STF_Samples[i].LpB + m.STF_Samples[i].LpS;
     Inc(sam, 2 + lin * 4);
    end;
   Inc(curofs, 2);
  end;

 mc.STP_Init_Id := PatsUsedMax * 3 + 16 + 15;

 msize := curofs;
 Move(mc, m, msize);
 Result := True;
end;

function ST12STC(var m: ModTypes; msize: integer): boolean;
var
 Pats: array of string;

 function AddPat(const pat: string): integer;
 var
   l, i: integer;
 begin
   Result := 0;
   l := Length(Pats);
   for i := 0 to l - 1 do
     if Pats[i] <> pat then
       Inc(Result, Length(Pats[i]))
     else
       exit;
   SetLength(Pats, l + 1);
   Pats[l] := pat;
 end;

var
 pat: string;
 empty: integer;

 function CalcEmpty(i, j, c: integer): integer;
 var
   n, newempty: integer;
 begin
   newempty := 0;
   for n := j + 1 to m.ST1_PatLen - 1 do
     if m.ST1_Pat[i][n][c].Nt and $F0 = 0 then
       Inc(newempty)
     else
       break;
   if newempty <> empty then
    begin
     empty := newempty;
     pat := pat + char(161 + empty);
    end;
   Result := empty;
 end;

var
 mc: ModTypes;
 CPats: array[0..ST1MaxPat] of TSTCPat;
 NPats, NPatsE, NPatsU, i, ir, j, c, n, o, Note, Octave, Diez, sam, orn, et, ep: integer;
 SmpUsed: array[1..15] of boolean;
 OrnUsed: array[0..15] of boolean;
 PatExists, PatUsed: array[0..ST1MaxPat] of boolean;
begin
 if msize > 3009 + ST1MaxPat * 576 then
   exit(False);
 if msize <= 3009 then
   exit(False);
 if (msize - 3009) mod 576 <> 0 then
   exit(False);
 NPats := (msize - 3009) div 576 - 1;
 if NPats > ST1MaxPat then
   exit(False);
 if not (m.ST1_PatLen in [1..64]) then
   exit(False);
 mc.ST_Delay := m.ST1_Del;
 mc.ST_Name := 'SONG BY ST COMPILE';

 for i := 1 to 15 do
  begin
   SmpUsed[i] := False;
   OrnUsed[i] := False;
  end;

 OrnUsed[0] := True;

 for i := 0 to ST1MaxPat do
  begin
   PatUsed[i] := False;
   PatExists[i] := False;
   CPats[i].Num := i + 1;
   CPats[i].Ofs[0] := 0;
   CPats[i].Ofs[1] := 0;
   CPats[i].Ofs[2] := 0;
  end;

 NPatsE := 0;
 NPatsU := 0;
 for i := 0 to 255 do
  begin
   n := m.ST1_Pos[i].PNum;
   if n = 0 then
     exit(False);
   Dec(n);
   if n > ST1MaxPat then
     exit(False);
   if not PatUsed[n] and (i <= m.ST1_PosLen) then
    begin
     Inc(NPatsU);
     PatUsed[n] := True;
    end;
   if not PatExists[n] then
    begin
     Inc(NPatsE);
     PatExists[n] := True;
    end;
  end;
 if NPatsU = 0 then
   exit(False);

 //cutoff unused patterns after used patterns (to fix broken modules like ishodnik.zip\SONG2.SCL\LYRA6.S)
 for i := ST1MaxPat downto 0 do
  begin
   if PatUsed[i] then break;
   if PatExists[i] then
    begin
     PatExists[i] := False;
     Dec(NPatsE);
    end;
  end;
 if NPatsE - 1 > NPats then
   exit(False);

{j := msize;
for i := ST1MaxPat downto 0 do
 if PatExists[i] then
  begin
   dec(j,576);
   if PatUsed[i] then
    Move(m.Index[j],m.ST1_Pat[i],576);
  end;}

 ir := -1;
 for i := 0 to ST1MaxPat do
   if PatExists[i] then
    begin
     Inc(ir);
     if PatUsed[i] then
      begin
       for c := 0 to 2 do
        begin
         pat := '';
         empty := -1;
         sam := -1;
         orn := -1;
         et := -1;
         ep := -1;
         j := 0;
         while j < m.ST1_PatLen do
          begin
            begin
             Note := m.ST1_Pat[ir][j][c].Nt shr 4;
             if Note = 0 then
              begin
               Inc(j, CalcEmpty(ir, j, c));
               pat := pat + #$81;
              end
             else
              begin
               CalcEmpty(ir, j, c);
               n := m.ST1_Pat[ir][j][c].ESNum shr 4;
               if (n in [1..15]) and (n <> sam) then
                begin
                 sam := n;
                 pat := pat + char($60 + n);
                 SmpUsed[n] := True;
                end;
               n := m.ST1_Pat[ir][j][c].ESNum and 15;
               if n in [7..14] then
                begin
                 if (et <> n) or (ep <> m.ST1_Pat[ir][j][c].EONum) then
                  begin
                   orn := -1;
                   et := n;
                   ep := m.ST1_Pat[ir][j][c].EONum;
                   pat := pat + char($80 + n) + char(ep);
                  end;
                end
               else if n in [1, 15] then
                begin
                 if n = 1 then
                   o := 0
                 else
                   o := m.ST1_Pat[ir][j][c].EONum and 15;
                 if o <> orn then
                  begin
                   et := -1;
                   ep := -1;
                   orn := o;
                   if (n = 1) and (o = 0) then
                     pat := pat + char($82) //strange behaviour of native compiler
                   else
                     pat := pat + char($70 + o);
                   OrnUsed[o] := True;
                  end;
                end;
               if Note and 8 = 0 then
                begin
                 Octave := m.ST1_Pat[ir][j][c].Nt and 7;
                 Diez := Ord((m.ST1_Pat[ir][j][c].Nt and 8) <> 0);
                 if (Note in [2, 5]) and (Diez <> 0) then
                   exit(False);
                 Note := st1nts[Note] + Octave * 12 + Diez;
                 if not (Note in [0..$5F]) then
                   exit(False);
                 pat := pat + char(Note);
                end
               else
                 pat := pat + #$80;
               Inc(j, empty);
              end;
            end;
           Inc(j);
          end;
         CPats[i].Ofs[c] := AddPat(pat + #$FF);
        end;
      end;
    end;

 n := 27;
 for i := 1 to 15 do
   if SmpUsed[i] then
    begin
     mc.Index[n] := i;
     Inc(n);
     for j := 0 to 31 do
      begin
       mc.Index[n] := (m.ST1_Smp[i].Vl[j] and 15) or
         ((m.ST1_Smp[i].Tn[j] and $F00) shr 4);
       Inc(n);
       mc.Index[n] := (m.ST1_Smp[i].Ns[j] and %11011111) or
         ((m.ST1_Smp[i].Tn[j] and $1000) shr 7);
       Inc(n);
       mc.Index[n] := m.ST1_Smp[i].Tn[j];
       Inc(n);
      end;
     mc.Index[n] := m.ST1_Smp[i].LPos;
     Inc(n);
     mc.Index[n] := m.ST1_Smp[i].LLen;
     Inc(n);
    end;

 mc.ST_PositionsPointer := n;
 mc.Index[n] := m.ST1_PosLen;
 Inc(n);
 Move(m.ST1_Pos, mc.Index[n], (m.ST1_PosLen + 1) * 2);
 Inc(n, (m.ST1_PosLen + 1) * 2);
 //в описании есть, а де-факто нигде не используется
 //mc.Index[n] := 255;
 //inc(n);

 mc.ST_OrnamentsPointer := n;
 for i := 0 to 15 do
   if OrnUsed[i] then
    begin
     mc.Index[n] := i;
     Inc(n);
     for j := 0 to 31 do
      begin
       mc.Index[n] := m.ST1_Orn[i][j];
       Inc(n);
      end;
    end;

 mc.ST_PatternsPointer := n;
 c := n + NPatsU * SizeOf(TSTCPat) + 1;
 for i := 0 to ST1MaxPat do
   if PatUsed[i] then
    begin
     for j := 0 to 2 do
       Inc(CPats[i].Ofs[j], c);
     Move(CPats[i], mc.Index[n], SizeOf(TSTCPat));
     Inc(n, SizeOf(TSTCPat));
    end;
 mc.Index[n] := 255;
 Inc(n);

 for i := 0 to Length(Pats) - 1 do
  begin
   if n + Length(Pats[i]) > 65536 then
     exit(False);
   Move(Pats[i][1], mc.Index[n], Length(Pats[i]));
   Inc(n, Length(Pats[i]));
  end;

 mc.ST_Size := n;
 Move(mc, m, n);
 Result := True;
end;

function ST32STC(var m: ModTypes; msize: integer): boolean;
var
 mc: ModTypes;
 i, j, num, ptr, ptr2, n, pat, maxpat, patsptr, patsdif, lpbeg, lplen, loadaddr: integer;
 tn: smallint;
 en, ns: byte;
 Id: boolean;
begin
 mc.ST3_Delay := m.ST_Delay;
 mc.ST_Name := 'SONG BY ST COMPILE';
 n := 27;

 i := m.ST3_PositionsPointer - 9;
 if i <= 0 then
   Exit(False);

 Id := False;
 if (i mod 130 <> 0) then
  begin
   if (i < 55) or ((i - 55) mod 130 <> 0) then
     Exit(False);
   Id := True;
  end;

 ptr := m.ST3_SamplesPointer;
 if ptr >= msize - 3 then
   Exit(False);

 num := m.Index[ptr];
 Inc(ptr);
 if ptr + num * 2 > msize then
   Exit(False);

 loadaddr := PWord(@m.Index[ptr])^ - 9;
 if Id then Dec(loadaddr, 55);
 if (loadaddr < 0) or (loadaddr + msize > 65536) then
   Exit(False);

 for i := 0 to num - 1 do
  begin
   mc.Index[n] := i;
   Inc(n);
   ptr2 := PWord(@m.Index[ptr])^ - loadaddr;
   Inc(ptr, 2);
   if ptr2 + 2 + 32 * 4 > msize then
     Exit(False);

   lpbeg := m.Index[ptr2];
   Inc(ptr2);
   lplen := m.Index[ptr2] - lpbeg;
   Inc(ptr2);
   for j := 0 to 31 do
    begin
     tn := PWord(@m.Index[ptr2])^;
     Inc(ptr2, 2);
     en := m.Index[ptr2];
     Inc(ptr2);
     ns := m.Index[ptr2];
     Inc(ptr2);
     ns := (en and $80) or ((en and $10) shl 2) or (ns and $1f);
     if tn > 0 then
       ns := ns or $20
     else
       tn := -tn;
     mc.Index[n] := (en and 15) or (Hi(tn) shl 4);
     Inc(n);
     mc.Index[n] := ns;
     Inc(n);
     mc.Index[n] := Lo(tn);
     Inc(n);
    end;
   mc.Index[n] := lpbeg;
   Inc(n);
   mc.Index[n] := lplen;
   Inc(n);
  end;

 mc.ST_PositionsPointer := n;
 ptr := m.ST3_PositionsPointer;
 if ptr >= msize - 3 then
   Exit(False);

 num := m.Index[ptr] - 1;
 Inc(ptr);
 if ptr + num * 2 > msize then
   Exit(False);

 mc.Index[n] := num;
 Inc(n);
 maxpat := -1;
 for i := 0 to num do
  begin
   if m.Index[ptr + 1] mod 6 <> 0 then
     Exit(False);

   pat := m.Index[ptr + 1] div 6;
   if pat > maxpat then
     maxpat := pat;
   mc.Index[n] := pat;
   mc.Index[n + 1] := m.Index[ptr];
   Inc(n, 2);
   Inc(ptr, 2);
  end;
 if maxpat < 0 then
   Exit(False);

 mc.ST_OrnamentsPointer := n;
 ptr := m.ST3_OrnamentsPointer;
 if ptr >= msize - 3 then
   Exit(False);

 num := m.Index[ptr];
 Inc(ptr);
 if ptr + num * 2 > msize then
   Exit(False);

 for i := 0 to num - 1 do
  begin
   mc.Index[n] := i;
   Inc(n);
   ptr2 := PWord(@m.Index[ptr])^ - loadaddr;
   Inc(ptr, 2);
   if ptr2 + 32 > msize then
     Exit(False);

   Move(m.Index[ptr2], mc.Index[n], 32);
   Inc(n, 32);
  end;

 patsptr := ptr;

 mc.ST_PatternsPointer := n;
 ptr := m.ST3_PatternsPointer;
 if ptr + maxpat * 6 + 6 > msize then
   Exit(False);

 patsdif := -patsptr + mc.ST_PatternsPointer + maxpat * 7 + 8;
 for i := 0 to maxpat do
  begin
   mc.Index[n] := i;
   Inc(n);
   for j := 0 to 2 do
    begin
     PWord(@mc.Index[n])^ := PWord(@m.Index[ptr])^ + patsdif;
     Inc(n, 2);
     Inc(ptr, 2);
    end;
  end;
 mc.Index[n] := 255;
 Inc(n);

 i := m.ST3_PatternsPointer - patsptr - 1; //usually 1 extra byte with random value
 if (i <= 0) or (patsptr + i > msize) then
   Exit(False);

 //simple test for non random value - 255 is end of pat mark:
 if (patsptr + i < msize) and (m.Index[patsptr + i] = 255) then
   Inc(i);

 Move(m.Index[patsptr], mc.Index[n], i);
 Inc(n, i);

 mc.ST_Size := n;
 Move(mc, m, n);
 Result := True;
end;

function LoadTrackerModule(var Module: ModTypes; PPLItem: pointer;
 Index, MAddr, MLen: integer; Mem: pointer; FType: Available_Types): boolean;
var
 f: file;
 i, i1, i2: integer;
 j: longword;
 pwrd: PWord;
 Err: ErrorCodes;
begin
 Err := FileNoError;
  try
    try
     if PPLItem <> nil then
       with PPlayListItem(PPLItem)^ do
        begin
         FType := FileType;
         MAddr := Address;
         AssignFile(f, FileName);
         System.Reset(f, 1);
         if FType = FT.FXM then
          begin
           Seek(f, Offset + 6);
           Length := System.FileSize(f) - 6 - Offset;
          end
         else
          begin
           Seek(f, Offset);
           if Length = -1 then Length := System.FileSize(f);
          end;
        end;
     i := 0;
     if FType = FT.FXM then i := MAddr;
     if PPLItem <> nil then
       with PPlayListItem(PPLItem)^ do
        begin
         if Length > 65536 - int64(i) then Length := 65536 - int64(i);
         MLen := Length;
        end;
      try
       FillChar(Module, 65536, 0);
       if PPLItem <> nil then
         System.BlockRead(f, Module.Index[i], MLen)
       else
         Move(Mem^, Module.Index[i], MLen);
      finally
       if PPLItem <> nil then CloseFile(f);
      end;
     if FType = FT.PT3 then
      begin
       if ((PPLItem <> nil) and
         (LowerCase(ExtractFileExt(PPlaylistItem(PPLItem)^.FileName)) <> '.pt3')) or
         (PPLItem = nil) then
        begin
         i := 0;
         i1 := 0;
         with Module do
          begin
           while (i < 65535 - 201) and (PT3_PositionList[i] <> 255) do
            begin
             if longword(i1) < PT3_PositionList[i] then i1 := PT3_PositionList[i];
             Inc(i);
            end;
           if i >= 65535 - 201 then RaiseBadFileStructure;
           if i > 255 then
             PT3_NumberOfPositions := 255
           else
             PT3_NumberOfPositions := i;
           j := MAddr;
           if j <> 0 then
            begin
             if j >= 65536 then RaiseBadFileStructure;
             if PT3_PatternsPointer < j then RaiseBadFileStructure;
             Dec(PT3_PatternsPointer, j);
             for i := 0 to 31 do
              begin
               if PT3_SamplesPointers[i] < j then RaiseBadFileStructure;
               Dec(PT3_SamplesPointers[i], j);
              end;
             for i := 0 to 15 do
              begin
               if PT3_OrnamentsPointers[i] < j then RaiseBadFileStructure;
               Dec(PT3_OrnamentsPointers[i], j);
              end;
             pwrd := @Index[PT3_PatternsPointer];
             for i := 0 to i1 + 2 do
              begin
               if (PT3_PatternsPointer + i * 2 >= 65535) or (pwrd^ < j) then
                 RaiseBadFileStructure;
               Dec(pwrd^, j);
               Inc(pwrd);
              end;
            end;
          end;
        end;
      end
     else if FType = FT.PT2 then
      begin
       if ((PPLItem <> nil) and
         (LowerCase(ExtractFileExt(PPlaylistItem(PPLItem)^.FileName)) <> '.pt2')) or
         (PPLItem = nil) then
        begin
         i := 0;
         i1 := 0;
         with Module do
          begin
           while (i < 65535 - 131) and (PT2_PositionList[i] < 128) do
            begin
             if longword(i1) < PT2_PositionList[i] then i1 := PT2_PositionList[i];
             Inc(i);
            end;
           if i >= 65535 - 131 then RaiseBadFileStructure;
           if i > 255 then
             PT2_NumberOfPositions := 255
           else
             PT2_NumberOfPositions := i;
           j := MAddr;
           if j <> 0 then
            begin
             if j >= 65536 then RaiseBadFileStructure;
             for i := 0 to 31 do
              begin
               if PT2_SamplesPointers[i] < j then RaiseBadFileStructure;
               Dec(PT2_SamplesPointers[i], j);
              end;
             for i := 0 to 15 do
              begin
               if PT2_OrnamentsPointers[i] < j then RaiseBadFileStructure;
               Dec(PT2_OrnamentsPointers[i], j);
              end;
             pwrd := @Index[PT2_PatternsPointer];
             for i := 0 to i1 * 3 + 2 do
              begin
               if (PT2_PatternsPointer + i * 2 >= 65535) or (pwrd^ < j) then
                 RaiseBadFileStructure;
               Dec(pwrd^, j);
               Inc(pwrd);
              end;
            end;
          end;
        end;
      end
     else if FType = FT.STP then
      begin
       //file with extension *.stp must be with STP_Init_Id <> 0, but there are
       //many badly ripped *.stp in Goblin's Cracktro Archive, so commenting next:
{      if ((PPLItem <> nil) and (LowerCase(ExtractFileExt(PPlaylistItem(PPLItem)^.FileName)) <> '.stp')) or
         (PPLItem = nil) then}
       with Module do
         //        if STP_Init_Id = 0 then //can be corrupted, so ignoring
        begin
         j := MAddr;
         if j >= 65536 then RaiseBadFileStructure;
         i1 := (MLen - STP_PatternsPointer) div 2;
         if not (i1 in [0..255]) then RaiseBadFileStructure;
         STP_Init_Id := i1;
         pwrd := @Index[STP_PatternsPointer];
         for i := 0 to i1 - 1 do
          begin
           if (STP_PatternsPointer + i * 2 >= 65535) or (pwrd^ < j) then
             RaiseBadFileStructure;
           Dec(pwrd^, j);
           Inc(pwrd);
          end;
        end;
      end
     else if FType = FT.ASC0 then
       with Module do
        begin
         if MLen >= 65535 then RaiseBadFileStructure;
         Move(ASC0_PatternsPointers, ASC1_PatternsPointers, MLen - 1);
         ASC1_LoopingPosition := 0;
         Inc(ASC1_PatternsPointers);
         Inc(ASC1_SamplesPointers);
         Inc(ASC1_OrnamentsPointers);
        end
     else if FType = FT.SQT then
       with Module do
        begin
         i := SQT_SamplesPointer - 10;
         if i < 0 then RaiseBadFileStructure;
         i1 := 0;
         i2 := SQT_PositionsPointer - i;
         if i2 < 0 then RaiseBadFileStructure;
         while Index[i2] <> 0 do
          begin
           if i2 > 65536 - 8 then RaiseBadFileStructure;
           if i1 < Index[i2] and $7f then
             i1 := Index[i2] and $7f;
           Inc(i2, 2);
           if i1 < Index[i2] and $7f then
             i1 := Index[i2] and $7f;
           Inc(i2, 2);
           if i1 < Index[i2] and $7f then
             i1 := Index[i2] and $7f;
           Inc(i2, 3);
          end;
         pwrd := @SQT_SamplesPointer;
         i1 := (SQT_PatternsPointer - i + i1 * 2) div 2;
         if (i1 < 1) or (i1 >= (65536 - 2) div 2) then RaiseBadFileStructure;
         for i2 := 1 to i1 do
          begin
           if pwrd^ < i then RaiseBadFileStructure;
           Dec(pwrd^, i);
           Inc(pwrd);
          end;
        end
     else if FType = FT.FTC then
      begin
       if (((PPLItem <> nil) and
         (LowerCase(ExtractFileExt(PPlaylistItem(PPLItem)^.FileName)) <> '.ftc')) or
         (PPLItem = nil)) and (MAddr <> 0) then
         with Module do
          begin
           j := MAddr;
           if j >= 65536 then RaiseBadFileStructure;
           for i := 0 to 32 do
            begin
             if FTC_OrnamentsPointers[i] < j then RaiseBadFileStructure;
             Dec(FTC_OrnamentsPointers[i], j);
            end;
           for i := 0 to 31 do
            begin
             if FTC_SamplesPointers[i] < j then RaiseBadFileStructure;
             Dec(FTC_SamplesPointers[i], j);
            end;
           pwrd := @Index[FTC_PatternsPointer];
           i := $d4;
           i1 := 0;
           while (i < 65536) and (shortint(Index[i]) >= 0) do
            begin
             if i1 < Index[i] then i1 := Index[i];
             Inc(i, 2);
            end;
           if i >= 65536 then RaiseBadFileStructure;
           i1 := (i1 + 1) * 3;
           if i1 < 1 then RaiseBadFileStructure;
           for i := 0 to i1 - 1 do
            begin
             if (FTC_PatternsPointer + i * 2 >= 65535) or (pwrd^ < j) then
               RaiseBadFileStructure;
             Dec(pwrd^, j);
             Inc(pwrd);
            end;
          end;
      end
     else if FType = FT.FLS then
      begin
       i := Module.FLS_OrnamentsPointer - 16;
       if i >= 0 then
         with Module do
           repeat
             i2 := FLS_SamplesPointer + 2 - i;
             if (i2 >= 8) and (i2 < MLen) then
              begin
               pwrd := @Index[i2];
               i1 := pwrd^ - i;
               if (i1 >= 8) and (i1 < MLen) then
                begin
                 pwrd := @Index[i2 - 4];
                 i2 := pwrd^ - i;
                 if (i2 >= 6) and (i2 < MLen) then
                   if i1 - i2 = $20 then
                    begin
                     i2 := FLS_PatternsPointers[1].PatternB - i;
                     if (i2 > 21) and (i2 < MLen) then
                      begin
                       i1 := FLS_PatternsPointers[1].PatternA - i;
                       if (i1 > 20) and (i1 < MLen) then
                         if Index[i1 - 1] = 0 then
                          begin
                           while (i1 < MLen) and (Index[i1] <> 255) do
                            begin
                             repeat
                               case Index[i1] of
                                 0..$5f, $80, $81:
                                  begin
                                   Inc(i1);
                                   break;
                                  end;
                                 $82..$8e:
                                   Inc(i1)
                                end;
                               Inc(i1);
                             until i1 >= MLen;
                            end;
                           if i1 + 1 = i2 then break;
                          end;
                      end;
                    end;
                end;
              end;
             Dec(i)
           until i < 0;
       if i < 0 then
         Err := ErFLSAddrNotDetected
       else
         with Module do
          begin
           pwrd := @Module;
           i1 := FLS_SamplesPointer - i;
           if i1 and 1 <> 0 then RaiseBadFileStructure;
           i2 := FLS_PositionsPointer - i;
           if (i2 - i1) and 3 <> 0 then RaiseBadFileStructure;
           for j := 1 to i1 div 2 do
            begin
             Dec(pwrd^, i);
             Inc(pwrd);
            end;
           Inc(pwrd);
           for j := 1 to (i2 - i1) div 4 do
            begin
             Dec(pwrd^, i);
             Inc(pwrd, 2);
            end;
          end;
      end
     else if FType = FT.GTR then
       with Module do
        begin
         pwrd := @GTR_SamplesPointers[0];
         j := GTR_Address;
         for i := 0 to (15 + 16 + 32 * 3) - 1 do
          begin
           if pwrd^ < j then RaiseBadFileStructure;
           Dec(pwrd^, j);
           Inc(pwrd);
          end;
         GTR_Address := 0;
        end
     else if FType = FT.ST1 then
      begin
       if not ST12STC(Module, MLen) then RaiseBadFileStructure;
      end
     else if FType = FT.ST3 then
      begin
       if not ST32STC(Module, MLen) then RaiseBadFileStructure;
      end
     else if FType = FT.STF then
      begin
       if not STFDepack(Module, MLen) then RaiseBadFileStructure;
       if not STF2STP(Module, MLen) then RaiseBadFileStructure;
      end;
    except
     on EFileStructureError do
       Err := ErBadFileStructure
     else
       Err := ErReadingFile;
    end;
  finally
   Result := Err = FileNoError;
   if PPLItem <> nil then PPlaylistItem(PPLItem)^.Error := Err;
   if Index <> -1 then RedrawItem(Index);
  end;
end;

procedure PrepareItem(Index: integer);

 procedure CaseTrModules(FType: Available_Types; n: integer);
 begin
   if FType = FT.PT3 then
    begin
     PlConsts[n].Version := 6;
     if PLConsts[n].RAM^.PT3_MusicName[13] in ['0'..'9'] then
       PlConsts[n].Version := Ord(PLConsts[n].RAM^.PT3_MusicName[13]) - $30;
     All_GetRegisters[n] := @PT3_Get_Registers;
    end
   else if FType = FT.PT2 then
    begin
     All_GetRegisters[n] := @PT2_Get_Registers;
    end
   else if (FType = FT.STC) or (FType = FT.ST1) or (FType = FT.ST3) then
    begin
     All_GetRegisters[n] := @STC_Get_Registers;
    end
   else if (FType = FT.STP) or (FType = FT.STF) then
    begin
     All_GetRegisters[n] := @STP_Get_Registers;
    end
   else if (FType = FT.ASC) or (FType = FT.ASC0) then
    begin
     All_GetRegisters[n] := @ASC_Get_Registers;
    end
   else if FType = FT.PSC then
    begin
     PlConsts[n].Version := 7;
     if PLConsts[n].RAM^.PSC_MusicName[8] in ['0'..'9'] then
       PlConsts[n].Version := Ord(PLConsts[n].RAM^.PSC_MusicName[8]) - $30;
     All_GetRegisters[n] := @PSC_Get_Registers;
    end
   else if FType = FT.SQT then
    begin
     All_GetRegisters[n] := @SQT_Get_Registers;
    end
   else if FType = FT.FTC then
    begin
     PlConsts[n].Version := 0;
     if (PLConsts[n].RAM^.FTC_MusicName[67] = '0') and
       (PLConsts[n].RAM^.FTC_MusicName[68] in ['0'..'9']) then
       PlConsts[n].Version := Ord(PLConsts[n].RAM^.FTC_MusicName[68]) - $30;
     All_GetRegisters[n] := @FTC_Get_Registers;
    end
   else if FType = FT.PT1 then
    begin
     All_GetRegisters[n] := @PT1_Get_Registers;
    end
   else if FType = FT.FLS then
    begin
     All_GetRegisters[n] := @FLS_Get_Registers;
    end
   else if FType = FT.GTR then
    begin
     All_GetRegisters[n] := @GTR_Get_Registers;
    end
   else if FType = FT.FXM then
    begin
     PlConsts[n].Address := PlayListItems[Index]^.Address;
     PlConsts[n].amad_andsix := PlayListItems[Index]^.FormatSpec;
     All_GetRegisters[n] := @FXM_Get_Registers;
    end
   else if FType = FT.PSM then
    begin
     All_GetRegisters[n] := @PSM_Get_Registers;
    end;
 end;

 function TrModLoaded: boolean;
 var
   TS: integer;
 begin
   Result := False;
   MakeBuffer := @MakeBufferTracker;
   PLConsts[0].RAM := @ZRAM;
   PLConsts[1].RAM := @RAM1;
   PLConsts[0].TS := $20;
   PLConsts[1].TS := $20;
    try
     if LoadTrackerModule(ZRAM, PlayListItems[Index], Index, 0, 0, nil, -1) then
      begin
       FileLoaded := True;
       Result := True;
       CurFileType := PlayListItems[Index]^.FileType;
       CaseTrModules(CurFileType, 0);
       if (CurFileType = FT.PT3) and (PlConsts[0].Version >= 7) then
        begin
         TS := Ord(ZRAM.PT3_MusicName[98]);
         if (TS <> $20) then
          begin
           TSMode := True;
           PLConsts[1] := PLConsts[0];
           PLConsts[1].TS := TS;
           CurFileType1 := CurFileType;
           All_GetRegisters[1] := @PT3_Get_Registers;
           if PlayListItems[Index]^.FormatSpec <> 0 then
            begin
             PlayListItems[Index]^.FormatSpec := 0;
             RedrawItem(Index);
            end;
          end
         else if PlayListItems[Index]^.FormatSpec <> -1 then
          begin
           PlayListItems[Index]^.FormatSpec := -1;
           RedrawItem(Index);
          end;
        end;
       if (TSMode = False) and (PlayListItems[Index]^.Next <> nil) then
         if LoadTrackerModule(RAM1, PlayListItems[Index]^.Next, Index,
           0, 0, nil, -1) then
          begin
           TSMode := True;
           CurFileType1 := PlayListItems[Index]^.Next^.FileType;
           CaseTrModules(CurFileType1, 1);
          end;
      end;
    finally
     if not Result then FileAvailable := False;
     RedrawItem(Index);
    end;
 end;

const
 Dump: packed array[0..11] of byte =
   ($F3, $AF, $CD, 0, 0, $FB, $76, $CD, 0, 0, $18, $F9);
var
 i, i1, i2, k, k2: integer;
 fpos: int64;
 sh: shortint;
 j: longword;
 AYMBlock: TAYMBlock;
 w: word;
begin
 TSMode := False;
 with PlayListItems[Index]^ do
  begin
   if not IsCDFileType(FileType) and not FileIsURL(FileName) and
     not FileExists(FileName) then
    begin
     FreePlayingResourses;
     Error := ErFileNotFound;
     RedrawItem(Index);
     FileAvailable := False;
    end
   else
    begin
     if Error <> FileNoError then
      begin
       Error := FileNoError;
       RedrawItem(Index);
      end;
     if IsAYNativeFileType(FileType) then
       TrModLoaded
     else if FileType = FT.OUT then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       FileOpened := True;
       CurFileType := FileType;
       MakeBuffer := @MakeBufferOUT;
       All_GetRegisters[0] := @OUT_Get_Registers;
      end
     else if FileType = FT.VTX then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       UniFileSeek(FileHandle, Offset);
       GetMem(PVTXYMUnpackedData, UnpackedSize);
       Compressed_Size := Length;
       Original_Size := UnpackedSize;
       UniAddDepacker(FileHandle, UDLZH);
        try
         UniRead(FileHandle, PVTXYMUnpackedData, UnpackedSize);
        except
         FreeMem(PVTXYMUnpackedData);
         Error := ErLZHDataIsNotValid;
         RedrawItem(Index);
         FileAvailable := False
        end;
       UniReadClose(FileHandle);
       if Error = FileNoError then
        begin
         FileLoaded := True;
         CurFileType := FileType;
         VTX_Offset := 0;
         NumberOfVBLs := UnpackedSize div 14;
         MakeBuffer := @MakeBufferVTX;
         All_GetRegisters[0] := @VTX_YM3_YM3b_Get_Registers;
        end;
      end
     else if IsSTSoundFileType(FileType) then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       GetMem(PVTXYMUnpackedData, UnpackedSize);
       if Offset <> 0 then
        begin
         UniFileSeek(FileHandle, Offset);
         Compressed_Size := Length;
         Original_Size := UnpackedSize;
         UniAddDepacker(FileHandle, UDLZH);
        end;
        try
         UniRead(FileHandle, PVTXYMUnpackedData, UnpackedSize);
        except
         on EInvalidCompressedData do
           Error := ErLZHDataIsNotValid;
         else
           Error := ErReadingFile;
         FreeMem(PVTXYMUnpackedData);
         RedrawItem(Index);
         FileAvailable := False;
        end;
       UniReadClose(FileHandle);
       if Error = FileNoError then
        begin
         CurFileType := FileType;
         FileLoaded := True;
         if (FileType = FT.YM2) or (FileType = FT.YM3) or (FileType = FT.YM3b) then
          begin
           if FileType = FT.YM3b then
            begin
             NumberOfVBLs := (UnpackedSize - 8) div 14;
             if Loop < 0 then
               Loop := PDWord(@PVTXYMUnpackedData[UnpackedSize - 4])^;
            end
           else
             NumberOfVBLs := (UnpackedSize - 4) div 14;
           VTX_Offset := 4;
           if FileType <> FT.YM2 then
            begin
             MakeBuffer := @MakeBufferVTX;
             All_GetRegisters[0] := @VTX_YM3_YM3b_Get_Registers;
            end
           else
            begin
             MakeBuffer := @MakeBufferYM2;
             All_GetRegisters[0] := @YM2_Get_Registers;
            end;
          end;
         if (FileType = FT.YM5) or (FileType = FT.YM6) then
          begin
           VTX_Offset := FormatSpec;
           NumberOfVBLs := SwapEndian(
             PYM5FileHeader(PVTXYMUnpackedData)^.Num_of_tiks);
           i := SwapEndian(PYM5FileHeader(PVTXYMUnpackedData)^.Num_of_Dig);
           if i > 0 then
            begin
             SetLength(DDrumSamples, i);
             i2 := 34 + SwapEndian(
               PYM5FileHeader(PVTXYMUnpackedData)^.Add_Size);
             i1 := 0;
             while i > 0 do
              begin
               j := SwapEndian(PDWord(@PVTXYMUnpackedData[i2])^);
               DDrumSamples[i1].Length := j;
               DDrumSamples[i1].Buf := @PVTXYMUnpackedData[i2 + 4];
               Inc(i2, j + 4);
               Inc(i1);
               Dec(i);
              end;
             if PYM5FileHeader(PVTXYMUnpackedData)^.Song_Attr and
               $06000000 = $02000000 then
               for i := 0 to System.Length(DDrumSamples) - 1 do
                 for i1 := 0 to DDrumSamples[i].Length - 1 do
                  begin
                   sh := shortint(DDrumSamples[i].Buf[i1]);
                   k2 := round((sh + 128) / 255 * 65535);
                   k := 1;
                   while (k < 32) and (Amplitudes_YM[k] < k2) do
                     Inc(k, 2);
                   if k > 1 then
                     if Amplitudes_YM[k] - k2 > k2 -
                     Amplitudes_YM[k - 2] then
                       Dec(k, 2);
                   DDrumSamples[i].Buf[i1] := k div 2;
                  end
             else if PYM5FileHeader(PVTXYMUnpackedData)^.Song_Attr and
               $06000000 = 0 then
               for i := 0 to System.Length(DDrumSamples) - 1 do
                 YMizeSample(DDrumSamples[i].Buf, DDrumSamples[i].Length);
            end;
           if FileType = FT.YM5 then
            begin
             MakeBuffer := @MakeBufferYM5;
             if PVTXYMUnpackedData[19] and 1 <> 0 then
               All_GetRegisters[0] := @YM5i_Get_Registers
             else
               All_GetRegisters[0] := @YM5_Get_Registers;
            end
           else
            begin
             MakeBuffer := @MakeBufferYM6;
             if PVTXYMUnpackedData[19] and 1 <> 0 then
               All_GetRegisters[0] := @YM6i_Get_Registers
             else
               All_GetRegisters[0] := @YM6_Get_Registers;
            end;
          end;
        end;
      end
     else if FileType = FT.EPSG then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       FileOpened := True;
       CurFileType := FileType;
       MakeBuffer := @MakeBufferEPSG;
       All_GetRegisters[0] := @EPSG_Get_Registers;
       EPSG_TStateMax := FormatSpec;
      end
     else if FileType = FT.PSG then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       FileOpened := True;
       CurFileType := FileType;
       MakeBuffer := @MakeBufferPSG;
       All_GetRegisters[0] := @PSG_Get_Registers;
      end
     else if FileType = FT.ZXAY then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       FileOpened := True;
       CurFileType := FileType;
       MakeBuffer := @MakeBufferZXAY;
       All_GetRegisters[0] := @ZXAY_Get_Registers;
      end
     else if FileType = FT.SNDH then
      begin
       if not sndh_UnpackFile(FileName, SNDHBuffer) then
        begin
         Error := ErBadFileStructure;
         FileAvailable := False;
         exit;
        end;
       if FormatSpec < 1 then
         CurrentSong := 1
       else
         CurrentSong := FormatSpec + 1;
       FileLoaded := True;
       CurFileType := FileType;
       MakeBuffer := @MakeBufferSNDH;
       All_GetRegisters[0] := @SNDH_Get_Registers;
      end
     else if FileType = FT.AY then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
       i := Offset;
       if i = 0 then
        begin
         UniFileSeek(FileHandle, 16);
         UniRead(FileHandle, @w, 2);
         if (FormatSpec < 0) or (FormatSpec > byte(w)) then
          begin
           Error := ErReadingFile;
           FileAvailable := False;
           exit;
          end;
         UniRead(FileHandle, @w, 2);
         i := smallint(SwapEndian(w)) + 18 + FormatSpec * 4 + 2;
         UniFileSeek(FileHandle, i);
         UniRead(FileHandle, @w, 2);
         Inc(i, smallint(SwapEndian(w)));
        end;
       UniFileSeek(FileHandle, i);
       UniRead(FileHandle, @AYSongData, SizeOf(TSongData));
       fpos := UniReadersData[FileHandle]^.UniFilePos;
       UniFileSeek(FileHandle, int64(smallint(SwapEndian(AYSongData.PPoints))) +
         fpos - 4);
       UniRead(FileHandle, @AYPoints, SizeOf(TPoints));
       AYPoints.Stek := SwapEndian(AYPoints.Stek);
       AYPoints.Init := SwapEndian(AYPoints.Init);
       AYPoints.Inter := SwapEndian(AYPoints.Inter);
       AYBlocks := smallint(SwapEndian(AYSongData.PAddresses)) + fpos - 2;
       FileOpened := True;
       CurFileType := FileType;
       MakeBuffer := @MakeBufferAY;
       All_GetRegisters[0] := @AY_Get_Registers;
      end
     else if FileType = FT.AYM then
      begin
       UniReadInit(FileHandle, URFile, FileName, nil, -1);
        try
         UniRead(FileHandle, @AYMFileHeader, SizeOf(TAYMFileHeader));
         FillChar(ZRAM.Index[12], 255 - 12 + 1, 201);
         FillChar(ZRAM.Index[256], 16383 - 256 + 1, 255);
         FillChar(ZRAM.Index[16384], 65535 - 16384 + 1, 0);
         ZRAM.Index[56] := $FB;
         for i := 0 to AYMFileHeader.Blocks - 1 do
          begin
           UniRead(FileHandle, @AYMBlock, SizeOf(AYMBlock));
           i1 := AYMBlock.size;
           if AYMBlock.start + i1 > 65536 then
             i1 := 65536 - AYMBlock.start;
           if i1 > UniReadersData[FileHandle]^.UniFileSize -
           UniReadersData[FileHandle]^.UniFilePos then
             i1 := UniReadersData[FileHandle]^.UniFileSize -
               UniReadersData[FileHandle]^.UniFilePos;
           UniRead(FileHandle, @ZRAM.Index[AYMBlock.start], i1);
          end;
         Move(Dump, ZRAM, 12);
         PWord(@ZRAM.Index[3])^ := AYMFileHeader.Init;
         PWord(@ZRAM.Index[8])^ := AYMFileHeader.Play;
         AYBlocks := FormatSpec;
         FileLoaded := True;
         CurFileType := FileType;
         MakeBuffer := @MakeBufferAY;
         All_GetRegisters[0] := @AY_Get_Registers;
        finally
         UniReadClose(FileHandle);
        end;
      end
     else if IsStreamOrModuleFileType(FileType) then
      begin
       if Time = 0 then
        try
         GetTime(-1, PlayListItems[Index], Index, nil, i)
        except
         Error := ErBASSError;
        end;
       CurFileType := FileType;
      end
     {$IFDEF Windows}
     else if IsCDFileType(FileType) then
      begin
       CurCDTrk := Offset;
       if CurCDNum <> Address then
         if (Address >= 0) and (Address < System.Length(CDDrives)) then
          begin
           FreeAllCD;
           CurCDNum := Address;
          end
         else
           Error := ErFileNotFound;
       if (Error = FileNoError) and (Time = 0) then
        try
         GetTime(-1, PlayListItems[Index], Index, nil, i)
        except
         Error := ErFileNotFound
        end;
       CurFileType := FileType;
      end
     else if IsMIDIFileType(FileType) then
      begin
        try
         load_midi(MIDIParams, nil, FileName);
         if (MIDIParams^.file_format = -1) or (MIDIParams^.file_format = 2) then
          begin
           MIDIParams^.track_from := FormatSpec;
           MIDIParams^.track_to := FormatSpec;
          end;
         FileLoaded := True;
        except
         Error := ErReadingFile;
         FileAvailable := False
        end;
       CurFileType := FileType;
      end;
     {$ENDIF Windows}
    end;
  end;
end;

procedure InitForAllTypes(InitAll: boolean);

 procedure InitTrackerModule(FType: Available_Types; n: integer);
 var
   i: integer;
   b: byte;
 begin
   if FType = FT.FXM then
    begin

     with PlParams[n].FXM, PLConsts[n].RAM^ do
      begin
       //"FillChared"    Noise_Base := 0;
       PlParams[n].FXM_A.Address_In_Pattern := PWord(@Index[PlConsts[n].Address])^;
       PlParams[n].FXM_B.Address_In_Pattern := PWord(@Index[PlConsts[n].Address + 2])^;
       PlParams[n].FXM_C.Address_In_Pattern := PWord(@Index[PlConsts[n].Address + 4])^;
      end;

     with PlParams[n].FXM_A do
      begin
       Note_Skip_Counter := 1;
       FXM_Mixer := 8;
{"FillChared"    Transposit := 0;
    b0e := False;
    b1e := False;
    b2e := False;
    b3e := False;}
      end;

     with PlParams[n].FXM_B do
      begin
       Note_Skip_Counter := 1;
       FXM_Mixer := 8;
{"FillChared"   Transposit := 0;
    b0e := False;
    b1e := False;
    b2e := False;
    b3e := False;}
      end;

     with PlParams[n].FXM_C do
      begin
       Note_Skip_Counter := 1;
       FXM_Mixer := 8;
{"FillChared"    Transposit := 0;
    b0e := False;
    b1e := False;
    b2e := False;
    b3e := False;}
      end;

     SetLength(FXM_StekA, 0);
     SetLength(FXM_StekB, 0);
     SetLength(FXM_StekC, 0);

    end
   else if FType = FT.GTR then
    begin

     with PlParams[n].GTR, PLConsts[n].RAM^ do
      begin
       //"FillChared"    CurrentPosition := 0;
       DelayCounter := 1;
       PlParams[n].GTR_A.Address_In_Pattern :=
         GTR_PatternsPointers[GTR_Positions[0] div 6].PatternA;
       PlParams[n].GTR_B.Address_In_Pattern :=
         GTR_PatternsPointers[GTR_Positions[0] div 6].PatternB;
       PlParams[n].GTR_C.Address_In_Pattern :=
         GTR_PatternsPointers[GTR_Positions[0] div 6].PatternC;
      end;

     with PlParams[n].GTR_A do
      begin
       //"FillChared"    Envelope_Enabled := False;
       SamplePointer := 65536 - 4;
       //"FillChared"    Position_In_Sample := 0;
       //"FillChared"    Loop_Sample_Position := 0;
       Sample_Length := 4;
       OrnamentPointer := 65536 - 4;
       //"FillChared"    Position_In_Ornament := 0;
       //"FillChared"    Loop_Ornament_Position := 0;
       Ornament_Length := 1;
       //"FillChared"    PDWord(@RAM.Index[65536-4])^ := 0;
       //"FillChared"    Note_Skip_Counter := 0;
       Enabled := True;
       //"FillChared"    Ton := 0;
       //"FillChared"    Volume := 0
      end;

     with PlParams[n].GTR_B do
      begin
       //"FillChared"    Envelope_Enabled := False;
       SamplePointer := 65536 - 4;
       //"FillChared"    Position_In_Sample := 0;
       //"FillChared"    Loop_Sample_Position := 0;
       Sample_Length := 4;
       OrnamentPointer := 65536 - 4;
       //"FillChared"    Position_In_Ornament := 0;
       //"FillChared"    Loop_Ornament_Position := 0;
       Ornament_Length := 1;
       //"FillChared"    PDWord(@RAM.Index[65536-4])^ := 0;
       //"FillChared"    Note_Skip_Counter := 0;
       Enabled := True;
       //"FillChared"    Ton := 0;
       //"FillChared"    Volume := 0
      end;

     with PlParams[n].GTR_C do
      begin
       //"FillChared"    Envelope_Enabled := False;
       SamplePointer := 65536 - 4;
       //"FillChared"    Position_In_Sample := 0;
       //"FillChared"    Loop_Sample_Position := 0;
       Sample_Length := 4;
       OrnamentPointer := 65536 - 4;
       //"FillChared"    Position_In_Ornament := 0;
       //"FillChared"    Loop_Ornament_Position := 0;
       Ornament_Length := 1;
       //"FillChared"    PDWord(@RAM.Index[65536-4])^ := 0;
       //"FillChared"    Note_Skip_Counter := 0;
       Enabled := True;
       //"FillChared"    Ton := 0;
       //"FillChared"    Volume := 0
      end;

    end
   else if (FType = FT.STC) or (FType = FT.ST1) or (FType = FT.ST3) then
    begin
     with PlParams[n].STC, PLConsts[n].RAM^ do
      begin
       //"FillChared"    CurrentPosition := 0;
       Transposition := Index[ST_PositionsPointer + 2];
       DelayCounter := 1;
      end;

     with PLConsts[n].RAM^ do
      begin
       i := 0;
       while Index[ST_PatternsPointer + 7 * i] <> Index[ST_PositionsPointer + 1] do
         Inc(i);
       PlParams[n].STC_A.Address_In_Pattern :=
         PWord(@Index[ST_PatternsPointer + 7 * i + 1])^;
       PlParams[n].STC_B.Address_In_Pattern :=
         PWord(@Index[ST_PatternsPointer + 7 * i + 3])^;
       PlParams[n].STC_C.Address_In_Pattern :=
         PWord(@Index[ST_PatternsPointer + 7 * i + 5])^;
      end;

     with PlParams[n].STC_A do
      begin
       //"FillChared"    Note_Skip_Counter := 0;
       //"FillChared"    Envelope_Enabled := False;
       //"FillChared"    Number_Of_Notes_To_Skip := 0;
       Sample_Tik_Counter := -1;
       //"FillChared"    Position_In_Sample := 0;
       OrnamentPointer := PLConsts[n].RAM^.ST_OrnamentsPointer + 1;
       //"FillChared"    Ton := 0
      end;

     with PlParams[n].STC_B do
      begin
       //"FillChared"    Note_Skip_Counter := 0;
       //"FillChared"    Envelope_Enabled := False;
       //"FillChared"    Number_Of_Notes_To_Skip := 0;
       Sample_Tik_Counter := -1;
       //"FillChared"    Position_In_Sample := 0;
       OrnamentPointer := PLConsts[n].RAM^.ST_OrnamentsPointer + 1;
       //"FillChared"    Ton := 0
      end;

     with PlParams[n].STC_C do
      begin
       //"FillChared"    Note_Skip_Counter := 0;
       //"FillChared"    Envelope_Enabled := False;
       //"FillChared"    Number_Of_Notes_To_Skip := 0;
       Sample_Tik_Counter := -1;
       //"FillChared"    Position_In_Sample := 0;
       OrnamentPointer := PLConsts[n].RAM^.ST_OrnamentsPointer + 1;
       //"FillChared"    Ton := 0
      end;

    end
   else if FType = FT.FLS then
    begin
     with PlParams[n].FLS, PLConsts[n].RAM^ do
      begin
       Delay := Index[FLS_PositionsPointer];
       //"FillChared"    CurrentPosition := 0;
       DelayCounter := 1;
      end;

     with PlParams[n].FLS_A, PLConsts[n].RAM^ do
      begin
       //"FillChared"    Note_Skip_Counter := 0;
       //"FillChared"    Number_Of_Notes_To_Skip := 0;
       Address_In_Pattern := FLS_PatternsPointers[Index[FLS_PositionsPointer +
         1]].PatternA;
       //"FillChared"    Ornament_Enabled := False;
       //"FillChared"    Envelope_Enabled := False;
       //"FillChared"    Ton := 0;
       Sample_Tik_Counter := -1;
      end;

     with PlParams[n].FLS_B, PLConsts[n].RAM^ do
      begin
       //"FillChared"    Note_Skip_Counter := 0;
       //"FillChared"    Number_Of_Notes_To_Skip := 0;
       Address_In_Pattern := FLS_PatternsPointers[Index[FLS_PositionsPointer +
         1]].PatternB;
       //"FillChared"    Ornament_Enabled := False;
       //"FillChared"    Envelope_Enabled := False;
       //"FillChared"    Ton := 0;
       Sample_Tik_Counter := -1;
      end;

     with PlParams[n].FLS_C, PLConsts[n].RAM^ do
      begin
       //"FillChared"    Note_Skip_Counter := 0;
       //"FillChared"    Number_Of_Notes_To_Skip := 0;
       Address_In_Pattern := FLS_PatternsPointers[Index[FLS_PositionsPointer +
         1]].PatternC;
       //"FillChared"    Ornament_Enabled := False;
       //"FillChared"    Envelope_Enabled := False;
       //"FillChared"    Ton := 0;
       Sample_Tik_Counter := -1;
      end;

    end
   else if (FType = FT.ASC) or (FType = FT.ASC0) then
    begin

{"FillChared"   with PlParams.ASC_A do
    begin
     Note := 0;
     Initial_Noise := 0;
     Current_Noise := 0;
     Sample_Finished := False;
     Sound_Enabled := False;
     Break_Sample_Loop := False;
     Envelope_Enabled := False;
     Number_Of_Notes_To_Skip := 0;
     Addition_To_Amplitude := 0;
     Note_Skip_Counter := 0;
     Initial_Point_In_Sample := 0;
     Initial_Point_In_Ornament := 0;
     Point_In_Ornament := 0;
     Loop_Point_In_Ornament := 0;
     Substruction_for_Ton_Sliding := 0;
     Volume := 0;
     Point_In_Sample := 0;
     Ton_Deviation := 0;
     Loop_Point_In_Sample := 0;
     Ton_Sliding_Counter := 0;
     Amplitude_Delay_Counter := 0;
     Amplitude_Delay := 0;
     Addition_To_Note := 0;
     Current_Ton_Sliding := 0;
     Ton:=0
    end;}

{"FillChared"   with PlParams.ASC_B do
    begin
     Note := 0;
     Initial_Noise := 0;
     Current_Noise := 0;
     Sample_Finished := False;
     Sound_Enabled := False;
     Break_Sample_Loop := False;
     Envelope_Enabled := False;
     Number_Of_Notes_To_Skip := 0;
     Addition_To_Amplitude := 0;
     Note_Skip_Counter := 0;
     Initial_Point_In_Sample := 0;
     Initial_Point_In_Ornament := 0;
     Point_In_Ornament := 0;
     Loop_Point_In_Ornament := 0;
     Substruction_for_Ton_Sliding := 0;
     Volume := 0;
     Point_In_Sample := 0;
     Ton_Deviation := 0;
     Loop_Point_In_Sample := 0;
     Ton_Sliding_Counter := 0;
     Amplitude_Delay_Counter := 0;
     Amplitude_Delay := 0;
     Addition_To_Note := 0;
     Current_Ton_Sliding := 0;
     Ton:=0
    end;}

{"FillChared"   with PlParams.ASC_C do
    begin
     Note := 0;
     Initial_Noise := 0;
     Current_Noise := 0;
     Sample_Finished := False;
     Sound_Enabled := False;
     Break_Sample_Loop := False;
     Envelope_Enabled := False;
     Number_Of_Notes_To_Skip := 0;
     Addition_To_Amplitude := 0;
     Note_Skip_Counter := 0;
     Initial_Point_In_Sample := 0;
     Initial_Point_In_Ornament := 0;
     Point_In_Ornament := 0;
     Loop_Point_In_Ornament := 0;
     Substruction_for_Ton_Sliding := 0;
     Volume := 0;
     Point_In_Sample := 0;
     Ton_Deviation := 0;
     Loop_Point_In_Sample := 0;
     Ton_Sliding_Counter := 0;
     Amplitude_Delay_Counter := 0;
     Amplitude_Delay := 0;
     Addition_To_Note := 0;
     Current_Ton_Sliding := 0;
     Ton:=0
    end;}

     with PlParams[n].ASC, PLConsts[n].RAM^ do
      begin
       //"FillChared"    CurrentPosition := 0;
       DelayCounter := 1;
       Delay := ASC1_Delay;
       PlParams[n].ASC_A.Address_In_Pattern :=
         PWord(@Index[ASC1_PatternsPointers + 6 * Index[9]])^ + ASC1_PatternsPointers;
       PlParams[n].ASC_B.Address_In_Pattern :=
         PWord(@Index[ASC1_PatternsPointers + 6 * Index[9] + 2])^ +
         ASC1_PatternsPointers;
       PlParams[n].ASC_C.Address_In_Pattern :=
         PWord(@Index[ASC1_PatternsPointers + 6 * Index[9] + 4])^ +
         ASC1_PatternsPointers;
      end;

    end
   else if FType = FT.FTC then
    begin
     with PlParams[n].FTC, PLConsts[n].RAM^ do
      begin
       Delay := FTC_Delay;
       DelayCounter := 1;
       //"FillChared"    CurrentPosition := 0;
       Transposition := FTC_Positions[0].Transposition;
       PlParams[n].FTC_A.Address_In_Pattern :=
         PWord(@Index[FTC_PatternsPointer + FTC_Positions[0].Pattern * 6])^;
       PlParams[n].FTC_B.Address_In_Pattern :=
         PWord(@Index[FTC_PatternsPointer + FTC_Positions[0].Pattern * 6 + 2])^;
       PlParams[n].FTC_C.Address_In_Pattern :=
         PWord(@Index[FTC_PatternsPointer + FTC_Positions[0].Pattern * 6 + 4])^;
      end;

     with PlParams[n].FTC_A do
      begin
       OrnamentPointer := PLConsts[n].RAM^.FTC_OrnamentsPointers[0];
       SamplePointer := $52;
       //"FillChared"     Note_Skip_Counter := 0;
       //"FillChared"     Loop_Ornament_Position := 0;
       //"FillChared"     Position_In_Ornament := 0;
       Ornament_Length := 1;
{"FillChared"     Noise := 0;
     Noise_Accumulator := 0;
     Note_Accumulator := 0;
     Ton_Slide_Step1 := 0;
     Sample_Enabled := False;
     Envelope_Enabled := False;}
       Volume := 15;
       //"FillChared"     Ton := 0
      end;

     with PlParams[n].FTC_B do
      begin
       OrnamentPointer := PlParams[n].FTC_A.OrnamentPointer;
       SamplePointer := $52;
       //"FillChared"     Note_Skip_Counter := 0;
       //"FillChared"     Loop_Ornament_Position := 0;
       //"FillChared"     Position_In_Ornament := 0;
       Ornament_Length := 1;
{"FillChared"     Noise := 0;
     Noise_Accumulator := 0;
     Note_Accumulator := 0;
     Ton_Slide_Step1 := 0;
     Sample_Enabled := False;
     Envelope_Enabled := False;}
       Volume := 15;
       //"FillChared"     Ton := 0
      end;

     with PlParams[n].FTC_C do
      begin
       OrnamentPointer := PlParams[n].FTC_A.OrnamentPointer;
       SamplePointer := $52;
       //"FillChared"     Note_Skip_Counter := 0;
       //"FillChared"     Loop_Ornament_Position := 0;
       //"FillChared"     Position_In_Ornament := 0;
       Ornament_Length := 1;
{"FillChared"     Noise := 0;
     Noise_Accumulator := 0;
     Note_Accumulator := 0;
     Ton_Slide_Step1 := 0;
     Sample_Enabled := False;
     Envelope_Enabled := False;}
       Volume := 15;
       //"FillChared"     Ton := 0
      end;

    end
   else if (FType = FT.STP) or (FType = FT.STF) then
    begin

     with PlParams[n].STP, PLConsts[n].RAM^ do
      begin
       DelayCounter := 1;
       Transposition := Index[STP_PositionsPointer + 3];
       //"FillChared"    CurrentPosition := 0;
       PlParams[n].STP_A.Address_In_Pattern :=
         PWord(@Index[STP_PatternsPointer + Index[STP_PositionsPointer + 2]])^;
       PlParams[n].STP_B.Address_In_Pattern :=
         PWord(@Index[STP_PatternsPointer + Index[STP_PositionsPointer + 2] + 2])^;
       PlParams[n].STP_C.Address_In_Pattern :=
         PWord(@Index[STP_PatternsPointer + Index[STP_PositionsPointer + 2] + 4])^;
      end;

     with PlParams[n].STP_A, PLConsts[n].RAM^ do
      begin
       SamplePointer := PWord(@Index[STP_SamplesPointer])^;
       Loop_Sample_Position := Index[SamplePointer];
       Inc(SamplePointer);
       Sample_Length := Index[SamplePointer];
       Inc(SamplePointer);
       PlParams[n].STP_B.SamplePointer := SamplePointer;
       PlParams[n].STP_B.Loop_Sample_Position := Loop_Sample_Position;
       PlParams[n].STP_B.Sample_Length := Sample_Length;
       PlParams[n].STP_C.SamplePointer := SamplePointer;
       PlParams[n].STP_C.Loop_Sample_Position := Loop_Sample_Position;
       PlParams[n].STP_C.Sample_Length := Sample_Length;

       OrnamentPointer := PWord(@Index[STP_OrnamentsPointer])^;
       Loop_Ornament_Position := Index[OrnamentPointer];
       Inc(OrnamentPointer);
       Ornament_Length := Index[OrnamentPointer];
       Inc(OrnamentPointer);
       PlParams[n].STP_B.OrnamentPointer := OrnamentPointer;
       PlParams[n].STP_B.Loop_Ornament_Position := Loop_Ornament_Position;
       PlParams[n].STP_B.Ornament_Length := Ornament_Length;
       PlParams[n].STP_C.OrnamentPointer := OrnamentPointer;
       PlParams[n].STP_C.Loop_Ornament_Position := Loop_Ornament_Position;
       PlParams[n].STP_C.Ornament_Length := Ornament_Length;

{"FillChared"    Envelope_Enabled := False;
    Glissade := 0;
    Current_Ton_Sliding := 0;
    Enabled := False;
    Number_Of_Notes_To_Skip := 0;
    Note_Skip_Counter := 0;
    Volume := 0;
    Ton := 0}
      end;

{"FillChared"  with PlParams.STP_B do
   begin
    Envelope_Enabled := False;
    Glissade := 0;
    Current_Ton_Sliding := 0;
    Enabled := False;
    Number_Of_Notes_To_Skip := 0;
    Note_Skip_Counter := 0;
    Volume := 0;
    Ton := 0
   end;}

{"FillChared"  with PlParams.STP_C do
   begin
    Envelope_Enabled := False;
    Glissade := 0;
    Current_Ton_Sliding := 0;
    Enabled := False;
    Number_Of_Notes_To_Skip := 0;
    Note_Skip_Counter := 0;
    Volume := 0;
    Ton := 0
   end}

    end
   else if FType = FT.PSC then
    begin

     with PlParams[n].PSC, PLConsts[n].RAM^ do
      begin
       DelayCounter := 1;
       Delay := PSC_Delay;
       Positions_Pointer := PSC_PatternsPointer;
       Lines_Counter := 1;
       //"FillChared"    Noise_Base := 0
      end;

     with PlParams[n].PSC_A, PLConsts[n].RAM^ do
      begin
       SamplePointer := PSC_SamplesPointers[0] + $4c;
       PlParams[n].PSC_B.SamplePointer := SamplePointer;
       PlParams[n].PSC_C.SamplePointer := SamplePointer;
       OrnamentPointer := PWord(@Index[PSC_OrnamentsPointer])^ +
         PSC_OrnamentsPointer;
       PlParams[n].PSC_B.OrnamentPointer := OrnamentPointer;
       PlParams[n].PSC_C.OrnamentPointer := OrnamentPointer;

{"FillChared"    Break_Ornament_Loop := False;
    Ornament_Enabled := False;
    Enabled := False;
    Break_Sample_Loop := False;
    Ton_Slide_Enabled := False;}
       Note_Skip_Counter := 1;
       //"FillChared"    Ton := 0
      end;

     with PlParams[n].PSC_B do
      begin
{"FillChared"    Break_Ornament_Loop := False;
    Ornament_Enabled := False;
    Enabled := False;
    Break_Sample_Loop := False;
    Ton_Slide_Enabled := False;}
       Note_Skip_Counter := 1;
       //"FillChared"    Ton := 0
      end;

     with PlParams[n].PSC_C do
      begin
{"FillChared"    Break_Ornament_Loop := False;
    Ornament_Enabled := False;
    Enabled := False;
    Break_Sample_Loop := False;
    Ton_Slide_Enabled := False;}
       Note_Skip_Counter := 1;
       //"FillChared"    Ton := 0
      end;

    end
   else if FType = FT.PT1 then
    begin
     with PlParams[n].PT1, PLConsts[n].RAM^ do
      begin
       DelayCounter := 1;
       Delay := PT1_Delay;
       //"FillChared"    CurrentPosition := 0;
       Move(Index[PT1_PatternsPointer + PT1_PositionList[0] * 6],
         PlParams[n].PT1_A.Address_In_Pattern, 2);
       Move(Index[PT1_PatternsPointer + PT1_PositionList[0] * 6 + 2],
         PlParams[n].PT1_B.Address_In_Pattern, 2);
       Move(Index[PT1_PatternsPointer + PT1_PositionList[0] * 6 + 4],
         PlParams[n].PT1_C.Address_In_Pattern, 2);
      end;

     with PlParams[n].PT1_A do
      begin
       OrnamentPointer := PLConsts[n].RAM^.PT1_OrnamentsPointers[0];
{"FillChared"     Envelope_Enabled := False;
     Position_In_Sample := 0;
     Enabled := False;
     Number_Of_Notes_To_Skip := 0;
     Note_Skip_Counter := 0;}
       Volume := 15;
       //"FillChared"     Ton := 0
      end;

     with PlParams[n].PT1_B do
      begin
       OrnamentPointer := PlParams[n].PT1_A.OrnamentPointer;
{"FillChared"     Envelope_Enabled := False;
     Position_In_Sample := 0;
     Enabled := False;
     Number_Of_Notes_To_Skip := 0;
     Note_Skip_Counter := 0;}
       Volume := 15;
       //"FillChared"     Ton := 0
      end;

     with PlParams[n].PT1_C do
      begin
       OrnamentPointer := PlParams[n].PT1_A.OrnamentPointer;
{"FillChared"     Envelope_Enabled := False;
     Position_In_Sample := 0;
     Enabled := False;
     Number_Of_Notes_To_Skip := 0;
     Note_Skip_Counter := 0;}
       Volume := 15;
       //"FillChared"     Ton := 0
      end;

    end
   else if FType = FT.PT2 then
    begin
     with PlParams[n].PT2, PLConsts[n].RAM^ do
      begin
       DelayCounter := 1;
       Delay := PT2_Delay;
       //"FillChared"    CurrentPosition := 0;
      end;

     with PLConsts[n].RAM^ do
      begin
       PlParams[n].PT2_A.Address_In_Pattern :=
         PWord(@Index[PT2_PatternsPointer + PT2_PositionList[0] * 6])^;
       PlParams[n].PT2_B.Address_In_Pattern :=
         PWord(@Index[PT2_PatternsPointer + PT2_PositionList[0] * 6 + 2])^;
       PlParams[n].PT2_C.Address_In_Pattern :=
         PWord(@Index[PT2_PatternsPointer + PT2_PositionList[0] * 6 + 4])^;
      end;

     with PlParams[n].PT2_A, PLConsts[n].RAM^ do
      begin
       //extra code begin (pt2 has no default sample anyway)
       SamplePointer := PT2_SamplesPointers[1];
       Sample_Length := Index[SamplePointer];
       Inc(SamplePointer);
       Loop_Sample_Position := Index[SamplePointer];
       Inc(SamplePointer);
       //extra code end
       OrnamentPointer := PT2_OrnamentsPointers[0];
       Ornament_Length := Index[OrnamentPointer];
       Inc(OrnamentPointer);
       Loop_Ornament_Position := Index[OrnamentPointer];
       Inc(OrnamentPointer);
{"FillChared"    Envelope_Enabled := False;
    Position_In_Sample := 0;
    Position_In_Ornament := 0;
    Addition_To_Noise := 0;
    Glissade := 0;
    Current_Ton_Sliding:=0;
    GlissType := 0;
    Enabled := False;
    Number_Of_Notes_To_Skip := 0;
    Note_Skip_Counter := 0;}
       Volume := 15;
       //"FillChared"    Ton := 0
      end;

     with PlParams[n].PT2_B do
      begin
       //extra code begin (pt2 has no default sample anyway)
       SamplePointer := PlParams[n].PT2_A.SamplePointer;
       Sample_Length := PlParams[n].PT2_A.Sample_Length;
       Loop_Sample_Position := PlParams[n].PT2_A.Loop_Sample_Position;
       //extra code end
       OrnamentPointer := PlParams[n].PT2_A.OrnamentPointer;
       Loop_Ornament_Position := PlParams[n].PT2_A.Loop_Ornament_Position;
       Ornament_Length := PlParams[n].PT2_A.Ornament_Length;
{"FillChared"    Envelope_Enabled := False;
    Position_In_Sample := 0;
    Position_In_Ornament := 0;
    Addition_To_Noise := 0;
    Glissade := 0;
    Current_Ton_Sliding := 0;
    GlissType := 0;
    Enabled := False;
    Number_Of_Notes_To_Skip := 0;
    Note_Skip_Counter := 0;}
       Volume := 15;
       //"FillChared"    Ton := 0
      end;

     with PlParams[n].PT2_C do
      begin
       //extra code begin (pt2 has no default sample anyway)
       SamplePointer := PlParams[n].PT2_A.SamplePointer;
       Sample_Length := PlParams[n].PT2_A.Sample_Length;
       Loop_Sample_Position := PlParams[n].PT2_A.Loop_Sample_Position;
       //extra code end
       OrnamentPointer := PlParams[n].PT2_A.OrnamentPointer;
       Loop_Ornament_Position := PlParams[n].PT2_A.Loop_Ornament_Position;
       Ornament_Length := PlParams[n].PT2_A.Ornament_Length;
{"FillChared"    Envelope_Enabled := False;
    Position_In_Sample := 0;
    Position_In_Ornament := 0;
    Addition_To_Noise := 0;
    Glissade := 0;
    Current_Ton_Sliding := 0;
    GlissType := 0;
    Enabled := False;
    Number_Of_Notes_To_Skip := 0;
    Note_Skip_Counter := 0;}
       Volume := 15;
       //"FillChared"    Ton := 0
      end;
    end
   else if FType = FT.PT3 then
    begin
     with PlParams[n].PT3, PLConsts[n].RAM^ do
      begin
       DelayCounter := 1;
       Delay := PT3_Delay;
{"FillChared"    CurrentPosition := 0;
    Noise_Base := 0;
    AddToNoise := 0;
    Cur_Env_Slide := 0;
    Cur_Env_Delay := 0;
    Env_Base.wrd := 0}
      end;

     with PLConsts[n].RAM^ do
      begin
       i := PT3_PositionList[0];
       b := PLConsts[n].TS;
       if b <> $20 then i := b * 3 - 3 - i;
       PlParams[n].PT3_A.Address_In_Pattern :=
         PWord(@Index[PT3_PatternsPointer + i * 2])^;
       PlParams[n].PT3_B.Address_In_Pattern :=
         PWord(@Index[PT3_PatternsPointer + i * 2 + 2])^;
       PlParams[n].PT3_C.Address_In_Pattern :=
         PWord(@Index[PT3_PatternsPointer + i * 2 + 4])^;
      end;

     with PlParams[n].PT3_A, PLConsts[n].RAM^ do
      begin
       OrnamentPointer := PT3_OrnamentsPointers[0];
       Loop_Ornament_Position := Index[OrnamentPointer];
       Inc(OrnamentPointer);
       Ornament_Length := Index[OrnamentPointer];
       Inc(OrnamentPointer);
       //extra code begin (pt3 has no default sample anyway)
       SamplePointer := PT3_SamplesPointers[1];
       Loop_Sample_Position := Index[SamplePointer];
       Inc(SamplePointer);
       Sample_Length := Index[SamplePointer];
       Inc(SamplePointer);
       //extra code end
       Volume := 15;
       //"FillChared"     Current_Ton_Sliding := 0;
       Note_Skip_Counter := 1;
{"FillChared"     Current_OnOff := 0;
     Enabled := False;
     Envelope_Enabled := False;
     Note := 0;
     Ton := 0}
      end;

     with PlParams[n].PT3_B do
      begin
       OrnamentPointer := PlParams[n].PT3_A.OrnamentPointer;
       Loop_Ornament_Position := PlParams[n].PT3_A.Loop_Ornament_Position;
       Ornament_Length := PlParams[n].PT3_A.Ornament_Length;
       //extra code begin (pt3 has no default sample anyway)
       SamplePointer := PlParams[n].PT3_A.SamplePointer;
       Loop_Sample_Position := PlParams[n].PT3_A.Loop_Sample_Position;
       Sample_Length := PlParams[n].PT3_A.Sample_Length;
       //extra code end
       Volume := 15;
       //"FillChared"     Current_Ton_Sliding := 0;
       Note_Skip_Counter := 1;
{"FillChared"     Current_OnOff := 0;
     Enabled := False;
     Envelope_Enabled := False;
     Note := 0;
     Ton := 0}
      end;

     with PlParams[n].PT3_C do
      begin
       OrnamentPointer := PlParams[n].PT3_A.OrnamentPointer;
       Loop_Ornament_Position := PlParams[n].PT3_A.Loop_Ornament_Position;
       Ornament_Length := PlParams[n].PT3_A.Ornament_Length;
       //extra code begin (pt3 has no default sample anyway)
       SamplePointer := PlParams[n].PT3_A.SamplePointer;
       Loop_Sample_Position := PlParams[n].PT3_A.Loop_Sample_Position;
       Sample_Length := PlParams[n].PT3_A.Sample_Length;
       //extra code end
       Volume := 15;
       //"FillChared"     Current_Ton_Sliding := 0;
       Note_Skip_Counter := 1;
{"FillChared"     Current_OnOff := 0;
     Enabled := False;
     Envelope_Enabled := False;
     Note := 0;
     Ton := 0}
      end;

    end
   else if FType = FT.SQT then
    begin
{"FillChared"  with PlParams.SQT_A do
   begin
    Ton:=0;
    Envelope_Enabled := False;
    Ornament_Enabled := False;
    Gliss := False;
    Enabled := False
   end;
  with PlParams.SQT_B do
   begin
    Ton:=0;
    Envelope_Enabled := False;
    Ornament_Enabled := False;
    Gliss := False;
    Enabled := False
   end;
  with PlParams.SQT_C do
   begin
    Ton:=0;
    Envelope_Enabled := False;
    Ornament_Enabled := False;
    Gliss := False;
    Enabled := False
   end;}

     with PlParams[n].SQT do
      begin
       DelayCounter := 1;
       Delay := 1;
       Lines_Counter := 1;
       Positions_Pointer := PLConsts[n].RAM^.SQT_PositionsPointer;
      end;

    end
   else if FType = FT.PSM then
    begin
     with PlParams[n].PSM, PLConsts[n].RAM^ do
      begin
       //"FillChared"    CurrentPosition := 0;
       //"FillChared"    Finished := False;
       b := Index[PSM_PositionsPointer];
       Transposition := Index[PSM_PositionsPointer + 1] + 48;
       Delay := Index[PSM_PatternsPointer + b * 7];
       PlParams[n].PSM_A.Address_In_Pattern :=
         PWord(@Index[PSM_PatternsPointer + b * 7 + 1])^;
       PlParams[n].PSM_B.Address_In_Pattern :=
         PWord(@Index[PSM_PatternsPointer + b * 7 + 3])^;
       PlParams[n].PSM_C.Address_In_Pattern :=
         PWord(@Index[PSM_PatternsPointer + b * 7 + 5])^;
{"FillChared"    PlParams.PSM_A.RetCnt := 0;
    PlParams[n].PSM_B.RetCnt := 0;
    PlParams[n].PSM_C.RetCnt := 0;}
       PlParams[n].PSM_A.Note_Skip_Counter := 1;
       PlParams[n].PSM_B.Note_Skip_Counter := 1;
       PlParams[n].PSM_C.Note_Skip_Counter := 1;
       PlParams[n].PSM_A.Note := -128;
       PlParams[n].PSM_B.Note := -128;
       PlParams[n].PSM_C.Note := -128;
       DelayCounter := 1;
      end;
    end;
 end;

const
 DumpIM2: packed array[0..9] of byte =
   ($F3, $CD, 0, 0, $ED, $5E, $FB, $76, $18, $FA);
 DumpIM1: packed array[0..12] of byte =
   ($F3, $CD, 0, 0, $ED, $56, $FB, $76, $CD, 0, 0, $18, $F7);
var
 Offs1, Offs2: int64;
 w, w1: word;
 si: smallint;
 b: byte;
begin
 if IsAYNativeFileType(CurFileType) then
   FillChar(PlParams, SizeOf(PlParams), 0);

 if CurFileType = FT.OUT then
  begin
   UniFileSeek(FileHandle, 0);
   Previous_AY_Takt := 0;
  end
 else if CurFileType = FT.AYM then
  begin
   InProc := @InitialInProc;
   OutProc := @InitialOutProc;
   Previous_Tact := 0;
   IntBeeper := False;
   IntAY := False;
   CPCSwitch := 0;
   CPCData := 0;
   CurrentTact := 0;
   Z80_Registers.Common := @CommonMain;
   PCommonAlt := @CommonAlt;
   Z80_Registers.AF := @AFMain;
   PAFAlt := @AFAlt;
   IFF := False;
   EIorDDorFD := False;
   IMode := 0;
   ZRAM.Index[65536] := ZRAM.Index[0];
   PArray0OfByte(@AYMFileHeader.AF)[AYMFileHeader.RegPos] :=
     AYBlocks + AYMFileHeader.MusMin;
   AFMain.AllWord := AYMFileHeader.AF;
   CommonMain.BC.AllWord := AYMFileHeader.BC;
   CommonMain.DE.AllWord := AYMFileHeader.DE;
   CommonMain.HL.AllWord := AYMFileHeader.HL;
   Z80_Registers.IX.AllWord := AYMFileHeader.IX;
   Z80_Registers.IY.AllWord := AYMFileHeader.IY;
   Z80_Registers.SP := $4000;
   Z80_Registers.PC := 2;
   R_Hi_Bit := 0;
   Z80_Registers.IR.AllWord := 0;
  end
 else if CurFileType = FT.SNDH then
   Atari_PrepEmu(FrmMixer.STeRB.Checked)
 else if CurFileType = FT.AY then
  begin
   InProc := @InitialInProc;
   OutProc := @InitialOutProc;
   Previous_Tact := 0;
   IntBeeper := False;
   IntAY := False;
   CPCSwitch := 0;
   CPCData := 0;
   CurrentTact := 0;
   Z80_Registers.Common := @CommonMain;
   PCommonAlt := @CommonAlt;
   Z80_Registers.AF := @AFMain;
   PAFAlt := @AFAlt;
   IFF := False;
   EIorDDorFD := False;
   IMode := 0;

   UniFileSeek(FileHandle, AYBlocks);
   FillChar(ZRAM.Index[10], 255 - 10 + 1, 201);
   FillChar(ZRAM.Index[256], 16383 - 256 + 1, 255);
   FillChar(ZRAM.Index[16384], 65535 - 16384 + 1, 0);
   ZRAM.Index[56] := $FB;
   if AYPoints.Inter <> 0 then
    begin
     Move(DumpIM1, ZRAM, 13);
     PWord(@ZRAM.Index[9])^ := AYPoints.Inter;
    end
   else
     Move(DumpIM2, ZRAM, 10);
   PWord(@ZRAM.Index[2])^ := AYPoints.Init;
   ZRAM.Index[65536] := ZRAM.Index[0];
   Z80_Registers.SP := AYPoints.Stek;
   b := AYSongData.HiReg;
   AFMain.HiByte := b;
   AFAlt.HiByte := b;
   CommonMain.HL.HiByte := b;
   CommonMain.DE.HiByte := b;
   CommonMain.BC.HiByte := b;
   CommonAlt.HL.HiByte := b;
   CommonAlt.DE.HiByte := b;
   CommonAlt.BC.HiByte := b;
   Z80_Registers.IX.HiByte := b;
   Z80_Registers.IY.HiByte := b;
   b := AYSongData.LoReg;
   AFMain.LoByte := b;
   AFAlt.LoByte := b;
   CommonMain.HL.LoByte := b;
   CommonMain.DE.LoByte := b;
   CommonMain.BC.LoByte := b;
   CommonAlt.HL.LoByte := b;
   CommonAlt.DE.LoByte := b;
   CommonAlt.BC.LoByte := b;
   Z80_Registers.IX.LoByte := b;
   Z80_Registers.IY.LoByte := b;
   Z80_Registers.IR.AllWord := $300;
   R_Hi_Bit := 0;
   Z80_Registers.PC := 0;
   UniRead(FileHandle, @w, 2);
   while w <> 0 do
    begin
     w := SwapEndian(w);
     if AYPoints.Init = 0 then
      begin
       PWord(@ZRAM.Index[2])^ := w;
       AYPoints.Init := w;
      end;
     UniRead(FileHandle, @w1, 2);
     w1 := SwapEndian(w1);
     if w1 + w > 65536 then
       w1 := 65536 - w;
     UniRead(FileHandle, @si, 2);
     Offs1 := smallint(SwapEndian(si)) +
       UniReadersData[FileHandle]^.UniFilePos - 2;
     if Offs1 + int64(w1) > UniReadersData[FileHandle]^.UniFileSize then
       w1 := UniReadersData[FileHandle]^.UniFileSize - int64(Offs1);
     Offs2 := UniReadersData[FileHandle]^.UniFilePos;
     UniFileSeek(FileHandle, Offs1);
     UniRead(FileHandle, @ZRAM.Index[w], w1);
     UniFileSeek(FileHandle, Offs2);
     UniRead(FileHandle, @w, 2);
    end;
  end
 else if (CurFileType = FT.YM2) or (CurFileType = FT.YM5) or (CurFileType = FT.YM6) then
  begin
   if CurFileType = FT.YM5 then
    begin
     AtariSE1Type := 0;
     AtariSE2Type := 1;
    end;
   Position_In_VTX := 0;
   AtariSE1Channel := 0;
   AtariSE2Channel := 0;
   AtariTimerCounter1 := 0;
   AtariTimerCounter2 := 0;
   YM6CurTik := YM6TiksOnInt;
   AtariV1 := 0;
   AtariV2 := 0;
   YM6SinusPos1 := 0;
   YM6SinusPos2 := 0;
  end
 else if IsAYNativeFileType(CurFileType) then
  begin
   InitTrackerModule(CurFileType, 0);
   if TSMode then InitTrackerModule(CurFileType1, 1);
  end
 else if (CurFileType = FT.VTX) or (CurFileType = FT.YM3) or (CurFileType = FT.YM3b) then
   Position_In_VTX := 0
 else if CurFileType = FT.EPSG then
  begin
   UniFileSeek(FileHandle, 16);
   Previous_AY_Takt := 0;
  end
 else if CurFileType = FT.PSG then
  begin
   UniFileSeek(FileHandle, 16);
   PSG_Skip := 0;
  end
 else if CurFileType = FT.ZXAY then
  begin
   UniFileSeek(FileHandle, 4);
   Previous_AY_Takt := 0;
  end;
 Real_End_All := False;
 Real_End[0] := False;
 Real_End[1] := False;
 if InitAll then
  begin
   if IsFilt >= 0 then
    begin
     FillChar(Filt_XL[0], (Filt_M + 1) * 4, 0);
     FillChar(Filt_XR[0], (Filt_M + 1) * 4, 0);
     Filt_I := 0;
    end;
   Beeper := 0;
   BaseSample := 0;
   MkVisPos := 0;
   VisPoint := 0;
   NOfTicks := 0;
   ResetAYChipEmulation(0, True);
   if TSMode then ResetAYChipEmulation(1, True);
   PlConsts[0].Global_Tick_Counter := 0;
   PlConsts[1].Global_Tick_Counter := 0;
   CurrTime_Rasch := 0;
   if IsAYChipFileType(CurFileType) then
     ProgrMax := round(Time_ms / 1000 * SampleRate);
   VProgrPos := 0;
   ShowProgress(VProgrPos);
  end;
end;

procedure InsertTitleASC(var Module: ModTypes; var Sz: integer; const TtlStr: string);
var
 n: integer;
begin
 if Sz > 65536 - 63 then exit;
 if Length(TtlStr) <> 63 then exit;
 if Module.ASC1_PatternsPointers - Module.ASC1_Number_Of_Positions <> 9 then exit;
 if Copy(TtlStr, 1, Length(AscId)) <> AscId then exit; //todo pos(AscId
 Inc(Module.ASC1_PatternsPointers, 63);
 Inc(Module.ASC1_SamplesPointers, 63);
 Inc(Module.ASC1_OrnamentsPointers, 63);
 n := Module.ASC1_Number_Of_Positions;
 Move(Module.ASC1_Positions[n], Module.ASC1_Positions[n + 63], Sz - 9 - n);
 Move(TtlStr[1], Module.ASC1_Positions[n], 63);
 Inc(Sz, 63);
end;

procedure InsertTitleSTP(var Module: ModTypes; var Sz: integer; const TtlStr: string);
var
 KsaId2: string;
 i: integer;
 p: PWord;
begin
 if Sz > 65536 - 53 then exit;
 if Length(TtlStr) <> 53 then exit;
 if Copy(TtlStr, 1, Length(KsaId)) <> KsaId then exit; //todo pos(KsaId
 SetLength(KsaId2, Length(KsaId));
 Move(Module.Index[10], KsaId2[1], Length(KsaId)); //todo memcpy
 if KsaId2 = KsaId then exit;
 Inc(Module.STP_PositionsPointer, 53);
 Inc(Module.STP_PatternsPointer, 53);
 Inc(Module.STP_OrnamentsPointer, 53);
 Inc(Module.STP_SamplesPointer, 53);
 Move(Module.Index[10], Module.Index[10 + 53], Sz - 10);
 Move(TtlStr[1], Module.Index[10], 53);
 Inc(Sz, 53);
 p := @Module.Index[Module.STP_PatternsPointer];
 for i := 1 to (Sz - Module.STP_PatternsPointer) div 2 do
  begin
   Inc(p^, 53);
   Inc(p);
  end;
end;

procedure InsertTitleSTC(var Module: ModTypes; var Sz: integer; const TtlStr: string);
var
 i, j: integer;
begin
 if Sz > 65536 - 55 then exit;
 if Length(TtlStr) <> 55 then exit;
 if Sz <= Module.ST_PatternsPointer then exit;
 if (Pos(StcId, TtlStr) <> 1) and (Pos(KsaId, TtlStr) <> 1) then exit;
 if Module.ST_PatternsPointer >= 55 + 27 then
   if CompareMem(@Module.Index[Module.ST_PatternsPointer - 55],
     @StcId[1], Length(StcId)) or CompareMem(
     @Module.Index[Module.ST_PatternsPointer - 55], @KsaId[1], Length(KsaId)) then
     Exit;
 Move(Module.Index[Module.ST_PatternsPointer],
   Module.Index[Module.ST_PatternsPointer + 55], Sz - Module.ST_PatternsPointer);
 Move(TtlStr[1], Module.Index[Module.ST_PatternsPointer], 55);
 i := Module.ST_PatternsPointer;
 Inc(Module.ST_PatternsPointer, 55);
 j := Module.ST_PatternsPointer;
 if Module.ST_Size = Sz then
   Inc(Module.ST_Size, 55);
 Inc(Sz, 55);
 while (j < Sz) and (Module.Index[j] <> 255) do
  begin
   if j > Sz - 7 then break;
   if PWord(@Module.Index[j + 1])^ >= i then
     //на всякий случай, в нормальном модуле не нужно
     Inc(PWord(@Module.Index[j + 1])^, 55);
   if PWord(@Module.Index[j + 3])^ >= i then
     Inc(PWord(@Module.Index[j + 3])^, 55);
   if PWord(@Module.Index[j + 5])^ >= i then
     Inc(PWord(@Module.Index[j + 5])^, 55);
   Inc(j, 7);
  end;
end;

procedure InsertTitleST3(var Module: ModTypes; var Sz: integer; const TtlStr: string);

 procedure IncPtrs(j: integer);
 var
   i: integer;
 begin
   i := Module.Index[j];
   Inc(j);
   for i := 0 to i - 1 do
    begin
     Inc(PWord(@Module.Index[j])^, 55);
     Inc(j, 2);
    end;
 end;

var
 i, j: integer;
begin
 if Sz > 65536 - 55 then exit;
 if Length(TtlStr) <> 55 then exit;
 if Pos(KsaId, TtlStr) <> 1 then exit;
 //min ST3 size
 if Sz < 9{hdr} + 130 + 3{sam} + 32 + 3{orn} + 3{pos} + 6 + 3{pat} then
   exit;

 i := Module.ST3_PositionsPointer - 9;
 if (i <= 0) or (i mod 130 <> 0) then exit; //broken or tag inserted already

 Move(Module.Index[9], Module.Index[9 + 55], Sz - 9);
 Move(TtlStr[1], Module.Index[9], 55);
 Inc(Module.ST3_PositionsPointer, 55);
 Inc(Module.ST3_SamplesPointer, 55);
 Inc(Module.ST3_OrnamentsPointer, 55);
 Inc(Module.ST3_PatternsPointer, 55);
 Inc(Sz, 55);

 IncPtrs(Module.ST3_SamplesPointer);
 IncPtrs(Module.ST3_OrnamentsPointer);
 j := Module.ST3_PatternsPointer;
 while j <= Sz - 6 do
  begin
   Inc(PWord(@Module.Index[j])^, 55);
   Inc(PWord(@Module.Index[j + 2])^, 55);
   Inc(PWord(@Module.Index[j + 4])^, 55);
   Inc(j, 6);
  end;
end;

procedure PrepareToSaveST3(var Module: ModTypes; Sz: integer);
var
 i, num, ptr, loadaddr: integer;
begin
 ptr := Module.ST3_SamplesPointer;
 num := Module.Index[ptr];
 Inc(ptr);
 loadaddr := PWord(@Module.Index[ptr])^ - 9;
 if ((Module.ST3_PositionsPointer - 9) mod 130 <> 0) then
   Dec(loadaddr, 55);
 if loadaddr <= 0 then
   Exit;
 for i := 0 to num - 1 do
  begin
   Dec(PWord(@Module.Index[ptr])^, loadaddr);
   Inc(ptr, 2);
  end;
 ptr := Module.ST3_OrnamentsPointer;
 num := Module.Index[ptr];
 Inc(ptr);
 for i := 0 to num - 1 do
  begin
   Dec(PWord(@Module.Index[ptr])^, loadaddr);
   Inc(ptr, 2);
  end;
end;

(* All available FXM extracted already, so no need to keep the FXM-finder
function FoundFXM(var TimeLength,LoopPoint:integer):boolean;
var
 Limit:integer;

 function ValidSample(var Add2:integer):boolean;
 var
  b:byte;
  Addr:integer;
 begin
  Result := False;
  if Add2 >= Limit then exit;
  Addr := Add2;
  b := F_Frame.Index[Addr];
  if b = $80 then exit;
  repeat
   case b of
   0..$F:
    begin
     inc(Addr);
     if Addr >= Limit then exit
    end;
   $80:
    begin
     inc(Addr,3);
     if Addr <= Limit + 1 then
      begin
       Result := True;
       Add2 := Addr
      end;
     exit
    end;
   $32..$41:
   else exit;
   end;
   inc(Addr);
   if Addr >= Limit then exit;
   b := F_Frame.Index[Addr]
  until False
 end;

 function ValidOrnament(var Add2:integer):boolean;
 var
  b:shortint;
  flg,flg82,flg83,flg84:boolean;
  Mode:boolean;
  Addr:integer;
 begin
  Result := False;
  if Add2 >= Limit then exit;
  Mode := True;
  Addr := Add2;
  b := F_Frame.Index[Addr];
  if b = -128 then exit;
  flg := False;
  flg82 := False;
  flg83 := False;
  flg84 := False;
  repeat
   case b of
   -126:
    begin
     if flg82 or flg83 then exit;
     Mode := True;
     flg82 := True
    end;
   -125:
    begin
     if flg83 or flg82 then exit;
     Mode := False;
     flg83 := True
    end;
   -124:
    begin
     if flg84 then exit;
     flg84 := True
    end;
   -128:
    begin
     if not flg then exit;
     inc(Addr,3);
     if Addr <= Limit + 1 then
      begin
       Result := True;
       Add2 := Addr
      end;
     exit
    end;
   else
    begin
     if Mode then
      if (b < -$53) or (b > $53) then exit;
     flg := True;
     flg82 := False;
     flg83 := False;
     flg84 := False
    end;
   end;
   inc(Addr);
   if Addr >= Limit then exit;
   b := F_Frame.Index[Addr]
  until False
 end;

 function ValidPattern(var Addr,Add2:integer;var Podpr:boolean):boolean;
 var
  flg:boolean;
  flg86,flg87,flg82,flg84,flg88,flg8a,flg8b,flg8d,flg8e:boolean;
  count82:integer;
  b:byte;
 begin
  Result := False;
  Add2 := Addr;
  if Addr >= Limit then exit;
  b := F_Frame.Index[Addr];
  if b = $80 then exit;
  flg := False;
  flg86 := False;
  flg87 := False;
  flg82 := False;
  count82 := 0;
  flg84 := False;
  flg88 := False;
  flg8a := False;
  flg8b := False;
  flg8d := False;
  flg8e := False;
  repeat
   case b of
   0..$54:
    begin
     inc(Addr);
     if Addr >= Limit then exit;
     flg := True;
     flg82 := False;
     flg86 := False;
     flg87 := False;
     flg84 := False;
     flg88 := False;
     flg8a := False;
     flg8b := False;
     flg8d := False;
     flg8e := False
    end;
   $80:
    begin
     if not flg then exit;
     inc(Addr,3);
     Podpr := False;
     Result := Addr <= Limit + 1;
     exit
    end;
   $89:
    begin
     if not flg or (count82 <> 0) then exit;
     inc(Addr);
     Podpr := True;
     Result := Addr <= Limit + 1;
     exit
    end;
   $81:
    begin
     inc(Addr,2);
     if Addr >= Limit then exit;
     flg := True;
     flg82 := False;
     flg86 := False;
     flg87 := False;
     flg84 := False;
     flg88 := False;
     flg8a := False;
     flg8b := False;
     flg8d := False;
     flg8e := False
    end;
   $82: 
    begin
     inc(Addr);
     if Addr >= Limit then exit;
     inc(count82);
     flg82 := True
    end;
   $83:
    begin
     if flg82 then exit;
     if count82 <= 0 then exit;
     flg := True;
     flg82 := False;
     flg86 := False;
     flg87 := False;
     flg84 := False;
     flg88 := False;
     flg8a := False;
     flg8b := False;
     flg8d := False;
     flg8e := False;
     dec(count82)
    end;
   $84:
    begin
     if flg84 then exit;
     inc(Addr);
     if Addr >= Limit then exit;
     flg84 := True
    end;
   $85:
    begin
     inc(Addr);
     if Addr >= Limit then exit;
    end;
   $86:
    begin
     if flg86 then exit;
     inc(Addr,2);
     if Addr >= Limit then exit;
     flg86 := True
    end;
   $87:
    begin
     if flg87 then exit;
     inc(Addr,2);
     if Addr >= Limit then exit;
     flg87 := True
    end;
   $88: 
    begin
     if flg88 then exit;
     inc(Addr);
     if Addr >= Limit then exit;
     flg88 := True
    end;
   $8A:
    begin
     if flg8a or flg8b then exit;
     flg8a := True
    end;
   $8B:
    begin
     if flg8a or flg8b then exit;
     flg8b := True
    end;
   $8C:
    begin
     inc(Addr,2);
     if Addr >= Limit then exit
    end;
   $8D:
    begin
     if flg8d then exit;
     inc(Addr);
     if Addr >= Limit then exit;
     flg8d := True
    end;
   $8E:
    begin
     if flg8e then exit;
     inc(Addr);
     if Addr >= Limit then exit;
     flg8e := True
    end;
   else exit;
   end;
   inc(Addr);
   if Addr >= Limit then exit;
   b := F_Frame.Index[Addr]
  until False;
 end;

type
 FXMTypes = (TPat,TSub,TSam,TOrn);
 PFXMObject = ^FXMObject;
 FXMObject = record
   Addr,Last:word;
   Typ:FXMTypes;
 end;
var
 RecDeep:integer;
 function BuildPatternStructure(var Pat:TList;Addr:integer):boolean;
  function ValidSample(var Addr,Add2:integer):boolean;
  var
   b:byte;
  begin
   Result := False;
   Add2 := Addr;
   if Addr > Limit then exit;
   b := F_Frame.Index[Addr];
   if b = $80 then exit;
   repeat
    case b of
    0..$F:
     begin
      inc(Addr);
      if Addr >= Limit then exit
     end;
    $80:
     begin
      inc(Addr,3);
      if Addr <= Limit + 1 then
       begin
        if WordPointer(@F_Frame.Index[Addr - 2])^ < F_Address + 6 then exit;
        Result := True;
        exit
       end
     end;
    $32..$41:
    else
     exit;
    end; 
    inc(Addr);
    if Addr >= Limit then exit;
    b := F_Frame.Index[Addr]
   until False
  end;

  function ValidOrnament(var Addr,Add2:integer):boolean;
  var
   b:shortint;
   flg,flg82,flg83,flg84:boolean;
  begin
   Result := False;
   Add2 := Addr;
   if Addr > Limit then exit;
   b := F_Frame.Index[Addr];
   if b = -128 then exit;
   flg := False;
   flg82 := False;
   flg83 := False;
   flg84 := False;
   repeat
    case b of
    -126:
     begin
      if flg82 or flg83 then exit;
      flg82 := True
     end;
    -125:
     begin
      if flg83 or flg82 then exit;
      flg83 := True
     end;
    -124:
     begin
      if flg84 then exit;
      flg84 := True
     end;
    -128:
     begin
      if not flg then exit;
      inc(Addr,3);
      if Addr <= Limit + 1 then
       begin
        if WordPointer(@F_Frame.Index[Addr - 2])^ < F_Address + 6 then exit;
        Result := True;
        exit
       end
     end;
    else
     begin
      flg := True;
      flg82 := False;
      flg83 := False;
      flg84 := False
     end;
    end;
    inc(Addr);
    if Addr >= Limit then exit;
    b := F_Frame.Index[Addr]
   until False
  end;

 var
  b:byte;
  Add2,AddT1,AddT2:integer;
  FXMO:PFXMObject;
  i:integer;
 begin
  Result := False;
  if RecDeep > 15 then exit;
  if Addr < F_Address + 6 then exit;
  dec(Addr,F_Address);
  if Addr >= Limit then exit;
  Add2 := Addr;
  b := F_Frame.Index[Addr];
  if b = $80 then exit;
  repeat
   case b of
   $8D,$8E,$88,
   $84,$85,$82,
   0..$54:
    begin
     inc(Addr);
     if Addr >= Limit then exit;
    end;
   $80:
    begin
     inc(Addr,3);
     if Addr <= Limit + 1 then
      begin
       if WordPointer(@F_Frame.Index[Addr - 2])^ < F_Address + 6 then exit;
       Result := True;
       New(FXMO);
       FXMO.Addr := Add2;
       FXMO.Last := Addr;
       FXMO.Typ := TPat;
       Pat.Add(FXMO)
      end;
     exit
    end;
   $89:
    begin
     inc(Addr);
     if Addr <= Limit + 1 then
      begin
       Result := True;
       New(FXMO);
       FXMO.Addr := Add2;
       FXMO.Last := Addr;
       FXMO.Typ := TSub;
       Pat.Add(FXMO)
      end;
     exit
    end;
   $81: 
    begin
     inc(Addr,2);
     if Addr >= Limit then exit;
     if WordPointer(@F_Frame.Index[Addr - 1])^ < F_Address + 6 then exit;
     inc(RecDeep);
     if not BuildPatternStructure(Pat,
                WordPointer(@F_Frame.Index[Addr - 1])^) then exit;
     dec(RecDeep)
    end;
   $86:
    begin
     inc(Addr,2);
     if Addr >= Limit then exit;
     i := WordPointer(@F_Frame.Index[Addr - 1])^ - F_Address;
     if i < 6 then exit;
     AddT1 := i;
     if not ValidOrnament(AddT1,AddT2) then exit;
     New(FXMO);
     FXMO.Addr := AddT2;
     FXMO.Last := AddT1;
     FXMO.Typ := TOrn;
     Pat.Add(FXMO)
    end;
   $87:
    begin
     inc(Addr,2);
     if Addr >= Limit then exit;
     i := WordPointer(@F_Frame.Index[Addr - 1])^ - F_Address;
     if i < 6 then exit;
     AddT1 := i;
     if not ValidSample(AddT1,AddT2) then exit;
     New(FXMO);
     FXMO.Addr := AddT2;
     FXMO.Last := AddT1;
     FXMO.Typ := TSam;
     Pat.Add(FXMO)
    end;
   $8C:
    begin
     inc(Addr,2);
     if Addr >= Limit then exit
    end;
   $8A,$8B,$83:
   else
    exit;
   end;
   inc(Addr);
   if Addr >= Limit then exit;
   b := F_Frame.Index[Addr]
  until False;
 end;

 function FXM_Structure(var Size:word):boolean;
 var
  PatA,PatB,PatC:TList;
  i:integer;
  min,max:word;
 begin
  Result := False;
  PatA := TList.Create;
  PatB := TList.Create;
  PatC := TList.Create;
  RecDeep := 0;
  if BuildPatternStructure(PatA,WordPointer(@F_Frame.Index[0])^) then
   if BuildPatternStructure(PatB,WordPointer(@F_Frame.Index[2])^) then
    if BuildPatternStructure(PatC,WordPointer(@F_Frame.Index[4])^) then
   begin
    max := 0;
    min := 65535;
    for i := 0 to PatA.Count - 1 do
     begin
      if min > PFXMObject(PatA.Items[i]).Addr then
       min := PFXMObject(PatA.Items[i]).Addr;
      if max < PFXMObject(PatA.Items[i]).Last then
       max := PFXMObject(PatA.Items[i]).Last;
     end;
    for i := 0 to PatB.Count - 1 do
     begin
      if min > PFXMObject(PatB.Items[i]).Addr then
       min := PFXMObject(PatB.Items[i]).Addr;
      if max < PFXMObject(PatB.Items[i]).Last then
       max := PFXMObject(PatB.Items[i]).Last;
     end;
    for i := 0 to PatC.Count - 1 do
     begin
      if min > PFXMObject(PatC.Items[i]).Addr then
       min := PFXMObject(PatC.Items[i]).Addr;
      if max < PFXMObject(PatC.Items[i]).Last then
       max := PFXMObject(PatC.Items[i]).Last;
     end;
    Size := max;
    Result := (min in [6..56]) and (Size >= 63)
   end;
  for i := 0 to PatA.Count - 1 do
   Dispose(PFXMObject(PatA.Items[i]));
  PatA.Clear;
  for i := 0 to PatB.Count - 1 do
   Dispose(PFXMObject(PatB.Items[i]));
  PatB.Clear;
  for i := 0 to PatC.Count - 1 do
   Dispose(PFXMObject(PatC.Items[i]));
  PatC.Clear;
 end;

type
 TPatterns = record
   Address:word;
   FirstFreeAddress:word;
 end;

var
 Add1,Add2:integer;
 Podpr:boolean;
 Patterns:array[0..16383] of TPatterns;
 NPat,i,j:integer;
 Size:word;
 M:PModTypes;
begin
TimeLength := 0;
LoopPoint := 0;
FoundFXM := False;
if Readen1 < 63 then exit;
NPat := 0;

if Readen1 < 49152 then
 Limit := Readen1
else
 Limit := 49151;

Podpr := False;
for i := 6 to 50 do
 if F_Frame.Index[i] in [$80,$86,$87] then
  begin
   Podpr := True;
   break
  end;
if not Podpr then exit;

Add1 := 6;
repeat
if not ValidSample(Add1) then
 if ValidPattern(Add1,Add2,Podpr) then
  begin
   if not Podpr then
    begin
     if NPat = 16384 then exit;
     Patterns[NPat].Address := Add2;
     Patterns[NPat].FirstFreeAddress := Add1;
     inc(NPat)
    end
  end
 else if not ValidOrnament(Add2) then
  begin
   if NPat = 0 then exit;
   for i := 0 to NPat - 1 do
    for j := 0 to 2 do
     begin
      F_Address := WordPointer(@F_Frame.Index[j*2])^ - Patterns[i].Address;
      if F_Address >= 0 then
       if FXM_Structure(Size) then
        begin
         if IntegrityCheck then
          try
           New(M);
           try
            if not LoadTrackerModule(M^,-1,F_Address,Size,F_Frame,FXMFile) then exit;
            GetTimeFXM(M,F_Address,TimeLength,LoopPoint);
            if TimeLength = 0 then exit
           finally
            Dispose(M)
           end 
          except
           exit
          end;
         FoundFXM := True;
         F_Length := Size;
         Exit
        end;
     end;
   Exit
  end
 else
  Add1 := Add2
until False
end;*)

function FoundGTR(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1: integer;
 w, w2, adr: word;
 b: byte;
 wp: PWord;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundGTR := False;
 if Readen1 < 296 then exit;
 adr := F_Frame^.GTR_Address;
 w := F_Frame^.GTR_PatternsPointers[0].PatternA - adr;
 if w > Readen1 then exit;
 b := F_Frame^.GTR_NumberOfPositions;
 if w <> b + 295 then exit;
 if F_Frame^.GTR_LoopPosition >= b then exit;
 for j := 0 to 13 do
  begin
   j1 := F_Frame^.GTR_SamplesPointers[j + 1] - F_Frame^.GTR_SamplesPointers[j];
   if j1 < 6 then exit;
   if (j1 - 2) mod 4 <> 0 then exit;
  end;

 wp := @F_Frame^.GTR_OrnamentsPointers[0];
 w := wp^;
 for j := 0 to 14 do
  begin
   Inc(wp);
   w2 := wp^;
   if w2 - w < 3 then exit;
   w := w2;
  end;

 Inc(wp);
 w := wp^;
 for j := 0 to 32 * 3 - 2 do
  begin
   Inc(wp);
   w2 := wp^;
   if w2 - w < 3 then exit;
   w := w2;
  end;

 wp := @F_Frame^.GTR_SamplesPointers[0];

 for j := 0 to 30 do
  begin
   w := wp^ - adr;
   if w >= Readen1 then exit;
   if F_Frame^.Index[w] >= F_Frame^.Index[w + 1] then exit;
   Inc(wp);
  end;

 F_Length := F_Frame^.GTR_OrnamentsPointers[15] + 3 - adr;
 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, adr, F_Length, F_Frame, FT.GTR{GTRFile}) then
       exit;
     GetTimeGTR(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit
    finally
     Dispose(M)
    end
  except
   exit
  end;
 wp := @F_Frame^.GTR_SamplesPointers[0];
 for j := 0 to (15 + 16 + 32 * 3) - 1 do
  begin
   Dec(wp^, adr);
   Inc(wp);
  end;
 F_Frame^.GTR_Address := 0;
 F_Address := adr;
 FoundGTR := True;
end;

function FoundST1(out TimeLength, LoopPoint: integer): boolean;
var
 NPatsU, NPatsE, i, ir, n, c, Note, Octave, Diez, j, NtCnt: integer;
 PatExists, PatUsed: array[0..ST1MaxPatE] of boolean;
 //ограничение вшито в оригинальный редактор, в память может влезть больше, но мы такое детектить не будем
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;

 if Readen1 < 3009 + 576 - 1 then //Readen1 уменьшено на 1
   exit(False);

 if not (F_Frame^.ST1_PatLen in [11..64]) then
   //ограничение вшито в оригинальный редактор, руками можно [1..64]
   exit(False);

 if not (F_Frame^.ST1_Del in [1..15]) then
   //ограничение вшито в оригинальный редактор, руками можно [0..255]
   exit(False);

 for i := 0 to 15 do
   //17-й орнамент избыточен, его не анализируем, так как там явно не орнамент (часто бракуется), может скрытое послание? ;)
   for j := 0 to 31 do
     if (F_Frame^.ST1_Orn[i][j] < -64) or (F_Frame^.ST1_Orn[i][j] > 63) then
       exit(False);

 for i := 1 to 15 do
  begin
   if F_Frame^.ST1_Smp[i].LPos > 32 then
     exit(False);
   if F_Frame^.ST1_Smp[i].LLen > 31 then
     exit(False);
   for j := 0 to 31 do
    begin
     if F_Frame^.ST1_Smp[i].Vl[j] > 15 then
       exit(False);
     if (F_Frame^.ST1_Smp[i].Ns[j] and %00100000) <> 0 then
       exit(False);
     if F_Frame^.ST1_Smp[i].Tn[j] > $1FFF then
       exit(False);
    end;
  end;

 FillChar(PatUsed, (ST1MaxPatE + 1) * SizeOf(boolean), 0);
 FillChar(PatExists, (ST1MaxPatE + 1) * SizeOf(boolean), 0);
 NPatsU := 0;
 NPatsE := 0;
 for i := 0 to 255 do
  begin
   n := F_Frame^.ST1_Pos[i].PNum;
   if n = 0 then
     exit(False);
   Dec(n);
   if n > ST1MaxPatE then
     exit(False);
   if not PatUsed[n] and (i <= F_Frame^.ST1_PosLen) then
    begin
     Inc(NPatsU);
     PatUsed[n] := True;
    end;
   if not PatExists[n] then
    begin
     Inc(NPatsE);
     PatExists[n] := True;
    end;
  end;
 if NPatsU = 0 then
   exit(False);

 //cutoff unused patterns after used patterns (to fix broken modules like ishodnik.zip\SONG2.SCL\LYRA6.S)
 for i := ST1MaxPatE downto 0 do
  begin
   if PatUsed[i] then break;
   if PatExists[i] then
    begin
     PatExists[i] := False;
     Dec(NPatsE);
    end;
  end;

 F_Length := 3009 + 576 * NPatsE;
 if Readen1 < F_Length - 1 then
   exit(False);

 ir := -1;
 NtCnt := 0;
 for i := 0 to ST1MaxPatE do
   if PatExists[i] then
    begin
     Inc(ir);
     //анализируем все паттерны, даже неиспользуемые, чтобы снизить число ложных детектов
     //   if PatUsed[i] then
      begin
       for c := 0 to 2 do
        begin
         j := 0;
         while j < {F_Frame^.ST1_PatLen} 64 do
           //анализируем все 64 строки (включая неиспользуемые), чтобы снизить количество ложных детектов
          begin
            begin
             Note := F_Frame^.ST1_Pat[ir][j][c].Nt shr 4;
             if Note <> 0 then
              begin
               if Note and 8 = 0 then
                begin
                 Octave := F_Frame^.ST1_Pat[ir][j][c].Nt and 7;
                 Diez := Ord((F_Frame^.ST1_Pat[ir][j][c].Nt and 8) <> 0);
                 if (Note in [2, 5]) and (Diez <> 0) then
                   exit(False);
                 Note := st1nts[Note] + Octave * 12 + Diez;
                 if not (Note in [0..$5F]) then
                   exit(False);
                 Inc(NtCnt);
                end;
              end;
            end;
           Inc(j);
          end;
        end;
      end;
    end;

 if NtCnt = 0 then
   exit(False);

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.ST1) then
       exit(False);
     GetTimeSTC(M, TimeLength);
     if TimeLength = 0 then
       exit(False);
    finally
     Dispose(M);
    end;
  except
   exit(False);
  end;

 FoundST1 := True;
end;

function FoundSTC(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2: integer;
 M: PModTypes;
 Id: boolean;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundSTC := False;
 if Readen1 < 6 then exit;

 if F_Frame^.ST_PositionsPointer > Readen1 then exit;

 j1 := integer(F_Frame^.ST_PatternsPointer - F_Frame^.ST_OrnamentsPointer);
 if j1 <= 0 then
   exit;

 j2 := F_Frame^.ST_PositionsPointer - F_Frame^.ST_OrnamentsPointer;
 if j2 = 0 then //j2 < 0 - ST, > 0 - S_SONIC
   exit;
 Id := False;
 if j2 > 0 then
  begin
   if j2 mod $21 <> 0 then
     exit;
  end
 else if (j1 mod $21 <> 0) then
  begin
   if (j1 < 55) or ((j1 - 55) mod $21 <> 0) then
     exit;
   Id := True; //возможно STC со встроенным Id (проверить в конце)
  end;

 j := F_Frame^.Index[F_Frame^.ST_PositionsPointer] * 2 + 3;

 if j2 < 0 then
  begin
   if j + j2 <> 0 then
     exit;
  end
 else if j + F_Frame^.ST_PositionsPointer - F_Frame^.ST_PatternsPointer <> 0 then
  begin
   if (F_Frame^.ST_PatternsPointer < 55 + 27) or
     (j + F_Frame^.ST_PositionsPointer - F_Frame^.ST_PatternsPointer + 55 <> 0) then
     exit;
   Id := True;
  end;

 j := F_Frame^.ST_OrnamentsPointer + $21;
 if j > 65535 then exit;
 if j > Readen1 then exit;
 repeat
   Dec(j);
   if F_Frame^.Index[j] <> 0 then exit;
 until j = F_Frame^.ST_OrnamentsPointer;

 j := F_Frame^.ST_PatternsPointer;
 if j > Readen1 then exit;
 j1 := 0;
 j2 := 0;
 while (j + 6 <= Readen1) and (j + 6 < 65536) and (F_Frame^.Index[j] <> 255) do
  begin
   Inc(j);
   move(F_Frame^.Index[j], j2, 2);
   if j1 < j2 then j1 := j2;
   Inc(j, 2);
   move(F_Frame^.Index[j], j2, 2);
   if j1 < j2 then j1 := j2;
   Inc(j, 2);
   move(F_Frame^.Index[j], j2, 2);
   if j1 < j2 then j1 := j2;
   Inc(j, 2);
  end;
 if F_Frame^.Index[j] <> 255 then exit;
 if j1 > Readen1 then exit;
 if F_Frame^.Index[j1 - 1] <> 255 then exit;

 repeat
   if F_Frame^.Index[j1] in [$83..$8e] then Inc(j1);
   Inc(j1);
 until (j1 > 65535) or (j1 > Readen1) or (F_Frame^.Index[j1] = 255);
 if j1 > 65535 then exit;
 if j1 > Readen1 then exit;
 F_Length := j1 + 1;
 //Frame.ST_Size := F_Length; //Agent-X used it for names

 if Id then
   if not CompareMem(@StcId[1], @F_Frame^.Index[F_Frame^.ST_PatternsPointer - 55],
     Length(StcId)) and not CompareMem(
     @KsaId[1], @F_Frame^.Index[F_Frame^.ST_PatternsPointer - 55], Length(KsaId)) then
     exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.STC) then exit;
     GetTimeSTC(M, TimeLength);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;
 FoundSTC := True;
end;

function FoundST3(out TimeLength, LoopPoint: integer): boolean;
var
 i, j, j1, j2, j3, j4, j5, j6, j7, j8, loadaddr: integer;
 M: PModTypes;
 Id: boolean;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundST3 := False;
 if Readen1 < 8 then exit;

 if F_Frame^.ST_PatternsPointer > Readen1 - 6 then exit;
 //at least 3 pointers at end (for single pattern)

 //first 4 pointers grow
 j1 := integer(F_Frame^.ST3_PatternsPointer - F_Frame^.ST3_OrnamentsPointer);
 if j1 <= 0 then
   exit;

 j2 := F_Frame^.ST3_OrnamentsPointer - F_Frame^.ST3_SamplesPointer;
 if j2 <= 0 then
   exit;

 j3 := F_Frame^.ST3_SamplesPointer - F_Frame^.ST3_PositionsPointer;
 if j3 <= 0 then
   exit;

 j4 := F_Frame^.ST3_PositionsPointer - 9;
 if j4 <= 0 then
   exit;

 Id := False;
 if (j4 mod 130 <> 0) then
  begin
   if (j4 < 55) or ((j4 - 55) mod 130 <> 0) then
     exit;
   Id := True; //возможно ST3 со встроенным Id (проверить в конце)
  end;

 j5 := F_Frame^.Index[F_Frame^.ST3_SamplesPointer]; //number of samples
 if not j5 in [1..16] then
   exit;
 j := j5 * 130 + 9;
 if Id then Inc(j, 55);

 if F_Frame^.ST3_PositionsPointer <> j then
   exit;

 j6 := F_Frame^.Index[j]; //number of positions
 if j6 = 0 then
   exit;
 Inc(j, j6 * 2 + 1);

 if (F_Frame^.ST3_SamplesPointer <> j) and (F_Frame^.ST3_SamplesPointer <> j + 2) then
   //can be 1 unused pos in some modules
   exit;

 j7 := F_Frame^.Index[F_Frame^.ST3_OrnamentsPointer]; //number of orns
 if not j7 in [1..16] then
   exit;

 j := F_Frame^.ST3_SamplesPointer + j5 * 2 + 1 + j7 * 32;
 if F_Frame^.ST3_OrnamentsPointer <> j then
   exit;

 Inc(j, j7 * 2 + 1);
 if PWord(@F_Frame^.Index[F_Frame^.ST3_PatternsPointer])^ <> j then
   exit;

 loadaddr := PWord(@F_Frame^.Index[F_Frame^.ST3_SamplesPointer + 1])^ - 9;
 //sam 0 ptr (can be fixed if init was called)
 if Id then Dec(loadaddr, 55);
 if loadaddr < 0 then
   exit;

 j := PWord(@F_Frame^.Index[F_Frame^.ST3_OrnamentsPointer + 1])^ - loadaddr;
 //orn 0 ptr (can be fixed if init was called)
 if j <> F_Frame^.ST3_SamplesPointer + j5 * 2 + 1 then
   exit;

 //orn 0 must be dummy
 for j := j to j + 31 do
   if F_Frame^.Index[j] <> 0 then exit;

 j8 := -1;
 j := F_Frame^.ST3_PositionsPointer + 2;
 for i := 0 to j6 - 1 do
  begin
   if F_Frame^.Index[j] mod 6 <> 0 then
     exit;
   if j8 < F_Frame^.Index[j] then j8 := F_Frame^.Index[j];
   Inc(j, 2);
  end;

 j := F_Frame^.ST3_PatternsPointer + j8 + 6;
 if j - 1 > Readen1 then
   exit;

 if loadaddr + j > 65536 then
   exit;

 F_Address := loadaddr;
 F_Length := j;

 if Id then
   if not CompareMem(@KsaId[1], @F_Frame^.Index[9], Length(KsaId)) then
     exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.ST3) then exit;
     GetTimeSTC(M, TimeLength);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;
 FoundST3 := True;
end;

function FoundASC1(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1: integer;
 j3: byte;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundASC1 := False;
 if Readen1 < 9 then exit;
 j := F_Frame^.ASC1_PatternsPointers - F_Frame^.ASC1_Number_Of_Positions;
 if (j <> 9) and (j <> 72) then exit;
 if F_Frame^.ASC1_PatternsPointers > Readen1 then exit;
 if F_Frame^.ASC1_SamplesPointers > Readen1 then exit;
 if F_Frame^.ASC1_OrnamentsPointers > Readen1 then exit;

 j := 0;
 move(F_Frame^.Index[F_Frame^.ASC1_SamplesPointers], j, 2);
 if j <> $40 then exit;

 move(F_Frame^.Index[F_Frame^.ASC1_OrnamentsPointers], j, 2);
 if j <> $40 then exit;

 j3 := 0;
 for j1 := 0 to Pred(F_Frame^.ASC1_Number_Of_Positions) do
   if j3 < F_Frame^.ASC1_Positions[j1] then
     j3 := F_Frame^.ASC1_Positions[j1];

 move(F_Frame^.Index[F_Frame^.ASC1_PatternsPointers], j, 2);
 if j <> (j3 + 1) * 6 then exit;

 move(F_Frame^.Index[F_Frame^.ASC1_OrnamentsPointers + $40 - 2], j, 2);
 Inc(j, F_Frame^.ASC1_OrnamentsPointers);
 while (j < Readen1) and (j < 65535) and (F_Frame^.Index[j] and $40 = 0) do
   Inc(j, 2);
 if j > 65534 then exit;
 if j >= Readen1 then exit;

 F_Length := j + 2;
 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.ASC) then exit;
     GetTimeASC(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;
 FoundASC1 := True;
end;

function FoundASC0(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1: integer;
 j3: byte;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundASC0 := False;
 if Readen1 < 8 then exit;
 j := F_Frame^.ASC0_PatternsPointers - F_Frame^.ASC0_Number_Of_Positions;
 if (j <> 8) and (j <> 71) then exit;
 if F_Frame^.ASC0_PatternsPointers > Readen1 then exit;
 if F_Frame^.ASC0_SamplesPointers > Readen1 then exit;
 if F_Frame^.ASC0_OrnamentsPointers > Readen1 then exit;

 j := 0;
 move(F_Frame^.Index[F_Frame^.ASC0_SamplesPointers], j, 2);
 if j <> $40 then exit;

 move(F_Frame^.Index[F_Frame^.ASC0_OrnamentsPointers], j, 2);
 if j <> $40 then exit;

 j3 := 0;
 for j1 := 0 to Pred(F_Frame^.ASC0_Number_Of_Positions) do
   if j3 < F_Frame^.ASC0_Positions[j1] then j3 := F_Frame^.ASC0_Positions[j1];

 move(F_Frame^.Index[F_Frame^.ASC0_PatternsPointers], j, 2);
 if j <> (j3 + 1) * 6 then exit;

 move(F_Frame^.Index[F_Frame^.ASC0_OrnamentsPointers + $40 - 2], j, 2);
 Inc(j, F_Frame^.ASC0_OrnamentsPointers);
 while (j < Readen1) and (j < 65535) and (F_Frame^.Index[j] and $40 = 0) do
   Inc(j, 2);
 if j > 65534 then exit;
 if j >= Readen1 then exit;

 F_Length := j + 2;
 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.ASC0) then exit;
     GetTimeASC(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit
    finally
     Dispose(M);
    end;
  except
   exit;
  end;
 FoundASC0 := True;
end;

function FoundSTF(out TimeLength, LoopPoint: integer; out Title: string): boolean;
var
 M: PModTypes;
 msize, pos1, pos2, posu, i, j: integer;
 b: byte;
 buf2: TSTFUnpacked;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundSTF := False;
 msize := Readen1 + 1;
 if msize < 5 then exit;
 if PWord(F_Frame)^ and $FFF0 = 0 then exit;
 //для ускорения пропуска пустых областей TRD:
 //трех нулей подряд пакер родить не должен
 //так как аналог кодируется короче - всего двумя байтами
 if not STFDepackInit(msize, pos1, pos2) then exit;


 posu := 0;
 for i := 1 to 15 do //сэмплы
   with PModTypes(@buf2)^.STF_Samples[i] do
    begin
     Inc(posu, 32); //распакуем 32 амплитуды
     if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
       (pos2 < 0) then
       exit;
     for j := 0 to 31 do
       if Vl[j] > 15 then //амплитуда 0..15
         exit;
     Inc(posu, 32 + 64 + 2);
     //32 шумы/маски + 32 откл. тона + loop + looplen
     if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
       (pos2 < 0) then
       exit;
     b := LpB;
     if b > 32 then
       exit; //начало цикла не больше 32
     if (b > 0) and (b + LpS > 32) then
       exit; //длина не более 32
     for j := 0 to 31 do
       if Tn[j] and $E000 <> 0 then
         //три старших бита должны быть обнулены
         exit;

    end;

 for i := 0 to 255 do //позиции
   with PModTypes(@buf2)^.STF_Positions[i] do
    begin
     Inc(posu, 2); //паттерн:транспозиция
     if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
       (pos2 < 0) then
       exit;
     if not (Pat in [1..31]) then //номер паттерна
       exit;
    end;

 Inc(posu, 1 + 32);
 //количество активных позиций 0..255 + нулевой орнамент
 if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
   (pos2 < 0) then
   exit;

 with PModTypes(@buf2)^.STF_Ornaments[0] do
  begin
   if LpB <> 0 then //нулевой орнамент зациклен на начало
     exit;
   if not (LpE in [0, 29]) then //встречаются только два вида
     exit;
   for j := 0 to 29 do
     if Vals[j] <> 0 then
       exit;
  end;

 for i := 1 to 15 do //орнаменты
   with PModTypes(@buf2)^.STF_Ornaments[i] do
    begin
     Inc(posu, 32);
     if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
       (pos2 < 0) then
       exit;
     if (LpE > 29) or (LpB > LpE) then
       //допустимая длина и положение цикла
       exit;
     for j := 0 to 29 do
       if (shortint(Vals[j]) < -64) or (Vals[j] > 63) then
         exit;
    end;

 Inc(posu, 33); //такие же непонятные 32 байта как в ST1 + tempo
 if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
   (pos2 < 0) then
   exit;

 if not (PModTypes(@buf2)^.STF_Delay in [3..15]) then
   //ограничение в редакторе
   exit;

 Inc(posu, 32); //длины паттернов + позиция цикла
 if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
   (pos2 < 0) then
   exit;
 for i := 1 to 31 do
   if not (PModTypes(@buf2)^.STF_PatLens[i] in [5..64]) then
     //нижнее - ограничение в редакторе
     exit;

 with PModTypes(@buf2)^ do
   if STF_LoopPos > STF_PosLen then
     //цикл должен быть внутри активных позиций
     exit;

 Inc(posu, 25); //название
 if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize, posu) or
   (pos2 < 0) then
   exit;
 for i := 1 to 25 do
   if not (PModTypes(@buf2)^.STF_Title[i] in STF_AllowedChars) then
     exit;

 //todo если будет много брака, можно еще сделать разбор паттернов

 //распакуем до конца
 if not STFDepackBytes(PSTFPacked(F_Frame)^, buf2, pos1, pos2, msize) or (pos2 >= 0) then
   exit;

 Title := PModTypes(@buf2)^.STF_Title;

 F_Length := pos1;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.STF) then exit;
     GetTimeSTP(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   Exit;
  end;
 FoundSTF := True;
end;

function FoundSTP(out TimeLength, LoopPoint: integer): boolean;
var
 j,{j1,}j2, j3: integer;
 KsaId2: string;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 Result := False;
 if Readen1 < 10 then exit;
 if F_Frame^.STP_PositionsPointer > Readen1 then exit;
 if F_Frame^.STP_PatternsPointer > Readen1 then exit;
 if F_Frame^.STP_OrnamentsPointer > Readen1 then exit;
 if F_Frame^.STP_SamplesPointer > Readen1 then exit;
 if F_Frame^.STP_SamplesPointer - F_Frame^.STP_OrnamentsPointer <> $20 then exit;
 if integer(F_Frame^.STP_OrnamentsPointer - F_Frame^.STP_PatternsPointer) <= 0 then
   exit;
 if (F_Frame^.STP_OrnamentsPointer - F_Frame^.STP_PatternsPointer) mod 6 <> 0 then
   exit;
 if integer(F_Frame^.Index[F_Frame^.STP_PositionsPointer]) * 2 + 2 +
   F_Frame^.STP_PositionsPointer - F_Frame^.STP_PatternsPointer <> 0 then exit;
 F_Length := F_Frame^.STP_SamplesPointer + 30;
 if F_Length > 65535 then exit;
 if F_Length > Readen1 + 1 then exit;

 j2 := 0;
 j3 := F_Frame^.STP_Init_Id;
 if j3 = 0 then
  begin
   j2 := PWord(@F_Frame^.Index[F_Frame^.STP_PatternsPointer])^;
   SetLength(KsaId2, 28);
   move(F_Frame^.Index[10], KsaId2[1], 28);
   if KsaId2 = KsaId then Dec(j2, $a + 53)
   else
     Dec(j2, $a);
   if j2 < 0 then exit;
   j3 := (F_Length - F_Frame^.STP_PatternsPointer) div 2;
  end;

 F_Address := j2;

 j := PWord(@F_Frame^.Index[F_Frame^.STP_OrnamentsPointer])^ - 1 - j2;
 if longword(j) <= longword(Readen1 - 1) then
  begin
   if PWord(@F_Frame^.Index[j])^ = 0 then
    begin
     if IntegrityCheck then
      try
       New(M);
        try
         if not LoadTrackerModule(M^, nil, -1, j2, F_Length, F_Frame, FT.STP) then exit;
         GetTimeSTP(M, TimeLength, LoopPoint);
         if TimeLength = 0 then exit;
        finally
         Dispose(M);
        end
      except
       exit;
      end;
{    if F_Frame^.STP_Init_Id = 0 then
     begin
      F_Frame^.STP_Init_Id := j3;
      for j1 := 0 to j3-1 do
       Dec(PWord(@F_Frame^.Index[F_Frame^.STP_PatternsPointer + j1 * 2])^,j2);
     end;}
     Result := True;
    end;
  end;

end;

type
 TFMask = record
   MinSz, Offs: integer;
   Mask: WideString;
 end;

const
 //0..255 - match byte, >255 - (skip bytes)+255
 STPMask: TFMask =
   (MinSz: $46; Offs: 0; Mask: #$21#257#$C3#257#$C3#257#$ED#258#$C3#258 +
   KsaId + widechar(255 + 25));
 ASCMask1: TFMask =
   (MinSz: 86; Offs: 14; Mask: #$C3#257#$C3#257 + AscId + widechar(255 + 20) +
   ' BY ' + widechar(255 + 20) + #$CD#$52#0);
 ASCMask2: TFMask =
   (MinSz: 96; Offs: 11; Mask: #$C3#257#$C3#257#$C3#257 + AscId +
   widechar(255 + 20) + ' BY ' + widechar(255 + 20) +
   #$AF#$21#257#$11#257#$01#257#$77#$ED#$B0);
 ASCMask3: TFMask =
   (MinSz: 85; Offs: 0; Mask: #$CD#257#$C3#257#$C3#257 + AscId +
   widechar(255 + 20) + ' BY ' + widechar(255 + 20) +
   #$AF#$21#257#$11#257#$01#257#$77#$ED#$B0);
 ASCMask4: TFMask =
   (MinSz: 94; Offs: 20; Mask: AscId + widechar(255 + 20) + ' BY ' +
   widechar(255 + 20) + #$CD#$52#0#$3B#$3B#$D1#$21#$8D#4#$19#$E9#$AF);
 STCMask: TFMask =
   (MinSz: 75; Offs: 0; Mask: #$B#0#$E#0#$7E#$80#$81#$80#$80#$10#$1F +
   #$18#$4C#0#$18#$4F#0#$18#$39#0 + StcId + widechar(255 + 10) +
   ' BY ' + widechar(255 + 12));
 ST3Mask: TFMask =
   (MinSz: $46; Offs: 0; Mask: #$21#257#$C3#257#$C3#257#$C3#257 +
   KsaId + widechar(255 + 27) + #$F3#$7E#$32);
 PlLens_STP: array[0..1] of integer = (1896, 1909);
 PlLens_ASC: array[0..5] of integer = (1559, 1529, 1649, 1191, 1228, 1518);
 PlLens_STC: array[0..0] of integer = ($4A8);
 PlLens_ST3: array[0..0] of integer = (1690);

function MatchMask(const aMask: TFMask; pBuf: pbyte; BufSz: integer): boolean;
var
 i, o: integer;
begin
 if aMask.MinSz > BufSz then
   exit(False);
 o := aMask.Offs;
 for i := 1 to Length(aMask.Mask) do
  begin
   if Ord(aMask.Mask[i]) > 255 then
     Inc(o, Ord(aMask.Mask[i]) - 255)
   else
    begin
     if Ord(aMask.Mask[i]) <> pBuf[o] then
       exit(False);
     Inc(o);
    end;
  end;
 Result := True;
end;

function MatchPlayerLength(PlType: TF_TagTypes; PlLen: integer): boolean;
var
 i: integer;
begin
 case PlType of
   F_Tag_ASC:
     for i := 0 to Length(PlLens_ASC) - 1 do
       if PlLens_ASC[i] = PlLen then
         exit(True);
   F_Tag_STP:
     for i := 0 to Length(PlLens_STP) - 1 do
       if PlLens_STP[i] = PlLen then
         exit(True);
   F_Tag_STC:
     for i := 0 to Length(PlLens_STC) - 1 do
       if PlLens_STC[i] = PlLen then
         exit(True);
   F_Tag_ST3:
     for i := 0 to Length(PlLens_ST3) - 1 do
       if PlLens_ST3[i] = PlLen then
         exit(True);
  end;
 Result := False;
end;

function FoundSTP_PlayerTags(var offs: integer): boolean;
var
 Tag: string;
begin
 offs := 17;
 Result := MatchMask(STPMask, pointer(F_Frame), Readen1);
 if Result then
  begin
   SetLength(Tag, 25);
   Move(F_Frame^.Index[offs + Length(KsaId)], Tag[1], 25);
   Tag := CPToUTF8(Trim(Tag));
   Result := Tag <> '';
  end;
end;

function FoundASC_PlayerTags(var offs: integer): boolean;
var
 Tag1, Tag2: string;
begin
 offs := $14;
 Result := MatchMask(ASCMask1, pointer(F_Frame), Readen1) or
   MatchMask(ASCMask2, pointer(F_Frame), Readen1) or
   MatchMask(ASCMask4, pointer(F_Frame), Readen1);
 if not Result then
  begin
   offs := 9;
   Result := MatchMask(ASCMask3, pointer(F_Frame), Readen1);
  end;
 if Result then
  begin
   //19+20+4+20
   SetLength(Tag1, 20);
   Move(F_Frame^.Index[offs + Length(AscId)], Tag1[1], 20);
   Tag1 := CPToUTF8(Trim(Tag1));
   SetLength(Tag2, 20);
   Move(F_Frame^.Index[offs + Length(AscId) + 20 + 4], Tag2[1], 20);
   Tag2 := CPToUTF8(Trim(Tag2));
   Result := (Tag1 <> '') or (Tag2 <> '');
  end;
end;

function FoundSTC_PlayerTags(var offs: integer): boolean;
var
 Tag1, Tag2: string;
begin
 offs := 20;
 Result := MatchMask(STCMask, pointer(F_Frame), Readen1);
 if Result then
  begin
   //20+29+10+4+12
   SetLength(Tag1, 10);
   Move(F_Frame^.Index[offs + Length(StcId)], Tag1[1], 10);
   Tag1 := CPToUTF8(Trim(Tag1));
   SetLength(Tag2, 12);
   Move(F_Frame^.Index[offs + Length(StcId) + 10 + 4], Tag2[1], 12);
   Tag2 := CPToUTF8(Trim(Tag2));
   Result := (Tag1 <> '') or (Tag2 <> '');
  end;
end;

function FoundST3_PlayerTags(var offs: integer): boolean;
var
 Tag: string;
begin
 offs := 12;
 Result := MatchMask(ST3Mask, pointer(F_Frame), Readen1);
 if Result then
  begin
   //12+28+27
   SetLength(Tag, 27);
   Move(F_Frame^.Index[offs + Length(KsaId)], Tag[1], 27);
   Tag := CPToUTF8(Trim(Tag));
   Result := Tag <> '';
  end;
end;

function FoundPT2(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2, j3, j4: integer;
 M: PModTypes;
begin
 //todo заменить сравнение с Readen1 на сравнение с Min(65535,Readen1);
 TimeLength := 0;
 LoopPoint := 0;
 FoundPT2 := False;
 if Readen1 < 132 then exit;
 if F_Frame^.PT2_PatternsPointer = 0 then exit;
 //if F_Frame^.PT2_PatternsPointer > Readen1 then exit; //нужно же 2 байта >=
 if F_Frame^.PT2_PatternsPointer >= Readen1 then exit;
 if F_Frame^.Index[F_Frame^.PT2_PatternsPointer - 1] <> 255 then exit;
 j3 := F_Frame^.PT2_SamplesPointers[0];
 //if F_Frame^.PT2_OrnamentsPointers[0] - j3 - 2 > Readen1 then exit; //почему минус 2, наоборот же?
 if F_Frame^.PT2_OrnamentsPointers[0] - j3 + 2 > Readen1 then exit;
 if F_Frame^.PT2_OrnamentsPointers[0] - j3 < 0 then exit;

 j := 0;
 move(F_Frame^.Index[F_Frame^.PT2_OrnamentsPointers[0] - j3], j, 3);
 if j <> 1 then exit;

 j := PWord(@F_Frame^.Index[F_Frame^.PT2_PatternsPointer])^ - j3;
 if (j < 0) or (j > Readen1) then exit;
 Dec(j, F_Frame^.PT2_PatternsPointer);
 if (j <= 0) or (j mod 6 <> 2) then exit;

 j1 := 0;
 j2 := 0;
 while (j2 < 256) and (j2 <= Readen1 - 131) and (F_Frame^.PT2_PositionList[j2] < 128) do
  begin
   if longword(j1) < F_Frame^.PT2_PositionList[j2] then
     j1 := F_Frame^.PT2_PositionList[j2];
   Inc(j2);
  end;
 if j div 6 <> j1 + 1 then exit;

 j := 15;
 while (j > 0) and (F_Frame^.PT2_OrnamentsPointers[j] = j3) do Dec(j);
 j4 := F_Frame^.PT2_OrnamentsPointers[j] - j3;
 //if (j4 < 0) or ((j4 - 2) > Readen1) then exit; //почему -2? наоборот же
 if (j4 < 0) or ((j4 + 2) > Readen1) then exit;
 F_Length := j4 + F_Frame^.Index[j4] + 2;
 if F_Length > 65536 then exit; //этой проверки не было, приводило к сбою ниже в LoadTrackerModule
 if F_Length > Readen1 + 1 then exit;

 for j := 0 to 31 do
  begin
   j4 := F_Frame^.PT2_SamplesPointers[j] - j3;
   //if (j4 < 0) or ((j4 - 2) > Readen1) then exit; //почему -2? наоборот же
   if (j4 < 0) or ((j4 + 2) > Readen1) then exit;
  end;
 for j := 0 to 15 do
  begin
   j4 := F_Frame^.PT2_OrnamentsPointers[j] - j3;
   //if (j4 < 0) or ((j4 - 2) > Readen1) then exit; //почему -2? наоборот же
   if (j4 < 0) or ((j4 + 2) > Readen1) then exit;
  end;
 for j := 0 to j1 * 3 + 2 do
  begin
   j4 := F_Frame^.PT2_PatternsPointer + j * 2;
   //if j4 > Readen1 then exit; //нужно же 2 байта, >=
   if j4 >= Readen1 then exit;
   j4 := PWord(@F_Frame^.Index[j4])^ - j3;
   if (j4 < 0) or (j4 > Readen1) then exit;
  end;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, j3, F_Length, F_Frame, FT.PT2) then exit;
     GetTimePT2(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit
    finally
     Dispose(M)
    end
  except
   exit
  end;

 F_Frame^.PT2_NumberOfPositions := j2;

 if j3 <> 0 then
  begin
   F_Address := j3;
   for j := 0 to 31 do Dec(F_Frame^.PT2_SamplesPointers[j], j3);
   for j := 0 to 15 do Dec(F_Frame^.PT2_OrnamentsPointers[j], j3);
   for j := 0 to j1 * 3 + 2 do
     Dec(PWord(@F_Frame^.Index[F_Frame^.PT2_PatternsPointer + j * 2])^, j3);
  end;
 FoundPT2 := True;
end;

function FoundPT3(DetectAdr: boolean; out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2, j4, j5, j6, adr: integer;
 pw: PWord;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundPT3 := False;
 if Readen1 < 202 then exit;
 if DetectAdr then
  //if ptrs linked to loading address via ptutil, we can detect it easy:
  adr := F_Frame^.PT3_SamplesPointers[0]
 else
  //PT 3.1 has empty sample 0 (unused, but non zero ptr)
  adr := 0;
 j4 := F_Frame^.PT3_PatternsPointer - adr;
 if (j4 < 202) or (j4 > Readen1) then exit;
 if F_Frame^.Index[j4 - 1] <> 255 then exit;
 j := F_Frame^.PT3_OrnamentsPointers[0] - adr;
 if (j < 202) or (j + 2 > Readen1) then exit;

 move(F_Frame^.Index[j], j, 3);
 if j <> 256 then exit;

 j5 := 0;
 j1 := 0;
 while j5 < 256 do
  begin
   if j5 + 201 > Readen1 then exit;
   j2 := F_Frame^.PT3_PositionList[j5];
   if j2 = 255 then break;
   if j2 mod 3 <> 0 then exit;
   if j1 < j2 then j1 := j2;
   Inc(j5);
  end;

 pw := @F_Frame^.Index[j4];
 j := 65535;
 for j2 := 0 to j1 + 2 do
  begin
   if j4 + j2 * 2 >= Readen1 then exit;
   j6 := pw^ - adr;
   if (j6 < 202) or (j6 > Readen1) then exit;
   if j > j6 then j := j6;
   Inc(pw);
  end;

 Dec(j, j4);
 if j <= 0 then exit;
 if j mod 6 <> 0 then exit;
 if j div 6 <> j1 div 3 + 1 then exit;

 j := 15;
 while (j > 0) and (F_Frame^.PT3_OrnamentsPointers[j] = adr) do Dec(j);
 j := F_Frame^.PT3_OrnamentsPointers[j] - adr;
 if (j < 202) or (j + 2 > Readen1) then exit;

 F_Length := j + F_Frame^.Index[j + 1] + 2;
 if F_Length > Readen1 + 1 then exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, adr, F_Length, F_Frame, FT.PT3) then exit;
     GetTimePT3(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;

 F_Frame^.PT3_NumberOfPositions := j5;
 F_Address := adr;
 F_Frame^.PT3_PatternsPointer := j4;
 for j := 0 to 31 do Dec(F_Frame^.PT3_SamplesPointers[j], adr);
 for j := 0 to 15 do Dec(F_Frame^.PT3_OrnamentsPointers[j], adr);
 pw := @F_Frame^.Index[j4];
 for j := 0 to j1 + 2 do
  begin
   Dec(pw^, adr);
   Inc(pw);
  end;
 FoundPT3 := True;
end;

function FoundPSC(PSC1_00: boolean; out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2, SamBase, OrnFirst: integer;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundPSC := False;
 if Readen1 < $4c + 2 then exit;
 if F_Frame^.PSC_OrnamentsPointer >= Readen1 then exit;
 if F_Frame^.PSC_OrnamentsPointer < $4c + 2 then exit;
 if F_Frame^.PSC_OrnamentsPointer > 64 + $4c then exit;
 if F_Frame^.PSC_OrnamentsPointer mod 2 <> 0 then exit;
 if PSC1_00 then
  SamBase := 0
 else
  SamBase := $4c;
 j := SamBase + F_Frame^.PSC_SamplesPointers[0];

 //нужно более жесткое условие, т.к. бывают ложные срабатывания
 // if j > 65534 - 5 then exit;

 //сэмплы сразу после смещений орнаментов, а их не более 32
 if j > F_Frame^.PSC_OrnamentsPointer + 64 then exit;

 if j + 5 > Readen1 then exit;

 OrnFirst := PWord(@F_Frame^.Index[F_Frame^.PSC_OrnamentsPointer])^;
 if not PSC1_00 then Inc(OrnFirst, F_Frame^.PSC_OrnamentsPointer);
 if OrnFirst > 65535 then exit;
 if OrnFirst >= Readen1 then exit;

 //последний сэмпл
 j2 := PWord(@F_Frame^.Index[F_Frame^.PSC_OrnamentsPointer - 2])^ + SamBase;
 if j2 > 65534 - 5 then exit;
 if j2 + 5 > Readen1 then exit;
 if OrnFirst - j2 < 8 then exit;
 if (OrnFirst - j2) mod 6 <> 2 then exit;

 j1 := F_Frame^.PSC_SamplesPointers[0] + SamBase + 4;
 while (j1 < 65536) and (j1 <= readen1) and (F_Frame^.Index[j1] and 32 <> 0) do
   Inc(j1, 6);
 if j1 > 65534 then exit;
 if j1 > readen1 then exit;

 if F_Frame^.PSC_OrnamentsPointer - $4c - 2 > 0 then
  begin
   if j1 + 3 <> F_Frame^.PSC_SamplesPointers[1] + SamBase then exit;
  end
 else if j1 + 4 <> OrnFirst then exit;

 j := F_Frame^.PSC_PatternsPointer + 11;
 if (j > 65535) or (j > Readen1) then exit;

 Dec(j, 10);
 if F_Frame^.Index[j] = 255 then exit;

 j1 := 0;
 repeat
   j2 := PWord(@F_Frame^.Index[j + 1])^; //данные канала A

   //примерная, но быстрая проверка допустимого диапазона
   if j2 <= OrnFirst then
    Exit;
   if j2 >= F_Frame^.PSC_PatternsPointer then
    Exit;

   j2 := PWord(@F_Frame^.Index[j + 3])^; //данные канала B

   if j2 <= OrnFirst then
    Exit;
   if j2 >= F_Frame^.PSC_PatternsPointer then
    Exit;

   j2 := PWord(@F_Frame^.Index[j + 5])^; //данные канала C

   if j2 <= OrnFirst then
    Exit;
   if j2 >= F_Frame^.PSC_PatternsPointer then
    Exit;

   Inc(j, 8);
   Inc(j1);
   if F_Frame^.Index[j] = 255 then
    begin
     if F_Frame^.Index[j-1] >= j1 then
      //цикл на несуществующую позицию
      Exit;
     Break;
    end;
   if (j > 65532) or (j + 2 > Readen1) then
    Exit;
 until False;

 F_Length := j + 3;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.PSC) then exit;
     GetTimePSC(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end
  except
   exit;
  end;

 if PSC1_00 then
  begin
   if not (F_Frame^.PSC_MusicName[8] in ['0'..'3']) then
     F_Frame^.PSC_MusicName[8] := '0';
  end
 else if F_Frame^.PSC_MusicName[8] in ['0'..'3'] then
   F_Frame^.PSC_MusicName[8] := '7';

 FoundPSC := True;
end;

function FoundFTC(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2, j3, maxpat, address: integer;
 jj: ^word;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundFTC := False;
 if Readen1 < $d4 + 3 then exit;
 if F_Frame^.FTC_PatternsPointer >= Readen1 then exit;
 if F_Frame^.FTC_OrnamentsPointers[0] <= F_Frame^.FTC_SamplesPointers[0] then exit;

 j1 := $d4;
 maxpat := 0;
 while (j1 <= readen1) and (j1 < $1d4) and (F_Frame^.Index[j1] < 128) do
  begin
   if maxpat < F_Frame^.Index[j1] then
     maxpat := F_Frame^.Index[j1];
   Inc(j1, 2);
  end;
 if j1 >= $1d4 then exit;
 if j1 > readen1 then exit;
 if F_Frame^.FTC_PatternsPointer <= j1 then exit;
 if F_Frame^.FTC_Loop_Position >= (j1 - $d4) div 2 then exit;

 address := 0;
 move(F_Frame^.Index[F_Frame^.FTC_PatternsPointer], address, 2);
 Dec(address, (maxpat + 1) * 6 + F_Frame^.FTC_PatternsPointer + 2);
 if address < 0 then exit;
 if F_Frame^.FTC_SamplesPointers[0] - address >= Readen1 then exit;
 if F_Frame^.FTC_PatternsPointer >= F_Frame^.FTC_SamplesPointers[0] - address then
   exit;
 if F_Frame^.FTC_OrnamentsPointers[0] - address >= Readen1 then exit;

 j1 := 0;
 j := 65535;
 for j2 := 0 to 32 do
  begin
   if j > F_Frame^.FTC_OrnamentsPointers[j2] then
     j := F_Frame^.FTC_OrnamentsPointers[j2];
   if j1 < F_Frame^.FTC_OrnamentsPointers[j2] then
     j1 := F_Frame^.FTC_OrnamentsPointers[j2];
  end;
 if j - address > 65535 then exit;
 if j - address >= Readen1 then exit;
 if j1 - address > 65533 then exit;
 if j1 - address >= Readen1 then exit;

 j3 := 0;
 for j2 := 0 to 31 do
  begin
   if j3 < F_Frame^.FTC_SamplesPointers[j2] then
     j3 := F_Frame^.FTC_SamplesPointers[j2];
  end;
 if j3 - address <= F_Frame^.FTC_PatternsPointer then exit;
 if j3 - address > 65533 then exit;
 if j3 - address >= Readen1 then exit;
 if j3 + 3 + (F_Frame^.Index[j3 - address + 2] + 1) * 5 <> j then exit;
 F_Length := j1 + 3 + (F_Frame^.Index[j1 - address + 2] + 1) * 2 - address;
 if F_Length > 65536 then exit;
 if F_Length > Readen1 + 1 then exit;
 if F_Length < F_Frame^.FTC_PatternsPointer then exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, address, F_Length, F_Frame, FT.FTC) then exit;
     GetTimeFTC(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit
    finally
     Dispose(M)
    end
  except
   exit
  end;

 F_Address := address;
 for j2 := 0 to 32 do Dec(F_Frame^.FTC_OrnamentsPointers[j2], address);
 for j2 := 0 to 31 do Dec(F_Frame^.FTC_SamplesPointers[j2], address);

 jj := @F_Frame^.Index[F_Frame^.FTC_PatternsPointer];
 for j2 := 1 to (maxpat + 1) * 3 do
  begin
   Dec(jj^, address);
   Inc(jj);
  end;

 FoundFTC := True;
end;

function FoundSQT(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2, j3: integer;
 pwrd: ^word;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundSQT := False;
 if Readen1 < 17 then exit;
 if F_Frame^.SQT_SamplesPointer < 10 then exit;
 if F_Frame^.SQT_OrnamentsPointer <= F_Frame^.SQT_SamplesPointer + 1 then exit;
 if F_Frame^.SQT_PatternsPointer < F_Frame^.SQT_OrnamentsPointer then exit;
 if F_Frame^.SQT_PositionsPointer <= F_Frame^.SQT_PatternsPointer then exit;
 if F_Frame^.SQT_LoopPointer < F_Frame^.SQT_PositionsPointer then exit;

 j := F_Frame^.SQT_SamplesPointer - 10;

 //позиция цикла д.б. не дальше последней позиции (6 нулей в конце +
 //7 байт сама позиция, Readen1 уменьшен на 1)
 if F_Frame^.SQT_LoopPointer - j > Readen1 - 12 then exit;

 j1 := F_Frame^.SQT_PositionsPointer - j;
 if F_Frame^.Index[j1] = 0 then exit;
 j2 := 0;
 repeat
   if j1 + 11 >= Readen1 then exit; //7 байт позиция + 6 нулей
   if j2 < F_Frame^.Index[j1] and $7f then
     j2 := F_Frame^.Index[j1] and $7f;
   Inc(j1, 2);
   if j2 < F_Frame^.Index[j1] and $7f then
     j2 := F_Frame^.Index[j1] and $7f;
   Inc(j1, 2);
   if j2 < F_Frame^.Index[j1] and $7f then
     j2 := F_Frame^.Index[j1] and $7f;
   Inc(j1, 3);
 until F_Frame^.Index[j1] = 0;

 pwrd := @F_Frame^.Index[F_Frame^.SQT_SamplesPointer - j + 2];
 if pwrd^ - F_Frame^.SQT_PatternsPointer - 2 <> j2 * 2 then exit;

 F_Length := j1 + 7;
 pwrd := @F_Frame^.Index[12];
 j2 := pwrd^;
 for j1 := 1 to (F_Frame^.SQT_OrnamentsPointer -
     F_Frame^.SQT_SamplesPointer) div 2 do
  begin
   Inc(pwrd);
   j3 := pwrd^;
   if j3 - j2 <> $62 then exit;
   j2 := j3;
  end;

 for j1 := 1 to (F_Frame^.SQT_PatternsPointer -
     F_Frame^.SQT_OrnamentsPointer) div 2 do
  begin
   Inc(pwrd);
   j3 := pwrd^;
   if j3 - j2 <> $22 then exit;
   j2 := j3;
  end;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.SQT) then exit;
     GetTimeSQT(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;

 F_Frame^.SQT_Size := F_Length;
 FoundSQT := True;
end;

function FoundPT1(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2: integer;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundPT1 := False;
 if Readen1 < $66 then exit;
 if F_Frame^.PT1_PatternsPointer >= Readen1 then exit;

 j := 0;
 j1 := 65535;
 for j2 := 0 to 15 do
  begin
   if j < F_Frame^.PT1_SamplesPointers[j2] then
     j := F_Frame^.PT1_SamplesPointers[j2];
   if (F_Frame^.PT1_OrnamentsPointers[j2] <> 0) and
     (j1 > F_Frame^.PT1_OrnamentsPointers[j2]) then
     j1 := F_Frame^.PT1_OrnamentsPointers[j2];
  end;
 if j1 < $67 then exit;
 if j < $67 then exit;
 if j > 65534 then exit;
 if j > Readen1 then exit;
 if j + F_Frame^.Index[j] * 3 + 2 <> j1 then exit;

 j := 0;
 for j2 := 0 to 15 do
   //todo настоящий PT1 проще вроде, адреса возрастают (если не ноль)
   if j < F_Frame^.PT1_OrnamentsPointers[j2] then
     j := F_Frame^.PT1_OrnamentsPointers[j2];
 if j < $67 then exit;

 //todo ошибка - необязательно все 64 тика орнамента в файле, нужно смотреть в сочетании с сэмплами!
 F_Length := j + 64;
 if F_Length > Readen1 + 1 then
  begin
   //todo временно подрезаем последний орнамент
   F_Length := Readen1 + 1;
   if F_Length <= j then
     Exit;
  end;
 if F_Length > 65536 then
   Exit;

 j := $63;
 while (j <= F_Frame^.PT1_PatternsPointer) and (F_Frame^.Index[j] <> 255) do
   Inc(j);
 if j + 1 <> F_Frame^.PT1_PatternsPointer then
   Exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, 0, F_Length, F_Frame, FT.PT1) then exit;
     GetTimePT1(M, TimeLength, LoopPoint);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;

 F_Frame^.PT1_NumberOfPositions := j - $63;
 FoundPT1 := True;
end;

function FoundFLS(out TimeLength, LoopPoint: integer): boolean;
var
 NSams, NOrns, NPoss, PLsA, PatA, SamA, CurO, CurA, MaxO, MaxD, Dif, i, j: integer;
 M: PModTypes;

 function ValidSamOffset:boolean; inline;
 begin
 Result := (CurO >= 12 + NOrns*2) and //хотя бы 1 паттерн и все орнаменты
           ((CurO - NOrns*2) mod 6 = 0); //по три указателя на паттерн
 end;

 function ValidSamParams(Ofs: integer): boolean;
 var
   Lp, LpLen: integer;
 begin
   Result := False;

   Lp := F_Frame^.Index[Ofs];

   //0 - нет цикла, 1..32 - точка цикла
   if not (Lp in [0..32]) then
     Exit;

   LpLen := F_Frame^.Index[Ofs + 1];

   if Lp = 0 then
    begin
     //для незацикленных LpLen не используется, но в имеющихся FLS
     //значение не совсем случайно
     if not LpLen in [1..32] then
       Exit;
    end
   else
   //зациклен, проверим тело цикла
   if not (LpLen in [1..33 - Lp]) then
     //здесь отбраковывается Iris UD - Setup.fls - есть сэмпл 1A 08
     //(то есть 26-1+8=33 - играет один тик за пределами сэмпла)
     Exit;
   Result := True;
 end;

begin
 TimeLength := 0;
 LoopPoint := 0;
 Result := False;

 if Readen1 < 2 + 2 + 2 +//3 первых указателя
   6 + 2 +//как минимум указатели на 1 паттерн и 1 сэмпл
   1 + 1 +//как минимум 1 позиция и маркер конца списка позиций
   32 + 2 +//тело как минимум 1 сэмпла + параметры его цикла
   3 //как минимум 1 пустой паттерн
   - 1 //Readen1 уменьшено на 1
 then Exit;

 //орнаментов гипотетически может не быть, но среди известных FLS такого не встречается
 //предположим, что у гипотетического FLS без орнаментов FLS_OrnamentsPointer = FLS_SamplesPointer
 NOrns := F_Frame^.FLS_SamplesPointer - F_Frame^.FLS_OrnamentsPointer;
 if (NOrns < 0) or (NOrns > 15 * 2) or (NOrns and 1 <> 0) then
   Exit;

 NOrns := NOrns div 2;

 //от FLS_SamplesPointer до FLS_PositionsPointer идёт по 4 байта на сэмпл
 //сэмплов от 1 до 16;
 PLsA := F_Frame^.FLS_PositionsPointer;
 NSams := PLsA - F_Frame^.FLS_SamplesPointer;
 if (NSams <= 0) or (NSams > 16 * 4) or (NSams and 3 <> 0) then
   Exit;

 NSams := NSams div 4;

 //первый указатель на паттерн должен указывать дальше списка позиций (минимум 2 байта)
 PatA := F_Frame^.FLS_PatternsPointers[1].PatternA;
 NPoss := PatA - PLsA - 1;
 if (NPoss <= 0) or (NPoss > 256) then
   //максимум ограничен в редакторе ST
   Exit;

 if Readen1 < 2 + 2 + 2 +//3 первых указателя
   6 +//как минимум указатели на 1 паттерн
   NPoss + 1 +//позиции и маркер конца списка позиций
   //параметры цикла, указатели, тела сэмплов
   (2 + 2 + 32) * NSams +
   (2 + 32) * NOrns +//указатели, тела орнаментов
   3 //как минимум 1 пустой паттерн
   - 1 //Readen1 уменьшено на 1
 then Exit;

 CurO := 6;
 MaxO := 6 + NOrns * 2 + NSams * 4; //чётное число

 //разница между указателями не должна превышать размера модуля за вычетом
 //самого размера области с указателями (число паттернов пока не известно)
 MaxD := Readen1 + 1 - MaxO;

 //больше максимально допустимого редактором ST числа не лезем
 Inc(MaxO, FLSMaxPatE * 6);

 //хотя бы 1 пустой паттерн и список позиций с маркером 0
 if MaxO > Readen1 + 1 - NPoss - 1 - 3 then
  begin
   MaxO := (Readen1 + 1 - NPoss - 1 - 3);
   if MaxO and 1 <> 0 then
     Dec(MaxO); //чётное
  end;

 //проверяем корректность указателей паттернов, орнаментов и сэмплов
 //по возможности останавливаемся на сэмплах
 while CurO < MaxO do
  begin
   CurA := PWord(@F_Frame^.Index[CurO])^;
   Dif := CurA - PLsA;
   if (Dif <= 0) or (Dif > MaxD) then
     //возможно наткнулись на первый не указатель (SamLoop/LoopLen)
     Break;

   //если FLS сохранён из плейлиста Ay_Emul, он отвязывается от адреса,
   //поэтому нужно убедиться, что это не первый сэмпл
   if ValidSamOffset and (CurO + 6 < MaxO) and ValidSamParams(CurO) then
    begin
     SamA := PWord(@F_Frame^.Index[CurO + 2])^;
     //расстояние до предыдущего орнамента должно быть 32
     if ((NOrns = 0) or (SamA - integer(PWord(@F_Frame^.Index[CurO - 2])^) =
       32)) and
       //а до следующего сэмпла или списка позиций - 32*3
       (((NSams = 1) and (PLsA - SamA = 32 * 3)) or
       ((NSams > 1) and ValidSamParams(CurO + 4) and
       (integer(PWord(@F_Frame^.Index[CurO + 6])^) - SamA = 32 * 3))) then
       Break;
    end;

   //в нормальном FLS первый указатель на паттерн должен быть минимальным
   if CurA < PatA then
     Exit;

   Inc(CurO, 2);
  end;

 //какой-то из паттернов не валидный?
 if not ValidSamOffset then
   Exit;

 //уточняем MaxO, MaxD
 MaxO := CurO + NSams * 4;
 if MaxO > Readen1 + 1 - NPoss - 1 - 3 then
   Exit;
 MaxD := Readen1 + 1 - MaxO;

 for i := 0 to NSams - 1 do
  begin
   if not ValidSamParams(CurO) then
     Exit;

   CurA := PWord(@F_Frame^.Index[CurO + 2])^;
   Dif := CurA - PLsA;
   //для указателя на сэмпл те же критерии валидности
   if (Dif <= 0) or (Dif > MaxD) then
     Exit;

   Inc(CurO, 4);
  end;

 for i := 0 to NPoss - 1 do
  begin
   if not (F_Frame^.Index[CurO] in [1..31]) then
     Exit;
   Inc(CurO);
  end;

 if F_Frame^.Index[CurO] <> 0 then
   //end of pos list marker
   Exit;

 j := PatA - CurO - 1;

 //Ornaments должны быть по чётному адресу
 if (F_Frame^.FLS_OrnamentsPointer - j) and 1 <> 0 then
   Exit;

 //Samples должны быть по чётному адресу
 if (F_Frame^.FLS_SamplesPointer - j) and 1 <> 0 then
   Exit;

 Dec(PLsA, j);
 //Positions List должен быть по чётному адресу
 if PLsA and 1 <> 0 then
   Exit;

 F_Length := 0;
 F_Length := PWord(@F_Frame^.Index[PLsA - 2])^ + $60 - j;
 if F_Length <= PLsA then
   Exit;
 if F_Length > Readen1 + 1 then
   Exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, j, F_Length, F_Frame, FT.FLS) then exit;
     GetTimeFLS(M, TimeLength);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   Exit;
  end;

 F_Address := j;

 Result := True;
end;

//предыдущий медленный и менее надёжный вариант
(*function FoundFLS(out TimeLength, LoopPoint: integer): boolean;
var
 j, j1, j2: integer;
 j3: PWord;
 M: PModTypes;
begin
 TimeLength := 0;
 LoopPoint := 0;
 FoundFLS := False;
 j := F_Frame^.FLS_PositionsPointer - F_Frame^.FLS_SamplesPointer;
 if (j < 0) or (j and 3 <> 0) then exit;
 j := F_Frame^.FLS_OrnamentsPointer - 16;
 if j < 0 then exit;

 repeat
   j2 := F_Frame^.FLS_SamplesPointer + 2 - j;
   if (j2 >= 8) and (j2 < Readen1) then
    begin
     j3 := @F_Frame^.Index[j2];
     j1 := j3^ - j;
     if (j1 >= 8) and (j1 < Readen1) then
      begin
       j3 := @F_Frame^.Index[j2 - 4];
       j2 := j3^ - j;
       if (j2 >= 6) and (j2 < Readen1) then
         if j1 - j2 = $20 then
          begin
           j2 := F_Frame^.FLS_PatternsPointers[1].PatternB - j;
           if (j2 > 21) and (j2 < Readen1) then
            begin
             j1 := F_Frame^.FLS_PatternsPointers[1].PatternA - j;
             if (j1 > 20) and (j1 < Readen1) then
               if F_Frame^.Index[j1 - 1] = 0 then
                begin
                 while (j1 <= Readen1) and (F_Frame^.Index[j1] <> 255) do
                  begin
                   repeat
                     case F_Frame^.Index[j1] of
                       0..$5f, $80, $81:
                        begin
                         Inc(j1);
                         break;
                        end;
                       $82..$8e:
                        begin
                         Inc(j1);
                        end;
                      end;
                     Inc(j1);
                   until j1 > Readen1;
                  end;
                 if j1 + 1 = j2 then break;
                end;
            end;
          end;
      end;
    end;
   Dec(j);
 until j = -1;
 if j < 0 then exit;

 F_Length := 0;
 if F_Frame^.FLS_PositionsPointer - j > Readen1 then exit;
 if F_Frame^.FLS_PositionsPointer - j < 16 then exit;
 F_Length := PWord(@F_Frame^.Index[F_Frame^.FLS_PositionsPointer - j - 2])^ + $60 - j;
 if F_Length <= F_Frame^.FLS_PositionsPointer - j then exit;
 if F_Length > Readen1 + 1 then exit;
 if (F_Frame^.FLS_SamplesPointer - j) and 1 <> 0 then exit;

 if IntegrityCheck then
  try
   New(M);
    try
     if not LoadTrackerModule(M^, nil, -1, j, F_Length, F_Frame, FT.FLS) then exit;
     GetTimeFLS(M, TimeLength);
     if TimeLength = 0 then exit;
    finally
     Dispose(M);
    end;
  except
   exit;
  end;
 F_Address := j;
 FoundFLS := True;
end;*)

{$IFDEF Windows}
procedure AddCDTrack(CDN, TN: integer; Inited: boolean);
var
 s: string;
 PLItem: PPlayListItem;
begin
 if not Inited then InitCDDevice(CDN);
  try
   if IsAudioTrack(CDN, TN) then
    begin
     s := CDDrives[CDN] + ':\Track';
     if TN < 10 then s := s + '0';
     s := s + IntToStr(TN) + '.cda';
     AddPlayListItem(PLItem);
     with PLItem^ do
      begin
       FileName := s;
       Offset := TN;
       Address := CDN;
       FileType := GetFileType('CDA');
      end;
    end;
  finally
   if not Inited then CloseCDDevice(CDN);
  end;

end;
{$ENDIF Windows}

procedure Add_Songs_From_File(File_Name: string; Detect: boolean);
type
 PStr2 = ^TStr2;
 TStr2 = packed array [0..2] of char;
 PStr4 = ^TStr4;
 TStr4 = packed array [0..3] of char;
 TStr5 = packed array [0..4] of char;
 PTRDFile = ^TTRDFile;

 TTRDFile = packed record
   Name: array [0..10] of char;
   Len: word;
   A: packed record
     case boolean of
       False: (SecLen, Sec, Trc: byte);
       True: (SecLenH, ChSumH: word);
      end;
  end;
var
 ImageCatalog: array of record
   Name: string;
   Offset, Size: integer;
    end;
 Zag: TStr4;
 LHZag: TStr5;
 F_Offset, F_Offset_Prev, F_Length_Prev: integer;
 FType: Available_Types;
 FTime, FLoop: integer;
 FTitle: string;
 F_Buffer: array[0..65536 * 2 - 1] of byte;
 F_Index, FilSiz, F_Point, F_NumOfTrack: integer;
 Start_Time: qword;
 SFileExt: string;
 PLItem: PPlayListItem;
 Loaded: boolean;
 FirstAdded: integer;
 URHandle: integer;

 function AddTRDName(i, sz, offs: integer): boolean;
 begin
   Result := False;
   with PTRDFile(@F_Buffer[65536 + i * sz + offs])^ do
    begin
     if Name[0] = #0 then
      begin
       SetLength(ImageCatalog, i);
       exit;
      end
     else if Name[0] = #1 then
       ImageCatalog[i].Name := 'Erased_' + Trim(Copy(Name, 1, 7))
     else
       ImageCatalog[i].Name := Trim(Copy(Name, 0, 8));
     ImageCatalog[i].Name := ImageCatalog[i].Name + '.' + Name[8];
     if (Name[9] in [#33..#127]) and (Name[10] in [#32..#127]) then
      begin
       ImageCatalog[i].Name := ImageCatalog[i].Name + Name[9];
       if Name[10] <> ' ' then
         ImageCatalog[i].Name := ImageCatalog[i].Name + Name[10];
      end;
     ImageCatalog[i].Name := CPToUTF8(ImageCatalog[i].Name);
     if sz = 0 then
       ImageCatalog[i].Size := A.SecLenH
     else
       ImageCatalog[i].Size := A.SecLen * 256;
     if sz = 16 then ImageCatalog[i].Offset := (A.Sec + A.Trc * 16) * 256;
    end;
   Result := True;
 end;

type
 PTSData = ^TTSData;

 TTSData = packed record
   Type1: TStr4;
   Size1: word;
   Type2: TStr4;
   Size2: word;
   TSID: TStr4;
  end;
var
 FType1, FType2: Available_Types;
 TSData: TTSData;

 function GetTSType(TS: TStr4): Available_Types;
 const
   STC = $21435453;
   ASC = $21435341;
   STP = $21505453;
   PSC = $21435350;
   FLS = $21534C46;
   FTC = $21435446;
   PT1 = $21315450;
   PT2 = $21325450;
   PT3 = $21335450;
   SQT = $21545153;
   GTR = $21525447;
   PSM = $214D5350;
 begin
   Result := -1;
   case PLongWord(@TS)^ of
     STC: Result := FT.STC;
     ASC: Result := FT.ASC;
     STP: Result := FT.STP;
     PSC: Result := FT.PSC;
     FLS: Result := FT.FLS;
     FTC: Result := FT.FTC;
     PT1: Result := FT.PT1;
     PT2: Result := FT.PT2;
     PT3: Result := FT.PT3;
     SQT: Result := FT.SQT;
     GTR: Result := FT.GTR;
     PSM: Result := FT.PSM;
    end;
 end;

 procedure Init_Detector;
 var
   i, n: integer;
 begin
   Loaded := True;
   FirstAdded := Length(PlayListItems);
   FileSeekTry(UniReadersData[URHandle]^.UniFile, 0);
   F_Offset := -1;
   F_Offset_Prev := -1;
   F_Length_Prev := 0;
   F_Index := 65535;
   FilSiz := UniReadersData[URHandle]^.UniFileSize - 1;
   PrgBox := False;
   Readen1 := FileReadTry(UniReadersData[URHandle]^.UniFile, F_Buffer[65536], 65536);
   F_Point := 1024;
   if (SFileExt = '.trd') and (UniReadersData[URHandle]^.UniFileSize > 4096) and
     (UniReadersData[URHandle]^.UniFileSize mod 256 = 0) and
     (F_Buffer[65536 + 8 * 256 + $e7] = 16) then
    begin
     SetLength(ImageCatalog, 128);
     for i := 0 to 127 do
       if not AddTRDName(i, 16, 0) then break;
    end
   else if (SFileExt = '.scl') and (UniReadersData[URHandle]^.UniFileSize > 13) and
     (PInt64(@F_Buffer[65536])^ = $5249414c434e4953) and
     (F_Buffer[65536 + 8] <> 0) and (UniReadersData[URHandle]^.UniFileSize >
     int64(F_Buffer[65536 + 8]) * 14 + 13) then
    begin
     SetLength(ImageCatalog, F_Buffer[65536 + 8]);
     n := 9 + F_Buffer[65536 + 8] * 14;
     for i := 0 to F_Buffer[65536 + 8] - 1 do
      begin
       if not AddTRDName(i, 14, 9) then break;
       ImageCatalog[i].Offset := n;
       Inc(n, PTRDFile(@F_Buffer[65536 + i * 14 + 9])^.A.SecLen * 256);
      end;
    end
   else if (Length(SFileExt) > 2) and (SFileExt[2] in ['!', '$']) and
     (UniReadersData[URHandle]^.UniFileSize > 17) then
    begin
     n := 0;
     for i := 0 to 14 do Inc(n, F_Buffer[65536 + i]);
     if PTRDFile(@F_Buffer[65536])^.A.ChSumH = word(n * 257 + 105) then
      begin
       SetLength(ImageCatalog, 1);
       if AddTRDName(0, 0, 0) then ImageCatalog[0].Offset := 17;
      end;
    end;
   F_PlayerTag.TagType := F_Tag_No;
   Start_Time := GetTickCount64;
   LongProcessPrepare;
 end;

 function Module_Detector(CheckTS: boolean): boolean;
 var
   Readen2, offs: integer;
 begin
   Module_Detector := False;
   repeat
     Inc(F_Offset);
     Inc(F_Index);
     Dec(Readen1);
     if F_Offset >= FilSiz then
      begin
       if PrgBox then
         FrmPrBox.Free;
       Exit;
      end;
     if F_Index >= 65536 then
      begin
       move(F_Buffer[65536], F_Buffer, 65536);
       Dec(F_Index, 65536);
       Readen2 := FileReadTry(UniReadersData[URHandle]^.UniFile, F_Buffer[65536], 65536);
       Inc(Readen1, Readen2);
      end;
     F_Frame := @F_Buffer[F_Index];
     if CheckTS then
      begin
       if (Readen1 >= 16 - 1) and (PTSData(F_Frame)^.TSID = '02TS') then
        begin
         FType1 := GetTSType(PTSData(F_Frame)^.Type1);
         if FType1 >= 0 then
          begin
           FType2 := GetTSType(PTSData(F_Frame)^.Type2);
           if FType2 >= 0 then
             exit(True);
          end;
        end;
       Dec(F_Offset);
       Dec(F_Index);
       Inc(Readen1);
       exit;
      end;
     FTime := 0;
     FLoop := 0;
     F_Address := 0;
     if F_STP and FoundSTP_PlayerTags(offs) then
      begin
       F_PlayerTag.Player_Offset := F_Offset;
       F_PlayerTag.TagType := F_Tag_STP;
       SetLength(F_PlayerTag.Value, Length(KsaId) + 25);
       Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(KsaId) + 25);
      end
     else if (F_ASM1 or F_ASM0) and FoundASC_PlayerTags(offs) then
      begin
       F_PlayerTag.Player_Offset := F_Offset;
       F_PlayerTag.TagType := F_Tag_ASC;
       SetLength(F_PlayerTag.Value, Length(AscId) + 20 + 4 + 20);
       Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(AscId) + 20 + 4 + 20);
      end
     else if F_STC and FoundSTC_PlayerTags(offs) then
      begin
       F_PlayerTag.Player_Offset := F_Offset;
       F_PlayerTag.TagType := F_Tag_STC;
       SetLength(F_PlayerTag.Value, Length(StcId) + 10 + 4 + 12);
       Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(StcId) + 10 + 4 + 12);
      end
     else if F_ST3 and FoundST3_PlayerTags(offs) then
      begin
       F_PlayerTag.Player_Offset := F_Offset;
       F_PlayerTag.TagType := F_Tag_ST3;
       SetLength(F_PlayerTag.Value, Length(KsaId) + 27);
       Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(KsaId) + 27);
      end;
     if F_ST1 and FoundST1(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.ST1;
       exit;
      end
     else if F_ST3 and FoundST3(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.ST3;
       exit;
      end
     else if F_STC and FoundSTC(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.STC;
       exit;
      end
     else if F_ASM1 and FoundASC1(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.ASC;
       exit;
      end
     else if F_ASM0 and FoundASC0(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.ASC0;
       exit;
      end
     else if F_STF and FoundSTF(FTime, FLoop, FTitle) then
      begin
       Module_Detector := True;
       FType := FT.STF;
       exit;
      end
     else if F_STP and FoundSTP(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.STP;
       exit;
      end
     else if F_PT2 and FoundPT2(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.PT2;
       exit;
      end
     else if F_PT3 and FoundPT3(False,FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.PT3;
       exit;
      end
     else if F_PT3 and FoundPT3(True,FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.PT3;
       exit;
      end
     else if F_PSC and FoundPSC(False, FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.PSC;
       exit;
      end
     else if F_PSC and FoundPSC(True, FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.PSC;
       exit;
      end
     else if F_FTC and FoundFTC(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.FTC;
       exit;
      end
     else if F_PT1 and FoundPT1(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.PT1;
       exit;
      end
     else if F_GTR and FoundGTR(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.GTR;
       exit;
      end
     else if F_SQT and FoundSQT(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.SQT;
       exit;
      end
     else if F_FLS and FoundFLS(FTime, FLoop) then
      begin
       Module_Detector := True;
       FType := FT.FLS;
       exit;
      end;
     if F_Offset > F_Point then
      begin
       if not PrgBox then
         if {%H-}GetTickCount - Start_Time > 2000 then
          begin
           FrmPrBox := TFrmPrBox.Create(FrmMain);
           PrgBox := True;
           FrmPrBox.Label1.Caption := File_Name;
           FrmPrBox.ProgressBar1.Max := FilSiz + 1;
          end;
       if PrgBox then FrmPrBox.ProgressBar1.Position := F_Offset + 1;
       Application.ProcessMessages;
       F_Point := F_Offset + 1024;
      end;
   until May_Quit or (F_Offset >= FilSiz);
   if PrgBox then
    begin
     FrmPrBox.Free;
     //allow continue with next file
     May_Quit := False;
    end;
 end;

 function OpenAYMFile: integer;
 var
   j: integer;
   AYMFileHeader: TAYMFileHeader;
   F, T: integer;
 begin
   Result := -1;
   UniRead(URHandle, @AYMFileHeader, SizeOf(AYMFileHeader));
   if AYMFileHeader.AYM <> 'AYM' then
     raise EAddFileError.Create(Mes_UnsupportedAYMHeader);
   if AYMFileHeader.Rev <> '0' then
     raise EAddFileError.Create(Mes_UnsupportedAYMRevision + ' (' +
       AYMFileHeader.Rev + ')');
   T := AYMFileHeader.MusMax - AYMFileHeader.MusMin;
   if F_NumOfTrack >= 0 then
    begin
     if F_NumOfTrack > T then exit;
     F := F_NumOfTrack;
     T := F_NumOfTrack;
    end
   else
     F := 0;
   for j := F to T do
    begin
     Result := AddPlayListItem(PLItem);
     with PLItem^ do
      begin
       Author := CPToUTF8(Trim(AYMFileHeader.Author));
       Title := CPToUTF8(Trim(AYMFileHeader.Name));
       FileName := File_Name;
       FormatSpec := j;
       FileType := FT.AYM;
       Time := 15000;
      end;
     RedrawItem(Result);
     CalculatePlaylistScrollBar;
    end;
 end;

 function OpenSNDHFile: integer;
 var
   COMM, TITL, RIPP, CONV, YEAR, OtherShortDesc: string;
   PlayGen: TPlayGen; //ignored, always used VBL for the moment
   NumberOfSongs, CurrentSong, PlayFreq, i: integer;
   PlayTimes: TArrayOfInteger;
   SongNames: TArrayOfString;
   F, T: integer;
 begin
   Result := -1;
   if not sndh_UnpackFile(File_Name, SNDHBuffer) then //todo via UniRead
     raise EAddFileError.Create(Mes_DamagedFileIceDepack);

   sndh_ExtractTextInfo(SNDHBuffer, COMM, TITL, RIPP, CONV, YEAR, OtherShortDesc,
     NumberOfSongs, CurrentSong, PlayFreq, PlayGen,
     PlayTimes, SongNames);
   SNDHBuffer := nil;

   T := NumberOfSongs - 1;
   if F_NumOfTrack >= 0 then
    begin
     if F_NumOfTrack > T then exit;
     F := F_NumOfTrack;
     T := F_NumOfTrack;
     CurrentSong := F_NumOfTrack + 1;
    end
   else
     F := 0;

   for i := F to T do
    begin
     Result := AddPlayListItem(PLItem);
     with PLItem^ do
      begin
       FileName := File_Name;
       FileType := FT.SNDH;
       FormatSpec := CurrentSong - 1;
       Int_Freq := PlayFreq * 1000;
       Author := COMM;
       Title := TITL;
       if RIPP <> '' then
         Comment := SNDH_RippedBy + ': ' + RIPP + #13#10;
       if CONV <> '' then
         Comment := Comment + SNDH_ConvertedBy + ': ' + CONV + #13#10;
       if OtherShortDesc <> '' then
         Comment := Comment + OtherShortDesc;
       Date := YEAR;
       if PlayTimes[CurrentSong - 1] = 0 then
         Time := PlayFreq * 300 //5 минут
       else
         Time := PlayTimes[CurrentSong - 1];
       //sndh_ExtractTextInfo теперь возвращает время в VBL
       if SongNames[CurrentSong - 1] <> '' then
        begin
         if Title <> '' then
           Title := Title + ' - ';
         Title := Title + SongNames[CurrentSong - 1];
        end;
       Inc(CurrentSong);
       if CurrentSong > NumberOfSongs then
         CurrentSong := 1;
      end;
     RedrawItem(Result);
     CalculatePlaylistScrollBar;
    end;
 end;

 function OpenAYFile: integer;
 var
   j: integer;
   CurPos: int64;
   Ch: char;
   Byt: byte;
   Wrd: word;
   AuthorString, MiscString, SongName: string;
   AYFileHeader: TAYFileHeader;
   SongStructure: TSongStructure;
 begin
   Result := -1;
   UniRead(URHandle, @AYFileHeader, SizeOf(AYFileHeader));
   if AYFileHeader.FileID <> $5941585A then
     raise EAddFileError.Create(Mes_UnsupportedAYHeader + ' (' +
       CPToUTF8(PStr4(@AYFileHeader.FileID)^) + ')');
   if (AYFileHeader.TypeID <> $4C554D45) and (AYFileHeader.TypeID <> $44414D41) and
     (AYFileHeader.TypeID <> $31315453) then
     raise EAddFileError.Create(Mes_UnsupportedAYType + ' (' +
       CPToUTF8(PStr4(@AYFileHeader.TypeID)^) + ')');

   UniFileSeek(URHandle, int64(smallint(SwapEndian(AYFileHeader.PAuthor))) + 12);
   AuthorString := '';
   repeat
     UniRead(URHandle, @Ch, 1);
     if Ch <> #0 then AuthorString := AuthorString + Ch;
   until Ch = #0;
   AuthorString := Trim(AuthorString);

   UniFileSeek(URHandle, int64(smallint(SwapEndian(AYFileHeader.PMisc))) + 14);
   MiscString := '';
   repeat
     UniRead(URHandle, @Ch, 1);
     if Ch <> #0 then MiscString := MiscString + Ch;
   until Ch = #0;
   MiscString := Trim(MiscString);

   UniFileSeek(URHandle, int64(smallint(SwapEndian(AYFileHeader.PSongsStructure))) + 18);
   for j := 0 to AYFileHeader.NumOfSongs do
    begin
     UniRead(URHandle, @SongStructure, 4);

     if F_NumOfTrack >= 0 then
       if j <> F_NumOfTrack then continue;

     CurPos := UniReadersData[URHandle]^.UniFilePos;
     UniFileSeek(URHandle, smallint(SwapEndian(SongStructure.PSongName)) + CurPos - 4);
     SongName := '';
     repeat
       UniRead(URHandle, @Ch, 1);
       if Ch <> #0 then SongName := SongName + Ch;
     until Ch = #0;
     SongName := Trim(SongName);
     Result := AddPlayListItem(PLItem);
     with PLItem^ do
      begin
       Author := CPToUTF8(AuthorString);
       Title := CPToUTF8(SongName);
       Comment := CPToUTF8(MiscString);
       FileName := File_Name;
       if AYFileHeader.TypeID = $4C554D45 then
        begin
         FormatSpec := j;
         FileType := FT.AY;
         UniFileSeek(URHandle, smallint(SwapEndian(SongStructure.PSongData)) +
           CurPos + 2);
         UniRead(URHandle, @Wrd, 2);
         if Wrd <> 0 then
           Time := SwapEndian(Wrd)
         else
           Time := 15000;
        end
       else if AYFileHeader.TypeID = $44414D41 then
        begin
         Offset := smallint(SwapEndian(SongStructure.PSongData)) + CurPos - 2;
         UniFileSeek(URHandle, Offset);
         UniRead(URHandle, @Wrd, 2);
         Address := SwapEndian(Wrd);
         UniRead(URHandle, @Byt, 1);
         FormatSpec := Byt;
         UniRead(URHandle, @Byt, 1);
         UniRead(URHandle, @Wrd, 2);
         Time := Byt * SwapEndian(Wrd);
         Inc(Offset, 14 - 6);
         FileType := FT.FXM;
        end
       else
        begin
         Offset := smallint(SwapEndian(SongStructure.PSongData)) + CurPos - 2 + 8;
         Length := UniReadersData[URHandle]^.UniFileSize - Offset;
         //todo вычисление длины (т.к. может быть более одного ST11 в файле)
         //длина всех паттернов должна быть кратна размеру паттерна (megamix1.ay - 1 лишний байт)
         if Length < 3009 + 576 then
           raise EAddFileError.Create(Mes_ToSmallST11);
         //todo допустим ли в этот месте raise?
         Length := 3009 + (Length - 3009) div 576 * 576;
         //todo проверка макс. длины?
         FileType := FT.ST1;
        end;
      end;
     RedrawItem(Result);
     CalculatePlaylistScrollBar;
     UniFileSeek(URHandle, CurPos);
    end;
 end;

 function AddOther(FType: Available_Types): integer;
 begin
   if not FileIsURL(File_Name) and IsStreamFileType(FType) then
    begin
     if LoadCUE(RemoveAnyExt(File_Name) + '.cue', File_Name) then
       Exit(-1);
     if LoadCUE(File_Name + '.cue', File_Name) then
       Exit(-1);
    end;
   Result := AddPlayListItem(PLItem);
   with PLItem^ do
    begin
     FileName := File_Name;
     FileType := FType;
    end;
   RedrawItem(Result);
   CalculatePlaylistScrollBar;
 end;

 function Add(FType: Available_Types; TimLen, Looping_VBL: integer;
   Redraw: boolean = True): integer;

   procedure AddTrackerModule(FType: Available_Types; var PLItem: TPlaylistItem);
   var
     KsaId2, s: string;
     Wrd, Pat: word;
     Int: integer;
   begin
     if FType = FT.STC then
      begin
       SetLength(KsaId2, 20);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 5 + PLItem.Offset);
         UniRead(URHandle, @Pat, 2);
         UniRead(URHandle, @KsaId2[1], 20);
        end
       else
        begin
         Pat := F_Frame^.ST_PatternsPointer;
         Move(F_Frame^.ST_Name, KsaId2[1], 20);
        end;
       PLItem.Title := Copy(KsaId2, 1, 18);
       if IsMatch(FT.STC, 7, PLItem.Title) then
         PLItem.Title := ''
       else
        begin
         Wrd := PWord(@KsaId2[19])^;
         if Wrd <> PLItem.Length then
           if KsaId2[19] in [' '..#127] then
            begin
             PLItem.Title := PLItem.Title + KsaId2[19];
             if KsaId2[20] in [' '..#127] then
               PLItem.Title := PLItem.Title + KsaId2[20];
            end;
        end;
       if Pat >= 55 + 27 then
        begin
         SetLength(KsaId2, 55);
         if not Loaded then
          begin
           UniFileSeek(URHandle, Pat + PLItem.Offset - 55);
           UniRead(URHandle, @KsaId2[1], 55);
          end
         else
           Move(F_Frame^.Index[Pat - 55], KsaId2[1], 55);
         if Pos(StcId, KsaId2) = 1 then
          begin
           //29+10+4+12
           PLItem.Author := Copy(KsaId2, 29 + 10 + 4 + 1, 12);
           s := Trim(Copy(KsaId2, 29 + 1, 10));
          end
         else if Pos(KsaId, KsaId2) = 1 then
           s := Trim(Copy(KsaId2, 29, 27))
         else
           s := '';
         if s <> '' then
          begin
           PLItem.Title := Trim(PLItem.Title);
           if PLItem.Title = '' then
             PLItem.Title := s
           else if PLItem.Title <> s then
             PLItem.Title := s + ' (' + PLItem.Title + ')';
          end;
        end;
      end
     else if FType = FT.ST3 then
      begin
       SetLength(KsaId2, 28);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 9 + PLItem.Offset);
         UniRead(URHandle, @KsaId2[1], 28);
        end
       else
         Move(F_Frame^.Index[9], KsaId2[1], 28);
       if KsaId2 = KsaId then
        begin
         SetLength(PLItem.Title, 27);
         if not Loaded then
           UniRead(URHandle, @PLItem.Title[1], 27)
         else
           Move(F_Frame^.Index[37], PLItem.Title[1], 27);
         if Trim(PLItem.Title) <> '' then
           PLItem.Comment := KsaId + PLItem.Title;
        end;
      end
     else if FType = FT.GTR then
      begin
       SetLength(PLItem.Title, 32);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 7 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Title[1], 32);
        end
       else
         Move(F_Frame^.GTR_Name, PLItem.Title[1], 32);
      end
     else if FType = FT.PSC then
      begin
       SetLength(PLItem.Title, 20);
       SetLength(PLItem.Author, 20);
       if not Loaded then
        begin
         UniFileSeek(URHandle, $19 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Title[1], 20);
         UniFileSeek(URHandle, $31 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Author[1], 20);
        end
       else
        begin
         Move(F_Frame^.PSC_MusicName[$19], PLItem.Title[1], 20);
         Move(F_Frame^.PSC_MusicName[$31], PLItem.Author[1], 20);
        end;
      end
     else if FType = FT.FTC then
      begin
       SetLength(PLItem.Title, 42);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 8 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Title[1], 42);
        end
       else
         Move(F_Frame^.FTC_MusicName[8], PLItem.Title[1], 42);
      end
     else if FType = FT.PT1 then
      begin
       SetLength(PLItem.Title, 30);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 69 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Title[1], 30);
        end
       else
         Move(F_Frame^.PT1_MusicName, PLItem.Title[1], 30);
      end
     else if FType = FT.PT2 then
      begin
       SetLength(PLItem.Title, 30);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 101 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Title[1], 30);
        end
       else
         Move(F_Frame^.PT2_MusicName, PLItem.Title[1], 30);
      end
     else if FType = FT.PT3 then
      begin
       SetLength(PLItem.Title, 32);
       SetLength(PLItem.Author, 32);
       SetLength(KsaId2, 2);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 13 + PLItem.Offset);
         UniRead(URHandle, @KsaId2[1], 1);
         UniFileSeek(URHandle, $1E + PLItem.Offset);
         UniRead(URHandle, @PLItem.Title[1], 32);
         UniFileSeek(URHandle, $42 + PLItem.Offset);
         UniRead(URHandle, @PLItem.Author[1], 32);
         UniRead(URHandle, @KsaId2[2], 1);
        end
       else
        begin
         Move(F_Frame^.PT3_MusicName[13], KsaId2[1], 1);
         Move(F_Frame^.PT3_MusicName[$1E], PLItem.Title[1], 32);
         Move(F_Frame^.PT3_MusicName[$42], PLItem.Author[1], 32);
         Move(F_Frame^.PT3_MusicName[98], KsaId2[2], 1);
        end;
       if KsaId2[2] <> #$20 then
        begin
         Int := 6;
         if KsaId2[1] in ['0'..'9'] then
           Int := Ord(KsaId2[1]) - $30;
         if Int >= 7 then
           PLItem.FormatSpec := 0; //PT v3.7 TS-format flag
        end;
      end
     else if FType = FT.ASC then
      begin
       if not Loaded then
        begin
         UniFileSeek(URHandle, 2 + PLItem.Offset);
         UniRead(URHandle, @F_Frame^.ASC1_PatternsPointers, 2);
         UniFileSeek(URHandle, 8 + PLItem.Offset);
         UniRead(URHandle, @F_Frame^.ASC1_Number_Of_Positions, 1);
        end;
       if F_Frame^.ASC1_PatternsPointers -
       F_Frame^.ASC1_Number_Of_Positions = 72 then
        begin
         SetLength(PLItem.Title, 20);
         SetLength(PLItem.Author, 20);
         if not Loaded then
          begin
           UniFileSeek(URHandle, int64(F_Frame^.ASC1_PatternsPointers) -
             44 + PLItem.Offset);
           UniRead(URHandle, @PLItem.Title[1], 20);
           UniFileSeek(URHandle, int64(F_Frame^.ASC1_PatternsPointers) -
             20 + PLItem.Offset);
           UniRead(URHandle, @PLItem.Author[1], 20);
          end
         else
          begin
           Move(F_Frame^.Index[F_Frame^.ASC1_PatternsPointers - 44],
             PLItem.Title[1], 20);
           Move(F_Frame^.Index[F_Frame^.ASC1_PatternsPointers - 20],
             PLItem.Author[1], 20);
          end;
        end;
      end
     else if FType = FT.ASC0 then
      begin
       if not Loaded then
        begin
         UniFileSeek(URHandle, 1 + PLItem.Offset);
         UniRead(URHandle, @F_Frame^.ASC0_PatternsPointers, 2);
         UniFileSeek(URHandle, 7 + PLItem.Offset);
         UniRead(URHandle, @F_Frame^.ASC0_Number_Of_Positions, 1);
        end;
       if F_Frame^.ASC0_PatternsPointers -
       F_Frame^.ASC0_Number_Of_Positions = 71 then
        begin
         SetLength(PLItem.Title, 20);
         SetLength(PLItem.Author, 20);
         if not Loaded then
          begin
           UniFileSeek(URHandle, int64(F_Frame^.ASC0_PatternsPointers) -
             44 + PLItem.Offset);
           UniRead(URHandle, @PLItem.Title[1], 20);
           UniFileSeek(URHandle, int64(F_Frame^.ASC0_PatternsPointers) -
             20 + PLItem.Offset);
           UniRead(URHandle, @PLItem.Author[1], 20);
          end
         else
          begin
           Move(F_Frame^.Index[F_Frame^.ASC0_PatternsPointers - 44],
             PLItem.Title[1], 20);
           Move(F_Frame^.Index[F_Frame^.ASC0_PatternsPointers - 20],
             PLItem.Author[1], 20);
          end;
        end;
      end
     else if FType = FT.STP then
      begin
       if Loaded then
         Wrd := PWord(@F_Frame^.Index[F_Frame^.STP_PatternsPointer])^
       else
        begin
         UniFileSeek(URHandle, 3 + PLItem.Offset);
         UniRead(URHandle, @Wrd, 2);
         UniFileSeek(URHandle, Wrd + PLItem.Offset);
         UniRead(URHandle, @Wrd, 2);
        end;
       SetLength(KsaId2, 28);
       if not Loaded then
        begin
         UniFileSeek(URHandle, 10 + PLItem.Offset);
         UniRead(URHandle, @KsaId2[1], 28);
        end
       else
         Move(F_Frame^.Index[10], KsaId2[1], 28);
       if KsaId2 = KsaId then
        begin
         Int := integer(Wrd) - $a - 53;
         SetLength(PLItem.Title, 25);
         if not Loaded then
           UniRead(URHandle, @PLItem.Title[1], 25)
         else
           Move(F_Frame^.Index[38], PLItem.Title[1], 25);
        end
       else
         Int := integer(Wrd) - $a;
       if Int < 0 then
         raise EAddFileError.Create(Mes_CantCalcSTPAddr);
       F_Address := Int;
       PLItem.Address := Int;
      end
     else if FType = FT.FXM then
      begin
       UniFileSeek(URHandle, 4 + PLItem.Offset);
       UniRead(URHandle, @Wrd, 2);
       F_Address := Wrd;
       PLItem.Address := Wrd;
       PLItem.FormatSpec := 31;
      end
     else if FType = FT.PSM then
      begin
       if not Loaded then
        begin
         UniFileSeek(URHandle,{0 + }PLItem.Offset);
         UniRead(URHandle, @Wrd, 2);
        end
       else
         Wrd := F_Frame^.PSM_PositionsPointer;
       if Wrd > 8 then
        begin
         Dec(Wrd, 8);
         SetLength(KsaId2, Wrd);
         if not Loaded then
          begin
           UniFileSeek(URHandle, 8 + PLItem.Offset);
           UniRead(URHandle, @KsaId2[1], Wrd);
          end
         else
           Move(F_Frame^.PSM_Remark, KsaId2[1], Wrd);
         if KsaId2 <> 'psm1'#0 then
           if (Wrd <= 5) or (Copy(KsaId2, 1, 5) <> 'psm1'#0) then
             PLItem.Title := KsaId2
           else
             PLItem.Title := Copy(KsaId2, 6, Wrd - 5);
        end;
      end;
   end;

 var
   i, j, k, l: integer;
   Ch: char;
   DWrd: dword;
   VTXFileHeader: TVTXFileHeader;
   LZHFileHeader: TLZHFileHeader;
   YM5FileHeader: TYM5FileHeader;
   PLItem1, PLItem2: TPlaylistItem;
 type
   PLZHDamaged = ^TLZHDamaged;
   TLZHDamaged = array[1..11] of char;
 begin
   Result := -1;
   FillDefPlayListItem(PLItem1);
   with PLItem1 do
    begin
     FileName := File_Name;
     Offset := F_Offset;
     Address := F_Address;
     Length := F_Length;
     FileType := FType;
     Loop := Looping_VBL;
     Time := TimLen;
    end;

   FType1 := FType;
   FType2 := -1;

   if IsAYNativeFileType(FType) then
    begin
     if not Loaded then
      begin
       if (UniReadersData[URHandle]^.UniFileSize > SizeOf(TSData)) and
         (UniReadersData[URHandle]^.UniFileSize <= 65536 * 2 + SizeOf(TSData)) then
        begin
         l := UniReadersData[URHandle]^.UniFileSize - SizeOf(TSData);
         UniFileSeek(URHandle, l);
         UniRead(URHandle, @TSData, 16);
         if TSData.TSID = '02TS' then
          begin
           FType1 := GetTSType(TSData.Type1);
           if FType1 >= 0 then
            begin
             FType2 := GetTSType(TSData.Type2);
             if (FType2 >= 0) and (TSData.Size1 < l) and
               (TSData.Size2 < l) and (integer(TSData.Size1 + TSData.Size2) = l) then
              begin
               PLItem1.FileType := FType1;
               PLItem1.Length := TSData.Size1;
               PLItem2 := PLItem1;
               PLItem2.FileType := FType2;
               PLItem2.Offset := TSData.Size1;
               PLItem2.Length := TSData.Size2;
              end
             else
               FType1 := -1;
            end;
           if (FType1 = -1) or (FType2 = -1) then
            begin
             if UniReadersData[URHandle]^.UniFileSize > 65536 then exit;
             FType1 := FType;
             FType2 := -1;
            end;
          end;
        end
       else if FType1 <> FT.TS then //strange size for TS, check later
         Exit;
      end;
     if FType1 = FT.TS then
      begin
       //can be Transport Stream container
       Exit(AddOther(GetFileType('MP2')));
       //      raise EAddFileError.Create(Mes_UnsupTSStruct);
      end;
     AddTrackerModule(FType1, PLItem1);
     if FType2 >= 0 then AddTrackerModule(FType2, PLItem2);
    end
   else if FType = FT.VTX then
    begin
     UniFileSeek(URHandle, 0);
     UniRead(URHandle, @VTXFileHeader, 2);
     if (VTXFileHeader.Id <> $5941) and (VTXFileHeader.Id <> $4d59) and
       (VTXFileHeader.Id <> $7961) and (VTXFileHeader.Id <> $6d79) then
       raise EAddFileError.Create(Mes_UnsupportedVTXHeader + ' (' +
         CPToUTF8(PStr2(@VTXFileHeader.Id)^) + ')');
     if (VTXFileHeader.Id = $5941) or (VTXFileHeader.Id = $4d59) then
      begin
       UniRead(URHandle, @VTXFileHeader.Mode, 8);
       UniRead(URHandle, @VTXFileHeader.UnpackSize, 4);
      end
     else
       UniRead(URHandle, @VTXFileHeader.Mode, sizeof(VTXFileHeader) - 2);
     PLItem1.Loop := VTXFileHeader.Loop;
     PLItem1.Int_Freq := VTXFileHeader.InterFrq * 1000;
     PLItem1.Ay_Freq := VTXFileHeader.ChipFrq;
     PLItem1.Channel_Mode := VTXFileHeader.Mode and 7;
     PLItem1.UnpackedSize := VTXFileHeader.UnpackSize;
     PLItem1.Time := VTXFileHeader.UnpackSize div 14;
     if VTXFileHeader.Mode = 0 then PLItem1.Number_Of_Channels := 1
     else
       PLItem1.Number_Of_Channels := 2;
     if (VTXFileHeader.Id = $7961) or (VTXFileHeader.Id = $5941) then
       PLItem1.Chip_Type := AY_Chip
     else
       PLItem1.Chip_Type := YM_Chip;
     repeat
       UniRead(URHandle, @Ch, 1);
       if Ch <> #0 then PLItem1.Title := PLItem1.Title + Ch;
     until Ch = #0;
     repeat
       UniRead(URHandle, @Ch, 1);
       if Ch <> #0 then PLItem1.Author := PLItem1.Author + Ch;
     until Ch = #0;
     if (VTXFileHeader.Id = $7961) or (VTXFileHeader.Id = $6d79) then
      begin
       if VTXFileHeader.Year <> 0 then
         PLItem1.Date := IntToStr(VTXFileHeader.Year);
       repeat
         UniRead(URHandle, @Ch, 1);
         if Ch <> #0 then PLItem1.Programm := PLItem1.Programm + Ch;
       until Ch = #0;
       repeat
         UniRead(URHandle, @Ch, 1);
         if Ch <> #0 then PLItem1.Tracker := PLItem1.Tracker + Ch;
       until Ch = #0;
       repeat
         UniRead(URHandle, @Ch, 1);
         if Ch <> #0 then PLItem1.Comment := PLItem1.Comment + Ch;
       until Ch = #0;
      end;
     F_Offset := UniReadersData[URHandle]^.UniFilePos;
     PLItem1.Offset := F_Offset;
     F_Length := UniReadersData[URHandle]^.UniFileSize - F_Offset;
     PLItem1.Length := F_Length;
    end
   else if IsSTSoundFileType(FType) then
    begin
     UniFileSeek(URHandle, 0);
     UniRead(URHandle, @LZHFileHeader, SizeOf(LZHFileHeader));
     if LZHFileHeader.Method = '-lh5-' then
      begin
       PLItem1.UnpackedSize := LZHFileHeader.UCompSize;
       Original_Size := LZHFileHeader.UCompSize;
       //try to fix "damaged" YM-files with "xx-lh5-xx" marker like 'YM Archive v5\Whittacker.David\Xenon 2\Xenon2.ym'
       if (PLZHDamaged(@LZHFileHeader)^ = 'xx-lh5-xx'#0#0) and
         (LZHFileHeader.FileNameLen + SizeOf(LZHFileHeader) <> LZHFileHeader.HSize) then
        begin
         F_Length := UniReadersData[URHandle]^.UniFileSize - 25 -
           LZHFileHeader.FileNameLen;
         F_Offset := LZHFileHeader.FileNameLen + SizeOf(LZHFileHeader) + 2;
        end
       else
        begin
         F_Length := LZHFileHeader.CompSize;
         F_Offset := LZHFileHeader.HSize + 2;
        end;
       if (F_Length <= 0) or (F_Offset >=
         UniReadersData[URHandle]^.UniFileSize) then
         InvalidLZH;
       PLItem1.Length := F_Length;
       Compressed_Size := F_Length;
       PLItem1.Offset := F_Offset;
       UniFileSeek(URHandle, F_Offset);
       UniAddDepacker(URHandle, UDLZH);
      end
     else
      begin
       PLItem1.UnpackedSize := UniReadersData[URHandle]^.UniFileSize;
       F_Offset := 0;
       PLItem1.Offset := 0;
       UniFileSeek(URHandle, 0);
      end;
     UniRead(URHandle, @YM5FileHeader, 4);
     case YM5FileHeader.Id of
       $62334d59:
        begin
         PLItem1.FileType := FT.YM3b;
         PLItem1.Time := (PLItem1.UnpackedSize - 8) div 14;
        end;
       $21334d59,
       $21324d59:
        begin
         if YM5FileHeader.Id = $21324d59 then
           PLItem1.FileType := FT.YM2
         else
           PLItem1.FileType := FT.YM3;
         PLItem1.Time := (PLItem1.UnpackedSize - 4) div 14;
         PLItem1.Loop := 0;
        end;
       $21354d59,
       $21364d59:
        begin
         if YM5FileHeader.Id = $21354d59 then
           PLItem1.FileType := FT.YM5
         else
           PLItem1.FileType := FT.YM6;
         if PLItem1.UnpackedSize < sizeof(TYM5FileHeader) then exit;
         UniRead(URHandle, @YM5FileHeader.Leo, sizeof(TYM5FileHeader) - 4);
         PLItem1.Time := SwapEndian(YM5FileHeader.Num_of_tiks);
         l := PLItem1.UnpackedSize - int64(PLItem1.Time) * 16;
         if l < sizeof(TYM5FileHeader) then exit;
         PLItem1.Ay_Freq := SwapEndian(YM5FileHeader.ChipFrq);
         PLItem1.Int_Freq := SwapEndian(YM5FileHeader.InterFrq) * 1000;
         PLItem1.Loop := SwapEndian(YM5FileHeader.Loop);
         k := SwapEndian(YM5FileHeader.Add_Size) + sizeof(TYM5FileHeader);
         if k + 3 > l then exit;
         for i := 34 + 1 to k do
           UniRead(URHandle, @DWrd, 1);
         for i := 1 to SwapEndian(YM5FileHeader.Num_of_Dig) do
          begin
           if k + 4 > l then exit;
           UniRead(URHandle, @DWrd, 4);
           DWrd := SwapEndian(DWrd);
           Inc(k, 4 + DWrd);
           if k > l then exit;
           for j := 0 to DWrd - 1 do
             UniRead(URHandle, @DWrd, 1);
          end;
         repeat
           Inc(k);
           if k > l then exit;
           UniRead(URHandle, @Ch, 1);
           if Ch <> #0 then PLItem1.Title := PLItem1.Title + Ch;
         until Ch = #0;
         repeat
           Inc(k);
           if k > l then exit;
           UniRead(URHandle, @Ch, 1);
           if Ch <> #0 then PLItem1.Author := PLItem1.Author + Ch;
         until Ch = #0;
         repeat
           Inc(k);
           if k > l then exit;
           UniRead(URHandle, @Ch, 1);
           if Ch <> #0 then PLItem1.Comment := PLItem1.Comment + Ch;
         until Ch = #0;
         PLItem1.FormatSpec := k;
        end
     else
       raise EAddFileError.Create(Mes_UnsupportedYMHeader + ' (' +
         CPToUTF8(PStr4(@YM5FileHeader.Id)^) + ')');
      end;
    end
   else if (FType = FT.PSG) or (FType = FT.EPSG) then
    begin
     UniFileSeek(URHandle, 0);
     UniRead(URHandle, @zag, 4);
     if zag = 'PSG'#26 then
      begin
       UniRead(URHandle, @zag, 2);
       if byte(zag[0]) > 10 then
         raise EAddFileError.Create(Mes_UnsupportedPSGVersion +
           ' (' + IntToStr(byte(zag[0])) + ')');
       if byte(zag[0]) = 10 then
         PLItem1.Int_Freq := byte(zag[1]) * 1000;
       PLItem1.FileType := FT.PSG;
      end
     else if zag = 'EPSG' then
      begin
       UniRead(URHandle, @zag, 2);
       if (zag[0] <> #26) then exit;
       case zag[1] of
         #0: PLItem1.FormatSpec := 70908;
         #1: PLItem1.FormatSpec := 71680;
         #255: UniRead(URHandle, @PLItem1.FormatSpec, 4)
       else
         raise EAddFileError.Create(Mes_UnsupportedEPSGCType +
           ' (' + IntToStr(byte(zag[1])) + ')');
        end;
       PLItem1.FileType := FT.EPSG;
      end
     else
       raise EAddFileError.Create(Mes_UnsupportedPSGHeader + ' (' +
         CPToUTF8(zag) + ')');
    end;
   PLItem1.Author := CPToUTF8(Trim(PLItem1.Author));
   PLItem1.Title := CPToUTF8(Trim(PLItem1.Title));
   PLItem1.Programm := CPToUTF8(Trim(PLItem1.Programm));
   PLItem1.Tracker := CPToUTF8(Trim(PLItem1.Tracker));
   if FType = FT.ST3 then
     PLItem1.Comment := CPToUTF8(PLItem1.Comment)
   //ST3 can contain TAG in comment, don't trim
   else
     PLItem1.Comment := CPToUTF8(Trim(PLItem1.Comment));
   if FType2 >= 0 then
    begin
     PLItem2.Author := CPToUTF8(Trim(PLItem2.Author));
     PLItem2.Title := CPToUTF8(Trim(PLItem2.Title));
     PLItem2.Programm := CPToUTF8(Trim(PLItem2.Programm));
     PLItem2.Tracker := CPToUTF8(Trim(PLItem2.Tracker));
     PLItem2.Comment := CPToUTF8(Trim(PLItem2.Comment));
     New(PLItem1.Next);
     PLItem1.Next^ := PLItem2;
    end;
   Result := AddPlayListItem(PLItem);
   PLItem^ := PLItem1;
   if Redraw then
    begin
     RedrawItem(Result);
     CalculatePlaylistScrollBar;
    end;
 end;

 {$IFDEF Windows}
 procedure AddCD;
 type
   TCDA = packed record
   rID: array[0..3] of char;
   rLen: DWORD;
   CDAID: array[0..3] of char;
   fID: array[0..3] of char;
   fLen: DWORD;
   Version, TrackNum: word;
   SerNum, BegTime, LenTime: integer;
  end;
 var
   i, j, DriveNum, TrackNum: integer;
   D: string;
   f: file of TCDA;
   CDA: TCDA;
   FormSpec, TimLen: integer;
   Flg: boolean;
 begin
   if Length(CDDrives) = 0 then exit;
    try
     D := UpperCase(ExtractFileDrive(File_Name));
     if Length(D) = 0 then D := CDDrives[0];
     DriveNum := 0;
     for j := 0 to Length(CDDrives) - 1 do
       if CDDrives[j] = D[1] then
        begin
         DriveNum := j;
         break;
        end;
     FormSpec := -1;
     TimLen := 0;
     Flg := False;
     if FileExists(File_Name) then
      begin
       AssignFile(f, File_Name);
       System.Reset(f);
       Read(f, CDA);
       CloseFile(f);
       if (CDA.rID = 'RIFF') and (CDA.CDAID = 'CDDA') and
         (CDA.fID = 'fmt ') and (CDA.Version = 1) then
        begin
         FormSpec := CDA.SerNum;
         TrackNum := CDA.TrackNum;
         TimLen := CDA.LenTime;
         Flg := True;
        end;
      end;
     if not Flg then
      begin
       D := UpperCase(File_Name);
       j := Pos('.CDA', D);
       if j >= 3 then
         TrackNum := StrToInt(Copy(D, j - 2, 2))
       else
         raise EAddFileError.Create(Mes_CantExtractTrkNum);
      end;
    except
     exit;
    end;

   i := AddPlayListItem(PLItem);
   with PLItem^ do
    begin
     FileName := File_Name;
     Offset := TrackNum;
     Address := DriveNum;
     FileType := GetFileType('CDA');
     Time := TimLen;
     FormatSpec := FormSpec;
    end;
   RedrawItem(i);
   CalculatePlaylistScrollBar;
 end;

 procedure AddMIDI(FType: Available_Types);
 var
   numoftrks: word;
   i, j, F, T: integer;
   dummyptr: PMIDIParams;
 begin
   load_midi(dummyptr, @numoftrks, File_Name);
   T := integer(numoftrks) - 1;
   if F_NumOfTrack >= 0 then
    begin
     if F_NumOfTrack > T then exit;
     F := F_NumOfTrack;
     T := F_NumOfTrack;
    end
   else
     F := 0;
   for j := F to T do
    begin
     i := AddPlayListItem(PLItem);
     with PLItem^ do
      begin
       FileName := File_Name;
       FileType := FType;
       FormatSpec := j;
      end;
     RedrawItem(i);
    end;
   CalculatePlaylistScrollBar;
 end;
 {$ENDIF Windows}
var
 n: integer;

 procedure ExtrName(idlen, nmlen, id2len, autlen: integer);
 var
   flg: boolean;
   s: string;
 begin
   flg := False;
   PlayListItems[n]^.Comment :=
     CPToUTF8(Copy(F_PlayerTag.Value, 1, idlen + nmlen + id2len + autlen));
   s := CPToUTF8(Trim(Copy(F_PlayerTag.Value, 1 + idlen, nmlen)));
   if PlayListItems[n]^.Title <> s then
    begin
     flg := True;
     if PlayListItems[n]^.Title = '' then
       PlayListItems[n]^.Title := s
     else if s <> '' then
       PlayListItems[n]^.Title := s + ' (' + PlayListItems[n]^.Title + ')';
    end;
   if autlen <> 0 then
    begin
     s := CPToUTF8(Trim(Copy(F_PlayerTag.Value, 1 + idlen + nmlen + id2len, autlen)));
     if PlayListItems[n]^.Author <> s then
      begin
       flg := True;
       if PlayListItems[n]^.Author = '' then
         PlayListItems[n]^.Author := s
       else if s <> '' then
         PlayListItems[n]^.Author := s + ' (' + PlayListItems[n]^.Author + ')';
      end;
    end;
   if flg then RedrawItem(n);
 end;

 procedure Check_PlayerTags;
 begin
   if FType = FT.STP then
    begin
     if F_PlayerTag.TagType = F_Tag_STP then
      begin
       if MatchPlayerLength(F_Tag_STP, F_Offset_Prev - F_PlayerTag.Player_Offset) then
         ExtrName(Length(KsaId), 25, 0, 0);
      end;
    end
   else if (FType = FT.ASC) or (FType = FT.ASC0) then
    begin
     if F_PlayerTag.TagType = F_Tag_ASC then
       if MatchPlayerLength(F_Tag_ASC, F_Offset_Prev - F_PlayerTag.Player_Offset) then
         ExtrName(Length(AscId), 20, 4, 20);
    end
   else if FType = FT.STC then
    begin
     if F_PlayerTag.TagType = F_Tag_STC then
       if MatchPlayerLength(F_Tag_STC, F_Offset_Prev - F_PlayerTag.Player_Offset) then
         ExtrName(Length(StcId), 10, 4, 12);
    end
   else if FType = FT.ST3 then
    begin
     if F_PlayerTag.TagType = F_Tag_ST3 then
       if MatchPlayerLength(F_Tag_ST3, F_Offset_Prev - F_PlayerTag.Player_Offset) then
         ExtrName(Length(KsaId), 27, 0, 0);
    end;
 end;

var
 i, extftype, added, oftmp, sz: integer;
begin
 F_NumOfTrack := -1;

 if FileIsURL(File_Name) then
  begin
   AddOther(GetFileType('MP3'));//todo added :=
   Exit;
  end;

 sz := Length(File_Name);
 i := sz;
 while (i > 2) and (File_Name[i] <> ':') do Dec(i);
 if (i > 2) and (i < sz) then
  begin
   Val(Copy(File_Name, i + 1, sz - i), F_NumOfTrack, oftmp);
   if (oftmp <> 0) or (F_NumOfTrack < 0) then
     F_NumOfTrack := -1
   else
     SetLength(File_Name, i - 1);
  end;

 if not FileExists(File_Name) then
   Exit;

 SFileExt := LowerCase(ExtractFileExt(File_Name));

 extftype := GetFileTypeFromFNExt(SFileExt);

 if IsStreamOrModuleFileType(extftype) then
   AddOther(extftype) //todo added :=
 {$IFDEF Windows}
 else if IsMIDIFileType(extftype) then
   AddMIDI(extftype)
 else if IsCDFileType(extftype) then
   AddCD
 {$ENDIF Windows}
 else
  begin
   UniReadInit(URHandle, URFile, File_Name, nil, -1);
    try
     F_Offset := 0;
     F_Address := 0;
     F_Length := UniReadersData[URHandle]^.UniFileSize;
     if F_Length > 65536 then F_Length := 65536;
     F_Frame := @F_Buffer;
     Loaded := False;
     added := -2;
     if extftype = FT.AYM then
       added := OpenAYMFile
     else if extftype = FT.SNDH then
       added := OpenSNDHFile
     else if IsAYChipFileType(extftype) then
       added := Add(extftype, 0, -1)
     else if extftype >= 0 then //new format added to Ay_Emul.fmt
       added := -1
     else if extftype = -2 then //multiformat extension like .ay/.ym
      begin
       if SFileExt = '.ay' then
         added := OpenAYFile
       else if SFileExt = '.ym' then
         added := Add(FT.YM, 0, -1)
       else if SFileExt = '.psg' then
         added := Add(FT.PSG, 0, -1)
       else
         added := -1; //new extension or multiformat added to Ay_Emul.fmt
      end
     else if Detect then
      begin
        try
         UniRead(URHandle, @Zag, 4);
         if zag = 'ZXAY' then
          begin
           UniRead(URHandle, @Zag, 4);
           UniFileSeek(URHandle, 0); // need for OpenAYFile
           if (Zag <> 'EMUL') and (Zag <> 'AMAD') and (Zag <> 'ST11') then
             added := Add(FT.ZXAY{ZXAYFile}, 0, -1)
           else
             added := OpenAYFile;
          end
         else
          begin
           if (zag = 'PSG'#$1a) or (zag = 'EPSG') then
             added := Add(FT.PSG{PSGFile}, 0, -1)
           else if (zag = 'YM2!') or (zag = 'YM3!') or (zag = 'YM3b') or
             (zag = 'YM5!') or (zag = 'YM6!') then
             added := Add(FT.YM{YM3File}, 0, -1)
           else if (((zag[0] = 'a') and (zag[1] = 'y')) or
             ((zag[0] = 'y') and (zag[1] = 'm')) or
             ((zag[0] = 'A') and (zag[1] = 'Y')) or
             ((zag[0] = 'Y') and (zag[1] = 'M'))) and
             (zag[2] in [#0..#6]) then
             added := Add(FT.VTX{VTXFile}, 0, -1)
           else
            begin
             UniFileSeek(URHandle, 2);
             UniRead(URHandle, @LHZag, 5);
             if LHZag = '-lh5-' then
               added := Add(FT.YM{YM3File}, 0, -1)
             else if not May_Quit2 then
              begin
               Init_Detector;
                try
                 while Module_Detector(False) do
                  begin
                   n := Add(FType, FTime, FLoop, False);
                   //todo: to redraw only once we redraw only previously found item, not so good...
                   F_Address := 0;
                   if n < 0 then
                     continue;
                   if FType = FT.STF then
                     PlayListItems[n]^.Title := CPToUTF8(Trim(FTitle));

                   Inc(F_Offset, F_Length - 1);
                   Inc(F_Index, F_Length - 1);
                   Dec(Readen1, F_Length - 1);
                   //check for TS
                   if (F_Offset_Prev + F_Length_Prev = F_Offset - F_Length + 1) and
                     Module_Detector(True) and
                     (PlayListItems[n - 1]^.FileType = FType1) and
                     (PlayListItems[n]^.FileType = FType2) and
                     (PlayListItems[n - 1]^.Length = PTSData(F_Frame)^.Size1) and
                     (PlayListItems[n]^.Length = PTSData(F_Frame)^.Size2) then
                    begin
                     F_Length_Prev := -1;
                     F_Offset_Prev := 0;
                     PlayListItems[n - 1]^.Next := PlayListItems[n];
                     SetLength(PlayListItems, n);
                     Inc(F_Offset, 16 - 1);
                     Inc(F_Index, 16 - 1);
                     Dec(Readen1, 16 - 1);
                    end
                   else
                    begin
                     F_Length_Prev := F_Length;
                     F_Offset_Prev := F_Offset - F_Length + 1;
                     Check_PlayerTags;
                     for i := 0 to Length(ImageCatalog) - 1 do
                       with ImageCatalog[i] do
                         if (F_Offset_Prev >= Offset) and
                           (F_Offset_Prev + F_Length <= Offset + Size) then
                          begin
                           PlayListItems[n]^.Programm :=
                             ImageID + ExtractFileName(File_Name) + '->' + Name;
                           if (PlayListItems[n]^.Author = '') and
                             (PlayListItems[n]^.Title = '') then
                            begin
                             PlayListItems[n]^.Title := Name;
                             //                        RedrawItem(n); //todo better
                            end;
                           break;
                          end;
                    end;
                   if n > FirstAdded then //todo better
                    begin
                     RedrawItem(n - 1);
                     CalculatePlaylistScrollBar;
                    end;
                  end;
                finally
                 LongProcessDone;
                end;
               if FirstAdded < Length(PlayListItems) then //todo better
                begin
                 RedrawItem(Length(PlayListItems) - 1);
                 CalculatePlaylistScrollBar;
                end;
              end;
            end;
          end;
        except
        end;
      end;
     if added = -1 then //unhandled errors
       raise EAddFileError.Create(Mes_UnhandledErrorAddFile);
    finally
     UniReadClose(URHandle);
    end;
  end;
end;

procedure FindModules;
var
 F_: boolean;
 DistDir, String1: string;
 F_In, F_Out: file;
 FTime, FLoop, F_Offset: integer;
 F_Index: integer;
 FilSiz, Readen2, F_Point: integer;
 F_Buffer: array[0..65536 * 2 - 1] of byte;
 Index, Sz, SzT, offs: integer;
 Buffer: ModTypes;
begin
 FinderWorksNow := True;
 with FrmTools do
  begin
   F_ := F_STF or F_ST1 or F_STC or F_ST3 or F_STP or F_ASM0 or F_ASM1 or
     F_PSC or F_PT1 or F_PT2 or F_PT3 or F_FTC or F_FLS or F_SQT or F_GTR;
   if not F_ then
    begin
     AllEnable;
     Exit;
    end;
   DistDir := DESrchWrkFld.Directory;
   if not ForceDirectories(DistDir) then
    begin
     AllEnable;
     MReport.Lines.Add(Mes_CantCreateDestFolder);
     exit;
    end;
   DistDir := IncludeTrailingPathDelimiter(DistDir);
  end;
 May_Quit := False;
 for Index := 0 to FrmTools.MSrchFiles.Lines.Count - 1 do
  begin
   AssignFile(F_In, FrmTools.MSrchFiles.Lines.Strings[Index]);
   {$i-}
   Reset(F_In, 1);
   {$i+}
   if IOResult <> 0 then
    begin
     FrmTools.MReport.Lines.Add(IntToStr(Index) + '. ' + Mes_File +
       ' "' + FrmTools.MSrchFiles.Lines.Strings[Index] + '" ' +
       Mes_notFoundOrDenied + '.');
    end
   else
    begin
     FrmTools.MReport.Lines.Add(IntToStr(Index) + '. ' + Mes_AnalisisOfFile +
       '  "' + FrmTools.MSrchFiles.Lines.Strings[Index] + '".');
     F_Offset := -1;
     F_Index := 65535;
     FilSiz := System.FileSize(F_In) - 1;
     FrmTools.PBSearching.Max := FilSiz + 1;
     FrmTools.PBSearching.Position := 0;
     System.blockread(F_In, F_Buffer[65536], 65536, Readen1);
     F_PlayerTag.TagType := F_Tag_No;
     may_quit := False;
     F_Point := 1024;
     repeat
       Inc(F_Offset);
       Inc(F_Index);
       Dec(Readen1);
       if F_Index >= 65536 then
        begin
         move(F_Buffer[65536], F_Buffer, 65536);
         Dec(F_Index, 65536);
         System.blockread(F_In, F_Buffer[65536], 65536, Readen2);
         Inc(Readen1, Readen2);
        end;
       F_Frame := @PArray0OfByte(@F_Buffer)[F_Index];
       FTime := 0;
       FLoop := 0;
       F_Address := 0;
       if F_STP and FoundSTP_PlayerTags(offs) then
        begin
         F_PlayerTag.Player_Offset := F_Offset;
         F_PlayerTag.TagType := F_Tag_STP;
         SetLength(F_PlayerTag.Value, Length(KsaId) + 25);
         Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(KsaId) + 25);
        end
       else if (F_ASM1 or F_ASM0) and FoundASC_PlayerTags(offs) then
        begin
         F_PlayerTag.Player_Offset := F_Offset;
         F_PlayerTag.TagType := F_Tag_ASC;
         SetLength(F_PlayerTag.Value, Length(AscId) + 20 + 4 + 20);
         Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(AscId) + 20 + 4 + 20);
        end
       else if F_STC and FoundSTC_PlayerTags(offs) then
        begin
         F_PlayerTag.Player_Offset := F_Offset;
         F_PlayerTag.TagType := F_Tag_STC;
         SetLength(F_PlayerTag.Value, Length(StcId) + 10 + 4 + 12);
         Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(StcId) + 10 + 4 + 12);
        end
       else if F_ST3 and FoundST3_PlayerTags(offs) then
        begin
         F_PlayerTag.Player_Offset := F_Offset;
         F_PlayerTag.TagType := F_Tag_ST3;
         SetLength(F_PlayerTag.Value, Length(KsaId) + 27);
         Move(F_Frame^.Index[offs], F_PlayerTag.Value[1], Length(KsaId) + 27);
        end;
       if F_STC and FoundSTC(FTime, FLoop) and
         LoadTrackerModule(Buffer, nil, -1, 0, F_Length, F_Frame, FT.STC) then
        begin
         FrmTools.MReport.Lines.Add('Sound Tracker Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.stc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, F_Length);
         closefile(F_Out);
         if F_PlayerTag.TagType = F_Tag_STC then
           if MatchPlayerLength(F_Tag_STC, F_Offset - F_PlayerTag.Player_Offset) then
            begin
             Sz := F_Length;
             InsertTitleSTC(Buffer, Sz, F_PlayerTag.Value);
             if Sz <> F_Length then
              begin
               AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
                 IntToHex(F_Offset, 8) + '-tag.stc');
               rewrite(F_Out, 1);
               blockwrite(F_Out, Buffer, Sz);
               closefile(F_Out);
              end;
            end;
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_ASM1 and FoundASC1(FTime, FLoop) and
         LoadTrackerModule(Buffer, nil, -1, 0, F_Length, F_Frame, FT.ASC) then
        begin
         FrmTools.MReport.Lines.Add('ASM 1.xx Offset ' + IntToHex(F_Offset, 8) +
           ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.asc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, F_Length);
         closefile(F_Out);
         if F_PlayerTag.TagType = F_Tag_ASC then
           if MatchPlayerLength(F_Tag_ASC, F_Offset - F_PlayerTag.Player_Offset) then
            begin
             Sz := F_Length;
             InsertTitleASC(Buffer, Sz, F_PlayerTag.Value);
             if Sz <> F_Length then
              begin
               AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
                 IntToHex(F_Offset, 8) + '-tag.asc');
               rewrite(F_Out, 1);
               blockwrite(F_Out, Buffer, Sz);
               closefile(F_Out);
              end;
            end;
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_ASM0 and FoundASC0(FTime, FLoop) and
         LoadTrackerModule(Buffer, nil, -1, 0, F_Length, F_Frame, FT.ASC0) then
        begin
         FrmTools.MReport.Lines.Add('ASM 0.xx Offset ' + IntToHex(F_Offset, 8) +
           ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.asc');
         rewrite(F_Out, 1);
{    blockwrite(F_Out,Buffer,1);
    blockwrite(F_Out,Zero,1);
    inc(F_Frame^.ASC0_PatternsPointers);
    inc(F_Frame^.ASC0_SamplesPointers);
    inc(F_Frame^.ASC0_OrnamentsPointers);
    blockwrite(F_Out,F_Frame^.ASC0_PatternsPointers,F_Length-1);}
         blockwrite(F_Out, Buffer, F_Length + 1);
         closefile(F_Out);
         if F_PlayerTag.TagType = F_Tag_ASC then
           if MatchPlayerLength(F_Tag_ASC, F_Offset - F_PlayerTag.Player_Offset) then
            begin
             Sz := F_Length + 1;
             InsertTitleASC(Buffer, Sz, F_PlayerTag.Value);
             if Sz <> F_Length + 1 then
              begin
               AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
                 IntToHex(F_Offset, 8) + '-tag.asc');
               rewrite(F_Out, 1);
               blockwrite(F_Out, Buffer, Sz);
               closefile(F_Out);
              end;
            end;
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_STP and FoundSTP(FTime, FLoop) and
         LoadTrackerModule(Buffer, nil, -1, F_Address, F_Length, F_Frame, FT.STP) then
        begin
         FrmTools.MReport.Lines.Add('Sound Tracker Pro Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.stp');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, F_Length);
         closefile(F_Out);
         if F_PlayerTag.TagType = F_Tag_STP then
           if MatchPlayerLength(F_Tag_STP, F_Offset - F_PlayerTag.Player_Offset) then
            begin
             Sz := F_Length;
             InsertTitleSTP(Buffer, Sz, F_PlayerTag.Value);
             if Sz <> F_Length then
              begin
               AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
                 IntToHex(F_Offset, 8) + '-tag.stp');
               rewrite(F_Out, 1);
               blockwrite(F_Out, Buffer, Sz);
               closefile(F_Out);
              end;
            end;
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_PT2 and FoundPT2(FTime, FLoop) then
        begin
         if F_Address <> 0 then
           String1 := 'Phantom Family Pro Tracker 2.4'
         else
           String1 := 'Pro Tracker 2.xx';
         FrmTools.MReport.Lines.Add(String1 + ' Offset ' + IntToHex(F_Offset, 8) +
           ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.pt2');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_PT3 and FoundPT3(False,FTime, FLoop) then
        begin
         String1 := 'Pro Tracker 3.xx';
         FrmTools.MReport.Lines.Add(String1 + ' Offset ' + IntToHex(F_Offset, 8) +
           ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.pt3');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_PT3 and FoundPT3(True,FTime, FLoop) then
        begin
         if F_Address <> 0 then
           String1 := 'Pro Tracker 3.x Utility'
         else
           String1 := 'Pro Tracker 3.xx';
         FrmTools.MReport.Lines.Add(String1 + ' Offset ' + IntToHex(F_Offset, 8) +
           ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.pt3');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_PSC and FoundPSC(False, FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('Pro Sound Creator v1.04-1.07 Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.psc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_PSC and FoundPSC(True, FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('Pro Sound Creator v1.00-1.03 Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.psc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_FTC and FoundFTC(FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('Fast Tracker Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.ftc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_PT1 and FoundPT1(FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('Pro Tracker v1.xx Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.pt1');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_SQT and FoundSQT(FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('SQ-Tracker Offset ' + IntToHex(F_Offset, 8) +
           ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.sqt');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
       if F_GTR and FoundGTR(FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('Global Tracker Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.gtr');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end
       else
(*    if F_FXM and FoundFXM(FTime,FLoop) then begin
    FrmTools.MReport.Lines.Add('Fuxoft AY Language Offset '+ IntToHex(F_Offset,8)+
                                    ' Length '+IntToHex(F_Length,4));
    AssignFile(F_Out,DistDir+IntToHex(Index,3)+'_'+IntToHex(F_Offset,8)+'.fxm');
    rewrite(F_Out,1);
    FXMSID.Ch := 'FXSM';
    FXMSID.Addr := F_Address;
    blockwrite(F_Out,FXMSID,6);
    blockwrite(F_Out,F_Frame^,F_Length);
    inc(F_Offset,F_Length-1);
    inc(F_Index,F_Length-1);
    dec(Readen1,F_Length-1);
    closefile(F_Out);end else*)
       if F_STF and FoundSTF(FTime, FLoop, String1) and
         LoadTrackerModule(Buffer, nil, -1, 0, F_Length, F_Frame, FT.STF) then
        begin
         FrmTools.MReport.Lines.Add('Sound Tracker Pro Uncompiled Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.stf');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         closefile(F_Out);
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.stp');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, Buffer.STP_SamplesPointer + 30);
         closefile(F_Out);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_ST1 and FoundST1(FTime, FLoop) and
         LoadTrackerModule(Buffer, nil, -1, 0, F_Length, F_Frame, FT.ST1) then
        begin
         FrmTools.MReport.Lines.Add('Sound Tracker Uncompiled Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.st1');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         closefile(F_Out);
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.stc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, Buffer.ST_Size);
         closefile(F_Out);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_ST3 and FoundST3(FTime, FLoop) and
         LoadTrackerModule(Buffer, nil, -1, 0, F_Length, F_Frame, FT.ST3) then
        begin
         FrmTools.MReport.Lines.Add('Sound Tracker 3 Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.stc');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, Buffer.ST_Size);
         closefile(F_Out);
         if (F_PlayerTag.TagType = F_Tag_ST3) and
           MatchPlayerLength(F_Tag_ST3, F_Offset - F_PlayerTag.Player_Offset) then
           String1 := F_PlayerTag.Value
         else
          begin
           String1 := F_Frame^.ST3_Title;
           if Trim(String1) = Trim(KsaId) then
             String1 := '';
          end;
         if String1 <> '' then
          begin
           Sz := Buffer.ST_Size;
           SzT := Sz;
           InsertTitleSTC(Buffer, Sz, String1);
           if Sz <> SzT then
            begin
             AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
               IntToHex(F_Offset, 8) + '-tag.stc');
             rewrite(F_Out, 1);
             blockwrite(F_Out, Buffer, Sz);
             closefile(F_Out);
            end;
          end;
         Move(F_Frame^, Buffer, F_Length);
         PrepareToSaveST3(Buffer, Sz);
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.st3');
         rewrite(F_Out, 1);
         blockwrite(F_Out, Buffer, F_Length);
         closefile(F_Out);
         if F_PlayerTag.TagType = F_Tag_ST3 then
           if MatchPlayerLength(F_Tag_ST3, F_Offset - F_PlayerTag.Player_Offset) then
            begin
             Sz := F_Length;
             InsertTitleST3(Buffer, Sz, F_PlayerTag.Value);
             if Sz <> F_Length then
              begin
               AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
                 IntToHex(F_Offset, 8) + '-tag.st3');
               rewrite(F_Out, 1);
               blockwrite(F_Out, Buffer, Sz);
               closefile(F_Out);
              end;
            end;
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
        end
       else
       if F_FLS and FoundFLS(FTime, FLoop) then
        begin
         FrmTools.MReport.Lines.Add('Flash Tracker Offset ' +
           IntToHex(F_Offset, 8) + ' Length ' + IntToHex(F_Length, 4));
         AssignFile(F_Out, DistDir + IntToHex(Index, 3) + '_' +
           IntToHex(F_Offset, 8) + '.fls');
         rewrite(F_Out, 1);
         blockwrite(F_Out, F_Frame^, F_Length);
         Inc(F_Offset, F_Length - 1);
         Inc(F_Index, F_Length - 1);
         Dec(Readen1, F_Length - 1);
         closefile(F_Out);
        end;
       if F_Offset > F_Point then
        begin
         FrmTools.PBSearching.Position := F_Offset;
         F_Point := F_Offset + 1024;
         Application.ProcessMessages;
        end;
     until may_quit or (F_Offset >= FilSiz);
     FrmTools.PBSearching.Position := F_Offset + 1;
     closefile(F_In);
     if may_quit then
      begin
       FrmTools.MReport.Lines.Add(Mes_UserInterrupted);
       break;
      end;
    end;
  end;
 FrmTools.AllEnable;
end;

//Set Real_End[CNum] depending of Do_Loop and Force_Loop
//(need for continue playback shorter module of TS-pair)
function CheckLoopAndStop(CNum: integer): boolean;
begin
 if PlConsts[CNum].Global_Tick_Counter >= PlConsts[CNum].Global_Tick_Max then
  begin
   if Do_Loop or Force_Loop then
     PlConsts[CNum].Global_Tick_Counter := PlConsts[CNum].Global_Tick_Max;
   if not Do_Loop then
    begin
     Real_End[CNum] := True;
     if not Force_Loop then
       Exit(True);
    end;
  end;
 Result := False;
end;

procedure MakeBufferOUT(Buf: pointer);
begin
 BuffLen := 0;
 if IntFlag then
  begin
   SynthesizerOUT(Buf);
   if IntFlag then exit;
   if (ZX_Takt <> -1) and ((ZX_Port and PortMask) = ($BFFD and PortMask)) then
     SoundChip[0].SetAYRegister(SoundChip[0].Current_RegisterAY, ZX_Port_Data);
  end;
 with UniReadersData[FileHandle]^ do
   if UniFilePos = UniFileSize then
     if not Do_Loop then
      begin
       Real_End_All := True;
       exit;
      end
     else
      begin
       InitForAllTypes(False);
       //1st frame of OUT commonly has no info about all 14 registers, so
       //reset it to repeat sound completely after looping
       ResetAYChipEmulation(0, True);
      end;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   UniRead(FileHandle, @ZX_Takt, 2);
   UniRead(FileHandle, @ZX_Port, 2);
   UniRead(FileHandle, @ZX_Port_Data, 1);
   if (ZX_Takt = -1) or (ZX_Takt = 0) then SynthesizerOUT(Buf);
   if ZX_Takt <> -1 then
     if (ZX_Port and PortMask) = ($FFFD and PortMask) then
       SoundChip[0].Current_RegisterAY := ZX_Port_Data
     else if (ZX_Port and PortMask) = ($BFFD and PortMask) then
      begin
       if ZX_Takt <> 0 then SynthesizerOUT(Buf);
       if not IntFlag then
         SoundChip[0].SetAYRegister(SoundChip[0].Current_RegisterAY, ZX_Port_Data);
      end;
   with UniReadersData[FileHandle]^ do
     if (UniFilePos >= UniFileSize) and (not IntFlag) then
       if not Do_Loop then
         Real_End_All := True
       else
        begin
         InitForAllTypes(False);
         //1st frame of OUT commonly has no info about all 14 registers, so
         //reset it to repeat sound completely after looping
         ResetAYChipEmulation(0, True);
        end;
  end;
end;

procedure OUT_Get_Registers(CNum: integer);
var
 ZX_Takt2: smallint;
 Number_Of_Takts: smallint;
begin
 with UniReadersData[FileHandle]^ do
   if UniFilePos = UniFileSize then
     exit;
 repeat
   if not IntFlag then
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
     if Number_Of_Takts <= 0 then
       Inc(Number_Of_Takts, 17472);
     Inc(OUTZXAYConv_TotalTime, Number_Of_Takts);
    end;

   IntFlag := False;
   if OUTZXAYConv_TotalTime >= MaxTStates then
    begin
     Dec(OUTZXAYConv_TotalTime, MaxTStates);
     IntFlag := True;
     exit;
    end;
   if ZX_Takt <> -1 then
     if (ZX_Port and PortMask) = ($FFFD and PortMask) then
       SoundChip[0].Current_RegisterAY := ZX_Port_Data
     else if (ZX_Port and PortMask) = ($BFFD and PortMask) then
       SoundChip[0].SetAYRegister(SoundChip[0].Current_RegisterAY, ZX_Port_Data)
 until UniReadersData[FileHandle]^.UniFilePos >=
   UniReadersData[FileHandle]^.UniFileSize;
end;

procedure MakeBufferEPSG(Buf: pointer);
var
 EPSGRec: TEPSGRec;
begin
 BuffLen := 0;
 if IntFlag then
  begin
   SynthesizerEPSG(Buf);
   if IntFlag then exit;
   if Flg <> 0 then
     SoundChip[0].SetAYRegister(AY_Reg, AY_Data);
  end;
 if UniReadersData[FileHandle]^.UniFilePos >=
   UniReadersData[FileHandle]^.UniFileSize then
   if not Do_Loop then
    begin
     Real_End_All := True;
     exit;
    end
   else
    begin
     InitForAllTypes(False);
     //1st frame of EPSG commonly has no info about all 14 registers, so
     //reset it to repeat sound completely after looping
     ResetAYChipEmulation(0, True);
    end;
 EPSGRec.All := 0;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   UniRead(FileHandle, @EPSGRec, 5);
   if EPSGRec.All = $FFFFFFFFFF then
    begin
     Inc(PlConsts[0].Global_Tick_Counter);
     Flg := 0;
     AY_Takt := 0;
     Dec(Previous_AY_Takt, EPSG_TStateMax);
     SynthesizerEPSG(Buf);
    end
   else
    begin
     Flg := 1;
     with EPSGRec do
      begin
       AY_Reg := Reg;
       AY_Data := Data;
       AY_Takt := TSt;
      end;
     SynthesizerEPSG(Buf);
     if not IntFlag then
       SoundChip[0].SetAYRegister(AY_Reg, AY_Data);
    end;
   if (UniReadersData[FileHandle]^.UniFilePos >=
     UniReadersData[FileHandle]^.UniFileSize) and not IntFlag then
     if not Do_Loop then
       Real_End_All := True
     else
      begin
       InitForAllTypes(False);
       //1st frame of EPSG commonly has no info about all 14 registers, so
       //reset it to repeat sound completely after looping
       ResetAYChipEmulation(0, True);
      end;
  end;
end;

procedure EPSG_Get_Registers(CNum: integer);
var
 EPSGRec: TEPSGRec;
begin
 if (UniReadersData[FileHandle]^.UniFilePos >=
   UniReadersData[FileHandle]^.UniFileSize) then
   exit;
 EPSGRec.All := 0;
 repeat
   UniRead(FileHandle, @EPSGRec, 5);
   if EPSGRec.All <> $FFFFFFFFFF then
     with EPSGRec do
       SoundChip[0].SetAYRegister(Reg, Data)
 until (UniReadersData[FileHandle]^.UniFilePos >=
     UniReadersData[FileHandle]^.UniFileSize) or (EPSGRec.All = $FFFFFFFFFF);
end;

procedure MakeBufferPSG(Buf: pointer);
begin
 BuffLen := 0;
 if IntFlag then SynthesizerZX50(Buf);
 if IntFlag then exit;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   PSG_Get_Registers(0);
   if not Real_End_All then SynthesizerZX50(Buf);
  end;
end;

procedure PSG_Get_Registers(CNum: integer);
var
 b, b2: byte;
begin
 if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
   if Do_Loop then
     PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
   else
    begin
     Real_End_All := True;
     Exit;
    end;
 Inc(PlConsts[0].Global_Tick_Counter);
 if PSG_Skip > 0 then
  begin
   Dec(PSG_Skip);
   Exit;
  end;
 if UniReadersData[FileHandle]^.UniFileSize <= 16 then
   Exit;
 if (UniReadersData[FileHandle]^.UniFilePos >=
   UniReadersData[FileHandle]^.UniFileSize) or (PSG_Skip < 0) then
  begin
   InitForAllTypes(False);
   //1st frame of PSG commonly has no info about all 14 registers, so
   //reset it to repeat sound completely after looping
   ResetAYChipEmulation(0, True);
  end;

 repeat
   UniRead(FileHandle, @b, 1);
   case b of
     255://Interrupt marker
       Exit;
     254://Skip frames
      begin
       if UniReadersData[FileHandle]^.UniFilePos <
         UniReadersData[FileHandle]^.UniFileSize then
        begin
         UniRead(FileHandle, @b, 1);
         PSG_Skip := b * 4 - 1;
        end;
       Exit;
      end;
     253://End of music (introduced in RDOSPLAY, realized in zxtune123,
       //so forced to support in Ay_Emul)
      begin
       PSG_Skip := -1;
       Exit;
      end
   else
     if UniReadersData[FileHandle]^.UniFilePos <
       UniReadersData[FileHandle]^.UniFileSize then
      begin
       UniRead(FileHandle, @b2, 1);
       if b < 14 then
        begin
         case b of
           13: SoundChip[0].SetEnvelopeRegister(b2 and 15);
           1, 3, 5:
             SoundChip[0].RegisterAY.Index[b] := b2 and 15;
           6: SoundChip[0].RegisterAY.Noise := b2 and 31;
           7: SoundChip[0].SetMixerRegister(b2 and 63);
           8: SoundChip[0].SetAmplA(b2 and 31);
           9: SoundChip[0].SetAmplB(b2 and 31);
           10: SoundChip[0].SetAmplC(b2 and 31);
         else
           SoundChip[0].RegisterAY.Index[b] := b2;
          end;
        end;
      end;
    end;
 until UniReadersData[FileHandle]^.UniFilePos >=
   UniReadersData[FileHandle]^.UniFileSize;
end;

procedure MakeBufferZXAY(Buf: pointer);
var
 tmp: integer;
begin
 BuffLen := 0;
 if IntFlag then
  begin
   SynthesizerZXAY(Buf);
   if IntFlag then exit;
   SoundChip[0].SetAYRegisterFast(AY_Reg, AY_Data);
  end;
 if UniReadersData[FileHandle]^.UniFilePos >=
   UniReadersData[FileHandle]^.UniFileSize then
   if not Do_Loop then
    begin
     Real_End_All := True;
     exit;
    end
   else
    begin
     InitForAllTypes(False);
     //1st frame of ZXAY commonly has no info about all 14 registers, so
     //reset it to repeat sound completely after looping
     ResetAYChipEmulation(0, True);
    end;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   UniRead(FileHandle, @tmp, 4);
   AY_Takt := tmp and $FFFFF;
   AY_Reg := (tmp shr 20) and 15;
   AY_Data := tmp shr 24;
   SynthesizerZXAY(Buf);
   if not IntFlag then
     SoundChip[0].SetAYRegisterFast(AY_Reg, AY_Data);
   if (UniReadersData[FileHandle]^.UniFilePos >=
     UniReadersData[FileHandle]^.UniFileSize) and not IntFlag then
     if not Do_Loop then
       Real_End_All := True
     else
      begin
       InitForAllTypes(False);
       //1st frame of ZXAY commonly has no info about all 14 registers, so
       //reset it to repeat sound completely after looping
       ResetAYChipEmulation(0, True);
      end;
  end;
end;

procedure ZXAY_Get_Registers(CNum: integer);
var
 AY_Takt: longint;
 Number_Of_Takts, tmp: longint;
begin
 with UniReadersData[FileHandle]^ do
   if UniFilePos = UniFileSize then
     exit;
 repeat
   if not IntFlag then
    begin
     UniRead(FileHandle, @tmp, 4);
     AY_Takt := tmp and $FFFFF;
     AY_Reg := (tmp shr 20) and 15;
     AY_Data := tmp shr 24;
     Number_Of_Takts := AY_Takt - Previous_AY_Takt;
     Previous_AY_Takt := AY_Takt;
     if (Number_Of_Takts <= 0) then Inc(Number_Of_Takts, $100000);
     Inc(OUTZXAYConv_TotalTime, Number_Of_Takts);
    end;
   IntFlag := False;
   if OUTZXAYConv_TotalTime >= MaxTStates then
    begin
     Dec(OUTZXAYConv_TotalTime, MaxTStates);
     IntFlag := True;
     exit;
    end;
   SoundChip[0].SetAYRegisterFast(AY_Reg, AY_Data);
 until UniReadersData[FileHandle]^.UniFilePos = UniReadersData[FileHandle]^.UniFileSize;
end;

procedure PT2_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: PT2_Channel_Parameters);
 var
   quit, gliss: boolean;
 begin
   quit := False;
   gliss := False;
   with Chan, PLConsts[CNum].RAM^ do
    begin
     repeat
       case Index[Chan.Address_In_Pattern] of
         $e1..$ff:
          begin
           SamplePointer := PT2_SamplesPointers[Index[Address_In_Pattern] - $e0];
           Sample_Length := Index[SamplePointer];
           Inc(SamplePointer);
           Loop_Sample_Position := Index[SamplePointer];
           Inc(SamplePointer);
          end;
         $e0:
          begin
           Position_In_Sample := 0;
           Position_In_Ornament := 0;
           Current_Ton_Sliding := 0;
           GlissType := 0;
           Enabled := False;
           quit := True;
          end;
         $80..$df:
          begin
           Position_In_Sample := 0;
           Position_In_Ornament := 0;
           Current_Ton_Sliding := 0;
           if gliss then
            begin
             Slide_To_Note := Index[Address_In_Pattern] - $80;
             if GlissType = 1 then Note := Slide_To_Note;
            end
           else
            begin
             Note := Index[Address_In_Pattern] - $80;
             GlissType := 0;
            end;
           Enabled := True;
           quit := True;
          end;
         $7f:
           Envelope_Enabled := False;
         $71..$7e:
          begin
           Envelope_Enabled := True;
           SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $70);
           Inc(Address_In_Pattern);
           SoundChip[CNum].RegisterAY.Index[11] := Index[Address_In_Pattern];
           Inc(Address_In_Pattern);
           SoundChip[CNum].RegisterAY.Index[12] := Index[Address_In_Pattern];
          end;
         $70:
           quit := True;
         $60..$6f:
          begin
           OrnamentPointer := PT2_OrnamentsPointers[Index[Address_In_Pattern] - $60];
           Ornament_Length := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Loop_Ornament_Position := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Position_In_Ornament := 0;
          end;
         $20..$5f:
           Number_Of_Notes_To_Skip := Index[Address_In_Pattern] - $20;
         $10..$1f:
           Volume := Index[Address_In_Pattern] - $10;
         $f:
          begin
           Inc(Address_In_Pattern);
           PlParams[CNum].PT2.Delay := Index[Address_In_Pattern];
          end;
         $e:
          begin
           Inc(Address_In_Pattern);
           Glissade := Index[Address_In_Pattern];
           GlissType := 1;
           gliss := True;
          end;
         $d:
          begin
           Inc(Address_In_Pattern);
           Glissade := Abs(shortint(Index[Address_In_Pattern]));
{      Inc(Address_In_Pattern);
      Ton_Delta := Index[Address_In_Pattern];
      Inc(Address_In_Pattern);
      Inc(Ton_Delta,word(Index[Address_In_Pattern])shl 8);}
           Inc(Address_In_Pattern, 2); //Not use precalculated Ton_Delta
           //to avoide error with first note of pattern
           GlissType := 2;
           gliss := True;
          end;
         $c:
           GlissType := 0
       else
        begin
         Inc(Address_In_Pattern);
         Addition_To_Noise := Index[Address_In_Pattern];
        end
        end;
       Inc(Address_In_Pattern)
     until quit;
     {Alternative Ton_Delta calc begin}
     if gliss and (GlissType = 2) then
      begin
       Ton_Delta := Abs(PT3NoteTable_ST[Slide_To_Note] - PT3NoteTable_ST[Note]);
       if Slide_To_Note > Note then Glissade := -Glissade;
      end;
     {Alternative Ton_Delta calc end}
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

 procedure GetRegisters(var Chan: PT2_Channel_Parameters);
 var
   j, b0, b1: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Enabled then
      begin
       b0 := Index[SamplePointer + Position_In_Sample * 3];
       b1 := Index[SamplePointer + Position_In_Sample * 3 + 1];
       Ton := Index[SamplePointer + Position_In_Sample * 3 + 2] +
         word(b1 and 15) shl 8;
       if b0 and 4 = 0 then Ton := -Ton;
       j := Note + Index[OrnamentPointer + Position_In_Ornament];
       if shortint(j) < 0 then j := 0
       else if j > 95 then j := 95;
       Ton := (Ton + Current_Ton_Sliding + PT3NoteTable_ST[j]) and $fff;
       if GlissType = 2 then
        begin
         Ton_Delta := Ton_Delta - Abs(Glissade);
         if Ton_Delta < 0 then
          begin
           Note := Slide_To_Note;
           GlissType := 0;
           Current_Ton_Sliding := 0;
          end;
        end;
       if GlissType <> 0 then Inc(Current_Ton_Sliding, Glissade);
       Amplitude := round((Volume * 17 + Ord(Volume > 7)) * byte(b1 shr 4) / 256);
       if Envelope_Enabled then Amplitude := Amplitude or 16;
       if b0 and 1 <> 0 then
         TempMixer := TempMixer or 64
       else
         SoundChip[CNum].RegisterAY.Noise := (b0 shr 3 + byte(Addition_To_Noise)) and 31;
       if b0 and 2 <> 0 then
         TempMixer := TempMixer or 8;
       Inc(Position_In_Sample);
       if Position_In_Sample = Sample_Length then
         Position_In_Sample := Loop_Sample_Position;
       Inc(Position_In_Ornament);
       if Position_In_Ornament = Ornament_Length then
         Position_In_Ornament := Loop_Ornament_Position;
      end
     else
       Amplitude := 0;
    end;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].PT2 do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].PT2_A, PLConsts[CNum].RAM^ do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
        begin
         if (Index[Address_In_Pattern] = 0) then
          begin
           Inc(CurrentPosition);
           if CurrentPosition = PT2_NumberOfPositions then
             CurrentPosition := PT2_LoopPosition;
           Address_In_Pattern :=
             PWord(@Index[PT2_PatternsPointer +
             PT2_PositionList[CurrentPosition] * 6])^;
           PlParams[CNum].PT2_B.Address_In_Pattern :=
             PWord(@Index[PT2_PatternsPointer +
             PT2_PositionList[CurrentPosition] * 6 + 2])^;
           PlParams[CNum].PT2_C.Address_In_Pattern :=
             PWord(@Index[PT2_PatternsPointer +
             PT2_PositionList[CurrentPosition] * 6 + 4])^;
          end;
         PatternInterpreter(PlParams[CNum].PT2_A);
        end;
      end;
     with PlParams[CNum].PT2_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].PT2_B);
      end;
     with PlParams[CNum].PT2_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].PT2_C);
      end;
     DelayCounter := Delay;
    end;
   TempMixer := 0;
   GetRegisters(PlParams[CNum].PT2_A);
   GetRegisters(PlParams[CNum].PT2_B);
   GetRegisters(PlParams[CNum].PT2_C);

   SoundChip[CNum].SetMixerRegister(TempMixer);

   SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].PT2_A.Ton;
   SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].PT2_B.Ton;
   SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].PT2_C.Ton;

   SoundChip[CNum].SetAmplA(PlParams[CNum].PT2_A.Amplitude);
   SoundChip[CNum].SetAmplB(PlParams[CNum].PT2_B.Amplitude);
   SoundChip[CNum].SetAmplC(PlParams[CNum].PT2_C.Amplitude);

   Inc(PlConsts[CNum].Global_Tick_Counter);
  end;
end;

procedure STC_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: STC_Channel_Parameters);
 var
   k: word;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     repeat
       case Index[Address_In_Pattern] of
         0..$5f:
          begin
           Note := Index[Address_In_Pattern];
           Sample_Tik_Counter := 32;
           Position_In_Sample := 0;
           Inc(Address_In_Pattern);
           break;
          end;
         $60..$6f:
          begin
           k := 0;
           while Index[$1b + $63 * k] <> (Index[Address_In_Pattern] - $60) do
             Inc(k);
           SamplePointer := $1c + $63 * k;
          end;
         $70..$7f:
          begin
           k := 0;
           while Index[ST_OrnamentsPointer + $21 * k] <>
             (Index[Address_In_Pattern] - $70) do
             Inc(k);
           OrnamentPointer := ST_OrnamentsPointer + $21 * k + 1;
           Envelope_Enabled := False;
          end;
         $80:
          begin
           Sample_Tik_Counter := -1;
           Inc(Address_In_Pattern);
           break;
          end;
         $81:
          begin
           Inc(Address_In_Pattern);
           break;
          end;
         $82:
          begin
           k := 0;
           while Index[ST_OrnamentsPointer + $21 * k] <> 0 do Inc(k);
           OrnamentPointer := ST_OrnamentsPointer + $21 * k + 1;
           Envelope_Enabled := False;
          end;
         $83..$8e:
          begin
           SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $80);
           Inc(Address_In_Pattern);
           SoundChip[CNum].RegisterAY.Index[11] := Index[Address_In_Pattern];
           Envelope_Enabled := True;
           k := 0;
           while Index[ST_OrnamentsPointer + $21 * k] <> 0 do Inc(k);
           OrnamentPointer := ST_OrnamentsPointer + $21 * k + 1;
          end
       else
         Number_Of_Notes_To_Skip := Index[Address_In_Pattern] - $a1;
        end;
       Inc(Address_In_Pattern)
     until False;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

 procedure GetRegisters(var Chan: STC_Channel_Parameters);
 var
   i: word;
   j: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Sample_Tik_Counter >= 0 then
      begin
       Dec(Sample_Tik_Counter);
       Position_In_Sample := (Position_In_Sample + 1) and $1f;
       if Sample_Tik_Counter = 0 then
         if Index[SamplePointer + $60] <> 0 then
          begin
           Position_In_Sample := Index[SamplePointer + $60] and $1f;
           Sample_Tik_Counter := Index[SamplePointer + $61] + 1;
          end
         else
           Sample_Tik_Counter := -1;
      end;
     if Sample_Tik_Counter >= 0 then
      begin
       i := ((Position_In_Sample - 1) and $1f) * 3 + SamplePointer;
       if Index[i + 1] and $80 <> 0 then
         TempMixer := TempMixer or 64
       else
         SoundChip[CNum].RegisterAY.Noise := Index[i + 1] and $1f;
       if Index[i + 1] and $40 <> 0 then
         TempMixer := TempMixer or 8;
       Amplitude := Index[i] and 15;
       j := Note + Index[OrnamentPointer + (Position_In_Sample - 1) and $1f] +
         PlParams[CNum].STC.Transposition;
       if j > 95 then j := 95;
       if Index[i + 1] and $20 <> 0 then
         Ton := (ST_Table[j] + Index[i + 2] + word(Index[i] and $f0) shl
           4) and $FFF
       else
         Ton := (ST_Table[j] - Index[i + 2] {%H-} - word(Index[i] and $f0) shl
           4) and $FFF;
       if Envelope_Enabled then Amplitude := Amplitude or 16;
      end
     else
       Amplitude := 0;
    end;
   TempMixer := TempMixer shr 1;
 end;

var
 i: word;
begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].STC do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
     with PLConsts[CNum].RAM^ do
      begin
       DelayCounter := ST_delay;
       with PlParams[CNum].STC_A do
        begin
         Dec(Note_Skip_Counter);
         if Note_Skip_Counter < 0 then
          begin
           if Index[Address_In_Pattern] = 255 then
            begin
             if CurrentPosition = Index[ST_PositionsPointer] then
               CurrentPosition := 0
             else
               Inc(CurrentPosition);
             Transposition := Index[ST_PositionsPointer + 2 +
               CurrentPosition * 2];
             i := 0;
             while Index[ST_PatternsPointer + 7 * i] <>
               Index[ST_PositionsPointer + 1 + CurrentPosition * 2] do
               Inc(i);
             Address_In_Pattern :=
               PWord(@Index[ST_PatternsPointer + 7 * i + 1])^;
             PlParams[CNum].STC_B.Address_In_Pattern :=
               PWord(@Index[ST_PatternsPointer + 7 * i + 3])^;
             PlParams[CNum].STC_C.Address_In_Pattern :=
               PWord(@Index[ST_PatternsPointer + 7 * i + 5])^;
            end;
           PatternInterpreter(PlParams[CNum].STC_A);
          end;
        end;
       with PlParams[CNum].STC_B do
        begin
         Dec(Note_Skip_Counter);
         if Note_Skip_Counter < 0 then
           PatternInterpreter(PlParams[CNum].STC_B);
        end;
       with PlParams[CNum].STC_C do
        begin
         Dec(Note_Skip_Counter);
         if Note_Skip_Counter < 0 then
           PatternInterpreter(PlParams[CNum].STC_C);
        end;
      end;
  end;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].STC_A);
 GetRegisters(PlParams[CNum].STC_B);
 GetRegisters(PlParams[CNum].STC_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].STC_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].STC_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].STC_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].STC_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].STC_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].STC_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure STP_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: STP_Channel_Parameters);
 var
   quit: boolean;
 begin
   quit := False;
   with Chan, PLConsts[CNum].RAM^ do
    begin
     repeat
       case Index[Address_In_Pattern] of
         1..$60:
          begin
           Note := Index[Address_In_Pattern] - 1;
           Position_In_Sample := 0;
           Position_In_Ornament := 0;
           Current_Ton_Sliding := 0;
           Enabled := True;
           quit := True;
          end;
         $61..$6f:
          begin
           SamplePointer := PWord(@Index[STP_SamplesPointer +
             (Index[Address_In_Pattern] - $61) * 2])^;
           Loop_Sample_Position := Index[SamplePointer];
           Inc(SamplePointer);
           Sample_Length := Index[SamplePointer];
           Inc(SamplePointer);
          end;
         $70..$7f:
          begin
           OrnamentPointer :=
             PWord(@Index[STP_OrnamentsPointer +
             (Index[Address_In_Pattern] - $70) * 2])^;
           Loop_Ornament_Position := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Ornament_Length := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Envelope_Enabled := False;
           Glissade := 0;
          end;
         $80..$bf:
           Number_Of_Notes_To_Skip := Index[Address_In_Pattern] - $80;
         $c0..$cf:
          begin
           if Index[Address_In_Pattern] <> $c0 then
            begin
             SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $c0);
             Inc(Address_In_Pattern);
             SoundChip[CNum].RegisterAY.Index[11] := Index[Address_In_Pattern];
            end;
           Envelope_Enabled := True;
           Loop_Ornament_Position := 0;
           Glissade := 0;
           Ornament_Length := 1;
          end;
         $D0..$DF:
          begin
           Enabled := False;
           quit := True;
          end;
         $e0..$ef:
           quit := True;
         $f0:
          begin
           Inc(Address_In_Pattern);
           Glissade := Index[Address_In_Pattern];
          end;
         $f1..$ff:
           Volume := Index[Address_In_Pattern] - $f1;
        end;
       Inc(Address_In_Pattern)
     until quit;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

 procedure GetRegisters(var Chan: STP_Channel_Parameters);
 var
   j, b0, b1: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Enabled then
      begin
       Inc(Current_Ton_Sliding, Glissade);
       if Envelope_Enabled then
         j := Note + PlParams[CNum].STP.Transposition
       else
         j := Note + PlParams[CNum].STP.Transposition +
           Index[OrnamentPointer + Position_In_Ornament];
       if j > 95 then j := 95;
       b0 := Index[SamplePointer + Position_In_Sample * 4];
       b1 := Index[SamplePointer + Position_In_Sample * 4 + 1];
       Ton := (ST_Table[j] + Current_Ton_Sliding +
         PWord(@Index[SamplePointer + Position_In_Sample * 4 + 2])^) and $fff;
       Amplitude := (b0 and 15) - Volume;
       if shortint(Amplitude) < 0 then Amplitude := 0;
       if ((b1 and 1) <> 0) and Envelope_Enabled then
         Amplitude := Amplitude or 16;
       TempMixer := b0 shr 1 and $48 or TempMixer;
       if shortint(b0) >= 0 then
         SoundChip[CNum].RegisterAY.Noise := (b1 shr 1) and 31;
       Inc(Position_In_Ornament);
       if Position_In_Ornament >= Ornament_Length then
         Position_In_Ornament := Loop_Ornament_Position;
       Inc(Position_In_Sample);
       if Position_In_Sample >= Sample_Length then
        begin
         Position_In_Sample := Loop_Sample_Position;
         if shortint(Loop_Sample_Position) < 0 then Enabled := False;
        end;
      end
     else
      begin
       TempMixer := TempMixer or $48;
       Amplitude := 0;
      end;
    end;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].STP do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
     with PLConsts[CNum].RAM^ do
      begin
       DelayCounter := STP_Delay;
       with PlParams[CNum].STP_A do
        begin
         Dec(Note_Skip_Counter);
         if Note_Skip_Counter < 0 then
          begin
           if (Index[Address_In_Pattern] = 0) then
            begin
             Inc(CurrentPosition);
             if CurrentPosition = Index[STP_PositionsPointer] then
               CurrentPosition := Index[STP_PositionsPointer + 1];
             Address_In_Pattern :=
               PWord(@Index[STP_PatternsPointer +
               Index[STP_PositionsPointer + 2 + CurrentPosition * 2]])^;
             PlParams[CNum].STP_B.Address_In_Pattern :=
               PWord(@Index[STP_PatternsPointer +
               Index[STP_PositionsPointer + 2 + CurrentPosition * 2] + 2])^;
             PlParams[CNum].STP_C.Address_In_Pattern :=
               PWord(@Index[STP_PatternsPointer +
               Index[STP_PositionsPointer + 2 + CurrentPosition * 2] + 4])^;
             Transposition := Index[STP_PositionsPointer + 3 +
               CurrentPosition * 2];
            end;
           PatternInterpreter(PlParams[CNum].STP_A);
          end;
        end;
       with PlParams[CNum].STP_B do
        begin
         Dec(Note_Skip_Counter);
         if Note_Skip_Counter < 0 then
           PatternInterpreter(PlParams[CNum].STP_B);
        end;
       with PlParams[CNum].STP_C do
        begin
         Dec(Note_Skip_Counter);
         if Note_Skip_Counter < 0 then
           PatternInterpreter(PlParams[CNum].STP_C);
        end;
      end;
  end;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].STP_A);
 GetRegisters(PlParams[CNum].STP_B);
 GetRegisters(PlParams[CNum].STP_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].STP_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].STP_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].STP_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].STP_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].STP_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].STP_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure ASC_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: ASC_Channel_Parameters);
 var
   delta_ton: smallint;
   Initialization_Of_Ornament_Disabled, Initialization_Of_Sample_Disabled: boolean;
 begin
   Initialization_Of_Sample_Disabled := False;
   Initialization_Of_Ornament_Disabled := False;
   with Chan do
    begin
     Ton_Sliding_Counter := 0;
     Amplitude_Delay_Counter := 0;
     repeat
       with PLConsts[CNum].RAM^ do
         case Index[Address_In_Pattern] of
           0..$55:
            begin
             Note := Index[Address_In_Pattern];
             Inc(Address_In_Pattern);
             Current_Noise := Initial_Noise;
             if shortint(Ton_Sliding_Counter) <= 0 then
               Current_Ton_Sliding := 0;
             if not Initialization_Of_Sample_Disabled then
              begin
               Addition_To_Amplitude := 0;
               Ton_Deviation := 0;
               Point_In_Sample := Initial_Point_In_Sample;
               Sound_Enabled := True;
               Sample_Finished := False;
               Break_Sample_Loop := False;
              end;
             if not Initialization_Of_Ornament_Disabled then
              begin
               Point_In_Ornament := Initial_Point_In_Ornament;
               Addition_To_Note := 0;
              end;
             if Envelope_Enabled then
              begin
               SoundChip[CNum].RegisterAY.Index[11] := Index[Chan.Address_In_Pattern];
               Inc(Address_In_Pattern);
              end;
             break;
            end;
           $56..$5d:
            begin
             Inc(Address_In_Pattern);
             break;
            end;
           $5e:
            begin
             Break_Sample_Loop := True;
             Inc(Address_In_Pattern);
             break;
            end;
           $5f:
            begin
             Sound_Enabled := False;
             Inc(Address_In_Pattern);
             break;
            end;
           $60..$9f:
             Number_Of_Notes_To_Skip := Index[Address_In_Pattern] - $60;
           $a0..$bf:
             Initial_Point_In_Sample :=
               PWord(@Index[(Index[Address_In_Pattern] - $a0) * 2 +
               ASC1_SamplesPointers])^ + ASC1_SamplesPointers;
           $c0..$df:
             Initial_Point_In_Ornament :=
               PWord(@Index[(Index[Address_In_Pattern] - $c0) * 2 +
               ASC1_OrnamentsPointers])^ + ASC1_OrnamentsPointers;
           $e0:
            begin
             Volume := 15;
             Envelope_Enabled := True;
            end;
           $e1..$ef:
            begin
             Volume := Index[Address_In_Pattern] - $e0;
             Envelope_Enabled := False;
            end;
           $f0:
            begin
             Inc(Address_In_Pattern);
             Initial_Noise := Index[Address_In_Pattern];
            end;
           $f1:
             Initialization_Of_Sample_Disabled := True;
           $f2:
             Initialization_Of_Ornament_Disabled := True;
           $f3:
            begin
             Initialization_Of_Sample_Disabled := True;
             Initialization_Of_Ornament_Disabled := True;
            end;
           $f4:
            begin
             Inc(Address_In_Pattern);
             PlParams[CNum].ASC.Delay := Index[Address_In_Pattern];
            end;
           $f5:
            begin
             Inc(Address_In_Pattern);
             Substruction_for_Ton_Sliding :=
               -shortint(Index[Address_In_Pattern]) * 16;
             Ton_Sliding_Counter := 255;
            end;
           $f6:
            begin
             Inc(Address_In_Pattern);
             Substruction_for_Ton_Sliding :=
               shortint(Index[Chan.Address_In_Pattern]) * 16;
             Chan.Ton_Sliding_Counter := 255;
            end;
           $f7:
            begin
             Inc(Address_In_Pattern);
             Initialization_Of_Sample_Disabled := True;
             if Index[Address_In_Pattern + 1] < $56 then
               delta_ton := ASM_Table[Note] + Current_Ton_Sliding div
                 16 - ASM_Table[Index[Address_In_Pattern + 1]]
             else
               delta_ton := Current_Ton_Sliding div 16;
             delta_ton := delta_ton shl 4;
             Substruction_for_Ton_Sliding :=
               -delta_ton div shortint(Index[Address_In_Pattern]);
             Current_Ton_Sliding :=
               delta_ton - delta_ton mod shortint(Index[Address_In_Pattern]);
             Ton_Sliding_Counter :=
               shortint(Index[Address_In_Pattern]);
            end;
           $f8:
             SoundChip[CNum].SetEnvelopeRegister(8);
           $f9:
            begin
             Inc(Address_In_Pattern);
             if Index[Address_In_Pattern + 1] < $56 then
               delta_ton := ASM_Table[Note] -
                 ASM_Table[Index[Address_In_Pattern + 1]]
             else
               delta_ton := Current_Ton_Sliding div 16;
             delta_ton := delta_ton shl 4;
             Substruction_for_Ton_Sliding :=
               -delta_ton div shortint(Index[Address_In_Pattern]);
             Current_Ton_Sliding :=
               delta_ton - delta_ton mod shortint(Index[Address_In_Pattern]);
             Ton_Sliding_Counter :=
               shortint(Index[Address_In_Pattern]);
            end;
           $fa:
             SoundChip[CNum].SetEnvelopeRegister(10);
           $fb:
            begin
             Inc(Chan.Address_In_Pattern);
             if Index[Chan.Address_In_Pattern] and 32 = 0 then
              begin
               Amplitude_Delay := Index[Address_In_Pattern] shl 3;
               Amplitude_Delay_Counter := Amplitude_Delay;
              end
             else
              begin
               Amplitude_Delay :=
                 ((Index[Address_In_Pattern] shl 3) xor $f8) + 9;
               {bit 0 - знаковый, а биты 7-3 - модуль}
               Amplitude_Delay_Counter := Chan.Amplitude_Delay;
              end;
            end;
           $fc:
             SoundChip[CNum].SetEnvelopeRegister(12);
           $fe:
             SoundChip[CNum].SetEnvelopeRegister(14);
          end;
       Inc(Address_In_Pattern);
     until False;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

 procedure GetRegisters(var Chan: ASC_Channel_Parameters);
 var
   j: shortint;
   Sample_Says_OK_for_Envelope: boolean;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Sample_Finished or not Sound_Enabled then
       Amplitude := 0
     else
      begin
       if Amplitude_Delay_Counter <> 0 then
         if Amplitude_Delay_Counter >= 16 then
          begin
           Dec(Amplitude_Delay_Counter, 8);
           if Addition_To_Amplitude < -15 then
             Inc(Addition_To_Amplitude)
           else if Addition_To_Amplitude > 15 then
             Dec(Addition_To_Amplitude);
          end
         else
          begin
           if (Amplitude_Delay_Counter and 1 <> 0) then
            begin
             if Addition_To_Amplitude > -15 then
               Dec(Addition_To_Amplitude);
            end
           else if Addition_To_Amplitude < 15 then
             Inc(Addition_To_Amplitude);
           Amplitude_Delay_Counter := Amplitude_Delay;
          end;
       if Index[Point_In_Sample] and 128 <> 0 then
         Loop_Point_In_Sample := Point_In_Sample;
       if Index[Point_In_Sample] and 96 = 32 then
         Sample_Finished := True;
       Inc(Ton_Deviation, shortint(Index[Point_In_Sample + 1]));
       TempMixer := Index[Point_In_Sample + 2] and 9 shl 3 or TempMixer;
       if Index[Point_In_Sample + 2] and 6 = 2 then
         Sample_Says_OK_for_Envelope := True
       else
         Sample_Says_OK_for_Envelope := False;
       if Index[Point_In_Sample + 2] and 6 = 4 then
         if Addition_To_Amplitude > -15 then
           Dec(Addition_To_Amplitude);
       if Index[Point_In_Sample + 2] and 6 = 6 then
         if Addition_To_Amplitude < 15 then
           Inc(Addition_To_Amplitude);
       Amplitude := byte(Addition_To_Amplitude) + Index[Point_In_Sample + 2] shr 4;
       if shortint(Amplitude) < 0 then
         Amplitude := 0
       else if Amplitude > 15 then
         Amplitude := 15;
       Amplitude := (Amplitude * (Volume + 1)) shr 4;
       if Sample_Says_OK_for_Envelope and (TempMixer and 64 <> 0) then
         Inc(SoundChip[CNum].RegisterAY.Index[11],
           shortint(Index[Point_In_Sample] shl 3) div 8)
       else
         Inc(Current_Noise, shortint(Index[Point_In_Sample] shl 3) div 8);
       Inc(Point_In_Sample, 3);
       if Index[Point_In_Sample - 3] and 64 <> 0 then
         if not Break_Sample_Loop then
           Point_In_Sample := Loop_Point_In_Sample
         else if Index[Point_In_Sample - 3] and 32 <> 0 then
           Sample_Finished := True;
       if Index[Point_In_Ornament] and 128 <> 0 then
         Loop_Point_In_Ornament := Point_In_Ornament;
       Inc(Addition_To_Note, Index[1 + Point_In_Ornament]);
       Inc(Current_Noise,
         (-shortint(Index[Point_In_Ornament] and $10)) or
         Index[Point_In_Ornament]);
       Inc(Point_In_Ornament, 2);
       if Index[Point_In_Ornament - 2] and 64 <> 0 then
         Point_In_Ornament := Loop_Point_In_Ornament;
       if TempMixer and 64 = 0 then
         SoundChip[CNum].RegisterAY.Noise :=
           (byte(Current_Ton_Sliding shr 8) + Current_Noise) and $1f;
       j := Note + Addition_To_Note;
       if j < 0 then
         j := 0
       else if j > $55 then
         j := $55;
       Ton := (ASM_Table[j] + Ton_Deviation +
         word(Current_Ton_Sliding div 16)) and $fff;
       if Ton_Sliding_Counter <> 0 then
        begin
         if shortint(Ton_Sliding_Counter) > 0 then Dec(Ton_Sliding_Counter);
         Inc(Current_Ton_Sliding, Substruction_for_Ton_Sliding);
        end;
       if Envelope_Enabled and Sample_Says_OK_for_Envelope then
         Amplitude := Amplitude or $10;
      end;
    end;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].ASC do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].ASC_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         with PLConsts[CNum].RAM^ do
          begin
           if Index[Address_In_Pattern] = 255 then
            begin
             Inc(CurrentPosition);
             if CurrentPosition >= ASC1_Number_Of_Positions then
               CurrentPosition := ASC1_LoopingPosition;
             Address_In_Pattern :=
               PWord(@Index[ASC1_PatternsPointers + 6 *
               Index[CurrentPosition + 9]])^ + ASC1_PatternsPointers;
             PlParams[CNum].ASC_B.Address_In_Pattern :=
               PWord(@Index[ASC1_PatternsPointers + 6 *
               Index[CurrentPosition + 9] + 2])^ + ASC1_PatternsPointers;
             PlParams[CNum].ASC_C.Address_In_Pattern :=
               PWord(@Index[ASC1_PatternsPointers + 6 *
               Index[CurrentPosition + 9] + 4])^ + ASC1_PatternsPointers;
             Initial_Noise := 0;
             PlParams[CNum].ASC_B.Initial_Noise := 0;
             PlParams[CNum].ASC_C.Initial_Noise := 0;
            end;
           PatternInterpreter(PlParams[CNum].ASC_A);
          end;
      end;
     with PlParams[CNum].ASC_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].ASC_B);
      end;
     with PlParams[CNum].ASC_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].ASC_C);
      end;
     DelayCounter := Delay;
    end;
  end;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].ASC_A);
 GetRegisters(PlParams[CNum].ASC_B);
 GetRegisters(PlParams[CNum].ASC_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].ASC_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].ASC_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].ASC_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].ASC_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].ASC_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].ASC_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure PSC_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: PSC_Channel_Parameters);
 var
   quit: boolean;
   b1b, b2b, b3b, b4b, b5b, b6b, b7b: boolean;
 begin
   quit := False;
   b1b := False;
   b2b := False;
   b3b := False;
   b4b := False;
   b5b := False;
   b6b := False;
   b7b := False;
   with PLConsts[CNum].RAM^, Chan do
    begin
     repeat
       case Index[Address_In_Pattern] of
         $c0..$ff:
          begin
           Note_Skip_Counter := Index[Address_In_Pattern] - $bf;
           quit := True;
          end;
         $a0..$bf:
          begin
           OrnamentPointer :=
             PWord(@Index[PSC_OrnamentsPointer +
             (Index[Address_In_Pattern] - $a0) * 2])^;
           if PlConsts[CNum].Version > 3 then
             Inc(OrnamentPointer, PSC_OrnamentsPointer);
          end;
         $7e..$9f:
           if Index[Address_In_Pattern] >= $80 then
            begin
             SamplePointer := PSC_SamplesPointers[Index[Address_In_Pattern] - $80];
             if PlConsts[CNum].Version > 3 then Inc(SamplePointer, $4c);
            end;
         $6b:
          begin
           Inc(Address_In_Pattern);
           Addition_To_Ton := Index[Address_In_Pattern];
           b5b := True;
          end;
         $6c:
          begin
           Inc(Address_In_Pattern);
           Addition_To_Ton := -shortint(Index[Address_In_Pattern]);
           b5b := True;
          end;
         $6d:
          begin
           b4b := True;
           Inc(Address_In_Pattern);
           Addition_To_Ton := Index[Address_In_Pattern];
          end;
         $6e:
          begin
           Inc(Address_In_Pattern);
           PlParams[CNum].PSC.Delay := Index[Address_In_Pattern];
          end;
         $6f:
          begin
           b1b := True;
           Inc(Address_In_Pattern);
          end;
         $70:
          begin
           b3b := True;
           Inc(Address_In_Pattern);
           Volume_Counter1 := Index[Address_In_Pattern];
          end;
         $71:
          begin
           Break_Ornament_Loop := True;
           Inc(Address_In_Pattern);
          end;
         $7a:
          begin
           Inc(Address_In_Pattern);
           if @Chan = @PlParams[CNum].PSC_B then
            begin
             SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] and 15);
             SoundChip[CNum].RegisterAY.Envelope :=
               PWord(@Index[Address_In_Pattern + 1])^;
             Inc(Address_In_Pattern, 2);
            end;
          end;
         $7b:
          begin
           Inc(Address_In_Pattern);
           if @Chan = @PlParams[CNum].PSC_B then
             PlParams[CNum].PSC.Noise_Base := Index[Address_In_Pattern];
          end;
         $7c:
          begin
           b1b := False;
           b2b := True;
           b3b := False;
           b4b := False;
           b5b := False;
           b6b := False;
           b7b := False;
          end;
         $7d:
           Break_Sample_Loop := True;
         $58..$66:
          begin
           Initial_Volume := Index[Address_In_Pattern] - $57;
           Envelope_Enabled := False;
           b6b := True;
          end;
         $57:
          begin
           Initial_Volume := $f;
           Envelope_Enabled := True;
           b6b := True;
          end;
         0..$56:
          begin
           Note := Index[Address_In_Pattern];
           b6b := True;
           b7b := True;
          end
       else
         Inc(Address_In_Pattern);
        end;
       Inc(Address_In_Pattern);
     until quit;
     if b7b then
      begin
       Break_Ornament_Loop := False;
       Ornament_Enabled := True;
       Enabled := True;
       Break_Sample_Loop := False;
       Ton_Slide_Enabled := False;
       Ton_Accumulator := 0;
       Current_Ton_Sliding := 0;
       Noise_Accumulator := 0;
       Volume_Counter := 0;
       Position_In_Sample := 0;
       Position_In_Ornament := 0;
      end;
     if b6b then
       Volume := Initial_Volume;
     if b5b then
      begin
       Gliss := False;
       Ton_Slide_Enabled := True;
      end;
     if b4b then
      begin
       Current_Ton_Sliding := Ton - ASM_Table[Note];
       Gliss := True;
       if Chan.Current_Ton_Sliding >= 0 then
         Addition_To_Ton := -Addition_To_Ton;
       Ton_Slide_Enabled := True;
      end;
     if b3b then
      begin
       Volume_Counter := Volume_Counter1;
       Volume_Inc := True;
       if Volume_Counter and $40 <> 0 then
        begin
         Volume_Counter := -shortint(Volume_Counter or 128);
         Volume_Inc := False;
        end;
       Volume_Counter_Init := Volume_Counter;
      end;
     if b2b then
      begin
       Break_Ornament_Loop := False;
       Ornament_Enabled := False;
       Enabled := False;
       Break_Sample_Loop := False;
       Ton_Slide_Enabled := False;
      end;
     if b1b then
       Ornament_Enabled := False;
    end;
 end;

 procedure GetRegisters(var Chan: PSC_Channel_Parameters);
 var
   j, b: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Enabled then
      begin
       j := Note;
       if Ornament_Enabled then
        begin
         b := Index[OrnamentPointer + Position_In_Ornament * 2];
         Inc(Noise_Accumulator, b);
         Inc(j, Index[OrnamentPointer + Position_In_Ornament * 2 + 1]);
         if shortint(j) < 0 then
           Inc(j, $56);
         if j > $55 then
           Dec(j, $56);
         if j > $55 then
           j := $55;
         if b and 128 = 0 then
           Loop_Ornament_Position := Position_In_Ornament;
         if b and 64 = 0 then
          begin
           if not Break_Ornament_Loop then
             Position_In_Ornament := Loop_Ornament_Position
           else
            begin
             Break_Ornament_Loop := False;
             if b and 32 = 0 then
               Ornament_Enabled := False;
             Inc(Position_In_Ornament);
            end;
          end
         else
          begin
           if b and 32 = 0 then
             Ornament_Enabled := False;
           Inc(Position_In_Ornament);
          end;
        end;
       Note := j;
       Ton := PWord(@Index[SamplePointer + Position_In_Sample * 6])^;
       Inc(Ton_Accumulator, Ton);
       Ton := ASM_Table[j] + Ton_Accumulator;
       if Ton_Slide_Enabled then
        begin
         Inc(Current_Ton_Sliding, Addition_To_Ton);
         if Gliss and (((Current_Ton_Sliding < 0) and (Addition_To_Ton <= 0)) or
           ((Current_Ton_Sliding >= 0) and (Addition_To_Ton >= 0))) then
           Ton_Slide_Enabled := False;
         Inc(Ton, Current_Ton_Sliding);
        end;
       Ton := Ton and $fff;
       b := Index[SamplePointer + Position_In_Sample * 6 + 4];
       TempMixer := TempMixer or ((b and 9) shl 3);
       j := 0;
       if b and 2 <> 0 then
         Inc(j);
       if b and 4 <> 0 then
         Dec(j);
       if Volume_Counter > 0 then
        begin
         Dec(Volume_Counter);
         if Volume_Counter = 0 then
          begin
           if Volume_Inc then Inc(j)
           else
             Dec(j);
           Volume_Counter := Volume_Counter_Init;
          end;
        end;
       Inc(Volume, j);
       if shortint(Volume) < 0 then
         Volume := 0
       else if Volume > 15 then
         Volume := 15;
       Amplitude := ((Volume + 1) *
         (Index[SamplePointer + Position_In_Sample * 6 + 3] and 15)) shr 4;
       if Envelope_Enabled and (b and 16 = 0) then
         Amplitude := Amplitude or 16;
       if (Amplitude and 16 <> 0) and (b and 8 <> 0) then
         SoundChip[CNum].RegisterAY.Envelope :=
           SoundChip[CNum].RegisterAY.Envelope + shortint(
           Index[SamplePointer + Position_In_Sample * 6 + 2])
       else
        begin
         Inc(Noise_Accumulator,
           Index[SamplePointer + Position_In_Sample * 6 + 2]);
         if b and 8 = 0 then
           SoundChip[CNum].RegisterAY.Noise := Noise_Accumulator and 31;
        end;
       if b and 128 = 0 then
         Loop_Sample_Position := Position_In_Sample;
       if b and 64 = 0 then
        begin
         if not Break_Sample_Loop then
           Position_In_Sample := Loop_Sample_Position
         else
          begin
           Break_Sample_Loop := False;
           if b and 32 = 0 then
             Enabled := False;
           Inc(Position_In_Sample);
          end;
        end
       else
        begin
         if b and 32 = 0 then
           Enabled := False;
         Inc(Position_In_Sample);
        end;
      end
     else
       Amplitude := 0;
    end;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].PSC do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     Dec(Lines_Counter);
     if Lines_Counter = 0 then
       with PLConsts[CNum].RAM^ do
        begin
         if Index[Positions_Pointer + 1] = 255 then
           Positions_Pointer := PWord(@Index[Positions_Pointer + 2])^;
         Lines_Counter := Index[Positions_Pointer + 1];
         PlParams[CNum].PSC_A.Address_In_Pattern :=
           PWord(@Index[Positions_Pointer + 2])^;
         PlParams[CNum].PSC_B.Address_In_Pattern :=
           PWord(@Index[Positions_Pointer + 4])^;
         PlParams[CNum].PSC_C.Address_In_Pattern :=
           PWord(@Index[Positions_Pointer + 6])^;
         Inc(Positions_Pointer, 8);
         PlParams[CNum].PSC_A.Note_Skip_Counter := 1;
         PlParams[CNum].PSC_B.Note_Skip_Counter := 1;
         PlParams[CNum].PSC_C.Note_Skip_Counter := 1;
        end;
     with PlParams[CNum].PSC_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         PatternInterpreter(PlParams[CNum].PSC_A);
      end;
     with PlParams[CNum].PSC_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         PatternInterpreter(PlParams[CNum].PSC_B);
      end;
     with PlParams[CNum].PSC_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         PatternInterpreter(PlParams[CNum].PSC_C);
      end;
     Inc(PlParams[CNum].PSC_A.Noise_Accumulator, Noise_Base);
     Inc(PlParams[CNum].PSC_B.Noise_Accumulator, Noise_Base);
     Inc(PlParams[CNum].PSC_C.Noise_Accumulator, Noise_Base);
     DelayCounter := Delay;
    end;
  end;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].PSC_A);
 GetRegisters(PlParams[CNum].PSC_B);
 GetRegisters(PlParams[CNum].PSC_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].PSC_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].PSC_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].PSC_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].PSC_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].PSC_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].PSC_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure SQT_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: SQT_Channel_Parameters);
 var
   Ptr: word;
   Temp: integer;

   procedure Call_LC1D1(a: byte);
   begin
     Inc(Ptr);
     with Chan do
      begin
       if b6ix0 then
        begin
         Address_In_Pattern := Ptr + 1;
         b6ix0 := False;
        end;
       with PLConsts[CNum].RAM^ do
         case a - 1 of
           0: if b4ix0 then Volume := Index[Ptr] and 15;
           1: if b4ix0 then Volume := (Volume + Index[Ptr]) and 15;
           2: if b4ix0 then
              begin
               PlParams[CNum].SQT_A.Volume := Index[Ptr];
               PlParams[CNum].SQT_B.Volume := Index[Ptr];
               PlParams[CNum].SQT_C.Volume := Index[Ptr];
              end;
           3: if b4ix0 then
              begin
               with PlParams[CNum].SQT_A do
                 Volume := (Volume + Index[Ptr]) and 15;
               with PlParams[CNum].SQT_B do
                 Volume := (Volume + Index[Ptr]) and 15;
               with PlParams[CNum].SQT_C do
                 Volume := (Volume + Index[Ptr]) and 15;
              end;
           4: if b4ix0 then
               with PlParams[CNum].SQT do
                begin
                 DelayCounter := Index[Ptr] and 31;
                 if DelayCounter = 0 then DelayCounter := 32;
                 Delay := DelayCounter;
                end;
           5: if b4ix0 then
               with PlParams[CNum].SQT do
                begin
                 DelayCounter := (DelayCounter + Index[Ptr]) and 31;
                 if DelayCounter = 0 then DelayCounter := 32;
                 Delay := DelayCounter;
                end;
           6: begin
             Current_Ton_Sliding := 0;
             Gliss := True;
             Ton_Slide_Step := -Index[Ptr];
            end;
           7: begin
             Current_Ton_Sliding := 0;
             Gliss := True;
             Ton_Slide_Step := Index[Ptr];
            end
         else
          begin
           Envelope_Enabled := True;
           SoundChip[CNum].SetEnvelopeRegister((a - 1) and 15);
           SoundChip[CNum].RegisterAY.Index[11] := Index[Ptr];
          end;
          end;
      end;
   end;

   procedure Call_LC2A8(a: byte);
   begin
     with Chan do
      begin
       Envelope_Enabled := False;
       Ornament_Enabled := False;
       Gliss := False;
       Enabled := True;
       with PLConsts[CNum].RAM^ do
         SamplePointer := PWord(@Index[a * 2 + SQT_SamplesPointer])^;
       Point_In_Sample := SamplePointer + 2;
       Sample_Tik_Counter := 32;
       MixNoise := True;
       MixTon := True;
      end;
   end;

   procedure Call_LC2D9(a: byte);
   begin
     with Chan do
      begin
       with PLConsts[CNum].RAM^ do
         OrnamentPointer := PWord(@Index[a * 2 + SQT_OrnamentsPointer])^;
       Point_In_Ornament := OrnamentPointer + 2;
       Ornament_Tik_Counter := 32;
       Ornament_Enabled := True;
      end;
   end;

   procedure Call_LC283;
   begin
     with PLConsts[CNum].RAM^ do
       case Index[Ptr] of
         0..$7f:
           Call_LC1D1(Index[Ptr]);
         $80..$ff:
          begin
           if Index[Ptr] shr 1 and 31 <> 0 then
             Call_LC2A8(Index[Ptr] shr 1 and 31);
           if Index[Ptr] and 64 <> 0 then
            begin
             Temp := Index[Ptr + 1] shr 4;
             if Index[Ptr] and 1 <> 0 then Temp := Temp or 16;
             if Temp <> 0 then Call_LC2D9(Temp);
             Inc(Ptr);
             if Index[Ptr] and 15 <> 0 then
               Call_LC1D1(Index[Ptr] and 15);
            end;
          end
        end;
     Inc(Ptr);
   end;

   procedure Call_LC191;
   begin
     with Chan do
      begin
       Ptr := ix27;
       b6ix0 := False;
      end;
     with PLConsts[CNum].RAM^ do
       case Index[Ptr] of
         0..$7f:
          begin
           Inc(Ptr);
           Call_LC283;
          end;
         $80..$ff:
           Call_LC2A8(Index[Ptr] and 31);
        end;
   end;

 begin
   with Chan do
    begin
     if ix21 <> 0 then
      begin
       Dec(ix21);
       if b7ix0 then Call_LC191;
       exit;
      end;
     Ptr := Address_In_Pattern;
     b6ix0 := True;
     b7ix0 := False;
     repeat
       with PLConsts[CNum].RAM^ do
         case Index[Ptr] of
           0..$5f:
            begin
             Note := Index[Ptr];
             ix27 := Ptr;
             Inc(Ptr);
             Call_LC283;
             if b6ix0 then Address_In_Pattern := Ptr;
             break;
            end;
           $60..$6e:
            begin
             Call_LC1D1(Index[Ptr] - $60);
             break;
            end;
           $6f..$7f:
            begin
             MixNoise := False;
             MixTon := False;
             Enabled := False;
             if Index[Ptr] <> $6f then
               Call_LC1D1(Index[Ptr] - $6f)
             else
               Address_In_Pattern := Ptr + 1;
             break;
            end;
           $80..$bf:
            begin
             Address_In_Pattern := Ptr + 1;
             if Index[Ptr] in [$80..$9f] then
              begin
               if Index[Ptr] and 16 = 0 then
                 Inc(Note, Index[Ptr] and 15)
               else
                 Dec(Note, Index[Ptr] and 15);
              end
             else
              begin
               ix21 := Index[Ptr] and 15;
               if Index[Ptr] and 16 = 0 then break;
               if ix21 <> 0 then b7ix0 := True;
              end;
             Call_LC191;
             break;
            end;
           $c0..$ff:
            begin
             Address_In_Pattern := Ptr + 1;
             ix27 := Ptr;
             Call_LC2A8(Index[Ptr] and 31);
             break;
            end
          end
     until False;
    end;
 end;

 procedure GetRegisters(var Chan: SQT_Channel_Parameters);
 var
   j, b0, b1: byte;
 begin
   TempMixer := TempMixer shl 1;
   with Chan do
    begin
     if Enabled then
       with PLConsts[CNum].RAM^ do
        begin
         b0 := Index[Point_In_Sample];
         Amplitude := b0 and 15;
         if Amplitude <> 0 then
          begin
           Dec(Amplitude, Volume);
           if shortint(Amplitude) < 0 then Amplitude := 0;
          end
         else if Envelope_Enabled then
           Amplitude := 16;
         b1 := Index[Point_In_Sample + 1];
         if b1 and 32 <> 0 then
          begin
           TempMixer := TempMixer or 8;
           SoundChip[CNum].RegisterAY.Noise := b0 and $f0 shr 3;
           if shortint(b1) < 0 then
             Inc(SoundChip[CNum].RegisterAY.Noise);
          end;
         if b1 and 64 <> 0 then
           TempMixer := TempMixer or 1;
         j := Note;
         if Ornament_Enabled then
          begin
           Inc(j, Index[Point_In_Ornament]);
           Dec(Ornament_Tik_Counter);
           if Ornament_Tik_Counter = 0 then
            begin
             if Index[OrnamentPointer] <> 32 then
              begin
               Ornament_Tik_Counter := Index[OrnamentPointer + 1];
               Point_In_Ornament := OrnamentPointer + 2 + Index[OrnamentPointer];
              end
             else
              begin
               Ornament_Tik_Counter := Index[SamplePointer + 1];
               Point_In_Ornament := OrnamentPointer + 2 + Index[SamplePointer];
              end;
            end
           else
             Inc(Point_In_Ornament);
          end;
         Inc(j, Transposit);
         if j > $5F then j := $5f;
         if b1 and 16 = 0 then
           Ton := SQT_Table[j] {%H-} - (word(b1 and 15) shl 8 +
             Index[Point_In_Sample + 2])
         else
           Ton := SQT_Table[j] + (word(b1 and 15) shl 8 +
             Index[Point_In_Sample + 2]);
         Dec(Sample_Tik_Counter);
         if Sample_Tik_Counter = 0 then
          begin
           Sample_Tik_Counter := Index[SamplePointer + 1];
           if Index[SamplePointer] = 32 then
            begin
             Enabled := False;
             Ornament_Enabled := False;
            end;
           Point_In_Sample := SamplePointer + 2 + Index[SamplePointer] * 3;
          end
         else
           Inc(Point_In_Sample, 3);
         if Gliss then
          begin
           Inc(Ton, Current_Ton_Sliding);
           Inc(Current_Ton_Sliding, Ton_Slide_Step);
          end;
         Ton := Ton and $fff;
        end
     else
       Amplitude := 0;
    end;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].SQT do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     DelayCounter := Delay;
     Dec(Lines_Counter);
     if Lines_Counter = 0 then
       with PLConsts[CNum].RAM^ do
        begin
         if Index[Positions_Pointer] = 0 then
           Positions_Pointer := SQT_LoopPointer;
         with PlParams[CNum].SQT_C do
          begin
           if shortint(Index[Positions_Pointer]) < 0 then
             b4ix0 := True
           else
             b4ix0 := False;
           Address_In_Pattern :=
             PWord(@Index[byte(Index[Positions_Pointer] * 2) +
             SQT_PatternsPointer])^;
           Lines_Counter := Index[Address_In_Pattern];
           Inc(Address_In_Pattern);
           Inc(Positions_Pointer);
           Volume := Index[Positions_Pointer] and 15;
           if Index[Positions_Pointer] shr 4 < 9 then
             Transposit := Index[Positions_Pointer] shr 4
           else
             Transposit := -(Index[Positions_Pointer] shr 4 - 9) - 1;
           Inc(Positions_Pointer);
           ix21 := 0;
          end;

         if Index[Positions_Pointer] = 0 then
           Positions_Pointer := SQT_LoopPointer;
         with PlParams[CNum].SQT_B do
          begin
           if shortint(Index[Positions_Pointer]) < 0 then
             b4ix0 := True
           else
             b4ix0 := False;
           Address_In_Pattern :=
             PWord(@Index[byte(Index[Positions_Pointer] * 2) +
             SQT_PatternsPointer])^ + 1;
           Inc(Positions_Pointer);
           Volume := Index[Positions_Pointer] and 15;
           if Index[Positions_Pointer] shr 4 < 9 then
             Transposit := Index[Positions_Pointer] shr 4
           else
             Transposit := -(Index[Positions_Pointer] shr 4 - 9) - 1;
           Inc(Positions_Pointer);
           ix21 := 0;
          end;

         if Index[Positions_Pointer] = 0 then
           Positions_Pointer := SQT_LoopPointer;
         with PlParams[CNum].SQT_A do
          begin
           if shortint(Index[Positions_Pointer]) < 0 then
             b4ix0 := True
           else
             b4ix0 := False;
           Address_In_Pattern :=
             PWord(@Index[byte(Index[Positions_Pointer] * 2) +
             SQT_PatternsPointer])^ + 1;
           Inc(Positions_Pointer);
           Volume := Index[Positions_Pointer] and 15;
           if Index[Positions_Pointer] shr 4 < 9 then
             Transposit := Index[Positions_Pointer] shr 4
           else
             Transposit := -(Index[Positions_Pointer] shr 4 - 9) - 1;
           Inc(Positions_Pointer);
           ix21 := 0;
          end;

         Delay := Index[Positions_Pointer];
         DelayCounter := Delay;
         Inc(Positions_Pointer);

        end;
     PatternInterpreter(PlParams[CNum].SQT_C);
     PatternInterpreter(PlParams[CNum].SQT_B);
     PatternInterpreter(PlParams[CNum].SQT_A);
    end;
  end;
 TempMixer := 0;
 GetRegisters(PlParams[CNum].SQT_C);
 GetRegisters(PlParams[CNum].SQT_B);
 GetRegisters(PlParams[CNum].SQT_A);
 TempMixer := (-(TempMixer + 1)) and $3f;

 with PlParams[CNum].SQT_A do
  begin
   if not MixNoise then TempMixer := TempMixer or 8;
   if not MixTon then TempMixer := TempMixer or 1;
  end;
 with PlParams[CNum].SQT_B do
  begin
   if not MixNoise then TempMixer := TempMixer or 16;
   if not MixTon then TempMixer := TempMixer or 2;
  end;
 with PlParams[CNum].SQT_C do
  begin
   if not MixNoise then TempMixer := TempMixer or 32;
   if not MixTon then TempMixer := TempMixer or 4;
  end;
 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].SQT_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].SQT_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].SQT_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].SQT_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].SQT_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].SQT_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure FTC_Get_Registers(CNum: integer);

 function GetNoteFreq(j: integer): integer;
 begin
   if PlConsts[CNum].Version < 7 then
     Result := PT3NoteTable_ST[j]
   else
     case PLConsts[CNum].RAM^.FTC_MusicName[$32] of
       #2:
         Result := FTCNoteTable2[j];
     else
       Result := ST_Table[j];
      end;
 end;

var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: FTC_Channel_Parameters; ChanNum: integer);
 var
   quit: boolean;
   ExxAF: shortint;
 begin
   quit := False;
   EXXAF := 2;
   with Chan do
    begin
     repeat
       with PLConsts[CNum].RAM^ do
         case Index[Address_In_Pattern] of
           0..$1f:
            begin
             SamplePointer := FTC_SamplesPointers[Index[Address_In_Pattern]];
             Inc(SamplePointer);
             Loop_Sample_Position := Index[SamplePointer];
             Inc(SamplePointer);
             Sample_Length := Index[SamplePointer] + 1;
             Inc(SamplePointer);
            end;
           $20..$2f:
             Volume := Index[Address_In_Pattern] - $20;
           $30:
            begin
             Sample_Enabled := False;
             Position_In_Sample := 0;
             Sample_Noise_Accumulator := 0;
             Volume_Slide := 0;
             Noise_Accumulator := 0;
             Note_Accumulator := 0;
             Position_In_Ornament := 0;
             Ton_Accumulator := 0;
             Envelope_Accumulator := 0;
             if EXXAF > 0 then
              begin
               Current_Ton_Sliding := 0;
               Ton_Slide_Direction := 0;
              end;
             if EXXAF > 1 then Ton_Slide_Step := 0;
             Note_Skip_Counter := 0;
             quit := True;
            end;
           $31..$3e:
            begin
             PlParams[CNum].FTC.EnvT := Index[Address_In_Pattern] - $30;
             Envelope_Enabled := True;
             Inc(Address_In_Pattern);
             Envelope := PWord(@Index[Chan.Address_In_Pattern])^;
             Inc(Chan.Address_In_Pattern);
            end;
           $3f:
             Envelope_Enabled := False;
           $40..$5f:
            begin
             Note_Skip_Counter := Index[Address_In_Pattern] - $40;
             EXXAF := 1;
             quit := True;
            end;
           $60..$cb:
            begin
             Previous_Note := Note;
             Note := PlParams[CNum].FTC.Transposition +
               Index[Chan.Address_In_Pattern] {%H-} - $60;
             Sample_Enabled := True;
             Position_In_Sample := 0;
             Sample_Noise_Accumulator := 0;
             Volume_Slide := 0;
             Noise_Accumulator := 0;
             Note_Accumulator := 0;
             Position_In_Ornament := 0;
             Ton_Accumulator := 0;
             Envelope_Accumulator := 0;
             if EXXAF > 0 then
              begin
               Current_Ton_Sliding := 0;
               Ton_Slide_Direction := 0;
              end;
             if EXXAF > 1 then Ton_Slide_Step := 0;
             Note_Skip_Counter := 0;
             quit := True;
            end;
           $cc..$ec:
            begin
             OrnamentPointer :=
               FTC_OrnamentsPointers[Index[Address_In_Pattern] - $cc];
             Inc(OrnamentPointer);
             Loop_Ornament_Position := Index[OrnamentPointer];
             Inc(OrnamentPointer);
             Ornament_Length := Index[OrnamentPointer] + 1;
             Inc(OrnamentPointer);
             Position_In_Ornament := 0;
             Noise_Accumulator := 0;
             Note_Accumulator := 0;
            end;
           $ed:
            begin
             EXXAF := 1;
             Inc(Address_In_Pattern);
             Ton_Slide_Step := PWord(@Index[Chan.Address_In_Pattern])^;
             Inc(Address_In_Pattern);
            end;
           $ee:
            begin
             EXXAF := 0;
             Inc(Address_In_Pattern);
             Ton_Slide_Step1 := Index[Address_In_Pattern];
            end;
           $ef:
            begin
             Inc(Address_In_Pattern);
             if (PlConsts[CNum].Version > 7) and
               (Index[Address_In_Pattern] = $fe) then
               //full env+tone retrig
               PlParams[CNum].FTC.Retrig := ChanNum
             else
               Noise := Index[Address_In_Pattern];
            end
         else
          begin
           Inc(Address_In_Pattern);
           PlParams[CNum].FTC.Delay := Index[Address_In_Pattern];
          end
          end;
       Inc(Address_In_Pattern);
     until quit;
     if exxaf = 0 then
      begin
       Current_Ton_Sliding := GetNoteFreq(Previous_Note) - GetNoteFreq(Note);
       if Current_Ton_Sliding < 0 then
        begin
         Ton_Slide_Step := Ton_Slide_Step1;
         Ton_Slide_Direction := 1;
        end
       else
        begin
         Ton_Slide_Step := -Ton_Slide_Step1;
         Ton_Slide_Direction := 2;
        end;
      end;
    end;
 end;

 procedure GetRegisters(var Chan: FTC_Channel_Parameters);
 var
   j, b: byte;
   k: word;
   Add_To_Note, Add_To_Noise: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     Add_To_Note := Note_Accumulator + Index[OrnamentPointer +
       Position_In_Ornament * 2 + 1];
     b := Index[OrnamentPointer + Position_In_Ornament * 2];
     if b and 64 <> 0 then
       Note_Accumulator := Add_To_Note;
     Add_To_Noise := Noise_Accumulator + b;
     if shortint(b) < 0 then
       Noise_Accumulator := Add_To_Noise;
     Inc(Position_In_Ornament);
     if Position_In_Ornament = Ornament_Length then
       Position_In_Ornament := Loop_Ornament_Position;
     if Sample_Enabled then
      begin
       b := Index[SamplePointer + Position_In_Sample * 5];
       j := Sample_Noise_Accumulator + b;
       if shortint(b) < 0 then
         Sample_Noise_Accumulator := j;
       if b and 64 = 0 then
         SoundChip[CNum].RegisterAY.Noise := (j + Noise + Add_To_Noise) and 31
       else
         TempMixer := TempMixer or 64;
       k := Ton_Accumulator + PWord(
         @Index[SamplePointer + Position_In_Sample * 5 + 1])^;
       b := Index[SamplePointer + Position_In_Sample * 5 + 2];
       if shortint(b) < 0 then
         Ton_Accumulator := k;
       Addition_To_Ton := k;
       if b and 64 <> 0 then
         TempMixer := TempMixer or 8;
       b := Index[SamplePointer + Position_In_Sample * 5 + 3];
       if b and 32 <> 0 then
         if b and 16 <> 0 then
          begin
           Dec(Volume_Slide);
           if Volume_Slide < -15 then Volume_Slide := -15;
          end
         else
          begin
           Inc(Volume_Slide);
           if Volume_Slide > 15 then Volume_Slide := 15;
          end;
       j := Volume_Slide + b and 15;
       if shortint(j) < 0 then j := 0
       else if j > 15 then j := 15;
       Amplitude := round((Volume * 17 + byte(Volume > 7)) * j / 256);
       k := Envelope_Accumulator + shortint(
         Index[SamplePointer + Position_In_Sample * 5 + 4]);
       if shortint(b) < 0 then
         Envelope_Accumulator := k;
       if (b and 64 <> 0) and Envelope_Enabled then
        begin
         SoundChip[CNum].RegisterAY.Envelope := Envelope - k;
         Amplitude := Amplitude or 16;
        end;
       Inc(Position_In_Sample);
       if Position_In_Sample = Sample_Length then
         Position_In_Sample := Loop_Sample_Position;
      end
     else
      begin
       Amplitude := 0;
       TempMixer := TempMixer or 72;
      end;
     j := Note + Add_To_Note;
     if j > $5F then j := $5F;
     Ton := GetNoteFreq(j) + Addition_To_Ton;
     Inc(Current_Ton_Sliding, Ton_Slide_Step);
     if ((Ton_Slide_Direction = 1) and (Current_Ton_Sliding >= 0)) or
       ((Ton_Slide_Direction = 2) and (Current_Ton_Sliding < 0)) then
      begin
       Current_Ton_Sliding := 0;
       Ton_Slide_Step := 0;
      end
     else
       Inc(Ton, Current_Ton_Sliding);
     Ton := Ton and $fff;
    end;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].FTC do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].FTC_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
        begin
         with PLConsts[CNum].RAM^ do
           if Index[Address_In_Pattern] = 255 then
            begin
             Inc(CurrentPosition);
             if FTC_Positions[CurrentPosition].Pattern = 255 then
               CurrentPosition := FTC_Loop_Position;
             Transposition := FTC_Positions[CurrentPosition].Transposition;
             Address_In_Pattern :=
               PWord(@Index[FTC_PatternsPointer +
               FTC_Positions[CurrentPosition].Pattern * 6])^;
             PlParams[CNum].FTC_B.Address_In_Pattern :=
               PWord(@Index[FTC_PatternsPointer +
               FTC_Positions[CurrentPosition].Pattern * 6 + 2])^;
             PlParams[CNum].FTC_C.Address_In_Pattern :=
               PWord(@Index[FTC_PatternsPointer +
               FTC_Positions[CurrentPosition].Pattern * 6 + 4])^;
            end;
         PatternInterpreter(PlParams[CNum].FTC_A, 1);
        end;
      end;
     with PlParams[CNum].FTC_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].FTC_B, 2);
      end;
     with PlParams[CNum].FTC_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].FTC_C, 3);
      end;
     DelayCounter := Delay;
    end;
  end;

 //почему-то оригинальный плеер делает ретриг только в одном из трех каналов
 if PlParams[CNum].FTC.Retrig <> 0 then
  begin
   case PlParams[CNum].FTC.Retrig of //Retrig imitation - to trigger Ton at next tick
     1: SoundChip[CNum].Ton_Counter_A.Hi := $FFFE;
     2: SoundChip[CNum].Ton_Counter_B.Hi := $FFFE;
     3: SoundChip[CNum].Ton_Counter_C.Hi := $FFFE;
    end;
  end;
 //FTC player does not write same EnvType (except if Retrig command is used)
 if (SoundChip[CNum].RegisterAY.EnvType <> PlParams[CNum].FTC.EnvT) or
   (PlParams[CNum].FTC.Retrig <> 0) then
   SoundChip[CNum].SetEnvelopeRegister(PlParams[CNum].FTC.EnvT);
 PlParams[CNum].FTC.Retrig := 0;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].FTC_A);
 GetRegisters(PlParams[CNum].FTC_B);
 GetRegisters(PlParams[CNum].FTC_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].FTC_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].FTC_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].FTC_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].FTC_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].FTC_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].FTC_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure PT1_Get_Registers(CNum: integer);
var
 TempMixer: integer;

 procedure PatternInterpreter(var Chan: PT1_Channel_Parameters);
 var
   quit: boolean;
 begin
   quit := False;
   with Chan do
    begin
     repeat
       with PLConsts[CNum].RAM^ do
         case Index[Address_In_Pattern] of
           0..$5f:
            begin
             Note := Index[Address_In_Pattern];
             Enabled := True;
             Position_In_Sample := 0;
             quit := True;
            end;
           $60..$6f:
            begin
             SamplePointer := PT1_SamplesPointers[Index[Address_In_Pattern] - $60];
             Sample_Length := Index[SamplePointer];
             Inc(SamplePointer);
             Loop_Sample_Position := Index[SamplePointer];
             Inc(SamplePointer);
            end;
           $70..$7f:
             OrnamentPointer :=
               PT1_OrnamentsPointers[Index[Address_In_Pattern] - $70];
           $80:
            begin
             Enabled := False;
             quit := True;
            end;
           $81:
             Envelope_Enabled := False;
           $82..$8f:
            begin
             Envelope_Enabled := True;
             SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $81);
             Inc(Address_In_Pattern);
             SoundChip[CNum].RegisterAY.Envelope := PWord(@Index[Address_In_Pattern])^;
             Inc(Address_In_Pattern);
            end;
           $90:
             quit := True;
           $91..$a0:
             PlParams[CNum].PT1.Delay := Index[Address_In_Pattern] - $91;
           $a1..$b0:
             Volume := Index[Address_In_Pattern] - $a1;
         else
           Number_Of_Notes_To_Skip := Index[Address_In_Pattern] - $b1;
          end;
       Inc(Address_In_Pattern)
     until quit;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

 procedure GetRegisters(var Chan: PT1_Channel_Parameters);
 var
   j, b: byte;
 begin
   with Chan do
     if Enabled then
       with PLConsts[CNum].RAM^ do
        begin
         j := Note + Index[OrnamentPointer + Position_In_Sample];
         if j > 95 then j := 95;
         b := Index[SamplePointer + Position_In_Sample * 3];
         Ton := word(b) shl 4 and $f00 + Index[SamplePointer +
           Position_In_Sample * 3 + 2];
         Amplitude := round((Volume * 17 + byte(Volume > 7)) * (b and 15) / 256);
         b := Index[SamplePointer + Position_In_Sample * 3 + 1];
         if b and 32 = 0 then Ton := -Ton;
         Ton := (Ton + PT3NoteTable_ST[j] + word(j = 46)) and $fff;
         if Envelope_Enabled then Amplitude := Amplitude or 16;
         if shortint(b) < 0 then
           TempMixer := TempMixer or 64
         else
           SoundChip[CNum].RegisterAY.Noise := b and 31;
         if b and 64 <> 0 then
           TempMixer := TempMixer or 8;
         Inc(Position_In_Sample);
         if Position_In_Sample = Sample_Length then
           Position_In_Sample := Loop_Sample_Position;
        end
     else
       Amplitude := 0;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].PT1 do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].PT1_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
        begin
         with PLConsts[CNum].RAM^ do
           if (Index[Address_In_Pattern] = 255) then
            begin
             Inc(CurrentPosition);
             if CurrentPosition = PT1_NumberOfPositions then
               CurrentPosition := PT1_LoopPosition;
             Address_In_Pattern :=
               PWord(@Index[PT1_PatternsPointer +
               PT1_PositionList[CurrentPosition] * 6])^;
             PlParams[CNum].PT1_B.Address_In_Pattern :=
               PWord(@Index[PT1_PatternsPointer +
               PT1_PositionList[CurrentPosition] * 6 + 2])^;
             PlParams[CNum].PT1_C.Address_In_Pattern :=
               PWord(@Index[PT1_PatternsPointer +
               PT1_PositionList[CurrentPosition] * 6 + 4])^;
            end;
         PatternInterpreter(PlParams[CNum].PT1_A);
        end;
      end;
     with PlParams[CNum].PT1_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].PT1_B);
      end;
     with PlParams[CNum].PT1_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].PT1_C);
      end;
     DelayCounter := Delay;
    end;
  end;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].PT1_A);
 GetRegisters(PlParams[CNum].PT1_B);
 GetRegisters(PlParams[CNum].PT1_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].PT1_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].PT1_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].PT1_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].PT1_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].PT1_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].PT1_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure FLS_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: FLS_Channel_Parameters);
 var
   quit: boolean;
 begin
   quit := False;
   with Chan do
    begin
     repeat
       with PLConsts[CNum].RAM^ do
         case Index[Address_In_Pattern] of
           0..$5f:
            begin
             Note := Index[Address_In_Pattern];
             Position_In_Sample := 0;
             Sample_Tik_Counter := $20;
             quit := True;
            end;
           $60..$6f:
            begin
             Loop_Sample_Position :=
               Index[FLS_SamplesPointer + (Index[Address_In_Pattern] -
               $60) * 4];
             Sample_Length := Index[FLS_SamplesPointer +
               (Index[Address_In_Pattern] - $60) * 4 + 1];
             SamplePointer :=
               PWord(@Index[FLS_SamplesPointer +
               (Index[Address_In_Pattern] - $60) * 4 + 2])^;
            end;
           $70:
            begin
             Ornament_Enabled := False;
             Envelope_Enabled := False;
            end;
           $71..$7f:
            begin
             OrnamentPointer :=
               PWord(@Index[FLS_OrnamentsPointer +
               (Index[Address_In_Pattern] - $71) * 2])^;
             Ornament_Enabled := True;
             Envelope_Enabled := False;
            end;
           $80:
            begin
             Sample_Tik_Counter := -1;
             quit := True;
            end;
           $81:
             quit := True;
           $82..$8e:
            begin
             SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $80);
             Envelope_Enabled := True;
             Ornament_Enabled := False;
             Inc(Address_In_Pattern);
             SoundChip[CNum].RegisterAY.Index[11] := Index[Address_In_Pattern];
            end
         else
           Number_Of_Notes_To_Skip := Index[Address_In_Pattern] - $a1
          end;
       Inc(Address_In_Pattern)
     until quit;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

 procedure GetRegisters(var Chan: FLS_Channel_Parameters);
 var
   j, b0, b1: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Sample_Tik_Counter >= 0 then
      begin
       Dec(Sample_Tik_Counter);
       if Sample_Tik_Counter = 0 then
         if Loop_Sample_Position = 0 then
          begin
           Dec(Sample_Tik_Counter);
           Amplitude := 0;
           TempMixer := TempMixer shr 1;
           exit;
          end
         else
          begin
           Sample_Tik_Counter := Sample_Length;
           Position_In_Sample := Loop_Sample_Position - 1;
          end;
       b0 := Index[SamplePointer + Position_In_Sample * 3];
       b1 := Index[SamplePointer + Position_In_Sample * 3 + 1];
       Amplitude := b0 and 15;
       if Envelope_Enabled then Amplitude := Amplitude or 16;
       if shortint(b1) < 0 then
         TempMixer := TempMixer or 64
       else
         SoundChip[CNum].RegisterAY.Noise := b1 and 31;
       if b1 and 64 <> 0 then
         TempMixer := TempMixer or 8;
       if Ornament_Enabled then
         j := Index[OrnamentPointer + Position_In_Sample]
       else
         j := 0;
       Inc(j, Note);
       if j > $5F then j := $5F;
       Ton := word(b0) shl 4 and $f00 + Index[SamplePointer +
         Position_In_Sample * 3 + 2];
       if b1 and 32 = 0 then
         Ton := -Ton;
       Ton := (Ton + ST_Table[j]) and $fff;
       Position_In_Sample := (Position_In_Sample + 1) and 31;
      end
     else
       Amplitude := 0;
     TempMixer := TempMixer shr 1;
    end;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].FLS do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].FLS_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         with PLConsts[CNum].RAM^ do
          begin
           if Index[Address_In_Pattern] = 255 then
            begin
             Inc(CurrentPosition);
             if Index[CurrentPosition + FLS_PositionsPointer + 1] = 0 then
               CurrentPosition := 0;
             Address_In_Pattern :=
               FLS_PatternsPointers[Index[CurrentPosition +
               FLS_PositionsPointer + 1]].PatternA;
             PlParams[CNum].FLS_B.Address_In_Pattern :=
               FLS_PatternsPointers[Index[CurrentPosition +
               FLS_PositionsPointer + 1]].PatternB;
             PlParams[CNum].FLS_C.Address_In_Pattern :=
               FLS_PatternsPointers[Index[CurrentPosition +
               FLS_PositionsPointer + 1]].PatternC;
            end;
           PatternInterpreter(PlParams[CNum].FLS_A);
          end;
      end;
     with PlParams[CNum].FLS_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].FLS_B);
      end;
     with PlParams[CNum].FLS_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].FLS_C);
      end;
     DelayCounter := Delay;
    end;
  end;

 TempMixer := 0;
 GetRegisters(PlParams[CNum].FLS_A);
 GetRegisters(PlParams[CNum].FLS_B);
 GetRegisters(PlParams[CNum].FLS_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].FLS_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].FLS_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].FLS_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].FLS_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].FLS_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].FLS_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure GTR_Get_Registers(CNum: integer);
var
 TempMixer: byte;

 procedure PatternInterpreter(var Chan: GTR_Channel_Parameters);
 begin
   with Chan do
    begin
     Note_Skip_Counter := 0;
     repeat
       with PLConsts[CNum].RAM^ do
         case Index[Address_In_Pattern] of
           0..$5f:
            begin
             Note := Index[Address_In_Pattern];
             Position_In_Sample := 0;
             Position_In_Ornament := 0;
             Enabled := True;
             Inc(Address_In_Pattern);
             exit;
            end;
           $60..$6f:
            begin
             SamplePointer := GTR_SamplesPointers[Index[Address_In_Pattern] - $60];
             Loop_Sample_Position := Index[Chan.SamplePointer];
             Inc(SamplePointer);
             Sample_Length := Index[SamplePointer];
             Inc(SamplePointer);
            end;
           $70..$7F:
            begin
             OrnamentPointer :=
               GTR_OrnamentsPointers[Index[Address_In_Pattern] - $70];
             Loop_Ornament_Position := Index[Chan.OrnamentPointer];
             Inc(Chan.OrnamentPointer);
             Ornament_Length := Index[Chan.OrnamentPointer];
             Inc(OrnamentPointer);
             Position_In_Ornament := 0;
             if GTR_ID[3] <> #$10 then
               Envelope_Enabled := False;
            end;
           $80..$BF:
             Note_Skip_Counter := Index[Address_In_Pattern] - $80;
           $C0..$CF:
            begin
             SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $C0);
             Inc(Address_In_Pattern);
             SoundChip[CNum].RegisterAY.Index[11] := Index[Address_In_Pattern];
             Envelope_Enabled := True;
            end;
           $D0..$DF:
            begin
             Inc(Address_In_Pattern);
             exit;
            end;
           $E0:
            begin
             Enabled := False;
             if GTR_ID[3] <> #$10 then
              begin
               Inc(Address_In_Pattern);
               exit;
              end;
            end;
           $E1..$EF:
             Volume := 15 - (Index[Address_In_Pattern] - $E0)
          end;
       Inc(Address_In_Pattern)
     until False;
    end;
 end;

 procedure GetRegisters(var Chan: GTR_Channel_Parameters);
 var
   j, b: byte;
 begin
   with Chan do
    begin
     if Enabled then
       with PLConsts[CNum].RAM^ do
        begin
         j := Note + Index[OrnamentPointer + Position_In_Ornament];
         if j > $5f then j := $5f;
         Inc(Position_In_Ornament);
         if Position_In_Ornament = Ornament_Length then
           Position_In_Ornament := Loop_Ornament_Position;
         Ton := (PT3NoteTable_ST[j] +
           PWord(@Index[SamplePointer + Position_In_Sample + 2])^) and $FFF;
         b := Index[SamplePointer + Position_In_Sample + 1];
         SoundChip[CNum].RegisterAY.Noise :=
           (SoundChip[CNum].RegisterAY.Noise or b) and $1F;
         Amplitude := Index[SamplePointer + Position_In_Sample] - Volume;
         if shortint(Amplitude) < 0 then Amplitude := 0;
         Amplitude := Amplitude and $F;
         if shortint(b) < 0 then
           if Envelope_Enabled then Amplitude := Amplitude or 16;
         if b and 64 <> 0 then
           TempMixer := TempMixer or 64;
         if b and 32 <> 0 then
           TempMixer := TempMixer or 8;
         Inc(Position_In_Sample, 4);
         if Position_In_Sample = Sample_Length then
           Position_In_Sample := Loop_Sample_Position;
        end
     else
      begin
       Amplitude := 0;
       TempMixer := TempMixer or 8 or 64;
      end;
    end;
   TempMixer := TempMixer shr 1;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].GTR do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     DelayCounter := PLConsts[CNum].RAM^.GTR_Delay;
     with PlParams[CNum].GTR_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
        begin
         with PLConsts[CNum].RAM^ do
           while Index[Address_In_Pattern] = 255 do
            begin
             Inc(CurrentPosition);
             if CurrentPosition = GTR_NumberOfPositions then
               CurrentPosition := GTR_LoopPosition;
             Address_In_Pattern :=
               GTR_PatternsPointers[GTR_Positions[CurrentPosition] div 6].PatternA;
             PlParams[CNum].GTR_B.Address_In_Pattern :=
               GTR_PatternsPointers[GTR_Positions[CurrentPosition] div 6].PatternB;
             PlParams[CNum].GTR_C.Address_In_Pattern :=
               GTR_PatternsPointers[GTR_Positions[CurrentPosition] div 6].PatternC;
            end;
         PatternInterpreter(PlParams[CNum].GTR_A);
        end;
      end;
     with PlParams[CNum].GTR_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].GTR_B);
      end;
     with PlParams[CNum].GTR_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter < 0 then
         PatternInterpreter(PlParams[CNum].GTR_C);
      end;
    end;
  end;

 TempMixer := 0;
 SoundChip[CNum].RegisterAY.Noise := 0;
 GetRegisters(PlParams[CNum].GTR_A);
 GetRegisters(PlParams[CNum].GTR_B);
 GetRegisters(PlParams[CNum].GTR_C);

 SoundChip[CNum].SetMixerRegister(TempMixer);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].GTR_A.Ton;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].GTR_B.Ton;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].GTR_C.Ton;

 SoundChip[CNum].SetAmplA(PlParams[CNum].GTR_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].GTR_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].GTR_C.Amplitude);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure FXM_Get_Registers(CNum: integer);

 procedure RealGetRegisters(var Chan: FXM_Channel_Parameters);
 begin
   SoundChip[CNum].RegisterAY.Noise := PlParams[CNum].FXM.Noise_Base and 31;
   with Chan do
    begin
     b2e := False;
     if Ton <> 0 then
       Amplitude := Volume and 15
     else
       Amplitude := 0;
    end;
 end;

 procedure GetRegisters(var Chan: FXM_Channel_Parameters);
 var
   b: byte;
 begin
   with Chan do
    begin
     Dec(Sample_Tik_Counter);
     if Sample_Tik_Counter = 0 then
      begin
       repeat
         with PLConsts[CNum].RAM^ do
           case Index[Chan.Point_In_Sample] of
             0..$1D:
              begin
               Volume := Index[Point_In_Sample];
               Inc(Point_In_Sample);
               Sample_Tik_Counter := Index[Point_In_Sample];
               Inc(Point_In_Sample);
               break;
              end;
             $80:
               Point_In_Sample := PWord(@Index[Point_In_Sample + 1])^
           else
            begin
             Volume := Index[Point_In_Sample] - $32;
             Inc(Point_In_Sample);
             Sample_Tik_Counter := 1;
             break;
            end;
            end
       until False;
      end;
     if (Ton <> 0) and not b2e then
      begin
       repeat
         with PLConsts[CNum].RAM^ do
           case Index[Point_In_Ornament] of
             $80:
               Point_In_Ornament := PWord(@Index[Point_In_Ornament + 1])^;
             $82:
              begin
               Inc(Point_In_Ornament);
               b3e := True;
              end;
             $83:
              begin
               Inc(Chan.Point_In_Ornament);
               b3e := False;
              end;
             $84:
              begin
               Inc(Point_In_Ornament);
               FXM_Mixer := FXM_Mixer xor 9;
              end
           else
            begin
             if b3e then
              begin
               Inc(Note, Index[Point_In_Ornament]);
               if Note > $53 then b := $53
               else
                 b := Note;
               Ton := FXM_Table[b];
              end
             else
               Inc(Ton, shortint(Index[Point_In_Ornament]));
             Inc(Point_In_Ornament);
             break;
            end;
            end;
       until False;
      end;
    end;
   RealGetRegisters(Chan);
 end;

 procedure PatternInterpreter(var Chan: FXM_Channel_Parameters; var Stek: FXM_Stek);
 var
   b: byte;
   i: integer;
 begin
   with Chan do
    begin
     Dec(Note_Skip_Counter);
     if Note_Skip_Counter <> 0 then
       GetRegisters(Chan)
     else
       repeat
         with PLConsts[CNum].RAM^ do
           case Index[Address_In_Pattern] of
             0..$7F:
              begin
               if Index[Address_In_Pattern] <> 0 then
                begin
                 Note := Index[Address_In_Pattern] - 1 + Transposit;
                 if Note > $53 then b := $53
                 else
                   b := Note;
                 Ton := FXM_Table[b];
                 b3e := False;
                end
               else
                 Ton := 0;
               Inc(Address_In_Pattern);
               Note_Skip_Counter := Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
               Point_In_Ornament := OrnamentPointer;
               if not b1e then
                begin
                 b1e := b0e;
                 Point_In_Sample := SamplePointer;
                 Volume := Index[Point_In_Sample];
                 Inc(Point_In_Sample);
                 Sample_Tik_Counter := Index[Point_In_Sample];
                 Inc(Point_In_Sample);
                 RealGetRegisters(Chan);
                end
               else
                 GetRegisters(Chan);
               exit;
              end;
             $80:
               Address_In_Pattern := PWord(@Index[Address_In_Pattern + 1])^;
             $81:
              begin
               i := Length(Stek);
               SetLength(Stek, i + 1);
               Stek[i] := Address_In_Pattern + 3;
               Address_In_Pattern := PWord(@Index[Address_In_Pattern + 1])^;
              end;
             $82:
              begin
               i := Length(Stek);
               SetLength(Stek, i + 2);
               Inc(Address_In_Pattern);
               Stek[i] := Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
               Stek[i + 1] := Address_In_Pattern;
              end;
             $83:
              begin
               i := Length(Stek);
               Dec(Stek[i - 2]);
               if Stek[i - 2] and 255 <> 0 then
                 Address_In_Pattern := Stek[i - 1]
               else
                begin
                 SetLength(Stek, i - 2);
                 Inc(Address_In_Pattern);
                end;
              end;
             $84:
              begin
               Inc(Address_In_Pattern);
               PlParams[CNum].FXM.Noise_Base := Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
              end;
             $85:
              begin
               Inc(Address_In_Pattern);
               FXM_Mixer := Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
              end;
             $86:
              begin
               Inc(Address_In_Pattern);
               OrnamentPointer := PWord(@Index[Address_In_Pattern])^;
               Inc(Address_In_Pattern, 2);
              end;
             $87:
              begin
               Inc(Address_In_Pattern);
               SamplePointer := PWord(@Index[Address_In_Pattern])^;
               Inc(Address_In_Pattern, 2);
              end;
             $88:
              begin
               Inc(Address_In_Pattern);
               Transposit := Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
              end;
             $89:
              begin
               i := Length(Stek);
               Address_In_Pattern := Stek[i - 1];
               SetLength(Stek, i - 1);
              end;
             $8A:
              begin
               Inc(Address_In_Pattern);
               b0e := True;
               b1e := False;
              end;
             $8B:
              begin
               Inc(Address_In_Pattern);
               b0e := False;
               b1e := False;
              end;
             $8C:
               Inc(Chan.Address_In_Pattern, 3);
             $8D:
              begin
               Inc(Address_In_Pattern);
               PlParams[CNum].FXM.Noise_Base :=
                 (PlParams[CNum].FXM.Noise_Base +
                 Index[Address_In_Pattern]) and PlConsts[CNum].amad_andsix;
               Inc(Address_In_Pattern);
              end;
             $8E:
              begin
               Inc(Address_In_Pattern);
               Transposit := Transposit + Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
              end;
             $8F:
              begin
               i := Length(Stek);
               SetLength(Stek, i + 1);
               Stek[i] := Transposit;
               Inc(Address_In_Pattern);
              end;
             $90:
              begin
               i := Length(Stek);
               Transposit := Stek[i - 1];
               SetLength(Stek, i - 1);
               Inc(Address_In_Pattern);
              end
           else
             Inc(Address_In_Pattern);
            end;
       until False;
    end;
 end;

begin
 if CheckLoopAndStop(CNum) then
   Exit;

 PatternInterpreter(PlParams[CNum].FXM_A, FXM_StekA);
 PatternInterpreter(PlParams[CNum].FXM_B, FXM_StekB);
 PatternInterpreter(PlParams[CNum].FXM_C, FXM_StekC);

 SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].FXM_A.Ton and $fff;
 SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].FXM_B.Ton and $fff;
 SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].FXM_C.Ton and $fff;

 SoundChip[CNum].SetAmplA(PlParams[CNum].FXM_A.Amplitude);
 SoundChip[CNum].SetAmplB(PlParams[CNum].FXM_B.Amplitude);
 SoundChip[CNum].SetAmplC(PlParams[CNum].FXM_C.Amplitude);

 SoundChip[CNum].SetMixerRegister(
   (PlParams[CNum].FXM_A.FXM_Mixer or PlParams[CNum].FXM_B.FXM_Mixer shl
   1 or PlParams[CNum].FXM_C.FXM_Mixer shl 2) and $3F);

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure PSM_Get_Registers(CNum: integer);

 procedure PatternInterpreter(var Chan: PSM_Channel_Parameters);
 var
   PatAddr: word;
   b: byte;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     PatAddr := Address_In_Pattern;
     if RetCnt <> 0 then
      begin
       Dec(RetCnt);
       if RetCnt = 0 then PatAddr := RetAddress;
      end;
     repeat
       case Index[PatAddr] of
         0..$5F:
          begin
           if Note < 0 then
             Note := PlParams[CNum].PSM.Transposition - Index[PatAddr]
           else
             Dec(Note, Index[PatAddr]);
           if Note < 0 then Inc(Note, 96);
           VolCnt := Vol;
           SmpTick := 0;
           DivShift := 0;
           LoopCnt := 1;
           if OrnTick < 0 then
             OrnTick := OrnTick and $E0
           else
             OrnTick := OrnTick and $C0;
           if (OrnTick and $40 <> 0) and (Orn >= 33) then
            begin
             if EnvType >= $b1 then
              begin
               SoundChip[CNum].SetEnvelopeRegister(EnvType - $b1 + 8);
               if EnvDiv >= $f1 then
                 SoundChip[CNum].RegisterAY.Envelope := word(EnvDiv and 15) shl 8
               else
                 SoundChip[CNum].RegisterAY.Envelope := EnvDiv;
               OrnTick := OrnTick or $40;
              end
             else
              begin
               b := EnvType - $a1;
               SoundChip[CNum].SetEnvelopeRegister(((b and 3) shl 1) or 8);
               b := (b and 12) * 3 + Note;
               if b >= 48 then
                begin
                 Dec(b, 48);
                 if b >= 48 then Dec(b, 48);
                end;
               SoundChip[CNum].RegisterAY.Envelope := PSM_Table[b + 48];
              end;
            end;
           Inc(PatAddr);
           break;
          end;
         $60:
          begin
           SmpTick := byte(SmpTick) or 128;
           Inc(PatAddr);
           break;
          end;
         $61..$6f:
           Samp := Index[PatAddr] - $61;
         $70..$8f:
          begin
           Orn := Index[PatAddr] - $70;
           OrnTick := 0;
          end;
         $90:
          begin
           Inc(PatAddr);
           break;
          end;
         $91..$9f:
           Vol := Index[PatAddr] - $90;
         $a0:
           OrnTick := Index[PatAddr]; // $a0
         $a1..$b0:
          begin
           Orn := 33;
           EnvType := Index[PatAddr];
           OrnTick := OrnTick or $40;
          end;
         $b1..$b7:
          begin
           EnvType := Index[PatAddr];
           Inc(PatAddr);
           EnvDiv := Index[PatAddr];
           SoundChip[CNum].SetEnvelopeRegister(EnvType - $b1 + 8);
           if EnvDiv >= $f1 then
             SoundChip[CNum].RegisterAY.Envelope := word(EnvDiv and 15) shl 8
           else
             SoundChip[CNum].RegisterAY.Envelope := EnvDiv;
           OrnTick := OrnTick or $40;
          end;
         $b8..$f8:
           Number_Of_Notes_To_Skip := Index[PatAddr] - $b7;
         $f9:
          begin
           RetAddress := PatAddr + 4;
           RetCnt := Index[word(PatAddr + 3)];
           PatAddr := PWord(@Index[PatAddr + 1])^ - 1;
          end;
         $fa..$fb:
           Orn := Index[PatAddr] - $fa + 32;
       else
        begin
         Inc(PatAddr);
         break;
        end
        end;
       Inc(PatAddr)
     until False;
     Address_In_Pattern := PatAddr;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

var
 TempMixer: byte;

 procedure ChangeRegisters(var Chan: PSM_Channel_Parameters);
 var
   b, b1, b2: byte;
   w, wo, ws: word;
 begin

   //CBA
   //  TempMixer := TempMixer shl 1;

   with Chan, PLConsts[CNum].RAM^ do
    begin
     b := Note and 127;
     b2 := OrnTick;
     wo := PWord(@PLConsts[CNum].RAM^.Index[PSM_OrnamentsPointer + Orn * 2])^;
     if OrnTick and $60 = 0 then
       Inc(b, Index[wo + 2 + b2]);
     if shortint(b) < 0 then b := 0
     else if b > 95 then b := 95;
     Ton := PSM_Table[b];

     b2 := SmpTick * 3;
     ws := PWord(@Index[PSM_SamplesPointer + Samp * 2])^;
     b := Index[ws + 2 + b2];
     b1 := Index[ws + 2 + b2 + 1];
     b2 := Index[ws + 2 + b2 + 2];

     w := word(b1 and 7) shl 8 + b2;
     if b1 and 4 <> 0 then w := w or $f800;

     Inc(DivShift, w);
     Inc(Ton, DivShift);
     if smallint(Ton) < 0 then Ton := 0
     else if Ton >= 4096 then Ton := 4095;

     Amplitude := b and 15;
     if OrnTick and $40 <> 0 then
       Amplitude := Amplitude or 16;
     Inc(Amplitude, VolCnt - 15);
     if (shortint(Amplitude) < 0) or (shortint(SmpTick) < 0) then Amplitude := 0;

     //CBA
     //    TempMixer := b shr 4 and 9 or TempMixer;
     //    if shortint(SmpTick) < 0 then TempMixer := TempMixer or 8;

     //ABC
     TempMixer := b shr 1 and $48 or TempMixer;
     if shortint(SmpTick) < 0 then TempMixer := TempMixer or $40;

     if (shortint(b) >= 0) and (Amplitude <> 0) then
       SoundChip[CNum].RegisterAY.Noise := b1 shr 3;

     b := SmpTick and 31 + 1;
     b1 := Index[ws];
     b2 := Index[ws + 1];
     if b > (b1 and 31) then
       if b2 and $e0 = 0 then
         SmpTick := byte(SmpTick) or 128
       else
        begin
         b := b2 and 31;
         Dec(LoopCnt);
         if LoopCnt = 0 then
          begin
           LoopCnt := b2 shr 5;
           if b1 and $20 = 0 then
             Inc(VolCnt, b1 shr 6)
           else
             Dec(VolCnt, b1 shr 6 + 1);
           if shortint(VolCnt) < 0 then VolCnt := 0
           else if VolCnt > 15 then VolCnt := 15;
          end;
        end;
     SmpTick := ((b xor byte(SmpTick)) and 31) xor byte(SmpTick);

     b := OrnTick and 31 + 1;
     b1 := Index[wo];
     b2 := Index[wo + 1];
     if b > b1 then
      begin
       if shortint(b2) < 0 then
         b := b2
       else
         OrnTick := OrnTick or $20;
      end;
     OrnTick := ((b xor byte(OrnTick)) and 31) xor byte(OrnTick);

    end;

   //ABC
   TempMixer := TempMixer shr 1;

 end;

var
 b: byte;
begin
 if CheckLoopAndStop(CNum) then
   Exit;

 Inc(PlConsts[CNum].Global_Tick_Counter);

 SoundChip[CNum].SetAmplA(0);
 SoundChip[CNum].SetAmplB(0);
 SoundChip[CNum].SetAmplC(0);

 with PlParams[CNum].PSM do
  begin
   if Finished then exit;
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].PSM_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         with PLConsts[CNum].RAM^ do
          begin
           if Index[Address_In_Pattern] = 255 then
            begin
             Inc(CurrentPosition);
             b := Index[PSM_PositionsPointer + CurrentPosition * 2];
             if b = 255 then
              begin
               b := Index[PSM_PositionsPointer + CurrentPosition * 2 + 1];
               if b = 255 then
                begin
                 Finished := True;
                 exit;
                end;
               CurrentPosition := b;
               b := Index[PSM_PositionsPointer + b * 2];
              end;
             Transposition := Index[PSM_PositionsPointer +
               CurrentPosition * 2 + 1] + 48;
             Delay := Index[PSM_PatternsPointer + b * 7];
             PlParams[CNum].PSM_A.Address_In_Pattern :=
               PWord(@Index[PSM_PatternsPointer + b * 7 + 1])^;
             PlParams[CNum].PSM_B.Address_In_Pattern :=
               PWord(@Index[PSM_PatternsPointer + b * 7 + 3])^;
             Address_In_Pattern :=
               PWord(@Index[PSM_PatternsPointer + b * 7 + 5])^;
             PlParams[CNum].PSM_A.RetCnt := 0;
             PlParams[CNum].PSM_B.RetCnt := 0;
             RetCnt := 0;
             PlParams[CNum].PSM_A.Note_Skip_Counter := 1;
             PlParams[CNum].PSM_B.Note_Skip_Counter := 1;
             PlParams[CNum].PSM_A.Note := byte(PlParams[CNum].PSM_A.Note) or 128;
             PlParams[CNum].PSM_B.Note := byte(PlParams[CNum].PSM_B.Note) or 128;
             Note := byte(Note) or 128;
            end;
           PatternInterpreter(PlParams[CNum].PSM_C);
          end;
      end;
     with PlParams[CNum].PSM_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then PatternInterpreter(PlParams[CNum].PSM_B);
      end;
     with PlParams[CNum].PSM_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then PatternInterpreter(PlParams[CNum].PSM_A);
      end;
     DelayCounter := Delay;
    end;
   TempMixer := 0;
   ChangeRegisters(PlParams[CNum].PSM_A);
   ChangeRegisters(PlParams[CNum].PSM_B);
   ChangeRegisters(PlParams[CNum].PSM_C);

   SoundChip[CNum].SetMixerRegister(TempMixer);

   SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].PSM_A.Ton;
   SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].PSM_B.Ton;
   SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].PSM_C.Ton;

   SoundChip[CNum].SetAmplA(PlParams[CNum].PSM_A.Amplitude);
   SoundChip[CNum].SetAmplB(PlParams[CNum].PSM_B.Amplitude);
   SoundChip[CNum].SetAmplC(PlParams[CNum].PSM_C.Amplitude);

  end;

end;

procedure MakeBufferTracker(Buf: pointer);
begin
 BuffLen := 0;
 if IntFlag then SynthesizerZX50(Buf);
 if IntFlag then exit;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   Real_End_All := True;
   All_GetRegisters[0](0);
   Real_End_All := Real_End_All and Real_End[0];
   if TSMode then
    begin
     All_GetRegisters[1](1);
     Real_End_All := Real_End_All and Real_End[1];
    end;
   if not Real_End_All then SynthesizerZX50(Buf);
  end;
end;

procedure PT3_Get_Registers(CNum: integer);

 function GetNoteFreq(j: integer): integer;
 begin
   case PLConsts[CNum].RAM^.PT3_TonTableId of
     0: if PlConsts[CNum].Version <= 3 then
         Result := PT3NoteTable_PT_33_34r[j]
       else
         Result := PT3NoteTable_PT_34_35[j];
     1: Result := PT3NoteTable_ST[j];
     2: if PlConsts[CNum].Version <= 3 then
         Result := PT3NoteTable_ASM_34r[j]
       else
         Result := PT3NoteTable_ASM_34_35[j];
   else
     if PlConsts[CNum].Version <= 3 then
       Result := PT3NoteTable_REAL_34r[j]
     else
       Result := PT3NoteTable_REAL_34_35[j]
    end;
 end;

 procedure PatternInterpreter(var Chan: PT3_Channel_Parameters);
 var
   quit: boolean;
   Flag9, Flag8, Flag5, Flag4, Flag3, Flag2, Flag1: byte;
   counter, b: byte;
   PrNote, PrSliding: integer;
 begin
   PrNote := Chan.Note;
   PrSliding := Chan.Current_Ton_Sliding;
   quit := False;
   counter := 0;
   Flag9 := 0;
   Flag8 := 0;
   Flag5 := 0;
   Flag4 := 0;
   Flag3 := 0;
   Flag2 := 0;
   Flag1 := 0;
   with Chan, PLConsts[CNum].RAM^ do
    begin
     repeat
       case Index[Address_In_Pattern] of
         $f0..$ff:
          begin
           OrnamentPointer :=
             PT3_OrnamentsPointers[Index[Address_In_Pattern] - $f0];
           Loop_Ornament_Position := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Ornament_Length := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Inc(Address_In_Pattern);
           SamplePointer := PT3_SamplesPointers[Index[Address_In_Pattern] div 2];
           Loop_Sample_Position := Index[SamplePointer];
           Inc(SamplePointer);
           Sample_Length := Index[SamplePointer];
           Inc(SamplePointer);
           Envelope_Enabled := False;
           Position_In_Ornament := 0;
          end;
         $d1..$ef:
          begin
           SamplePointer := PT3_SamplesPointers[Index[Address_In_Pattern] - $d0];
           Loop_Sample_Position := Index[SamplePointer];
           Inc(SamplePointer);
           Sample_Length := Index[SamplePointer];
           Inc(SamplePointer);
          end;
         $d0:
           quit := True;
         $c1..$cf:
           Volume := Index[Address_In_Pattern] - $c0;
         $c0:
          begin
           Position_In_Sample := 0;
           Current_Amplitude_Sliding := 0;
           Current_Noise_Sliding := 0;
           Current_Envelope_Sliding := 0;
           Position_In_Ornament := 0;
           Ton_Slide_Count := 0;
           Current_Ton_Sliding := 0;
           Ton_Accumulator := 0;
           Current_OnOff := 0;
           Enabled := False;
           quit := True;
          end;
         $b2..$bf:
          begin
           Envelope_Enabled := True;
           SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $b1);
           Inc(Address_In_Pattern);
           with PlParams[CNum].PT3 do
            begin
             Env_Base.hi := Index[Address_In_Pattern];
             Inc(Address_In_Pattern);
             Env_Base.lo := Index[Address_In_Pattern];
             Position_In_Ornament := 0;
             Cur_Env_Slide := 0;
             Cur_Env_Delay := 0;
            end;
          end;
         $b1:
          begin
           Inc(Address_In_Pattern);
           Number_Of_Notes_To_Skip := Index[Address_In_Pattern];
          end;
         $b0:
          begin
           Envelope_Enabled := False;
           Position_In_Ornament := 0;
          end;
         $50..$af:
          begin
           Note := Index[Address_In_Pattern] - $50;
           Position_In_Sample := 0;
           Current_Amplitude_Sliding := 0;
           Current_Noise_Sliding := 0;
           Current_Envelope_Sliding := 0;
           Position_In_Ornament := 0;
           Ton_Slide_Count := 0;
           Current_Ton_Sliding := 0;
           Ton_Accumulator := 0;
           Current_OnOff := 0;
           Enabled := True;
           quit := True;
          end;
         $40..$4f:
          begin
           OrnamentPointer :=
             PT3_OrnamentsPointers[Index[Address_In_Pattern] - $40];
           Loop_Ornament_Position := Index[Chan.OrnamentPointer];
           Inc(OrnamentPointer);
           Ornament_Length := Index[OrnamentPointer];
           Inc(OrnamentPointer);
           Position_In_Ornament := 0;
          end;
         $20..$3f:
           PlParams[CNum].PT3.Noise_Base := Index[Address_In_Pattern] - $20;
         $10..$1f:
          begin
           if Index[Address_In_Pattern] = $10 then
             Envelope_Enabled := False
           else
            begin
             SoundChip[CNum].SetEnvelopeRegister(Index[Address_In_Pattern] - $10);
             Inc(Address_In_Pattern);
             with PlParams[CNum].PT3 do
              begin
               Env_Base.hi := Index[Address_In_Pattern];
               Inc(Address_In_Pattern);
               Env_Base.lo := Index[Address_In_Pattern];
               Envelope_Enabled := True;
               Cur_Env_Slide := 0;
               Cur_Env_Delay := 0;
              end;
            end;
           Inc(Address_In_Pattern);
           SamplePointer := PT3_SamplesPointers[Index[Address_In_Pattern] div 2];
           Loop_Sample_Position := Index[SamplePointer];
           Inc(SamplePointer);
           Sample_Length := Index[SamplePointer];
           Inc(SamplePointer);
           Position_In_Ornament := 0;
          end;
         $9:
          begin
           Inc(counter);
           Flag9 := counter;
          end;
         $8:
          begin
           Inc(counter);
           Flag8 := counter;
          end;
         $5:
          begin
           Inc(counter);
           Flag5 := counter;
          end;
         $4:
          begin
           Inc(counter);
           Flag4 := counter;
          end;
         $3:
          begin
           Inc(counter);
           Flag3 := counter;
          end;
         $2:
          begin
           Inc(counter);
           Flag2 := counter;
          end;
         $1:
          begin
           Inc(counter);
           Flag1 := counter;
          end
        end;
       Inc(Address_In_Pattern)
     until quit;
     while counter > 0 do
      begin
       if (counter = Flag1) then
        begin
         Ton_Slide_Delay := Index[Address_In_Pattern];
         Ton_Slide_Count := Ton_Slide_Delay;
         Inc(Address_In_Pattern);
         Ton_Slide_Step := PWord(@Index[Address_In_Pattern])^;
         Inc(Address_In_Pattern, 2);
         SimpleGliss := True;
         Current_OnOff := 0;
         if (Ton_Slide_Count = 0) and (PlConsts[CNum].Version >= 7) then
           Inc(Ton_Slide_Count);
        end
       else if (counter = Flag2) then
        begin
         SimpleGliss := False;
         Current_OnOff := 0;
         Ton_Slide_Delay := Index[Address_In_Pattern];
         Ton_Slide_Count := Ton_Slide_Delay;
         Inc(Address_In_Pattern, 3);
         Ton_Slide_Step := Abs(smallint(PWord(@Index[Address_In_Pattern])^));
         Inc(Address_In_Pattern, 2);
         Ton_Delta := GetNoteFreq(Note) - GetNoteFreq(PrNote);
         Slide_To_Note := Note;
         Note := PrNote;
         if PlConsts[CNum].Version >= 6 then
           Current_Ton_Sliding := PrSliding;
         if Ton_Delta - Current_Ton_Sliding < 0 then
           Ton_Slide_Step := -Ton_Slide_Step;
        end
       else if counter = Flag3 then
        begin
         Position_in_Sample := Index[Address_In_Pattern];
         Inc(Address_In_Pattern);
        end
       else if counter = Flag4 then
        begin
         Position_in_Ornament := Index[Address_In_Pattern];
         Inc(Address_In_Pattern);
        end
       else if counter = Flag5 then
        begin
         OnOff_Delay := Index[Address_In_Pattern];
         Inc(Address_In_Pattern);
         OffOn_Delay := Index[Address_In_Pattern];
         Current_OnOff := OnOff_Delay;
         Inc(Address_In_Pattern);
         Ton_Slide_Count := 0;
         Current_Ton_Sliding := 0;
        end
       else if counter = Flag8 then
        begin
         with PlParams[CNum].PT3 do
          begin
           Env_Delay := Index[Address_In_Pattern];
           Cur_Env_Delay := Env_Delay;
           Inc(Address_In_Pattern);
           Env_Slide_Add := PWord(@Index[Address_In_Pattern])^;
          end;
         Inc(Address_In_Pattern, 2);
        end
       else if counter = Flag9 then
        begin
         b := Index[Address_In_Pattern];
         PlParams[CNum].PT3.Delay := b;
         if TSMode and (PLConsts[1].TS <> $20) then
          begin
           PlParams[0].PT3.Delay := b;
           PlParams[0].PT3.DelayCounter := b;
           PlParams[1].PT3.Delay := b;
          end;
         Inc(Address_In_Pattern);
        end;
       Dec(counter);
      end;
     Note_Skip_Counter := Number_Of_Notes_To_Skip;
    end;
 end;

var
 TempMixer: byte;
 AddToEnv: shortint;

 procedure ChangeRegisters(var Chan: PT3_Channel_Parameters);
 var
   j, b1, b0: byte;
   w: word;
 begin
   with Chan, PLConsts[CNum].RAM^ do
    begin
     if Enabled then
      begin
       Ton := PWord(@Index[SamplePointer + Position_In_Sample * 4 + 2])^;
       Inc(Ton, Ton_Accumulator);
       b0 := Index[SamplePointer + Position_In_Sample * 4];
       b1 := Index[SamplePointer + Position_In_Sample * 4 + 1];
       if b1 and $40 <> 0 then
         Ton_Accumulator := Ton;
       j := Note + Index[OrnamentPointer + Position_In_Ornament];
       if shortint(j) < 0 then j := 0
       else if j > 95 then j := 95;
       w := GetNoteFreq(j);
       Ton := (Ton + Current_Ton_Sliding + w) and $fff;
       if Ton_Slide_Count > 0 then
        begin
         Dec(Ton_Slide_Count);
         if Ton_Slide_Count = 0 then
          begin
           Inc(Current_Ton_Sliding, Ton_Slide_Step);
           Ton_Slide_Count := Ton_Slide_Delay;
           if not SimpleGliss then
             if ((Ton_Slide_Step < 0) and (Current_Ton_Sliding <= Ton_Delta)) or
               ((Ton_Slide_Step >= 0) and (Current_Ton_Sliding >= Ton_Delta)) then
              begin
               Note := Slide_To_Note;
               Ton_Slide_Count := 0;
               Current_Ton_Sliding := 0;
              end;
          end;
        end;
       Amplitude := b1 and $f;
       if b0 and $80 <> 0 then
         if b0 and $40 <> 0 then
          begin
           if Current_Amplitude_Sliding < 15 then
             Inc(Current_Amplitude_Sliding);
          end
         else if Current_Amplitude_Sliding > -15 then
           Dec(Current_Amplitude_Sliding);
       Inc(Amplitude, Current_Amplitude_Sliding);
       if shortint(Amplitude) < 0 then Amplitude := 0
       else if Amplitude > 15 then Amplitude := 15;
       if PlConsts[CNum].Version <= 4 then
         Amplitude := PT3VolumeTable_33_34[Volume, Amplitude]
       else
         Amplitude := PT3VolumeTable_35[Volume, Amplitude];
       if (b0 and 1 = 0) and Envelope_Enabled then
         Amplitude := Amplitude or 16;
       if b1 and $80 <> 0 then
        begin
         if b0 and $20 <> 0 then
           j := (b0 shr 1) or $F0 + Current_Envelope_Sliding
         else
           j := (b0 shr 1) and $F + Current_Envelope_Sliding;
         if b1 and $20 <> 0 then Current_Envelope_Sliding := j;
         Inc(AddToEnv, j);
        end
       else
        begin
         PlParams[CNum].PT3.AddToNoise := b0 shr 1 + Current_Noise_Sliding;
         if b1 and $20 <> 0 then
           Current_Noise_Sliding := PlParams[CNum].PT3.AddToNoise;
        end;
       TempMixer := b1 shr 1 and $48 or TempMixer;
       Inc(Position_In_Sample);
       if Position_In_Sample >= Sample_Length then
         Position_In_Sample := Loop_Sample_Position;
       Inc(Position_In_Ornament);
       if Position_In_Ornament >= Ornament_Length then
         Position_In_Ornament := Loop_Ornament_Position;
      end
     else
       Amplitude := 0;
     TempMixer := TempMixer shr 1;
     if Current_OnOff > 0 then
      begin
       Dec(Current_OnOff);
       if Current_OnOff = 0 then
        begin
         Enabled := not Enabled;
         if Enabled then Current_OnOff := OnOff_Delay
         else
           Current_OnOff := OffOn_Delay;
        end;
      end;
    end;
 end;

var
 i, b: integer;
begin
 if CheckLoopAndStop(CNum) then
   Exit;
 with PlParams[CNum].PT3 do
  begin
   Dec(DelayCounter);
   if DelayCounter = 0 then
    begin
     with PlParams[CNum].PT3_A do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         with PLConsts[CNum].RAM^ do
          begin
           if (Index[Address_In_Pattern] = 0) then
            begin
             Inc(CurrentPosition);
             if CurrentPosition = PT3_NumberOfPositions then
               CurrentPosition := PT3_LoopPosition;
             i := PT3_PositionList[CurrentPosition];
             b := PLConsts[CNum].TS;
             if b <> $20 then i := b * 3 - 3 - i;
             Address_In_Pattern :=
               PWord(@Index[PT3_PatternsPointer + i * 2])^;
             PlParams[CNum].PT3_B.Address_In_Pattern :=
               PWord(@Index[PT3_PatternsPointer + i * 2 + 2])^;
             PlParams[CNum].PT3_C.Address_In_Pattern :=
               PWord(@Index[PT3_PatternsPointer + i * 2 + 4])^;
             Noise_Base := 0;
            end;
           PatternInterpreter(PlParams[CNum].PT3_A);
          end;
      end;
     with PlParams[CNum].PT3_B do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         PatternInterpreter(PlParams[CNum].PT3_B);
      end;
     with PlParams[CNum].PT3_C do
      begin
       Dec(Note_Skip_Counter);
       if Note_Skip_Counter = 0 then
         PatternInterpreter(PlParams[CNum].PT3_C);
      end;
     DelayCounter := Delay;
    end;

   AddToEnv := 0;
   TempMixer := 0;
   ChangeRegisters(PlParams[CNum].PT3_A);
   ChangeRegisters(PlParams[CNum].PT3_B);
   ChangeRegisters(PlParams[CNum].PT3_C);

   SoundChip[CNum].SetMixerRegister(TempMixer);

   SoundChip[CNum].RegisterAY.TonA := PlParams[CNum].PT3_A.Ton;
   SoundChip[CNum].RegisterAY.TonB := PlParams[CNum].PT3_B.Ton;
   SoundChip[CNum].RegisterAY.TonC := PlParams[CNum].PT3_C.Ton;

   SoundChip[CNum].SetAmplA(PlParams[CNum].PT3_A.Amplitude);
   SoundChip[CNum].SetAmplB(PlParams[CNum].PT3_B.Amplitude);
   SoundChip[CNum].SetAmplC(PlParams[CNum].PT3_C.Amplitude);

   SoundChip[CNum].RegisterAY.Noise := (Noise_Base + AddToNoise) and 31;

   SoundChip[CNum].RegisterAY.Envelope := Env_Base.wrd + AddToEnv + Cur_Env_Slide;

   if Cur_Env_Delay > 0 then
    begin
     Dec(Cur_Env_Delay);
     if Cur_Env_Delay = 0 then
      begin
       Cur_Env_Delay := Env_Delay;
       Inc(Cur_Env_Slide, Env_Slide_Add);
      end;
    end;
  end;

 Inc(PlConsts[CNum].Global_Tick_Counter);
end;

procedure MakeBufferVTX(Buf: pointer);
begin
 BuffLen := 0;
 if IntFlag then SynthesizerZX50(Buf);
 if IntFlag then exit;
 if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
   if Do_Loop then
     PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
   else
    begin
     Real_End_All := True;
     exit;
    end;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   VTX_YM3_YM3b_Get_Registers(0);
   SynthesizerZX50(Buf);
   if (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) and
     (not IntFlag) then
     if Do_Loop then
       PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
     else
      begin
       Real_End_All := True;
       exit;
      end;
   if Position_In_VTX = NumberOfVBLs then Position_In_VTX := LoopVBL;
  end;
end;

procedure VTX_YM3_YM3b_Get_Registers(CNum: integer);
var
 i: word;
 k: integer;
begin
 k := VTX_Offset;
 for i := 0 to 12 do
  begin
   case i of
     1, 3, 5:
       SoundChip[CNum].RegisterAY.Index[i] :=
         PVTXYMUnpackedData[Position_In_VTX + k] and 15;
     6: SoundChip[CNum].RegisterAY.Noise :=
         PVTXYMUnpackedData[Position_In_VTX + k] and 31;
     7: SoundChip[CNum].SetMixerRegister(PVTXYMUnpackedData[Position_In_VTX + k] and 63);
     8: SoundChip[CNum].SetAmplA(PVTXYMUnpackedData[Position_In_VTX + k] and 31);
     9: SoundChip[CNum].SetAmplB(PVTXYMUnpackedData[Position_In_VTX + k] and 31);
     10: SoundChip[CNum].SetAmplC(PVTXYMUnpackedData[Position_In_VTX + k] and 31);
   else
     SoundChip[CNum].RegisterAY.Index[i] := PVTXYMUnpackedData[Position_In_VTX + k];
    end;
   Inc(k, NumberOfVBLs);
  end;
 if PVTXYMUnpackedData[Position_In_VTX + k] <> 255 then
   SoundChip[CNum].SetEnvelopeRegister(PVTXYMUnpackedData[Position_In_Vtx + k] and 15);
 Inc(PlConsts[0].Global_Tick_Counter);
 Inc(Position_In_VTX);
end;

procedure MakeBufferYM2(Buf: pointer);
var
 MaxT: real;
begin
 Bufflen := 0;
 if IntFlag then SynthesizerYM6(Buf);
 if IntFlag then exit;
 if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
   if Do_Loop then
     PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
   else
    begin
     Real_End_All := True;
     exit;
    end;
 MaxT := YM6TiksOnInt;
 while not Real_End_All and (BuffLen < BufferLength) do
  begin
   if YM6CurTik >= MaxT then
    begin
     YM6CurTik := YM6CurTik - MaxT;
     YM2_Get_Registers(0);
    end;
   YM6_Extra_GetRegisters(0);
   SynthesizerYM6(Buf);
   if (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) and
     (not IntFlag) then
     if Do_Loop then PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
     else
      begin
       Real_End_All := True;
       exit;
      end;
  end;
end;

procedure YM2_Get_Registers(CNum: integer);
var
 i: word;
 k: integer;
 frq: real;
 SE1TC: byte;
begin
 k := VTX_Offset;
 for i := 0 to 10 do
  begin
   case i of
     1, 3, 5:
       SoundChip[CNum].RegisterAY.Index[i] :=
         PVTXYMUnpackedData[Position_In_VTX + k] and 15;
     6: SoundChip[CNum].RegisterAY.Noise :=
         PVTXYMUnpackedData[Position_In_VTX + k] and 31;
     7: SoundChip[CNum].SetMixerRegister(PVTXYMUnpackedData[Position_In_VTX + k] and 63);
     8: SoundChip[CNum].SetAmplA(PVTXYMUnpackedData[Position_In_VTX + k] and 31);
     9: SoundChip[CNum].SetAmplB(PVTXYMUnpackedData[Position_In_VTX + k] and 31);
     10: SoundChip[CNum].SetAmplC(PVTXYMUnpackedData[Position_In_VTX + k] and 31);
   else
     SoundChip[CNum].RegisterAY.Index[i] := PVTXYMUnpackedData[Position_In_VTX + k];
    end;
   Inc(k, NumberOfVBLs);
  end;
 if PVTXYMUnpackedData[Position_In_VTX + k + NumberOfVBLs * 2] <> 255 then
  begin
   SoundChip[CNum].SetEnvelopeRegister(10);
   SoundChip[CNum].RegisterAY.Index[11] := PVTXYMUnpackedData[Position_In_VTX + k];
   SoundChip[CNum].RegisterAY.Index[12] := 0;
  end;
 k := PVTXYMUnpackedData[Position_In_VTX + VTX_Offset + NumberOfVBLs * 10];
 if k and 128 <> 0 then
  begin
   AtariSE1Channel := 3;
   AtariSE1Type := 1;
   AtariSE1Pos := 0;
   AtariParam1 := k and $7F;
   if AtariParam1 > 39 then AtariParam1 := 39;
   SE1TC := PVTXYMUnpackedData[Position_In_VTX + VTX_Offset + NumberOfVBLs * 12];
   frq := 1 / (MFPTimerFrq / SE1TC / (AY_Freq / 8));
   AtariTimerPeriod1 := frq * 4;
   if AtariTimerCounter1 >= AtariTimerPeriod1 then
     AtariTimerCounter1 := 0;
  end;
 if (AtariSE1Channel <> 0) then
   SoundChip[CNum].SetMixerRegister(SoundChip[CNum].RegisterAY.Mixer or $24);
 Inc(PlConsts[0].Global_Tick_Counter);
 Inc(Position_In_VTX);
 if Position_In_VTX = NumberOfVBLs then Position_In_VTX := LoopVBL;
end;

procedure YM6_Extra_GetRegisters(CNum: integer);
var
 t1, t2, t3: real;
begin
 t3 := YM6TiksOnInt - YM6CurTik;
 t1 := t3;
 t2 := t3;
 if AtariSE1Channel <> 0 then
  begin
   if AtariTimerCounter1 = 0 then
     case AtariSE1Type of
       0: begin
         if AtariV1 = 0 then
           AtariV1 := AtariParam1
         else
           AtariV1 := 0;
         SoundChip[CNum].RegisterAY.Index[7 + AtariSE1Channel] := AtariV1;
        end;
       1: if CurFileType <> FT.YM2 then
          begin
           SoundChip[CNum].RegisterAY.Index[7 + AtariSE1Channel] :=
             DDrumSamples[AtariParam1].Buf[AtariSE1Pos];
           Inc(AtariSE1Pos);
           if AtariSE1Pos >= DDrumSamples[AtariParam1].Length then
             AtariSE1Channel := 0;
          end
         else
          begin
           SoundChip[CNum].RegisterAY.Index[10] :=
             PArray0OfByte(sampleAdress[AtariParam1])[AtariSE1Pos];
           Inc(AtariSE1Pos);
           if longword(AtariSE1Pos) >= sampleLen[AtariParam1] then
             AtariSE1Channel := 0;
          end;
       2: begin
         SoundChip[CNum].RegisterAY.Index[7 + AtariSE1Channel] :=
           YM6SinusTable[AtariParam1, YM6SinusPos1];
         YM6SinusPos1 := (YM6SinusPos1 + 1) and 7;
        end;
       3: SoundChip[CNum].SetEnvelopeRegister(AtariParam1);
      end;
   t1 := AtariTimerPeriod1 - AtariTimerCounter1;
  end;
 if AtariSE2Channel <> 0 then
  begin
   if AtariTimerCounter2 = 0 then
     case AtariSE2Type of
       0: begin
         if AtariV2 = 0 then
           AtariV2 := AtariParam2
         else
           AtariV2 := 0;
         SoundChip[CNum].RegisterAY.Index[7 + AtariSE2Channel] := AtariV2;
        end;
       1: begin
         SoundChip[CNum].RegisterAY.Index[7 + AtariSE2Channel] :=
           DDrumSamples[AtariParam2].Buf[AtariSE2Pos] and 15;
         Inc(AtariSE2Pos);
         if AtariSE2Pos >= DDrumSamples[AtariParam2].Length then
           AtariSE2Channel := 0;
        end;
       2: begin
         SoundChip[CNum].RegisterAY.Index[7 + AtariSE2Channel] :=
           YM6SinusTable[AtariParam2, YM6SinusPos2];
         YM6SinusPos2 := (YM6SinusPos2 + 1) and 7;
        end;
       3: SoundChip[CNum].SetEnvelopeRegister(AtariParam2);
      end;
   t2 := AtariTimerPeriod2 - AtariTimerCounter2;
  end;

 if t2 < t1 then t1 := t2;
 if t3 < t1 then t1 := t3;

 YM6Tiks := round(t1 * 4294967296);

 if AtariSE1Channel <> 0 then
  begin
   AtariTimerCounter1 := AtariTimerCounter1 + t1;
   if AtariTimerCounter1 >= AtariTimerPeriod1 then
     AtariTimerCounter1 := 0;
  end;
 if AtariSE2Channel <> 0 then
  begin
   AtariTimerCounter2 := AtariTimerCounter2 + t1;
   if AtariTimerCounter2 >= AtariTimerPeriod2 then
     AtariTimerCounter2 := 0;
  end;
 YM6CurTik := YM6CurTik + t1;
end;

procedure MakeBufferYM5(Buf: pointer);
var
 MaxT: real;
begin
 BuffLen := 0;
 if IntFlag then SynthesizerYM6(Buf);
 if IntFlag then exit;
 if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
   if Do_Loop then
     PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
   else
    begin
     Real_End_All := True;
     exit;
    end;
 MaxT := YM6TiksOnInt;
 if PVTXYMUnpackedData[19] and 1 <> 0 then
   while not Real_End_All and (BuffLen < BufferLength) do
    begin
     if YM6CurTik >= MaxT then
      begin
       YM6CurTik := YM6CurTik - MaxT;
       YM5i_Get_Registers(0);
      end;
     YM6_Extra_GetRegisters(0);
     SynthesizerYM6(Buf);
     if (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) and
       (not IntFlag) then
       if Do_Loop then
         PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
       else
        begin
         Real_End_All := True;
         exit;
        end;
    end
 else
   while not Real_End_All and (BuffLen < BufferLength) do
    begin
     if YM6CurTik >= MaxT then
      begin
       YM6CurTik := YM6CurTik - MaxT;
       YM5_Get_Registers(0);
      end;
     YM6_Extra_GetRegisters(0);
     SynthesizerYM6(Buf);
     if (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) and
       (not IntFlag) then
       if Do_Loop then
         PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
       else
        begin
         Real_End_All := True;
         exit;
        end;
    end;
end;

procedure MakeBufferYM6(Buf: pointer);
var
 MaxT: real;
begin
 Bufflen := 0;
 if IntFlag then SynthesizerYM6(Buf);
 if IntFlag then exit;
 if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
   if Do_Loop then
     PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
   else
    begin
     Real_End_All := True;
     exit;
    end;
 MaxT := YM6TiksOnInt;
 if PVTXYMUnpackedData[19] and 1 <> 0 then
   while not Real_End_All and (BuffLen < BufferLength) do
    begin
     if YM6CurTik >= MaxT then
      begin
       YM6CurTik := YM6CurTik - MaxT;
       YM6i_Get_Registers(0);
      end;
     YM6_Extra_GetRegisters(0);
     SynthesizerYM6(Buf);
     if (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) and
       (not IntFlag) then
       if Do_Loop then PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
       else
        begin
         Real_End_All := True;
         exit;
        end;
    end
 else
   while not Real_End_All and (BuffLen < BufferLength) do
    begin
     if YM6CurTik >= MaxT then
      begin
       YM6CurTik := YM6CurTik - MaxT;
       YM6_Get_Registers(0);
      end;
     YM6_Extra_GetRegisters(0);
     SynthesizerYM6(Buf);
     if (PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max) and
       (not IntFlag) then
       if Do_Loop then
         PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
       else
        begin
         Real_End_All := True;
         exit;
        end;
    end;
end;

procedure YM6i_Get_Registers(CNum: integer);
var
 k: integer;
 b, mx, la, lb, lc: byte;
 SE1Ch, SE2Ch, SE1Typ, SE2Typ, SE1TC, SE2TC: byte;
 frq: real;
begin

 k := Position_In_Vtx + VTX_Offset;
 SoundChip[CNum].RegisterAY.Index[0] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[1] := b and 15;
 SE1Ch := b and $30 shr 4;
 SE1Typ := b shr 6;

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[2] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[3] := b and 15;
 SE2Ch := b and $30 shr 4;
 SE2Typ := b shr 6;

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[4] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[5] := PVTXYMUnpackedData[k] and 15;

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Noise := b and 31;
 AtariSE1TP := b shr 5;

 Inc(k, NumberOfVBLs);
 mx := PVTXYMUnpackedData[k] and 63;

 Inc(k, NumberOfVBLs);
 la := PVTXYMUnpackedData[k];
 AtariSE2TP := la shr 5;

 Inc(k, NumberOfVBLs);
 lb := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 lc := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[11] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[12] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 if b <> 255 then
   SoundChip[CNum].SetEnvelopeRegister(b and 15);

 Inc(k, NumberOfVBLs);
 SE1TC := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SE2TC := PVTXYMUnpackedData[k];

 if (SE1TC <> 0) and (AtariSE1TP <> 0) and (SE1Ch <> 0) then
  begin
   case SE1Ch of
     1: case SE1Typ of
         0, 2: begin
           AtariParam1 := la and 15;
           SoundChip[CNum].Envelope_EnA := True;
          end;
         3: begin
           AtariParam1 := la and 15;
           SoundChip[CNum].SetAmplA(la and 16);
          end
       else
        begin
         AtariParam1 := la and 31;
         SoundChip[CNum].Envelope_EnA := True;
        end
        end;
     2: case SE1Typ of
         0, 2: begin
           AtariParam1 := lb and 15;
           SoundChip[CNum].Envelope_EnB := True;
          end;
         3: begin
           AtariParam1 := lb and 15;
           SoundChip[CNum].SetAmplB(lb and 16);
          end
       else
        begin
         AtariParam1 := lb and 31;
         SoundChip[CNum].Envelope_EnB := True;
        end
        end;
     3: case SE1Typ of
         0, 2: begin
           AtariParam1 := lc and 15;
           SoundChip[CNum].Envelope_EnC := True;
          end;
         3: begin
           AtariParam1 := lc and 15;
           SoundChip[CNum].SetAmplC(lc and 16);
          end
       else
        begin
         AtariParam1 := lc and 31;
         SoundChip[CNum].Envelope_EnC := True;
        end
        end;
    end;
   if (SE1Typ = 1) and (AtariParam1 >= Length(DDrumSamples)) then SE1Ch := 0;
   AtariSE1Type := SE1Typ;
   AtariSE1Channel := SE1Ch;
   AtariSE1Pos := 0;
   frq := 1 / (MFPTimerFrq / SE1TC / (AY_Freq / 8));
   case AtariSE1TP of
     1: AtariTimerPeriod1 := frq * 4;
     2: AtariTimerPeriod1 := frq * 10;
     3: AtariTimerPeriod1 := frq * 16;
     4: AtariTimerPeriod1 := frq * 50;
     5: AtariTimerPeriod1 := frq * 64;
     6: AtariTimerPeriod1 := frq * 100;
     7: AtariTimerPeriod1 := frq * 200
    end;
   if AtariTimerCounter1 >= AtariTimerPeriod1 then
     AtariTimerCounter1 := 0;
  end
 else
  begin
   if (AtariSE1Channel <> 0) and (AtariSE1Type = 1) then
    begin
     case AtariSE1Channel of
       1: if mx and 9 <> 9 then AtariSE1Channel := 0;
       2: if mx and 18 <> 18 then AtariSE1Channel := 0;
       3: if mx and 36 <> 36 then AtariSE1Channel := 0
      end;
    end
   else
    begin
     AtariSE1Channel := 0;
     AtariTimerCounter1 := 0;
     AtariV1 := 0;
    end;
  end;

 if (SE2TC <> 0) and (AtariSE2TP <> 0) and (SE2Ch <> 0) then
  begin
   case SE2Ch of
     1: case SE2Typ of
         0, 2: begin
           AtariParam2 := la and 15;
           SoundChip[CNum].Envelope_EnA := True;
          end;
         3: begin
           AtariParam2 := la and 15;
           SoundChip[CNum].SetAmplA(la and 16);
          end
       else
        begin
         AtariParam2 := la and 31;
         SoundChip[CNum].Envelope_EnA := True;
        end;
        end;
     2: case SE2Typ of
         0, 2: begin
           AtariParam2 := lb and 15;
           SoundChip[CNum].Envelope_EnB := True;
          end;
         3: begin
           AtariParam2 := lb and 15;
           SoundChip[CNum].SetAmplB(lb and 16);
          end
       else
        begin
         AtariParam2 := lb and 31;
         SoundChip[CNum].Envelope_EnB := True;
        end
        end;
     3: case SE2Typ of
         0, 2: begin
           AtariParam2 := lc and 15;
           SoundChip[CNum].Envelope_EnC := True;
          end;
         3: begin
           AtariParam2 := lc and 15;
           SoundChip[CNum].SetAmplC(lc and 16);
          end
       else
        begin
         AtariParam2 := lc and 31;
         SoundChip[CNum].Envelope_EnC := True;
        end
        end;
    end;
   if (SE2Typ = 1) and (AtariParam2 >= Length(DDrumSamples)) then SE2Ch := 0;
   AtariSE2Type := SE2Typ;
   AtariSE2Channel := SE2Ch;
   AtariSE2Pos := 0;
   frq := 1 / (MFPTimerFrq / SE2TC / (AY_Freq / 8));
   case AtariSE2TP of
     1: AtariTimerPeriod2 := frq * 4;
     2: AtariTimerPeriod2 := frq * 10;
     3: AtariTimerPeriod2 := frq * 16;
     4: AtariTimerPeriod2 := frq * 50;
     5: AtariTimerPeriod2 := frq * 64;
     6: AtariTimerPeriod2 := frq * 100;
     7: AtariTimerPeriod2 := frq * 200
    end;
   if AtariTimerCounter2 >= AtariTimerPeriod2 then
     AtariTimerCounter2 := 0;
  end
 else
  begin
   if (AtariSE2Channel <> 0) and (AtariSE2Type = 1) then
    begin
     case AtariSE2Channel of
       1: if mx and 9 <> 9 then AtariSE2Channel := 0;
       2: if mx and 18 <> 18 then AtariSE2Channel := 0;
       3: if mx and 36 <> 36 then AtariSE2Channel := 0
      end;
    end
   else
    begin
     AtariSE2Channel := 0;
     AtariTimerCounter2 := 0;
     AtariV2 := 0;
    end;
  end;

 if AtariSE1Type = 1 then
   case AtariSE1Channel of
     1: mx := mx or 9;
     2: mx := mx or 18;
     3: mx := mx or 36;
    end;

 if AtariSE2Type = 1 then
   case AtariSE2Channel of
     1: mx := mx or 9;
     2: mx := mx or 18;
     3: mx := mx or 36;
    end;

 SoundChip[CNum].SetMixerRegister(mx);

 if (AtariSE1Channel <> 1) and (AtariSE2Channel <> 1) then
   SoundChip[CNum].SetAmplA(la and 31);

 if (AtariSE1Channel <> 2) and (AtariSE2Channel <> 2) then
   SoundChip[CNum].SetAmplB(lb and 31);

 if (AtariSE1Channel <> 3) and (AtariSE2Channel <> 3) then
   SoundChip[CNum].SetAmplC(lc and 31);

 Inc(PlConsts[0].Global_Tick_Counter);
 Inc(Position_In_VTX);
 if Position_In_VTX = NumberOfVBLs then
   Position_In_VTX := LoopVBL;
end;

procedure YM6_Get_Registers(CNum: integer);
var
 k: integer;
 b, mx, la, lb, lc: byte;
 SE1Ch, SE2Ch, SE1Typ, SE2Typ, SE1TC, SE2TC: byte;
 frq: real;
begin

 k := Position_In_Vtx + VTX_Offset;
 SoundChip[CNum].RegisterAY.Index[0] := PVTXYMUnpackedData[k];

 Inc(k);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[1] := b and 15;
 SE1Ch := b and $30 shr 4;
 SE1Typ := b shr 6;

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[2] := PVTXYMUnpackedData[k];

 Inc(k);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[3] := b and 15;
 SE2Ch := b and $30 shr 4;
 SE2Typ := b shr 6;

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[4] := PVTXYMUnpackedData[k];

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[5] := PVTXYMUnpackedData[k] and 15;

 Inc(k);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Noise := b and 31;
 AtariSE1TP := b shr 5;

 Inc(k);
 mx := PVTXYMUnpackedData[k] and 63;

 Inc(k);
 la := PVTXYMUnpackedData[k];
 AtariSE2TP := la shr 5;

 Inc(k);
 lb := PVTXYMUnpackedData[k];

 Inc(k);
 lc := PVTXYMUnpackedData[k];

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[11] := PVTXYMUnpackedData[k];

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[12] := PVTXYMUnpackedData[k];

 Inc(k);
 b := PVTXYMUnpackedData[k];
 if b <> 255 then
   SoundChip[CNum].SetEnvelopeRegister(b and 15);

 Inc(k);
 SE1TC := PVTXYMUnpackedData[k];

 Inc(k);
 SE2TC := PVTXYMUnpackedData[k];

 if (SE1TC <> 0) and (AtariSE1TP <> 0) and (SE1Ch <> 0) then
  begin
   case SE1Ch of
     1: case SE1Typ of
         0, 2: begin
           AtariParam1 := la and 15;
           SoundChip[CNum].Envelope_EnA := True;
          end;
         3: begin
           AtariParam1 := la and 15;
           SoundChip[CNum].SetAmplA(la and 16);
          end
       else
        begin
         AtariParam1 := la and 31;
         SoundChip[CNum].Envelope_EnA := True;
        end
        end;
     2: case SE1Typ of
         0, 2: begin
           AtariParam1 := lb and 15;
           SoundChip[CNum].Envelope_EnB := True;
          end;
         3: begin
           AtariParam1 := lb and 15;
           SoundChip[CNum].SetAmplB(lb and 16);
          end
       else
        begin
         AtariParam1 := lb and 31;
         SoundChip[CNum].Envelope_EnB := True;
        end;
        end;
     3: case SE1Typ of
         0, 2: begin
           AtariParam1 := lc and 15;
           SoundChip[CNum].Envelope_EnC := True;
          end;
         3: begin
           AtariParam1 := lc and 15;
           SoundChip[CNum].SetAmplC(lc and 16);
          end
       else
        begin
         AtariParam1 := lc and 31;
         SoundChip[CNum].Envelope_EnC := True;
        end
        end;
    end;
   if (SE1Typ = 1) and (AtariParam1 >= Length(DDrumSamples)) then SE1Ch := 0;
   AtariSE1Type := SE1Typ;
   AtariSE1Channel := SE1Ch;
   AtariSE1Pos := 0;
   frq := 1 / (MFPTimerFrq / SE1TC / (AY_Freq / 8));
   case AtariSE1TP of
     1: AtariTimerPeriod1 := frq * 4;
     2: AtariTimerPeriod1 := frq * 10;
     3: AtariTimerPeriod1 := frq * 16;
     4: AtariTimerPeriod1 := frq * 50;
     5: AtariTimerPeriod1 := frq * 64;
     6: AtariTimerPeriod1 := frq * 100;
     7: AtariTimerPeriod1 := frq * 200;
    end;
   if AtariTimerCounter1 >= AtariTimerPeriod1 then
     AtariTimerCounter1 := 0;
  end
 else
  begin
   if (AtariSE1Channel <> 0) and (AtariSE1Type = 1) then
    begin
     case AtariSE1Channel of
       1: if mx and 9 <> 9 then AtariSE1Channel := 0;
       2: if mx and 18 <> 18 then AtariSE1Channel := 0;
       3: if mx and 36 <> 36 then AtariSE1Channel := 0;
      end;
    end
   else
    begin
     AtariSE1Channel := 0;
     AtariTimerCounter1 := 0;
     AtariV1 := 0;
    end;
  end;

 if (SE2TC <> 0) and (AtariSE2TP <> 0) and (SE2Ch <> 0) then
  begin
   case SE2Ch of
     1: case SE2Typ of
         0, 2: begin
           AtariParam2 := la and 15;
           SoundChip[CNum].Envelope_EnA := True;
          end;
         3: begin
           AtariParam2 := la and 15;
           SoundChip[CNum].SetAmplA(la and 16);
          end
       else
        begin
         AtariParam2 := la and 31;
         SoundChip[CNum].Envelope_EnA := True;
        end
        end;
     2: case SE2Typ of
         0, 2: begin
           AtariParam2 := lb and 15;
           SoundChip[CNum].Envelope_EnB := True;
          end;
         3: begin
           AtariParam2 := lb and 15;
           SoundChip[CNum].SetAmplB(lb and 16);
          end
       else
        begin
         AtariParam2 := lb and 31;
         SoundChip[CNum].Envelope_EnB := True;
        end
        end;
     3: case SE2Typ of
         0, 2: begin
           AtariParam2 := lc and 15;
           SoundChip[CNum].Envelope_EnC := True;
          end;
         3: begin
           AtariParam2 := lc and 15;
           SoundChip[CNum].SetAmplC(lc and 16);
          end
       else
        begin
         AtariParam2 := lc and 31;
         SoundChip[CNum].Envelope_EnC := True;
        end;
        end;
    end;
   if (SE2Typ = 1) and (AtariParam2 >= Length(DDrumSamples)) then SE2Ch := 0;
   AtariSE2Type := SE2Typ;
   AtariSE2Channel := SE2Ch;
   AtariSE2Pos := 0;
   frq := 1 / (MFPTimerFrq / SE2TC / (AY_Freq / 8));
   case AtariSE2TP of
     1: AtariTimerPeriod2 := frq * 4;
     2: AtariTimerPeriod2 := frq * 10;
     3: AtariTimerPeriod2 := frq * 16;
     4: AtariTimerPeriod2 := frq * 50;
     5: AtariTimerPeriod2 := frq * 64;
     6: AtariTimerPeriod2 := frq * 100;
     7: AtariTimerPeriod2 := frq * 200
    end;
   if AtariTimerCounter2 >= AtariTimerPeriod2 then
     AtariTimerCounter2 := 0;
  end
 else
  begin
   if (AtariSE2Channel <> 0) and (AtariSE2Type = 1) then
    begin
     case AtariSE2Channel of
       1: if mx and 9 <> 9 then AtariSE2Channel := 0;
       2: if mx and 18 <> 18 then AtariSE2Channel := 0;
       3: if mx and 36 <> 36 then AtariSE2Channel := 0
      end;
    end
   else
    begin
     AtariSE2Channel := 0;
     AtariTimerCounter2 := 0;
     AtariV2 := 0;
    end;
  end;

 if AtariSE1Type = 1 then
   case AtariSE1Channel of
     1: mx := mx or 9;
     2: mx := mx or 18;
     3: mx := mx or 36;
    end;

 if AtariSE2Type = 1 then
   case AtariSE2Channel of
     1: mx := mx or 9;
     2: mx := mx or 18;
     3: mx := mx or 36;
    end;

 SoundChip[CNum].SetMixerRegister(mx);

 if (AtariSE1Channel <> 1) and (AtariSE2Channel <> 1) then
   SoundChip[CNum].SetAmplA(la and 31);

 if (AtariSE1Channel <> 2) and (AtariSE2Channel <> 2) then
   SoundChip[CNum].SetAmplB(lb and 31);

 if (AtariSE1Channel <> 3) and (AtariSE2Channel <> 3) then
   SoundChip[CNum].SetAmplC(lc and 31);

 Inc(PlConsts[0].Global_Tick_Counter);
 Inc(Position_In_VTX, 16);
 if Position_In_VTX div 16 = NumberOfVBLs then
   Position_In_VTX := LoopVBL * 16;
end;

procedure YM5i_Get_Registers(CNum: integer);
var
 k: integer;
 b, la, lb, lc, mx: byte;
 DD, SE1TC, SE2TC: byte;
 frq: real;
begin

 k := Position_In_Vtx + VTX_Offset;
 SoundChip[CNum].RegisterAY.Index[0] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[1] := b and 15;
 AtariSE1Channel := b and $30 shr 4;
 if b and $40 <> 0 then
   AtariTimerCounter1 := 0;

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[2] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 DD := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[3] := DD and 15;
 DD := DD and $30 shr 4;

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[4] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[5] := PVTXYMUnpackedData[k] and 15;

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Noise := b and 31;
 AtariSE1TP := b shr 5;

 Inc(k, NumberOfVBLs);
 mx := PVTXYMUnpackedData[k] and 63;

 Inc(k, NumberOfVBLs);
 la := PVTXYMUnpackedData[k];
 AtariSE2TP := la shr 5;

 Inc(k, NumberOfVBLs);
 lb := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 lc := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[11] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SoundChip[CNum].RegisterAY.Index[12] := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 b := PVTXYMUnpackedData[k];
 if b <> 255 then
   SoundChip[CNum].SetEnvelopeRegister(b and 15);

 Inc(k, NumberOfVBLs);
 SE1TC := PVTXYMUnpackedData[k];

 Inc(k, NumberOfVBLs);
 SE2TC := PVTXYMUnpackedData[k];

 if (SE1TC <> 0) and (AtariSE1TP <> 0) and (AtariSE1Channel <> 0) then
  begin
   case AtariSE1Channel of
     1: begin
       AtariParam1 := la and 15;
       SoundChip[CNum].Envelope_EnA := True;
      end;
     2: begin
       AtariParam1 := lb and 15;
       SoundChip[CNum].Envelope_EnB := True;
      end;
     3: begin
       AtariParam1 := lc and 15;
       SoundChip[CNum].Envelope_EnC := True;
      end;
    end;
   frq := 1 / (MFPTimerFrq / SE1TC / (AY_Freq / 8));
   case AtariSE1TP of
     1: AtariTimerPeriod1 := frq * 4;
     2: AtariTimerPeriod1 := frq * 10;
     3: AtariTimerPeriod1 := frq * 16;
     4: AtariTimerPeriod1 := frq * 50;
     5: AtariTimerPeriod1 := frq * 64;
     6: AtariTimerPeriod1 := frq * 100;
     7: AtariTimerPeriod1 := frq * 200
    end;
   if AtariTimerCounter1 >= AtariTimerPeriod1 then
     AtariTimerCounter1 := 0;
  end
 else
  begin
   AtariSE1Channel := 0;
   AtariTimerCounter1 := 0;
   AtariV1 := 0;
  end;

 if (SE2TC <> 0) and (AtariSE2TP <> 0) and (DD <> 0) then
  begin
   case DD of
     1: begin
       AtariParam2 := la and 15;
       SoundChip[CNum].Envelope_EnA := True;
      end;
     2: begin
       AtariParam2 := lb and 15;
       SoundChip[CNum].Envelope_EnB := True;
      end;
     3: begin
       AtariParam2 := lc and 15;
       SoundChip[CNum].Envelope_EnC := True;
      end;
    end;
   if AtariParam2 >= Length(DDrumSamples) then DD := 0;
   AtariSE2Channel := DD;
   AtariSE2Pos := 0;
   frq := 1 / (MFPTimerFrq / SE2TC / (AY_Freq / 8));
   case AtariSE2TP of
     1: AtariTimerPeriod2 := frq * 4;
     2: AtariTimerPeriod2 := frq * 10;
     3: AtariTimerPeriod2 := frq * 16;
     4: AtariTimerPeriod2 := frq * 50;
     5: AtariTimerPeriod2 := frq * 64;
     6: AtariTimerPeriod2 := frq * 100;
     7: AtariTimerPeriod2 := frq * 200
    end;
   if AtariTimerCounter2 >= AtariTimerPeriod2 then
     AtariTimerCounter2 := 0;
  end
 else
  begin
   case AtariSE2Channel of
     0: AtariTimerCounter2 := 0;
     1: if mx and 9 <> 9 then AtariSE2Channel := 0;
     2: if mx and 18 <> 18 then AtariSE2Channel := 0;
     3: if mx and 36 <> 36 then AtariSE2Channel := 0
    end;
  end;

 case AtariSE2Channel of
   1: mx := mx or 9;
   2: mx := mx or 18;
   3: mx := mx or 36;
  end;

 SoundChip[CNum].SetMixerRegister(mx);

 if (AtariSE1Channel <> 1) and (AtariSE2Channel <> 1) then
   SoundChip[CNum].SetAmplA(la and 31);

 if (AtariSE1Channel <> 2) and (AtariSE2Channel <> 2) then
   SoundChip[CNum].SetAmplB(lb and 31);

 if (AtariSE1Channel <> 3) and (AtariSE2Channel <> 3) then
   SoundChip[CNum].SetAmplC(lc and 31);

 Inc(PlConsts[0].Global_Tick_Counter);
 Inc(Position_In_VTX);
 if Position_In_VTX = NumberOfVBLs then
   Position_In_VTX := LoopVBL;
end;

procedure YM5_Get_Registers(CNum: integer);
var
 k: integer;
 b, la, lb, lc, mx: byte;
 DD, SE1TC, SE2TC: byte;
 frq: real;
begin

 k := Position_In_Vtx + VTX_Offset;
 SoundChip[CNum].RegisterAY.Index[0] := PVTXYMUnpackedData[k];

 Inc(k);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[1] := b and 15;
 AtariSE1Channel := b and $30 shr 4;
 if b and $40 <> 0 then
   AtariTimerCounter1 := 0;

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[2] := PVTXYMUnpackedData[k];

 Inc(k);
 DD := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Index[3] := DD and 15;
 DD := DD and $30 shr 4;

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[4] := PVTXYMUnpackedData[k];

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[5] := PVTXYMUnpackedData[k] and 15;

 Inc(k);
 b := PVTXYMUnpackedData[k];
 SoundChip[CNum].RegisterAY.Noise := b and 31;
 AtariSE1TP := b shr 5;

 Inc(k);
 mx := PVTXYMUnpackedData[k] and 63;

 Inc(k);
 la := PVTXYMUnpackedData[k];
 AtariSE2TP := la shr 5;

 Inc(k);
 lb := PVTXYMUnpackedData[k];

 Inc(k);
 lc := PVTXYMUnpackedData[k];

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[11] := PVTXYMUnpackedData[k];

 Inc(k);
 SoundChip[CNum].RegisterAY.Index[12] := PVTXYMUnpackedData[k];

 Inc(k);
 b := PVTXYMUnpackedData[k];
 if b <> 255 then
   SoundChip[CNum].SetEnvelopeRegister(b and 15);

 Inc(k);
 SE1TC := PVTXYMUnpackedData[k];

 Inc(k);
 SE2TC := PVTXYMUnpackedData[k];

 if (SE1TC <> 0) and (AtariSE1TP <> 0) and (AtariSE1Channel <> 0) then
  begin
   case AtariSE1Channel of
     1: begin
       AtariParam1 := la and 15;
       SoundChip[CNum].Envelope_EnA := True;
      end;
     2: begin
       AtariParam1 := lb and 15;
       SoundChip[CNum].Envelope_EnB := True;
      end;
     3: begin
       AtariParam1 := lc and 15;
       SoundChip[CNum].Envelope_EnC := True;
      end
    end;
   frq := 1 / (MFPTimerFrq / SE1TC / (AY_Freq / 8));
   case AtariSE1TP of
     1: AtariTimerPeriod1 := frq * 4;
     2: AtariTimerPeriod1 := frq * 10;
     3: AtariTimerPeriod1 := frq * 16;
     4: AtariTimerPeriod1 := frq * 50;
     5: AtariTimerPeriod1 := frq * 64;
     6: AtariTimerPeriod1 := frq * 100;
     7: AtariTimerPeriod1 := frq * 200
    end;
   if AtariTimerCounter1 >= AtariTimerPeriod1 then
     AtariTimerCounter1 := 0;
  end
 else
  begin
   AtariSE1Channel := 0;
   AtariTimerCounter1 := 0;
   AtariV1 := 0;
  end;

 if (SE2TC <> 0) and (AtariSE2TP <> 0) and (DD <> 0) then
  begin
   case DD of
     1: begin
       AtariParam2 := la and 15;
       SoundChip[CNum].Envelope_EnA := True;
      end;
     2: begin
       AtariParam2 := lb and 15;
       SoundChip[CNum].Envelope_EnB := True;
      end;
     3: begin
       AtariParam2 := lc and 15;
       SoundChip[CNum].Envelope_EnC := True;
      end;
    end;
   if AtariParam2 >= Length(DDrumSamples) then DD := 0;
   AtariSE2Channel := DD;
   AtariSE2Pos := 0;
   frq := 1 / (MFPTimerFrq / SE2TC / (AY_Freq / 8));
   case AtariSE2TP of
     1: AtariTimerPeriod2 := frq * 4;
     2: AtariTimerPeriod2 := frq * 10;
     3: AtariTimerPeriod2 := frq * 16;
     4: AtariTimerPeriod2 := frq * 50;
     5: AtariTimerPeriod2 := frq * 64;
     6: AtariTimerPeriod2 := frq * 100;
     7: AtariTimerPeriod2 := frq * 200
    end;
   if AtariTimerCounter2 >= AtariTimerPeriod2 then
     AtariTimerCounter2 := 0;
  end
 else
  begin
   case AtariSE2Channel of
     0: AtariTimerCounter2 := 0;
     1: if mx and 9 <> 9 then AtariSE2Channel := 0;
     2: if mx and 18 <> 18 then AtariSE2Channel := 0;
     3: if mx and 36 <> 36 then AtariSE2Channel := 0
    end;
  end;

 case AtariSE2Channel of
   1: mx := mx or 9;
   2: mx := mx or 18;
   3: mx := mx or 36;
  end;

 SoundChip[CNum].SetMixerRegister(mx);

 if (AtariSE1Channel <> 1) and (AtariSE2Channel <> 1) then
   SoundChip[CNum].SetAmplA(la and 31);

 if (AtariSE1Channel <> 2) and (AtariSE2Channel <> 2) then
   SoundChip[CNum].SetAmplB(lb and 31);

 if (AtariSE1Channel <> 3) and (AtariSE2Channel <> 3) then
   SoundChip[CNum].SetAmplC(lc and 31);

 Inc(PlConsts[0].Global_Tick_Counter);
 Inc(Position_In_VTX, 16);
 if (Position_In_VTX div 16 = NumberOfVBLs) then
   Position_In_VTX := LoopVBL * 16;
end;

procedure MakeBufferAY(Buf: pointer);
begin
 BufP := Buf;
 Bufflen := 0;
 if IntFlag then
  begin
   IntFlag := False;
   Synthesizer(Buf);
   if IntFlag then exit;
   if IntBeeper then
    begin
     IntBeeper := False;
     Beeper := BeeperNext;
    end;
   if IntAY then
    begin
     IntAY := False;
     SoundChip[0].SetAYRegister(RegNumNext, DatNext);
    end;
  end;
 while BuffLen < BufferLength do
  begin
   Z80_Step;
   if CurrentTact >= MaxTStates then
    begin
     Dec(CurrentTact, MaxTStates);
     Dec(Previous_Tact, MaxTStates);
     if Bufflen < BufferLength then
       SynthesizerAY;
     Inc(PlConsts[0].Global_Tick_Counter);
     if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
       if Do_Loop then
         PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
       else
        begin
         Real_End_All := True;
         exit;
        end;
    end;
  end;
end;

procedure AY_Get_Registers(CNum: integer);
begin
 repeat
   Z80_Step;
   if CurrentTact >= MaxTStates then
    begin
     Dec(CurrentTact, MaxTStates);
     Inc(PlConsts[0].Global_Tick_Counter);
     if PlConsts[0].Global_Tick_Counter >= PlConsts[0].Global_Tick_Max then
       if Do_Loop then
         PlConsts[0].Global_Tick_Counter := PlConsts[0].Global_Tick_Max
       else
         Real_End_All := True;
     exit;
    end;
 until False;
end;

procedure MakeBufferSNDH(Buf: pointer);
begin
 BufP := Buf;
 BuffLen := 0;
 if IntFlag then
  begin
   IntFlag := False;
   Synthesizer(Buf);
   if IntFlag then exit;
  end;
 Atari_CheckOuts;
 //todo: вывести пропущенные данные с точностью до такта (для тестов sndh46lf\Tao\Songs_That_Make_You_Go_Mmh\Commando_Hiscore_digi.sndh)
 //if Real_End_All then exit;
 while (BuffLen < BufferLength) and not Real_End_All do
   //проверить, по Real_End_All всегда доиграется последний тик или нет?
  begin
   Atari_Emulate;
   if Atari_ExecutionError then
    begin
     StopPlaying;
     break;
    end;
   if (BuffLen < BufferLength) and ((s68000readOdometer >= 150000) or Real_End_All) then
     SynthesizerSNDH;
  end;
end;

procedure SNDH_Get_Registers(CNum: integer);
begin
 Atari_Emulate_One_VBL;
end;

procedure RerollMusic(newpos, maxpos: integer);
var
 pos, stp, bas: integer;
 l: integer;
 op: TOutProc;
 nMax, SeekTo, CurrTime: integer;
begin
 if (CurFileType = FT.VTX) or IsSTSoundFileType(CurFileType) then
  begin
   ResetAYChipEmulation(0, True);
   PlConsts[0].Global_Tick_Counter :=
     round(newpos / maxpos * PlConsts[0].Global_Tick_Max);
   BaseSample := round(PlConsts[0].Global_Tick_Counter * 1000 /
     Interrupt_Freq * SampleRate);
   Position_In_VTX := PlConsts[0].Global_Tick_Counter mod NumberOfVBLs;
   if (CurFileType = FT.YM5) or (CurFileType = FT.YM6) then
    begin
     if PVTXYMUnpackedData[{%H-}19] and 1 <> 0 then
      begin
       pos := Position_In_VTX;
       bas := VTX_Offset + NumberOfVBLs * 13;
       stp := 1;
      end
     else
      begin
       Position_In_VTX := Position_In_VTX * 16;
       pos := Position_In_VTX;
       bas := VTX_Offset + 13;
       stp := 16;
      end;
    end
   else
    begin
     pos := Position_In_VTX;
     bas := VTX_Offset + NumberOfVBLs * 13;
     stp := 1;
    end;
   if PVTXYMUnpackedData[pos + bas] = 255 then
    begin
     repeat
       Dec(pos, stp)
     until (pos < 0) or (PVTXYMUnpackedData[pos + bas] <> 255);
     if pos >= 0 then
       SoundChip[0].SetEnvelopeRegister(PVTXYMUnpackedData[pos + bas] and 15);
    end;
   ProgrPos := trunc(newpos / maxpos * ProgrMax + 0.5);
   VProgrPos := ProgrPos;
  end
 else if (CurFileType = FT.PSG) or IsAYNativeFileType(CurFileType) then
  begin
   //store index of max duration TS-pair (can be different time length)
   if TSMode and (PlConsts[1].Global_Tick_Max > PlConsts[0].Global_Tick_Max) then
     nMax := 1
   else
     nMax := 0;
   SeekTo := round(newpos / maxpos * PlConsts[nMax].Global_Tick_Max);
   if SeekTo < PlConsts[nMax].Global_Tick_Counter then
    begin
     InitForAllTypes(False);
     ResetAYChipEmulation(0, True);
     PlConsts[0].Global_Tick_Counter := 0;
     if TSMode then
      begin
       ResetAYChipEmulation(1, True);
       PlConsts[1].Global_Tick_Counter := 0;
      end;
    end
   else
    begin
     ResetAYChipEmulation(0, False);
     if TSMode then ResetAYChipEmulation(1, False);
    end;
   while PlConsts[nMax].Global_Tick_Counter < SeekTo do
    begin
     All_GetRegisters[0](0);
     if TSMode then All_GetRegisters[1](1);
    end;
   BaseSample := trunc(PlConsts[nMax].Global_Tick_Counter * 1000 /
     Interrupt_Freq * SampleRate + 0.5);
   ProgrPos := trunc(newpos / maxpos * ProgrMax + 0.5);
   VProgrPos := ProgrPos;
  end
 else if CurFileType = FT.EPSG then
  begin
   SeekTo := round(newpos / maxpos * Time_ms / 1000 * FrqZ80 / EPSG_TStateMax);
   CurrTime := PlConsts[0].Global_Tick_Counter;
   PlConsts[0].Global_Tick_Counter := SeekTo;
   if SeekTo < CurrTime then
    begin
     InitForAllTypes(False);
     ResetAYChipEmulation(0, True);
     CurrTime := 0;
    end
   else
     ResetAYChipEmulation(0, False);
   if CurrTime < SeekTo then
    begin
     Previous_AY_Takt := 0;
     while CurrTime < SeekTo do
      begin
       EPSG_Get_Registers(0);
       Inc(CurrTime);
      end;
     IntFlag := False;
    end;
   BaseSample := trunc(newpos / maxpos * Time_ms / 1000 * SampleRate + 0.5);
   ProgrPos := trunc(newpos / maxpos * ProgrMax + 0.5);
   VProgrPos := ProgrPos;
  end
 else if (CurFileType = FT.OUT) or (CurFileType = FT.ZXAY) then
  begin
   InitForAllTypes(False); //Always seek from start, fix it?
   ResetAYChipEmulation(0, True);
   OUTZXAYConv_TotalTime := IntOffset;
   SeekTo := round(newpos / maxpos * Time_ms / 1000 * FrqZ80 / MaxTStates);
   while SeekTo > 0 do
    begin
     All_GetRegisters[0](0);
     Dec(SeekTo);
    end;
   IntFlag := False;
   BaseSample := trunc(newpos / maxpos * Time_ms / 1000 * SampleRate + 0.5);
   ProgrPos := trunc(newpos / maxpos * ProgrMax + 0.5);
   VProgrPos := ProgrPos;
  end
 else if IsZ80EmuFileType(CurFileType) then
  begin
   l := round(newpos / maxpos * PlConsts[0].Global_Tick_Max);
   if l > PlConsts[0].Global_Tick_Counter then
    begin
     op := OutProc;
     if op = @ZXOutProc then
       OutProc := @OutZXConverter
     else if op = @CPCOutProc then
       OutProc := @OutCPCConverter
     else
       OutProc := @OutInitialConverter;
     repeat
       AY_Get_Registers(0)
     until PlConsts[0].Global_Tick_Counter >= l;
     OutProc := op;
     Previous_Tact := CurrentTact;
     IntBeeper := False;
     IntAY := False;
     ResetAYChipEmulation(0, False);
     SoundChip[0].SetEnvelopeRegister(SoundChip[0].RegisterAY.EnvType);
     SoundChip[0].First_Period := False;
     SoundChip[0].Ampl := 0;
     SoundChip[0].SetMixerRegister(SoundChip[0].RegisterAY.Mixer);
     SoundChip[0].SetAmplA(SoundChip[0].RegisterAY.AmplitudeA);
     SoundChip[0].SetAmplB(SoundChip[0].RegisterAY.AmplitudeB);
     SoundChip[0].SetAmplC(SoundChip[0].RegisterAY.AmplitudeC);
    end
   else if l < PlConsts[0].Global_Tick_Counter then
    begin
     op := OutProc;
     InitForAllTypes(False);
     ResetAYChipEmulation(0, True);
     if op = @ZXOutProc then
       OutProc := @OutZXConverter
     else if op = @CPCOutProc then
       OutProc := @OutCPCConverter
     else
       OutProc := @OutInitialConverter;
     PlConsts[0].Global_Tick_Counter := 0;
     while PlConsts[0].Global_Tick_Counter < l do
       AY_Get_Registers(0);
     OutProc := op;
     SoundChip[0].SetEnvelopeRegister(SoundChip[0].RegisterAY.EnvType);
     SoundChip[0].First_Period := False;
     SoundChip[0].Ampl := 0;
     SoundChip[0].SetMixerRegister(SoundChip[0].RegisterAY.Mixer);
     SoundChip[0].SetAmplA(SoundChip[0].RegisterAY.AmplitudeA);
     SoundChip[0].SetAmplB(SoundChip[0].RegisterAY.AmplitudeB);
     SoundChip[0].SetAmplC(SoundChip[0].RegisterAY.AmplitudeC);
    end
   else
     ResetAYChipEmulation(0, False);
   BaseSample := trunc(l / FrqZ80 * MaxTStates * SampleRate + 0.5);
   ProgrPos := trunc(newpos / maxpos * ProgrMax + 0.5);
   VProgrPos := ProgrPos;
  end
 else if CurFileType = FT.SNDH then
  begin
   if not Atari_SeekTo(round(newpos / maxpos * PlConsts[0].Global_Tick_Max)) then
   ;//todo могут быть ошибки исполнения mc68000
   BaseSample := trunc(PlConsts[0].Global_Tick_Counter * 1000 /
     Interrupt_Freq * SampleRate + 0.5);
   ProgrPos := trunc(newpos / maxpos * ProgrMax + 0.5);
   VProgrPos := ProgrPos;
  end;
 CurrTime_Rasch := trunc(VProgrPos / SampleRate * 1000 + 0.5);
end;

procedure FreePlayingResourses;
begin
 if FileOpened then
  begin
   UniReadClose(FileHandle);
   FileOpened := False;
  end;
 if FileLoaded then
  begin
   FileLoaded := False;
   if (CurFileType = FT.VTX) or IsSTSoundFileType(CurFileType) then
    begin
     FreeMem(PVTXYMUnpackedData);
     if ((CurFileType = FT.YM5) or (CurFileType = FT.YM6)) and
       (Length(DDrumSamples) > 0) then
       DDrumSamples := nil;
    end
   else if CurFileType = FT.SNDH then
     Atari_Free
   else if CurFileType = FT.FXM then
    begin
     FXM_StekC := nil;
     FXM_StekB := nil;
     FXM_StekA := nil;
    end
   {$IFDEF Windows}
   else if IsMIDIFileType(CurFileType) then
     unload_midi(MIDIParams);
   {$ENDIF Windows}
  end;
 FrmMain.RestoreAllParams;
end;

procedure BASSGetType(h: longword; PPLItem: pointer);
var
 info: BASS_CHANNELINFO;
 t: integer;
begin
 if h = 0 then
   Exit;
 if not BASS_ChannelGetInfo(h, info) then
   Exit;
 case info.ctype of
   BASS_CTYPE_STREAM_VORBIS: t := GetFileType('OGG');
   BASS_CTYPE_STREAM_MP1: t := GetFileType('MP1');
   BASS_CTYPE_STREAM_MP2: t := GetFileType('MP2');
   BASS_CTYPE_STREAM_MP3: t := GetFileType('MP3');
   BASS_CTYPE_STREAM_AIFF: t := GetFileType('AIFF');
   // BASS_CTYPE_STREAM_AM Android media codec stream. Additional format information is avaliable from BASS_ChannelGetTags (BASS_TAG_AM_MIME).
   //BASS_CTYPE_STREAM_CA CoreAudio codec stream. Additional format information is avaliable from BASS_ChannelGetTags (BASS_TAG_CA_CODEC).
   //BASS_CTYPE_STREAM_MF Media Foundation codec stream. Additional format information is avaliable from BASS_ChannelGetTags (BASS_TAG_WAVEFORMAT).
   BASS_CTYPE_STREAM_AAC: t := GetFileType('AAC');
   BASS_CTYPE_STREAM_MP4: t := GetFileType('M4A');
   BASS_CTYPE_STREAM_AC3: t := GetFileType('AC3');
   BASS_CTYPE_STREAM_ALAC: t := GetFileType('M4A');
   BASS_CTYPE_STREAM_APE: t := GetFileType('APE');
   BASS_CTYPE_STREAM_DSD: t := GetFileType('DFF');
   BASS_CTYPE_STREAM_FLAC, BASS_CTYPE_STREAM_FLAC_OGG: t := GetFileType('FLAC');
   BASS_CTYPE_STREAM_OPUS: t := GetFileType('OPUS');
   BASS_CTYPE_STREAM_WMA, BASS_CTYPE_STREAM_WMA_MP3: t := GetFileType('WMA');
   BASS_CTYPE_STREAM_WV: t := GetFileType('WV');
   // BASS_CTYPE_STREAM_WAV_PCM Integer PCM WAVE format stream.
   // BASS_CTYPE_STREAM_WAV_FLOAT Floating-point PCM WAVE format stream.
   // BASS_CTYPE_STREAM_WAV WAVE format flag. This can be used to test if the channel is any kind of WAVE format. The codec (the file's "wFormatTag") is specified in the LOWORD. Additional information is also avaliable from BASS_ChannelGetTags (BASS_TAG_WAVEFORMAT).
   BASS_CTYPE_MUSIC_MOD: t := GetFileType('MOD');
   BASS_CTYPE_MUSIC_MTM: t := GetFileType('MTM');
   BASS_CTYPE_MUSIC_S3M: t := GetFileType('S3M');
   BASS_CTYPE_MUSIC_XM: t := GetFileType('XM');
   BASS_CTYPE_MUSIC_IT: t := GetFileType('IT');
   BASS_CTYPE_MUSIC_MOD or BASS_CTYPE_MUSIC_MO3,
   BASS_CTYPE_MUSIC_MTM or BASS_CTYPE_MUSIC_MO3,
   BASS_CTYPE_MUSIC_S3M or BASS_CTYPE_MUSIC_MO3,
   BASS_CTYPE_MUSIC_XM or BASS_CTYPE_MUSIC_MO3,
   BASS_CTYPE_MUSIC_IT or BASS_CTYPE_MUSIC_MO3: t := GetFileType('MO3');
 else
   Exit;
  end;
 if t >= 0 then
   PPlayListItem(PPLItem)^.FileType := t;
end;

procedure BASSGetTags(h: longword; PPLItem: pointer);
var
 Tags: TTags;
 p: PChar;
 i: integer;
begin
 if h = 0 then
   Exit;
 with PPlayListItem(PPLItem)^ do
   if IsModuleFileType(FileType) then
    begin
     Title := CPToUTF8(Trim(BASS_ChannelGetTags(h, BASS_TAG_MUSIC_NAME)));
     Comment := CPToUTF8(Trim(BASS_ChannelGetTags(h, BASS_TAG_MUSIC_MESSAGE)));
     i := 0;
     repeat
       p := BASS_ChannelGetTags(h, BASS_TAG_MUSIC_INST + i);
       if p = nil then break;
       if Comment <> '' then Comment := Comment + #13#10;
       Comment := Comment + 'I' + IntToStr(i) + ': ' + CPToUTF8(Trim(p));
       Inc(i);
     until False;
     i := 0;
     repeat
       p := BASS_ChannelGetTags(h, BASS_TAG_MUSIC_SAMPLE + i);
       if p = nil then break;
       if Comment <> '' then Comment := Comment + #13#10;
       Comment := Comment + 'S' + IntToStr(i) + ': ' + CPToUTF8(Trim(p));
       Inc(i);
     until False;
    end
 {WAVFile:
  Title := BASS_ChannelGetTags(h,BASS_TAG_RIFF_INFO);}
   else
   if TAGS_Read(h, Tags, GetFileType(FileType) = 'APE'{APEFile}) then
    begin
     Author := Tags.Artist;
     Title := Tags.Title;
     Comment := Tags.Comment;
     Date := Tags.Date;
    end;
end;

procedure incr(var i: longword);
begin
 Inc(i);
 if i >= 65536 then RaiseBadFileStructure;
end;

procedure GetTimeFXM(Module: PModTypes; Address: integer; var Tm, Lp: integer);

 function FXM_Loop_Found(j11, j22, j33: word): boolean;
 var
   j1, j2, j3: longword;
   a1, a2, a3: byte;
   f71, f72, f73: boolean;
   f61, f62, f63: boolean;
   fxms1, fxms2, fxms3: array of word;
   k, tr: integer;
 begin
   fxms1 := nil;
   fxms2 := nil;
   fxms3 := nil;
   j1 := PWord(@Module^.Index[Address])^;
   j2 := PWord(@Module^.Index[Address + 2])^;
   j3 := PWord(@Module^.Index[Address + 4])^;
   a1 := 1;
   a2 := 1;
   a3 := 1;
   f71 := False;
   f72 := False;
   f73 := False;
   f61 := False;
   f62 := False;
   f63 := False;
   tr := 0;
   repeat
     if (j1 = j11) and (j2 = j22) and (j3 = j33) then
      begin
       Result := True;
       Lp := tr;
       exit;
      end;
     Dec(a1);
     if a1 = 0 then
      begin
       f71 := False;
       f61 := False;
       repeat
         case Module^.Index[j1] of
           0..$7F, $8F..$FF:
            begin
             incr(j1);
             a1 := Module^.Index[j1];
             incr(j1);
             break;
            end;
           $80:
            begin
             if j1 >= 65536 - 2 then RaiseBadFileStructure;
             j1 := PWord(@Module^.Index[j1 + 1])^;
             f71 := True;
            end;
           $81:
            begin
             if j1 >= 65536 - 3 then RaiseBadFileStructure;
             k := Length(fxms1);
             SetLength(fxms1, k + 1);
             fxms1[k] := j1 + 3;
             j1 := PWord(@Module^.Index[j1 + 1])^;
            end;
           $82:
            begin
             if (j1 = j11) and (j2 = j22) and (j3 = j33) then
              begin
               Result := True;
               Lp := tr;
               exit;
              end;
             k := Length(fxms1);
             SetLength(fxms1, k + 2);
             incr(j1);
             fxms1[k] := Module^.Index[j1];
             incr(j1);
             fxms1[k + 1] := j1;
            end;
           $83:
            begin
             k := Length(fxms1);
             if k < 2 then RaiseBadFileStructure;
             Dec(fxms1[k - 2]);
             if fxms1[k - 2] and 255 <> 0 then
              begin
               j1 := fxms1[k - 1];
               f61 := True;
              end
             else
              begin
               SetLength(fxms1, k - 2);
               Inc(j1);
              end;
            end;
           $84, $85, $88, $8D, $8E:
             Inc(j1, 2);
           $86, $87, $8C:
             Inc(j1, 3);
           $89:
            begin
             k := Length(fxms1);
             if k < 1 then RaiseBadFileStructure;
             j1 := fxms1[k - 1];
             SetLength(fxms1, k - 1);
            end;
           $8A, $8B:
             Inc(j1);
          end;
         if j1 >= 65536 then RaiseBadFileStructure
       until False;
      end;
     Dec(a2);
     if a2 = 0 then
      begin
       f72 := False;
       f62 := False;
       repeat
         case Module^.Index[j2] of
           0..$7F, $8F..$FF:
            begin
             incr(j2);
             a2 := Module^.Index[j2];
             incr(j2);
             break;
            end;
           $80:
            begin
             if j2 >= 65536 - 2 then RaiseBadFileStructure;
             j2 := PWord(@Module^.Index[j2 + 1])^;
             f72 := True;
            end;
           $81:
            begin
             if j2 >= 65536 - 3 then RaiseBadFileStructure;
             k := Length(fxms2);
             SetLength(fxms2, k + 1);
             fxms2[k] := j2 + 3;
             j2 := PWord(@Module^.Index[j2 + 1])^;
            end;
           $82:
            begin
             if (j1 = j11) and (j2 = j22) and (j3 = j33) then
              begin
               Result := True;
               Lp := tr;
               exit;
              end;
             k := Length(fxms2);
             SetLength(fxms2, k + 2);
             incr(j2);
             fxms2[k] := Module^.Index[j2];
             incr(j2);
             fxms2[k + 1] := j2;
            end;
           $83:
            begin
             k := Length(fxms2);
             if k < 2 then RaiseBadFileStructure;
             Dec(fxms2[k - 2]);
             if fxms2[k - 2] and 255 <> 0 then
              begin
               j2 := fxms2[k - 1];
               f62 := True;
              end
             else
              begin
               SetLength(fxms2, k - 2);
               Inc(j2);
              end;
            end;
           $84, $85, $88, $8D, $8E:
             Inc(j2, 2);
           $86, $87, $8C:
             Inc(j2, 3);
           $89:
            begin
             k := Length(fxms2);
             if k < 1 then RaiseBadFileStructure;
             j2 := fxms2[k - 1];
             SetLength(fxms2, k - 1);
            end;
           $8A, $8B:
             Inc(j2)
          end;
         if j2 >= 65536 then RaiseBadFileStructure
       until False;
      end;
     Dec(a3);
     if a3 = 0 then
      begin
       f73 := False;
       f63 := False;
       repeat
         case Module^.Index[j3] of
           0..$7F, $8F..$FF:
            begin
             incr(j3);
             a3 := Module^.Index[j3];
             incr(j3);
             break;
            end;
           $80:
            begin
             if j3 >= 65536 - 2 then RaiseBadFileStructure;
             j3 := PWord(@Module^.Index[j3 + 1])^;
             f73 := True;
            end;
           $81:
            begin
             if j3 >= 65536 - 3 then RaiseBadFileStructure;
             k := Length(fxms3);
             SetLength(fxms3, k + 1);
             fxms3[k] := j3 + 3;
             j3 := PWord(@Module^.Index[j3 + 1])^;
            end;
           $82:
            begin
             if (j1 = j11) and (j2 = j22) and (j3 = j33) then
              begin
               Result := True;
               Lp := tr;
               exit;
              end;
             k := Length(fxms3);
             SetLength(fxms3, k + 2);
             incr(j3);
             fxms3[k] := Module^.Index[j3];
             incr(j3);
             fxms3[k + 1] := j3;
            end;
           $83:
            begin
             k := Length(fxms3);
             if k < 2 then RaiseBadFileStructure;
             Dec(fxms3[k - 2]);
             if fxms3[k - 2] and 255 <> 0 then
              begin
               j3 := fxms3[k - 1];
               f63 := True;
              end
             else
              begin
               SetLength(fxms3, k - 2);
               Inc(j3);
              end;
            end;
           $84, $85, $88, $8D, $8E:
             Inc(j3, 2);
           $86, $87, $8C:
             Inc(j3, 3);
           $89:
            begin
             k := Length(fxms3);
             if k < 1 then RaiseBadFileStructure;
             j3 := fxms3[k - 1];
             SetLength(fxms3, k - 1);
            end;
           $8A, $8B:
             Inc(j3);
          end;
         if j3 >= 65536 then RaiseBadFileStructure
       until False;
      end;
     Inc(tr);
   until ((f71 and (f72 or f62) and (f73 or f63)) or
       ((f71 or f61) and f72 and (f73 or f63)) or
       ((f71 or f61) and (f72 or f62) and f73));
   Result := False;
 end;

var
 j1, j2, j3: longword;
 a1, a2, a3: shortint;
 f71, f72, f73, f61, f62, f63: boolean;
 k: integer;
 j11, j22, j33: word;
 fxms1, fxms2, fxms3: array of word;
begin
 fxms1 := nil;
 fxms2 := nil;
 fxms3 := nil;
 with Module^ do
  begin
   if Address > 65536 - 6 then RaiseBadFileStructure;
   j1 := PWord(@Index[Address])^;
   j2 := PWord(@Index[Address + 2])^;
   j3 := PWord(@Index[Address + 4])^;
   a1 := 1;
   a2 := 1;
   a3 := 1;
   f71 := False;
   f72 := False;
   f73 := False;
   f61 := False;
   f62 := False;
   f63 := False;
   repeat
     Dec(a1);
     if a1 = 0 then
      begin
       f71 := False;
       f61 := False;
       repeat
         case Index[j1] of
           0..$7F, $8F..$FF:
            begin
             Incr(j1);
             a1 := Index[j1];
             Incr(j1);
             break;
            end;
           $80:
            begin
             if j1 >= 65536 - 2 then RaiseBadFileStructure;
             j1 := PWord(@Index[j1 + 1])^;
             j11 := j1;
             f71 := True;
            end;
           $81:
            begin
             if j1 >= 65536 - 3 then RaiseBadFileStructure;
             k := System.Length(fxms1);
             SetLength(fxms1, k + 1);
             fxms1[k] := j1 + 3;
             j1 := PWord(@Index[j1 + 1])^;
            end;
           $82:
            begin
             k := System.Length(fxms1);
             SetLength(fxms1, k + 2);
             Incr(j1);
             fxms1[k] := Index[j1];
             Incr(j1);
             fxms1[k + 1] := j1;
            end;
           $83:
            begin
             k := System.Length(fxms1);
             if k < 2 then RaiseBadFileStructure;
             Dec(fxms1[k - 2]);
             if fxms1[k - 2] and 255 <> 0 then
              begin
               j1 := fxms1[k - 1];
               if j1 < 2 then RaiseBadFileStructure;
               j11 := j1 - 2;
               f61 := True;
              end
             else
              begin
               SetLength(fxms1, k - 2);
               Inc(j1);
              end;
            end;
           $84, $85, $88, $8D, $8E:
             Inc(j1, 2);
           $86, $87, $8C:
             Inc(j1, 3);
           $89:
            begin
             k := System.Length(fxms1);
             if k < 1 then RaiseBadFileStructure;
             j1 := fxms1[k - 1];
             SetLength(fxms1, k - 1);
            end;
           $8A, $8B:
             Inc(j1)
          end;
         if j1 >= 65536 then RaiseBadFileStructure
       until False;
      end;
     Dec(a2);
     if a2 = 0 then
      begin
       f72 := False;
       f62 := False;
       repeat
         case Index[j2] of
           0..$7F, $8F..$FF:
            begin
             Incr(j2);
             a2 := Index[j2];
             Incr(j2);
             break;
            end;
           $80:
            begin
             if j2 >= 65536 - 2 then RaiseBadFileStructure;
             j2 := PWord(@Index[j2 + 1])^;
             j22 := j2;
             f72 := True;
            end;
           $81:
            begin
             if j2 >= 65536 - 3 then RaiseBadFileStructure;
             k := System.Length(fxms2);
             SetLength(fxms2, k + 1);
             fxms2[k] := j2 + 3;
             j2 := PWord(@Module^.Index[j2 + 1])^;
            end;
           $82:
            begin
             k := System.Length(fxms2);
             SetLength(fxms2, k + 2);
             Incr(j2);
             fxms2[k] := Index[j2];
             Incr(j2);
             fxms2[k + 1] := j2;
            end;
           $83:
            begin
             k := System.Length(fxms2);
             if k < 2 then RaiseBadFileStructure;
             Dec(fxms2[k - 2]);
             if fxms2[k - 2] and 255 <> 0 then
              begin
               j2 := fxms2[k - 1];
               if j2 < 2 then RaiseBadFileStructure;
               j22 := j2 - 2;
               f62 := True;
              end
             else
              begin
               SetLength(fxms2, k - 2);
               Inc(j2);
              end;
            end;
           $84, $85, $88, $8D, $8E:
             Inc(j2, 2);
           $86, $87, $8C:
             Inc(j2, 3);
           $89:
            begin
             k := System.Length(fxms2);
             if k < 1 then RaiseBadFileStructure;
             j2 := fxms2[k - 1];
             SetLength(fxms2, k - 1);
            end;
           $8A, $8B:
             Inc(j2)
          end;
         if j2 >= 65536 then RaiseBadFileStructure
       until False;
      end;
     Dec(a3);
     if a3 = 0 then
      begin
       f73 := False;
       f63 := False;
       repeat
         case Index[j3] of
           0..$7F, $8F..$FF:
            begin
             Incr(j3);
             a3 := Index[j3];
             Incr(j3);
             break;
            end;
           $80:
            begin
             if j3 >= 65536 - 2 then RaiseBadFileStructure;
             j3 := PWord(@Index[j3 + 1])^;
             j33 := j3;
             f73 := True;
            end;
           $81:
            begin
             if j3 >= 65536 - 3 then RaiseBadFileStructure;
             k := System.Length(fxms3);
             SetLength(fxms3, k + 1);
             fxms3[k] := j3 + 3;
             j3 := PWord(@Index[j3 + 1])^;
            end;
           $82:
            begin
             k := System.Length(fxms3);
             SetLength(fxms3, k + 2);
             Incr(j3);
             fxms3[k] := Index[j3];
             Incr(j3);
             fxms3[k + 1] := j3;
            end;
           $83:
            begin
             k := System.Length(fxms3);
             if k < 2 then RaiseBadFileStructure;
             Dec(fxms3[k - 2]);
             if fxms3[k - 2] and 255 <> 0 then
              begin
               j3 := fxms3[k - 1];
               if j3 < 2 then RaiseBadFileStructure;
               j33 := j3 - 2;
               f63 := True;
              end
             else
              begin
               SetLength(fxms3, k - 2);
               Inc(j3);
              end;
            end;
           $84, $85, $88, $8D, $8E:
             Inc(j3, 2);
           $86, $87, $8C:
             Inc(j3, 3);
           $89:
            begin
             k := System.Length(fxms3);
             if k < 1 then RaiseBadFileStructure;
             j3 := fxms3[k - 1];
             SetLength(fxms3, k - 1);
            end;
           $8A, $8B:
             Inc(j3)
          end;
         if j3 >= 65536 then RaiseBadFileStructure
       until False;
      end;
     Inc(tm);
     if tm > 180000 then
      begin
       tm := 15001;
       break;
      end
   until ((f71 and (f72 or f62) and (f73 or f63)) or
       ((f71 or f61) and f72 and (f73 or f63)) or
       ((f71 or f61) and (f72 or f62) and f73)) and FXM_Loop_Found(j11, j22, j33);
   Dec(tm);
  end;
end;

procedure GetTimeGTR(Module: PModTypes; var Tm, Lp: integer);
var
 a: byte;
 a1: shortint;
 flg: boolean;
 j1: longword;
begin
 with Module^ do
  begin
   a := 0;
   a1 := 0;
   flg := False;
   j1 := GTR_PatternsPointers[GTR_Positions[0] div 6].PatternA;
   repeat
     Dec(a1);
     if a1 < 0 then
      begin
       a1 := 0;
       while Index[j1] = 255 do
        begin
         Inc(a);
         flg := a >= GTR_NumberOfPositions;
         if flg then break;
         if a = GTR_LoopPosition then Lp := tm;
         j1 := GTR_PatternsPointers[Module^.GTR_Positions[a] div 6].PatternA;
        end;
       if flg then break;
       repeat
         case Index[j1] of
           0..$5f, $D0..$DF:
            begin
             Incr(j1);
             break;
            end;
           $80..$BF:
             a1 := Index[j1] - $80;
           $C0..$CF:
             Inc(j1);
           $E0:
             if GTR_ID[3] <> #$10 then
              begin
               Incr(j1);
               break;
              end
          end;
         Incr(j1);
       until False;
      end;
     Inc(tm, GTR_Delay);
   until False;
  end;
end;

procedure GetTimeSTC(Module: PModTypes; var Tm: integer);
var
 i, j: integer;
 j1, j2: longword;
 a: byte;
begin
 with Module^ do
  begin
   j := -1;
   repeat
     Inc(j);
     j2 := ST_PositionsPointer + j * 2;
     incr(j2);
     j2 := Index[j2];
     i := -1;
     repeat
       Inc(i);
       j1 := ST_PatternsPointer + 7 * i;
       if j1 >= 65535 then RaiseBadFileStructure
     until Index[j1] = j2;
     j1 := PWord(@Index[j1 + 1])^;
     a := 1;
     while Index[j1] <> 255 do
      begin
       case Index[j1] of
         0..$5f, $80, $81:
           Inc(tm, a);
         $a1..$e0:
           a := Index[j1] - $a0;
         $83..$8e:
           Inc(j1);
        end;
       incr(j1);
      end;
   until j = Index[ST_PositionsPointer];
   tm := tm * ST_Delay;
  end;
end;

procedure GetTimeASC(Module: PModTypes; var Tm, Lp: integer);
var
 i: integer;
 j1, j2, j3: longword;
 b: byte;
 a1, a2, a3, a11, a22, a33: shortint;
 Env1, Env2, Env3: boolean;
 DLCatcher: integer;
begin
 a1 := 0;
 a2 := 0;
 a3 := 0;
 a11 := 0;
 a22 := 0;
 a33 := 0;
 Env1 := False;
 Env2 := False;
 Env3 := False;
 with Module^ do
  begin
   b := ASC1_Delay;
   DLCatcher := 16384;
   for i := 0 to ASC1_Number_Of_Positions - 1 do
    begin
     if ASC1_LoopingPosition = i then Lp := tm;
     j1 := PWord(@Index[ASC1_PatternsPointers + 6 * Index[i + 9]])^
       + ASC1_PatternsPointers;
     j2 := PWord(@Index[ASC1_PatternsPointers + 6 * Index[i + 9] + 2])^ +
       ASC1_PatternsPointers;
     j3 := PWord(@Index[ASC1_PatternsPointers + 6 * Index[i + 9] + 4])^ +
       ASC1_PatternsPointers;
     repeat
       Dec(a1);
       if a1 < 0 then
        begin
         if Index[j1] = 255 then break;
         repeat
           case Index[j1] of
             0..$55:
              begin
               a1 := a11;
               incr(j1);
               if Env1 then incr(j1);
               break;
              end;
             $56..$5f:
              begin
               a1 := a11;
               incr(j1);
               break;
              end;
             $60..$9f:
               a11 := Index[j1] - $60;
             $e0:
               Env1 := True;
             $e1..$ef:
               Env1 := False;
             $f0, $f5..$f7, $f9, $fb:
               Inc(j1);
             $f4:
              begin
               incr(j1);
               b := Index[j1];
              end
            end;
           incr(j1)
         until False;
        end;
       Dec(a2);
       if a2 < 0 then
         repeat
           case Index[j2] of
             0..$55:
              begin
               a2 := a22;
               incr(j2);
               if Env2 then incr(j2);
               break;
              end;
             $56..$5f:
              begin
               a2 := a22;
               incr(j2);
               break;
              end;
             $60..$9f:
               a22 := Index[j2] - $60;
             $e0:
               Env2 := True;
             $e1..$ef:
               Env2 := False;
             $f0, $f5..$f7, $f9, $fb:
               Inc(j2);
             $f4:
              begin
               incr(j2);
               b := Index[j2];
              end
            end;
           incr(j2)
         until False;
       Dec(a3);
       if a3 < 0 then
         repeat
           case Module^.Index[j3] of
             0..$55:
              begin
               a3 := a33;
               incr(j3);
               if Env3 then incr(j3);
               break;
              end;
             $56..$5f:
              begin
               a3 := a33;
               incr(j3);
               break;
              end;
             $60..$9f:
               a33 := Index[j3] - $60;
             $e0:
               env3 := True;
             $e1..$ef:
               env3 := False;
             $f0, $f5..$f7, $f9, $fb:
               Inc(j3);
             $f4:
              begin
               incr(j3);
               b := Index[j3];
              end;
            end;
           incr(j3);
         until False;
       Inc(tm, b);
       Dec(DLCatcher);
       if DLCatcher < 0 then RaiseBadFileStructure;
     until False;
    end;
  end;
end;

procedure GetTimeSTP(Module: PModTypes; var Tm, Lp: integer);
var
 a: byte;
 i: integer;
 j1: longword;
begin
 a := 1;
 with Module^ do
  begin
   for i := 0 to Index[STP_PositionsPointer] - 1 do
    begin
     if i = Index[STP_PositionsPointer + 1] then
       Lp := tm * STP_Delay;
     j1 := PWord(@Index[STP_PatternsPointer +
       Index[STP_PositionsPointer + 2 + i * 2]])^;
     while Index[j1] <> 0 do
      begin
       case Index[j1] of
         1..$60, $d0..$ef:
           Inc(tm, a);
         $80..$BF:
           a := Index[j1] - $7f;
         $c0..$cf, $f0:
           Inc(j1);
        end;
       incr(j1);
      end;
    end;
   tm := tm * STP_Delay;
  end;
end;

procedure GetTimePT2(Module: PModTypes; var Tm, Lp: integer);
var
 i: integer;
 b: byte;
 a1, a2, a3, a11, a22, a33: shortint;
 DLCatcher: integer;
 j1, j2, j3: longword;
begin
 with Module^ do
  begin
   b := PT2_Delay;
   a1 := 0;
   a2 := 0;
   a3 := 0;
   a11 := 0;
   a22 := 0;
   a33 := 0;
   DLCatcher := 16384;
   i := 0;
   repeat
     if i >= 65536 - 131 then RaiseBadFileStructure;
     if shortint(PT2_PositionList[i]) < 0 then break;
     if i = PT2_LoopPosition then Lp := tm;
     j1 := PWord(@Index[PT2_PatternsPointer + PT2_PositionList[i] * 6])^;
     j2 := PWord(@Index[PT2_PatternsPointer + PT2_PositionList[i] * 6 + 2])^;
     j3 := PWord(@Index[PT2_PatternsPointer + PT2_PositionList[i] * 6 + 4])^;
     repeat
       Dec(a1);
       if a1 < 0 then
        begin
         if Index[j1] = 0 then break;
         repeat
           case Index[j1] of
             $70, $80..$e0:
              begin
               a1 := a11;
               incr(j1);
               break;
              end;
             $71..$7e:
               Inc(j1, 2);
             $20..$5f:
               a11 := Index[j1] - $20;
             $f:
              begin
               incr(j1);
               b := Index[j1];
              end;
             1..$b, $e:
               Inc(j1);
             $d:
               Inc(j1, 3)
            end;
           incr(j1)
         until False;
        end;
       Dec(a2);
       if a2 < 0 then
         repeat
           case Index[j2] of
             $70, $80..$e0:
              begin
               a2 := a22;
               incr(j2);
               break;
              end;
             $71..$7e:
               Inc(j2, 2);
             $20..$5f:
               a22 := Index[j2] - $20;
             $f:
              begin
               incr(j2);
               b := Index[j2];
              end;
             1..$b, $e:
               Inc(j2);
             $d:
               Inc(j2, 3)
            end;
           incr(j2)
         until False;
       Dec(a3);
       if a3 < 0 then
         repeat
           case Index[j3] of
             $70, $80..$e0:
              begin
               a3 := a33;
               incr(j3);
               break;
              end;
             $71..$7e:
               Inc(j3, 2);
             $20..$5f:
               a33 := Index[j3] - $20;
             $f:
              begin
               incr(j3);
               b := Index[j3];
              end;
             1..$b, $e:
               Inc(j3);
             $d:
               Inc(j3, 3)
            end;
           incr(j3)
         until False;
       Inc(tm, b);
       Dec(DLCatcher);
       if DLCatcher < 0 then RaiseBadFileStructure;
     until False;
     Inc(i);
   until False;
  end;
end;

procedure GetTimePT3(Module: PModTypes; var Tm, Lp: integer);
var
 b: byte;
 TS: integer;
 vars: array[0..1] of record
   a1, a2, a3, a11, a22, a33: shortint;
   j1, j2, j3: longword;
    end;

 procedure GetPatPtrs(n, i: integer);
 begin
   if (i < 0) or (i > 84 * 3) or (i mod 3 <> 0) then RaiseBadFileStructure;
   with vars[n], Module^ do
    begin
     j1 := PWord(@Index[PT3_PatternsPointer + i * 2])^;
     j2 := PWord(@Index[PT3_PatternsPointer + i * 2 + 2])^;
     j3 := PWord(@Index[PT3_PatternsPointer + i * 2 + 4])^;
    end;
 end;

 function PatInt(n: integer): boolean;
 var
   j, c1, c2, c3, c4, c5, c8: integer;
 begin
   Result := False;
   with vars[n], Module^ do
    begin
     Dec(a1);
     if a1 = 0 then
      begin
       if Index[j1] = 0 then exit;
       j := 0;
       c1 := 0;
       c2 := 0;
       c3 := 0;
       c4 := 0;
       c5 := 0;
       c8 := 0;
       repeat
         case Index[j1] of
           $d0, $c0, $50..$af:
            begin
             a1 := a11;
             incr(j1);
             break;
            end;
           $10, $f0..$ff:
             Inc(j1);
           $b2..$bf:
             Inc(j1, 2);
           $b1:
            begin
             incr(j1);
             a11 := Index[j1];
            end;
           $11..$1f:
             Inc(j1, 3);
           1:
            begin
             Inc(j);
             c1 := j;
            end;
           2:
            begin
             Inc(j);
             c2 := j;
            end;
           3:
            begin
             Inc(j);
             c3 := j;
            end;
           4:
            begin
             Inc(j);
             c4 := j;
            end;
           5:
            begin
             Inc(j);
             c5 := j;
            end;
           8:
            begin
             Inc(j);
             c8 := j;
            end;
           9:
             Inc(j)
          end;
         incr(j1)
       until False;
       while j > 0 do
        begin
         if (j = c1) or (j = c8) then
           Inc(j1, 3)
         else if (j = c2) then
           Inc(j1, 5)
         else if (j = c3) or (j = c4) then
           Inc(j1)
         else if (j = c5) then
           Inc(j1, 2)
         else
          begin
           b := Index[j1];
           Inc(j1);
          end;
         if j1 >= 65536 then RaiseBadFileStructure;
         Dec(j);
        end;
      end;
     Dec(a2);
     if a2 = 0 then
      begin
       j := 0;
       c1 := 0;
       c2 := 0;
       c3 := 0;
       c4 := 0;
       c5 := 0;
       c8 := 0;
       repeat
         case Index[j2] of
           $d0, $c0, $50..$af:
            begin
             a2 := a22;
             incr(j2);
             break;
            end;
           $10, $f0..$ff:
             Inc(j2);
           $b2..$bf:
             Inc(j2, 2);
           $b1:
            begin
             incr(j2);
             a22 := Index[j2];
            end;
           $11..$1f:
             Inc(j2, 3);
           1:
            begin
             Inc(j);
             c1 := j;
            end;
           2:
            begin
             Inc(j);
             c2 := j;
            end;
           3:
            begin
             Inc(j);
             c3 := j;
            end;
           4:
            begin
             Inc(j);
             c4 := j;
            end;
           5:
            begin
             Inc(j);
             c5 := j;
            end;
           8:
            begin
             Inc(j);
             c8 := j;
            end;
           9:
             Inc(j)
          end;
         incr(j2)
       until False;
       while j > 0 do
        begin
         if (j = c1) or (j = c8) then
           Inc(j2, 3)
         else if (j = c2) then
           Inc(j2, 5)
         else if (j = c3) or (j = c4) then
           Inc(j2)
         else if (j = c5) then
           Inc(j2, 2)
         else
          begin
           b := Index[j2];
           Inc(j2);
          end;
         if j2 >= 65536 then RaiseBadFileStructure;
         Dec(j);
        end;
      end;
     Dec(a3);
     if a3 = 0 then
      begin
       j := 0;
       c1 := 0;
       c2 := 0;
       c3 := 0;
       c4 := 0;
       c5 := 0;
       c8 := 0;
       repeat
         case Module^.Index[j3] of
           $d0, $c0, $50..$af:
            begin
             a3 := a33;
             incr(j3);
             break;
            end;
           $10, $f0..$ff:
             Inc(j3);
           $b2..$bf:
             Inc(j3, 2);
           $b1:
            begin
             incr(j3);
             a33 := Index[j3];
            end;
           $11..$1f:
             Inc(j3, 3);
           1:
            begin
             Inc(j);
             c1 := j;
            end;
           2:
            begin
             Inc(j);
             c2 := j;
            end;
           3:
            begin
             Inc(j);
             c3 := j;
            end;
           4:
            begin
             Inc(j);
             c4 := j;
            end;
           5:
            begin
             Inc(j);
             c5 := j;
            end;
           8:
            begin
             Inc(j);
             c8 := j;
            end;
           9:
             Inc(j)
          end;
         incr(j3)
       until False;
       while j > 0 do
        begin
         if (j = c1) or (j = c8) then
           Inc(j3, 3)
         else if (j = c2) then
           Inc(j3, 5)
         else if (j = c3) or (j = c4) then
           Inc(j3)
         else if (j = c5) then
           Inc(j3, 2)
         else
          begin
           b := Index[j3];
           Inc(j3);
          end;
         if j3 >= 65536 then RaiseBadFileStructure;
         Dec(j);
        end;
      end;
    end;
   Result := True;
 end;

var
 i: integer;
 DLCatcher: integer;
begin
 with Module^ do
  begin
   b := PT3_Delay;
   TS := $20;
   if PT3_MusicName[13] in ['7'..'9'] then
     TS := Ord(PT3_MusicName[98]);
   for i := 0 to 1 do
     with vars[i] do
      begin
       a11 := 1;
       a22 := 1;
       a33 := 1;
       DLCatcher := 256 * 256; //max 256 patterns 256 lines per pattern
      end;
   for i := 0 to PT3_NumberOfPositions - 1 do
    begin
     if i = PT3_LoopPosition then Lp := tm;
     GetPatPtrs(0, PT3_PositionList[i]);
     with vars[0] do
      begin
       a1 := 1;
       a2 := 1;
       a3 := 1;
      end;
     if TS <> $20 then
      begin
       GetPatPtrs(1, TS * 3 - 3 - PT3_PositionList[i]);
       with vars[1] do
        begin
         a1 := 1;
         a2 := 1;
         a3 := 1;
        end;
      end;
     repeat
       if not PatInt(0) then break;
       if TS <> $20 then
         if not PatInt(1) then break;
       Inc(tm, b);
       Dec(DLCatcher);
       if DLCatcher < 0 then RaiseBadFileStructure;
     until False;
    end;
  end;
end;

procedure GetTimePSC(Module: PModTypes; var Tm, Lp: integer);
var
 b: byte;
 pptr, cptr: longword;
 j1, j2, j3: longword;
 a1, a2, a3: shortint;
 i: integer;
begin
 with Module^ do
  begin
   b := PSC_Delay;
   pptr := PSC_PatternsPointer;
   incr(pptr);
   while Index[pptr] <> 255 do
    begin
     Inc(pptr, 8);
     if pptr >= 65536 then RaiseBadFileStructure;
    end;
   if pptr >= 65536 - 2 then RaiseBadFileStructure;
   cptr := PWord(@Index[pptr + 1])^;
   incr(cptr);
   pptr := PSC_PatternsPointer;
   incr(pptr);
   while Index[pptr] <> 255 do
    begin
     if pptr = cptr then Lp := tm;
     if pptr >= 65536 - 6 then RaiseBadFileStructure;
     j1 := PWord(@Index[pptr + 1])^;
     j2 := PWord(@Index[pptr + 3])^;
     j3 := PWord(@Index[pptr + 5])^;
     Inc(pptr, 8);
     if pptr >= 65536 then RaiseBadFileStructure;
     a1 := 1;
     a2 := 1;
     a3 := 1;
     for i := 1 to Index[pptr - 8] do
      begin
       Dec(a1);
       if a1 = 0 then
         repeat
           case Index[j1] of
             $c0..$ff:
              begin
               a1 := Index[j1] - $bf;
               Inc(j1);
               break;
              end;
             $67..$6d, $6f..$7b:
               Inc(j1);
             $6e:
              begin
               incr(j1);
               b := Index[j1];
              end
            end;
           incr(j1)
         until False;
       Dec(a2);
       if a2 = 0 then
         repeat
           case Index[j2] of
             $c0..$ff:
              begin
               a2 := Index[j2] - $bf;
               Inc(j2);
               break;
              end;
             $67..$6d, $6f..$79, $7b:
               Inc(j2);
             $6e:
              begin
               incr(j2);
               b := Index[j2];
              end;
             $7a:
               Inc(j2, 3)
            end;
           incr(j2)
         until False;
       Dec(a3);
       if a3 = 0 then
         repeat
           case Index[j3] of
             $c0..$ff:
              begin
               a3 := Index[j3] - $bf;
               Inc(j3);
               break;
              end;
             $67..$6d, $6f..$7b:
               Inc(j3);
             $6e:
              begin
               incr(j3);
               b := Index[j3];
              end;
            end;
           incr(j3);
         until False;
       Inc(tm, b);
      end;
    end;
  end;
end;

procedure GetTimeFTC(Module: PModTypes; var Tm, Lp: integer);
var
 b: byte;
 i: integer;
 j1, j2, j3: longword;
 a1, a2, a3: shortint;
 DLCatcher: integer;
begin
 with Module^ do
  begin
   b := FTC_Delay;
   i := 0;
   repeat
     if FTC_Positions[i].Pattern = 255 then break;
     if i = FTC_Loop_Position then Lp := tm;
     j1 := PWord(@Index[FTC_PatternsPointer + FTC_Positions[i].Pattern * 6])^;
     j2 := PWord(@Index[FTC_PatternsPointer + FTC_Positions[i].Pattern * 6 + 2])^;
     j3 := PWord(@Index[FTC_PatternsPointer + FTC_Positions[i].Pattern * 6 + 4])^;
     Inc(i);
     if i >= (65536 - $d4) div 2 then RaiseBadFileStructure;
     a1 := 0;
     a2 := 0;
     a3 := 0;
     DLCatcher := 256;
     repeat
       Dec(a1);
       if a1 < 0 then
        begin
         if Index[j1] = 255 then break;
         repeat
           case Index[j1] of
             $30, $60..$cb:
              begin
               a1 := 0;
               Incr(j1);
               break;
              end;
             $40..$5f:
              begin
               a1 := Index[j1] - $40;
               Incr(j1);
               break;
              end;
             $ee, $ef:
               Inc(j1);
             $31..$3e, $ed:
               Inc(j1, 2);
             $f0..$ff:
              begin
               Incr(j1);
               b := Index[j1];
              end
            end;
           Incr(j1)
         until False;
        end;
       Dec(a2);
       if a2 < 0 then
         repeat
           case Index[j2] of
             $30, $60..$cb:
              begin
               a2 := 0;
               Incr(j2);
               break;
              end;
             $40..$5f:
              begin
               a2 := Index[j2] - $40;
               Incr(j2);
               break;
              end;
             $ee, $ef:
               Inc(j2);
             $31..$3e, $ed:
               Inc(j2, 2);
             $f0..$ff:
              begin
               incr(j2);
               b := Index[j2];
              end
            end;
           Incr(j2)
         until False;
       Dec(a3);
       if a3 < 0 then
         repeat
           case Index[j3] of
             $30, $60..$cb:
              begin
               a3 := 0;
               Incr(j3);
               break;
              end;
             $40..$5f:
              begin
               a3 := Index[j3] - $40;
               Incr(j3);
               break;
              end;
             $ee, $ef:
               Inc(j3);
             $31..$3e, $ed:
               Inc(j3, 2);
             $f0..$ff:
              begin
               Incr(j3);
               b := Index[j3];
              end
            end;
           Incr(j3)
         until False;
       Inc(tm, b);
       Dec(DLCatcher);
       if DLCatcher < 0 then RaiseBadFileStructure;
     until False;
   until False;
  end;
end;

procedure GetTimeSQT(Module: PModTypes; var Tm, Lp: integer);
var
 pptr, cptr: longword;
 f71, f72, f73, f61, f62, f63, f41, f42, f43: boolean;
 j1, j2, j3: longword;
 j11, j22, j33: word;
 b: byte;
 a1, a2, a3: shortint;
 i: integer;
begin
 with Module^ do
  begin
   pptr := SQT_PositionsPointer;
   while Index[pptr] <> 0 do
    begin
     if pptr = SQT_LoopPointer then Lp := tm;
     f41 := Index[pptr] and 128 <> 0;
     j1 := PWord(@Index[byte(Index[pptr] * 2) + SQT_PatternsPointer])^;
     Incr(j1);
     Inc(pptr, 2);
     if pptr >= 65536 then RaiseBadFileStructure;
     f42 := Index[pptr] and 128 <> 0;
     j2 := PWord(@Index[byte(Index[pptr] * 2) + SQT_PatternsPointer])^;
     Incr(j2);
     Inc(pptr, 2);
     if pptr >= 65536 then RaiseBadFileStructure;
     f43 := Index[pptr] and 128 <> 0;
     j3 := PWord(@Index[byte(Index[pptr] * 2) + SQT_PatternsPointer])^;
     Incr(j3);
     Inc(pptr, 2);
     if pptr >= 65536 then RaiseBadFileStructure;
     b := Index[pptr];
     Incr(pptr);
     a1 := 0;
     a2 := 0;
     a3 := 0;
     for i := 1 to Index[j1 - 1] do
      begin
       if a1 <> 0 then
        begin
         Dec(a1);
         if {%H-}f71 then
          begin
           cptr := {%H-}j11;
           f61 := False;
           if Index[cptr] in [0..$7f] then
            begin
             Incr(cptr);
             case Index[cptr] of
               0..$7f:
                begin
                 Incr(cptr);
                 if f61 then j1 := cptr + 1;
                 case Index[cptr - 1] - 1 of
                   4:
                     if f41 then
                      begin
                       b := Index[cptr] and 31;
                       if b = 0 then b := 32;
                      end;
                   5:
                     if f41 then
                      begin
                       b := (b + Index[cptr]) and 31;
                       if b = 0 then b := 32;
                      end
                  end;
                end;
               $80..$ff:
                begin
                 if Index[cptr] and 64 <> 0 then
                  begin
                   Incr(cptr);
                   if Index[cptr] and 15 <> 0 then
                    begin
                     Incr(cptr);
                     if f61 then j1 := cptr + 1;
                     case (Index[cptr - 1]) and 15 - 1 of
                       4:
                         if f41 then
                          begin
                           b := Index[cptr] and 31;
                           if b = 0 then b := 32;
                          end;
                       5:
                         if f41 then
                          begin
                           b := (b + Index[cptr]) and 31;
                           if b = 0 then b := 32;
                          end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end
       else
        begin
         if j1 >= 65536 then RaiseBadFileStructure;
         cptr := j1;
         f61 := True;
         f71 := False;
         repeat
           case Index[cptr] of
             0..$5f:
              begin
               j11 := cptr;
               Incr(cptr);
               case Index[cptr] of
                 0..$7f:
                  begin
                   Incr(cptr);
                   if f61 then
                    begin
                     j1 := cptr + 1;
                     f61 := False;
                    end;
                   case Index[cptr - 1] - 1 of
                     4:
                       if f41 then
                        begin
                         b := Index[cptr] and 31;
                         if b = 0 then b := 32;
                        end;
                     5:
                       if f41 then
                        begin
                         b := (b + Index[cptr]) and 31;
                         if b = 0 then b := 32;
                        end
                    end;
                  end;
                 $80..$ff:
                  begin
                   if Index[cptr] and 64 <> 0 then
                    begin
                     Incr(cptr);
                     if Index[cptr] and 15 <> 0 then
                      begin
                       Incr(cptr);
                       if f61 then
                        begin
                         j1 := cptr + 1;
                         f61 := False;
                        end;
                       case Index[cptr - 1] and 15 - 1 of
                         4:
                           if f41 then
                            begin
                             b := Index[cptr] and 31;
                             if b = 0 then b := 32;
                            end;
                         5:
                           if f41 then
                            begin
                             b := (b + Index[cptr]) and 31;
                             if b = 0 then b := 32;
                            end;
                        end;
                      end;
                    end;
                  end;
                end;
               Incr(cptr);
               if f61 then j1 := cptr;
               break;
              end;
             $60..$6e:
              begin
               Incr(cptr);
               if f61 then j1 := cptr + 1;
               case Index[cptr - 1] - $60 - 1 of
                 4:
                   if f41 then
                    begin
                     b := Index[cptr] and 31;
                     if b = 0 then b := 32;
                    end;
                 5: if f41 then
                    begin
                     b := (b + Index[cptr]) and 31;
                     if b = 0 then b := 32;
                    end;
                end;
               break;
              end;
             $6f..$7f:
              begin
               if Index[cptr] <> $6f then
                begin
                 Incr(cptr);
                 if f61 then j1 := cptr + 1;
                 case Index[cptr - 1] - $6f - 1 of
                   4:
                     if f41 then
                      begin
                       b := Index[cptr] and 31;
                       if b = 0 then b := 32;
                      end;
                   5:
                     if f41 then
                      begin
                       b := (b + Index[cptr]) and 31;
                       if b = 0 then b := 32;
                      end
                  end;
                end
               else
                 j1 := cptr + 1;
               break;
              end;
             $80..$bf:
              begin
               j1 := cptr + 1;
               if Index[cptr] in [$a0..$bf] then
                begin
                 a1 := Index[cptr] and 15;
                 if Index[cptr] and 16 = 0 then break;
                 if a1 <> 0 then f71 := True;
                end;
               cptr := j11;
               f61 := False;
               if Index[cptr] in [0..$7f] then
                begin
                 Incr(cptr);
                 case Index[cptr] of
                   0..$7f:
                    begin
                     Incr(cptr);
                     if f61 then j1 := cptr + 1;
                     case Index[cptr - 1] - 1 of
                       4:
                         if f41 then
                          begin
                           b := Index[cptr] and 31;
                           if b = 0 then b := 32;
                          end;
                       5:
                         if f41 then
                          begin
                           b := (b + Index[cptr]) and 31;
                           if b = 0 then b := 32;
                          end
                      end;
                    end;
                   $80..$ff:
                    begin
                     if Index[cptr] and 64 <> 0 then
                      begin
                       Incr(cptr);
                       if Index[cptr] and 15 <> 0 then
                        begin
                         Incr(cptr);
                         if f61 then j1 := cptr + 1;
                         case (Index[cptr - 1]) and 15 - 1 of
                           4:
                             if f41 then
                              begin
                               b := Index[cptr] and 31;
                               if b = 0 then b := 32;
                              end;
                           5:
                             if f41 then
                              begin
                               b := (b + Index[cptr]) and 31;
                               if b = 0 then b := 32;
                              end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
               break;
              end;
             $c0..$ff:
              begin
               j1 := cptr + 1;
               j11 := cptr;
               break;
              end;
            end;
         until False;
        end;
       if a2 <> 0 then
        begin
         Dec(a2);
         if {%H-}f72 then
          begin
           cptr := {%H-}j22;
           f62 := False;
           if Index[cptr] in [0..$7f] then
            begin
             incr(cptr);
             case Index[cptr] of
               0..$7f:
                begin
                 incr(cptr);
                 if f62 then j2 := cptr + 1;
                 case Index[cptr - 1] - 1 of
                   4:
                     if f42 then
                      begin
                       b := Index[cptr] and 31;
                       if b = 0 then b := 32;
                      end;
                   5:
                     if f42 then
                      begin
                       b := (b + Index[cptr]) and 31;
                       if b = 0 then b := 32;
                      end
                  end;
                end;
               $80..$ff:
                begin
                 if Index[cptr] and 64 <> 0 then
                  begin
                   incr(cptr);
                   if Index[cptr] and 15 <> 0 then
                    begin
                     incr(cptr);
                     if f62 then j2 := cptr + 1;
                     case Index[cptr - 1] and 15 - 1 of
                       4:
                         if f42 then
                          begin
                           b := Index[cptr] and 31;
                           if b = 0 then b := 32;
                          end;
                       5:
                         if f42 then
                          begin
                           b := (b + Index[cptr]) and 31;
                           if b = 0 then b := 32;
                          end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end
       else
        begin
         if j2 >= 65536 then RaiseBadFileStructure;
         cptr := j2;
         f62 := True;
         f72 := False;
         repeat
           case Index[cptr] of
             0..$5f:
              begin
               j22 := cptr;
               Incr(cptr);
               case Index[cptr] of
                 0..$7f:
                  begin
                   Incr(cptr);
                   if f62 then
                    begin
                     j2 := cptr + 1;
                     f62 := False;
                    end;
                   case Index[cptr - 1] - 1 of
                     4:
                       if f42 then
                        begin
                         b := Index[cptr] and 31;
                         if b = 0 then b := 32;
                        end;
                     5:
                       if f42 then
                        begin
                         b := (b + Index[cptr]) and 31;
                         if b = 0 then b := 32;
                        end
                    end;
                  end;
                 $80..$ff:
                  begin
                   if Index[cptr] and 64 <> 0 then
                    begin
                     Incr(cptr);
                     if Index[cptr] and 15 <> 0 then
                      begin
                       Incr(cptr);
                       if f62 then
                        begin
                         j2 := cptr + 1;
                         f62 := False;
                        end;
                       case Index[cptr - 1] and 15 - 1 of
                         4:
                           if f42 then
                            begin
                             b := Index[cptr] and 31;
                             if b = 0 then b := 32;
                            end;
                         5:
                           if f42 then
                            begin
                             b := (b + Index[cptr]) and 31;
                             if b = 0 then b := 32;
                            end;
                        end;
                      end;
                    end;
                  end;
                end;
               incr(cptr);
               if f62 then j2 := cptr;
               break;
              end;
             $60..$6e:
              begin
               incr(cptr);
               if f62 then j2 := cptr + 1;
               case Index[cptr - 1] - $60 - 1 of
                 4:
                   if f42 then
                    begin
                     b := Index[cptr] and 31;
                     if b = 0 then b := 32;
                    end;
                 5:
                   if f42 then
                    begin
                     b := (b + Index[cptr]) and 31;
                     if b = 0 then b := 32;
                    end;
                end;
               break;
              end;
             $6f..$7f:
              begin
               if Index[cptr] <> $6f then
                begin
                 incr(cptr);
                 if f62 then j2 := cptr + 1;
                 case Index[cptr - 1] - $6f - 1 of
                   4:
                     if f42 then
                      begin
                       b := Index[cptr] and 31;
                       if b = 0 then b := 32;
                      end;
                   5:
                     if f42 then
                      begin
                       b := (b + Index[cptr]) and 31;
                       if b = 0 then b := 32;
                      end;
                  end;
                end
               else
                 j2 := cptr + 1;
               break;
              end;
             $80..$bf:
              begin
               j2 := cptr + 1;
               if not (Index[cptr] in [$80..$9f]) then
                begin
                 a2 := Index[cptr] and 15;
                 if Index[cptr] and 16 = 0 then break;
                 if a2 <> 0 then f72 := True;
                end;
               cptr := j22;
               f62 := False;
               if Index[cptr] in [0..$7f] then
                begin
                 incr(cptr);
                 case Index[cptr] of
                   0..$7f:
                    begin
                     incr(cptr);
                     if f62 then j2 := cptr + 1;
                     case Index[cptr - 1] - 1 of
                       4:
                         if f42 then
                          begin
                           b := Index[cptr] and 31;
                           if b = 0 then b := 32;
                          end;
                       5:
                         if f42 then
                          begin
                           b := (b + Index[cptr]) and 31;
                           if b = 0 then b := 32;
                          end
                      end;
                    end;
                   $80..$ff:
                    begin
                     if Index[cptr] and 64 <> 0 then
                      begin
                       incr(cptr);
                       if Index[cptr] and 15 <> 0 then
                        begin
                         incr(cptr);
                         if f62 then j2 := cptr + 1;
                         case Index[cptr - 1] and 15 - 1 of
                           4:
                             if f42 then
                              begin
                               b := Index[cptr] and 31;
                               if b = 0 then b := 32;
                              end;
                           5:
                             if f42 then
                              begin
                               b := (b + Index[cptr]) and 31;
                               if b = 0 then b := 32;
                              end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
               break;
              end;
             $c0..$ff:
              begin
               j2 := cptr + 1;
               j22 := cptr;
               break;
              end
            end
         until False;
        end;
       if a3 <> 0 then
        begin
         Dec(a3);
         if {%H-}f73 then
          begin
           cptr := {%H-}j33;
           f63 := False;
           if Index[cptr] in [0..$7f] then
            begin
             incr(cptr);
             case Index[cptr] of
               0..$7f:
                begin
                 incr(cptr);
                 if f63 then j3 := cptr + 1;
                 case Index[cptr - 1] - 1 of
                   4:
                     if f43 then
                      begin
                       b := Index[cptr] and 31;
                       if b = 0 then b := 32;
                      end;
                   5:
                     if f43 then
                      begin
                       b := (b + Index[cptr]) and 31;
                       if b = 0 then b := 32;
                      end;
                  end;
                end;
               $80..$ff:
                begin
                 if Index[cptr] and 64 <> 0 then
                  begin
                   Incr(cptr);
                   if Index[cptr] and 15 <> 0 then
                    begin
                     Incr(cptr);
                     if f63 then j3 := cptr + 1;
                     case Index[cptr - 1] and 15 - 1 of
                       4:
                         if f43 then
                          begin
                           b := Index[cptr] and 31;
                           if b = 0 then b := 32;
                          end;
                       5:
                         if f43 then
                          begin
                           b := (b + Index[cptr]) and 31;
                           if b = 0 then b := 32;
                          end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end
       else
        begin
         if j3 >= 65536 then RaiseBadFileStructure;
         cptr := j3;
         f63 := True;
         f73 := False;
         repeat
           case Index[cptr] of
             0..$5f:
              begin
               j33 := cptr;
               Incr(cptr);
               case Index[cptr] of
                 0..$7f:
                  begin
                   Incr(cptr);
                   if f63 then
                    begin
                     j3 := cptr + 1;
                     f63 := False;
                    end;
                   case Index[cptr - 1] - 1 of
                     4:
                       if f43 then
                        begin
                         b := Index[cptr] and 31;
                         if b = 0 then b := 32;
                        end;
                     5:
                       if f43 then
                        begin
                         b := (b + Index[cptr]) and 31;
                         if b = 0 then b := 32;
                        end;
                    end;
                  end;
                 $80..$ff:
                  begin
                   if Index[cptr] and 64 <> 0 then
                    begin
                     Incr(cptr);
                     if Index[cptr] and 15 <> 0 then
                      begin
                       Incr(cptr);
                       if f63 then
                        begin
                         j3 := cptr + 1;
                         f63 := False;
                        end;
                       case Index[cptr - 1] and 15 - 1 of
                         4:
                           if f43 then
                            begin
                             b := Index[cptr] and 31;
                             if b = 0 then b := 32;
                            end;
                         5:
                           if f43 then
                            begin
                             b := (b + Index[cptr]) and 31;
                             if b = 0 then b := 32;
                            end;
                        end;
                      end;
                    end;
                  end;
                end;
               incr(cptr);
               if f63 then j3 := cptr;
               break;
              end;
             $60..$6e:
              begin
               incr(cptr);
               if f63 then j3 := cptr + 1;
               case Index[cptr - 1] - $60 - 1 of
                 4:
                   if f43 then
                    begin
                     b := Index[cptr] and 31;
                     if b = 0 then b := 32;
                    end;
                 5:
                   if f43 then
                    begin
                     b := (b + Index[cptr]) and 31;
                     if b = 0 then b := 32;
                    end
                end;
               break;
              end;
             $6f..$7f:
              begin
               if Index[cptr] <> $6f then
                begin
                 Incr(cptr);
                 if f63 then j3 := cptr + 1;
                 case Index[cptr - 1] - $6f - 1 of
                   4:
                     if f43 then
                      begin
                       b := Index[cptr] and 31;
                       if b = 0 then b := 32;
                      end;
                   5:
                     if f43 then
                      begin
                       b := (b + Index[cptr]) and 31;
                       if b = 0 then b := 32;
                      end;
                  end;
                end
               else
                 j3 := cptr + 1;
               break;
              end;
             $80..$bf:
              begin
               j3 := cptr + 1;
               if not (Index[cptr] in [$80..$9f]) then
                begin
                 a3 := Index[cptr] and 15;
                 if Index[cptr] and 16 = 0 then break;
                 if a3 <> 0 then f73 := True;
                end;
               cptr := j33;
               f63 := False;
               if Index[cptr] in [0..$7f] then
                begin
                 Incr(cptr);
                 case Index[cptr] of
                   0..$7f:
                    begin
                     Incr(cptr);
                     if f63 then j3 := cptr + 1;
                     case Index[cptr - 1] - 1 of
                       4:
                         if f43 then
                          begin
                           b := Index[cptr] and 31;
                           if b = 0 then b := 32;
                          end;
                       5:
                         if f43 then
                          begin
                           b := (b + Index[cptr]) and 31;
                           if b = 0 then b := 32;
                          end;
                      end;
                    end;
                   $80..$ff:
                    begin
                     if Index[cptr] and 64 <> 0 then
                      begin
                       Incr(cptr);
                       if Index[cptr] and 15 <> 0 then
                        begin
                         Incr(cptr);
                         if f63 then j3 := cptr + 1;
                         case Index[cptr - 1] and 15 - 1 of
                           4:
                             if f43 then
                              begin
                               b := Index[cptr] and 31;
                               if b = 0 then b := 32;
                              end;
                           5:
                             if f43 then
                              begin
                               b := (b + Index[cptr]) and 31;
                               if b = 0 then b := 32;
                              end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;
               break;
              end;
             $c0..$ff:
              begin
               j3 := cptr + 1;
               j33 := cptr;
               break;
              end;
            end;
         until False;
        end;
       Inc(tm, b);
      end;
    end;
  end;
end;

procedure GetTimePT1(Module: PModTypes; var Tm, Lp: integer);
var
 b: byte;
 j1, j2, j3: longword;
 a1, a2, a3, a11, a22, a33: shortint;
 DLCatcher: integer;
 i: integer;
begin
 with Module^ do
  begin
   b := PT1_Delay;
   a1 := 0;
   a2 := 0;
   a3 := 0;
   a11 := 0;
   a22 := 0;
   a33 := 0;
   DLCatcher := 16384;
   for i := 0 to PT1_NumberOfPositions - 1 do
    begin
     if i = PT1_LoopPosition then Lp := tm;
     j1 := PWord(@Index[PT1_PatternsPointer + PT1_PositionList[i] * 6])^;
     j2 := PWord(@Index[PT1_PatternsPointer + PT1_PositionList[i] * 6 + 2])^;
     j3 := PWord(@Index[PT1_PatternsPointer + PT1_PositionList[i] * 6 + 4])^;
     repeat
       Dec(a1);
       if a1 < 0 then
        begin
         if Index[j1] = 255 then break;
         repeat
           case Index[j1] of
             $80, $90, 0..$5f:
              begin
               a1 := a11;
               Incr(j1);
               break;
              end;
             $82..$8f:
               Inc(j1, 2);
             $b1..$fe:
               a11 := Index[j1] - $b1;
             $91..$a0:
               b := Index[j1] - $91;
            end;
           Incr(j1)
         until False;
        end;
       Dec(a2);
       if a2 < 0 then
         repeat
           case Index[j2] of
             $80, $90, 0..$5f:
              begin
               a2 := a22;
               Incr(j2);
               break;
              end;
             $82..$8f:
               Inc(j2, 2);
             $b1..$fe:
               a22 := Index[j2] - $b1;
             $91..$a0:
               b := Index[j2] - $91
            end;
           Incr(j2)
         until False;
       Dec(a3);
       if a3 < 0 then
         repeat
           case Index[j3] of
             $80, $90, 0..$5f:
              begin
               a3 := a33;
               Incr(j3);
               break;
              end;
             $82..$8f:
               Inc(j3, 2);
             $b1..$fe:
               a33 := Index[j3] - $b1;
             $91..$a0:
               b := Index[j3] - $91
            end;
           Incr(j3);
         until False;
       Inc(tm, b);
       Dec(DLCatcher);
       if DLCatcher < 0 then RaiseBadFileStructure;
     until False;
    end;
  end;
end;

procedure GetTimeFLS(Module: PModTypes; var Tm: integer);
var
 b: byte;
 a1, a11: shortint;
 i: integer;
 pptr: longword;
 j1: longword;
begin
 with Module^ do
  begin
   b := Index[FLS_PositionsPointer];
   a1 := 0;
   a11 := 0;
   i := 0;
   repeat
     pptr := i + FLS_PositionsPointer + 1;
     if pptr >= 65536 then RaiseBadFileStructure;
     if Index[pptr] = 0 then break;
     j1 := FLS_PatternsPointers[Index[pptr]].PatternA;
     repeat
       Dec(a1);
       if a1 < 0 then
        begin
         if Index[j1] = 255 then break;
         repeat
           case Index[j1] of
             0..$5f, $80, $81:
              begin
               Incr(j1);
               a1 := a11;
               break;
              end;
             $82..$8e:
               Inc(j1);
             $8f..$ff:
               a11 := Index[j1] - $a1;
            end;
           Incr(j1);
         until False;
        end;
       Inc(tm, b);
     until False;
     Inc(i);
   until False;
  end;
end;

procedure GetTimePSM(Module: PModTypes; var Tm, Lp: integer);
var
 d, b, a, rc: byte;
 p, l, j, ra: longword;
begin
 with Module^ do
  begin
   p := PSM_PositionsPointer;
   if Index[p] = 255 then RaiseBadFileStructure;
   l := p;
   repeat
     Inc(p);
     incr(p)
   until Index[p] = 255;
   incr(p);
   d := Index[p];
   if d <> 255 then
    begin
     l := PSM_PositionsPointer + d;
     if l > p - 3 then RaiseBadFileStructure;
    end;

   p := PSM_PositionsPointer;
   repeat
     if p = l then Lp := Tm;
     d := Index[p];
     if d = 255 then break;
     j := PSM_PatternsPointer + d * 7 + 5;
     if j >= 65535 then RaiseBadFileStructure;
     j := PWord(@Index[j])^;
     d := Index[PSM_PatternsPointer + d * 7];
     a := 1;
     rc := 0;
     repeat
       if rc <> 0 then
        begin
         Dec(rc);
         if rc = 0 then j := {%H-}ra;
        end;
       b := Index[j];
       case b of
         0..$60, $90, $fc..$fe:
           Inc(Tm, d * a);
         $b1..$b7:
           Inc(j);
         $b8..$f8:
           a := b - $b7;
         $f9:
          begin
           ra := j + 3;
           if ra >= 65536 then RaiseBadFileStructure;
           rc := Index[j + 2];
           j := PWord(@Index[j])^ - 1;
          end;
         $ff: break;
        end;
       incr(j);
     until False;
     Inc(p);
     incr(p)
   until False;
  end;
end;

procedure GetTime(FileHandle: integer; PPLItem: pointer; Index: integer;
 AlreadyLoaded: pointer; var Lp: integer);
var
 Module: PModTypes;
 t: smallint;
 b, b1: byte;
 i, j, tm: integer;
 fl: DWORD;
 EPSGRec: TEPSGRec;
 tmbass: QWORD;
 bassh: integer;
 KsaId2: string;
 {$IFDEF Windows}
 MSF: packed record
   case boolean of
     True: (MSF: DWORD);
     False: (M, S, F: byte);
    end;
 mp: PMIDIParams;
 {$ENDIF Windows}
begin
 Lp := 0;
 tm := 0;

 with PPlayListItem(PPLItem)^ do
  begin

    try

     if IsAYNativeFileType(FileType) then
      begin
       if AlreadyLoaded = nil then
        begin
         New(Module);
         if not LoadTrackerModule(Module^, PPLItem, Index, 0, 0, nil, -1) then
          begin
           Dispose(Module);
           exit;
          end;
        end
       else
         Module := AlreadyLoaded;
      end;

      try

       if FileType = FT.OUT then
         with UniReadersData[FileHandle]^ do
          begin
           UniFileSeek(FileHandle, 0);
           repeat
             UniRead(FileHandle, @t, 2);
             if (t = -1) or (t = 0) then Inc(tm);
             UniFileSeek(FileHandle, UniFilePos + 3);
           until UniFilePos >= UniFileSize;
           tm := round(tm * 1000 / (FrqZ80 / 17472));
           if t > 0 then
             Inc(tm, round((t / 17472) * 1000 / (FrqZ80 / 17472)));
          end
       else if FileType = FT.EPSG then
         with UniReadersData[FileHandle]^ do
          begin
           UniFileSeek(FileHandle, 5);
           UniRead(FileHandle, @b, 1);
           case b of
             0: i := 70908;
             255: UniRead(FileHandle, @i, 4)
           else
             i := 71680;
            end;
           UniFileSeek(FileHandle, 16);
           EPSGRec.All := 0;
           while UniFilePos < UniFileSize do
            begin
             UniRead(FileHandle, @EPSGRec, 5);
             if EPSGRec.All = $FFFFFFFFFF then Inc(tm);
            end;
           if EPSGRec.All = $FFFFFFFFFF then
             j := 0
           else
             j := EPSGRec.TSt;
           tm := round((tm / (FrqZ80 / i) + j / FrqZ80) * 1000);
          end
       else if FileType = FT.PSG then
         with UniReadersData[FileHandle]^ do
          begin
           UniFileSeek(FileHandle, 16);
           while UniFilePos < UniFileSize do
            begin
             UniRead(FileHandle, @b, 1);
             case b of
               255: Inc(tm); //interrupt
               254: //skip frames
                begin
                 UniRead(FileHandle, @b1, 1);
                 Inc(tm, b1 * 4);
                end;
               253: Break; //eom
             else
               UniFileSeek(FileHandle, UniFilePos + 1);
              end;
            end;
           if not (b in [254, 255]) then
             Inc(tm);
          end
       else if FileType = FT.ZXAY then
         with UniReadersData[FileHandle]^ do
          begin
           UniFileSeek(FileHandle, 4);
           while UniFilePos < UniFileSize do
            begin
             UniRead(FileHandle, @i, 4);
             if i and $FFFFF = 0 then Inc(tm);
            end;
           tm := round(tm * 1000 / (FrqZ80 / $100000) + (t and $FFFFF) /
             FrqZ80 * 1000);
          end
       else if FileType = FT.PT3 then
         GetTimePT3(Module, Tm, Lp)
       else if FileType = FT.PT2 then
         GetTimePT2(Module, Tm, Lp)
       else if (FileType = FT.STC) or (FileType = FT.ST1) or (FileType = FT.ST3) then
         GetTimeSTC(Module, Tm)
       else if (FileType = FT.STP) or (FileType = FT.STF) then
        begin
         if FileType = FT.STF then
          begin
           SetLength(KsaId2, 28);
           Move(Module^.Index[10], KsaId2[1], 28);
           if KsaId2 = KsaId then
            begin
             SetLength(Title, 25);
             Move(Module^.Index[38], Title[1], 25);
            end;
          end;
         GetTimeSTP(Module, Tm, Lp);
        end
       else if (FileType = FT.ASC) or (FileType = FT.ASC0) then
         GetTimeASC(Module, Tm, Lp)
       else if FileType = FT.PSC then
         GetTimePSC(Module, Tm, Lp)
       else if FileType = FT.SQT then
         GetTimeSQT(Module, Tm, Lp)
       else if FileType = FT.FTC then
         GetTimeFTC(Module, Tm, Lp)
       else if FileType = FT.PT1 then
         GetTimePT1(Module, Tm, Lp)
       else if FileType = FT.FLS then
         GetTimeFLS(Module, Tm)
       else if FileType = FT.GTR then
         GetTimeGTR(Module, Tm, Lp)
       else if FileType = FT.FXM then
         GetTimeFXM(Module, Address, Tm, Lp)
       else if FileType = FT.PSM then
         GetTimePSM(Module, Tm, Lp)
       else if IsStreamOrModuleFileType(FileType) then
        begin
         Lp := -1;
         LoadBASS;
         if not BASSInitialized then InitBASS(BASS_NOSOUNDDEVICE, SampleRate, 0, 0);
         if IsStreamFileType(FileType) then
          begin
           if StreamPrescan then
             //slow, but need for VBR MP3 and chained OGG
             fl := BASS_STREAM_DECODE or BASS_STREAM_PRESCAN
           else
             fl := BASS_STREAM_DECODE;
           bassh := BASS_StreamCreateFile2(PChar(FileName), fl);
          end
         else
           bassh := BASS_MusicLoad(False, PChar(FileName), 0, 0,
             BASS_MUSIC_STOPBACK or BASS_MUSIC_PRESCAN or BASS_MUSIC_NOSAMPLE, 0);
         if bassh = 0 then RaiseLastBASSError;
          try
           tmbass := BASS_ChannelGetLength(bassh, BASS_POS_BYTE);
           if tmbass = QWORD(-1) then
             Tm := -1
           else
             Tm := Trunc(BASS_ChannelBytes2Seconds(bassh, tmbass) * 1000);
           BASSGetType(bassh, PPLItem);
           BASSGetTags(bassh, PPLItem);
          finally
           if IsStreamFileType(FileType) then
             BASS_StreamFree(bassh)
           else
             BASS_MusicFree(bassh);
          end;
        end
       {$IFDEF Windows}
       else if IsCDFileType(FileType) then
        begin
         Lp := -1;
         InitCDDevice(Address);
         if not CheckCDNum(Address) then exit;
         MSF.MSF := CDGetTrackLength(Address, Offset);
         Tm := MSF.F + (MSF.S + MSF.M * 60) * 75;
        end
       else if IsMIDIFileType(FileType) then
        begin
         mp := MIDIParams;
         if AlreadyLoaded = nil then load_midi(mp, nil, FileName);
         if mp^.file_format in [0, 1] then
          begin
           Tm := mp^.song_length;
           Author := CPToUTF8(mp^.th[0].fstcopyrtxt);
           Title := CPToUTF8(mp^.th[0].fstseqtrkname);
           Comment := '';
           for i := 0 to mp^.num_tracks - 1 do
             Comment := Comment + mp^.th[i].alltexts;
           Comment := CPToUTF8(Comment);
          end
         else if (FormatSpec >= 0) and (FormatSpec < mp^.num_tracks) then
          begin
           Tm := mp^.th[FormatSpec].track_length;
           Author := CPToUTF8(mp^.th[FormatSpec].fstcopyrtxt);
           Title := CPToUTF8(mp^.th[FormatSpec].fstseqtrkname);
           Comment := CPToUTF8(mp^.th[FormatSpec].alltexts);
          end;
         if AlreadyLoaded = nil then unload_midi(mp);
        end;
       {$ENDIF Windows}

      finally

       if IsAYNativeFileType(FileType) and (AlreadyLoaded = nil) then
         Dispose(Module);
       if Tm = 0 then Error := ErBadFileStructure;

      end;

     if Tm <> 0 then
      begin
       Time := Tm;
       if CalculateTotalTime(False) then
        begin
         if BASSInitialized and (BASSDevice = BASS_NOSOUNDDEVICE) then
           FreeAndUnloadBASS;
         {$IFDEF Windows}
         if not IsPlaying or not IsCDFileType(CurFileType) then
           FreeAllCD;
         {$ENDIF Windows}
        end;
      end;

    except
     on EBASSError do Error := ErBASSError;
     on EFileStructureError do Error := ErBadFileStructure;
     else if Error = FileNoError then Error := ErReadingFile;
    end;

  end;
end;

procedure YMizeSample(Buf: PArray0OfByte; Len: integer);
var
 i1, k, k2: integer;
 b: byte;
begin
 for i1 := 0 to Len - 1 do
  begin
   b := Buf[i1];
   k2 := round(b / 255 * 65535);
   k := 1;
   while (k < 32) and (Amplitudes_YM[k] < k2) do
     Inc(k, 2);
   if k > 1 then
     if Amplitudes_YM[k] - k2 > k2 - Amplitudes_YM[k - 2] then
       Dec(k, 2);
   Buf[i1] := k div 2;
  end;
end;

var
 i, j: integer;

initialization

 for i := 0 to 15 do
   for j := 0 to 7 do
     YM6SinusTable[i, j] := round(sin(j * 2 * pi / 8) * i / 2 + i / 2);

 for i := 0 to 39 do
   YMizeSample(sampleAdress[i], sampleLen[i]);

finalization

end.
