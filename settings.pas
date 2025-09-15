{
This is part of AY Emulator project
AY-3-8910/12 Emulator
Version 3.0 for Windows and Linux
Author Sergey Vladimirovich Bulba
(c)1999-2025 S.V.Bulba
}

unit settings;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils;

//todo завести текущие установки типа Index_ALCur (сейчас установки хранятся
//в миксере, а Index_AL - текущее. Подумать...

//может объеденить с опциями типа TOption = (SetValue,DefValue,CurValue,OptionName)

const
//Default mixer parameters
 SampleRateDef  = 48000;
 SampleBitDef   = 16;
 FrqZ80Def      = 3494400;
 AY_FreqDef     = 1773400;
 IntOffsetDef   = 0;
 BeeperMaxDef   = 146;
 Atari_DMAMaxDef = 146;
 MaxTStatesDef  = 69888;
 Interrupt_FreqDef = 50000;
 Index_ALDef    = 255;
 Index_ARDef    = 13;
 Index_BLDef    = 170;
 Index_BRDef    = 170;
 Index_CLDef    = 13;
 Index_CRDef    = 255;
 NumOfChanDef   = 2;
 ChanModeDef    = 1;
 MFPTimerModeDef = 0;
 MFPTimerFrqDef = 2457600;

 NumberOfBuffersDef = 3;
 BufLen_msDef = 200;

 //todo: select default CP in Linux due system language settings
 //todo: Ansi for Vortex Tracker, OEM for other trackers?
 CodePageDef:string = {$IFDEF Windows}'Ansi'{$ELSE Windows}'CP1251'{$ENDIF Windows};

var
 VolumeCtrl,VolumeCtrlMax:integer;
 VolLinear:boolean = False;

 NumberOfChannels,SampleRate,SampleBit:integer;
 NumberOfBuffers,BufferLength,BuffLen,BufLen_ms:integer;

 IntOffset:integer;
 FrqZ80,Interrupt_Freq,AY_Freq:integer;

 Real_End_All:boolean;
 Real_End:array[0..1] of boolean;

 Do_Loop:boolean = False;

 //set RealEnd flag but continue playback
 //(need for TS-pairs of different length, currently only tracker modules)
 Force_Loop:boolean = True;

 StreamPrescan:boolean = True;

 BeeperMax,Atari_DMAMax:byte;
 BeeperLevel,Atari_DMALevel:integer;

implementation

end.

